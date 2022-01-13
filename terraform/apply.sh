#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"


# shellcheck source=./terraform/include.sh
source "$CI_SUPPORT_ROOT/terraform/include.sh"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"


check_aws_credentials
exitonfail $? "AWS credentials not set; static analysis"

for DIR in "$@"
do
    if [ ! -d "$DIR" ]; then
        exitonfail 1 "directory $DIR does not exist; terraform plan"
    fi

    pushd "$1" || exit 1

    echo_info "running apply on $1"
    terraform apply -auto-approve tf.plan
    exitonfail $? "terraform apply"

    popd > /dev/null || exit 1
done

echo_success "terraform apply passed"
