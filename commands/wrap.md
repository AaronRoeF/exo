# /wrap [meeting name] — Meeting Debrief + KB Enrichment

Run this after any meeting. Pulls the transcript, enriches the KB (people + accounts), extracts action items, and reports what changed.

Schemas for people and account files are defined in `~/Exo/CLAUDE.md` under **People File Schema** and **Account File Schema**. Do not duplicate them here — read and follow those schemas when creating or updating files.

---

## Step 1: Pull Transcript

Use a transcripts MCP (e.g., Granola) to pull the latest meeting transcript. If multiple recent meetings exist, ask which one. If a meeting name was provided as an argument, search for it.

If no transcripts MCP is connected, the command operates from notes the user pastes inline.

Store the transcript content in working memory for the remaining steps.

---

## Step 2: People Enrichment

For every person mentioned in the transcript:

a. **Search `~/Exo/people/` for an existing file** (match on name, check alternate spellings).

b. **If a file exists:** Append a new entry to their Interactions section:
   ```
   - [date] <Source> (<meeting name>): <concise summary of what was discussed, decided, or committed>
   ```
   Update their Context bullets if the transcript reveals new information (role change, new ask, new relationship detail). Never overwrite existing context — append or refine.

c. **If no file exists:** Create one at `~/Exo/people/<firstname-lastname>.md` following the People File Schema. Populate with whatever the transcript provides. Set Email and LinkedIn to TBD if unknown.

d. **Cross-reference accounts:** If a newly created person belongs to an org that has a file in `~/Exo/accounts/`, note the account connection in their Context section. Also check if they should be added to that account's Key People table.

---

## Step 3: Account Enrichment

For every account (company/org) discussed in the transcript:

a. **Search `~/Exo/accounts/` for an existing file.**

b. **If a file exists:** Append to the Timeline section:
   ```
   - [date] <what happened — new signal, commitment, status change, decision>
   ```
   Update the Status section if the meeting changes the picture (e.g., moved from no engagement to engaged). Update Key People table if new contacts surfaced. Update related sections if those changed.

c. **If no file exists:** Flag it: "No account file for [Company] — want me to create one?"

d. **CRM check (optional):** If a CRM MCP (HubSpot, Salesforce, etc.) is connected, pull deal stage, last activity date, and contact notes for the account. Merge any net-new data into the account file. If no CRM is connected, skip this sub-step silently.

---

## Step 4: Action Items

Extract every action item, commitment, and follow-up from the transcript. Append them to `~/Exo/priorities/this-week.md` under the appropriate section with:
- Owner (the user or the other party)
- Deadline if stated, otherwise "TBD"
- Source reference: "(from [meeting name] [date])"

Do not duplicate items that already exist in this-week.md.

---

## Step 5: Corrections

Scan the transcript for anything that contradicts existing KB data (wrong title, wrong company, wrong assumption about a deal or relationship). If found:
- Propose the correction and get approval before changing the source file
- Append to `~/Exo/mistakes.md` (if maintained) under the appropriate category:
  ```
  - [date] <what was wrong>. <the correction>.
  ```

---

## Step 6: Timestamp All Touched Files

For every file created or updated in Steps 2-5, add or update a line at the bottom:
```
Last Updated: [date]
```
If the line already exists, replace the date. If it does not exist, append it after a blank line at the end of the file.

---

## Step 7: Enrichment Gap Check

After all updates, scan every file that was touched and flag missing key fields:
- People files: missing Email, missing LinkedIn, missing Context bullets, empty Interactions
- Account files: missing Key People, missing Status, missing "Why this company / How we fit", empty Timeline

Output each gap as a question:
```
Enrichment gaps found:
- [person] has no LinkedIn URL — want me to look it up?
- [account] has no "Why this company" section — want me to draft one?
```

If no gaps, skip this step.

---

## Step 8: Summary

After all steps complete, output a structured summary:

```
WRAP COMPLETE — [meeting name] ([date])

Files created:   [list of new files, or "none"]
Files updated:   [list of updated files]
Action items:    [count] extracted to this-week.md
Corrections:     [count logged to mistakes.md, or "none"]
Gaps flagged:    [count, or "none"]
```

Then suggest a `capture` if anything in the meeting felt like a worthwhile observation (e.g., a new pattern in how a customer thinks, a process insight worth graduating).
