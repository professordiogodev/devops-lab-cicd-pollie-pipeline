#!/usr/bin/env bash
# Run with: ./verify.sh   (needs the GitHub CLI, logged in, and the read:packages scope)
cd "$(dirname "$0")"
exec bash .lab/pipeline-check.sh
