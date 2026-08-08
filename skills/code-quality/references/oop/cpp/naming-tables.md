# Naming Convention Tables

## Naming Conventions by Category

| Element | Convention | Example |
|---------|-----------|---------|
| Classes/Structs/Enums | `PascalCase` | `TaskScheduler`, `SchedulerSettings` |
| Functions/Methods | `camelCase` (USE camelCase; not enforced by clang-tidy) | `initializeWorkerPool`, `getTaskCount` |
| Variables/Parameters | `snake_case` | `task_count`, `delta_time` |
| Member variables | `snake_case` + trailing `_` for private | `queue_capacity`, `worker_id_` |
| Constants/Macros | `UPPER_CASE` | `MAX_RETRIES`, `PI` |
| File names | `snake_case` | `task_scheduler.hpp` |
| Include guards | `<PROJECT>_<PATH>_<FILE>_H` | `MYAPP_TASK_SCHEDULER_H` |
| Namespaces | `snake_case` | `my_app` |
