# Multi-Component Debugging

When a failure could involve multiple layers (e.g., OpenGL, SDL3, shader, parser, UI), standard per-file investigation is insufficient. Use this instrumentation template to isolate the layer boundary where the failure originates.

## Layer Boundary Isolation Protocol

Before proposing any fix in a multi-component failure:

1. **Name the layers involved.** List every component the failing code path touches in execution order.
   ```
   Example: File picker -> ViewerApp -> SDL3Context -> OpenGL -> Shader -> Render
   ```

2. **Identify the boundary between "working" and "broken."**
   Ask: at which layer does the correct input produce incorrect output?
   ```
   Layer check: does [Layer A] receive correct input? -> YES/NO
   Layer check: does [Layer B] produce correct output given correct input? -> YES/NO
   ```
   The first "NO" is the boundary where the failure lives.

3. **Add instrumentation at that boundary.**
   ```cpp
   // Minimal boundary probe -- remove after diagnosis
   std::cerr << "[DEBUG boundary] input: " << input << " output: " << output << "\n";
   ```

4. **Run with instrumentation.** Read the output. State: "The failure is between [Layer A] and [Layer B] because [evidence]."

5. **Remove all instrumentation before the fix commit.**

## Common Multi-Component Failure Patterns

| Symptom | Most likely boundary | Investigation action |
|---------|---------------------|---------------------|
| Renders blank / nothing visible | Shader or OpenGL state | Check `glGetError()` after each GL call; verify shader compile/link log |
| Tests pass locally, fail in CI | Environment difference | Check: headless display? OpenGL driver? Font path? File path separator? |
| Visual regression diff shows offset | Camera or viewport transform | Log camera matrix and viewport before render; compare against baseline |
| SDL3 window creates but hangs | SDL3/OpenGL init sequence | Add `SDL_GetError()` and `glGetError()` probes at each init step |
| Flatpak crash on startup | Library version mismatch | Run `ldd` on the binary; check manifest pinned versions |

For the Particle-Viewer layer taxonomy (SDL3 events -> ViewerApp -> UI -> Graphics -> OpenGL -> Shader -> GPU), see `references/PV_DEBUG_REFERENCE.md`.
