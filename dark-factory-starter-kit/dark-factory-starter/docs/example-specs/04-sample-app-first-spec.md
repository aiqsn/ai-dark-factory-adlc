# Return at most 3 results, best match first

A small first spec that fits the sample app. File it as a new issue with the spec template,
let the red-team comment, then apply `factory:build`.

## Goal
Search results are hard to scan when every product matches. Return the three best matches,
best first, so the top of the list is always the most relevant.

## Acceptance criteria
- [ ] GET /api/search returns at most 3 results.
- [ ] Results whose name contains a query word rank above results that match only by tag.
- [ ] Ties keep the existing order (lowest id first).
- [ ] GET /api/search?q=running returns ids [1, 2, 4] in that order.
- [ ] A query with no matches still returns {"query": ..., "results": []} with status 200.
- [ ] Missing or blank q still returns 400 {"error": "missing q"}.

## Out of scope
- Pagination, scoring weights in config, fuzzy matching.
- Any change to /healthz, /version or the HTML home page.
- New dependencies.

## Files likely touched
- src/index.js
- test/index.test.js
