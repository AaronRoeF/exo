---
name: health
description: >
  Trigger on: "whoop sleep," "whoop recovery," "whoop today," "whoop week,"
  "whoop train," "whoop month," "whoop coach," "how did I sleep," "how's my recovery,"
  "health brief," "should I train hard today," "coach me," or any request for
  WHOOP biometric data analysis.
  Do NOT trigger on general health questions unrelated to WHOOP data.
---

<!--
SKILL SUMMARY: health
==========================
Personal health and fitness tracking using WHOOP biometric data.

WHAT IT DOES:
  Pulls real-time biometric data from WHOOP and delivers interpreted health
  reports — sleep analysis, recovery scores, training readiness, and trend
  analysis across daily, weekly, and monthly timeframes. Every report
  includes real numbers, comparison to personal baselines, and actionable
  interpretation.

WHEN TO USE:
  - whoop sleep — last night's sleep breakdown
  - whoop recovery — today's recovery + HRV
  - whoop today — combined daily snapshot
  - whoop week — 7-day trend analysis
  - whoop train — workout guidance based on recovery
  - whoop month — 30-day deep dive with patterns
  - whoop coach — training coaching and healthspan guidance
  - whoop help / whoop man / whoop ? — show available commands

WHEN NOT TO USE:
  - Medical diagnoses or clinical interpretation
  - Prescription or supplement recommendations
  - Comparison to population norms (WHOOP data is personal baselines only)

DATA SOURCES:
  Whoop MCP (recovery, sleep, workouts, cycles, body measurements)

KEY RULES:
  - Always pull real data — never generic advice without numbers
  - Compare to personal baselines (rolling averages), not population norms
  - Flag concerning patterns but recommend consulting a doctor
  - Direct, personal tone — this is the user's personal health assistant
-->

# health — Personal Health & Fitness Tracking

**WHY:** Health data is useless without interpretation. This skill turns raw WHOOP biometrics into actionable insight — no dashboard-squinting required.
**WHO:** the user (personal use; requires a WHOOP subscription + the whoop MCP installed)
**HOW:** `whoop <command>` — pulls live data from WHOOP MCP, computes baselines and deltas, delivers interpreted reports
**WHAT:** Sleep analysis, recovery checks, training readiness, weekly/monthly trends, workout coaching

---

## Commands

| Command | Mode | Data Window |
|---|---|---|
| `whoop sleep` | **Sleep Report** | Last night + 7-day context |
| `whoop recovery` | **Recovery Check** | Today + 7-day context |
| `whoop today` | **Daily Health Brief** | Today + yesterday |
| `whoop week` | **Weekly Health** | Last 7 days |
| `whoop train` | **Training Readiness** | Today's recovery + 3-day strain |
| `whoop month` | **Monthly Health** | Last 30 days |
| `whoop coach` | **Coaching** | Recent workouts + recovery trends |
| `whoop help` | **Help** | Show this command list |

Natural language also works: "how did I sleep?", "how's my recovery?", "should I train hard today?", "coach me", etc.

---

## Step 1 — Identify the Mode

Match the user's input to a command above. Natural language mappings:

| If the user says... | Command |
|---|---|
| "How did I sleep?" / "sleep report" | `whoop sleep` |
| "How's my recovery?" / "recovery check" | `whoop recovery` |
| "Health brief" / "daily health" / "how am I doing" | `whoop today` |
| "Weekly health" / "health trends" / "this week" | `whoop week` |
| "Should I train hard today?" / "training readiness" | `whoop train` |
| "Monthly health" / "health deep dive" | `whoop month` |
| "Coach me" / "review my workout" / "fitness plan" | `whoop coach` |
| "whoop help" / "whoop man" / "whoop ?" | `whoop help` |

If ambiguous, default to `whoop today` (Daily Health Brief).

### Help Output

When the user runs `whoop help`, `whoop man`, or `whoop ?`, respond with:

