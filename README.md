# melek-skills

Collection of Claude Code skills for productivity, sales, research, and security.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **Obsidian GTD Lite** | `/obsidian-gtd-lite` | Lightweight GTD task system inside Obsidian — inbox triage, daily notes, Eisenhower prioritization |
| **YouTube Search** | `/yt-search <query>` | Search YouTube from Claude Code via yt-dlp, returns structured results |
| **Deep Research** | `/deep-research <topic>` | YouTube search + NotebookLM as free RAG backend for in-depth research |
| **Weekly Deal Review** | `/weekly-deal-review` | Parse meeting notes into pipeline summary + deal cards |
| **Sales Deck** | `/sales-deck <prospect>` | Generate prospect-specific 8-slide deck from real verbatims |
| **Battle Cards** | `/battle-cards` | Competitive intelligence cards with objection scripts |
| **Help Center Gaps** | `/help-center-gaps` | Find doc gaps from prospect questions, generate article briefs |
| **Discord Support Gaps** | `/discord-support-gaps` | Analyze Discord support messages into bugs, features, UX gaps |
| **Sales Pipeline** | `/sales-pipeline` | Orchestrator — runs all sales skills and compiles a unified weekly report |
| **Draft Email** | `/draft-email` | Professional email composition with context-gathering checklist |
| **Create Invoice** | `/create-invoice` | Generate Invoice Ninja invoices via API |
| **Resolve Obsidian** | `/resolve-obsidian` | Auto-resolve git merge conflicts in an Obsidian vault |

## Guides

| Guide | Description |
|-------|-------------|
| [OpenClaw Security Guide](security/openclaw-security-guide.md) | VPS hardening for OpenClaw — SSH, firewall, Tailscale, sandbox |

## Install

**All skills:**
```bash
npx skills add manfromtunis/melek-skills
```

**Individual skill:**
```bash
npx skills add manfromtunis/melek-skills@yt-search
npx skills add manfromtunis/melek-skills@deep-research
npx skills add manfromtunis/melek-skills@obsidian-gtd-lite
npx skills add manfromtunis/melek-skills@sales-agents/weekly-deal-review
npx skills add manfromtunis/melek-skills@sales-agents/sales-deck
npx skills add manfromtunis/melek-skills@sales-agents/battle-cards
npx skills add manfromtunis/melek-skills@sales-agents/help-center-gaps
npx skills add manfromtunis/melek-skills@sales-agents/discord-support-gaps
npx skills add manfromtunis/melek-skills@sales-agents/sales-pipeline
```

## Repo Structure

```
melek-skills/
  obsidian-gtd-lite/       # Obsidian GTD workflow
    skill.md
    references/
  yt-search/               # YouTube search
    skill.md
  deep-research/           # YouTube + NotebookLM research
    skill.md
  sales-agents/            # Sales intelligence suite
    weekly-deal-review/
    sales-deck/
    battle-cards/
    help-center-gaps/
    discord-support-gaps/
    sales-pipeline/
    references/
  security/                # Hardening guides
    openclaw-security-guide.md
```

## Configuration (Sales Skills)

All optional — skills work out of the box with defaults.

| Env Variable | Default | Used By |
|-------------|---------|---------|
| `MEETING_NOTES_PATH` | `./meeting-notes/` | All sales skills |
| `DOCS_PATH` | *(none)* | help-center-gaps |
| `BRAND_SKILL` | *(none)* | sales-deck |
| `DISCORD_SUPPORT_CHANNEL` | *(none)* | discord-support-gaps |
| `CLIP2EARN_TICKETS_DB` | *(none)* | discord-support-gaps |

## Optional Integrations

| Tool | Used By | What It Adds |
|------|---------|-------------|
| Notion MCP | Sales skills | Output to Notion pages/databases |
| WebSearch | battle-cards | Enrich competitor cards |
| GitHub CLI (`gh`) | help-center-gaps | Auto-create issues for doc gaps |
| Discord MCP | discord-support-gaps | Read Discord channels live |
| yt-dlp | yt-search, deep-research | YouTube search backend |
| notebooklm-py | deep-research | NotebookLM API access |

## License

MIT
