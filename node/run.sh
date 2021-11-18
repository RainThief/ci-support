#!/usr/bin/env bash

set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./node/move_modules.sh
source "$CI_SUPPORT_ROOT/node/move_modules.sh"

_term() {
  restore_modules
  kill -TERM "$CHILD_PROCESS" 2>/dev/null
}

move_modules

trap _term SIGINT

yarn run start
CHILD_PROCESS=$!

restore_modules
