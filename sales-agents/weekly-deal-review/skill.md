---
name: weekly-deal-review
description: Parse meeting notes to generate a weekly deal pipeline review with prospect data, budgets, objections, and next steps. Works with Gemini Meet notes, Claap transcripts, or raw text.
user_invocable: true
arguments: "[meeting_notes_path] [--format markdown|notion] [--range 7d|30d|all]"
---

# Weekly Deal Review

Parse all meeting notes and produce a structured pipeline review — deal summary table + individual deal cards.

## Inputs

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `meeting_notes_path` | No | `$MEETING_NOTES_PATH` env var, then `./meeting-notes/` | Directory containing .md meeting notes |
| `--format` | No | `markdown` | Output format: `markdown` or `notion` |
| `--range` | No | `7d` | Time range: `7d`, `30d`, `all` |

## Execution

### Step 1: Locate Meeting Notes

```
1. Resolve notes path:
   - Use argument if provided
   - Else use $MEETING_NOTES_PATH env var
   - Else use ./meeting-notes/
2. Glob for *.md files in that directory
3. If --range is set, filter by date:
   - Extract date from filename (YYYY_MM_DD pattern) or first line of file
   - Keep only files within the range
4. If no files found, report error and stop
```

### Step 2: Parse Each Meeting Note

For each .md file, apply the parsing algorithm from `references/meeting-parsing-guide.md`:

```
Extract:
  - date: from filename or first line
  - prospect_company: from email domains + title + summary
  - contacts: names and emails from Invités line
  - source: how the lead came in (inbound/outbound/referral — infer from context)
  - budget: amounts + context (monthly/one-time/per-unit)
  - objections: list of concerns raised by prospect
  - must_haves: features/requirements the prospect explicitly needs
  - competitors: any competing solutions mentioned
  - verbatims: direct quotes from the prospect
  - next_steps: action items with owners and deadlines
  - deal_stage: Discovery | Qualification | Proposal | Negotiation | Closed Won | Closed Lost
```

### Step 3: Generate Pipeline Summary Table

```markdown
## Pipeline Review — Week of [DATE]

| Prospect | Contact | Stage | Budget | Key Objection | Next Step | Risk |
|----------|---------|-------|--------|----------------|-----------|------|
| Company A | Name (email) | Qualification | €5-10K/mo | Platform recognition | Create account by Sat | 🟡 |
| Company B | Name (email) | Proposal | €2K | Content quality | Send brief | 🟢 |
```

**Risk levels:**
- 🟢 Low — clear next steps, engaged prospect, no blockers
- 🟡 Medium — some objections, timeline unclear, or missing decision maker
- 🔴 High — strong objections, competitor preference, stalled, or no budget

### Step 4: Generate Individual Deal Cards

For each prospect, generate a detailed card:

```markdown
### [Prospect Company] — [Stage]

**Contact:** Name <email> | **Date:** YYYY-MM-DD | **Source:** inbound/outbound

#### Budget
- [Amount and context]

#### Key Needs
- [Must-have 1]
- [Must-have 2]

#### Objections
- [Objection 1]
- [Objection 2]

#### Competitors
- [Competitor mentions with context]

#### Prospect Quotes
> "[Verbatim 1]" — Speaker Name
> "[Verbatim 2]" — Speaker Name

#### Next Steps
- [ ] [Action] — Owner — Deadline
- [ ] [Action] — Owner — Deadline

#### Deal Notes
[Any additional context, risks, or strategy notes]
```

### Step 5: Output

**Markdown (default):**
- Print the full report to console
- If a file path is obvious (e.g., user's working directory), offer to save as `deal-review-YYYY-MM-DD.md`

**Notion (--format notion):**
- Check if Notion MCP tools are available (`mcp__plugin_Notion_notion__notion-search`)
- If available:
  1. Search for a "Deal Reviews" database or page
  2. Create a new page with the review content
  3. Return the Notion URL
- If NOT available:
  - Fall back to markdown output
  - Print: "Notion MCP not available. Output as markdown. To enable Notion, install the Notion MCP plugin."

## Aggregation Insights

After all deal cards, add a summary section:

```markdown
## Insights

- **Total active deals:** X
- **Total pipeline value:** €X - €Y (range based on budget mentions)
- **Deals needing follow-up this week:** X
- **Most common objection:** [theme]
- **Competitor landscape:** [most mentioned competitors]
- **Stalled deals (no activity > 14 days):** [list]
```

## Error Handling

- No notes directory found → clear error message with path tried
- No .md files in directory → suggest checking path or date range
- Notes with no extractable data → skip with warning, don't fail the whole review
- Malformed dates → best-effort parsing, warn user
