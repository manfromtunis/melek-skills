---
name: sales-pipeline
description: Orchestrator that runs all sales-agents skills in sequence — weekly deal review, battle cards, help center gaps — and compiles a unified weekly pipeline report. Supports full or partial runs.
user_invocable: true
arguments: "[meeting_notes_path] [--config full|review-only|compete-only|docs-only] [--format markdown|notion]"
---

# Sales Pipeline Orchestrator

Run all sales-agents skills in sequence, compile a unified weekly report. This is the "one command" entry point for your weekly sales review.

## Inputs

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `meeting_notes_path` | No | `$MEETING_NOTES_PATH` env var, then `./meeting-notes/` | Directory containing .md meeting notes |
| `--config` | No | `full` | Run mode (see below) |
| `--format` | No | `markdown` | Output format: `markdown` or `notion` |

**Run modes:**
| Mode | Skills Run |
|------|-----------|
| `full` | weekly-deal-review → battle-cards → help-center-gaps |
| `review-only` | weekly-deal-review only |
| `compete-only` | battle-cards only |
| `docs-only` | help-center-gaps only |

## Execution

### Step 0: Pre-Flight Check

Before running any skill, verify the environment:

```
1. NOTES PATH
   - Resolve meeting_notes_path (argument → $MEETING_NOTES_PATH → ./meeting-notes/)
   - Glob for *.md files
   - Report: "Found [N] meeting notes in [path]"
   - If 0 files: STOP with clear error

2. AVAILABLE TOOLS (check once, share with sub-skills)
   - Notion MCP: check if mcp__plugin_Notion_notion__notion-search is available
   - WebSearch: check if WebSearch tool is available
   - GitHub CLI: check if `gh --version` succeeds
   - Report:
     ✅ Notion MCP — available (will create Notion pages)
     ❌ WebSearch — not available (battle cards will use notes only)
     ✅ GitHub CLI — available (can create issues)

3. DOCS PATH (for help-center-gaps)
   - Check $DOCS_PATH env var
   - If set: verify directory exists
   - If not: note "No docs path — gap analysis will skip cross-reference"

4. Print pre-flight summary and proceed
```

### Step 1: Run Weekly Deal Review

```
If config is "full" or "review-only":
  1. Invoke /weekly-deal-review with:
     - meeting_notes_path: [resolved path]
     - --format: [user's format choice]
     - --range: 7d (default weekly)
  2. Capture output as DEAL_REVIEW
  3. Extract key metrics:
     - deal_count: number of active deals
     - pipeline_value: total budget range
     - deals_needing_followup: count
     - stages: breakdown by stage
```

### Step 2: Run Battle Cards

```
If config is "full" or "compete-only":
  1. Invoke /battle-cards with:
     - meeting_notes_path: [resolved path]
     - --format: [user's format choice]
  2. Capture output as BATTLE_CARDS
  3. Extract key metrics:
     - competitor_count: unique competitors detected
     - high_threat: competitors at 🔴 level
     - most_mentioned: top competitor name
```

### Step 3: Run Help Center Gaps

```
If config is "full" or "docs-only":
  1. Invoke /help-center-gaps with:
     - meeting_notes_path: [resolved path]
     - --docs: $DOCS_PATH if available
     - --format: [user's format choice]
     - --issues: false (don't auto-create issues in orchestrated mode)
  2. Capture output as DOC_GAPS
  3. Extract key metrics:
     - p1_gaps: count of P1 documentation gaps
     - p2_gaps: count of P2 gaps
     - total_questions: total questions extracted
```

### Step 4: Compile Unified Report

```markdown
# Weekly Sales Pipeline Report — [DATE]

## Executive Summary

| Metric | Value |
|--------|-------|
| Active Deals | [deal_count] |
| Pipeline Value | [pipeline_value] |
| Deals Needing Follow-up | [deals_needing_followup] |
| Competitors Tracked | [competitor_count] |
| High-Threat Competitors | [high_threat] |
| P1 Doc Gaps | [p1_gaps] |
| Prospect Questions Logged | [total_questions] |

## Key Actions This Week

Based on all analyses, prioritized actions:

1. **[Most urgent deal action]** — from deal review
2. **[Competitive response needed]** — from battle cards
3. **[Documentation to write]** — from gap analysis
4. [Additional actions...]

## Pipeline by Stage

| Stage | Deals | Value | Trend |
|-------|-------|-------|-------|
| Discovery | [N] | [range] | [↑↓→] |
| Qualification | [N] | [range] | [↑↓→] |
| Proposal | [N] | [range] | [↑↓→] |
| Negotiation | [N] | [range] | [↑↓→] |

---

## Full Deal Review

[DEAL_REVIEW output here]

---

## Competitive Intelligence

[BATTLE_CARDS output here]

---

## Documentation Gaps

[DOC_GAPS output here]
```

### Step 5: Output

**Markdown (default):**
- Print unified report to console
- Save as `pipeline-report-YYYY-MM-DD.md` in current directory

**Notion (--format notion):**
- Check for Notion MCP
- If available:
  1. Search for "Sales Pipeline" page/database
  2. Create new page with report content
  3. Return Notion URL
- If not: fall back to markdown

## Scheduling

### Claude Code Cron

To run this automatically every Monday:

```bash
# In Claude Code, use:
/cron create "Every Monday at 9am" "/sales-pipeline --config full"
```

### OpenClaw Workflow

This skill is designed to be convertible to an OpenClaw scheduled workflow. The orchestrator's sequential skill invocation maps directly to OpenClaw's step-based execution model:

```yaml
# Example OpenClaw trigger (future)
name: weekly-sales-pipeline
schedule: "0 9 * * 1"  # Every Monday 9am
steps:
  - skill: weekly-deal-review
    args: "--range 7d"
  - skill: battle-cards
  - skill: help-center-gaps
  - compile: unified-report
notify: slack  # or email
```

## Error Handling

- **Partial failure:** If one skill fails, continue with the others. Mark the failed section as "[SKILL FAILED — error message]" in the report.
- **No notes:** Stop at pre-flight. Don't run partial skills on empty data.
- **Tool unavailability:** Degrade gracefully per sub-skill's own fallback logic. The pre-flight check warns upfront.

## Tips for the Agent

- **Don't duplicate work.** Each sub-skill handles its own parsing. The orchestrator just invokes and compiles.
- **Key Actions are the most valuable part.** Spend time making them specific and actionable, not generic.
- **Trend data requires history.** On first run, skip trend arrows. On subsequent runs, compare with previous report if available.
