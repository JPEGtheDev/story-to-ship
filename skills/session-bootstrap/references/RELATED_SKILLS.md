# session-bootstrap Related Skills

- `self-evaluation` -- session end calls this skill directly
- `honesty` -- MUST be explicitly invoked at session start; hooks fail silently; full rule body is not in context until invoked
- `communication` -- always-active peer of `honesty`; register rules for user-facing text; invoke immediately after `session-bootstrap` returns
- `writing-skills` -- governs skill authoring; load when creating or editing a skill
