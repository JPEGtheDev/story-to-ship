# Abstractive Summarization Method

## What It Is

Abstractive summarization generates **new prose** that captures the core meaning of the source. It does not quote or lift text verbatim. The output reads like a knowledgeable person explaining the source in their own words -- concise, accurate, and original.

## Rules

1. **No verbatim copying.** Every sentence must be original. If a source phrase is too precise to rewrite without losing meaning, attribute it explicitly with quotation marks -- do not silently lift it.
2. **Capture core meaning, not surface structure.** Do not follow the source's section order if a different structure communicates more clearly.
3. **Compress without omitting key concepts.** The output should be materially shorter than the source while retaining every idea that matters.
4. **No new claims.** Do not introduce facts, interpretations, or conclusions that are not supported by the source. Paraphrase only what is there.
5. **Preserve nuance.** If the source is uncertain, hedged, or qualified, the abstractive summary must reflect that. Do not flatten complexity into false certainty.

## Length Guidance

Output length is a soft target. Slightly longer output is preferable to omitting a key concept.

| Source length | Target output |
|--------------|--------------|
| Short (< 1,000 words) | 20-25% of source word count |
| Medium (1,000-3,000 words) | 15-20% of source word count |
| Long (> 3,000 words) | 10-15% of source word count |

## Output Format

Return a single Markdown section with this structure:

```markdown
## Abstractive Summary

[2-5 paragraphs of original prose. Each paragraph covers one major theme or idea from the source. No bullet points. No headings within the section. No verbatim source text.]
```

## Quality Signals

- A good abstractive summary can be read without the source and still be understood.
- A bad abstractive summary is a lightly reworded version of the source with the same sentence structure.
- If you find yourself copying sentence structure while changing only nouns and verbs, stop and rewrite from meaning, not form.
