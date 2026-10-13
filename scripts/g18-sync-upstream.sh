#!/bin/sh
# Merge other upstream changes while retaining all frozen local inputs.
set -eu
cd "$(dirname "$0")/.."
ref=${1:-upstream/istoreos-24.10}
if [ -n "$(git status --porcelain)" ]; then
    echo "Commit local changes before synchronizing." >&2
    exit 1
fi
if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
    echo "Finish or abort the existing merge first." >&2
    exit 1
fi
python3 scripts/g18-wifi-guard.py --baseline HEAD
git rev-parse --verify "$ref^{commit}" >/dev/null
base=$(git rev-parse HEAD)
# A conflicting merge is expected when upstream modifies locked inputs.
if git merge --no-commit --no-ff "$ref"; then
    :
else
    git rev-parse -q --verify MERGE_HEAD >/dev/null || exit 1
fi
if ! git rev-parse -q --verify MERGE_HEAD >/dev/null; then
    exit 0
fi
# Use the pre-merge lock, never an upstream copy.
git show "$base:config/g18-wifi-lock.json" | python3 -c '
import json, subprocess, sys
lock = json.load(sys.stdin)
paths = lock["directories"] + list(lock["sha256"]) + ["config/g18-wifi-lock.json"]
subprocess.run(["git", "restore", "--source=" + sys.argv[1], "--staged", "--worktree", "--", *paths], check=True)
' "$base"
python3 scripts/g18-wifi-guard.py --baseline "$base"
if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    echo "Wireless inputs preserved. Resolve remaining merge conflicts, then run the guard and commit." >&2
    exit 1
fi
echo "Wireless inputs preserved. Merge is staged for review; build/test before committing."
