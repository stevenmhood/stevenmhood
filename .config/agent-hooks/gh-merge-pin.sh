#!/bin/bash

# gh Merge Pin Hook - allows `gh pr merge` only when the approved head is pinned.
# Triggered on PreToolUse for shell commands, for Claude Code and Codex alike.
#
# The settings allow rule is a plain `Bash(gh pr merge *)`; this hook supplies
# the argument check, because a wildcard in the middle of a permission rule
# makes Claude Code warn at startup.
#
# Every merge invocation must carry `--match-head-commit <full-sha>` with a
# literal 40- or 64-hex object id, so GitHub refuses the merge if the head moved
# after approval. A value resolved at merge time (`$(gh pr view ...)`, `$SHA`,
# `HEAD`) is rejected: it would pin whatever the head is *now*, not the head that
# was reviewed. `--admin` (bypass of branch protection) is always blocked.
#
# Contract: a block is a readable reason on stderr and exit 2 with empty stdout,
# for every harness argument, including an unknown one. Anything that is not a
# `gh pr merge` invocation exits 0 silently. The harness argument is accepted
# for registration symmetry with the other hooks but does not change behaviour:
# the allow itself comes from the settings rule, never from this hook.

json_input=$(cat)
command=$(printf '%s' "$json_input" | jq -r '.tool_input.command // empty')

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

[ -n "$command" ] || exit 0

# Newlines separate commands; fd redirections (`2>&1`, `&>f`) contain `&`, which
# would otherwise read as a separator and cut a merge's arguments short.
flat=$(printf '%s' "$command" |
  tr '\n' ';' |
  sed -E 's/[0-9]*>&[0-9]+-?/ /g; s/[0-9]*&>>?/ /g; s/>&/ /g')

# A real invocation: at the start of the command or after ; & | ` $( or a bare
# ( (one not glued to a word, so `Bash(gh pr merge *)` text is not one), with
# optional VAR=value prefixes, an env/command/exec/sudo wrapper, and gh's global
# repo flag before `pr merge`. Quoted text elsewhere (a commit message, a bead
# reason, a grep pattern) is preceded by a quote or a word and does not match.
# The match runs to the end of that one simple command, so a pin named in a
# different command cannot satisfy it.
assign='[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+'
repo_flag='([[:space:]]+(-R|--repo)[[:space:]]+[^[:space:]]+|[[:space:]]+--repo=[^[:space:]]+)*'
invocation="(^|[;&|\`]|(^|[^[:alnum:]_])\\(|\\\$\\()[[:space:]]*(${assign})*((env|command|exec|sudo)[[:space:]]+(${assign})*)?gh${repo_flag}[[:space:]]+pr[[:space:]]+merge([[:space:]]|\$|[;&|)])[^;&|)]*"

segments=$(printf '%s' "$flat" | grep -oE "$invocation" || true)
[ -n "$segments" ] || exit 0

quote="[\"']?"
pin="(^|[[:space:]])--match-head-commit([[:space:]]+|=)${quote}([0-9a-f]{40}|[0-9a-f]{64})${quote}([[:space:]]|\$)"

while IFS= read -r segment; do
  if printf '%s' "$segment" | grep -qE '(^|[[:space:]])--admin([[:space:]=]|$)'; then
    deny "# Merge Blocked

\`gh pr merge --admin\` bypasses branch protection and is blocked. Let the user run it."
  fi

  if ! printf '%s' "$segment" | grep -qE "$pin"; then
    deny "# Merge Blocked

\`gh pr merge\` must pin the approved head: add \`--match-head-commit <full-sha>\`
with the literal 40-character commit SHA that was reviewed. GitHub then refuses
the merge if the head moved after approval.

A value computed at merge time (\`\$(gh pr view ...)\`, a variable, \`HEAD\`) does
not count: it pins whatever the head is now, not the head that was approved."
  fi
done <<EOF
$segments
EOF

exit 0
