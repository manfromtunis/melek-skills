---
name: discord-support-gaps
description: Analyze Discord support messages to find bugs, feature requests, and UX gaps. Clusters by topic, deduplicates against Notion tickets, creates new tickets for gaps.
user_invocable: true
arguments: "[--channel channel_id] [--days 7] [--messages-file path] [--db notion_db_id] [--format markdown|notion] [--dry-run]"
---

# Discord Support Gap Analysis

Extract bug reports, feature requests, and UX confusion signals from Discord support channels. Cluster by topic, deduplicate against existing Notion tickets, and create new tickets for gaps.

## Inputs

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--channel` | No | `$DISCORD_SUPPORT_CHANNEL` env var | Discord channel ID to read |
| `--days` | No | `7` | How many days back to analyze |
| `--messages-file` | No | *(none)* | Path to exported Discord messages (.md) — fallback if no Discord MCP |
| `--db` | No | `$CLIP2EARN_TICKETS_DB` env var | Notion database ID for ticket dedup + creation |
| `--format` | No | `markdown` | Output format: `markdown` or `notion` |
| `--dry-run` | No | `false` | Report gaps without creating tickets |

## Execution

### Step 0: Pre-Flight Check

```
1. DISCORD MCP
   - Probe for Discord MCP tools (any tool matching mcp__discord__*)
   - If available: ✅ Discord MCP — will read channel live
   - If not: check --messages-file argument
     - If provided: ✅ Messages file — will parse [path]
     - If neither:
       ❌ No Discord source available.

       To use Discord MCP, add to .claude/settings.json:
       {
         "mcpServers": {
           "discord": {
             "command": "npx",
             "args": ["-y", "discord-mcp-server"],
             "env": { "DISCORD_TOKEN": "<your-bot-token>" }
           }
         }
       }
       Bot needs: MESSAGE_CONTENT intent + READ_MESSAGE_HISTORY permission.

       Or provide --messages-file <path> with exported Discord messages.
       STOP here.

2. NOTION MCP
   - Probe for Notion MCP tools (mcp__plugin_Notion_notion__notion-search)
   - If available: ✅ Notion MCP — will cross-reference and create tickets
   - If not: ⚠️ Notion MCP not available — will skip dedup, output markdown only

3. RESOLVE ARGUMENTS
   - channel: --channel arg → $DISCORD_SUPPORT_CHANNEL env var
   - db: --db arg → $CLIP2EARN_TICKETS_DB env var → collection://25d97e82-35fa-80a1-b544-000bece8d772
   - days: --days arg → 7
   - format: --format arg → markdown
   - dry_run: --dry-run flag → false

4. Print pre-flight summary and proceed
```

### Step 1: Fetch Messages

```
IF Discord MCP available:
  1. Use Discord MCP to read --channel
  2. Paginate in batches of 100 messages
  3. Filter to messages within --days window
  4. Safety cap: 2000 messages maximum
  5. For each message, capture:
     - message_id
     - author (username, not bot)
     - content (text)
     - timestamp
     - thread_id (if in thread)
     - is_reply (boolean)
     - reply_to_id (if reply)
     - attachments (screenshots, etc.)
  6. Skip bot messages (unless they contain error reports)
  7. Report: "Fetched [N] messages from last [days] days"

IF --messages-file provided:
  1. Read the file
  2. Parse using formats from references/discord-parsing-guide.md
     - Try [YYYY-MM-DD HH:MM] Author: Message format first
     - Fall back to best-effort line-by-line parsing
  3. Extract same fields where available
  4. Report: "Parsed [N] messages from [filename]"
```

### Step 2: Extract Signals

Use patterns from `references/discord-parsing-guide.md`:

```
For each message:
  1. Check against Bug Signals patterns
     - If match: create signal { type: "Bug", message, author, timestamp, thread_id, context }
     - Assess severity: Critical / Medium / Low

  2. Check against Feature Request Signals patterns
     - If match: create signal { type: "Feature", message, author, timestamp, thread_id, context }

  3. Check against UX Confusion (Polish) patterns
     - If match: create signal { type: "Polish", message, author, timestamp, thread_id, context }

  4. Check Frustration Signals for intensity boosting
     - If frustration markers present: flag signal with frustration_level (low/medium/high)
     - Churn signals → auto-escalate to P1

  5. Apply Thread Context rules:
     - Thread starter = the signal
     - "+1" / "same" / "pareil" / "moi aussi" replies → increment user_count
     - Team replies → mark resolution status
     - Author follow-up after team reply → confirm resolution

  6. Skip messages that are:
     - Pure greetings ("salut", "hello", "bonjour")
     - Thank you messages without complaint context
     - Off-topic / memes / social chat
     - Bot commands

Report: "Extracted [N] signals: [X] bugs, [Y] features, [Z] polish"
```

### Step 3: Cluster by Topic

```
Group signals into topic clusters using references/discord-parsing-guide.md Topic Classification:

Default clusters:
  - Onboarding
  - Payments
  - Clip Creation
  - Analytics
  - Account Issues
  - Technical

