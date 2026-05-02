# C++ HeisenBug Patterns

A HeisenBug is a bug that disappears or changes behavior when you attempt to observe or isolate it. In C++, several mechanisms cause this. Work through the table when a bug vanishes under investigation.

---

## HeisenBug Patterns

| Cause | Symptom | Investigation action |
|-------|---------|---------------------|
| Uninitialized variable | Zero in debug builds (compilers zero-initialize stack in debug mode), garbage in release | Explicitly initialize all variables. Run with address sanitizer (`-fsanitize=address,undefined`). |
| `assert(x = 5)` single-equals trap | Assignment inside `assert` executes in debug, but the entire expression is removed in release (`NDEBUG`) | Audit every `assert` statement for `=` vs `==`. |
| Stack padding | Buffer overflow corrupts neighbor data in release, but is absorbed by debug padding | Run with address sanitizer. Never rely on stack layout. |
| Debugger timing | Race condition disappears because step-through execution serializes threads | Test without the debugger attached. Use thread sanitizer (`-fsanitize=thread`). |
| Compiler optimization | Undefined behavior that is visible at `-O0` is legally optimized away at `-O2` | Compare debug vs release. Run with undefined behavior sanitizer (`-fsanitize=undefined`). |
| Logging/tracing changes timing | A log statement adds a memory barrier or slows execution enough to change a race | Remove logs before final diagnosis. |
| Exception path masks crash | A `catch` block swallows the real fault location | Check exception handler coverage. Add specific re-throw or logging at catch boundaries. |

---

## HeisenBug Investigation Checklist

Before declaring "the bug disappeared":

- [ ] Compare debug vs release build behavior: `cmake -DCMAKE_BUILD_TYPE=Debug` vs `Release`
- [ ] Audit every `assert` for `=` (assignment) vs `==` (comparison)
- [ ] Compile with sanitizers: `-fsanitize=address,undefined` — does the bug surface?
- [ ] If a threading issue: run with thread sanitizer (`-fsanitize=thread`)
- [ ] Test without the debugger attached — run the binary directly
- [ ] Compile with `-O2` and `-O0` — does behavior differ between the two?
- [ ] Check for uninitialized variables: `-Wuninitialized -Wall -Wextra`

A bug that only reproduces in one build mode is a real bug with a real root cause. The difference in behavior is evidence — use it.
