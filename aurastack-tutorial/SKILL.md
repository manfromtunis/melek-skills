---
name: aurastack-tutorial
description: Plan, write and illustrate an AuraStack blog tutorial (Claude skills, Claude Code, MCP, VPS, AI tools) that ranks on Google and gets quoted by AI answer engines (GEO). Use when Melek asks for an article, a tutorial, a blog post, an outline, "un article sur…", or to turn his notes or a user question into a post on aurastack.link/blog. Drafts only: never publishes.
---

# AuraStack tutorial writer

Turns a topic into a blog draft that follows the **Tutoriel** template. Melek brings the experience; this skill
brings the keyword research, the structure, the GEO rules, the figure and the draft. The draft goes
into the CMS as a **draft**. Melek reads it and publishes it himself.

## Hard rules
- **Real experience only.** Never invent a step, a command output, a number or a skill Melek uses.
  Anything you have not run or read in a source is marked `[À VÉRIFIER]` in the draft. Screenshots
  are real terminal captures from Melek, never generated images.
- **Never publish.** `aura blog create/update` with `--confirm` makes a draft; `aura blog publish`
  is Melek's call.
- **Write French natively**, never translated from English: "vous", plain words, a no-break space
  before `? : ; !`, no em or en dash, no "officiel". Run the unslop rules on every paragraph.
- **One main keyword per article.** Never two articles on the same keyword.
- **Write for non-technical readers too** (Melek 2026-10-22: "les skills ne sont pas utilisés seulement par
  des développeurs"). Never assume the reader is a developer. When a no-code path exists (the Claude
  app, a settings page), it comes first; the terminal path comes after, labelled "développeurs". Every
  technical word is explained in plain French the first time (a token: "l'unité de texte que Claude
  lit, environ trois quarts de mot") or replaced. Examples come from everyday work (an e-mail, a
  quote, a report), not only from code.

## Workflow
1. **Keyword.** With a keyword tool (OpenSEO MCP or similar), check the
   main keyword and 5 to 10 related ones in France (`locationCode 2250`, `fr`):
   `get_keyword_metrics`, then `get_serp_results` (depth 10) on the main keyword to see what ranks.
   Note what the top results miss: that is the article's angle. Keep the credit spend under 100.
2. **Outline.** One H2 per question people really ask (People Also Ask, related keywords, Melek's
   users). Map each related keyword to the H2 that answers it. Show the outline as a table
   (H2 | content | keywords) and wait for Melek's go before drafting.
3. **Draft**, in the template order:
   - Title: main keyword + concrete result. Meta description ≤ 160 characters.
   - **En bref**: 3 bullets that answer the main question on their own.
   - **Vidéo** (Melek makes one per article): right after En bref. YouTube facade (real thumbnail,
     the player loads on click), chapters with their start time, and the transcript corrected by
     hand under a "Lire la transcription" fold. Produces VideoObject JSON-LD with one Clip per
     chapter. Ask Melek for the YouTube id, duration, chapters and transcript; never invent them.
   - **Introduction**: who it is for, what they have at the end, how long it takes.
   - **Avant de commencer**: prerequisites, OS, accounts, cost.
   - Each H2 is a question. Its first paragraph is the **réponse directe**: 40 to 60 words that make
     sense with no context (this is the passage AI engines quote). Details follow.
   - **Étapes**: one step = a title, the command, the expected output, a "Vérifiez" line.
   - **Tableau** when comparing 3 or more things.
   - **Erreurs fréquentes**: error, cause, fix. Use the real errors Melek's users hit.
   - **FAQ**: 3 to 5 questions from users or People Also Ask.
   - **Sources**: named and dated ("Anthropic, documentation Agent Skills, consultée le …"). Every tool,
     skill or repo the article names gets a line here with its URL: the body has no inline links yet,
     and Sources is the only block that renders clickable links.
   - **Et après ?**: 2 or 3 internal links (other posts, a store page when relevant).
4. **Figure** (one per article, optional): use the `anatomy` skill (github.com/wheresryan22/anatomy, MIT;
   never run its `publish.mjs --submit`). Pick a physical object
   whose working is the idea (example: skills as drawers that open
   only on a match). Size "Figure", about 1 hour. Export the
   interactive HTML and the static SVG; the SVG carries the alt text and is what Google, AI engines
   and social cards see. Every number in the figure must be true. Make the still PNG (cover, figure
   image) with headless Chromium (`chrome --headless=new --screenshot` of a page holding the
   standalone SVG), never with sharp/librsvg: they ignore the CSS variables and paint a black shape.
5. **Check** before handing over: the main keyword is in the title, the first paragraph and one H2;
   every H2 has its réponse directe; no `[À VÉRIFIER]` left unflagged; meta description ≤ 160
   characters; the unslop pass is done; no dash; FAQ answers are plain text.
6. **Hand over.** Save the draft as `~/aurastack-blog/<slug>/<slug>.fr.md` (and `.en.md` when an
   English version is written), then, if `aura` reaches the store, create the CMS draft:
   `aura blog create --file <slug>.en.md --confirm` then
   `aura blog update <slug> --lang fr --file <slug>.fr.md --confirm`, and `aura blog check <slug>`.
   Report the slug, the open `[À VÉRIFIER]` items and the check result. Melek publishes.

## Post file (today's CMS format)
Front matter: `title, excerpt, slug, category (guides|comparisons|news), authors (melek), products,
cover, cover_alt, meta_title, meta_description`. Body: `## heading`, paragraphs, `- list`,
`> callout`, `{{product:<store-slug>}}`, `{{post:<slug>|Link text}}`. Publishing needs the English
version (title, excerpt, body, author, category, cover alt).

Tutorial blocks: `### subheading`, a fenced
code block (```` ```file=path ````), and directives from a `:::name` line to a `:::` line: `:::summary` and
`:::prerequisites` (`- one point per line`), `:::answer` (the direct answer right under each question H2),
`:::steps` (`### Title`, text, `$ command`, `expected: …`, `check: …`), `:::table` (`| a | b |`, first row is
the header), `:::figure` (`image: <media id>`, `alt:`, `caption:`, `interactive: /figures/<name>`), `:::video`
(`id:`, `title:`, `date:`, `duration:`, `1:35 Chapter` lines, `transcript:` then the text), `:::errors`
(`### Problem`, `cause:`, `fix:`), `:::faq` (`### Question`, answer), `:::sources` (`- Label | https://url`).
`aura blog --help` prints the same. HowTo, FAQPage and VideoObject data come from these blocks automatically.
Interactive figures ship as one static file in the storefront repo, `public/figures/<name>.html`, which must be
the LIGHT build (`node build.mjs --light`; the store is light-only); the still image is uploaded with
`aura blog upload`. Keep each direct answer to 40 to 60 words (not checked by the CMS yet).

