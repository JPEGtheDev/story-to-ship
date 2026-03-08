# Flatpak + OpenGL/SDL3 Gotchas

Patterns discovered while shipping the Flatpak build. Reference this document
when modifying the Flatpak manifest, SDL3 window creation code, or GL context
initialisation.

---

## SDL3 MSAA is strictly enforced

`SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)` causes `SDL_CreateWindow`
to return NULL on Mesa/llvmpipe (Xvfb) because the software renderer doesn't
support MSAA. GLFW silently fell back to no MSAA. Always add a fallback retry
without MSAA: try 4x first; if creation fails, retry with
`SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0)`.

---

## SDL3 FetchContent in Flatpak produces no display backends

When SDL3 is built via CMake `FetchContent` inside a `flatpak-builder` module,
the Freedesktop SDK `pkg-config` paths are **not** inherited by the sub-build.
This causes `sdl3_config.cmake` to report `SDL_X11: OFF` and
`SDL_WAYLAND: OFF`, leaving no video driver available at runtime — the app
silently fails to create a window with no useful error.

**Fix:** Build SDL3 as a **separate** module in the Flatpak manifest, before
the app module, with explicit flags:

```yaml
- name: sdl3
  buildsystem: cmake-ninja
  config-opts:
    - -DSDL_X11=ON
    - -DSDL_WAYLAND=ON
    - -DSDL_SHARED=ON
```

Then in `CMakeLists.txt`, try `find_package(SDL3 QUIET)` first so the
Flatpak-built SDL3 is picked up; fall back to FetchContent for local builds.

---

## NVIDIA GL extension version mismatch — three env vars required

**Symptom:** `SDL_CreateWindow failed: Invalid window driver data` inside
Flatpak on NVIDIA hardware.

**Root cause:** Flatpak GL extensions are versioned to the exact driver patch
(e.g. `nvidia-580-126-16`). If the installed extension doesn't match the
running driver (e.g. driver `580.126.18`), only Mesa's `GL.default` extension
mounts in the sandbox. Mesa's `libGLX_mesa.so` tries to negotiate with
NVIDIA's X server GLX extension, which rejects the connection → window
creation fails.

**Fix — set all three env vars before the first `SDL_Init`:**

```cpp
setenv("LIBGL_ALWAYS_SOFTWARE",    "1",    1);
setenv("GALLIUM_DRIVER",           "llvmpipe", 1);
setenv("__GLX_VENDOR_LIBRARY_NAME","mesa", 1);
```

Why all three are needed:
- `LIBGL_ALWAYS_SOFTWARE=1` alone is **insufficient** — GLVND still queries
  the X server GLX extension (which advertises NVIDIA) and tries to
  `dlopen libGLX_nvidia.so`, which is absent.
- `__GLX_VENDOR_LIBRARY_NAME=mesa` bypasses the X server's vendor
  negotiation entirely and routes to `libGLX_mesa.so`.
- `GALLIUM_DRIVER=llvmpipe` selects Mesa's software rasteriser explicitly.

**Detection heuristic** (requires `--device=all` finish-arg in manifest):

```cpp
// Gate on Flatpak — native systems have drivers installed normally.
if (access("/.flatpak-info", F_OK) != 0) return false;

const bool nvidia_dev = access("/dev/nvidia0", F_OK) == 0;
// Scan /usr/lib/*/GL/ for nvidia-* directories (architecture-agnostic).
const bool ext_mounted = isNvidiaGlExtensionMounted();
if (nvidia_dev && !ext_mounted) { /* set the three vars */ }
```

**Important:** Do NOT rely on `LD_LIBRARY_PATH` containing "nvidia" — Flatpak
mounts the GL extension into `/usr/lib/<triplet>/GL/nvidia-<ver>` and GLVND
resolves it via the directory structure, not via `LD_LIBRARY_PATH`.

This must run **before** the first `SDL_Init` call. Setting env vars after
SDL_Init (once NVIDIA's `libGL` is already loaded by GLVND) has no effect.

---

## Gate Flatpak workarounds on `/.flatpak-info`

Any runtime workaround that exists solely for the Flatpak sandbox (e.g.
NVIDIA GL extension checks, Mesa software fallbacks) **must** be gated on
actually running inside Flatpak. The canonical check:

```cpp
static bool isRunningInFlatpak() {
    return access("/.flatpak-info", F_OK) == 0;
}
```

Without this gate, the workaround will misfire on native systems — e.g.
scanning `/usr/lib/*/GL/nvidia-*` on a native NVIDIA system finds nothing
(those directories only exist inside the Flatpak sandbox) and incorrectly
forces software rendering.

---

## Flatpak `setenv` requires `overwrite=1`

Flatpak pre-initialises env vars it manages to `""` (empty string, not unset).
An `overwrite=0` call to `setenv()` sees a non-NULL existing value and
silently does nothing.

```cpp
// WRONG — silently does nothing inside Flatpak when the var is pre-set to ""
setenv("LIBGL_ALWAYS_SOFTWARE", "1", 0);

// CORRECT
setenv("LIBGL_ALWAYS_SOFTWARE", "1", 1);
```

Always use `overwrite=1` when setting env vars inside a Flatpak sandbox,
unless explicitly preserving a user-supplied value is required.

---

## Inspecting the sandbox environment

Useful when debugging GL/display issues inside Flatpak:

```bash
# Drop into a shell inside the sandbox
flatpak run --command=bash org.particleviewer.ParticleViewer

# Inside the shell:
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
ls /run/flatpak/ld.so.conf.d/       # which GL extensions are mounted
ls /usr/lib/x86_64-linux-gnu/GL/    # what GL dirs are present
ldconfig -p | grep -i "libGLX"      # which vendor libraries are found
cat /proc/driver/nvidia/version     # host driver version
```
