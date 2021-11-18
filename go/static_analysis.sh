#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

echo_info "linting go"
# to skip test files add arg "--skip-files test.go"
golangci-lint --color always run -exclude-use-default -E revive -E gosec -E bodyclose -E gofmt -E wsl "$@"
exitonfail $? "go linting"

echo_success "Go static analysis passed"
