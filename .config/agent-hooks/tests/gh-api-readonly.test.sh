#!/bin/bash

HOOK="${AGENT_HOOKS_DIR:-$HOME/.config/agent-hooks}/gh-api-readonly.sh"
pass=0
fail=0

run_test() {
  local cmd="$1" expect="$2" label="$3"
  local result
  result=$(printf '{"tool_input":{"command":"%s"},"hook_event_name":"PreToolUse"}\n' "$cmd" | bash "$HOOK" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')
  local check="PASS"
  if [[ "$expect" == "deny" && "$result" != "deny" ]]; then check="FAIL"; fi
  if [[ "$expect" == "allow" && "$result" == "deny" ]]; then check="FAIL"; fi
  if [[ "$check" == "PASS" ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi
  printf "%-4s %-7s %s\n" "$check" "[$result]" "$label"
}

echo "=== gh-api-readonly.sh tests ==="
echo ""

echo "--- Read-only (implicit GET): allowed ---"
run_test "gh api repos/owner/repo/pulls" allow "simple GET"
run_test "gh api repos/owner/repo/issues --jq '.[]'" allow "GET with --jq"
run_test "gh api search/code" allow "search endpoint"

echo ""
echo "--- Explicit -X GET with data flags: allowed ---"
run_test 'gh api search/code -X GET --raw-field q=test' allow "-X GET with --raw-field"
run_test 'gh api search/code --method GET --raw-field q=test' allow "--method GET with --raw-field"
run_test 'gh api search/code -X GET -f q=test' allow "-X GET with -f"

echo ""
echo "--- Implicit mutation: blocked ---"
run_test 'gh api repos/owner/repo/labels --raw-field name=bug' deny "--raw-field without method"
run_test 'gh api repos/owner/repo/labels -f name=bug' deny "-f without method"
run_test 'gh api repos/owner/repo/releases --input release.json' deny "--input without method"

echo ""
echo "--- Explicit mutations: blocked ---"
run_test "gh api repos/owner/repo/labels -X POST -f name=bug" deny "POST to labels"
run_test "gh api repos/owner/repo/labels -X PUT -f name=bug" deny "PUT to labels"
run_test "gh api repos/owner/repo/labels/bug -X DELETE" deny "DELETE label"
run_test "gh api repos/owner/repo/labels -X PATCH -f name=fix" deny "PATCH label"
run_test "gh api repos/owner/repo/releases --method POST --input release.json" deny "--method POST"

echo ""
echo "--- Allowed write endpoints: comment/reply/review ---"
run_test "gh api repos/owner/repo/issues/42/comments -X POST -f body=hi" allow "POST issue comment"
run_test "gh api repos/owner/repo/pulls/42/comments -X POST -f body=hi" allow "POST PR comment"
run_test "gh api repos/owner/repo/pulls/42/comments/100/replies -X POST -f body=hi" allow "POST PR comment reply"
run_test "gh api repos/owner/repo/pulls/comments/100/replies -X POST -f body=hi" allow "POST PR comment reply without PR number"
run_test "gh api repos/owner/repo/pulls/42/reviews -X POST -f body=lgtm" allow "POST PR review"

echo ""
echo "--- Unrelated commands: allowed ---"
run_test "gh pr list" allow "gh pr"
run_test "ls -la" allow "unrelated command"
run_test "git status" allow "git command"
run_test "echo 'gh api test'" allow "mention inside echo"

echo ""
echo "=== Results: $pass passed, $fail failed ==="
exit $fail
