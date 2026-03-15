---
name: battle-cards
description: Generate competitive battle cards from meeting notes — per-competitor positioning, advantages, objection scripts, and win/loss tracking. Optionally enriched with web research.
user_invocable: true
arguments: "[meeting_notes_path] [--competitor competitor_name] [--format markdown|notion]"
---

# Battle Cards Generator

Scan meeting notes for competitor mentions, build per-competitor battle cards with positioning, advantages, counters, and objection scripts.

## Inputs

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `meeting_notes_path` | No | `$MEETING_NOTES_PATH` env var, then `./meeting-notes/` | Directory containing .md meeting notes |
| `--competitor` | No | All detected | Filter to a single competitor |
| `--format` | No | `markdown` | Output format: `markdown` or `notion` |

## Execution

### Step 1: Scan for Competitor Mentions

```
1. Resolve notes path (same logic as weekly-deal-review)
2. Glob for *.md files
3. For each file, search for competitor signals using references/meeting-parsing-guide.md:
   - "actuellement on utilise X" / "currently we use X"
   - "par rapport à X" / "compared to X"
   - "comme X" / "like X"
   - "X fait/propose..." / "X does/offers..."
   - Brand names near comparison/alternative words
4. Build a competitor registry:
   competitor:
     name: [detected name]
     mentions: [count]
     deals: [list of prospect names where mentioned]
     quotes: [verbatims about this competitor]
     context: [full sentences mentioning competitor]
5. If --competitor is set, filter to that competitor only
6. If no competitors found, report: "No competitor mentions detected in [N] notes."
```

### Step 2: Web Research (Optional Enrichment)

```
If WebSearch tool is available:
  For each competitor:
  1. Search: "[competitor name] product features pricing"
  2. Search: "[competitor name] vs alternatives [your industry]"
  3. Extract: key features, pricing model, positioning, recent news
  4. Merge with meeting note data

If WebSearch is NOT available:
  - Skip this step
  - Add note: "Web research unavailable. Cards based on meeting notes only.
    For richer cards, enable WebSearch or add competitor intel manually."
```

### Step 3: Generate Per-Competitor Battle Card

For each competitor, produce:

```markdown
# Battle Card: [Competitor Name]

**Last mentioned:** [date] | **Deals involved:** [count] | **Threat level:** [🔴🟡🟢]

## Their Positioning
[How the competitor positions themselves — from prospect quotes + web research]

## Our Advantages (Why We Win)

| Advantage | Evidence | Prospect Quote |
|-----------|----------|----------------|
| [Advantage 1] | [Specific capability] | "[Quote from prospect]" — [Name], [Company] |
| [Advantage 2] | [Specific capability] | "[Quote or observation]" |

## Their Advantages (Where They're Strong)

| Strength | Our Counter | Script |
|----------|-------------|--------|
| [Their strength 1] | [How we address it] | "[What to say when prospect raises this]" |
| [Their strength 2] | [How we address it] | "[What to say]" |

## Objection Scripts

When a prospect says... → Respond with...

| Prospect Says | Response Script |
|---------------|-----------------|
| "We already use [Competitor]" | "[Acknowledgment + differentiation + bridge question]" |
| "[Competitor] is cheaper" | "[Value reframe + TCO argument + proof point]" |
| "[Competitor] has [feature]" | "[Feature comparison + unique value + redirect]" |

*Scripts are generated from real objections in meeting notes. Each script follows:*
*1. Acknowledge → 2. Differentiate → 3. Bridge to prospect's specific need*

## Win/Loss Record

| Prospect | Outcome | Key Factor | Date |
|----------|---------|------------|------|
| [Company A] | Won ✅ | [Why we won] | [Date] |
| [Company B] | Lost ❌ | [Why we lost] | [Date] |
| [Company C] | Active 🔄 | [Current status] | [Date] |

*Win/loss is inferred from deal stage in notes. Mark as "Active" if deal is still open.*
```

### Step 4: Competitive Landscape Summary

After all individual cards, add a landscape overview:

```markdown
# Competitive Landscape Summary

## Competitor Matrix

| Competitor | Mentions | Deals | Threat | Key Differentiator | Our Counter |
|------------|----------|-------|--------|-------------------|-------------|
| [Name] | [N] | [N] | 🔴🟡🟢 | [Their main edge] | [Our response] |

## Threat Levels

- 🔴 **High** — Mentioned in 3+ deals, prospect has existing relationship, or competitor was chosen
- 🟡 **Medium** — Mentioned in 1-2 deals, prospect comparing options
- 🟢 **Low** — Passing mention, no active evaluation

## Top Patterns
- **Most mentioned competitor:** [Name] ([N] mentions across [N] deals)
- **Most common comparison point:** [Feature/price/ease of use]
- **Our strongest differentiator:** [Based on win patterns]
- **Biggest competitive risk:** [Based on loss patterns]
```

### Step 5: Output

**Markdown (default):**
- Print full report to console
- Offer to save as `battle-cards-YYYY-MM-DD.md`

**Notion (--format notion):**
- Check for Notion MCP tools
- If available: create page in workspace, return URL
- If not: fall back to markdown with notice

## Tips for the Agent

- **Don't guess competitor features.** Only state what's evidenced in notes or web research. Flag uncertainties.
- **Scripts should feel natural.** Avoid aggressive language — focus on curiosity and value, not competitor bashing.
- **Update over time.** Each run overwrites previous cards. Mention if a competitor's threat level has changed since last review.
- **Unnamed competitors.** If prospect says "our current solution" without naming it, create a card titled "[Company A]'s Current Solution" and note what's known.
