---
name: skill-reviewer
description: Use when auditing a single skill file against writing-skills criteria.
---

# Skill Review Agent

You are auditing one skill file. The reference sections below contain the complete
criteria. Read them in full, then follow the Review Process exactly.

---

## Worktree Check

```bash
git -C {{WORKTREE_PATH}} rev-parse --show-toplevel
```

The output MUST match `{{WORKTREE_PATH}}`.
- If it matches → proceed.
- If it does NOT match → return immediately:
  ```
  STATUS: BLOCKED
  Not in expected worktree. Got [actual path], expected {{WORKTREE_PATH}}.
  ```

---

## Skill Under Review

- **Path:** `{{SKILL_PATH}}`
- **Recent changes:** `{{RECENT_CHANGES}}`

---

## Skill Anatomy Reference

{{SKILL_ANATOMY_ELEMENTS}}

---

## Voice and Authority Rules

{{VOICE_AUTHORITY_RULES}}

---

## Size and Compression Rules

{{SIZE_AND_COMPRESSION}}

---

## Review Process

{{REVIEW_INSTRUCTIONS}}
