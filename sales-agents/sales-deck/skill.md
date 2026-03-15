---
name: sales-deck
description: Generate a personalized sales deck for a prospect using real quotes and data extracted from meeting notes. Produces an 8-slide markdown deck with verbatims, not generic copy.
user_invocable: true
arguments: "<prospect_name> [meeting_notes_path] [--brand brand_skill_name]"
---

# Sales Deck Generator

Generate a prospect-specific sales deck using real data from meeting notes — verbatims, objections, budget context, and needs.

## Inputs

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `prospect_name` | **Yes** | — | Company or contact name to search for in notes |
| `meeting_notes_path` | No | `$MEETING_NOTES_PATH` env var, then `./meeting-notes/` | Directory containing .md meeting notes |
| `--brand` | No | `$BRAND_SKILL` env var | Name of a brand guidelines skill to invoke for tone/visual direction |

## Execution

### Step 1: Find Prospect Notes

```
1. Resolve notes path (same logic as weekly-deal-review)
2. Glob for *.md files
3. Search each file for prospect_name (case-insensitive, partial match)
   - Check: title, Invités line, email domains, body text
4. Collect ALL matching files (prospect may have multiple meetings)
5. Sort by date (most recent first)
6. If no matches: report error, suggest checking the name spelling
```

### Step 2: Extract Prospect Data

From all matching notes, build a unified prospect profile:

```
prospect:
  company: [name]
  contacts: [list of names + emails]
  industry: [from summary/context]
  meetings: [count and dates]

needs:
  - [explicit requirements from notes]
  - [implicit needs inferred from problems described]

budget:
  range: [amount or range]
  context: [monthly/annual, what it covers]

objections:
  - text: [objection]
    context: [when/why raised]

competitors:
  - name: [competitor]
    context: [what prospect said about them]

verbatims:
  - quote: [exact words]
    speaker: [name]
    topic: [what it relates to]

next_steps:
  - [action items from most recent meeting]

deal_stage: [current stage]
```

### Step 3: Load Brand Guidelines (Optional)

```
If --brand argument or $BRAND_SKILL env var is set:
  1. Invoke the brand skill (e.g., /clip2earn-brand)
  2. Extract: tone of voice, key messaging, visual direction, terminology
  3. Apply throughout deck generation

If no brand skill:
  1. Use neutral professional tone
  2. Skip brand-specific terminology
  3. Note in output: "No brand skill loaded. Add --brand <skill> for branded output."
```

### Step 4: Generate 8-Slide Deck

Output as structured markdown. Each slide is a `## Slide N:` section.

```markdown
# Sales Deck — [Prospect Company]
Generated: [DATE] | Based on [N] meeting(s)

---

## Slide 1: Cover

**[Prospect Company] × [Your Company]**
*[One-line value proposition tailored to prospect's industry]*

Meeting history: [dates of meetings]
Prepared for: [primary contact name]

---

## Slide 2: Context — What We Heard

Use real verbatims from the prospect. This slide builds trust by showing you listened.

> "[Verbatim about their challenge]" — [Speaker]

> "[Verbatim about their goals]" — [Speaker]

**Key context:**
- [Industry/company context from notes]
- [Current situation summary]

---

## Slide 3: The Problems

Map prospect's stated problems. Use their language, not yours.

| Problem | Impact | Source |
|---------|--------|--------|
| [Problem from notes] | [Business impact] | [Meeting date] |
| [Problem from notes] | [Business impact] | [Meeting date] |

---

## Slide 4: Our Solution

Connect each problem to your solution. Reference specific features/capabilities discussed in meetings.

| Their Problem | Our Answer | How It Works |
|---------------|-----------|--------------|
| [Problem 1] | [Solution 1] | [Brief mechanism] |
| [Problem 2] | [Solution 2] | [Brief mechanism] |

---

## Slide 5: Implementation Plan

Based on next steps and timeline discussed in meetings.

| Phase | What | Timeline | Owner |
|-------|------|----------|-------|
| 1. Setup | [From next steps] | [From notes] | [From notes] |
| 2. Launch | [Inferred] | [Inferred] | [TBD] |
| 3. Optimize | [Inferred] | [Inferred] | [TBD] |

---

## Slide 6: ROI Projection

Build from budget data and prospect's own metrics when available.

**Their current spend:** [Budget data from notes]
**Expected outcome:**
- [Metric improvement based on discussed goals]
- [Cost comparison if competitor data available]

> "[Any verbatim about expected results or metrics]" — [Speaker]

*Note: If no budget/metrics data in notes, use industry benchmarks and flag as estimates.*

---

## Slide 7: Objection Handling

Pre-address every objection raised in meetings.

| Concern Raised | Our Response | Proof Point |
|----------------|-------------|-------------|
| "[Objection verbatim]" | [Counter-argument] | [Evidence/case study] |
| "[Objection verbatim]" | [Counter-argument] | [Evidence/case study] |

---

## Slide 8: Next Steps

Pull directly from the most recent meeting's action items.

**Agreed next steps:**
- [ ] [Action] — [Owner] — [Deadline]
- [ ] [Action] — [Owner] — [Deadline]

**Proposed additions:**
- [ ] [Suggested next action based on deal stage]
```

### Step 5: Output

- Print the full deck to console as markdown
- Offer to save as `sales-deck-[prospect]-YYYY-MM-DD.md`
- If `--brand` was used, note which brand guidelines were applied

## Tips for the Agent

- **Never invent verbatims.** Only use actual quotes from the notes. If no direct quotes exist, paraphrase and mark as "paraphrased from [date] meeting."
- **Flag data gaps.** If a slide has insufficient data (e.g., no budget mentioned), include it with a `[DATA NEEDED]` placeholder and suggest what to ask in the next meeting.
- **Multiple meetings = richer deck.** When multiple notes exist, show evolution of the relationship across slides.
- **Competitor slides are optional.** If competitor data exists, consider adding a "Why Us vs [Competitor]" slide between slides 6 and 7.
