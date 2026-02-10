# Documentation Examples and Templates

This reference provides templates and examples for writing documentation in Particle-Viewer.

---

## Skill File Template (SKILL.md)

```markdown
---
name: skill-name
description: One-line description of what this skill does and when to use it.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.0"
  category: category-name
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked
[How users activate this skill]

## Core Principle
[One sentence summarizing the key principle]

## Step 1: Understand the Request
[Questions to ask the user]

## Step 2: Apply Rules
[Domain-specific rules and patterns]

## Step 3: Review Checklist
[Verification checklist before presenting results]

## Reference
For examples, see [references/EXAMPLES.md](references/EXAMPLES.md).
```

### Key Rules for Skills

1. **Minimize duplication** — if another skill covers a topic, reference it:
   ```markdown
   For CI pipeline rules, see the `workflow` skill (`.github/skills/workflow/`).
   ```
2. **Keep SKILL.md focused** — rules and workflow only
3. **Put examples in `references/`** — not in SKILL.md itself (unless inline for clarity)

---

## Guide Document Template

```markdown
# Feature Name Guide

Brief description of what this guide covers.

## Table of Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Usage](#usage)
4. [Best Practices](#best-practices)

---

## Overview
[What it is, why it exists, key components]

## Getting Started
[Prerequisites, setup steps, first example]

## Usage
[Detailed usage with code examples]

## Best Practices
[Do's and don'ts with concrete examples]
```

---

## Relative Link Examples

### From `docs/testing/visual-regression.md`:

```markdown
<!-- ✅ Correct: relative path from docs/testing/ to docs/ -->
See [Testing Standards](../TESTING_STANDARDS.md) for AAA pattern details.

<!-- ❌ Incorrect: wrong relative path -->
See [Testing Standards](TESTING_STANDARDS.md) for AAA pattern details.
```

### From `docs/CODING_STANDARDS.md`:

```markdown
<!-- ✅ Correct: same directory -->
See [Testing Standards](TESTING_STANDARDS.md) for test-specific conventions.

<!-- ✅ Correct: subdirectory -->
See [Visual Regression Guide](testing/visual-regression.md) for image comparison.
```

---

## Type Reference Table Template

```markdown
| Type | Location | Purpose |
|------|----------|---------|
| `ClassName` | `src/File.hpp` | Brief description |
| `StructName` | `src/other/File.hpp` | Brief description |
```

---

## Code Example Formatting

Always include language tags:

````markdown
```cpp
// C++ example
Image img(16, 16);
```

```bash
# Shell example
cmake -B build -S .
```

```yaml
# YAML example
steps:
  - uses: actions/checkout@v4
```
````

---

## copilot-instructions.md Style Guide

The instructions file should:
1. **Summarize, don't duplicate** — point to skills and docs for details
2. **Use this pattern for referencing skills:**
   ```markdown
   **CRITICAL: Read `docs/TESTING_STANDARDS.md` before writing tests.**
   For detailed guidelines, examples, and patterns, use the `testing` skill
   (`.github/skills/testing/`).
   ```
3. **Keep examples to bare minimum** — only include examples that are essential for onboarding
4. **Group related information** — use clear headings and sections
