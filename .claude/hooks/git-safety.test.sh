#!/bin/bash

# Tests for git-safety.sh hook

HOOK="$HOME/.claude/hooks/git-safety.sh"
pass=0
fail=0

run_test() {
  local cmd="$1" expect="$2" label="$3"
  local result
  result=$(echo "{\"tool_input\":{\"command\":\"$cmd\"},\"hook_event_name\":\"test\"}" | bash "$HOOK" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')
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

echo "=== git-safety.sh tests ==="
echo ""

echo "--- Destructive operations: blocked ---"
run_test "git reset --hard" deny "reset --hard"
run_test "git reset --hard HEAD~1" deny "reset --hard HEAD~1"
run_test "git clean -f" deny "clean -f"
run_test "git clean -fd" deny "clean -fd"
run_test "git branch -D old-branch" deny "branch -D"
run_test "git stash clear" deny "stash clear"
run_test "git commit --amend" deny "commit --amend"
run_test "git commit --amend -m 'fix'" deny "commit --amend -m"
run_test "git push --force" deny "push --force"
run_test "git push -f" deny "push -f"
run_test "git push origin main --force" deny "push origin main --force"
run_test "git checkout -- ." deny "checkout -- ."

echo ""
echo "--- Safe variants: allowed ---"
run_test "git push --force-with-lease" allow "push --force-with-lease"
run_test "git push --force-with-lease origin feature" allow "push --force-with-lease origin"
run_test "git branch -d old-branch" allow "branch -d (safe delete)"
run_test "git reset --soft HEAD~1" allow "reset --soft"
run_test "git clean -n" allow "clean -n (dry run)"
run_test "git stash" allow "stash"
run_test "git stash pop" allow "stash pop"
run_test "git commit -m 'test'" allow "commit -m"
run_test "git push origin main" allow "push (normal)"
run_test "git checkout feature-branch" allow "checkout branch"
run_test "git checkout -- src/file.ts" allow "checkout specific file"

echo ""
echo "--- With -C path prefix: still caught ---"
run_test "git -C /workplace/range/containers/dev-1 reset --hard" deny "-C reset --hard"
run_test "git -C /workplace/range/containers/dev-1 commit --amend" deny "-C commit --amend"
run_test "git -C /workplace/range/containers/dev-1 push --force" deny "-C push --force"
run_test "git -C /workplace/range/containers/dev-1 push -f" deny "-C push -f"
run_test "git -C /workplace/range/containers/dev-1 checkout -- ." deny "-C checkout -- ."
run_test "git -C /workplace/range/containers/dev-1 clean -fd" deny "-C clean -fd"
run_test "git -C /workplace/range/containers/dev-1 branch -D x" deny "-C branch -D"
run_test "git -C /foo push --force-with-lease" allow "-C push --force-with-lease"
run_test "git -C /foo status" allow "-C status"
run_test "git -C /foo log --oneline -5" allow "-C log"

echo ""
echo "--- With -c config flag: still caught ---"
run_test "git -c user.name=x commit --amend" deny "-c config + commit --amend"
run_test "git -c user.name=x push --force" deny "-c config + push --force"
run_test "git -c user.name=x commit -m 'test'" allow "-c config + normal commit"

echo ""
echo "--- Chained commands: caught ---"
run_test "git add . && git commit --amend" deny "chained: add && commit --amend"
run_test "git add . && git commit -m 'ok'" allow "chained: add && normal commit"

echo ""
echo "--- Safe operations: pass through ---"
run_test "git status" allow "status"
run_test "git log --oneline -10" allow "log"
run_test "git diff" allow "diff"
run_test "git add ." allow "add"
run_test "git fetch origin" allow "fetch"
run_test "git pull" allow "pull"
run_test "git branch -l" allow "branch -l"
run_test "git remote -v" allow "remote -v"

echo ""
echo "--- Non-git commands: pass through ---"
run_test "echo git reset --hard" allow "echo (not actual git)"
run_test "grep 'git reset' file.txt" allow "grep (not actual git)"

echo ""
echo "=== Results: $pass passed, $fail failed ==="
exit $fail
