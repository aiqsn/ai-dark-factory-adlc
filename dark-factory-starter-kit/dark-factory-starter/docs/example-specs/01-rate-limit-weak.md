# Rate limiting (weak first draft)

This is the kind of draft the spec red-team exists to catch. Compare it with 02.

## Goal
Add rate limiting to the API so it doesn't get abused.

## What the spec red-team said

- [ ] "Abused" is undefined: per API key, per IP, or global? What limit, over what window?
- [ ] No behaviour when the limit is hit: status code, response body, Retry-After header?
- [ ] Untestable: "doesn't get abused". Testable rewrite: "the 61st request within
      60 seconds from one API key returns 429".
- [ ] Missing edge cases: requests without a key, admin or internal callers.
- [ ] Needs a decision: which endpoints are covered, and are limits configurable?
