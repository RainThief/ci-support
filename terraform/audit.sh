#!/usr/bin/env bash
set -uo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./terraform/include.sh
source "$CI_SUPPORT_ROOT/terraform/include.sh"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

echo_info "running tfsec"
while IFS= read -r DIR; do
    pushd "$DIR" > /dev/null || continue

    # skip terraform cache folder
    [[ $DIR =~ .terraform ]] && continue

    if ! RESULT=$(terraform init -force-copy -input=false -backend=false -lock=false 2>&1); then
        echo "$RESULT"
        exitonfail 1 "terrform init"
    fi

    echo "running tfsec on $DIR"

    tfsec .
    exitonfail $? "terraform audit"

    popd > /dev/null || exit 1
done < <(printf '%s\n' "$(get_terraform_dirs ./)")

echo_success "terraform audit passed"
