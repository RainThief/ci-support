#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./common/git.sh
source "$CI_SUPPORT_ROOT/common/git.sh"

# shellcheck source=./node/move_modules.sh
source "$CI_SUPPORT_ROOT/node/move_modules.sh"

move_modules

ESLINT_OPT="--fix"

if [ "$CI" == "true" ]; then
    ESLINT_OPT="--quiet"
fi


LINT_SASS=${LINT_SASS:-"true"}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --no-lint-sass)
    LINT_SASS="false"
    shift
    ;;
esac
done


skip_dir() {
    if [[ $1 == *"./."* ]] \
    || [[ $1 == *"coverage"* ]] \
    || [[ $1 == *"node_modules"* ]] \
    || [[ $1 == *"config.js"* ]] \
    || [[ $1 == *"build"* ]] \
    || [[ $1 == *"__generated__"* ]]
        then
        return 0
    fi
    return 1
}


if [ "$DIFF_LINT" == "true" ]; then
    FILES=$(diff_to_main_branch ".js\|.js\|.jsx\|.tsx\|.json")

    if [ "$FILES" != "" ]; then
        echo_info "linting javascript"

        while IFS= read -r FILE; do

            if skip_dir "$FILE"; then
                continue
            fi

            echo "linting $FILE"

            if ! RESULT=$(npx eslint "$ESLINT_OPT" --color -c .eslintrc.js "$FILE"); then
                echo_warning "error linting $FILE"
                echo "$RESULT"
                exitonfail 1 "eslint"
            fi
        done < <(printf '%s\n' "$FILES")
    fi

    FILES=$(diff_to_main_branch ".css\|.scss\|.sass")
    if [ "$FILES" != "" ]; then
        echo_info "linting sass"

         while IFS= read -r FILE; do

            if skip_dir "$FILE"; then
                continue
            fi

            echo "linting $FILE"

            if ! RESULT=$(npx stylelint --color "$FILE"); then
                echo_warning "error linting $FILE"
                echo "$RESULT"
                exitonfail 1 "Stylelint"
            fi
        done < <(printf '%s\n' "$FILES")
    fi

else
    echo_info "linting javascript"
    npx eslint "$ESLINT_OPT" --color ./src -c .eslintrc.js --ext .ts,.tsx,.js,.jsx
    exitonfail $? "eslint"

    if [ "$LINT_SASS" == "true" ]; then
        echo_info "linting sass"
        npx stylelint --color --allow-empty-input "**/*.{css,scss,sass}"
        exitonfail $? "Stylelint"
    fi
fi

restore_modules

echo_success "ECMAscript static analysis passed"
