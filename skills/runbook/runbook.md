---
name: runbook
description: >
  Use this skill when the user says "investigate [symptom]", "runbook [topic]",
  "diagnose [issue]", "troubleshoot [problem]", "what's wrong with [system]",
  or describes a symptom that needs multi-source investigation across available
  MCP tools (health anomaly, MCP server failure, team ops incident, or any
  open-ended diagnostic question).
  Also trigger when another skill surfaces a symptom that warrants structured
  investigation (e.g., health flags an anomaly, or a meeting wrap reveals
  an operational issue).
  Do NOT use for ad-hoc questions that can be answered with a single tool call.
triggers:
  - "investigate [symptom]"
  - "runbook [topic]"
  - "diagnose [issue]"
  - "troubleshoot [problem]"
  - "what's wrong with [system]"
---

<!--
SKILL SUMMARY: runbook
===========================
Personal investigation runbooks — symptom to structured findings report.

WHAT IT DOES:
  Takes a symptom or anomaly, identifies the matching runbook type, executes a
  multi-tool investigation sequence across available MCP servers, and produces
  a structured findings report with timeline, root cause (if identifiable),
  and recommended actions.

WHEN TO USE:
  - investigate [symptom] — open-ended investigation using all available tools
  - runbook [topic] — run a named investigation playbook
  - diagnose [issue] — structured diagnostic for a specific problem
  - troubleshoot [problem] — step-by-step troubleshooting with tool verification
  - what's wrong with [system] — system health check and anomaly investigation

RUNBOOK TYPES:
  - WHOOP anomaly — unexpected recovery/sleep/strain patterns
  - MCP server failure — tool not responding or returning errors
  - Team ops incident — operational issue across Slack, email, Jira, CRM
  - General investigation — open-ended multi-source triage

WHEN NOT TO USE:
  - Single-tool questions (just use the tool directly)
  - Medical diagnoses (health can flag patterns, but see a doctor)

DATA SOURCES:
  Any MCP servers the user has installed — commonly WHOOP, Apple, Gmail, Slack,
  HubSpot, Jira, Playwright, Things, Obsidian, Notion, filesystem.
-->

# runbook — Personal Investigation Runbooks

**WHY:** When something goes wrong, the instinct is to check one tool at a time. This skill runs a structured multi-source investigation — pulling data from the right tools in the right order — so nothing gets missed.
**WHO:** the user (personal use)
**HOW:** Symptom input, runbook matching, parallel MCP tool pulls, structured findings report
**WHAT:** WHOOP anomaly investigation, MCP server diagnostics, team ops incident triage, general multi-source investigation

---

## How It Works

Every investigation follows three phases: **Identify, Investigate, Report.**

### Phase 1 — Identify

1. **Match the symptom.** Map the user's description to one of the runbook types below. If the symptom spans multiple types, run the most specific one first.
2. **Confirm the match.** State which runbook you are running and why. Ask the user to confirm before proceeding unless the match is obvious.
3. **Gather inputs.** Each runbook type has required context. Collect it upfront — don't discover it mid-investigation.

### Phase 2 — Investigate

1. **Execute the tool sequence.** Each runbook type defines which tools to call and in what order. Issue independent calls in parallel.
2. **Log findings as you go.** After each tool call, note what was found or what was absent (absence of data is itself a finding).
3. **Follow leads.** If a tool result reveals a new thread worth pulling, follow it — but note that you are deviating from the standard sequence.
4. **Handle failures.** If a tool fails or returns no data, log the failure and move to the next step. Do not block the investigation on a single broken tool.

### Phase 3 — Report

Produce a structured findings report. Default output is to the terminal (ephemeral). If the user says "save this," write to `~/Exo/analyses/runbook-[topic]-[date].md`.

---

## Runbook Types

### 1. WHOOP Anomaly

**Symptom patterns:** "my recovery is weird," "why did I sleep so badly," "strain seems off," "HRV crashed," "recovery has been red for days," or health flags a concerning pattern.

**Required inputs:** What seems off (recovery, sleep, strain, HRV) and approximate timeframe.

**Investigation sequence:**

