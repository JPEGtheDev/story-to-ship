# Human-Reviewable Formatting Patterns

These require **manual inspection** after running clang-format — tools don't always catch them:

| Issue | Fix | Example |
|-------|-----|---------|
| Semicolon after function closing brace | Remove trailing `;` | `void foo() { }` not `void foo() { };` |
| Empty constructor syntax | Use `= default` | `Shader() = default;` not `Shader() {};` |
| Exception catching by value | Catch by const reference | `catch (const std::ifstream::failure& e)` |
| Multiple declarations in one line | Split to separate lines | `uint32_t w; uint32_t h;` not `uint32_t w, h;` |

**Always check `git diff` for these patterns after formatting.**
