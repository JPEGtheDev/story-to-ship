---
name: user-story-estimation
license: MIT
description: Use when estimating effort, premium request counts, or model tier selection for user stories or agent dispatches.
---

## Iron Law

```
YOU MUST INCLUDE AN EFFORT ESTIMATE AND MODEL RECOMMENDATION IN EVERY STORY.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the user-story-estimation skill to estimate effort for [story name]."

---

# Instructions for Agent

## When to Load This Skill

Load this skill when:
- Generating a story (called automatically from `user-story-generator`)
- User asks "how many requests will this take?"
- Deciding between Small/Standard/Advanced model for an agent dispatch

---

## Effort Estimate Block (Required in Every Story)

Every generated story must include this section:

```markdown
## Effort Estimate

**Total Premium Requests:** [Range, e.g., 30-40]
**Recommended Model Tier:** [Small | Standard | Advanced]
**Reasoning:** [One sentence explaining complexity level]
```

---

## Premium Request Estimation Guidelines

### Small (S) — 15–30 requests
- Single file/class creation
- Simple utilities or helpers
- Basic configuration files
- Bug fixes with clear root cause
- Examples: Image format converter, config parser

### Medium (M) — 30–70 requests
- Multi-file features
- Moderate integration work
- Test suite creation
- CI/CD workflow setup
- Examples: Pixel comparator, GitHub Actions workflow, unit test suite

### Large (L) — 70–120+ requests
- Major architectural changes
- Cross-cutting refactoring
- Complex integration across multiple subsystems
- Deep dependency changes
- Examples: Global state elimination, layer separation, dependency injection

### Factors that increase estimates
- Complex algorithms or math
- Need for mocking/abstraction layers
- Tight integration with external APIs
- Performance optimization requirements
- Legacy code refactoring with unclear dependencies

---

## Model Selection Guidelines

| Tier | Tasks | When |
|------|-------|------|
| **Small (Lightweight)** | Simple, well-defined tasks; clear examples; basic file operations | Speed and minimal context needed |
| **Standard (Mid-level)** | Standard implementation; moderate complexity; tests, CI/CD, features | Balanced complexity and context understanding |
| **Advanced (Deep-reasoning)** | Architectural decisions; deep refactoring; cross-subsystem integration; novel design | Deep reasoning and architecture-level decisions needed |

---

## Estimation Formula

| Component | % of Total |
|-----------|-----------|
| Base implementation | 40–60% |
| Testing and validation | 20–30% |
| Iteration and fixes | 15–25% |
| Documentation | 5–10% |

---

## Validated Example Estimates

For real-world Particle-Viewer estimates (Framebuffer Capture, Global State Elimination, Coding Standards), see `references/PV_ESTIMATION_EXAMPLES.md`.

---

## Red Flags — STOP

- Generating a story without an effort estimate section
- "I'll add the estimate later" — add it now
- Recommending Advanced model for a clearly mechanical task
- Estimate range exceeds 50 requests for an S-sized story — recategorize as M
- Dispatching a premium agent for a task clearly scoped as XS or S

---

## BEFORE PROCEEDING

- [ ] The story has been validated against INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable)
- [ ] All unknowns are identified and noted in the estimate
- [ ] The task breakdown reflects the actual work, not a best-case scenario
- [ ] All skill dispatches needed have been identified
- [ ] If the story requires >3 agents, the Wave structure has been accounted for

✓ All met → commit to the estimate
✗ Any unmet → resolve unknowns and recheck INVEST compliance before estimating

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Estimates are just guesses anyway" | Calibrated estimates improve sprint planning; validated examples improve calibration |
| "The model tier doesn't matter that much" | Wrong tier wastes budget or loses quality on critical tasks |
| "I'll estimate after implementation" | Pre-estimation exposes scope uncertainty before it causes overruns |
| "The story is straightforward, premium model isn't needed" | Story complexity is not always visible at estimation time. Use the model tier the standard prescribes for the story size. |
| "I'll update the estimate after starting" | Estimates set expectations. Changing them mid-task without communication breaks trust. Revise estimates before beginning, not during. |
