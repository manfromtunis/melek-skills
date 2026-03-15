---
name: help-center-gaps
description: Identify documentation gaps from prospect questions in meeting notes. Clusters recurring questions, ranks by frequency, cross-references with existing docs, and generates article briefs. Outputs markdown, Notion pages, or GitHub issues.
user_invocable: true
arguments: "[meeting_notes_path] [--docs docs_path] [--issues] [--format markdown|notion]"
---

# Help Center Gap Analysis

Extract questions and confusion signals from meeting notes, identify what documentation is missing, and generate prioritized article briefs.

## Inputs

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `meeting_notes_path` | No | `$MEETING_NOTES_PATH` env var, then `./meeting-notes/` | Directory containing .md meeting notes |
| `--docs` | No | `$DOCS_PATH` env var | Path to existing docs/help center (for cross-reference) |
| `--issues` | No | `false` | Create GitHub issues via `gh` CLI for each article brief |
| `--format` | No | `markdown` | Output format: `markdown` or `notion` |

## Execution

### Step 1: Extract Questions & Confusion Signals

```
1. Resolve notes path
2. Glob for *.md files
3. For each file, extract:

   EXPLICIT QUESTIONS:
   - Lines ending with "?"
   - "comment" / "how" / "est-ce que" / "qu'est-ce que" patterns
   - "can you explain" / "pouvez-vous expliquer" patterns
   - "I don't understand" / "je ne comprends pas"

   CONFUSION SIGNALS (FR):
   - "c'est pas clair" / "je ne suis pas sûr(e)"
   - "comment ça marche" / "ça veut dire quoi"
   - "qu'est-ce qui se passe si" / "et dans le cas où"
   - Questions about process, pricing, features, integrations

   CONFUSION SIGNALS (EN):
   - "that's not clear" / "I'm not sure"
   - "how does that work" / "what does that mean"
   - "what happens if" / "what about the case where"

   FEATURE REQUESTS (often disguise doc needs):
   - "est-ce que vous pouvez/avez" / "do you have / can you"
   - "il faudrait" / "it would be nice if"
   - "on aimerait" / "we'd like"

4. For each extracted signal, capture:
   - question_text: the actual question or confusion
   - speaker: who asked (prospect name)
   - company: which prospect company
   - meeting_date: when it was asked
   - context: surrounding paragraph for topic inference
```

### Step 2: Cluster by Topic

```
Group extracted questions into topic clusters:

1. Analyze question text and context for topic keywords
2. Group into clusters like:
   - Pricing & Billing
   - Getting Started / Onboarding
   - Feature Capabilities
   - Integrations & Technical
   - Security & Compliance
   - Process & Workflow
   - Performance & Metrics
3. Each cluster gets:
   - topic: cluster name
   - questions: list of individual questions
   - frequency: total count
   - prospects_asking: unique prospect count
   - urgency: based on frequency + how many different prospects asked
```

### Step 3: Cross-Reference with Existing Docs

```
If --docs path is provided:
  1. Glob for *.md files in docs directory
  2. For each topic cluster:
     - Search docs for keywords from the cluster
     - If matching doc exists: mark as "Covered" or "Partially Covered"
     - If no match: mark as "Gap"
  3. For "Partially Covered": note what's missing

If --docs is NOT provided:
  - Skip cross-reference
  - Mark all clusters as "Unknown — no docs path provided"
  - Note: "Provide --docs <path> to check against existing documentation."
```

### Step 4: Rank & Generate Priority Matrix

```markdown
## Documentation Gap Priority Matrix

| Priority | Topic | Questions | Prospects | Coverage | Action |
|----------|-------|-----------|-----------|----------|--------|
| 🔴 P1 | [Topic] | [N] | [N unique] | Gap | Write new article |
| 🔴 P1 | [Topic] | [N] | [N unique] | Partial | Expand existing |
| 🟡 P2 | [Topic] | [N] | [N unique] | Gap | Write new article |
| 🟢 P3 | [Topic] | [N] | [N unique] | Covered | No action |

Priority scoring:
- P1: 3+ questions OR 2+ different prospects asking
- P2: 2 questions OR notable confusion signal
- P3: 1 question, low confusion
```

### Step 5: Generate Article Briefs

For each P1 and P2 gap:

```markdown
### Article Brief: [Topic Title]

**Priority:** P1/P2 | **Questions driving this:** [N]
**Prospects who asked:** [Company A], [Company B]

#### Questions to Answer
- [Question 1] — asked by [Name] at [Company] on [Date]
- [Question 2] — asked by [Name] at [Company] on [Date]

#### Suggested Outline
1. [Section based on question grouping]
2. [Section based on question grouping]
3. [FAQ subsection for edge-case questions]

#### Key Points to Cover
- [Point inferred from question context]
- [Point inferred from confusion signal]

#### Verbatims to Reference
> "[Prospect's exact question]" — [Name], [Company]

#### Related Existing Docs
- [Link to related doc if --docs was provided, or "None found"]
```

### Step 6: Output

**Markdown (default):**
- Print priority matrix + all article briefs
- Offer to save as `help-center-gaps-YYYY-MM-DD.md`

**Notion (--format notion):**
- Check for Notion MCP tools
- If available: create database with one row per article brief (columns: Priority, Topic, Status, Questions Count)
- If not: fall back to markdown

**GitHub Issues (--issues):**
- Check if `gh` CLI is available: `gh --version`
- If available:
  1. For each P1/P2 brief, create an issue:
     ```bash
     gh issue create --title "Docs: [Topic Title]" --body "[Brief content]" --label "documentation"
     ```
  2. Report created issue URLs
- If not available:
  - Fall back to markdown
  - Note: "Install GitHub CLI (`gh`) to create issues automatically."

## Tips for the Agent

- **Questions reveal real gaps.** A question asked by 3 different prospects is far more valuable than one asked once.
- **Feature requests ≠ doc gaps.** Only generate briefs for things that CAN be documented (existing features, processes). Flag feature requests separately.
- **Tone matters.** Article briefs should be written so a technical writer can pick them up without needing more context.
- **Don't over-cluster.** Better to have 5 specific clusters than 2 vague ones. "How does tracking work?" and "How do I track conversions?" are the same cluster. "How does tracking work?" and "What's the pricing?" are not.
