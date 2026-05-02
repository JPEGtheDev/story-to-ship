# Pipeline Reference -- Summarization Dispatch Instructions

Detailed per-agent prompt structure for the 6-agent summarization pipeline.

---

## Agents 1-3: Parallel Method Agents

Dispatch three `general-purpose` agents simultaneously via the `task` tool.

**Each agent receives:**
- Full source content (paste inline in the prompt -- do not pass a file path)
- Full method instructions from the relevant reference file (read and inline):
  - Abstractive agent: contents of `references/ABSTRACTIVE_METHOD.md`
  - Extractive agent: contents of `references/EXTRACTIVE_METHOD.md`
  - SAAC agent: contents of `references/SAAC_METHOD.md`

**Each agent returns:** A single method summary in the format defined by its reference file.

**Partial failure handling:**
- 1 of 3 agents fails -> proceed to synthesizer; synthesizer notes the missing method in the article
- 2 or more fail -> halt; report "BLOCKED: [N] method agents failed. Cannot synthesize."

---

## Agent 4: Synthesizer

Dispatch using `.github/agents/synthesizer.md` after all three method agents return.

Fill every `{{VARIABLE}}` slot:

| Variable | Value |
|----------|-------|
| `{{SOURCE_TITLE}}` | Title of the source (derive from content if not given) |
| `{{SOURCE_CONTENT}}` | Full source text |
| `{{ABSTRACTIVE_SUMMARY}}` | Output from Agent 1 |
| `{{EXTRACTIVE_SUMMARY}}` | Output from Agent 2 |
| `{{SAAC_SUMMARY}}` | Output from Agent 3 |
| `{{TEMP_PATH}}` | `scratch/summaries/temp-[kebab-source-title].md` |
| `{{OUTPUT_PATH}}` | Resolved output path, or `ASK_USER` if not yet determined |

The synthesizer writes the article to `{{TEMP_PATH}}` first. Dispatch the claim enrichment agent immediately after.

---

## Agent 5: Claim Enrichment

Dispatch using `.github/agents/claim-enrichment.md` after the synthesizer returns.

Fill every `{{VARIABLE}}` slot:

| Variable | Value |
|----------|-------|
| `{{SOURCE_CONTENT}}` | Full source text |
| `{{SYNTHESIZED_ARTICLE}}` | Full content returned by the synthesizer |
| `{{TEMP_PATH}}` | Same temp path used by synthesizer (agent overwrites it) |

The claim enrichment agent identifies every analytical claim that goes beyond the source, evaluates whether each is noteworthy (connects source concepts, surfaces a unifying principle, aids comprehension), keeps noteworthy claims with explicit framing (`> **Synthesis:** ...`), and removes claims that are unsupported or add no value.

After the enrichment agent reports, report the temp path to the user. They can review the enriched file while the quality agent runs in parallel.

---

## Agent 6: Quality Evaluator

Dispatch using `.github/agents/summarization-quality.md`. Can be dispatched in parallel with notifying the user of the temp path -- they do not need to be sequential.

Fill every `{{VARIABLE}}` slot:

| Variable | Value |
|----------|-------|
| `{{SOURCE_CONTENT}}` | Full source text |
| `{{SYNTHESIZED_ARTICLE}}` | Full content of the enriched temp file (after Agent 5) |
| `{{OUTPUT_PATH}}` | Resolved output path (must be known before quality writes) |
| `{{TEMP_PATH}}` | Same temp path used by synthesizer |

**If `{{OUTPUT_PATH}}` is `ASK_USER`:** Ask the user for the directory before dispatching the quality agent. Auto-derive the filename from `{{SOURCE_TITLE}}` (kebab-case + `.md`).

---

## Output Path Resolution

| Situation | Resolution |
|-----------|-----------|
| User provided explicit full path | Use it verbatim |
| User provided directory, no filename | `[directory]/[kebab-source-title].md` |
| No path provided | Ask for directory after temp file is written; auto-derive filename |

Derivation rule: "Test Frameworks Overview" -> `test-frameworks-overview.md`
