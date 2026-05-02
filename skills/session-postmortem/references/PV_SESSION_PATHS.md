# PV Session Paths

Path conventions for reviewing Particle-Viewer postmortem sessions.
All paths are relative to the git root of the Particle-Viewer repository.

```
REPO:             [git root of Particle-Viewer]
SESSION_ID:       [session ID — shown in workspace.yaml or .copilot/session-state/ directory name]
EVENTS_LOG:       [SESSION_ID]/events.jsonl
WORKSPACE:        [SESSION_ID]/
SCRATCH:          [REPO]/scratch/
SELF_ASSESSMENT:  [SESSION_ID]/postmortem.md  (if self-eval already ran)
OUTPUT:           [SESSION_ID]/postmortem-external.md
```

The `scratch/` directory contains session artifacts written during the session
(intermediate analysis, theory-testing files, research dumps). It is `.gitignored`
but may contain evidence of exploratory work not captured in the event log.
