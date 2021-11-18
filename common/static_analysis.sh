#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./common/git.sh
source "$CI_SUPPORT_ROOT/common/git.sh"

EXCLUDE_CI_DIR=build/"$(basename "$(realpath "$CI_SUPPORT_ROOT")")"


if [ "$DIFF_LINT" == "true" ]; then
    FILES=$(diff_to_main_branch ".sh$")
else
    FILES=$(find . -iname "*.sh")
fi


if [ "$FILES" != "" ]; then
    echo_info "linting bash"

    while IFS= read -r FILE; do
        if [[ $FILE == *"$EXCLUDE_CI_DIR"* ]] \
        || [[ $FILE == *"node_modules"* ]]
            then
            continue
        fi
        echo "linting $FILE"

        if ! RESULT=$(shellcheck -x "$@" "$FILE"); then
            EXIT=1
            echo "$RESULT"
            exitonfail $EXIT "shellcheck"
        fi
    done < <(printf '%s\n' "$FILES")
fi


if [ "$DIFF_LINT" == "true" ]; then
    FILES=$(diff_to_main_branch "Dockerfile")
else
    FILES=$(find . -iname "Dockerfile*")
fi

if [ "$FILES" != "" ]; then
    echo_info "linting dockerfile"
    while IFS= read -r FILE; do
        if [[ $FILE == *"$EXCLUDE_CI_DIR"* ]] \
        || [[ $FILE == *"node_modules"* ]]
            then
            continue
        fi

        echo "linting $FILE"

        if ! RESULT=$(hadolint "$@" "$FILE"); then
            EXIT=1
            echo "$RESULT"
            exitonfail $EXIT "hadolint"
        fi
    done < <(printf '%s\n' "$FILES")
fi


echo_success "Common static analysis passed"
