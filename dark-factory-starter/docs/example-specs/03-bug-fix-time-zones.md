# Fix: report dates shift back one day for users west of UTC

A bug-fix spec: reproduction, expected and actual results, and a required regression test.

## Goal
Report rows show the wrong date for users west of UTC: an event on the evening of
10 March appears under 9 March. Dates must show the calendar day in the user's own time zone.

## Steps to reproduce
1. Set a user's time zone to America/Los_Angeles.
2. Create an event at 2026-03-10T17:00:00Z (10:00 local time on 10 March).
3. Open the weekly report. Expected: 2026-03-10. Actual: 2026-03-09.

## Acceptance criteria
- [ ] 2026-03-10T17:00:00Z viewed in America/Los_Angeles shows 2026-03-10.
- [ ] 2026-03-10T06:00:00Z viewed in America/Los_Angeles shows 2026-03-09
      (23:00 on 9 March, local time).
- [ ] Daylight saving edge: 2026-03-08T10:30:00Z shows 2026-03-08 in America/Los_Angeles.
- [ ] Users with no time zone set still see UTC dates.
- [ ] A regression test reproduces the original bug and fails on the current main branch.

## Out of scope
- Stored timestamps stay in UTC; do not migrate data.
- CSV and PDF exports (a separate spec).

## Files likely touched
- src/reports/format.py
- tests/reports/test_dates.py
