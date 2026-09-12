# Agent Templates Index

Find the row whose Use-when matches the todo and dispatch that template (per BEFORE
PROCEEDING item 4 in `../SKILL.md`); if no row matches, the General-purpose dispatch rule
in `MODEL_SELECTION.md` applies. The Model column is each template's frontmatter `model:`
pin, which is the value the dispatch actually uses (all 17 are `sonnet` today; a future
non-sonnet pin shows here). CI checks every row against `agents/` by exact string match, so
a template description or model change is made in the template frontmatter first and then
mirrored in the row.

| Template | Use when | Model |
|----------|----------|-------|
| `amigo.md` | Use when dispatching a Three Amigos ceremony participant. | sonnet |
| `architecture-reviewer.md` | Use when reviewing a changed file against architecture and design principles (YAGNI, Clean Architecture, Clean Code, Deferred Decisions, Golden Hammer). | sonnet |
| `claim-enrichment.md` | Use when evaluating and enriching analytical claims in a synthesized summary article before quality validation. | sonnet |
| `code-quality-reviewer.md` | Use for Stage 2 post-todo review after Stage 1 passes to check code quality and standards. | sonnet |
| `explorer.md` | Use for read-only multi-file research to answer specific questions. | sonnet |
| `implementer.md` | Use when implementing a feature task in a git worktree. | sonnet |
| `infrastructure-reviewer.md` | Use for per-file CI/CD, reproducible build, and sandboxed/packaging compliance review. | sonnet |
| `plan-reviewer.md` | Use when reviewing a plan for soundness, sequencing, and enforceability before implementation begins. | sonnet |
| `postmortem-reviewer.md` | Use when reviewing a completed agent session retrospective. | sonnet |
| `rehearsal-subject.md` | Use when an agent must act as the coordinator under test in a behavioral rehearsal of skill or agent text. | sonnet |
| `researcher.md` | Use when empirically confirming or denying a hypothesis. | sonnet |
| `skeptic.md` | Use when reviewing a plan for gaps before implementation begins. | sonnet |
| `skill-reviewer.md` | Use when auditing a single skill file against writing-skills criteria. | sonnet |
| `spec-compliance-reviewer.md` | Use for Stage 1 post-todo review to verify implementation matches spec. | sonnet |
| `summarization-method.md` | Use when running one summarization method (Abstractive, Extractive, or SAAC) over an injected source. | sonnet |
| `summarization-quality.md` | Use when evaluating a synthesized summary article for faithfulness, completeness, and actionability. | sonnet |
| `synthesizer.md` | Use when synthesizing three parallel method summaries (Abstractive, Extractive, SAAC) into a final Markdown article. | sonnet |

## Related

- [SKILL.md](../SKILL.md) -- BEFORE PROCEEDING item 4 (use a template when one exists)
- [MODEL_SELECTION.md](MODEL_SELECTION.md) -- tier table and the General-purpose dispatch rule
