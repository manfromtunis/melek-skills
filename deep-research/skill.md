---
name: deep-research
description: Deep research workflow combining YouTube search + NotebookLM as a free RAG backend. Use when user wants to research a topic in depth, find up-to-date information, generate analysis, infographics, podcasts, quizzes, or any NotebookLM artifact from YouTube sources. Triggers on "research X", "deep dive into X", "find everything about X", or /deep-research.
user_invocable: true
arguments: topic to research
---

# Deep Research Skill

Research any topic using YouTube as a source and NotebookLM as a free RAG analysis engine. Zero token cost for the research itself — only tokens used are for sending/receiving commands.

## Why This Works

- **YouTube** = massive library of up-to-date expert content on any topic
- **NotebookLM** = free Google-powered RAG that indexes sources and generates artifacts
- **Claude Code** = orchestrator that chains yt-search → NotebookLM → output
- **Result**: comprehensive, current research without burning Claude tokens on analysis

## Workflow

```
User query → yt-search (find videos) → NotebookLM (create notebook, add sources) → Analyze/Generate artifacts → Return results
```

## Step-by-Step Execution

### Step 1: Search YouTube

Use the `/yt-search` skill to find relevant videos on the topic.

```bash
PYTHONIOENCODING=utf-8 python -m yt_dlp "ytsearch10:<TOPIC>" --flat-playlist -j 2>/dev/null
```

- Default: 10 results. Use 15-20 for deeper research.
- Extract video URLs from results for NotebookLM import.

### Step 2: Create NotebookLM Notebook

Use the notebooklm CLI to create a notebook and add the YouTube videos as sources.

```bash
# Create notebook
python -m notebooklm create "<TOPIC> Research"

# Select the notebook
python -m notebooklm use <notebook_id>

# Add YouTube videos as sources (one per video URL)
python -m notebooklm source add-url "https://www.youtube.com/watch?v=VIDEO_ID" --wait
```

- Add the top 5-10 most relevant videos (by view count and relevance)
- Use `--wait` to ensure each source is fully indexed before proceeding
- NotebookLM will transcribe and index the video content automatically

### Step 3: Analyze with NotebookLM

Ask NotebookLM to analyze the sources:

```bash
# Ask a research question
python -m notebooklm chat "Analyze the key strategies, frameworks, and trends discussed across all sources. Provide a comprehensive summary."

# Or ask specific questions
python -m notebooklm chat "<specific question about the topic>"
```

### Step 4: Generate Artifacts (Optional)

NotebookLM can generate various artifact types from the indexed sources:

| Artifact | Command | Output |
|----------|---------|--------|
| Audio podcast | `python -m notebooklm generate audio` | MP3 |
| Video overview | `python -m notebooklm generate video` | MP4 |
| Infographic | `python -m notebooklm generate infographic` | PNG |
| Slide deck | `python -m notebooklm generate slides` | PDF/PPTX |
| Quiz | `python -m notebooklm generate quiz` | JSON/MD |
| Flashcards | `python -m notebooklm generate flashcards` | JSON/MD |
| Report | `python -m notebooklm generate report` | Markdown |
| Mind map | `python -m notebooklm generate mindmap` | JSON |
| Data table | `python -m notebooklm generate table` | CSV |

Download artifacts with:
```bash
python -m notebooklm download audio output.mp3
python -m notebooklm download infographic output.png
```

### Step 5: Return Results to User

- Present the analysis in a clean, structured format
- Mention which videos were used as sources
- Offer to generate additional artifacts if useful

## Tips

- **More videos = better analysis** — 10-20 sources give NotebookLM rich context
- **Filter by views** — higher view count usually means better quality content
- **Add non-YouTube sources too** — NotebookLM accepts URLs, PDFs, Google Drive docs
- **Use web research** — `python -m notebooklm source add-research "<query>"` for web sources
- **Free tier limits** — NotebookLM has generous free limits, but be mindful of heavy usage
- **Save results** — use `python -m notebooklm chat save` to save Q&A as notebook notes

## Example Prompt

> /deep-research meta ad strategies 2026
>
> This will:
> 1. Search YouTube for top 10 videos on meta ad strategies
> 2. Create a NotebookLM notebook
> 3. Add all videos as sources
> 4. Generate comprehensive analysis
> 5. Optionally create infographic/slides/podcast

## Credits

Workflow inspired by [Erik Lazar](https://www.youtube.com/@eriklazar). NotebookLM Python API by [teng-lin/notebooklm-py](https://github.com/teng-lin/notebooklm-py).
