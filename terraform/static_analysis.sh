#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

echo_info "linting terraform"
terraform fmt -check=true -diff=true -recursive=true .
exitonfail $? "terraform fmt"

tflint --enable-plugin=aws --module .
exitonfail $? "terraform linting"

echo_success "Terraform static analysis passed"
