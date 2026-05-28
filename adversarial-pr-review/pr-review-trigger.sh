#!/usr/bin/env bash
# PostToolUse nudge: when Claude opens a PR with `gh pr create`, inject a
# system-reminder telling it to run the adversarial review->fix loop on that PR.
# Does NOT block. Fires ONLY on `gh pr create` (not `git push`) so the fix-loop's
# own pushes don't re-trigger it. Always exits 0.
#
# stdin: PostToolUse JSON payload. stdout: hook-response JSON (or '{}' to do nothing).
set -euo pipefail

input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
if [ "$tool" != "Bash" ]; then printf '{}'; exit 0; fi

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
# Match `gh pr create` (also covers an rtk-wrapped `rtk gh pr create`).
case "$cmd" in
  *"gh pr create"*) : ;;
  *) printf '{}'; exit 0 ;;
esac

# A PR URL on stdout means the create succeeded. No URL => don't nudge.
url=$(printf '%s' "$input" \
  | jq -r '(.tool_response // empty) as $r
           | if ($r|type)=="object" then ($r.stdout // "")
             elif ($r|type)=="string" then $r
             else "" end' 2>/dev/null \
  | grep -oE 'https://github\.com/[^ ]+/pull/[0-9]+' | head -1 || true)
if [ -z "$url" ]; then printf '{}'; exit 0; fi

num=$(printf '%s' "$url" | grep -oE '[0-9]+$')

reminder="A pull request was just opened: ${url}. Per repo policy, immediately run the adversarial review->fix loop on it: invoke /adversarial-pr-review ${num} (BMAD adversarial review + Explore cross-repo + pr-reviewer), triage findings, fix blockers, push, and re-review until the reviewers find nothing actionable. Then STOP and report — do NOT auto-merge."

jq -n --arg msg "$reminder" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $msg
  }
}'