| Step | Tool(s) | What to Look For |
|------|---------|-----------------|
| 1. Pull WHOOP data | `whoop-get-recovery-collection` (7-14 days), `whoop-get-sleep-collection` (7-14 days), `whoop-get-cycle-collection` (7-14 days), `whoop-get-workout-collection` (14 days) | The anomaly itself — quantify the deviation from rolling baselines |
| 2. Check calendar context | `apple_calendar_range` (same window), Google Calendar via `gcal_list_events` | Late nights, travel, timezone changes, early meetings, social events that explain sleep disruption |
| 3. Check recent tasks/stress | `things_today`, `things_upcoming` | Deadline pressure, overloaded task list, major deliverables |
| 4. Check vault for context | `obsidian_search` for recent daily notes | Personal notes that might explain the anomaly (illness, stress, life events) |

**Analysis framework:**
- Compare the anomaly window to the 7-day and 30-day baselines
- Look for correlating events (travel, late calendar events, high strain days before poor recovery)
- Check if the pattern is acute (one-off) or trending (multiple days)
- Distinguish between explainable anomalies (late flight, alcohol, overtraining) and unexplained ones (flag for doctor)

### 2. MCP Server Failure

**Symptom patterns:** "whoop isn't working," "can't access Slack," "MCP tool not responding," "[tool] is broken," "getting errors from [server]," or a tool call returns an unexpected error.

**Required inputs:** Which server/tool is failing, error message (if any).

**Investigation sequence:**

| Step | Tool(s) | What to Look For |
|------|---------|-----------------|
| 1. Check server config | Read `~/.claude.json` — find the server entry | Server registered, command path exists, env vars set |
| 2. Test the tool | Call a simple read-only tool from the failing server | Does it respond at all? What error? |
| 3. Check auth state | Server-specific auth check (see table below) | Token expired, OAuth needs refresh, API key invalid |
| 4. Check server process | `ps aux \| grep [server-name]` or check if tools appear in deferred set | Server running, or failed silently at startup |
| 5. Check logs | Read server-specific log files if they exist | Stack traces, connection errors, timeout messages |

**Auth check reference:**

| Server | Auth Type | How to Check | How to Fix |
|--------|-----------|-------------|------------|
| WHOOP | OAuth (hourly expiry) | Try any `whoop-get-*` call | Re-run the whoop MCP auth script |
| Google Drive | OAuth (persistent) | Try `authGetStatus` | Re-run OAuth flow in browser |
| Gmail | OAuth (persistent) | Try `search_emails` with a simple query | Re-run OAuth flow |
| Slack | Bot token | Try `channels_list` | Check bot token in `~/.claude.json` |
| HubSpot | API token | Try `search_contacts` with a simple query | Check Private App token scopes |
| Jira | API token | Try `get_myself` | Check API token in `~/.claude.json` |
| Apple | None (local DB) | Try `apple_notes_stats` | Check Full Disk Access permissions |
| Things | None (local DB) | Try `things_today` | Ensure Things 3 app is installed |
| Obsidian | None (CLI) | Try `obsidian_vault_info` | Ensure Obsidian is running |
| Playwright | None | Try `browser_navigate` to a simple URL | Check Chrome/WebKit availability |
| Notion | Hosted (API key) | Try `notion-search` | Check API key in Notion integration settings |

**Common failure patterns:**
- **Silent startup failure:** Server not in deferred tool list = never loaded. Check `~/.claude.json` path.
- **Auth expired:** WHOOP expires hourly. Google/Gmail usually persist but can expire after weeks.
- **Permission denied:** Apple tools need Full Disk Access. Safari history especially.
- **App not running:** Obsidian, Granola, and Things require the desktop app to be open.

### 3. Team Ops Incident

**Symptom patterns:** "something went wrong with [deal/customer/deployment]," "there's a problem with [process]," "what happened with [incident]," or a meeting/email reveals an operational issue that needs investigation.

**Required inputs:** What happened (or what seems wrong), approximate timeframe, people/accounts involved.

**Investigation sequence:**

