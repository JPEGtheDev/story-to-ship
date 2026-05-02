---
name: flatpak
license: MIT
description: Use when packaging, running, or debugging a Flatpak application with OpenGL and SDL3.
---

## Iron Law

```
GATE ALL FLATPAK WORKAROUNDS ON /.flatpak-info — NEVER APPLY SANDBOX WORKAROUNDS
ON NATIVE SYSTEMS
```

Violating the letter of this rule is violating the spirit of this rule.

A workaround that fires outside the Flatpak sandbox forces software rendering on native hardware, silently degrades quality, and masks real bugs.

**Announce at start:** "I am using the flatpak skill to [package/debug/diagnose] [brief description]."

---

## BEFORE PROCEEDING

Before modifying the Flatpak manifest, SDL3 window creation code, or GL context initialization:

- [ ] Is this code running inside Flatpak? Check `/.flatpak-info` — gate every workaround on this.
- [ ] Is SDL3 built as a **separate** manifest module (not via FetchContent inside the app module)?
- [ ] Are all `setenv()` calls using `overwrite=1`?
- [ ] Is the NVIDIA fallback check gated on both `/dev/nvidia0` AND absence of the mounted GL extension?
- [ ] Is the MSAA fallback retry present if requesting multisample?

✓ All pass → proceed
✗ Any fail → fix the gate condition first, then proceed

---

## Core Rules

### 1. SDL3 MSAA Fallback

`SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)` causes `SDL_CreateWindow` to return NULL on Mesa/llvmpipe (Xvfb) because the software renderer doesn't support MSAA.

**Fix:** Try 4x first; if creation fails, retry with `SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0)`.

---

### 2. SDL3 as a Separate Flatpak Module

When SDL3 is built via CMake `FetchContent` inside a `flatpak-builder` module, the Freedesktop SDK `pkg-config` paths are **not** inherited by the sub-build. This causes `sdl3_config.cmake` to report `SDL_X11: OFF` and `SDL_WAYLAND: OFF` — no video driver available at runtime.

**Fix:** Build SDL3 as a separate module in the Flatpak manifest, before the app module:

```yaml
- name: sdl3
  buildsystem: cmake-ninja
  config-opts:
    - -DSDL_X11=ON
    - -DSDL_WAYLAND=ON
    - -DSDL_SHARED=ON
```

Then in `CMakeLists.txt`, try `find_package(SDL3 QUIET)` first so the Flatpak-built SDL3 is picked up; fall back to FetchContent for local builds.

---

### 3. NVIDIA GL Extension Mismatch — Three Env Vars Required

**Symptom:** `SDL_CreateWindow failed: Invalid window driver data` inside Flatpak on NVIDIA hardware.

**Root cause:** Flatpak GL extensions are versioned to the exact driver patch. If the installed extension doesn't match the running driver, only Mesa's `GL.default` extension mounts. Mesa's `libGLX_mesa.so` tries to negotiate with NVIDIA's X server GLX extension, which rejects the connection.

**Fix:** Set all three env vars before the first `SDL_Init`:

```cpp
setenv("LIBGL_ALWAYS_SOFTWARE",    "1",       1);
setenv("GALLIUM_DRIVER",           "llvmpipe", 1);
setenv("__GLX_VENDOR_LIBRARY_NAME","mesa",     1);
```

Why all three:
- `LIBGL_ALWAYS_SOFTWARE=1` alone is insufficient — GLVND still queries the X server's GLX extension and tries to `dlopen libGLX_nvidia.so`, which is absent.
- `__GLX_VENDOR_LIBRARY_NAME=mesa` bypasses X server vendor negotiation entirely.
- `GALLIUM_DRIVER=llvmpipe` selects Mesa's software rasterizer explicitly.

**Detection heuristic** (requires `--device=all` finish-arg in manifest):

```cpp
static bool isRunningInFlatpak() {
    return access("/.flatpak-info", F_OK) == 0;
}

// Gate: only apply when inside Flatpak AND nvidia device present AND GL extension NOT mounted
const bool nvidia_dev = access("/dev/nvidia0", F_OK) == 0;
// Scan /usr/lib/*/GL/ for nvidia-* directories (architecture-agnostic)
const bool ext_mounted = isNvidiaGlExtensionMounted();
if (isRunningInFlatpak() && nvidia_dev && !ext_mounted) { /* set the three vars */ }
```

Do NOT rely on `LD_LIBRARY_PATH` containing "nvidia" — Flatpak mounts the GL extension into `/usr/lib/<triplet>/GL/nvidia-<ver>` and GLVND resolves it via the directory structure.

This must run **before** the first `SDL_Init` call. Setting env vars after SDL_Init has no effect.

---

### 4. `setenv` Requires `overwrite=1`

Flatpak pre-initializes env vars it manages to `""` (empty string, not unset). An `overwrite=0` call to `setenv()` sees a non-NULL existing value and silently does nothing.

```cpp
// WRONG — silently does nothing inside Flatpak when the var is pre-set to ""
setenv("LIBGL_ALWAYS_SOFTWARE", "1", 0);

// CORRECT
setenv("LIBGL_ALWAYS_SOFTWARE", "1", 1);
```

Always use `overwrite=1` when setting env vars inside a Flatpak sandbox, unless explicitly preserving a user-supplied value is required.

---

### 5. Gate All Workarounds on `/.flatpak-info`

Any runtime workaround that exists solely for the Flatpak sandbox must be gated on actually running inside Flatpak:

```cpp
static bool isRunningInFlatpak() {
    return access("/.flatpak-info", F_OK) == 0;
}
```

Without this gate, the workaround will misfire on native systems.

---

## Debugging Commands

```bash
# Drop into a shell inside the sandbox
flatpak run --command=bash <app-id>

# Inside the shell:
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
ls /run/flatpak/ld.so.conf.d/       # which GL extensions are mounted
ls /usr/lib/x86_64-linux-gnu/GL/    # what GL dirs are present
ldconfig -p | grep -i "libGLX"      # which vendor libraries are found
cat /proc/driver/nvidia/version     # host driver version
```

---

## Red Flags — STOP

If any of the following apply, stop and re-read the relevant core rule:

- SDL3 is built inside the app's `FetchContent` in the Flatpak manifest (not as a separate module)
- `setenv()` calls use `overwrite=0` (or omit the parameter, which defaults to 0 in some wrappers)
- NVIDIA detection logic runs on native systems (missing `/.flatpak-info` gate)
- MSAA is requested without a no-MSAA fallback retry
- Three NVIDIA env vars are not set together (partial set = partial fix = still broken)
- Env vars are set after `SDL_Init` (too late — GL vendor already loaded)

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "It works on my machine" | Your machine has a matching NVIDIA driver version. CI has a mismatch. |
| "I'll add the `/.flatpak-info` gate later" | A workaround that fires on native systems silently forces software rendering. Add the gate now. |
| "Setting two of the three NVIDIA vars should be enough" | It is not. All three are required for distinct reasons. See Core Rule 3. |
| "FetchContent is simpler than a separate manifest module" | FetchContent in a flatpak-builder module silently loses the Freedesktop SDK pkg-config paths. See Core Rule 2. |
| "I'll set the env vars in `main()` before calling anything" | `SDL_Init` may be called by library init code. Set before the first `SDL_Init` in your entry point. |

---

## Quick Reference

For the full discovery story and root cause analysis of each gotcha, see the `workflow` skill.
