# /daily — Morning Briefing

Renders the day's orienting snapshot. Read `~/Exo/priorities/this-week.md` (if it exists) and surface:

1. **What's due today?** Pull from `this-week.md` and any deadline-bearing items in `~/Exo/projects/*/pulse.md`.
2. **What meetings are on the calendar today?** Use the Google Calendar MCP if connected.
3. **Any new emails requiring action?** Use the Gmail MCP — scan last 12 hours, focus on the user's primary domain and known senders (per `~/Exo/people/INDEX.md` if present).
4. **Update `this-week.md`** with any new items discovered during steps 1-3.

Output a concise briefing:

- Greet the user by name (from their `~/Exo/CLAUDE.md` identity section)
- What's due (numbered, with deadlines)
- What's scheduled (chronological)
- What needs attention (action-required items only)

If `~/Exo/priorities/this-week.md` doesn't exist, offer to create it from the priorities the user declared during `/exo setup`.

Keep it short — under one screen. The point is orientation, not exhaustive reporting.
