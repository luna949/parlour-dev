# HEARTBEAT.md — Companion

Reply HEARTBEAT_OK unless something below triggers an action.

## Event Follow-Ups
1. Read `data/memory/events.json`
2. Any events with `follow_up: true` and `follow_up_after` ≤ today and `resolved: false`?
3. If yes → send a natural check-in about that event
4. Only one follow-up per heartbeat. Don't stack.

## Inactivity Check
1. Check last conversation date
2. If >3 days and <7 days → one gentle check-in: "hey — how's your week going?"
3. If >14 days → "hey, been thinking about you. hope you're good."
4. If >30 days → nothing. They'll come back when they're ready.
5. Never send more than one inactivity check-in per week.

## Rules
- Never message between 10 PM and 7 AM (user's timezone)
- Never send more than 1 unsolicited message per day
- Nothing to do → HEARTBEAT_OK
