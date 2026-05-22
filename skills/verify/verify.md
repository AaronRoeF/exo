---
name: verify
description: >
  Structural verification for analysis outputs and structured documents.
  Trigger on: "verify this analysis", "check this document", "is this complete",
  "quality check [output]". Runs assertion-based structural checks against an
  expected output rubric. Reports a PASS/FAIL scorecard with gaps and suggested
  fixes. This is a quality gate, not a content judgment.
---

<!--
SKILL SUMMARY: verify
==========================
General-purpose structural verification for any analysis output or structured document.

WHAT IT DOES:
  Validates that a completed output meets its expected structural contract.
  Checks section presence, required fields, evidence citations, and completeness
  against a rubric. Produces a scorecard with PASS/FAIL per assertion and an
  overall verdict.

WHEN TO USE:
  - "verify this analysis" -- after generating any structured analysis
  - "check this document" -- spot-check before treating it as ground truth
  - "is this complete" -- quick completeness audit
  - "quality check [output]" -- full structural verification

WHEN NOT TO USE:
  - Evaluating whether the substantive claims in an analysis are correct (content judgment)
  - Editing or fixing an output (this skill reports; it does not repair)
  - Stylistic or rhetorical review (use a dedicated rhetoric/style skill)

DATA SOURCE:
  Local filesystem -- reads the target file and compares it against a rubric.
  The rubric is either provided by the user, inferred from a template referenced
  in the file, or built inline from the document's stated structure.

KEY RULES:
  - Structural quality gate only. Never judge whether a claim is accurate.
  - Every FAIL must include a specific suggested fix.
  - The scorecard is the deliverable. No prose preamble, no summary paragraph after.
  - If the rubric cannot be determined, ask the user before proceeding.
-->

# verify -- Structural Verification

**WHY:** Analyses and structured documents that skip sections or omit evidence get treated as ground truth and degrade every downstream decision that references them. This skill catches structural gaps before that happens.

---

## Step 1: Identify the Target

Determine what is being verified and locate the file.

If the user provides a file path, use it directly. If the user says "verify this" in a session where an output was just generated, use that file. If ambiguous, ask: "Which file should I verify?"

Determine the rubric:
- If the file references a template (e.g., "generated from template X"), use that template as the rubric.
- If the user provides a rubric or expected section list, use that.
- If the file declares its own structure in a header or table of contents, derive the rubric from that.
- If none of the above apply, ask the user what assertions to run against the file.

---

## Step 2: Run Assertions

Build an assertion table from the rubric. Each assertion checks one structural element. Common assertion patterns:

| Pattern | What it checks |
|---------|----------------|
| Header present | File has the expected top-level title, generation date, and source list |
| Section exists | A required section is present with a populated header |
| Section non-empty | A required section contains substantive content (not just a placeholder) |
| Required subsections | A parent section contains all named child sections |
| Evidence citations | Claims in the document cite specific data (quotes, metrics, references) |
| Quantitative fields populated | Required numbers, dates, or ranges are filled in |
| Data scope disclosed | The document states the time range, sample size, or scope of inputs |
| Source identification | Sources, authors, or subjects are clearly identified |
| Gap disclosure | Known data gaps or limitations are acknowledged |
| Open questions | Unresolved questions or follow-ups are listed |

Run each assertion against the file and record PASS or FAIL with a brief note for each FAIL.

---

## Step 3: Produce the Scorecard

Output format (use exactly this structure):

```
## Verification Scorecard: [filename]
Rubric: [template name | user-provided | inferred from document]
Date verified: [today]

| # | Assertion | Verdict | Notes |
|---|-----------|---------|-------|
| 1 | [name]    | PASS    |       |
| 2 | [name]    | FAIL    | [what is missing] |
...

### Overall Verdict: [PASS | FAIL]

[If FAIL, list each gap with a concrete suggested fix. Format as numbered items
matching the assertion numbers that failed. Each fix should state exactly what
to add or change in the file.]
```

If every assertion passes, the Overall Verdict is PASS and no fix list is needed. State "All assertions passed. This output meets its structural contract." and stop.

If any assertion fails, the Overall Verdict is FAIL. The fix list is mandatory.

---

## Guardrails

This skill is a structural quality gate. It checks whether the output covered what it was supposed to cover, not whether the claims are correct or the interpretation is sound. A document can pass every assertion here and still contain a wrong claim. Conversely, a document can fail here on a missing section while being brilliant in the sections it does have.

The distinction matters. Structural completeness is a prerequisite for treating an output as referenceable ground truth. Content accuracy requires human judgment and, ideally, real-world validation. This skill handles the first concern only.

Do not soften FAIL verdicts. Do not add qualifiers like "mostly complete" or "nearly there." An assertion passes or it fails. The suggested fixes tell the user exactly what to do about it.
