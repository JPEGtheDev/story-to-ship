---
name: workflow
description: Write and maintain GitHub Actions CI/CD workflows for Particle-Viewer. Use when creating workflows, adding CI jobs, configuring artifact uploads, or reviewing pipeline configuration. Covers pipeline safety rules, permissions, and artifact patterns.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.0"
  category: ci-cd
  project: Particle-Viewer
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

---

## Reference

For concrete workflow examples and patterns, see [references/WORKFLOW_EXAMPLES.md](references/WORKFLOW_EXAMPLES.md).
