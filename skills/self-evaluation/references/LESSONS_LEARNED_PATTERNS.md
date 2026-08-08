# Lessons Learned Patterns

Concrete examples of lessons captured from past sessions and how they were incorporated into project skills.

Project-specific war stories have been moved to their source project's own `docs/lessons-learned.md`
so this harness-level file stays project-agnostic. Where a project-specific entry captured a lesson
worth keeping here, a genericized distillation is kept below in its place -- the full original
story lives in the source project's doc.

---

## Code Quality Lessons

### Open Binary Data Files in Binary Mode

**Rule:** Always open binary data files with binary mode (`"rb"`/`"wb"`), never text mode (`"r"`/`"w"`).

**Why:** Text mode silently translates line-ending bytes on some platforms, corrupting binary reads/writes. The corruption is platform-dependent, so it will not reproduce on every OS a developer tests on.

### Return Large Stored Objects by Const Reference

**Rule:** When a getter returns a large object (matrix, vector, struct) that is already stored as a member, return it by `const&` instead of by value.

**Why:** Returning by value copies the object on every call. In a hot path (a render loop, a per-frame update), that copy cost compounds silently and is easy to miss in a code review that only checks correctness, not allocation/copy cost.

---

## Testing Lessons

### Separate Act and Assert (PR #64)

**Problem:** Tests combined `// Act & Assert` phases, making failures harder to diagnose.

**Lesson:** Always keep Act and Assert as separate phases, even when they seem naturally combined.

**Added to:** `testing` skill -> Critical Rules, `TESTING_EXAMPLES.md` -> Incorrect Examples

### Ensure Output Directories Exist Before Writing

**Rule:** In test setup (or any code that writes output files), create every directory the code writes to -- not only the ones already known to exist -- and check the write/save call's return value instead of assuming success.

**Why:** A missing output directory causes a silent write failure. Without checking the return value, the test (or the run) reports success while no artifact was actually produced -- the failure only surfaces later, far from its cause.

### Binary Seek Tests Need N+1 Records to Reach the Target Offset

**Rule:** When testing that a function seeks to record N in a binary file, the test fixture must contain at least N+1 records. A fixture with only N records makes the seek land past end-of-file, exercising the truncation/EOF branch instead of the intended read branch.

**Why:** An EOF-truncation short read and a successful record read can produce the same failure signature at the assertion level -- the test silently verifies the wrong code path and passes for the wrong reason.

---

## Code Formatting and Verification Lessons

### Silent Tool Output Is Not Proof of Success

**Rule:** Never interpret "no output" from a dry-run or check command as "nothing to fix." After any formatting or lint pass: (1) run the mutating form and inspect the actual diff, (2) spot-check the diff for patterns the tool is known not to catch, (3) only then trust a clean dry-run result.

**Why:** Some tool invocations exit clean without ever checking for the class of issue that matters -- silence means "no reported problem," not "verified clean."

---

## Process Lessons

### Fix Naming/Categorization Issues at the Source, Not in the Checker

**Rule:** When an automated check misclassifies output because of a naming or format mismatch, fix the producer's naming convention -- do not loosen the checker's pattern to accommodate the deviation.

**Why:** A checker's pattern exists to enforce a convention. Expanding the pattern to match every deviation instead of fixing the deviation erodes the convention until the check no longer means anything.

### Don't Modify README Unless Asked (PR #64)

**Problem:** Agent added visual regression testing docs to README, which wasn't requested.

**Lesson:** Don't update README unless specifically asked by the user.

### Skills Should Cross-Reference (PR #64)

**Problem:** Testing skill duplicated CI pipeline rules from workflow skill.

**Lesson:** Minimize duplication across skills. Each skill owns one domain. Skills reference other skills instead of repeating content.

**Added to:** `AGENTS.md` -> Skill Architecture section

### Do Not Delete a Stable API Method When Only Its Caller Is Removed

**Rule:** When removing a call site (e.g., a feature toggled off by user preference), do not also delete the API method it called -- unless the method is architecturally wrong or duplicates something else. Remove a method because it is structurally incorrect, not merely because it currently has zero callers.

