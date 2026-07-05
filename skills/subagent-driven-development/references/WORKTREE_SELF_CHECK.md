# Worktree Self-Check -- Canonical Block

This file is the source of truth for the Worktree Self-Check block used by every agent
template in agents/. Read-only templates carry the core block (Variant A). Templates that
COMMIT to a branch (currently only implementer) additionally carry the branch-isolation
step (Variant B). Copy the applicable variant verbatim, substituting the template's own
path placeholder (e.g. {{REPO_PATH}} for postmortem-reviewer, {{WORKTREE_PATH}} elsewhere).
Do not shorten or reword it.

## Variant A -- read-only templates

````
## Worktree Self-Check -- Run BEFORE starting

```bash
git -C {{WORKTREE_PATH}} rev-parse --show-toplevel
```

The output MUST match `{{WORKTREE_PATH}}`.
- If it matches -> proceed.
- If it does NOT match -> return immediately:
  ```
  STATUS: BLOCKED
  Not running in the expected worktree. `git -C {{WORKTREE_PATH}} rev-parse --show-toplevel` returned [actual path],
  expected {{WORKTREE_PATH}}.
  ```
````

## Variant B -- write templates (commit to a branch)

````
## Worktree Self-Check -- Run BEFORE starting

```bash
# Step 1: Verify you are in the correct worktree
git -C {{WORKTREE_PATH}} rev-parse --show-toplevel
```

The output MUST match `{{WORKTREE_PATH}}`.

- If it matches -> you are in the correct worktree. Proceed.
- If it does NOT match -> return immediately:
  ```
  STATUS: BLOCKED
  Blockers: Not running in the expected worktree. `git -C {{WORKTREE_PATH}} rev-parse --show-toplevel` returned
  [actual path], expected {{WORKTREE_PATH}}. The orchestrator must create the worktree and
  re-dispatch with the correct WORKTREE_PATH.
  ```

```bash
# Step 2: Verify branch isolation
git branch --show-current
```

The output MUST NOT be `main` or the parent development branch name.

- If it is -> return immediately:
  ```
  STATUS: BLOCKED
  Blockers: Running on main or the parent development branch. Branch isolation is not
  confirmed. The worktree must be on a dedicated branch before this agent can proceed.
  ```
````
