## Stack: Go

1. Accepted Language values: `Go`, `Golang`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v go`. When it prints nothing, skip the local run and report `go` as missing in the final `## Bootstrapped Files` summary.

3. Files:

File: `go.mod`
```
module <project-id>

go 1.22
```

The extra substituted value here is the Go version. The skill replaces `1.22` with the local language version: run `go env GOVERSION`, drop the leading `go`, and keep the first two dot-separated parts (`go1.25.3` -> `1.25`). When Go is absent, keep `1.22`.

File: `main.go`
```go
package main

import "fmt"

func main() {
	fmt.Println("Hello from <project-name>")
}
```

4. .gitignore entries (`go build ./...` writes the binary named after the module):

```
/<project-id>
```

5. Lockfile committed with the project: none (`go.sum` is created only when a dependency is added).

6. Smoke workflow steps:

```yaml
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - name: Build
        run: go build ./...
      - name: Run
        run: go run main.go
```

7. Local run, in the project directory: `go build ./... && go run main.go`.
