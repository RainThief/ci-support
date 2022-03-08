#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./common/git.sh
source "$CI_SUPPORT_ROOT/common/git.sh"


if [ "$DIFF_LINT" == "true" ]; then
    FILES=$(diff_to_main_branch ".py")
else
    FILES=$(find . -iname "*.py")
fi

if [ "$FILES" != "" ]; then
    echo_info "linting python"

    while IFS= read -r FILE; do
        if [[ $FILE == *"./."* ]]
            then
            continue
        fi
        echo "linting $FILE"

        if ! RESULT=$(pylint "$@" "$FILE"); then
            EXIT=1
            echo_warning "error linting $FILE"
            echo "$RESULT"
            exitonfail $EXIT "pylint"
        fi
    done < <(printf '%s\n' "$FILES")
fi


echo_info "running bandit"
bandit src/main.py
exitonfail $? "bandit"


echo_success "Python static analysis passed"
