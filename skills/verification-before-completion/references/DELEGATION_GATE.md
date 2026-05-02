# Agent Delegation Gate

## Agent Delegation Verification

When a subagent reports that it completed work, **do not propagate its claim without verifying.**

Subagents can:
- Report success on work that was only partially done
- Fail silently (exit 0 with no actual file changes)
- Write to the wrong path (worktree vs. main working tree)

**The delegation verification gate:**

```
Agent reports: "Done" / "Complete" / "Fixed" / "Committed"
    ↓
1. Check VCS diff — do the changes exist?
   git diff HEAD  OR  git -C [worktree-path] diff HEAD
    ↓
2. Verify changes match the stated intent
   Read the diff — do the files changed match what was requested?
    ↓
3. Run verification commands on the output
   Run the project verification commands (see `references/PV_VERIFICATION_COMMANDS.md`)
    ↓
4. ONLY THEN claim the subagent's work is complete
```

✓ All steps passed → claim the subagent's work is complete
✗ Any step failed → do not relay the completion claim; investigate and fix before claiming done

**Gate rule:** An agent's "Done" claim is a hypothesis. Your verification makes it a fact.

| Agent claim | Your response |
|-------------|---------------|
| "I committed [X]" | `git log --oneline -5` — does the commit exist? |
| "I updated the file" | `git diff HEAD [file]` — are the changes present? |
| "All tests pass" | Run `./build/tests/ParticleViewerTests` yourself |
| "I created the skill" | `ls .github/skills/[skill-name]/SKILL.md` — does it exist? |

**Never relay a subagent's completion claim to the user without first running this gate.**
