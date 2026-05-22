---
name: things
description: >
  Trigger on: "my tasks," "what's on my list," "things today," "things inbox,"
  "show my projects," "search tasks," "add a task," "create a todo," "complete [task],"
  "mark [task] done," "what's upcoming," "someday list," or any request to view,
  search, create, or complete tasks in Things 3.
  Do NOT trigger on Apple Reminders (use apple) or project-level tracking (use pulse).
---

<!--
SKILL SUMMARY: things
=========================
Access to Things 3 task manager via the Things MCP server.

WHAT IT DOES:
  Reads and manages Things 3 to-dos, projects, areas, and tags. Can list items
  by smart list (Today, Inbox, Upcoming, Anytime, Someday, Logbook), search by
  keyword, get full details with checklist items, create new to-dos, mark items
  complete, and update existing items. 15 tools total.

WHEN TO USE:
  - Task lists: Today, Inbox, Upcoming, Anytime, Someday, Logbook
  - Projects: list all, get to-dos in a project
  - Search: find tasks by keyword in title or notes
  - Create: add new to-dos with scheduling, tags, checklists
  - Complete: mark tasks done
  - Update: reschedule, add notes, add tags, add checklist items

WHEN NOT TO USE:
  - Apple Reminders (use apple skill)
  - Calendar events (use apple for Apple Calendar, Google Calendar MCP for work)
  - Notes (use apple for Apple Notes)

DATA SOURCES:
  Things MCP server (15 tools)
  - Reads: SQLite database (sub-ms, works when Things is closed)
  - Writes: JXA (complete), URL scheme (create, update)

KEY RULES:
  - Read operations do not require Things to be open.
  - Write operations (create, complete, update) require Things to be installed.
  - Search is case-insensitive and matches both title and notes.
  - IDs are UUIDs — use search or list tools to find them before complete/update.
  - Pull data in parallel when multiple tools are needed.
  - Direct, personal tone — this is the user's task manager.
-->

# things — Things 3 Task Manager

**WHY:** Things 3 is a popular Mac/iOS task manager. This skill gives Claude direct access to read, search, create, and manage tasks without switching apps.
**WHO:** the user (personal use)
**HOW:** 15 tools via the Things MCP server — SQLite reads, JXA/URL scheme writes
**WHAT:** List by smart list, search, get details, create, complete, update

---

## Commands & Triggers

| Trigger | What It Does |
|---|---|
| "things today", "my tasks", "what's on my list" | List Today to-dos |
| "things inbox", "what's in my inbox" | List Inbox to-dos |
| "upcoming tasks", "what's coming up" | List Upcoming to-dos |
| "someday list", "someday tasks" | List Someday to-dos |
| "show my projects", "things projects" | List all projects |
| "search tasks for [X]", "find task [X]" | Search to-dos |
| "add a task", "create a todo [X]" | Create a new to-do |
| "complete [task]", "mark [task] done" | Complete a to-do |
| "what did I finish", "completed tasks" | List Logbook items |

Natural language also works. If the user mentions tasks, to-dos, Things, or task management, use the appropriate tool.

**Disambiguation:** If the user says "reminders" without specifying, ask whether they mean Things to-dos or Apple Reminders. Default to Things for task context, Apple Reminders for time-based alerts.

---

## Tools

### Read Tools (SQLite — instant)

| Tool | What It Does |
|---|---|
| `things_today` | All to-dos in the Today list (scheduled on or before today) |
| `things_inbox` | Unscheduled, unassigned to-dos |
| `things_upcoming` | To-dos scheduled for future dates, sorted by start date |
| `things_anytime` | Started to-dos without a specific start date |
| `things_someday` | Deferred to-dos |
| `things_logbook` | Completed to-dos, most recent first (configurable limit) |
| `things_projects` | All projects with status, area, and open to-do count |
| `things_areas` | All areas with project and to-do counts |
| `things_tags` | All tags |
| `things_search` | Search by keyword (title + notes, case-insensitive) |
| `things_get` | Full details for a specific to-do by ID, including checklist items |
| `things_project_todos` | All to-dos in a specific project |

### Write Tools (JXA/URL scheme — requires Things installed)

| Tool | What It Does |
|---|---|
| `things_create` | Create a new to-do with title, notes, schedule, deadline, tags, checklist |
| `things_complete` | Mark a to-do as complete by ID |
| `things_update` | Update title, notes, schedule, deadline, tags, or add checklist items |

---

## Workflows

### Daily Review

**Data pulls (all in parallel):**
1. `things_today` — today's tasks
2. `things_inbox` — unprocessed items

**Output format:**
```
## Things — Daily Review

### Today (N items)
[Tasks grouped by project, then ungrouped]

### Inbox (N items)
[Unprocessed items needing triage]
```

### Find and Complete a Task

1. `things_search` with the keyword to find the task
2. Note the `id` from the result
3. `things_complete` with the ID

### Create a Scheduled Task

1. Parse the user's request for: title, notes, schedule date, deadline, tags, project
2. Map schedule language: "today" / "tomorrow" / "next week" → `when` parameter
3. `things_create` with extracted fields

### Project Status

1. `things_projects` to list all projects
2. `things_project_todos` for the specific project
3. Present with open/total count and grouped by heading if available

---

## Error Handling

**Things not installed:** If the database is not found, inform the user: "Things 3 database not found. Is Things installed?"

**Task not found:** If `things_get` or `things_complete` fails with "not found", suggest using `things_search` to find the correct ID.

**Project not found:** If `things_project_todos` fails, suggest `things_projects` to list available projects.

---

## Guardrails

**DO:**
- Pull multiple tools in parallel when the request spans lists
- Use `things_search` to find IDs before calling `things_complete` or `things_update`
- Present tasks sorted by project/area grouping when displaying lists
- Use direct, personal tone
- Confirm before creating tasks if the request is ambiguous

**DON'T:**
- Confuse Things to-dos with Apple Reminders — they are separate apps
- Complete tasks without confirming the correct item if the search returns multiple matches
- Include full notes text in list views unless specifically asked (keep lists scannable)
- Use emojis in output
