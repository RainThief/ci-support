#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

COVER_REPORT="logs/coverage.out"
HTML_REPORT="logs/coverage.html"

exit_tests() {
    if [ "$1" -gt 0 ]; then
        rm -f $COVER_REPORT
    fi
    exitonfail "$1" "unit tests"
}

rm -f $HTML_REPORT

TEST_OUTPUT=$(go test -race -coverprofile=$COVER_REPORT ./... 2> /dev/null)
EXIT=$?
echo "$TEST_OUTPUT" | sed ''/PASS/s//"$(printf "\033[32mPASS\033[0m")"/'' | sed ''/FAIL/s//"$(printf "\033[31mFAIL\033[0m")"/''
echo_info "coverage report"
go tool cover -func=$COVER_REPORT -o /dev/stdout
exit_tests $EXIT "unit tests"

if [ "$(echo "$TEST_OUTPUT" | sed -r 's/^.*: ([0-9]{2}).*/\1/')" -lt 80 ]; then
    echo_warning "coverage check failed: coverage report generated at $HTML_REPORT"
    go tool cover -html=$COVER_REPORT -o $HTML_REPORT
    exit_tests 1 "unit tests"
fi

echo_success "Unit tests passed"
