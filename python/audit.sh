#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

echo_info "running dependency checker"

pip freeze | safety check --stdin
exitonfail $? "dependency audit"

echo_info "running license checker"

LICENSE_LIST="$(curl -L https://raw.githubusercontent.com/defencedigital/react-lint-config/master/licenses.json | jq -c -r '.[]')"
exitonfail $? "obtaining license list"

LICENSES_USED="$(pip-licenses)"
exitonfail $? "checking licenses used"

# check what licenses are used in pip packages and remove ones that are allowed
IFS=$'\n'
for LICENSE in $LICENSE_LIST; do
    LICENSES_USED="$(sed "/$LICENSE/d" <<< "$LICENSES_USED")"
done

# if results contain more than just heading row we have license violations
# disable word splitting warning as wc produces number
# shellcheck disable=SC2046
if [ $(echo "$LICENSES_USED" | wc -l) -gt 1 ]; then
    echo "$LICENSES_USED"
    warnonfail 1 "licence checker"
    echo "PLEASE REVIEW LICENSES LISTED ABOVE"
fi

echo_success "Security audit passed"
