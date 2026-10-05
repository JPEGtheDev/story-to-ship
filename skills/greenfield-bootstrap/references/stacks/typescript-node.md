## Stack: TypeScript/Node.js

1. Accepted Language values: `TypeScript`, when every runtime or framework the `Runtime/framework` value names (the part before its ` -- ` separator) is on this list: Node.js, Express, NestJS, Fastify, Koa. The framework itself is not scaffolded; the hello world stays a plain Node.js console program. A value that names any other runtime or framework, even alongside Node.js (for example Deno, Bun, Next.js, React or Vite), is not supported, because the template is a console program and a browser app or a full-stack framework is out of scope.

2. Toolchain probe: `command -v node && command -v npm`. When either prints nothing, skip the local run and report `node` as missing (npm ships with Node.js) in the final `## Bootstrapped Files` summary.

3. Files:

File: `package.json`
```json
{
  "name": "<project-id>",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "tsc"
  },
  "devDependencies": {
    "typescript": "^7.0.2"
  }
}
```

File: `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true
  },
  "include": ["src"]
}
```

File: `src/main.ts`
```typescript
console.log("Hello from <project-name>");
```

4. .gitignore entries:

```
node_modules/
dist/
```

5. Lockfile committed with the project: `package-lock.json` (created by `npm install`).

6. Smoke workflow steps:

```yaml
      - uses: actions/setup-node@v7
        with:
          node-version: 'lts/*'
      - name: Build
        run: npm install && npm run build
      - name: Run
        run: node dist/main.js
```

7. Local run, in the project directory: `npm install && npm run build`, then `node dist/main.js`.
