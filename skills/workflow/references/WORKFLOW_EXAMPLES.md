# Workflow Examples and Patterns

This reference provides concrete examples of correct and incorrect CI/CD (Continuous Delivery) workflow patterns.

---

## Generic YAML Templates

### Artifact Upload Template

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

### Idempotent PR Comment Template (Full Pattern)

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

## Pipeline Safety -- Correct Examples

### [+] Upload Artifacts Instead of Committing

```yaml
- name: Upload Generated Images
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: visual-regression-images
    path: |
      build/tests/artifacts/
      build/tests/diffs/
    retention-days: 30
    if-no-files-found: ignore
```

### [+] Link to Artifacts in PR Comments

```yaml
const runUrl = `${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`;
const artifactsUrl = `${runUrl}#artifacts`;
body += `**[Download images from workflow artifacts](${artifactsUrl})**\n\n`;
```

### [+] Minimal Permissions

```yaml
permissions:
  contents: read        # Read repo
  checks: write         # Write check results
  pull-requests: write  # Comment on PRs
```

---

## Pipeline Safety -- INCORRECT Examples (Do NOT Follow)

### [-] Committing from CI

```yaml
# BAD: Never commit from a pipeline
- name: Commit generated files
  run: |
    git add generated-images/
    git commit -m "chore: update generated images [skip ci]"
    git push
```

**Why:** Creates infinite loops, race conditions, and audit trail problems.

### [-] Base64 Data URIs in PR Comments

```yaml
# BAD: GitHub strips data: URIs from img tags
body += `<img src="data:image/png;base64,${base64Data}" />`;
```

**Why:** GitHub strips `data:image/png;base64,...` from `<img>` tags for security. Images appear broken.

### [-] Over-Permissive Workflow

```yaml
# BAD: Don't grant write access to everything
permissions: write-all
```

**Why:** Violates principle of least privilege. Only grant what the job actually needs.

### [-] Duplicate PR Comments (No Idempotency)

```javascript
// BAD: Creates a new comment every run
await github.rest.issues.createComment({
  owner: context.repo.owner,
  repo: context.repo.repo,
  issue_number: context.issue.number,
  body: report
});
```

**Why:** Spams the PR with duplicate comments on re-runs.

---

## Job Dependency Patterns

### Sequential: Unit -> Integration -> Visual

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    # Unit tests run first (no dependencies)

  visual-regression:
    runs-on: ubuntu-latest
    needs: test
    # Visual tests run after unit tests pass
```

### Gtest (Google Test) Output Parsing (Final Summary Lines)

```bash
TOTAL=$(grep -E '^\[==========\] [0-9]+ tests? from [0-9]+ test suites? ran\.' output.txt \
  | tail -1 | grep -oE '[0-9]+' | head -1 || echo "0")
PASSED=$(grep -E '^\[  PASSED  \] [0-9]+ tests?\.' output.txt \
  | tail -1 | grep -oE '[0-9]+' | head -1 || echo "0")
FAILED=$(grep -E '^\[  FAILED  \] [0-9]+ tests?, listed below:' output.txt \
  | tail -1 | grep -oE '[0-9]+' | head -1 || echo "0")
```

**Note:** Don't use `"X tests from"` lines -- gtest outputs one per suite. Always parse the final summary.

---

## Current Workflow Structure

The project uses `unit-tests.yml` with two jobs:

1. **`test`** -- Build, run unit tests, generate coverage, comment on PR
2. **`visual-regression`** -- Build, run `VisualRegressionTest.*` under Xvfb (X Virtual Framebuffer), upload artifact images, comment on PR
