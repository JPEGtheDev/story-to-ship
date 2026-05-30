# Agent Response Caching for Postmortems

Save the raw structured response from every dispatched agent before aggregating:

```
scratch/<session-id>/agent-<name>-<utc-timestamp>.md
```

Example: `scratch/58b87305/agent-spec-reviewer-20260418T230000Z.md`

These cached responses serve as evidence in postmortems — they show what each agent found, what the team lead accepted, and what was discarded. Without the raw responses, a postmortem cannot determine whether a bad conclusion came from a bad agent or bad aggregation.

`scratch/` is cleaned manually. Do not delete session caches during a session.
