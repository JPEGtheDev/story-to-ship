# Naming Convention Tables

## Naming Conventions by Category

| Element | Convention | Example |
|---------|-----------|---------|
| Classes/Structs/Enums | `PascalCase` | `ParticleSystem`, `RenderSettings` |
| Functions/Methods | `camelCase` (USE camelCase; not enforced by clang-tidy) | `initializeBuffers`, `getParticleCount` |
| Variables/Parameters | `snake_case` | `particle_count`, `delta_time` |
| Member variables | `snake_case` + trailing `_` for private | `window_width`, `camera_` |
| Constants/Macros | `UPPER_CASE` | `MAX_PARTICLES`, `PI` |
| File names | `snake_case` | `particle_system.hpp` |
| Include guards | `<PROJECT>_<PATH>_<FILE>_H` | `PARTICLE_VIEWER_PARTICLE_SYSTEM_H` |
| Namespaces | `snake_case` | `particle_viewer` |
