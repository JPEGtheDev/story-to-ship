---
name: workflow
license: MIT
description: Use when creating GitHub Actions workflows, adding CI jobs, configuring artifact uploads, or reviewing pipeline configuration for Particle-Viewer.
---

## Iron Law

```
PIPELINES ARE READ-ONLY — NEVER COMMIT FROM CI
```

Violating the letter of this rule is violating the spirit of this rule.

CI workflows read code, run tests, and publish artifacts. They never write code. No exceptions.

**Second Iron Law:**

```
BROKEN PIPELINE = HIGHEST PRIORITY — STOP ALL MERGES UNTIL GREEN
```

Violating the letter of this rule is violating the spirit of this rule.

A broken main branch pipeline is not a background task. It is the highest-priority item for anyone working on the project. No PR merges while the pipeline is red. The broken build is the only work that matters until it is fixed.

**Why:** A broken pipeline on main means the deploy safety net is gone. Every merge while it is broken is unverified. The longer it stays broken, the harder the root cause is to identify (multiple changes compound). Fix it immediately, not in the next sprint.

**Announce at start:** "I am using the workflow skill to [create/update/debug] [workflow description]."

---

# Instructions for Agent

## How This Skill is Invoked

In VS Code, users will activate this skill by:
- Typing `@workspace /workflow [description]` in Copilot Chat
- Or asking: "Add a CI job for [task]", "Fix the workflow", "Set up artifact uploads"

When activated, write or modify workflows that strictly follow the project's CI pipeline rules.

---

## Core Principle: Pipelines Are Read-Only Consumers

CI pipelines observe and report — they never modify the repository. Every rule below follows from this principle.

---

## Step 1: Understand the Request

Ask the user what CI/CD change they need:

> "What would you like to do? I support:
> 1. **Add a new workflow job** — e.g., visual regression, linting, deployment
> 2. **Modify an existing job** — change steps, add artifacts, fix permissions
> 3. **Review a workflow** — check for safety issues and best practices
> 4. **Set up artifact uploads** — images, reports, test results"

---

## Step 2: Apply Pipeline Safety Rules

### Rules That Must NEVER Be Violated

1. **NEVER commit or push from a pipeline.** Pipelines are read-only consumers of the repository. Committing from CI creates infinite loops, race conditions, and audit trail problems.
2. **NEVER use `data:` URIs for inline images in PR comments.** GitHub strips `data:image/png;base64,...` from `<img>` tags in comments and step summaries for security.

### Rules That Must ALWAYS Be Followed

3. **Upload generated files** (images, reports) as workflow artifacts via `actions/upload-artifact`.
4. **Link to artifact downloads** in PR comments for visibility.
5. **Use `$GITHUB_STEP_SUMMARY`** for rich text reports on the Actions tab.
6. **Keep permissions minimal** — use `contents: read` unless the job needs to write checks or comments.
7. **Use idempotent PR comments** — find and update existing comments instead of creating duplicates.

---

## Step 3: Follow Workflow Structure Patterns

### Job Dependencies

Use `needs:` to enforce execution order:
- Unit tests run first
- Integration/visual tests run after unit tests pass
- Deployment runs after all tests pass

### Artifact Upload Pattern

```yaml
- name: Upload Test Artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: descriptive-artifact-name
    path: |
      path/to/generated/files/
    retention-days: 30
    if-no-files-found: ignore
```

### PR Comment Pattern (Idempotent)

```yaml
- name: Comment on PR
  if: always() && github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    script: |
      const marker = 'Unique Report Title';
      const body = `## ${marker}\n\nReport content here...`;

      const { data: comments } = await github.rest.issues.listComments({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
      });

      const existing = comments.find(c =>
        c.user.type === 'Bot' && c.body.includes(marker)
      );

      if (existing) {
        await github.rest.issues.updateComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          comment_id: existing.id,
          body: body
        });
      } else {
        await github.rest.issues.createComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          issue_number: context.issue.number,
          body: body
        });
      }
```

---

## Step 4: Review Checklist

Before presenting workflow changes, verify:

- [ ] No `git commit`, `git push`, or write-back operations in any step
- [ ] No `data:` URIs in PR comment bodies
- [ ] Permissions are minimal (`contents: read` unless writing comments/checks)
- [ ] Generated files uploaded as artifacts (not committed)
- [ ] PR comments are idempotent (update existing, don't duplicate)
- [ ] Job dependencies are correct (`needs:` ordering)
- [ ] `if: always()` on artifact upload and PR comment steps where needed
- [ ] Artifact retention set appropriately (default: 30 days)

✓ All met → proceed with presenting workflow changes
✗ Any unmet → fix before presenting

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I need to commit from CI to fix this issue" | NEVER. Fix the code locally, push, let CI re-run. Committing from CI creates loops. |
| "Broad permissions are easier than figuring out minimal ones" | Broad permissions are a security risk. Use minimal permissions — write only what's needed. |
| "I'll test this workflow change in CI" | Test locally with `act` or trace the logic manually. Don't waste CI minutes on avoidable failures. |
| "Artifact retention doesn't matter much" | Excessive retention wastes storage. PRs: short retention. Releases: longer. |
| "The trigger seems right, I'll push and check" | Incorrect triggers cause runaway pipelines or missing runs. Verify the trigger logic before pushing. |
| "This job doesn't need to wait for the other to finish" | Race conditions in CI are hard to debug. Use `needs:` dependencies explicitly. |

---

## Red Flags — STOP

If you catch yourself thinking any of these, stop and follow the rule:
- Typing `git commit` or `git push` inside a workflow `run:` step
- "I'll just set `permissions: write-all` for now"
- "Let me push this workflow change and see if it works"
- Adding a `workflow_run` trigger without verifying it won't cause infinite loops
- `secrets.GITHUB_TOKEN` used with `write` permission for something that only needs `read`
- Artifact upload without a `retention-days:` value

**All of these mean: Pipelines are read-only. Verify trigger logic and permissions before every push. Never commit from CI.**

---

## Reference

For concrete workflow examples and patterns, see [references/WORKFLOW_EXAMPLES.md](references/WORKFLOW_EXAMPLES.md).

For Flatpak packaging, SDL3 display backend configuration, NVIDIA GL extension issues, and `setenv` behaviour inside the Flatpak sandbox, see the `flatpak` skill (`.github/skills/flatpak/`) or [references/FLATPAK_GL_GOTCHAS.md](references/FLATPAK_GL_GOTCHAS.md) for the detailed reference.
