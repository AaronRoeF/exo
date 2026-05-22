---
name: apple
description: >
  Use this skill when the user says "check my notes," "search notes," "my reminders,"
  "what's due today," "apple calendar," "search my contacts," "browsing history,"
  "reading list," or asks to access Apple native apps (Notes, Reminders, Calendar,
  Contacts, Safari).
  Do NOT trigger on Things 3 queries (use things).
---

<!--
SKILL SUMMARY: apple
=========================
Unified access to Apple's native macOS apps via the Apple MCP server.

WHAT IT DOES:
  Reads and searches Apple Notes, Reminders, Calendar, Contacts, and Safari
  data directly from local macOS databases and JXA automation. Can also create
  notes, create reminders, and mark reminders complete. Provides a single
  interface across 5 Apple apps with 28 tools.

WHEN TO USE:
  - Notes: search, list, read, create, browse by folder, get stats
  - Reminders: due today/this week/overdue, search, create, complete, list by list
  - Calendar: today's events, date range, upcoming, search (local Apple Calendar)
  - Contacts: search by name/email/company, get full details, company lookup
  - Safari: browsing history, search history, bookmarks, reading list

WHEN NOT TO USE:
  - Google Calendar events (use google-drive MCP or built-in Google Calendar)
  - Sending emails (use gmail MCP)
  - Anything requiring internet search (use playwright or WebSearch)

DATA SOURCES:
  Apple MCP server (28 tools across Notes, Reminders, Calendar, Contacts, Safari)
  - Notes: reads NoteStore.sqlite + JXA for full note body and creation
  - Reminders: JXA automation (Apple Reminders app)
  - Calendar: reads Calendar.sqlitedb
  - Contacts: reads AddressBook-v22.abcddb
  - Safari: reads History.db + Bookmarks.plist

KEY RULES:
  - Read-only for Calendar, Contacts, Safari. Read+write for Notes and Reminders.
  - Safari History requires Full Disk Access for the terminal app.
  - Apple Calendar is LOCAL only — does not include Google Calendar events.
  - Pull data in parallel when multiple tools are needed.
  - Direct, personal tone — this is the user's personal assistant.
-->

# apple — Apple Native App Access

**WHY:** Apple's native apps hold years of notes, reminders, contacts, calendar events, and browsing history — but they're siloed in separate apps. This skill gives unified access to all of them in one place.
**WHO:** the user (personal use)
**HOW:** 28 tools across 5 modules via the Apple MCP server, reading local macOS databases and using JXA automation
**WHAT:** Notes search/read/create, Reminders management, Calendar lookup, Contacts search, Safari history/bookmarks

---

## Commands & Triggers

| Trigger | Module | What It Does |
|---|---|---|
| "check my notes", "search notes for [X]" | **Notes** | Search and read Apple Notes |
| "my notes about [X]", "recent notes" | **Notes** | Find notes by topic or recency |
| "create a note", "note titled [X]" | **Notes** | Create a new Apple Note |
| "my reminders", "what's due today" | **Reminders** | Show due/overdue reminders |
| "remind me to [X]", "add a reminder" | **Reminders** | Create a new reminder |
| "apple calendar", "what's on my calendar today" | **Calendar** | Today's local calendar events |
| "what's coming up", "next 5 events" | **Calendar** | Upcoming events |
| "search my contacts", "find contact for [X]" | **Contacts** | Search contacts by name/email |
| "who works at [X]" | **Contacts** | Company-based contact lookup |
| "browsing history", "search my history for [X]" | **Safari** | Safari browsing history |
| "my bookmarks", "reading list" | **Safari** | Bookmarks and Reading List |

Natural language also works. If the user mentions Apple Notes, Reminders, their local calendar, contacts, or Safari browsing data, use the appropriate module.

**Disambiguation:** If the user says "calendar" without specifying, ask whether they mean Apple Calendar (local) or Google Calendar (work). Default to Google Calendar for work context, Apple Calendar for personal context.

---

## Module 1 — Notes

### Tools

| Tool | What It Does |
|---|---|
| `apple_notes_list` | List notes with title, snippet, folder, dates (paginated) |
| `apple_notes_search` | Search notes by keyword in title and snippet |
| `apple_notes_get` | Get full plaintext body of a note by exact title |
| `apple_notes_folders` | List all folders with note counts |
| `apple_notes_recent` | Get N most recently modified notes |
| `apple_notes_by_folder` | Get all notes in a specific folder |
| `apple_notes_create` | Create a new note (title, body, optional folder) |
| `apple_notes_stats` | Aggregate stats: total notes, per-folder counts, date range |

### Workflow: Find and Read a Note

1. **Search first:** Use `apple_notes_search` with the topic keyword
2. **Read the match:** Use `apple_notes_get` with the exact title from search results
3. If no match, try `apple_notes_list` or `apple_notes_by_folder` to browse

### Workflow: Create a Note

1. Use `apple_notes_create` with title and body
2. Optionally specify a folder name (default: "Notes")
3. Confirm the folder exists first with `apple_notes_folders` if unsure

---

## Module 2 — Reminders

### Tools

| Tool | What It Does |
|---|---|
| `apple_reminders_lists` | List all reminder lists with counts |
| `apple_reminders_list` | Get all reminders in a specific list |
| `apple_reminders_due` | Get reminders due today, this week, or overdue |
| `apple_reminders_search` | Search reminders by keyword across all lists |
| `apple_reminders_create` | Create a new reminder (name, list, due date, priority, body) |
| `apple_reminders_complete` | Mark a reminder as complete by name |

### Workflow: What's Due

1. Use `apple_reminders_due` with `range: "today"` for today's items
2. Also pull `range: "overdue"` in parallel to catch anything missed
3. Present grouped by list, sorted by priority

