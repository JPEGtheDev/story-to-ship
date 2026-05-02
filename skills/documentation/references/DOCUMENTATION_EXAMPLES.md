# Documentation Examples and Templates

This reference provides templates and examples for writing documentation in Particle-Viewer.

---

## Domain Taxonomy

| Domain | Subdomains | Location |
|--------|-----------|----------|
| `testing` | `unit-testing`, `integration-testing`, `visual-regression` | `docs/testing/` |
| `coding` | `naming`, `formatting`, `memory-management`, `patterns` | `docs/coding/` |
| `build` | `cmake`, `flatpak`, `dependencies` | `docs/build/` |
| `workflow` | `ci-cd`, `releases`, `branching` | `docs/workflow/` |
| `architecture` | `opengl`, `sdl3`, `imgui`, `camera` | `docs/architecture/` |
| `cross-cutting` | standards, process | `docs/` (flat, UPPERCASE filename) |

---

## YAML Frontmatter Template

Every `docs/` file MUST begin with this block:

```yaml
---
title: "Short Descriptive Title"
description: "One sentence describing exactly what this doc covers."
domain: testing
subdomain: unit-testing
tags: [testing, unit-testing, gtest, c++]
related:
  - "../TESTING_STANDARDS.md"
  - "integration-tests.md"
---
```

**Field rules:**
- `description` — the primary field for semantic (vector) search; make it specific and concrete
- `tags` — MUST include the domain and subdomain as the first two entries
- `related` — relative paths from the file's own directory; verified to exist before adding

**Cross-cutting standard files** (`docs/UPPERCASE.md`):
```yaml
---
title: "Testing Standards"
description: "AAA pattern, naming conventions, and coverage expectations for all Particle-Viewer tests."
domain: cross-cutting
subdomain: ""
tags: [testing, standards, gtest, aaa]
related:
  - "testing/unit-testing/naming.md"
  - "testing/visual-regression.md"
---
```

---

## Domain Guide Template

```markdown
---
title: "Concept Name"
description: "One concrete sentence about exactly what this covers."
domain: testing
subdomain: unit-testing
tags: [testing, unit-testing, gtest]
related:
  - "../TESTING_STANDARDS.md"
---

# Concept Name

Brief one-paragraph description. ≤600 words total for the full file.

## Overview

What it is and why it matters for this project.

## Usage

```cpp
// Concrete code example
TEST(ClassName, Action_ExpectedResult) {
    // Arrange
    // Act
    // Assert
}
```

## Rules

Numbered list of rules. Specific, concrete, no soft language.

## Related

- [Testing Standards](../TESTING_STANDARDS.md) — AAA pattern and naming conventions
- [Integration Tests](integration-tests.md) — multi-component test patterns
```

---

## Related Section Template

Every doc file MUST end with a `## Related` section:

```markdown
## Related

- [Link Text](relative/path.md) — one-line description of why it's related
- [Another Doc](../other.md) — one-line description
```

Rules:
- Use relative paths from the file's own directory
- Verify all paths exist before adding
- At least one link is required
- One-line descriptions are mandatory — naked links are not acceptable

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

## Copilot Skill File Template (SKILL.md)

Skills follow a strict 5-element anatomy. See the `writing-skills` skill for the full authoring standard.

Minimal structure:

```markdown
---
name: skill-name
description: Use when [triggering conditions only].
---

## Iron Law

​```
ALL CAPS RULE — NO EXCEPTIONS
​```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST [action]. No exceptions.

**Announce at start:** "I am using the [skill-name] skill to [purpose]."

---

## BEFORE PROCEEDING

1. [Condition]
2. [Condition]

✓ All met → proceed
✗ Any unmet → [specific required action]

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "[rationalization]" | [counter] |
```

Key rules:
- Minimize duplication — if another skill covers a topic, reference it with a one-line pointer
- `SKILL.md` contains workflow and rules only
- Heavy content, examples, and templates go in `references/`

---

## copilot-instructions.md Update Pattern

When adding a new skill, update these 4 locations in `copilot-instructions.md`:

```markdown
<!-- 1. Skills Directory table — add a row -->
| `skill-name` | `.github/skills/skill-name/` | Domain description |

<!-- 2. Before Every Response checklist — add if HARD-GATE trigger -->
8. **Unclear approach or design impact?** → HARD-GATE: load `brainstorming`...

<!-- 3. Minimum skill loads table — add the row -->
| Writing or editing a skill file | `writing-skills` |

<!-- 4. Instruction Priority Hierarchy — only if new priority tier -->
(usually no change needed)
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

## Type Reference Table Template

```markdown
| Type | Location | Purpose |
|------|----------|---------|
| `ClassName` | `src/File.hpp` | Brief description |
| `StructName` | `src/other/File.hpp` | Brief description |
```
