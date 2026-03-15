# Meeting Note Parsing Guide

Shared extraction patterns for sales-agents skills. Works with Gemini Meet notes, Claap transcripts, and raw text meeting notes.

## Supported Formats

| Format | Structure | Detection |
|--------|-----------|-----------|
| Gemini Meet notes | Date header → `## Title` → `Invités` → `### Résumé` → `### Détails` → `### Étapes suivantes` | Contains "Notes by Gemini" or "Notes par Gemini" in filename or "Invités" section |
| Claap transcripts | Speaker labels → timestamps → text blocks | Contains `[HH:MM:SS]` timestamps with speaker names |
| Raw text | Free-form paragraphs, bullet lists | Fallback when no structured format detected |

## Extraction Patterns

### 1. Company / Prospect Detection

**Primary signals (in order of reliability):**

```
# From Gemini header
- Title line: "Call <Company A> X <Company B>" → both are prospects/partners
- "Invités" line: email domains → company identification
  - Extract domain from emails: user@kosmopellis.com → "Kosmopellis"
  - Ignore generic domains: gmail.com, outlook.com, hotmail.com, yahoo.com

# From content
- First paragraph of Résumé usually names the company and their industry
- Pattern: "<Company>, une entreprise de/d'/du ..." or "<Company>, a company that..."
- "## <Meeting Title>" often contains company names
```

**FR patterns:**
- `entreprise`, `société`, `marque`, `startup`, `client`
- `lancée en [0-9]{4}` → founding year
- `basée à`, `située à` → location

**EN patterns:**
- `company`, `brand`, `startup`, `client`, `organization`
- `founded in [0-9]{4}`, `launched in [0-9]{4}`
- `based in`, `located in`

### 2. Budget Detection

```regex
# Explicit amounts
[0-9]+[\s]?[0-9]*[\s]?[€$£]
[€$£][\s]?[0-9]+[\s]?[0-9]*
[0-9]+[\s]?(euros?|dollars?|USD|EUR|GBP|k€|K€|k\$)

# Budget ranges
(entre|between|from)\s+[0-9].*?(et|and|to)\s+[0-9].*?[€$£]
(budget|prix|price|cost|coût).*?[0-9]

# Budget signals (FR)
budget, prix, tarif, coût, investissement, dépenses, facturation
montant, enveloppe, financement

# Budget signals (EN)
budget, price, pricing, cost, spend, investment, billing
amount, funding, expenditure
```

**Context extraction:** Capture the full sentence containing the budget mention for context (monthly vs one-time, per-unit, etc.).

### 3. Objection Detection

```regex
# FR objection markers
mais|cependant|toutefois|néanmoins|en revanche
le problème|la difficulté|le défi|le souci|le risque
inquiétude|préoccupation|hésitation|réticence
pas sûr|pas convaincu|pas certain
trop (cher|complexe|long|risqué)

# EN objection markers
but|however|although|nevertheless|on the other hand
the problem|the challenge|the difficulty|the issue|the risk
concern|worry|hesitation|reluctance
not sure|not convinced|not certain
too (expensive|complex|long|risky)

# Implicit objections
- Questions starting with "et si" / "what if" (risk scenarios)
- Conditional language: "si seulement" / "if only", "à condition que" / "provided that"
- Comparison to current solution: "actuellement on utilise" / "currently we use"
```

### 4. Next Steps Detection

**Structured (Gemini):**
```
### Étapes suivantes suggérées
- [ ] Action item with owner and deadline
```

**Unstructured signals:**
```regex
# FR
prochaines étapes|étapes suivantes|à faire|action items
(je|on|nous|il|elle) (va|vais|allons|devra|devrait|doit)
la semaine prochaine|le mois prochain|demain|lundi|mardi|...
d'ici (le|lundi|la fin)
envoyer|préparer|planifier|lancer|valider|confirmer

# EN
next steps|action items|to-do|follow-up
(I|we|he|she|they) (will|shall|should|must|need to)
next week|next month|tomorrow|Monday|Tuesday|...
by (Monday|the end of|next)
send|prepare|schedule|launch|validate|confirm
```

**Owner detection:** Look for proper names or pronouns immediately before the verb.

### 5. Competitor Detection

```regex
# FR
(actuellement|en ce moment).*(utilise|utilisons|avons)
par rapport à|en comparaison (de|avec)|contrairement à
alternative|concurrent|concurrence|compétiteur
(mieux|moins bien|plus cher|moins cher) que

# EN
(currently|right now).*(use|using|have)
compared to|in comparison (to|with)|as opposed to
alternative|competitor|competition
(better|worse|cheaper|more expensive) than

# Named competitor patterns
- "on utilise <Name>" / "we use <Name>"
- "comme <Name>" / "like <Name>"
- "<Name> fait/propose..." / "<Name> does/offers..."
- Brand names near comparison words
```

### 6. Verbatim Extraction

Direct quotes from prospects — the most valuable data for sales decks and battle cards.

**Detection patterns:**
```regex
# Explicit quotes
«.*?»          # French guillemets
".*?"          # Standard quotes
'.*?'          # Single quotes

# First-person prospect statements (in Détails section)
# Look for statements attributed to the prospect (not your team)
# Pattern: "<ProspectName> a (dit|mentionné|expliqué|indiqué|souligné|exprimé)..."
# The content following these attribution verbs is a verbatim

# Strong opinion signals
(vraiment|absolument|exactement|parfaitement|très)
(really|absolutely|exactly|perfectly|very)
(le plus important|ce qu'on veut|notre priorité)
(most important|what we want|our priority)
```

**Attribution:** Always tag verbatims with the speaker name when available.

## Parsing Algorithm

```
1. DETECT FORMAT
   - Check filename/header for format markers
   - Select appropriate section parser

2. EXTRACT METADATA
   - Date (first line or filename pattern: YYYY_MM_DD or YYYY-MM-DD)
   - Title (## heading)
   - Attendees (Invités line → parse emails and names)
   - Company (from email domains + title + first paragraph)

3. PARSE SECTIONS
   For Gemini format:
   - Summary → high-level deal context
   - Details → deep extraction (budget, objections, competitors, verbatims)
   - Next steps → action items with owners

4. CLASSIFY DEAL STAGE
   Based on extracted signals:
   - "Discovery" → first meeting, mostly questions, no pricing discussed
   - "Qualification" → budget mentioned, needs identified, timeline discussed
   - "Proposal" → solution presented, pricing shared, objections raised
   - "Negotiation" → terms discussed, contract mentioned, legal involved
   - "Closed Won" → agreement reached, onboarding discussed
   - "Closed Lost" → explicit rejection or competitor chosen

5. OUTPUT structured data per meeting note
```

## Deal Stage Heuristics

| Signal | Stage |
|--------|-------|
| No budget mentioned, exploratory questions | Discovery |
| Budget range given, needs articulated | Qualification |
| Pricing discussed, demo/proposal given | Proposal |
| Terms negotiation, contract review | Negotiation |
| "Prêt à commencer" / "Ready to start", account creation | Closed Won |
| "On va rester avec" / "We'll stick with", explicit no | Closed Lost |
