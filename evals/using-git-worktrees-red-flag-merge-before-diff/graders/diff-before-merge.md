---
type: regex
pattern: '^(?:(?!git[^"\n]*(?:merge|cherry-pick)[^"\n]*agent/row-export)[\s\S])*git[^"\n]*diff(?![^"\n]*--stat)[^"\n]*\.\.\.[^"\n]*agent/row-export'
match: contains
target: trace
---
