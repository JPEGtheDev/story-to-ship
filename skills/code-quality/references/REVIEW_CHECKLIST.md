# Pre-Review Checklist

- [ ] `clang-format -i` run on all changed files
- [ ] `clang-format --dry-run -Werror` passes
- [ ] Build succeeds
- [ ] All tests pass
- [ ] Conventional commit message format used
- [ ] No raw `new`/`delete` — use RAII or smart pointers
- [ ] GL resources cleaned up in destructors
- [ ] Headers are self-contained
- [ ] If a public interface changed: documentation updated in same commit (see cpp-patterns skill)
- [ ] If a symbol is deprecated: all call sites removed or annotated (see cpp-patterns skill)

✓ All 10 met → proceed to commit
✗ Any unmet → complete the failing step before committing
