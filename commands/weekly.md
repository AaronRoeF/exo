# /weekly — Weekly Review

A weekly orienting + capturing pass. Run on Friday afternoon or Monday morning.

1. **Review `~/Exo/priorities/this-week.md`** — what got done, what didn't? Carry unfinished items forward.
2. **Check all accounts** in `~/Exo/accounts/` — update status fields based on the week's activity (last interaction date, deal stage, current posture).
3. **Pull this week's meetings** from Google Calendar. For each meeting, append a one-line note to the relevant person file in `~/Exo/people/` (or call `/wrap [meeting]` for any unwrapped meeting that produced material commitments).
4. **Update project tracker** — for any project in `~/Exo/projects/*/pulse.md` touched this week, run `pulse update <project>` (or do the equivalent manually): update `last_touched`, prepend a Last Stop entry, refresh Next Actions.
5. **Draft next week's `this-week.md`** — what's on next week's calendar, what's due, what's blocked, what's the focus.
6. **Flag stale accounts** — any account in `~/Exo/accounts/` with no interaction in 60+ days. List them so the user can decide whether to nudge or close.

Output a Weekly Review:
- Wins (3-5)
- Misses (3-5)
- Carries (unfinished items moving to next week)
- Focus for next week (1-3 priorities)
- Accounts needing attention

After the review, suggest the user run `dream` if `capture status` shows accumulated observations.
