#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"


# shellcheck source=./terraform/include.sh
source "$CI_SUPPORT_ROOT/terraform/include.sh"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"


check_aws_credentials
exitonfail $? "AWS credentials not set; static analysis"


pushd "$1" || exit 1

echo_info "running terraform plan on $1"
terraform init -force-copy -lock=false
exitonfail $? "terraform init"


echo_info "running terraform destroy on $1"
terraform destroy -lock=false -auto-approve
exitonfail $? "terraform destroy"

popd > /dev/null || exit 1


echo_success "terraform destroy"
