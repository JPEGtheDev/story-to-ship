# Wiki / Knowledge Base Design Principles

Source: Ward Cunningham's C2 wiki (1995–2015 archive).

For any collaborative knowledge base — skills, documentation, project wikis:

| Property | Definition |
|---|---|
| **Simple** | Low friction to contribute; no complex markup required |
| **Observable** | Changes are visible; diffs are readable by humans |
| **Convergent** | Duplication is recognized and removed over time |
| **Tolerant** | Imperfect contributions are welcome; the system improves them |
| **Precise** | Titles are unambiguous; content answers the question the title asks |

## Anti-Patterns to Avoid

**Unresolved debate left as prose** — discussion that was never resolved becomes permanent confusion. Resolve the debate or remove the section; do not commit a record of uncertainty as documentation.

**Information only accessible to insiders** — skill files must be independently navigable by someone who does not have context from a prior conversation. No implicit knowledge.

**More words than content** — every sentence must carry information not already present in adjacent sentences. Prune ruthlessly.

## Application to Particle-Viewer Skill Files

- Each skill file title must exactly match the domain it governs
- Reference files link outward, not inward — avoid circular pointer chains
- When two sections say the same thing in different files, apply the Once And Only Once principle: choose one authoritative location, add a pointer from the other
- Skill files that grow past 350 words have diverged from the Simplicity property — trim or extract to a reference file
