#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./terraform/include.sh
source "$CI_SUPPORT_ROOT/terraform/include.sh"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"


check_aws_credentials
exitonfail $? "AWS credentials not set; static analysis"


# init tflint aws module
if [ ! -f /usr/app/.tflint.hcl ];then
cat <<EOT >> /usr/app/.tflint.hcl
plugin "aws" {
    enabled = true
    version = "0.11.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
    deep_check = true
}
EOT
fi

if tflint --init > /dev/null; then
    exitonfail $? "tflint init"
fi

echo_info "linting terraform"
# run tflint in all dirs that contain terraform
while IFS= read -r DIR; do
    pushd "$DIR" > /dev/null || continue

    # skip terraform cache folder
    [[ $DIR =~ .terraform ]] && continue

    echo "linting $DIR"

    if ! RESULT=$(terraform init -force-copy -input=false -backend=false -lock=false 2>&1); then
        echo "$RESULT"
        exitonfail 1 "terrform init"
    fi

    echo_info "running terraform format"
    FMT_ARGS="-write=true"
    if [ "$CI" == "true" ]; then
        FMT_ARGS="-check -diff -write=false"
    fi
    # shellcheck disable=SC2086
    if ! RESULT=$(terraform fmt $FMT_ARGS -recursive . 2>&1); then
        echo "$RESULT"
        echo_warning "please make changes above"
        exitonfail 1 "terrform fmt"
    fi

    echo_info "running tflint"
    if ! RESULT=$(tflint --enable-plugin=aws --module . 2>&1); then
        echo "$RESULT"
        exitonfail 1 "tflint"
        continue
    fi

    popd > /dev/null || exit 1

done < <(printf '%s\n' "$(get_terraform_dirs ./)")

echo_success "terraform static analysis passed"
