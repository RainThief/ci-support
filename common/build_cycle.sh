#!/usr/bin/env bash
set -uo pipefail

DOCKERFILE="build/Dockerfile"
CI=${CI:-"false"}

# alternative dockerfiles to check for i.e build/Dockerfile.ubi8
VARIANTS=(
    ubi8
    debian
    alpine
)

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./common/docker.sh
source "$CI_SUPPORT_ROOT/common/docker.sh"


# check if we need qemu and it is installed
check_qemu_installed


build_with_cache() {
    export USE_CACHE=true
    bash "$CI_SUPPORT_ROOT/common/build_image.sh" "$@"
    return $?
}


build_no_cache() {
    export USE_CACHE=false
    bash "$CI_SUPPORT_ROOT/common/build_image.sh" "$@"
    return $?
}

build_success() {
    echo_success "image built with dockerfile '$DOCKERFILE'"
    exit 0
}

build() {
    echo_info "attempting build with dockerfile '$DOCKERFILE'"

    if build_with_cache "$@"; then
        build_success
    fi

    echo_warning "$DOCKERFILE failed to build"
    echo_info "attempting cacheless build with dockerfile '$DOCKERFILE'"
    if build_no_cache "$@"; then
        build_success
    fi

    echo_warning "$DOCKERFILE failed to build"
    return 1
}

ORIG_DOCKERFILE="$DOCKERFILE"

# if build fails then check for alternative docker files to use
if ! build "$@"; then
    for VARIANT in "${VARIANTS[@]}"
        do
            DOCKERFILE=$ORIG_DOCKERFILE.$VARIANT
            if [ -f "$DOCKERFILE" ]; then
                echo_warning "trying build with alternative dockerfile '$DOCKERFILE'"
                export DOCKERFILE
                export VARIANT
                export USE_CACHE=true
                build
            fi
        done
fi

# if no success exit was raised and we are here, then this script has failed
exit 1
