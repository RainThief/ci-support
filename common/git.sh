#!/bin/bash

set -euo pipefail

main_branch() {
    [ -f .git/refs/heads/master ] && echo master || echo main
}

diff_to_main_branch() {
    DIFF_FILES=$(git diff --diff-filter=ACMR --name-only "$(main_branch)")
    echo "$DIFF_FILES" | { grep "$1" || true; }
}
