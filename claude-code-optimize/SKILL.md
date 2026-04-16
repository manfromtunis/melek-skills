---
name: claude-code-optimize
description: Use when setting up or optimizing a repo for Claude Code — slim CLAUDE.md, scoped rules, RTK install, model routing, token reduction
---

# Claude Code Repo Optimization

Full setup checklist for a lean, token-efficient Claude Code environment.

## Step 1 — RTK (Rust Token Killer)

Intercepts shell output before it hits context. 60–90% reduction on build/test commands.

**Install (Windows → use WSL):**
```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

**Init for Claude Code:**
```bash
rtk init -g --hook-only   # PreToolUse hook only, zero CLAUDE.md overhead (recommended)
rtk init -g               # Hook + adds @RTK.md to CLAUDE.md
```

**Verify:**
```bash
rtk --version
rtk gain   # must show Token Killer stats
```

**Key commands:**
```bash
rtk git status / diff / log
rtk test cargo test / pytest / jest
rtk err npm run build      # errors/warnings only
rtk ls .                   # token-optimized tree
rtk gain                   # session savings stats
```

**Real numbers:**

| Command | Before | After | Savings |
|---------|--------|-------|---------|
| `cargo test` (262 tests) | 4,823 tokens | 11 | 99% |
| `git diff` | ~21,500 | ~1,259 | 94% |
| Typical 80-cmd session | ~113,600 | ~29,000 | 74% |

> Windows native: hook falls back to CLAUDE.md-only mode. Use WSL for full hook support.

---

## Step 2 — CLAUDE.md Architecture

### Règle : CLAUDE.md = navigation + règles globales seulement

```markdown
# [Project Name]

[2-line project description max]

## Core Rules
- [Behavioral rules only — no file trees, no API docs]

## Key Locations
- [3-5 critical paths max]

## Workflows
- /skill-name — one-line description
```

**Ne jamais mettre dans CLAUDE.md :**
- Arbres de fichiers (utilisez Glob)
- Docs d'API ou configs détaillées
- Règles domaine-spécifiques (→ `.claude/rules/`)
- Historique ou contexte de session

### `.claude/rules/` — règles scoped par domaine

Créer un fichier par domaine. Claude les charge automatiquement selon le contexte.

```
.claude/rules/
  financial.md      # calculs, formats, règles comptables
  email-outreach.md # tone, séquences, CAN-SPAM
  obsidian.md       # vault paths, daily notes format
  automation.md     # agents, crons, approval gates
  content-design.md # contrast checks, palette melekbuilds
  agents.md         # multi-agent rules, worktree protocol
```

### `.worktreeinclude` — limit worktree scope

```
src/
tests/
package.json
```

Tout ce qui n'est pas listé = ignoré dans les worktrees. Réduit le contexte des agents parallèles.

---

## Step 3 — Model Routing

| Tâche | Modèle |
|-------|--------|
| Raisonnement complexe, architecture | Opus |
| Développement, écriture, analyse | Sonnet (défaut) |
| Subagents : grep, glob, lookups | Haiku |

Dans Claude Code : `claude --model claude-haiku-4-5-20251001` pour les sous-agents.

---

## Step 4 — Session Hygiene

```bash
/clear    # entre tâches non liées (vide le contexte)
/compact  # quand le contexte grossit (résume sans perdre l'essentiel)
```

**Règles multi-agent :**
- Toujours passer le contexte complet dans le prompt du sous-agent (pas d'héritage)
- Merge les branches parallèles séquentiellement : rebase une à la fois
- Plan first (`/plan`), parallelize second

---

## Checklist rapide nouveau repo

- [ ] RTK installé et vérifié (`rtk gain`)
- [ ] CLAUDE.md < 50 lignes, no file trees
- [ ] `.claude/rules/` créé avec domaines séparés
- [ ] `.worktreeinclude` configuré si multi-agent
- [ ] Model routing documenté dans les prompts sous-agents
- [ ] `/clear` + `/compact` dans les habitudes de session
