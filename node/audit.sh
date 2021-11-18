#!/usr/bin/env bash

set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./node/move_modules.sh
source "$CI_SUPPORT_ROOT/node/move_modules.sh"

move_modules

ALLOWED_LICENSES="$(< ./node_modules/@defencedigital/react-lint-config/licenses.json jq -c -r '.[]' | tr '\n' ';')"
if [ "$ALLOWED_LICENSES" == "" ]; then
    exitonfail 1 "License list import"
fi

# TODO: False positive for graphql-language-service. Remove when @apollographql/graphql-language-service-interface has been upgraded.
ALLOWED_LICENSES+='Custom: https://github.com/graphql/graphql-language-service;Custom: http://graphql.org/;Custom: https://flowtype.org/;'
npx license-checker --excludePrivatePackages --onlyAllow "$ALLOWED_LICENSES" >> /dev/null
EXIT=$?
if [ $EXIT -gt 0 ]; then
    restore_modules
    exitonfail $EXIT "License check"
fi

yarn audit
EXIT=$?

if [ $EXIT -gt 15 ]; then
    echo_danger "Security audit failed"
    restore_modules
    exit 1
fi
if [ $EXIT -gt 0 ]; then
    echo_warning "Security audit passed with warnings"
    restore_modules
    exit 0
fi

yarn outdated
warnonfail $? "Not all dependencies up to date"

restore_modules

echo_success "Audit passed"
