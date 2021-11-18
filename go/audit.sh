#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"


echo_info "running dependency checker"
export USER=ci
go list -json -m all | nancy sleuth
exitonfail $? "nancy"


echo_info "running license checker"

LICENSES_USED="$(go-licenses csv ./... 2> /dev/null)"
if [ "${#LICENSES_USED}" -eq 0 ]; then
    echo_warning "unable to obtain license whitelist"
    exitonfail 1 "licence checker"
fi

LICENSE_LIST="$(curl -L -s https://raw.githubusercontent.com/defencedigital/react-lint-config/master/licenses.json | jq -c -r '.[]')"

# check what licenses are used in modules and remove ones that are allowed leaving violation list
IFS=$'\n'
for LICENSE in $LICENSE_LIST; do
    LICENSES_USED="$(sed "/$LICENSE/d" <<< "$LICENSES_USED")"
done

if [ "${#LICENSES_USED}" -gt 0 ]; then
    printf "\n%s\n" "$LICENSES_USED"
    echo_warning "PLEASE REVIEW LICENSES LISTED ABOVE"
    exitonfail 1 "licence checker"
fi

echo_success "Security audit passed"
