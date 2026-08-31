#!/bin/bash

HOOK="${AGENT_HOOKS_DIR:-$HOME/.config/agent-hooks}/gh-api-readonly.sh"
REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
pass=0
fail=0

run_hook() {
  local harness="$1" cmd="$2"
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)
  printf '{"tool_input":{"command":"%s"},"hook_event_name":"PreToolUse"}\n' "$cmd" |
    bash "$HOOK" "$harness" >"$stdout_file" 2>"$stderr_file"
  status=$?
  stdout=$(cat "$stdout_file")
  stderr=$(cat "$stderr_file")
  rm -f "$stdout_file" "$stderr_file"
}

assert_contract() {
  local harness="$1" cmd="$2" expected_status="$3" expected_stdout="$4" expected_stderr="$5" label="$6"
  local check=PASS
  run_hook "$harness" "$cmd"
  [[ "$status" == "$expected_status" ]] || check=FAIL
  [[ "$stdout" == "$expected_stdout" ]] || check=FAIL
  [[ "$stderr" == "$expected_stderr" ]] || check=FAIL
  if [[ "$check" == PASS ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf '     expected: status=%s stdout=%q stderr=%q\n' "$expected_status" "$expected_stdout" "$expected_stderr"
    printf '       actual: status=%s stdout=%q stderr=%q\n' "$status" "$stdout" "$stderr"
  fi
  printf '%-4s %s [%s]\n' "$check" "$label" "$harness"
}

assert_codex_allow() {
  assert_contract codex "$1" 0 '' '' "$2"
}

assert_claude_allow() {
  run_hook claude "$1"
  local check=PASS
  [[ "$status" == 0 ]] || check=FAIL
  [[ -z "$stderr" ]] || check=FAIL
  printf '%s' "$stdout" | jq -e '
    .hookSpecificOutput.hookEventName == "PreToolUse" and
    .hookSpecificOutput.permissionDecision == "allow" and
    (.hookSpecificOutput | keys | sort == ["hookEventName", "permissionDecision"])
  ' >/dev/null 2>&1 || check=FAIL
  if [[ "$check" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%-4s %s [claude]\n' "$check" "$2"
}

assert_deny() {
  local harness="$1" cmd="$2" label="$3"
  run_hook "$harness" "$cmd"
  local check=PASS
  [[ "$status" == 2 ]] || check=FAIL
  [[ -z "$stdout" ]] || check=FAIL
  [[ "$stderr" == *'Mutating GitHub API Call Blocked'* ]] || check=FAIL
  if [[ "$check" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%-4s %s [%s]\n' "$check" "$label" "$harness"
}

assert_registration() {
  local config="$1" expected="$2" label="$3"
  local check=PASS
  jq -e --arg command "$expected" '
    [.hooks.PreToolUse[].hooks[].command] | index($command) != null
  ' "$config" >/dev/null || check=FAIL
  if [[ "$check" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%-4s %s\n' "$check" "$label"
}

echo '=== gh-api-readonly.sh contract tests ==='

assert_registration "$REPO_ROOT/.claude/settings.json" '~/.config/agent-hooks/gh-api-readonly.sh claude' 'Claude registration passes explicit harness'
assert_registration "$REPO_ROOT/.codex/hooks.json" '~/.config/agent-hooks/gh-api-readonly.sh codex' 'Codex registration passes explicit harness'

allowed_write='gh api --method POST repos/owner/repo/pulls/comments/100/replies -f body=reply'
assert_claude_allow "$allowed_write" 'allowed write emits Claude permission grant'
assert_codex_allow "$allowed_write" 'allowed write remains silent for Codex'
assert_contract unknown "$allowed_write" 0 '' '' 'unknown harness receives no explicit grant'

blocked_write='gh api --method PATCH repos/owner/repo/pulls/42 -f title=blocked'
assert_deny claude "$blocked_write" 'PATCH pull request is blocked with stderr reason'
assert_deny codex "$blocked_write" 'PATCH pull request is blocked with stderr reason'
assert_deny unknown "$blocked_write" 'unknown harness fails closed with stderr reason'

# Preserve the existing writable endpoint families for both harnesses.
for cmd in \
  'gh api repos/owner/repo/issues/42/comments -X POST -f body=hi' \
  'gh api repos/owner/repo/pulls/42/comments -X POST -f body=hi' \
  'gh api repos/owner/repo/pulls/42/comments/100/replies -X POST -f body=hi' \
  'gh api repos/owner/repo/pulls/42/reviews -X POST -f body=lgtm'; do
  assert_codex_allow "$cmd" 'existing write endpoint remains allowed'
done

echo "=== Results: $pass passed, $fail failed ==="
exit "$fail"
