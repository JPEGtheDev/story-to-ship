/**
 * story-to-ship -- OpenCode plugin
 *
 * Ports the Claude Code hook set (hooks/hooks.json) onto the OpenCode plugin
 * API. The hook scripts themselves are shared, unmodified, and fail-open;
 * this file only translates the OpenCode event stream into the hook payload
 * shape the scripts already expect (JSON on stdin).
 *
 * Event map (Claude Code -> OpenCode):
 *   SessionStart      -> "session.created" / "session.compacted"
 *   UserPromptSubmit  -> "chat.message" (user parts)
 *   PreToolUse        -> "tool.execute.before"
 *   PostToolUse       -> "tool.execute.after"
 *   Stop              -> "session.idle"
 *
 * Tool-name translation: Claude Code's `Skill` tool is `skill` in OpenCode.
 * The `Workflow` tool is Claude Code only; its guard is a no-op here (the
 * hook itself also no-ops on absent tool_input.script).
 *
 * Bootstrap flag state lives in <project>/.claude/ (the Claude Code
 * convention) so an existing checkout's flags are respected. Set
 * STS_STATE_DIR to override the state directory.
 *
 * Every hook runs under a hard timeout and fails open: any error (including
 * a timeout) is swallowed so a plugin defect can never wedge a session.
 */

import { spawn } from "node:child_process"
import path from "node:path"
import fs from "node:fs"

// The plugin file lives in <repo>/opencode/; hook scripts live in <repo>/hooks/.
// Resolved dynamically so the plugin works from a git checkout, an npm
// package, or a copied plugin directory alike.
const HOOKS_DIR = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..", "hooks")

const HOOK_TIMEOUT_MS = 10_000

const OC_TO_CC_TOOL: Record<string, string> = {
  skill: "Skill",
  workflow: "Workflow",
}

function hookScript(name: string): string | null {
  try {
    const p = path.join(HOOKS_DIR, name)
    return fs.existsSync(p) ? p : null
  } catch {
    return null
  }
}

/**
 * Run a hook script with `payload` on stdin. Resolves to the script's stdout
 * (the Claude Code hook JSON envelope, if any) and to null on any failure.
 */
function runHook(scriptName: string, payload: unknown, env?: Record<string, string>): Promise<string | null> {
  return new Promise((resolve) => {
    const script = hookScript(scriptName)
    if (!script) {
      resolve(null)
      return
    }
    const child = spawn("bash", [script], {
      env: { ...process.env, ...env },
      stdio: ["pipe", "pipe", "pipe"],
    })
    let stdout = ""
    const timer = setTimeout(() => {
      try {
        child.kill("SIGKILL")
      } catch {}
      resolve(null)
    }, HOOK_TIMEOUT_MS)
    child.stdout.on("data", (d) => (stdout += d.toString()))
    child.on("error", () => {
      clearTimeout(timer)
      resolve(null)
    })
    child.on("close", () => {
      clearTimeout(timer)
      resolve(stdout || null)
    })
    child.stdin.write(JSON.stringify(payload))
    child.stdin.end()
  })
}

/** Parse a Claude Code hook envelope; returns null unless it is usable. */
function parseEnvelope(out: string | null): { hookSpecificOutput?: any; decision?: string; reason?: string } | null {
  if (!out) return null
  try {
    return JSON.parse(out.trim())
  } catch {
    return null
  }
}

/**
 * Map the Claude Code hook JSON (stdout of a hook script) onto the OpenCode
 * hook `output` object. Returns true if the call should be blocked.
 *
 * PreToolUse deny envelope:
 *   {"hookSpecificOutput": {"hookEventName": "PreToolUse",
 *    "permissionDecision": "deny", "permissionDecisionReason": "..."}}
 * Context-injection envelope (UserPromptSubmit):
 *   {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
 *    "additionalContext": "..."}}
 */
