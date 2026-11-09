#!/usr/bin/env bash
# The pipeline itself is checked with the GitHub API (needs the token that the Lab check job provides).
bash .lab/pipeline-check.sh >/tmp/pipeline-check.out 2>&1
rc=$?
sed -e 's/^PASS  /- ✅ /' -e 's/^FAIL  /- ❌ /' /tmp/pipeline-check.out | grep -E '^- (✅|❌)'
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
