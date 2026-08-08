# Multi-Component Debugging

When a failure could involve multiple layers (e.g., query engine, connection pool, serializer, parser, UI (User Interface)), standard per-file investigation is insufficient. Use this instrumentation template to isolate the layer boundary where the failure originates.

## Layer Boundary Isolation Protocol

Before proposing any fix in a multi-component failure:

1. **Name the layers involved.** List every component the failing code path touches in execution order.
   ```
   Example: CLI -> ImportService -> DatabaseConnection -> QueryEngine -> Serializer -> Response
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
| Response body is empty | Serializer or query-engine state | Check `queryEngine.lastError()` after each query call; verify serializer schema/init log |
| Tests pass locally, fail in CI | Environment difference | Check: test database seeded? Network access allowed? Config file path? File path separator? |
| Output diff shows field misalignment | Serializer field-order or schema mapping | Dump `serializer.fieldOffsets()` and the schema-mapping log before writing output; compare against baseline |
| Database connection opens but hangs | Connection/query-engine init sequence | Add `conn.lastError()` and `queryEngine.lastError()` probes at each init step |
| Flatpak crash on startup | Library version mismatch | Run `ldd` on the binary; check manifest pinned versions |
