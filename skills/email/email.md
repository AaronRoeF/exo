---
name: email
description: >
  Autonomous inbox triage — scan a work inbox, auto-archive noise, draft replies
  for everything that needs a response, present a PINE-style index with single-key
  commands. Trigger on "scan email", "scan my inbox", "email triage", "clean inbox",
  "check my email", "inbox zero", or any request to review/triage email in bulk.
---

<!--
SKILL SUMMARY: email
==========================
Autonomous inbox triage for any Gmail account connected via the gmail MCP.

WHAT IT DOES:
  3-phase autonomous pipeline that scans an inbox, auto-archives noise
  (spam, cold outreach, notifications, newsletters, promotions), drafts
  replies for everything that needs a response with KB + calendar context
  enrichment, and presents a PINE-style index table. One interaction point
  instead of N.

  Pipeline: Scan+Classify -> Auto-Archive+Draft -> Approve+Execute

WHEN TO USE:
  - "scan email" / "scan my inbox" / "email triage" / "clean inbox"
  - "check my email" / "inbox zero"
  - Any request to review, sort, or act on emails in bulk

WHEN NOT TO USE:
  - Writing a single email from scratch (draft directly with the gmail MCP)
  - Searching for a specific email thread (just use Gmail search)

COMMANDS (PINE-style, from index or read view):
  [#]                     Read full email
  r [#]                   Draft reply (AI writes it, y sends)
  f [#] [email]           Forward, no confirmation needed
  a [#-#,#]               Archive
  s [#]                   Star
  n / p                   Next / previous (from read view)
  i                       Back to index
  d                       Done, show final stats

ACCOUNT:
  Whichever Gmail account is connected via mcp__gmail__* tools.
  If multiple accounts are connected, the user can scope the scan to a
  specific account via the scan command.

DATA SOURCES:
  - Gmail MCP
  - KB people/ and accounts/ files (if present) — for sender context enrichment
  - Google Calendar (next 7 days) — to reference upcoming meetings naturally
  - Recent Gmail threads (last 30 days per sender) — for conversation continuity
-->

# email — Autonomous Inbox Triage

3-phase pipeline: Scan+Classify, Auto-Archive+Draft, Approve+Execute.

---

## Phase 1 — Scan + Classify

Scan the user's inbox.

### Inbox Scan
- Tool: `mcp__gmail__search_emails`
- Query: `is:inbox newer_than:1d` (default; override with scan variants)
- maxResults: 100

Number results sequentially starting from 1. Include date on every row.

### Classify Each Email

Assign every email to exactly one category:

| Category | Action | Autonomous? |
|----------|--------|-------------|
| **reply-needed** | Draft reply, present for approval | No |
| **archive** | Remove from inbox | **Yes** |
| **remind-later** | Present in table, user decides | No |
| **delegate** | Present in table with suggested recipient | No |

### Auto-Archive Rules (no confirmation needed)

Archive immediately:
- Spam, phishing, scam emails
- Cold outreach with no prior thread initiated by the user
- Automated notifications (Zoom, payroll, banking alerts, ticketing alerts, LinkedIn alerts, GitHub)
- Marketing/promotional emails
- Newsletter digests (also label `newsletters`)
- Multi-email cadences (2+ follow-ups with no reply from the user)
- Travel confirmations and itineraries (label `travel`)

### Never Auto-Archive

- Anything from the user's own domain (configure this per install — typically the company domain of the inbox being triaged)
- Known customers, partners, investors (check `~/Exo/people/INDEX.md` and `~/Exo/accounts/INDEX.md` if these exist)
- Active deal or hiring threads
- Calendar invitations for real meetings
- Threads the user initiated
- Emails mentioning legal, HR, compliance, or personnel matters

---

## Phase 2 — Auto-Archive + Parallel Draft

Both streams run concurrently. No user input required.

### Auto-Archive Stream

Execute all archive actions immediately:
- Use `mcp__gmail__batch_modify_emails` — remove INBOX label
- Label newsletters as `newsletters` before archiving
- Label travel as `travel` before archiving
- Track count by type for the final report

### Parallel Draft Stream

For every `reply-needed` email, spawn one subagent. Each agent:

1. **Read full thread** — `mcp__gmail__read_email`. Full content, not snippet.
2. **Search KB** — check `~/Exo/people/` for sender file, `~/Exo/accounts/` for their org (if these dirs exist). Read INDEX.md first, load individual files only if sender found.
3. **Check calendar** — next 7 days via the Google Calendar MCP, looking for meetings with this person.
4. **Search recent threads** — last 30 days with this sender for conversation continuity.
5. **Draft reply** in the user's voice profile:
   - Direct, warm, contractions ("we're," "I'll," "it's")
   - No filler ("hope this finds you well," "just wanted to," "I wanted to reach out")
   - No apologies or qualifiers unless the user specified them
   - Reference upcoming meetings naturally ("see you Thursday")
   - Short sentences for decisions, longer for explanations
   - HTML format (`contentType: "text/html"`) with `<br>` for line breaks, `<p>` for paragraphs
   - Sign-off: use the user's configured sign-off (set during `/exo setup`)
   - Do NOT append a signature — Gmail injects it when the user opens the draft
   - **Concise-by-default** — target half the length of your impulse; lede in sentence 1; <100 words on default reply
6. **Prepend the CONTEXT block** to every draft body — at the very top, above the salutation. Plain text characters only (NO HTML tags wrapping the block — `<pre>`/`<div>` resist deletion in Gmail). ASCII bordered. Header names the user explicitly. Sections: WHO YOU'RE WRITING, WHERE THE RELATIONSHIP STANDS, YOUR LAST FEW INTERACTIONS, THINGS YOU PROMISED THEM, CHECK BEFORE YOU HIT SEND. Pulls from people files, account files, Gmail history, CRM (if connected), active PULSE.

   **Canonical format:**
   ```
   ============================================================
     READ BEFORE SENDING. THEN DELETE THIS BLOCK.
   ============================================================

   WHO YOU'RE WRITING
     <Name + handles> · <Title>, <Company>
     <Company one-liner>
     <Key org context>
     <How you met them>

   WHERE THE RELATIONSHIP STANDS
     <Type> · Tier <N> · <status: warm/cool/cold>
     Project: <related KB project>
     CRM deal (if connected): "<name>" · Stage: <stage>
     Last interaction: <date>

   YOUR LAST FEW INTERACTIONS
     <date>  <event/email summary>
     <date>  <prior>

   THINGS YOU PROMISED <them>
     • <open promise 1>
     • <open promise 2>

   CHECK BEFORE YOU HIT SEND
     ! <watch-out 1>
     ! <watch-out 2>

   ============================================================
     DELETE THIS BLOCK BEFORE SENDING
   ============================================================

   Hi <Name>,

   <email body in standard HTML>
   ```

7. **Verify recipients** before draft creation: read each recipient's people file if available; drop any `status: terminated`; refresh title if `last_updated >60 days`; disambiguate first-name-only matches.

8. **Send via** `mcp__gmail__send_email`. For BULK send (>3 emails in one batch), follow the Plan-Before-Bulk-Execute rule — show plan first, get approval, then execute.

### Sensitivity Gate

If any thread contains compensation, headcount, departures, performance, legal, or HR content:
- Classify as `reply-needed`
- Flag `[SENSITIVE]`
- Do NOT auto-draft
- Show in table with: "Review thread before replying."

---

## Phase 3 — Present + Approve + Execute

Once all archives and drafts complete, present a single output.

### Output Format — PINE-style Index

**Section 1 — Auto-archive report (one line):**
```
Auto-archived: 33 (12 notifications, 8 newsletters, 7 promotions, 5 cold outreach, 1 travel)
```

**Section 2 — PINE-style message index:**
```
INBOX (7 remaining)                                           <account-email>
------------------------------------------------------------------------------
 #  Flag   From                    Subject                              Date
 1  reply  <Sender 1>              Re: <topic>                          <date>
 2  act    <Sender 2>              Action Required — <subject>          <date>
 3  act    <Sender 3>              <expense approval subject>           <date>
 4  sign   <DocuSign sender>       <document name>                      <date>
 5  info   <Sender 5>              <Q2 OKR comment>                     <date>
 6         <Sender 6>              Re: <positioning subject>            <date>
 7         <Sender 7>              Re: <compliance subject>             <date>
------------------------------------------------------------------------------
 [#] read · r reply · f fwd · a archive · s star · d done
```

Flags: `reply` = AI draft ready, `act` = action required, `sign` = signature needed, `info` = FYI, `[SENSITIVE]` = review before replying, blank = no action needed.

**Section 3 — Reply drafts (shown inline below the index for all `reply` flagged emails):**
```
--- Draft #1 -> <Sender 1> ---
<Direct, voice-matched draft body. Short. Ledes with the answer.>

<user-signoff>
```

User types commands directly. No confirmation prompts for routine actions.

### Batch Execution

When the user issues commands, execute immediately. No confirmation for routine actions. Compound commands separated by semicolons execute in parallel.

**Command reference:**
- `[#]` — read full email (PINE read view). From read view: `r` reply, `f [email]` forward, `a` archive, `n`/`p` next/prev, `i` back to index
- `r [#]` — show AI draft inline, `y` sends immediately (one keystroke)
- `f [#] [email]` — forward immediately, no confirmation
- `a [#-#,#]` — archive range, no confirmation
- `s [#]` — star and keep in inbox
- `d` / `done` — finish session, show final stats
- Compound: `a 6-7; send 1; s 4` — all execute in one pass

### Final Report
```
Inbox Zero Complete:
  Auto-archived:  47
  Sent:            5
  Skipped:         1 draft
  Reminded:        2
  Forwarded:       1
  Remaining:       1 (sensitive — kept for manual review)
```

No second round. After execution, the skill is done.

---

## Account Configuration

This skill operates on whichever Gmail account is connected via `mcp__gmail__*`. If the user has multiple accounts (work + personal) and wants to scope a triage to one, use a scan variant with a Gmail search filter.

The "Never Auto-Archive" rule for "anything from your own domain" should be configured at install time. The `/exo setup` wizard collects the user's primary email domain(s) and the desired sign-off.

---

## Scan Variants

- **`scan email`** — default: connected inbox, last 24 hours
- **`scan email [query]`** — custom Gmail search filter
- **`scan email 3d`** / **`scan email 7d`** — override time window

---

## Rate Limiting

If the inbox exceeds 150 emails, process in batches of 75. Present the first batch, execute commands, then offer: "75 more emails. Continue?"

---

## Guardrails

1. **No sends without approval.** Every outbound email shown in batch review first.
2. **No deletes.** This skill archives — never permanently deletes.
3. **Spam vs. archive.** Only mark as spam if it's actual spam/phishing. Cold outreach gets archived, not spammed (avoid training Gmail's filter incorrectly).
4. **Preserve business emails.** Never auto-archive same-domain senders, known contacts, active deal threads.
5. **Sensitivity.** Never surface compensation, headcount, departure, or performance details. Flag sensitive threads for manual review.
6. **Voice compliance.** All drafts use the user's configured voice profile and sign-off. No exceptions.
7. **No confirmation for routine actions.** Archive, forward, star execute immediately. Only `r` (reply) shows a draft first — then `y` sends with no second prompt.
8. **Date on every row.** Include date in every email display, summary, or triage row.
9. **Gmail URLs.** Include clickable Gmail links on every email subject where available.

---

## Learning Loop Integration

When using email, capture observations about:
- **Classification errors** — emails miscategorized (spam marked as business, cold outreach marked as notification)
- **False confidence** — batch actions executed too quickly without enough context
- **Reply tone misses** — drafted replies that don't match the user's actual voice for a given context
- **New classification signals** — patterns in incoming email that should update the classification heuristics

Observations go to `capture`. Graduated patterns update the Classification Signals or Guardrails sections above.
