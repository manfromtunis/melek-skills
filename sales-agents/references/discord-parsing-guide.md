# Discord Support Channel Parsing Guide

Extraction patterns for Discord support messages. Works with Discord MCP live reads and exported markdown files.

## Supported Formats

| Format | Structure | Detection |
|--------|-----------|-----------|
| Discord MCP | Message objects with author, content, timestamp, thread_id | Live read via `mcp__discord__*` tools |
| Exported markdown | `[timestamp] author: message` lines | Fallback file format |

## Extraction Patterns

### 1. Bug Signals

```
# FR
ça marche pas, ça fonctionne pas, ça plante, ça crash
erreur, bug, problème technique, écran blanc/noir
j'ai un souci avec, j'arrive pas à, impossible de
ça charge pas, ça se bloque, ça boucle, ça répond pas
"depuis la mise à jour", "depuis hier", "depuis ce matin"

# EN
it doesn't work, it's not working, it broke, it crashed
error, bug, technical issue, blank/white screen
I can't, I'm unable to, impossible to
not loading, stuck, frozen, unresponsive
"since the update", "since yesterday", "since this morning"

# Universal
HTTP status codes: 400, 401, 403, 404, 500, 502, 503
Error messages in backticks or code blocks
Stack traces, error screenshots (image attachments after complaint)
Reproduction steps: "quand je clique" / "when I click", step-by-step descriptions
```

**Severity heuristics:**
- Multiple users reporting same issue → Critical
- Blocks core flow (payments, clip creation, login) → Critical
- Cosmetic / edge case → Low
- Includes reproduction steps → Higher confidence

### 2. Feature Request Signals

```
# FR
il faudrait, il manque, ce serait bien si, est-ce que vous pouvez
on aimerait, on aurait besoin de, ça serait cool de pouvoir
vous avez prévu de, c'est prévu, est-ce que c'est possible
suggestion, idée, proposition
pourquoi on peut pas, pourquoi c'est pas possible

# EN
can you add, it would be nice if, we need, I wish
is there a way to, it'd be great if, please add
do you plan to, is it planned, is it possible to
suggestion, idea, proposal
why can't I, why isn't it possible
feature request, enhancement

# Implicit
Comparisons to other platforms: "sur TikTok on peut" / "on Fiverr you can"
Workflow workarounds: "je suis obligé de" / "I have to manually"
```

### 3. UX Confusion (Polish)

```
# FR
c'est pas clair, je comprends pas, comment on fait
c'est où, je trouve pas, ça veut dire quoi
c'est quoi la différence entre, c'est normal que
j'ai cherché partout, c'est pas intuitif, c'est compliqué

# EN
it's not clear, I don't understand, how do I
where is, I can't find, what does this mean
what's the difference between, is it normal that
I've looked everywhere, it's not intuitive, it's confusing
where do I go to, how am I supposed to

# Navigation confusion
"where is the button", "où est le bouton"
"I clicked X but nothing happened", "j'ai cliqué mais rien"
Multiple "?" in same message (confusion accumulation)
```

### 4. Frustration Signals

```
# Temporal frustration (recurring/unresolved issues)
"depuis X jours/semaines" / "for X days/weeks"
"toujours pas" / "still not", "encore" / "again"
"ça fait X fois que" / "this is the Xth time"
"j'attends depuis" / "I've been waiting since"

# Intensity markers
ALL CAPS messages or CAPS within message
Multiple exclamation marks (!!!)
Repeated question marks (???)
Angry emoji: 😡 😤 🤬 💢 😠
"sérieusement" / "seriously", "n'importe quoi" / "ridiculous"

# Churn signals
"je vais partir" / "I'm going to leave"
"je regrette" / "I regret"
"remboursement" / "refund"
"annuler" / "cancel"
"déçu" / "disappointed"
```

### 5. Thread Context

```
THREAD HANDLING:
1. Thread starter = the signal (bug report, feature request, etc.)
2. Replies from team = resolution status
   - If team replied with fix → Resolved
   - If team replied with workaround → Partially resolved
   - If no team reply → Unresolved (escalate priority)
3. Replies from other users confirming = frequency boost
   - "+1", "same here", "pareil", "moi aussi", "same issue"
   - Boost priority proportionally to confirmation count
4. Reply from original author after team reply:
   - "ça marche" / "it works" / "merci" → Confirmed resolved
   - "toujours pas" / "still not working" → Still open
```

### 6. Message Format (Exported Files)

```
Expected format for --messages-file:
[YYYY-MM-DD HH:MM] AuthorName: Message content here
[YYYY-MM-DD HH:MM] AuthorName: Another message
  > Reply to above (indented or prefixed with >)

Alternative formats accepted:
- Discord chat export (DiscordChatExporter format)
- Simple "author: message" per line
- Raw copy-paste from Discord (best effort parsing)
```

## Topic Classification

Map extracted signals to these default clusters:

| Cluster | Keywords |
|---------|----------|
| Onboarding | inscription, sign up, register, account creation, getting started, première fois, first time |
| Payments | paiement, payment, withdraw, retrait, money, argent, earning, gain, stripe, paypal, virement |
| Clip Creation | upload, clip, vidéo, video, création, create, edit, publish, publier |
| Analytics | stats, statistiques, analytics, views, vues, dashboard, tableau de bord, earnings |
| Account Issues | connexion, login, password, mot de passe, email, profil, profile, settings, paramètres, banned, banni |
| Technical | API, bug, error, erreur, lent, slow, crash, loading, chargement, mobile, app, navigateur, browser |

## Priority Scoring

```
P1 (Critical):
  - 5+ users reporting same issue
  - Blocks core flow (payments, clip creation, auth)
  - Contains churn signals
  - Unresolved for 48h+

P2 (Important):
  - 2-4 users reporting
  - Feature request with multiple "+1"
  - UX confusion on key flow
  - Frustration signals present

P3 (Nice to have):
  - 1 user reporting
  - Cosmetic issue
  - Edge case feature request
  - Already has workaround
```
