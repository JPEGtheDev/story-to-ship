---
title: "greenfield-bootstrap References Index"
description: "Index of reference files for the greenfield-bootstrap skill -- one file per stack with scaffold files, ignore entries, workflow steps and run commands for seven stacks, plus a shared file with the tokens, language mapping, README, smoke workflow and issue templates."
domain: skills
subdomain: greenfield-bootstrap
tags: [skills, greenfield-bootstrap, references, index]
related:
  - "../SKILL.md"
---

# greenfield-bootstrap References Index

The skill procedure in SKILL.md cites a reference file for every literal value it writes into a new project: one shared file, plus one file for the chosen stack.

---

| File | Covers |
|------|--------|
| `SHARED_TEMPLATES.md` | Tokens, the Language-value mapping (which names each stack file), the action versions, and the `## Shared:` templates for README.md, .gitignore, smoke.yml and the three issue templates. |
| `stacks/python.md` | The `## Stack: Python` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |
| `stacks/typescript-node.md` | The `## Stack: TypeScript/Node.js` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |
| `stacks/rust.md` | The `## Stack: Rust` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |
| `stacks/go.md` | The `## Stack: Go` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |
| `stacks/csharp.md` | The `## Stack: C#` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |
| `stacks/cpp.md` | The `## Stack: C++` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |
| `stacks/c-embedded.md` | The `## Stack: C/embedded C` section: toolchain probe, hello world files, ignore entries, smoke workflow steps and local-run commands. |

---

## Related

- [SKILL.md](../SKILL.md) -- procedure and gates that cite this reference
- The `greenfield-discovery` skill produces the `## Domain Model` block this skill reads; the `greenfield-architecture` skill produces the `## Architecture Decision` block it reads.
