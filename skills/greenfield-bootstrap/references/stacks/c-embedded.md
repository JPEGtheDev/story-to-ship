## Stack: C/embedded C

This is a hosted gcc build that prints to stdout. Real cross-compiled embedded targets are out of scope.

1. Accepted Language values: `C`, `C99`, `C11`, `Embedded C`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v gcc`. When it prints nothing, skip the local run and report `gcc` as missing in the final `## Bootstrapped Files` summary.

3. Files:

File: `main.c`
```c
#include <stdio.h>

int main(void) {
  puts("Hello from <project-name>");
  return 0;
}
```

4. .gitignore entries:

```
hello_world
```

5. Lockfile committed with the project: none.

6. Smoke workflow steps (no setup step; gcc is preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: gcc main.c -o hello_world
      - name: Run
        run: ./hello_world
```

7. Local run, in the project directory: `gcc main.c -o hello_world && ./hello_world`.
