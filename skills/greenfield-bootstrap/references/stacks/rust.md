## Stack: Rust

1. Accepted Language values: `Rust`. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v cargo`. When it prints nothing, skip the local run and report `cargo` as missing (installed with `rustup`) in the final `## Bootstrapped Files` summary.

3. Files:

File: `Cargo.toml`
```toml
[package]
name = "<project-id>"
version = "0.1.0"
edition = "2021"
```

File: `src/main.rs`
```rust
fn main() {
    println!("Hello from {}", "<project-name>");
}
```

4. .gitignore entries:

```
target/
```

5. Lockfile committed with the project: `Cargo.lock` (created by `cargo build`).

6. Smoke workflow steps (no setup step; Cargo is preinstalled on `ubuntu-latest`):

```yaml
      - name: Build
        run: cargo build
      - name: Run
        run: cargo run
```

7. Local run, in the project directory: `cargo build && cargo run`.
