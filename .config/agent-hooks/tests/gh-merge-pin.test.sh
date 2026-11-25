#!/usr/bin/env bash
# Tests for gh-merge-pin.sh: the harness output contract first, then command
# classification.
set -u

HOOK="${AGENT_HOOKS_DIR:-$HOME/.config/agent-hooks}/gh-merge-pin.sh"
pass=0
fail=0

SHA=0123456789abcdef0123456789abcdef01234567
SHA256=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

run_hook() {
  local harness="$1" event="$2" cmd="$3" out err
  out=$(mktemp)
  err=$(mktemp)
  jq -cn --arg cmd "$cmd" --arg ev "$event" \
    '{tool_input: {command: $cmd}, hook_event_name: $ev}' \
    | bash "$HOOK" "$harness" >"$out" 2>"$err"
  status=$?
  stdout=$(cat "$out")
  stderr=$(cat "$err")
  rm -f "$out" "$err"
}

record() { # label ok
  if [[ "$2" == yes ]]; then pass=$((pass + 1)); printf 'PASS %s\n' "$1"; else fail=$((fail + 1)); printf 'FAIL %s (status=%s stdout=%q stderr=%q)\n' "$1" "$status" "$stdout" "$stderr"; fi
}

run_test() {
  local cmd="$1" expect="$2" label="$3" event="${4:-PreToolUse}" ok=no
  run_hook claude "$event" "$cmd"
  if [[ "$expect" == deny ]]; then
    [[ "$status" == 2 && -z "$stdout" && -n "$stderr" ]] && ok=yes
  else
    [[ "$status" == 0 && -z "$stdout" && -z "$stderr" ]] && ok=yes
  fi
  record "[$expect] $label" "$ok"
}

echo "=== gh-merge-pin.sh tests ==="

echo "--- Harness output contracts ---"
for h in claude codex unknown; do
  run_hook "$h" PreToolUse "gh pr merge 42"
  ok=no
  [[ "$status" == 2 && -z "$stdout" && "$stderr" == *'Merge Blocked'* ]] && ok=yes
  record "$h: block is stderr only, exit 2" "$ok"
  run_hook "$h" PreToolUse "gh pr merge 42 --match-head-commit $SHA"
  ok=no
  [[ "$status" == 0 && -z "$stdout" && -z "$stderr" ]] && ok=yes
  record "$h: pinned merge is silent, exit 0" "$ok"
done
run_hook claude PreToolUse "gh pr merge 42 --admin --match-head-commit $SHA"
ok=no
[[ "$status" == 2 && "$stderr" == *'--admin'* ]] && ok=yes
record "admin block names the flag" "$ok"

echo "--- Pinned merges are allowed ---"
run_test "gh pr merge 42 --squash --match-head-commit $SHA" allow "flag after number"
run_test "gh pr merge --match-head-commit $SHA 42" allow "flag before number"
run_test "gh pr merge 42 --match-head-commit=$SHA" allow "equals form"
run_test "gh pr merge 42 --match-head-commit \"$SHA\"" allow "double-quoted sha"
run_test "gh pr merge 42 --match-head-commit '$SHA'" allow "single-quoted sha"
run_test "gh pr merge 42 --match-head-commit $SHA256" allow "sha256 object id"
run_test "gh pr merge 42 --match-head-commit $SHA" allow "pre_tool_use event" pre_tool_use
run_test "gh -R Range-Engineering/range pr merge 42 --match-head-commit $SHA" allow "-R before pr"
run_test "gh --repo=o/r pr merge 42 --match-head-commit $SHA" allow "--repo= before pr"

echo "--- Unpinned merges are denied ---"
run_test "gh pr merge 42 --squash" deny "no pin"
run_test "gh pr merge" deny "bare merge"
run_test "gh pr merge 42 --match-head-commit" deny "flag with no value"
run_test "gh pr merge 42 --match-head-commit abc123" deny "abbreviated sha"
run_test "gh pr merge 42 --match-head-commit HEAD" deny "ref instead of sha"
run_test "gh pr merge 42 --match-head-commit \$(gh pr view 42 --json headRefOid -q .headRefOid)" deny "sha resolved at merge time"
run_test "gh pr merge 42 --match-head-commit \$SHA" deny "variable instead of literal sha"
run_test "gh pr merge 42 --match-head-commit ${SHA}0" deny "41-char value"

echo "--- --admin is always denied ---"
run_test "gh pr merge 42 --admin --match-head-commit $SHA" deny "admin with pin"
run_test "gh pr merge 42 --match-head-commit $SHA --admin" deny "admin after pin"
run_test "gh pr merge 42 --admin" deny "admin without pin"

echo "--- Invocation shapes that must still be seen ---"
run_test "cd /repo && gh pr merge 42" deny "after &&"
run_test "echo ok; gh pr merge 42" deny "after ;"
run_test "true | gh pr merge 42" deny "after pipe"
run_test "(gh pr merge 42)" deny "in subshell"
run_test "out=\$(gh pr merge 42)" deny "in command substitution"
run_test "GH_TOKEN=x gh pr merge 42" deny "with env prefix"
run_test "gh -R o/r pr merge 42" deny "-R before pr"
run_test "gh --repo o/r pr merge 42" deny "--repo before pr"
run_test "env GH_TOKEN=x gh pr merge 42" deny "env wrapper"
run_test $'echo hi\ngh pr merge 42' deny "on a later line"
run_test "gh pr merge 42 --match-head-commit $SHA && gh pr merge 43" deny "second merge unpinned"

echo "--- Pin must belong to the same merge ---"
run_test "gh pr merge 42; echo --match-head-commit $SHA" deny "pin text in a later command"
run_test "echo --match-head-commit $SHA; gh pr merge 42" deny "pin text in an earlier command"

echo "--- Not a merge invocation ---"
run_test "gh pr view 42" allow "pr view"
run_test "gh pr list" allow "pr list"
run_test "git merge main" allow "git merge"
run_test "echo 'gh pr merge 42'" allow "quoted mention"
run_test "git commit -m 'document gh pr merge usage'" allow "commit message mention"
run_test "grep -rn 'gh pr merge' docs" allow "grep for the phrase"
run_test "echo 'Bash(gh pr merge *)'" allow "permission rule text in quotes"
run_test "jq '.allow += [\"Bash(gh pr merge *)\"]' settings.json" allow "permission rule text in jq filter"
run_test "" allow "empty command"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
