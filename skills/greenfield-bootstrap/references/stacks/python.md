## Stack: Python

1. Accepted Language values: `Python`, with any version number or parenthetical note. The `Runtime/framework` value is not read for mapping, and any framework it names is not scaffolded.

2. Toolchain probe: `command -v python || command -v python3`. When neither prints a path, skip the local run and report `python3` as missing in the final `## Bootstrapped Files` summary.

3. Files:

File: `main.py`
```python
print("Hello from <project-name>")
```

No `requirements.txt` is written. No other file is needed.

4. .gitignore entries:

```
__pycache__/
*.pyc
```

5. Lockfile committed with the project: none.

6. Smoke workflow steps:

```yaml
      - uses: actions/setup-python@v7
        with:
          python-version: '3.x'
      - name: Build
        run: if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
      - name: Run
        run: python main.py
```

7. Local run, in the project directory: `python main.py`; when `python` is absent, `python3 main.py`. There is no build command.
