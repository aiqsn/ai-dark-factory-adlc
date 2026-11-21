# Rate-limit /api/search

The buildable version of 01, after answering the red-team's questions.

## Goal
Stop a single API key from flooding /api/search, which slows search for everyone.

## Acceptance criteria
- [ ] Each API key may make 60 requests to GET /api/search per fixed 60-second window.
- [ ] The 61st request in a window returns HTTP 429 with body
      {"error": "rate_limited", "retry_after": <seconds>} and a Retry-After header
      giving the same number of seconds.
- [ ] Requests without an API key are limited to 20 per window per client IP.
- [ ] Keys with role=admin are never limited.
- [ ] Limits come from SEARCH_RATE_LIMIT and SEARCH_ANON_RATE_LIMIT (defaults 60 and 20).
- [ ] New tests cover: 60th request succeeds, 61st returns 429, the window resets,
      admin keys are exempt, and the anonymous limit. Existing search tests still pass.

## Out of scope
- Any endpoint other than /api/search.
- Limiting across multiple app instances; an in-memory store is fine.
- New dependencies, including Redis.

## Files likely touched
- src/middleware/ratelimit.py (new)
- src/api/search.py
- tests/test_ratelimit.py (new)
