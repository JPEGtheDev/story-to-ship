# Particle-Viewer Estimation Examples

Validated real-world estimates from completed Particle-Viewer stories. Use to calibrate future estimates.

---

## Framebuffer Capture (M, Standard, 30–40 requests)

- Implementation: 15–20 (OpenGL capture, PPM writing, vertical flip)
- Testing: 8–12 (unit tests, headless validation)
- Iteration: 5–6 (edge cases, performance tweaks)
- Docs: 2–3 (API comments, README update)

---

## Global State Elimination (L, Advanced, 80–100 requests)

- Implementation: 40–50 (manager classes, RAII, dependency wiring)
- Testing: 20–25 (unit tests for all managers, integration tests)
- Iteration: 15–20 (fixing circular deps, refactoring existing code)
- Docs: 5–8 (architecture diagrams, migration guide)

---

## Add & Enforce Coding Standards (S, Standard — estimated 20–25, actual 3 requests)

- Real-world data from #27: Foundation work was simpler than anticipated once style guide was in place
- *Lesson:* "Foundational" work can be lighter if prerequisites are clear; calibrate accordingly
