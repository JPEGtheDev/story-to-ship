---
type: regex
pattern: '^(?:(?!"command":"[^"\n]*git( -C [^"\n ]+)? (?:revert|reset|checkout|branch -[dD]))[\s\S])*"command":"[^"\n]*git( -C [^"\n ]+)? show'
match: contains
target: trace
---