**Why:** Call sites driven by preference or feature flags are volatile and often come back. The underlying API is comparatively stable. Deleting the method on a temporary caller removal creates unnecessary rework the next time the caller returns.

### Worktree `../` Relative Path Creates Sibling Outside Repo (Metaballs session)

**Problem:** Three amigo worktrees were created with `git worktree add ../amigo-refinement-*`. From `[repo-root]`, `../` resolves to the parent directory, placing the worktrees at `[repo-root]/../amigo-refinement-*`. Agent prompts were given a path one level up from the actual location. All three amigos returned BLOCKED -- the path didn't exist at the specified location.

**Lesson:** Never use `../` relative paths with `git worktree add`. Always use `.worktrees/agent-<name>` (inside the repo, gitignored). The `.worktrees/` convention makes absolute paths predictable: `<repo_root>/.worktrees/<name>`. `../` paths land at a depth dependent on the current working directory, which is easy to get wrong when constructing agent prompt absolute paths.

**Added to:** `using-git-worktrees` skill -> Red Flags section

---

## Quick Reference: Where to Add Lessons

Use this for fast question-based lookup -- "my lesson is about X, where does it go?" For formal classification with concrete examples, use the Category Classification Table below.

| If the lesson is about... | Add to... |
|---|---|
| Code patterns, naming, error handling | `AGENTS.md` |
| Test writing, Arrange-Act-Assert (AAA), mocking, visual regression | `testing` skill |
| CI/CD workflows, artifacts, permissions | `workflow` skill |
| Documentation format, linking, content | `documentation` skill |
| User story creation, estimation | `user-story-generator` skill |
| Meta/process (skill creation, evaluation) | `self-evaluation` skill |

---

## Category Classification Table

Use this when classifying a captured lesson into a skill update. The Examples column gives concrete signals for each category.

| Category | Examples | Update Target |
|----------|----------|---------------|
| **Code quality** | Binary file modes, const refs, resource cleanup | `code-quality` skill |
| **Testing** | AAA violations, missing directory setup, save checks | `testing` skill |
| **CI/CD** | Workflow structure, artifact patterns | `workflow` skill |
| **Documentation** | Link fixes, formatting, content standards | `documentation` skill |
| **Versioning** | PR title format, commit conventions, releases | `versioning` skill |


---

## Objectivity Block -- Why Structural Mechanisms Beat "Try Harder"

Humans are structurally poor at evaluating their own work. This is not a character flaw -- it is an architectural constraint of cognition. The response is not "try harder to be objective" but "use structural mechanisms that bypass the block":

- Dispatch a separate reviewer agent rather than self-reviewing
- Compare against requirements written before the work began, not a remembered version
- Use a checklist created before the session, not reconstructed from memory after it

The self-evaluation block itself is imperfect by construction. Use it to surface what you can, knowing that a separate postmortem reviewer will catch what you cannot. Source: C2 Wiki "HumansAreLousyAtSelfEvaluation".

---

## Skill Authoring Lessons

### Wrong Anatomy Red Flag Propagates to All Reviews (PR #16)

**Problem:** A new Red Flag added to `writing-skills/SKILL.md` claimed the Iron Law letter/spirit line MUST be INSIDE the backtick block. The canonical schema in `SKILL_ANATOMY_ELEMENTS.md` shows it OUTSIDE. Three internal skill reviewers all returned PASS because they were validating against the wrong Red Flag. The error was caught only by a Copilot review of the PR.

**Lesson:** When a Red Flag in `writing-skills` makes a format assertion ("MUST be inside/outside X"), that Red Flag becomes the schema all future skill reviewers validate against. A wrong Red Flag propagates the error to every review until caught. Before writing any Red Flag about anatomy format: (1) read `SKILL_ANATOMY_ELEMENTS.md`, (2) cite the specific line, (3) verify the claim matches the canonical example.

**Added to:** `writing-skills` BEFORE PROCEEDING item 5 -- extended to cover "adding a Red Flag about anatomy format" and require canonical citation for format assertions.