For each cluster:
  1. Group matching signals by keyword overlap in message text
  2. Within each cluster, merge near-duplicates:
     - Same issue described differently by different users → one entry, multiple reporters
     - Same user reporting same issue multiple times → one entry, note frequency
  3. Compute cluster metadata:
     - topic: cluster name
     - signals: list of individual signals
     - unique_users: count of distinct authors
     - total_mentions: total signal count (including duplicates)
     - suggested_type: majority type (Bug/Feature/Polish)
     - first_seen: earliest timestamp
     - last_seen: latest timestamp
     - resolution_status: Resolved / Partially resolved / Unresolved
  4. Drop clusters with 0 signals

Report: "Grouped into [N] topic clusters"
```

### Step 4: Cross-Reference with Notion Tickets

```
IF Notion MCP available AND db is resolved:
  1. For each cluster topic:
     - Search Notion DB using topic keywords
     - Use: mcp__plugin_Notion_notion__notion-search with cluster topic terms
     - Also search by key verbatims from the signals

  2. For each search result, check:
     - Status field:
       - "Done" / "Terminé" → ticket was resolved
       - "In Progress" / "En cours" → ticket is being worked on
       - "Backlog" → ticket exists but not started
       - Not found → new gap

  3. Classify each cluster:
     - "New gap" → no matching ticket found
     - "Existing ticket (open)" → matching ticket in Backlog/In Progress
     - "Regression" → matching ticket marked Done, but users still reporting
     - "Already resolved" → matching ticket Done, no recent reports (>14 days)

  4. For "Existing ticket" matches, capture:
     - ticket_title
     - ticket_status
     - ticket_url (if available)

IF Notion MCP NOT available:
  - Mark all clusters as "Unknown — Notion not available"
  - Note: "Connect Notion MCP to enable dedup against existing tickets"
  - Continue to output step

Report: "Cross-referenced [N] clusters: [X] new gaps, [Y] existing, [Z] regressions"
```

### Step 5: Output

#### Priority Matrix

Apply scoring from `references/discord-parsing-guide.md`:

```markdown
## Discord Support Gap Analysis — [date range]

**Source:** #[channel-name] | **Messages analyzed:** [N] | **Signals extracted:** [N]

### Priority Matrix

| Priority | Topic | Type | Users | Mentions | Status | Action |
|----------|-------|------|-------|----------|--------|--------|
| 🔴 P1 | [Topic] | Bug | [N] | [N] | New gap | Create ticket |
| 🔴 P1 | [Topic] | Bug | [N] | [N] | Regression | Reopen ticket |
| 🟡 P2 | [Topic] | Feature | [N] | [N] | New gap | Create ticket |
| 🟡 P2 | [Topic] | Polish | [N] | [N] | Existing | Link: [ticket] |
| 🟢 P3 | [Topic] | Polish | [N] | [N] | Resolved | No action |
```

#### Gap Details (for P1 and P2 "New gap" and "Regression" items)

```markdown
### [Topic]: [Suggested Title]

**Type:** Bug/Feature/Polish | **Priority:** P1/P2 | **Users:** [N] | **First seen:** [date]

#### Verbatims
> "[exact user message]" — @author, [date]
> "[exact user message]" — @author, [date]

#### Thread Summary
- [N] users confirmed this issue
- Team response: [Yes/No] — [summary if yes]
- Resolution: Unresolved / Partially resolved

#### Suggested Ticket
- **Task name:** [descriptive title]
- **Description:** [summary + verbatims]
- **Task type:** Bug / Feature request / Polish
- **Priority:** High / Medium / Low
- **Effort level:** [S/M/L inferred from scope]
- **Status:** Backlog
```

#### Ticket Creation

```
IF --dry-run:
  - Print full report with suggested tickets
  - Do NOT create any tickets
  - Note: "Dry run — no tickets created. Remove --dry-run to create tickets."

IF --format notion AND Notion MCP available AND NOT --dry-run:
  For each P1/P2 "New gap" or "Regression" cluster:
    1. Create Notion page in --db database
    2. Map fields:
       | Skill output | Notion field |
       |---|---|
       | Cluster topic + suggested title | Task name |
       | Summary + verbatims + thread links | Description |
       | Bug / Feature request / Polish | Task type |
       | P1 → High, P2 → Medium, P3 → Low | Priority |
       | Inferred from scope (S/M/L) | Effort level |
       | Always "Backlog" | Status |
    3. Report created ticket URLs

IF --format markdown (default):
  - Print full report as markdown
  - Offer to save as discord-support-gaps-YYYY-MM-DD.md
```

## Tips for the Agent

- **Thread context is gold.** A bug reported by 1 person with 5 "+1" replies is more urgent than 5 separate minor issues.
- **Frustration ≠ priority.** An angry user with a cosmetic issue is still P3. But frustration + core flow blocker = P1.
- **Watch for regressions.** Issues matching "Done" tickets are the highest signal — something broke after being fixed.
- **Don't over-cluster.** "Can't withdraw earnings" and "Payment stuck" are the same cluster. "Can't withdraw" and "How to upload a clip" are not.
- **Bilingual matching.** Many channels have FR and EN users reporting the same issue in different languages. Merge these.
- **Bot noise.** Skip bot messages, command invocations, and auto-responses unless they contain error output.
- **Screenshots matter.** If a message has an image attachment right after a complaint, note it — the user likely shared an error screenshot.
