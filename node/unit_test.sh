#!/usr/bin/env bash
set -u

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./node/move_modules.sh
source "$CI_SUPPORT_ROOT/node/move_modules.sh"

move_modules

export NODE_ENV=test

JEST="false"


while [[ $# -gt 0 ]]
do
key="$1"

ARGS=""

case $key in
    -c|--coverage)
    ARGS="$ARGS --coverage"
    shift
    ;;
    -w|--watch)
    ARGS="$ARGS --watch"
    shift
    ;;
    -j|--jest)
    JEST="true"
    shift
    ;;
    *)
    ARGS+=("$1")
    shift
    ;;
esac
done

set -- "${ARGS[@]}"


if [ "$JEST" == "true" ]; then
    # shellcheck disable=SC2068
    npx jest --colors --updateSnapshot $@
else
    # shellcheck disable=SC2068
    npx react-scripts test $@
fi

EXIT=$?
restore_modules
exitonfail $EXIT "Unit tests"

echo_success "Unit tests passed"
