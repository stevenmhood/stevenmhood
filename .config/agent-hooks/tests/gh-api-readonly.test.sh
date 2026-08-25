#!/bin/bash

HOOK="${AGENT_HOOKS_DIR:-$HOME/.config/agent-hooks}/gh-api-readonly.sh"
pass=0
fail=0

run_hook() {
  local event="$1" cmd="$2"
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)
  printf '{"tool_input":{"command":"%s"},"hook_event_name":"%s"}\n' "$cmd" "$event" |
    bash "$HOOK" >"$stdout_file" 2>"$stderr_file"
  status=$?
  stdout=$(cat "$stdout_file")
  stderr=$(cat "$stderr_file")
  rm -f "$stdout_file" "$stderr_file"
}

assert_contract() {
  local event="$1" cmd="$2" expected_status="$3" expected_stdout="$4" expected_stderr="$5" label="$6"
  local check=PASS
  run_hook "$event" "$cmd"
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
  printf '%-4s %s [%s]\n' "$check" "$label" "$event"
}

claude_allow='{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}'

assert_claude_allow() {
  assert_contract PreToolUse "$1" 0 "$claude_allow" '' "$2"
}

assert_codex_allow() {
  assert_contract pre_tool_use "$1" 0 '' '' "$2"
}

assert_claude_deny() {
  run_hook PreToolUse "$1"
  local check=PASS
  [[ "$status" == 2 ]] || check=FAIL
  [[ -z "$stderr" ]] || check=FAIL
  [[ $(printf '%s' "$stdout" | jq -r '.hookSpecificOutput.permissionDecision') == deny ]] || check=FAIL
  [[ $(printf '%s' "$stdout" | jq -r '.hookSpecificOutput.permissionDecisionReason') == *'Mutating GitHub API Call Blocked'* ]] || check=FAIL
  if [[ "$check" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%-4s %s [PreToolUse]\n' "$check" "$2"
}

assert_codex_deny() {
  run_hook pre_tool_use "$1"
  local check=PASS
  [[ "$status" == 2 ]] || check=FAIL
  [[ -z "$stdout" ]] || check=FAIL
  [[ "$stderr" == *'Mutating GitHub API Call Blocked'* ]] || check=FAIL
  if [[ "$check" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%-4s %s [pre_tool_use]\n' "$check" "$2"
}

echo '=== gh-api-readonly.sh contract tests ==='

for harness in claude codex; do
  if [[ "$harness" == claude ]]; then allow=assert_claude_allow; else allow=assert_codex_allow; fi
  "$allow" 'gh api --method POST repos/owner/repo/pulls/comments/100/replies -f body=reply' 'POST review-comment reply is allowed'
  "$allow" 'gh api --method PATCH repos/owner/repo/pulls/comments/100 -f body=corrected' 'PATCH review comment is allowed'
done

assert_claude_deny 'gh api --method PATCH repos/owner/repo/pulls/42 -f title=blocked' 'PATCH pull request is blocked'
assert_codex_deny 'gh api --method PATCH repos/owner/repo/pulls/42 -f title=blocked' 'PATCH pull request is blocked'

# Preserve the existing writable endpoint families for both harnesses.
for cmd in \
  'gh api repos/owner/repo/issues/42/comments -X POST -f body=hi' \
  'gh api repos/owner/repo/pulls/42/comments -X POST -f body=hi' \
  'gh api repos/owner/repo/pulls/42/comments/100/replies -X POST -f body=hi' \
  'gh api repos/owner/repo/pulls/42/reviews -X POST -f body=lgtm'; do
  assert_claude_allow "$cmd" 'existing write endpoint remains allowed'
  assert_codex_allow "$cmd" 'existing write endpoint remains allowed'
done

# Unknown event variants fail closed without emitting an unsupported decision.
run_hook FutureToolUse 'gh api --method POST repos/owner/repo/pulls/comments/100/replies -f body=reply'
check=PASS
[[ "$status" == 2 ]] || check=FAIL
[[ -z "$stdout" ]] || check=FAIL
[[ "$stderr" == *'Unknown hook event'* ]] || check=FAIL
if [[ "$check" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
printf '%-4s %s [FutureToolUse]\n' "$check" 'unknown event is blocked safely'

echo "=== Results: $pass passed, $fail failed ==="
exit "$fail"
