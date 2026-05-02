# Extractive Summarization Method

## What It Is

Extractive summarization identifies and **lifts the most important passages verbatim** from the source. Nothing is paraphrased or rewritten. The output is a curated selection of the source's own words, selected for maximum informational density.

## Rules

1. **Verbatim only.** Copy text exactly as it appears in the source. Do not alter wording, fix grammar, or modernize phrasing.
2. **Never paraphrase.** If a passage is too long to lift in full, select the most essential sentence or clause within it -- do not summarize it.
3. **Select for density.** Prefer passages that carry a complete idea in few words. Skip filler, transitions, and rhetorical framing that adds no information.
4. **Cite location when possible.** If the source has sections, headings, or paragraph numbers, note where the passage was found.
5. **Quantity guideline (soft cap):** Select the minimum number of passages needed to cover every distinct major claim. Add a passage beyond the cap only if it is not implied by another selected passage.

| Source length | Target passage count |
|--------------|----------------------|
| Short (< 1,000 words) | 3-5 passages |
| Medium (1,000-3,000 words) | 5-8 passages |
| Long (> 3,000 words) | 7-10 passages |

## Output Format

Return a single Markdown section with this structure:

```markdown
## Extractive Summary

> "[Exact verbatim passage from source]"
> -- [Section or location in source, if identifiable]

> "[Next passage]"
> -- [Location]
```

Each passage is a separate blockquote. No commentary between passages. No paraphrase. Attribution line uses `--` (not an emdash).

## Quality Signals

- A good extractive summary reads like the source's highlights reel -- every quote could stand alone.
- A bad extractive summary lifts obvious topic sentences and misses the denser, more specific claims.
- If two passages say the same thing in different words, keep only the more precise one.
