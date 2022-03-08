#!/usr/bin/env bash
set -uo pipefail

check_aws_credentials() {
    if [ "${AWS_ACCESS_KEY_ID:=""}" == "" ]; then
        echo_warning "AWS_ACCESS_KEY_ID env var is not exported"
        return 1
    fi
    if [ "${AWS_SECRET_ACCESS_KEY:=""}" == "" ]; then
        echo_warning "AWS_SECRET_ACCESS_KEY env var is not exported"
        return 1
    fi
    if [ "${AWS_DEFAULT_REGION:=""}" == "" ]; then
        echo_warning "AWS_DEFAULT_REGION env var is not exported"
        return 1
    fi
}

get_terraform_dirs() {
    find . -maxdepth 3 -name '*.tf' -printf '%h\n' | sort -u | uniq
    # find ./ -maxdepth 3 -name "*.tf" -o -name "*.tfvars" | sed -E 's/[\.0-9A-Za-z\-_]+.tf(vars)?//' | sort -u | uniq
}
