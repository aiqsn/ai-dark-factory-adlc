## Goal
Treat a query made only of punctuation as blank, so "?!" doesn't search for nothing.

## Acceptance criteria
- [ ] GET /api/search?q=%3F%21 returns 400 {"error": "missing q"}.
- [ ] Queries with letters are unchanged.
