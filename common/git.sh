#!/bin/bash

set -uo pipefail

main_branch() {
    [ -f .git/refs/heads/master ] && echo master || echo main
}

diff_to_main_branch() {
    DIFF_FILES=$(git diff --diff-filter=ACMR --name-only "$(main_branch)")
    echo "$DIFF_FILES" | { grep "$1" || true; }
}

check_if_git_repo() {
    if [ ! -d ".git" ]; then
        exitonfail 1 "Not a git repository; running CI support"
    fi

    # ci always has a valid git repo
    if [ "$CI" == "false" ]; then
        if ! git rev-parse --verify "$(main_branch)"; then
            exitonfail 1 "Cannot identify main branch; running CI support"
        fi
    fi
}
