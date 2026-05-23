# /prep [person or meeting name] — Meeting Pre-Brief

1. **Look up the person** in `~/Exo/people/` — read their full file. If multiple people match, list them and ask which.
2. **Look up their account** in `~/Exo/accounts/` — read the full file for their company.
3. **Check Gmail** for recent email exchanges (last 30 days with this person).
4. **Check meeting transcripts** if a transcripts MCP is connected (e.g., Granola). Search for prior meetings with this person.
5. **Cross-reference active projects** in `~/Exo/projects/*/pulse.md` for any that mention this person or their org.

Output a pre-brief:
- **Who they are** — name, title, company, one-line context
- **What we want from this meeting** — the user's goals (inferred from project pulses + prior interactions)
- **What they want** — their likely goals (inferred from past emails / prior meetings / their company's posture)
- **Suggested talking points** — 3-5 specific, concrete starters
- **Open questions** — unresolved things from prior conversations
- **Promises outstanding** — anything the user committed to them but hasn't delivered

If no person/account file exists, offer to create stubs and run `/enrich` to populate them.