| Step | Tool(s) | What to Look For |
|------|---------|-----------------|
| 1. Check Slack | `conversations_history` for relevant channels (e.g., #incidents, #general, team-specific channels) | Mentions of the issue, timeline of events, who raised it |
| 2. Check email | `search_emails` for relevant threads | Customer complaints, internal escalations, vendor notifications |
| 3. Check Jira | `search_issues` for related tickets | Existing tickets, status, assignees, blockers |
| 4. Check CRM (if deal-related) | `search_deals`, `get_deal`, `get_notes` | Deal stage, recent activity, contact history |
| 5. Check Notion (if process-related) | `notion-search` for relevant pages/decision records | Process documentation, prior incidents, decisions |
| 6. Check calendar | Google Calendar for relevant meetings | Meetings where this was discussed, upcoming meetings to address it |

**Analysis framework:**
- Build a timeline: when did the issue first appear, who noticed, what actions were taken
- Identify the current state: resolved, in progress, blocked, or unacknowledged
- Map the stakeholders: who is affected, who is responsible, who needs to know
- Surface any related patterns: has this happened before? Is there an existing runbook or decision record?

### 4. General Investigation

**Symptom patterns:** Anything that does not cleanly map to the above types. Open-ended questions like "what's going on with [X]," "can you dig into [Y]," or "I need to understand [Z]."

**Required inputs:** The question or symptom, any context the user can provide.

**Investigation sequence:**

| Step | Action | Tools |
|------|--------|-------|
| 1. Scope the question | Determine which data sources are most likely to have relevant information | None — analysis only |
| 2. Primary sweep | Pull data from the 2-3 most relevant sources in parallel | Depends on topic |
| 3. Follow-up pulls | Based on primary findings, pull from additional sources | Depends on findings |
| 4. Vault check | Search Obsidian vault for related notes, prior analyses | `obsidian_search` |
| 5. Synthesize | Combine all findings into a coherent picture | None — analysis only |

**Tool selection heuristic:**

| If the topic involves... | Start with... |
|--------------------------|--------------|
| Health / biometrics | WHOOP MCP, Apple Calendar |
| People / relationships | Apple Contacts, Gmail, CRM |
| Work / team operations | Slack, Gmail, Jira, CRM, Notion |
| Tasks / productivity | Things, Apple Reminders, Apple Calendar |
| Content / knowledge | Obsidian, Apple Notes, Google Drive |
| Web / external info | Playwright, WebSearch |

---

## Report Format

All investigation reports follow this structure:

```
## Investigation Report — [Topic]
**Date:** [date]
**Runbook:** [Type] | **Triggered by:** [symptom description]

### Timeline
[Chronological sequence of events, if applicable. Each entry: date/time, what happened, source.]

### Findings
[Numbered list of key findings from the investigation. Each finding includes:]
1. **[Finding title]** — [description]. Source: [which tool/data source].

### Data Gaps
[What could NOT be determined and why — tools that failed, data that was missing, sources not checked.]

### Root Cause
[If identifiable: the root cause of the issue. If not: "Root cause not definitively identified" + best hypotheses ranked by likelihood.]

### Recommended Actions
[Numbered list of specific next steps with owners where applicable.]
1. [Action] — [who should do it, by when]

### Sources Checked
[List of MCP tools/data sources queried during this investigation.]
```

---

## Saving Reports

**Default:** Reports render to terminal (ephemeral). Good for quick investigations.

**On "save this":** Write to `~/Exo/analyses/runbook-[topic-slug]-[date].md` with YAML frontmatter:

```yaml
---
type: investigation
runbook: [whoop-anomaly | mcp-failure | ops-incident | general]
topic: [short description]
date: [date]
status: [resolved | open | monitoring]
---
```

---

## Gotchas

1. **Don't skip the confirm step for ambiguous symptoms.** If the symptom could map to multiple runbook types, confirm before investigating. Running the wrong runbook wastes tool calls and context.

2. **Parallel tool calls save time.** Within each runbook, independent data pulls should be issued in parallel. Do not serialize calls that have no dependency.

3. **Absence is a finding.** If Slack has no mentions and email has no threads, that is itself informative — the issue may not have been communicated yet, or it may not be as widespread as feared.

4. **WHOOP auth expires hourly.** The most common MCP failure. If any `whoop-get-*` call fails, try re-auth first before deeper investigation.

5. **Don't send communications without approval.** If the investigation suggests someone should be notified (Slack message, email), draft it and wait for the user's approval. Never auto-send.

6. **Follow the thread but note the deviation.** If a tool result reveals something unexpected that is worth investigating, follow it — but explicitly note in the report that you deviated from the standard sequence and why.

7. **Save threshold.** Not every investigation is worth saving. Quick diagnostics (MCP auth fix, single-tool check) are fine as ephemeral terminal output. Save when: the investigation took 5+ tool calls, revealed a non-obvious root cause, or produced action items worth tracking.

---

## Learning Loop Integration

When using runbook, capture observations about:
- **Missing runbook types** — when a symptom does not map to any defined type (candidate for a new runbook)
- **Tool sequence gaps** — when the standard sequence misses a data source that turned out to be key
- **Common failures** — patterns in what breaks and why (especially MCP server failures)
- **False positives** — when the symptom was a non-issue (calibrates future triage)

Observations go to `capture`. Graduated patterns update the runbook definitions or the Gotchas section.