function applyEnvelope(env: ReturnType<typeof parseEnvelope>, output: { block?: boolean; blockReason?: string; args?: any; [k: string]: any }, kind: "pre" | "context"): boolean {
  if (!env?.hookSpecificOutput) return false
  if (kind === "pre") {
    if (env.hookSpecificOutput.permissionDecision === "deny") {
      output.block = true
      output.blockReason = env.hookSpecificOutput.permissionDecisionReason || "Blocked by story-to-ship hook"
      return true
    }
  } else {
    if (typeof env.hookSpecificOutput.additionalContext === "string") {
      output.systemMessage = env.hookSpecificOutput.additionalContext
    }
  }
  return false
}

export const StoryToShip = async (ctx: {
  project?: any
  client?: any
  $?: any
  directory?: string
  worktree?: string
}) => {
  const projectDir = ctx.directory || process.cwd()
  const stateDir = process.env.STS_STATE_DIR || path.join(projectDir, ".claude")
  try {
    fs.mkdirSync(stateDir, { recursive: true })
  } catch {}
  const env: Record<string, string> = { CLAUDE_PROJECT_DIR: stateDir, BOOTSTRAP_GATE_STATE_DIR: stateDir }

  return {
    "session.created": async (_input: any, output: any) => {
      // Claude SessionStart: re-grounding banner + bootstrap-pending flag.
      const out = await runHook("session-start.sh", { source: "startup" }, env)
      applyEnvelope(parseEnvelope(out), output, "context")
    },

    "session.compacted": async (_input: any, output: any) => {
      // Claude SessionStart (source: compact) continuation path.
      const out = await runHook("session-start.sh", { source: "compact" }, env)
      applyEnvelope(parseEnvelope(out), output, "context")
    },

    "chat.message": async (input: any, output: any) => {
      // Claude UserPromptSubmit: per-turn gate reminders (pre-message-gates.md,
      // pre-message.md). Both Claude registrations run every prompt, so both
      // scripts run here and their additionalContext values are concatenated.
      // Only user parts trigger this; assistant parts are ignored.
      const text: string = Array.isArray(input?.parts)
        ? input.parts.filter((p: any) => p?.type === "text" || p?.type === "text-input").map((p: any) => p.text || "").join("\n")
        : (input?.text || input?.message || "")
      const payload = { session_id: input?.sessionID || input?.session_id || "", prompt: text, source: "prompt" }
      const parts: string[] = []
      for (const s of ["pre-message-gates.sh", "pre-message.sh"] as const) {
        const e = parseEnvelope(await runHook(s, payload, env))
        if (typeof e?.hookSpecificOutput?.additionalContext === "string") parts.push(e.hookSpecificOutput.additionalContext)
      }
      if (parts.length > 0) output.systemMessage = parts.join("\n\n")
    },

    "tool.execute.before": async (input: any, output: any) => {
      // Claude PreToolUse: bootstrap gate (all tools) + workflow model guard.
      const ccTool = OC_TO_CC_TOOL[input?.tool] || input?.tool
      const payload = {
        session_id: input?.sessionID || "",
        tool_name: ccTool,
        tool_input: output?.args || {},
        agent_id: "",
      }
      const gate = await runHook("bootstrap-gate-pre.sh", payload, env)
      if (applyEnvelope(parseEnvelope(gate), output, "pre")) return
      if (ccTool === "Workflow") {
        const guard = await runHook("workflow-model-guard.sh", payload, env)
        applyEnvelope(parseEnvelope(guard), output, "pre")
      }
    },

    "tool.execute.after": async (input: any, _output: any) => {
      // Claude PostToolUse (matcher: Skill): clears the bootstrap-pending flag
      // once Skill(session-bootstrap) completes.
      const ccTool = OC_TO_CC_TOOL[input?.tool] || input?.tool
      if (ccTool !== "Skill") return
      const payload = {
        session_id: input?.sessionID || "",
        tool_name: ccTool,
        tool_input: input?.args || {},
        tool_response: input?.output ?? {},
        agent_id: "",
      }
      await runHook("bootstrap-gate-post.sh", payload, env)
    },

    "session.idle": async (_input: any, _output: any) => {
      // Claude Stop: passive per-turn JSONL logging. Fire and forget.
      void runHook("stop-turn-log.sh", { session_id: "", stop_hook_active: false, last_assistant_message: "" }, env)
    },
  }
}

export default StoryToShip
