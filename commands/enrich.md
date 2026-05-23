# /enrich [name or company] — Deep Enrichment

Deeply research and enrich a person or account file. The argument is a person name or company/account name.

## Determine Target Type

Check both `~/Exo/people/` and `~/Exo/accounts/` for an existing file matching the argument.
- If found in `people/` or the argument looks like a person name → PERSON flow
- If found in `accounts/` or the argument looks like a company name → ACCOUNT flow
- If ambiguous, ask: "Is this a person or an account?"

---

## PERSON Flow

1. **Find or create** the file in `~/Exo/people/` following the People File Schema in `~/Exo/CLAUDE.md`. Search before creating.

2. **Research sources** — run all available in parallel:
   - **LinkedIn** (Playwright MCP if connected): navigate to their profile. Capture current title, org, background summary, recent posts/activity.
   - **Gmail** (gmail MCP `search_emails`): search for their name and email domain, last 6 months. Note key threads, topics, tone.
   - **Meeting transcripts** (e.g., Granola MCP if connected): search for their name. Pull context from any meeting transcripts.
   - **Web search**: "[full name]" + org name. Look for interviews, talks, articles, news, board seats.
   - **CRM MCP** (HubSpot/Salesforce/etc. if connected): pull their contact record, deal associations, last activity.

3. **Fill gaps** in the existing file. Do NOT overwrite existing content. ADD missing info:
   - Fill TBD fields (email, LinkedIn URL, title, org)
   - Add new Context bullets for newly discovered facts
   - Add relationship context (board seats, prior companies, mutual connections)

4. **Log the enrichment** — append to Interactions:
   ```
   - [date] Enrichment: Sources checked: [list]. Key findings: [summary].
   ```

5. **Update enrichment marker** — add or update at the top of the file:
   ```
   <!-- Last Enriched: [date] -->
   ```

6. **Cross-reference**: if this person is associated with a tracked account in `~/Exo/accounts/`, ensure they appear in that account's Key People table. Flag if the account file is missing.

---

## ACCOUNT Flow

1. **Find or create** the file in `~/Exo/accounts/` following the Account File Schema in `~/Exo/CLAUDE.md`. Search before creating.

2. **Research sources** — run all available in parallel:
   - **Web search**: company news, funding, leadership changes, product announcements — focus on last 90 days.
   - **LinkedIn company page** (Playwright MCP if connected): company size, recent posts, notable job openings.
   - **Gmail** (gmail MCP `search_emails`): search for @company.com addresses, last 6 months. Note key threads and contacts.
   - **CRM MCP** (HubSpot/Salesforce/etc. if connected): pull the company record, associated deals, recent activity.

3. **Fill gaps** — especially:
   - Current Stack (technologies, platforms, partnerships)
   - Key People table (names, titles, roles)
   - Status indicator and summary
   - "Why this company" / "How we fit" if empty

4. **Log the enrichment** — append to Timeline:
   ```
   - [date] Enrichment: Sources checked: [list]. Key findings: [summary].
   ```

5. **Update enrichment marker** — add or update at the top of the file:
   ```
   <!-- Last Enriched: [date] -->
   ```

6. **Cross-reference**: check if key people mentioned have files in `~/Exo/people/`. List any missing ones and ask: "Want me to create files for: [names]?"

---

## Output

Summarize:
- **Updated:** what fields/sections were filled or added
- **Sources checked:** which sources returned useful data
- **Gaps remaining:** what is still TBD or unverified
- **Cross-references:** any linked files created or flagged
