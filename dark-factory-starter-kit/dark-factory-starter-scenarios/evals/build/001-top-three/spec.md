## Goal
Return the three best matches, best first.

## Acceptance criteria
- [ ] GET /api/search returns at most 3 results.
- [ ] Results whose name contains a query word rank above results that match only by tag.
- [ ] Ties keep the existing order (lowest id first).

## Out of scope
- Pagination, fuzzy matching, new dependencies.
