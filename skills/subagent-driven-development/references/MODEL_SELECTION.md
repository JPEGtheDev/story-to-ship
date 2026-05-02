# Model Selection

Match model tier to task complexity. Instructions must be written for GPT-4.1 baseline regardless of selected tier.

**Model preference priority — check in this order before every agent dispatch:**

1. **Stored memory override (highest):** Check stored memories for a user-specified model preference. If found, apply that tier to ALL agents in this batch — it overrides the table below.
2. **Tier table (default):** If no stored preference, use the task-type table below.
3. **Session default (fallback):** If neither applies, use the current session default.

If the user states a model preference in the current session, store it as a memory fact immediately so it persists.

| Task type | Default tier |
|-----------|-------------|
| Mechanical: grep, rename, format, one-function change | Standard |
| Research: read files, summarize patterns, compare approaches | Standard |
| Implementation: multi-file, design judgment | Standard |
| Review: spec compliance, code quality, architecture | Standard |
| Architecture design, security, final review | Premium |

**Using Premium for non-architecture tasks:** State the reasoning before dispatching. Example: "Dispatching Premium for this review because the change touches 3 layer boundaries." Do not dispatch Premium silently for mechanical work.

**Concurrency:** Copilot Enterprise accounts have no practical agent concurrency limit. Dispatch as many parallel agents as the task warrants. Standard accounts: verify your limit before parallelizing.

**For parallel read-only research:** Use `dispatching-parallel-agents` skill.
