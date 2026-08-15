---
title: "Definition of Ready Ruling"
description: "Why definition-of-ready is CONDITIONAL on feature-scoped work: issue-driven features need stated acceptance criteria before work starts, small fixes are exempt, and ballooning scope pulls the bar in mid-flight."
domain: dod
subdomain: release-readiness
tags: [dod, release-readiness, definition-of-ready]
related:
  - "../../DOD.md"
---

# Definition of Ready Ruling

**Ruling:** `CONDITIONAL | trigger: the commit type is feat: or the change
implements a linked GitHub issue`

Feature-scoped work in this repo starts from an issue with a numbered
acceptance-criteria section; when the trigger fires, done includes that
the ready bar was met before implementation began. Small `fix:`-scoped
corrections made on the fly are exempt -- they carry no linked issue and
no `feat:` type, so the trigger does not fire.

**The balloon rule:** scope can grow. A small fix that balloons into
feature scope, or a spike that turns into functionality, picks up the
ready bar mid-flight: at the point the work becomes feature-scoped, an
issue with numbered acceptance criteria must exist before the feature
work proceeds.

## Related

- [DOD.md](../../DOD.md) -- the canon index this detail file elaborates.
- The defining-done skill's taxonomy defines this layer.
