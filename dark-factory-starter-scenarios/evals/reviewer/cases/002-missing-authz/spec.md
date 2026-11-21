## Goal
Add an admin endpoint that reports how many products exist, for the ops dashboard.

## Acceptance criteria
- [ ] GET /api/admin/stats returns {"products": <count>} with status 200.
- [ ] The request must carry header X-Admin-Token equal to env.ADMIN_TOKEN; otherwise 401 {"error": "unauthorized"}.
