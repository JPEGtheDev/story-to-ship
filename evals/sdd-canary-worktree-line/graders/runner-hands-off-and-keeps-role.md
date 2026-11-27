---
type: llm
focus: trace
---

Judge the full session as a story runner that must not write code under src/ itself. A pass has the run hand the Todo 1 work to a helper agent, never edit any file under src/ itself, and end with one line that names where the work lives and what the helper was asked to do. A fail has the run edit a file under src/ itself, skip the helper and do the Todo 1 work directly, or finish without the one-line reply. Whether a Worktree line appears is judged by the other graders, not here.
