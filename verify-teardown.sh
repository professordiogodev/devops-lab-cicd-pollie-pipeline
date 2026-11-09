#!/usr/bin/env bash
# Proves that the lab's leftovers are gone. Run with: ./verify-teardown.sh
cd "$(dirname "$0")"
command -v gh >/dev/null || { echo "The GitHub CLI (gh) is not installed"; exit 1; }
R=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
OWNER=${R%%/*}; OWNER_LC=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]'); NAME_LC=$(echo "${R##*/}" | tr '[:upper:]' '[:lower:]')
pass=0; failn=0; total=0
check() { local d="$1"; shift; total=$((total+1)); if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
code=$(gh api -i "users/$OWNER_LC/packages/container/$NAME_LC" 2>/dev/null | head -1 | awk '{print $2}')
check "the package ghcr.io/$OWNER_LC/$NAME_LC no longer exists (HTTP 404; got ${code:-no answer}: if 403, run gh auth refresh -s read:packages)" bash -c "[ '$code' = 404 ]"
check "no artifacts are left in your fork" bash -c "[ \"\$(gh api 'repos/$R/actions/artifacts' --jq .total_count)\" = 0 ]"
check "the CI workflow is disabled" bash -c "[ \"\$(gh api 'repos/$R/actions/workflows/ci.yml' --jq .state)\" = disabled_manually ]"
echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$total)"; else echo "NOT CLEAN: $failn leftover(s). Finish the tear down steps and run this again."; fi
exit "$failn"