### Workflow: Create a Reminder

1. Parse the user's request for: name, due date, priority, list
2. If a due date is mentioned, convert to ISO 8601
3. Priority mapping: "urgent"/"important" = high, "sometime" = low, default = none
4. Use `apple_reminders_create`

---

## Module 3 — Calendar (Local Apple Calendar)

### Tools

| Tool | What It Does |
|---|---|
| `apple_calendar_today` | Today's events across all calendars |
| `apple_calendar_range` | Events in a date range (ISO 8601 start/end) |
| `apple_calendar_calendars` | List all calendars |
| `apple_calendar_search` | Search events by title |
| `apple_calendar_upcoming` | Next N upcoming events from now |

### Important: Apple Calendar vs. Google Calendar

Apple Calendar reads the **local macOS Calendar database**. This includes events synced to iCloud Calendar but does NOT include Google Calendar events unless they're subscribed in Apple Calendar. For Google Calendar (work meetings), use the google-drive MCP or built-in Google Calendar integration.

### Workflow: Today's Schedule

1. Use `apple_calendar_today` for all events today
2. Present chronologically with time, title, location, and calendar name

---

## Module 4 — Contacts

### Tools

| Tool | What It Does |
|---|---|
| `apple_contacts_search` | Search contacts by name, email, or company |
| `apple_contacts_get` | Get full contact details by ID (emails, phones, job title, etc.) |
| `apple_contacts_recent` | Recently modified contacts |
| `apple_contacts_company` | List contacts at a specific company |
| `apple_contacts_stats` | Total contacts, top companies, date range |

### Workflow: Find a Contact

1. Use `apple_contacts_search` with the person's name, email, or company
2. If multiple matches, use `apple_contacts_get` with the ID for full details (emails, phones)
3. For company lookups ("who works at [company]?"), use `apple_contacts_company`

---

## Module 5 — Safari

### Tools

| Tool | What It Does |
|---|---|
| `apple_safari_history` | Recent browsing history (configurable days + limit) |
| `apple_safari_search_history` | Search history by URL, domain, or page title |
| `apple_safari_bookmarks` | List bookmarks, optionally filter by folder |
| `apple_safari_reading_list` | Get all Reading List items |

### Requirements

Safari History requires **Full Disk Access** for the terminal app (System Settings > Privacy & Security > Full Disk Access). Bookmarks and Reading List do not require this.

### Workflow: Find Something You Browsed

1. Use `apple_safari_search_history` with a keyword (matches URL, domain, and title)
2. If the keyword is too broad, narrow by checking the domain or title in results
3. For recent browsing, use `apple_safari_history` with a specific `days` window

---

## Multi-Source Workflows

These workflows combine Apple data with other MCP sources for richer output.

### Morning Briefing

Combine Apple Calendar + Reminders for a daily snapshot. (If the user runs a health MCP like WHOOP, also include recovery + sleep.)

**Data pulls (all in parallel):**
1. `apple_calendar_today` — today's local calendar events
2. `apple_reminders_due` with `range: "today"` — reminders due today
3. `apple_reminders_due` with `range: "overdue"` — overdue items
4. Optional: health MCP recovery/sleep pulls

**Output format:**
```
## Morning Briefing — [Date]

### Recovery (if available)
**Score:** [X]% ([Band]) | **Sleep:** [X]h [Y]m
[One sentence on readiness.]

### Today's Calendar
[Chronological list of events with times and locations]

### Due Today
[Reminders grouped by list, priority-sorted]

### Overdue
[Any overdue items flagged]
```

### Meeting Prep Enrichment

Before a meeting, supplement attendee context with Apple Contacts data.

**When to use:** If attendee names are available during meeting prep, search Apple Contacts for each attendee to pull job titles, company, email, phone.

**Data pull:** `apple_contacts_search` for each attendee name (in parallel).

**Integration:** Add an "Attendee Details" section to the pre-brief with contact info found.

### Note Search + Retrieval

When the user asks about a topic and the answer might be in their notes.

1. `apple_notes_search` with the topic keyword
2. If matches found, `apple_notes_get` for the top result(s)
3. Summarize or quote the relevant content

### Contact Lookup Before Outreach

Before sending an email or message to someone, check contacts for their details.

1. `apple_contacts_search` for the person's name
2. `apple_contacts_get` for full details if found
3. Optionally cross-reference messaging history if available

---

## Error Handling

**Safari Full Disk Access:** If Safari history tools return SQLITE_CANTOPEN, inform the user: "Safari history requires Full Disk Access for the terminal app. Go to System Settings > Privacy & Security > Full Disk Access and add your terminal."

**Calendar DB not found:** If the calendar database is not at any expected path, report the error. Calendar data may be in iCloud only or the path may differ on this macOS version.

**Contacts DB not found:** Similar — the AddressBook path may differ. Report the specific error.

**Note not found:** If `apple_notes_get` fails because the title doesn't match exactly, suggest using `apple_notes_search` first to find the correct title.

**Reminders app not running:** JXA tools may launch the Reminders app if it's not running. This is expected behavior.

---

## Guardrails

**DO:**
- Pull multiple tools in parallel when the request spans modules
- Use `apple_notes_search` before `apple_notes_get` (search finds the exact title)
- Clarify "calendar" ambiguity — Apple (local) vs. Google (work)
- Present reminders sorted by priority, then due date
- Note when Safari history requires Full Disk Access
- Use direct, personal tone

**DON'T:**
- Confuse Apple Calendar with Google Calendar — they are separate data sources
- Assume all calendar events are in Apple Calendar (work events are typically Google)
- Create reminders or notes without confirming the user's intent if the request is ambiguous
- Include phone numbers or emails in output unless specifically asked (privacy)
- Use emojis in output