```
## whoop — Personal Health & Fitness

Usage: whoop <command>

Commands:
  sleep      Last night's sleep breakdown (duration, stages, efficiency, vs. 7-day avg)
  recovery   Today's recovery score, HRV, resting HR, SpO2, skin temp
  today      Daily health brief — recovery + sleep + yesterday's strain
  week       7-day trends — recovery arc, sleep consistency, strain load
  train      Training readiness verdict — should you go hard or rest?
  month      30-day deep dive — patterns, correlations, actionable insights
  coach      Training coaching — workout review, healthspan guidance, programming advice

  help       Show this message (also: man, ?)

Data source: WHOOP band (live biometric data via MCP)
Not medical advice. Personal baselines, not population norms.
```

---

## Step 2 — Pull Data

### Date handling

All Whoop collection tools accept `start` and `end` in ISO 8601. Use current date to calculate windows.

### Data pulls by mode (always issue independent calls in parallel)

**Sleep Report:**
1. `whoop-get-sleep-collection` — `limit: 7`, `start: 7 days ago` (last night + context)
2. `whoop-get-recovery-collection` — `limit: 1` (today's recovery, driven by sleep)

**Recovery Check:**
1. `whoop-get-recovery-collection` — `limit: 7`, `start: 7 days ago` (today + context)
2. `whoop-get-sleep-collection` — `limit: 1` (last night, explains recovery)

**Daily Health Brief:**
1. `whoop-get-recovery-collection` — `limit: 1`
2. `whoop-get-sleep-collection` — `limit: 1`
3. `whoop-get-cycle-collection` — `limit: 2` (today + yesterday strain)
4. `whoop-get-workout-collection` — `limit: 3`, `start: yesterday`

**Weekly Health:**
1. `whoop-get-recovery-collection` — `limit: 7`, `start: 7 days ago`
2. `whoop-get-sleep-collection` — `limit: 7`, `start: 7 days ago`
3. `whoop-get-cycle-collection` — `limit: 7`, `start: 7 days ago`
4. `whoop-get-workout-collection` — `limit: 25`, `start: 7 days ago`

**Training Readiness:**
1. `whoop-get-recovery-collection` — `limit: 1`
2. `whoop-get-cycle-collection` — `limit: 3`, `start: 3 days ago`
3. `whoop-get-sleep-collection` — `limit: 1`
4. `whoop-get-workout-collection` — `limit: 5`, `start: 3 days ago`

**Monthly Health:**
1. `whoop-get-recovery-collection` — `limit: 25`, `start: 30 days ago` (paginate with `nextToken` if needed)
2. `whoop-get-sleep-collection` — `limit: 25`, `start: 30 days ago` (paginate)
3. `whoop-get-cycle-collection` — `limit: 25`, `start: 30 days ago` (paginate)
4. `whoop-get-workout-collection` — `limit: 25`, `start: 30 days ago` (paginate)

**Coaching:**
1. `whoop-get-workout-collection` — `limit: 25`, `start: 14 days ago` (training history)
2. `whoop-get-recovery-collection` — `limit: 14`, `start: 14 days ago` (recovery trend)
3. `whoop-get-sleep-collection` — `limit: 7`, `start: 7 days ago` (recent sleep)
4. `whoop-get-user-body-measurements` (baseline reference)
5. `whoop-get-cycle-collection` — `limit: 14`, `start: 14 days ago` (strain distribution)

---

## Step 3 — Compute Baselines and Deltas

For every metric reported, compute:

1. **Current value** — raw number from today/last night
2. **Baseline** — rolling average from context window (7-day or 30-day)
3. **Delta** — percentage or absolute change from baseline
4. **Direction** — improving, declining, or stable

### Time conversion

WHOOP stores durations in milliseconds. Convert: `milli / 1000 / 60 / 60` = hours. Display as `Xh Ym` (e.g., "7h 23m"). Calories: `kilojoule / 4.184` = kcal.

### Recovery score bands

| Score | Band | Meaning |
|-------|------|---------|
| 0-33% | Red | Body under significant stress. Prioritize rest. |
| 34-66% | Yellow | Partial recovery. Light to moderate training. |
| 67-100% | Green | Well recovered. Ready for high-intensity. |

### HRV interpretation (RMSSD in milliseconds)

- **>15% above baseline:** Excellent recovery, well-adapted
- **Within +/-10%:** Normal, steady state
- **10-20% below baseline:** Body under stress (training, sleep, illness, alcohol)
- **>20% below baseline for 3+ days:** Flag — warrants attention

### Resting heart rate

- **Below baseline:** Good — well recovered
- **3+ bpm above baseline:** Body stressed
- **Trending up over 7+ days:** Flag as potential overtraining

---

## Step 4 — Output by Mode

### Sleep Report

```
## Last Night's Sleep

**Duration:** [X]h [Y]m (needed [A]h [B]m — [surplus/deficit])
**Sleep Performance:** [X]% — [vs. 7-day avg]
**Efficiency:** [X]%

### Sleep Stages
- **Deep (SWS):** [X]h [Y]m ([Z]% of total — [vs. avg])
- **REM:** [X]h [Y]m ([Z]% of total — [vs. avg])
- **Light:** [X]h [Y]m
- **Awake:** [X]m ([N] disturbances)

### Key Signals
- **Respiratory Rate:** [X] rpm ([vs. avg])
- **Sleep Consistency:** [X]%

### What This Means
[1-2 sentences connecting the data. Be specific.]
```

### Recovery Check

```
## Today's Recovery

**Recovery Score:** [X]% ([Band]) — [vs. 7-day avg]

### Vitals
- **HRV:** [X]ms — [delta vs. avg, interpretation]
- **Resting HR:** [X] bpm — [delta vs. avg]
- **SpO2:** [X]% — [flag if below 95%]
- **Skin Temp:** [X]C — [vs. baseline]

### What's Driving This
[1-2 sentences connecting recovery to sleep and strain.]

### Recovery Trend (Last 7 Days)
[Date, score, band for each day. Note the arc.]
```

### Daily Health Brief

```
## Daily Health Brief — [Date]

### Recovery
**Score:** [X]% ([Band]) | **HRV:** [X]ms | **Resting HR:** [X] bpm
[One sentence interpretation.]

### Last Night's Sleep
**Duration:** [X]h [Y]m / [needed] ([Z]% performance)
**Deep:** [X]h [Y]m | **REM:** [X]h [Y]m | **Efficiency:** [X]%

### Yesterday's Strain
**Day Strain:** [X] | **Calories:** [X] kcal
**Workouts:** [sport, strain, duration for each]

### Bottom Line
[2-3 sentence synthesis. What does today look like? What should the user prioritize?]
```

### Weekly Health

```
## Weekly Health — [Date Range]

### Recovery Arc
[Table: Day, Recovery %, HRV, Resting HR, Band]
**7-Day Avg:** [X]% recovery, [Y]ms HRV
**Trend:** [Describe: improving, declining, volatile]

### Sleep Consistency
[Table: Day, Duration, Performance %, Efficiency %]
**Avg Duration:** [X]h [Y]m (need: [A]h [B]m)
**Avg Deep:** [X]h [Y]m | **Avg REM:** [X]h [Y]m

### Strain Load
[Table: Day, Strain, Workouts, Calories]
**Total Weekly Strain:** [X]
**Workout Count:** [N] sessions

### Key Patterns
[3-4 bullet points identifying correlations from the data.]

### Recommendations
[2-3 actionable items grounded in the week's data.]
```

### Training Readiness

```
## Training Readiness — [Date]

### Verdict: [GO HARD / MODERATE DAY / TAKE IT EASY / REST DAY]

### The Data
- **Recovery:** [X]% ([Band]) — [vs. avg]
- **HRV:** [X]ms — [vs. avg]
- **Last Night's Sleep:** [X]h [Y]m ([Z]% performance)
- **Recent Strain:** [last 3 days values]

### Recommendation
[2-4 sentences. Framework by band:]

**Green + adequate sleep + manageable strain:** Go hard. High-intensity, heavy lifting, long endurance all on the table.

**Yellow + mixed signals:** Moderate session. Steady-state cardio, moderate lifting, skill work. Avoid sustained zone 4+.

**Red or compounding negatives:** Active recovery only. Walk, stretch, mobility. Training through this extends the hole.

### Strain Budget
Target strain for today: [X]-[Y] (your avg workout strain: [Z])
```

### Monthly Health

```
## Monthly Health — [Date Range]

### 30-Day Averages
[Table: Metric, This Month, change direction]

### Recovery Distribution
- **Green:** [N] days ([X]%)
- **Yellow:** [N] days ([X]%)
- **Red:** [N] days ([X]%)

### Sleep Analysis
[Avg duration, avg need, net balance, deep/REM breakdown, best/worst nights]

### Strain & Training
[Total strain, workout count, breakdown by sport, highest strain day, rest days]

### Patterns & Correlations
[3-5 data-driven observations. Connect sleep→recovery, strain→recovery, consistency→HRV.]

### Actionable Insights
[3-4 specific recommendations grounded in the month's data.]
```

### Coaching

```
## Coaching Review — [Date or Date Range]

### Your Recent Training Profile
**Last 14 days:** [N] workouts | Avg strain: [X] | Total calories: [Y] kcal
**Sports:** [breakdown by type with count and avg strain each]
**Recovery avg:** [X]% | **Strain-to-recovery ratio:** [description]

### Workout Breakdown
[For each recent workout from Whoop:]
- **[Date] — [Sport]:** [duration], strain [X], avg HR [Y], max HR [Z], [calories] kcal
  [If HR zone data: time in zone 3+: Xm]

### What Whoop Sees
[Analysis of training patterns from the data: frequency, intensity distribution,
recovery balance, whether training load is progressing, plateauing, or excessive.]

### Coaching Assessment
[2-4 paragraphs of training guidance grounded in the data. Address:]
- **Volume & frequency:** Is the user training enough? Too much? Is there periodization?
- **Intensity distribution:** What % of training is low/moderate/high intensity?
  The 80/20 rule: ~80% should be low-moderate, ~20% high intensity for longevity.
- **Recovery compliance:** Is the user respecting red/yellow days or pushing through?
- **Sleep as a training variable:** Is sleep supporting the training load?
- **Healthspan lens:** Frame recommendations around longevity, not just performance.
  Zone 2 cardio, grip strength, mobility, VO2 max maintenance matter more than
  peak strain scores.

### Specific Exercises (if provided)
[When the user uploads or describes specific workout details — sets, reps, weights —
analyze them here:]
- **Progressive overload:** Are weights/reps increasing over time?
- **Balance:** Push/pull ratio, upper/lower split, any neglected movement patterns
- **Volume per muscle group:** Adequate stimulus without overreaching?
- **Form notes:** If the user describes issues, address them

### Recommendations
[3-5 specific, actionable training recommendations. Example:]
1. "Add a dedicated Zone 2 session (30-45 min, conversational pace). Your data
   shows 85% of training is high-intensity — flipping to 70/30 would improve
   recovery and VO2 max long-term."
2. "Your 3-day training streaks consistently produce yellow recoveries by day 3.
   Try a 2-on/1-off pattern."
```

**Handling specific workout details:**

Whoop provides strain, HR, duration, and sport type — but NOT specific exercises (sets, reps, weights, movements). When the user wants coaching on weightlifting or specific exercises:

1. Ask: "Whoop shows your [sport] session on [date] — [strain], [duration], [HR data]. What did you do specifically? (exercises, sets, reps, weight)"
2. The user can paste a workout log, screenshot, or describe it
3. Combine the WHOOP biometric layer (HR zones, strain, recovery) with the exercise specifics for a complete coaching picture
4. Track uploaded workout details in conversation context — reference prior sessions when giving progressive overload guidance

**Healthspan coaching principles:**
- Prioritize VO2 max maintenance (the strongest predictor of all-cause mortality)
- Zone 2 cardio: 150-180 min/week minimum
- Strength training: maintain muscle mass, grip strength, bone density
- Mobility and stability: prevent injury, maintain independence
- Sleep optimization: the force multiplier for everything else
- Avoid chronic overtraining — sustainable consistency beats heroic effort
- Frame every recommendation in terms of decades, not weeks

---

## Error Handling

**Auth expired:** "WHOOP authentication has expired. Re-authenticate via the whoop MCP setup script."

**Score not available:** If `score_state` is not `SCORED` or `score` is null, say: "Recovery/sleep isn't scored yet — WHOOP may still be processing. Try again in a bit."

**No data for period:** Report what's available, note the gap.

---

## Guardrails

- **Not medical advice.** When flagging anomalies: "Worth mentioning to your doctor" — never diagnose.
- **Flag these patterns:** SpO2 consistently <95%, resting HR trending up 7+ days, HRV >30% below baseline for 3+ days, respiratory rate spikes.
- **Data-first, always.** Never say "you slept okay" — say "you slept 6h 48m, 42 minutes below your 7-day average."
- **Personal baselines over population norms.** Your good HRV is your good HRV — never compare to other people's numbers.
- **Direct, personal tone.** Use "you" throughout. Be honest about bad numbers.
- **No supplement or diet advice.** Stick to sleep, training, and recovery recommendations.
- **No emojis.** No bullet points in interpretation paragraphs — use prose.

---

## Gotchas

Known failure modes and WHOOP API edge cases. Check here first when something breaks.

| Gotcha | What Happens | What To Do |
|--------|-------------|------------|
| **OAuth token expiry** | Access tokens expire every hour. Any API call returns a 401 or generic `Error` string. The MCP server has no automatic refresh logic — it passes the error through as-is. | Re-authenticate via the whoop MCP setup script. The symptom is usually a cryptic axios error, not a clear "auth expired" message. |
| **`score` is null / `score_state` not `SCORED`** | Recovery, sleep, workout, and cycle objects all have an optional `score` field. When WHOOP is still processing, `score_state` will be `PENDING_STRAIN` or `UNSCORABLE` and `score` will be undefined. Normal for current-day data early in the morning, or if the band was off. | Check `score_state` before accessing any score fields. If not `SCORED`, report the data as unavailable and suggest trying again later. Do not treat missing scores as zeros. |
| **Sleep processing delay** | Sleep data is not available the instant you wake up. WHOOP takes 15-45 minutes after detecting wakefulness to finalize sleep staging and scores. Early-morning `whoop sleep` calls often return yesterday's sleep as the most recent scored record. | If the most recent sleep record's `end` timestamp is not from last night, tell the user the data is still processing and to try again shortly. |
| **Recovery requires scored sleep** | Recovery score is derived from sleep. If sleep was not tracked (band died, band off, sleep not scored), recovery will have a non-`SCORED` `score_state` and no score for that day. There is no way to get a recovery score without a completed sleep. | Report that recovery is unavailable because sleep was not tracked. Do not guess or extrapolate from prior days. |
| **Naps mixed into sleep collection** | `whoop-get-sleep-collection` returns both primary sleep and naps in the same collection. Naps have `nap: true`. Naively taking the first record as "last night's sleep" might grab an afternoon nap instead. | Filter on `nap: false` when looking for primary overnight sleep. Include naps separately if relevant to the report. |
| **Pagination cap at 25** | All collection endpoints max out at `limit: 25` per request. Monthly mode needs 30 days of data, so a single call is not enough. The API returns a `next_token` field when more records exist. | Always check for `next_token` in the response and issue follow-up calls when pulling 25+ records (monthly mode, coaching mode with long windows). |
| **UTC date boundaries** | WHOOP stores all timestamps in UTC. The API's `start` and `end` filter parameters also operate in UTC. A query for "today" using midnight local time can miss or include records from the wrong day depending on timezone offset. Every record includes a `timezone_offset` string but this is informational only. | Convert local dates to UTC using the known timezone offset. For daily queries, pad the window by a day in both directions and filter results locally, rather than relying on exact UTC boundaries. |
| **Strain accumulates throughout the day** | The current day's cycle strain is a running total. Querying strain at 10am shows a much lower number than the final daily strain. This is expected behavior, not an error. | When reporting today's strain, note that it is a live value and will increase throughout the day. Compare to prior days' final strain with that caveat. |
| **Workout auto-detection gaps** | WHOOP auto-detects some activities but misses others (especially strength training, yoga, or low-HR activities). If the user says they trained but no workout appears, the band may not have detected it. | Acknowledge the gap and suggest logging the activity manually in the WHOOP app. Do not assume no workout occurred just because the API returned nothing. |
| **MCP server silent failure on startup** | If the WHOOP MCP server fails to load at session init (bad token file, Node crash), it fails silently. The `whoop-*` tools simply will not appear in the deferred tool set. | If whoop tools are not responding, verify the server loaded by checking whether whoop tools appear in the tool list. If absent, re-run the whoop MCP setup script. |
