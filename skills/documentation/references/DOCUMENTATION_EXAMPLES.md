# Documentation Examples and Templates

This reference provides templates and examples for writing documentation in projects using the story-to-ship plugin.

---

## Domain Taxonomy

Define your domains using Domain-Driven Design (DDD) Bounded Contexts: one directory per team concern, one vocabulary per directory.

**How to define your taxonomy:**
1. Identify your top-level bounded contexts (e.g., `payments`, `catalog`, `delivery`). Each becomes a `docs/<domain>/` directory.
2. Within each context, identify subdomains -- cohesive sub-concerns that share terminology. Each becomes `docs/<domain>/<subdomain>/`.
3. When a subdomain needs further splitting, add a third level: `docs/<domain>/<subdomain>/<subdomain2>/`. Use sparingly -- three levels is the maximum.
4. Cross-cutting concerns (standards that apply across domains) go at `docs/UPPERCASE.md` as flat files.

**Example structure (replace with your actual bounded contexts):**

| Level | Example Path | Purpose |
|-------|-------------|---------|
| Domain | `docs/payments/` | Payments bounded context |
| Subdomain | `docs/payments/invoicing/` | Invoicing sub-concern |
| Sub-subdomain | `docs/payments/invoicing/disputes/` | Dispute resolution patterns (use only when a subdomain is too broad) |
| Cross-cutting | `docs/PAYMENTS_STANDARDS.md` | Standards that apply across all payments docs |

---

## YAML Frontmatter Template

Every `docs/` file MUST begin with this block:

```yaml
---
title: "Short Descriptive Title"
description: "One sentence describing exactly what this doc covers."
domain: <domain>
subdomain: <subdomain>
tags: [<domain>, <subdomain>, <additional-tags>]
related:
  - "../RELATED_DOC.md"
---
```

**Field rules:**
- `description` -- the primary field for semantic (vector) search; make it specific and concrete
- `tags` -- MUST include the domain and subdomain as the first two entries
- `related` -- relative paths from the file's own directory; verified to exist before adding
- `subdomain2` -- omit this field entirely when not using a third level. Do NOT write `subdomain2: ""`. Only add it when a value exists: `subdomain2: <value>`

**Cross-cutting standard files** (`docs/UPPERCASE.md`):
```yaml
---
title: "Standards Title"
description: "One sentence describing the standards this file defines and what domains it covers."
domain: cross-cutting
tags: [<domain>, standards, <additional-tags>]
related:
  - "<domain>/<subdomain>/concept.md"
---
```

---

## Domain Guide Template

```markdown
---
title: "Concept Name"
description: "One concrete sentence about exactly what this covers."
domain: <domain>
subdomain: <subdomain>
tags: [<domain>, <subdomain>]
related:
  - "../RELATED_STANDARDS.md"
---

# Concept Name

Brief one-paragraph description. <=800 tokens total for the full file.

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

- [Testing Standards](../TESTING_STANDARDS.md) -- AAA pattern and naming conventions
- [Integration Tests](integration-tests.md) -- multi-component test patterns
```

---

## Related Section Template

Every doc file MUST end with a `## Related` section:

```markdown
## Related

- [Link Text](relative/path.md) -- one-line description of why it's related
- [Another Doc](../other.md) -- one-line description
```

Rules:
- Use relative paths from the file's own directory
- Verify all paths exist before adding
- At least one link is required
- One-line descriptions are mandatory -- naked links are not acceptable

---

## Relative Link Examples

### From `docs/<domain>/<subdomain>/concept.md` (guide inside a subdomain directory):

```markdown
<!-- [+] Correct: relative path from docs/<domain>/<subdomain>/ to docs/ -->
See [Standards Doc](../../STANDARDS_DOC.md) for details.

<!-- [-] Incorrect: one level short -->
See [Standards Doc](../STANDARDS_DOC.md) for details.
```

### From `docs/CROSS_CUTTING_STANDARDS.md` (root cross-cutting file):

```markdown
<!-- [+] Correct: same directory -->
See [Other Standards](OTHER_STANDARDS.md) for additional conventions.

<!-- [+] Correct: subdirectory -->
See [Subdomain Guide](<domain>/<subdomain>/concept.md) for domain-specific patterns.
```

---

## Copilot Skill File Template (SKILL.md)

Skills follow a strict 5-element anatomy. See the `writing-skills` skill for the full authoring standard.

Minimal structure:

````markdown
---
name: skill-name
description: Use when [triggering conditions only].
---

## Iron Law

```
ALL CAPS RULE -- NO EXCEPTIONS
YOU MUST [action]. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the [skill-name] skill to [purpose]."

---

## BEFORE PROCEEDING

1. [Condition]
2. [Condition]

[+] All met -> proceed
[-] Any unmet -> [specific required action]

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "[rationalization]" | [counter] |
````

Key rules:
- Minimize duplication -- if another skill covers a topic, reference it with a one-line pointer
- `SKILL.md` contains process steps and rules only
- Heavy content, examples, and templates go in `references/`

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
