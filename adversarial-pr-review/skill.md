---
name: adversarial-pr-review
description: Run an adversarial review→fix loop on a GitHub PR using BMAD adversarial agents until the reviewers find nothing actionable, then stop and report. Never auto-merges. Use after opening a PR, or when the user says "adversarially review", "hammer this PR", "review until clean", or /adversarial-pr-review.
user_invocable: true
arguments: PR number or URL (optional; defaults to the open PR for the current branch)
---

# Adversarial PR review → fix loop

Hammer a pull request with multiple adversarial review lenses, fix what's real,
re-review, and repeat until the reviewers stop finding actionable problems — then
**stop and report**. Merging is left to a human.

Generic and repo-agnostic. Reuses the BMAD adversarial agents (`bmad-code-review`,
`bmad-review-adversarial-general`, `bmad-review-edge-case-hunter`) and the `pr-reviewer`
agent when available, plus the project's own review conventions.

## Hard rules
1. **Never `gh pr merge`.** Stop at "clean + reported."
2. **Never weaken tests/assertions** to make a finding disappear — fix the cause.
3. **Don't balloon the PR.** Fix blockers + cheap in-scope items here; file follow-up
   issues for out-of-scope criticals.
4. **Cap at 3 rounds.** If still not clean, escalate to the user with the open list.
5. **Use a task list** so each round is visible.
6. Apply fixes in a git worktree of the PR's head branch so the working copy is untouched.

## Procedure

### 0. Resolve PR + context
```bash
gh pr view <N> --json number,title,body,headRefName,baseRefName,url,files
gh pr diff <N>
```
Identify changed files, languages, and risk areas (auth, money, IaC, shell-run-as-root,
migrations, concurrency). If the repo has `.claude/rules/code-review.md`, read it and use
its severity/disposition conventions; otherwise default to P0=blocker / P1=important / P2-3=nit.
Check out the head branch in a worktree to apply fixes.

### 1–2. Review round — dispatch lenses IN PARALLEL (one message)
- **BMAD adversarial review (primary):** `bmad-code-review` on the diff (Blind Hunter +
  Edge Case Hunter + Acceptance Auditor + triage). If unavailable, dispatch a
  general-purpose agent briefed with the `bmad-review-adversarial-general` persona
  ("cynical, assume problems, find ≥10, look for what's MISSING") + the
  `bmad-review-edge-case-hunter` method (walk every branch/boundary).
- **Cross-repo `Explore` agent:** exhaustive grep for downstream references to anything the
  PR changes, across sibling repos — catches coupling the diff-local review can't see.
- **`pr-reviewer` agent:** hygiene pass; posts prioritized findings to the PR.

Brief every lens with the PR's purpose and risk constraints. Vague briefs → generic findings.

### 3. Triage
Collect all findings → severity × scope. Post one **triage-table comment** on the PR
(finding → disposition: `fix-now` / `follow-up-issue` / `wontfix: reason` / `nit-defer`).
Never silently drop a finding.

### 4. Fix + 5. Loop
Apply `fix-now` items; re-run the repo's build/lint/tests to confirm. Commit, push to the
PR branch, and re-dispatch all lenses against the new diff.

### 6. Terminate
**Clean** = no blocker and no in-scope important findings remain. When clean (or after 3
rounds): post a final `✅ adversarial review clean (K rounds)` summary. **Report. Do NOT merge.**
If not clean after 3 rounds, escalate the outstanding blockers to the user.

## Auto-trigger hook (optional but recommended)
`pr-review-trigger.sh` (shipped alongside this skill) is a Claude Code **PostToolUse** hook
that fires when you run `gh pr create` and nudges Claude to run this loop on the new PR. It
only matches `gh pr create` (not `git push`), so the loop's own fix-pushes don't re-trigger it.

Install:
```bash
install -m 0755 pr-review-trigger.sh ~/.claude/hooks/pr-review-trigger.sh
```
Then add to `~/.claude/settings.json` under `hooks`:
```json
"PostToolUse": [
  { "matcher": "Bash",
    "hooks": [ { "type": "command", "command": "/home/<you>/.claude/hooks/pr-review-trigger.sh" } ] }
]
```

## Notes
- Keep secret-free; read project specifics at runtime from each repo's `.claude/rules/code-review.md`.
- Remove the temporary worktree when done (`git worktree remove`).
