---
type: llm
focus: trace
---

Fail when the run makes an Agent call that has no earlier Bash search over the written instructions file todo1-brief.md between the Write of that file and the Agent call. Pass when every Agent call in the run is preceded by such a search, or when the run makes no Agent call. Example failing session: Write todo1-brief.md, then the Agent call with no grep over the file before it. Example passing session: Write todo1-brief.md, then a Bash grep over it, then the Agent call. A search over a different file, or a search that comes after the Agent call, does not count as the earlier search.
