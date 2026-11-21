# Instructions for coding agents

You are building changes for this repository from a spec in a GitHub issue. Nobody reads your
code before it ships: hidden scenarios and two adversarial reviewers judge it instead.

## The app
- A product-search API on Cloudflare Workers, plain JavaScript (ES modules), Node 22.
- Entry point: `src/index.js` (the `fetch` handler). `src/lambda.js` adapts it for AWS Lambda.
- Data lives in `PRODUCTS` in `src/index.js`. There is no database.

## Commands
- `make test` runs the unit tests (`node --test`). It must pass before you finish.
- `make dev` serves the app on http://127.0.0.1:8787.

## Rules
1. Implement only what the spec asks. If the spec is unclear, choose the simplest reading and say so
   in a code comment; do not invent extra features.
2. Add or update tests in `test/` for every acceptance criterion, including the error cases.
3. Never delete, skip or weaken an existing test. Never hard-code values to make a test pass.
4. Never modify `.github/`, `probes/`, `AGENTS.md`, `wrangler.jsonc` or `package-lock.json`.
5. Do not add dependencies unless the spec names them. Use the Web platform APIs Workers provide.
6. Keep `/healthz` and `/version` working: deploy probes depend on them.
7. Keep the change under about 300 lines. Match the existing style: small pure functions, clear names.
8. Errors are JSON: `{"error": "<short message>"}` with a 4xx status.
