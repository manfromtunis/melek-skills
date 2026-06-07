---
name: agent-design-playbook
description: Methodology for designing, refactoring, and evaluating AI agents — when to use a tool vs a skill vs a subagent, how to keep system prompts lean, and how to improve agents through eval-driven hill climbing. Use this skill whenever the user is building a new agent, refactoring or debugging an existing one, complains that an agent "got worse" or "is inconsistent", asks about system prompt length, tool design, multi-agent/subagent architecture, or wants to create evals for an LLM app — even if they don't use the word "agent" (e.g., "my Claude workflow keeps messing up", "should I add another tool?", "how do I test my prompt changes?").
---

# Agent Design Playbook

Distilled from Anthropic's Applied AI workshop on agent decomposition ("Code with Claude", London) plus eval best practices. The core insight: most agent failures are **context problems, not model problems**. Agents degrade when capabilities get bolted on over time — the system prompt bloats, tools multiply, subagents proliferate — until the model is confused by its own scaffolding. The fix is decomposition: the right primitive for the right job, and evals to prove each change helps.

## The golden rule: measure before you change

Never refactor an agent without a baseline. The workshop's agent "felt" 83% good; measurement showed 62%. Intuition about agent performance is unreliable.

1. Establish or build an eval suite first (see "Evals" below — even 10 cases from real failures is enough).
2. Run it, record the baseline pass rate.
3. Change **one thing**, rerun, compare. Keep or revert.
4. Repeat. This loop is called hill climbing.

If the user asks you to fix or refactor an agent and no evals exist, propose building a minimal suite first — or at minimum, collect the failing examples so improvement is checkable.

## Choosing the right primitive

Three questions, in order:

**Does Claude need this information all of the time?** → System prompt. Only identity, non-negotiable constraints, and universally needed context belong there. Target ~50 lines, not 400.

**Does Claude need it some of the time?** → A **skill**: packaged, composable information Claude pulls into context only when the task requires it (progressive disclosure). Policies, procedures, domain reference, format specs, brand guidelines. Stuffing these into the system prompt pollutes context, creates contradictions, and causes exactly the failures it's meant to prevent.

**Does Claude need to *do* something, not know something?** → A **tool**. But prefer general primitives before custom tools (next section).

**Does a task need an isolated context window?** → Only then, a **subagent**. See "Subagents" below — they are the most over-used primitive.

## System prompts

- Keep only what is needed regardless of the task. Everything task-conditional moves to skills.
- Long prompts accumulate contradictions (the workshop's R8 failure: two conflicting policies in different sections made the agent pull the correct 3.1x multiplier, then silently use 1.35 in the calculation). When an agent "hallucinates" a value it had already retrieved correctly, suspect prompt conflicts before suspecting the model.
- When reviewing an existing agent, read the system prompt looking specifically for: duplicated policies, conditional rules that only apply to some tasks, reference material, and format specs — all candidates for extraction into skills.

## Tools: primitives first

Lean into the same primitives a human has at work: **code execution, file system access, web search, a to-do list**. Start with these; add custom tools only where primitives genuinely can't reach (proprietary APIs, side-effectful actions like filing a purchase order).

Why: a bash tool + a quick Python script beats a bespoke `analyze_csv` tool *and* beats dumping the file into context. Primitives compose, custom tools don't. And every model upgrade makes the same primitives work better — your agent improves for free.

Warning signs an agent has too many tools: a tool per data source ("retrieve X", "retrieve Y"), tools that just reshape data Claude could process with code, tools that wrap subagents. Consolidate aggressively; the workshop cut 12 tools down to primitives plus a handful of true-action tools and scores rose.

## Subagents

Use a subagent only when context isolation is genuinely valuable: large intermediate context the orchestrator doesn't need, parallelizable independent work, or a sharply different persona/toolset.

The most common multi-agent failure (workshop F2) is the **orchestrator↔subagent communication breakdown**: the subagent does the work correctly, but its report back is unstructured or lossy and the orchestrator misreports the result. If you use subagents:

- Define an explicit output contract — what fields, what format, what the subagent must include in its final message.
- Enforce structure (schema, template) on the handoff in both directions.
- Add an eval that checks the orchestrator's final answer against the subagent's actual findings.

A subagent wrapped as a tool with a vague "result: ok" return is a bug waiting for an eval to find it.

## Evals

What to grade — use both kinds:

- **Deterministic graders**: exact/regex match, JSON schema validity, code that checks the output, turn count, tool-call count, latency, token cost. Cheap, reliable, use these first.
- **LLM-as-judge**: for tone, quality, faithfulness. One specific binary question per judge ("does the response use only facts from the source?"), required justification, and validate the judge against ~20 human-graded examples before trusting it.

What to test — two task shapes:

- **Regression (R) tasks**: realistic single-turn tasks grading the final response.
- **Failure-mode (F) tasks**: multi-turn trajectories. Grade the *path*, not just the destination — an agent that reaches the right answer in 40 turns instead of 6 is failing (workshop F1). Mock the tools so runs are fast, free, and deterministic.

Process:

1. **Error analysis first**: collect 20–30 real inputs, grade outputs by hand, cluster failures into named themes. Those themes become the suite. Evals invented from imagination test nothing.
2. Run each case 3–5 times — single runs lie.
3. Tag each eval with the failure mode it guards, so a regression names its own cause.
4. Every production failure becomes a new eval case.
5. Use Claude itself to triage failed runs — ask it to find themes across the failures before fixing anything.

## Refactoring workflow (existing agent)

When asked to improve a degraded agent, work in this order — each step is one hill-climbing iteration:

1. Run evals → baseline. No evals? Build a minimal suite from known failures first.
2. Triage failures into themes (use Claude on the transcripts).
3. Extract task-conditional system prompt content into skills; shrink the prompt. Rerun.
4. Replace custom tools with primitives where possible; consolidate the rest. Rerun.
5. Remove unnecessary subagents; for the survivors, fix the output contracts. Rerun.
6. Only after architecture is clean, tune wording/models/parameters.

Resist fixing everything at once — you won't know which change helped, and you'll overfit to the eval cases you happen to have.

## Greenfield design (new agent)

Start minimal: short system prompt, primitive tools, no subagents, and a 10-case eval suite *defined before the first prompt is written* (what does success look like?). Add custom tools, skills, and subagents only when an eval failure demonstrates the need. Architecture should be earned by evidence, not anticipated.
