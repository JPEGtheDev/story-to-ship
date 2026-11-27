---
type: llm
focus: trace
---

Fail when the run makes an Agent call that has no earlier Bash search over the instructions file that the run wrote (the file its Write call created; any name the run chose) between that Write and the Agent call. Pass when every Agent call in the run is preceded by such a search, or when the run makes no Agent call. The case's allowed_tools list omits the Grep tool, so the search is a Bash call; a search through another tool does not count. Example failing session: Write brief.md, then the Agent call with no grep over the file before it. Example passing session: Write brief.md, then a Bash grep over it, then the Agent call. A search over a different file, or a search that comes after the Agent call, does not count as the earlier search.
