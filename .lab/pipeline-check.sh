#!/usr/bin/env bash
# Checks your pipeline: the workflow file, the runs GitHub recorded and the published image.
# Used by ./verify.sh on your laptop and by the Lab check in GitHub Actions.
cd "$(dirname "$0")/.."
command -v gh >/dev/null || { echo "The GitHub CLI (gh) is not installed: https://cli.github.com, then run: gh auth login"; exit 1; }
if [ -n "${GITHUB_REPOSITORY:-}" ]; then R="$GITHUB_REPOSITORY"; else
  R=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
fi
[ -n "$R" ] || { echo "Cannot work out your repository: run this inside your fork"; exit 1; }
OWNER=${R%%/*}; NAME=${R##*/}; NAME_LC=$(echo "$NAME" | tr '[:upper:]' '[:lower:]'); OWNER_LC=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')
pass=0; failn=0; total=0
check() { local d="$1"; shift; total=$((total+1)); if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
WF=.github/workflows/ci.yml
DEF=$(gh api "repos/$R" --jq .default_branch 2>/dev/null || echo main)

echo "== The workflow file ($WF) =="
check "the file exists" test -s $WF
st() { python3 .lab/workflow_lint.py "$1" 2>/dev/null; }
check "triggers on pull requests and on pushes to main" st triggers
check "top-level permissions are read-only (least privilege)" st permissions
check "no action pinned to a moving ref (@main, @master, @latest)" st pins
check "has a concurrency group that cancels superseded runs" st concurrency
check "the test job uses PostgreSQL and Redis service containers with health checks" st services
check "uses a cache (setup-python cache, actions/cache or build cache)" st cache
check "builds with Docker (build-push-action or docker build)" st build
check "scans with Trivy and fails the build on findings (exit-code 1)" st scan
check "publishes only from main (an if: on the publish job) with packages: write only on that job" st publish
check "jobs lint, test, build, scan and publish exist and are chained with needs:" st chain

echo "== What GitHub recorded =="
RUNS=$(gh api "repos/$R/actions/workflows/ci.yml/runs?branch=$DEF&event=push&status=completed&per_page=10" 2>/dev/null)
rid=$(echo "$RUNS" | python3 -c 'import json,sys; r=[x for x in json.load(sys.stdin).get("workflow_runs",[]) if x["conclusion"]=="success"]; print(r[0]["id"] if r else "")' 2>/dev/null)
check "the latest push to $DEF has a green CI run" bash -c "[ -n '$rid' ]"
jobs_ok() { # all five job kinds succeeded in the green run
  gh api "repos/$R/actions/runs/$rid/jobs?per_page=50" 2>/dev/null | python3 -c '
import json,sys
j={x["name"].lower():x["conclusion"] for x in json.load(sys.stdin)["jobs"]}
need=["lint","test","build","scan","publish"]
ok=all(any(k in n and c=="success" for n,c in j.items()) for k in need)
sys.exit(0 if ok else 1)'
}
check "in that run lint, test, build, scan and publish all succeeded (none skipped)" jobs_ok
PRS=$(gh api "repos/$R/actions/workflows/ci.yml/runs?event=pull_request&status=completed&per_page=50" 2>/dev/null)
pr_evidence() {
  echo "$PRS" | python3 -c '
import json,sys
runs=sorted(json.load(sys.stdin).get("workflow_runs",[]), key=lambda x:x["created_at"])
f=[r for r in runs if r["conclusion"]=="failure"]
if not f: sys.exit(1)
first=f[0]["created_at"]
sys.exit(0 if any(r["conclusion"]=="success" and r["created_at"]>first for r in runs) else 1)'
}
check "a pull request went red and a later one went green (the gate caught a bad change)" pr_evidence

echo "== The image =="
pkg_tags() { gh api "users/$OWNER_LC/packages/container/$NAME_LC/versions?per_page=100" --jq '.[].metadata.container.tags[]' 2>/dev/null; }
tags=$(pkg_tags)
if [ -z "$tags" ] && grep -qE '^TEARDOWN VERIFIED \(' SUBMISSION.md 2>/dev/null; then
  echo "PASS  the package is gone, as it should be after the tear down (your SUBMISSION.md has the proof)"; pass=$((pass+1)); total=$((total+1))
else
  check "the package ghcr.io/$OWNER_LC/$NAME_LC exists (needs the read:packages scope: gh auth refresh -s read:packages)" bash -c "[ -n '$tags' ]"
  check "it has a tag equal to a full commit SHA" bash -c "echo '$tags' | grep -Eq '^[0-9a-f]{40}\$'"
  check "it has the tag latest" bash -c "echo '$tags' | grep -qx latest"
fi

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$total)"; else echo "$failn check(s) failed, $pass passed. Fix the FAIL lines and run again."; fi
exit "$failn"
