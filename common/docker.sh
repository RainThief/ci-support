#!/usr/bin/env bash
set -euo pipefail

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"
CI=${CI:-"false"}
DIFF_LINT=${DIFF_LINT:-"false"}
DOCKER_REG=${CI_IMAGE_NAME_BASE:-"ghcr.io"}
CI_IMAGE_NAME_BASE=${CI_IMAGE_NAME_BASE:-"ghcr.io/rainthief/ci-support"}
DOCKER_PROGRESS=${DOCKER_PROGRESS:-"auto"}
USE_CACHE=${USE_CACHE:-"true"}
DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:-""}

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./common/git.sh
source "$CI_SUPPORT_ROOT/common/git.sh"

check_if_git_repo

REPO_NAME="$(basename "$(cd "$PROJECT_ROOT"; git rev-parse --show-toplevel)")"


get_machine_arch(){
    case "$(uname -m)" in
        "x86_64")
        echo "linux/amd64"
        ;;
        "arm64")
        echo "linux/arm64"
        ;;
        "aarch64")
        echo "linux/arm64"
        ;;
        *)
        return 1
        ;;
    esac
}

get_env_arch(){
    if [ "$CI" == "true" ]; then
        echo "linux/amd64,linux/arm64";
        return
    fi
    get_machine_arch
}


# check for invalid architectures
set +e
if ! get_machine_arch > /dev/null; then
    echo_danger "your arctitecture '$(uname -m)' is not supported"
    exitonfail 1 "build docker"
fi
set -e

DOCKER_PLATFORM=${DOCKER_PLATFORM:-"$(get_env_arch)"}
if [ "$CI" != "true" ]; then
    DOCKER_PLATFORM="$(get_machine_arch)"
fi

CI_IMAGE_ARCH=${CI_IMAGE_ARCH:-"$(get_machine_arch)"}


docker_login() {
    if [ "$CI" == "true" ]; then
        docker login "$DOCKER_REG" -u "$DOCKER_USER" -p "$DOCKER_PASS"
    fi
}

docker_branch_tag() {
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    BRANCH_TAG="${GIT_BRANCH//\//--}"
    if [ "$GIT_BRANCH" == "main" ] || [ "$GIT_BRANCH" == "master" ] || [ "$GIT_BRANCH" == "HEAD" ]; then
        BRANCH_TAG="latest"
    fi
    echo $BRANCH_TAG
}

pull_image() {
    if docker pull "$1"; then
        echo_info "using '$1' for cache"
        return 0
    else
        echo_warning "cannot pull '$1' for cache"
        return 1
    fi
}

build_image_stage() {
    DOCKERFILE=$1
    IMAGE_NAME=$2
    TARGET=$3
    shift
    shift
    shift

    if [ "$TARGET" != "" ]; then
        TARGET="--target $TARGET"
    fi

    echo_info "building image stage '$IMAGE_NAME' arch:$DOCKER_PLATFORM"

    CACHES=""
    if [ "$USE_CACHE" == "true" ]; then
        set +e
        for CACHE_IMAGE in "$@"
        do
            if pull_image "$CACHE_IMAGE"; then
                CACHES="$CACHES --cache-from $CACHE_IMAGE"
            fi
        done
        set -e
    fi

    _build_image "$DOCKERFILE" "$IMAGE_NAME" "$CACHES" "$TARGET"
}

build_image() {
    DOCKERFILE=$1
    IMAGE_NAME=$2
    shift
    shift

    echo_info "building image '$IMAGE_NAME' arch:$DOCKER_PLATFORM"

    CACHES=""
    if [ "$CI" == "true" ] && [ "$USE_CACHE" == "true" ]; then
        set +e
        for CACHE_IMAGE in "$@"
        do
            if pull_image "$CACHE_IMAGE"; then
                CACHES="$CACHES --cache-from $CACHE_IMAGE"
            fi
        done
        set -e
    fi

    _build_image "$DOCKERFILE" "$IMAGE_NAME" "$CACHES"
}


check_qemu_installed() {
    if [ "$(get_machine_arch)" != "$DOCKER_PLATFORM" ] ; then
        if ! command -v qemu-x86_64-static  &> /dev/null; then
            exitonfail 1 "is qemu installed? building image for non native arch:$DOCKER_PLATFORM"
        fi
        docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    fi
}


setup_builder() {
    docker buildx use ci-builder || docker buildx create --name ci-builder --use

    check_qemu_installed

    ACTION="--load"
    # only on ci we push to registry
    if [ "$CI" == "true" ] && [ "$DOCKER_PLATFORM" != "$(get_machine_arch)" ]; then
        ACTION="--push";
    fi

    # multi arch images cannot yet save to local machine, outside ci (which pushes) this will fail
    if [ "$CI" == "false" ] && [[ "$DOCKER_PLATFORM" == *","* ]]; then
        exitonfail 1 "cannot save multi arch images locally, building image '$IMAGE_NAME' arch:$DOCKER_PLATFORM"
    fi
}

_build_image() {
    DOCKERFILE=$1
    IMAGE_NAME=$2
    CACHES=${3:-""}
    TARGET=${4:-""}

    echo "$GITHUB_TOKEN" > "$CI_SUPPORT_ROOT/secrets.txt"

    CACHE=""

    if [ "$USE_CACHE" == "false" ]; then
        CACHE="--no-cache"
        CACHES=""
    fi

    setup_builder

    # do not quote vars used as inline args
    # shellcheck disable=SC2086
    DOCKER_BUILDKIT=1 docker buildx build $ACTION \
        --platform $DOCKER_PLATFORM \
        --pull \
        --progress="$DOCKER_PROGRESS" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        $CACHE \
        $CACHES \
        $TARGET \
        $DOCKER_BUILD_ARGS \
        --secret id=GITHUB_TOKEN,src="$CI_SUPPORT_ROOT/secrets.txt" \
        -t "$IMAGE_NAME" -f "$DOCKERFILE" .
    EXIT=$?
    docker buildx stop ci-builder
    docker buildx use default
    exitonfail $EXIT "build image"

    push_image "$IMAGE_NAME"
}

push_image() {
    # only ci can push to registry
    # if build stage did not "load" then no local image exists
    if [ "$CI" == "true" ] && [ "$ACTION" == "--load" ]; then
        docker push "$1"
    fi
}

# args ci_image_type ci_image_version ci_image_tag
get_ci_image() {
    # set ci images to just use arch of machine running
    DOCKER_PLATFORM="$CI_IMAGE_ARCH"

    docker_login

    NAME_PART="$1-$2"
    if [ "$2" == "" ]; then
        NAME_PART="$1"
    fi

    ID_TAG_PART="-$REPO_NAME"

    if [ "$1" == "common" ] || [ "$1" == "cve" ]; then
        ID_TAG_PART=""
    fi

    CI_IMAGE_NAME="$CI_IMAGE_NAME_BASE:${NAME_PART}${ID_TAG_PART}"

    DOCKERFILE="$CI_SUPPORT_ROOT/images/$1/$2/Dockerfile"

    if [ "$CI" == "true" ] && grep -i "as builder" "$DOCKERFILE"  > /dev/null; then
        build_image_stage "$DOCKERFILE" "$CI_IMAGE_NAME-builder" builder "$CI_IMAGE_NAME-builder"
        build_image "$DOCKERFILE" "$CI_IMAGE_NAME" "$CI_IMAGE_NAME-builder" "$CI_IMAGE_NAME"
    else
        build_image "$DOCKERFILE" "$CI_IMAGE_NAME" "$CI_IMAGE_NAME"
    fi

    echo_success "built ci image '$CI_IMAGE_NAME' arch:$DOCKER_PLATFORM"
}

# Builds and executes a CI container
# args
#   ci_image_type  the type of image e.g. common, go, python, typescript
#   ci_image_version the revision of image i.e. 1.16
#   cmd the command or script to run inside image
#   extra_args exgtra arguments to pass to script or command
exec_ci_container() {
    if [ $# -lt 3 ]; then
        exitonfail 1 "invalid args passed to exec_ci_script(); CI"
    fi

    get_ci_image "$@"

    OPTS="-it --init"

    CONT_NAME="$(basename "$CI_IMAGE_NAME" | sed -r 's/:(.*)//' )-$(date +%s)"
    CONT_USER=$(id -u):$(id -g)

    if [ "$CI" == "true" ]; then
        OPTS="-t"
    fi

    IMAGE_TYPE=$1
    shift
    shift
    CMD=$1
    shift

    MOUNTS="-v $PROJECT_ROOT/:/usr/app/"

    if [ "$IMAGE_TYPE" == "go" ]; then
        mkdir -p "$PROJECT_ROOT/build/.nancy_cache"
        MOUNTS="${MOUNTS} -v $PROJECT_ROOT/build/.nancy_cache:/home/.ossindex"
    elif [ "$IMAGE_TYPE" == "python" ]; then
        mkdir -p "$PROJECT_ROOT/build/.pylint_cache"
        mkdir -p "$PROJECT_ROOT/build/.pytest_cache"
        MOUNTS="${MOUNTS} -v $PROJECT_ROOT/build/.pylint_cache:/var/cache/pylint"
    elif [ "$IMAGE_TYPE" == "node" ]; then
        mkdir -p "$PROJECT_ROOT/coverage"
        mkdir -p "$PROJECT_ROOT/build/dist"
        MOUNTS="${MOUNTS} -v $PROJECT_ROOT/coverage"
        MOUNTS="${MOUNTS} -v $PROJECT_ROOT/build/dist"
    fi

    # shellcheck disable=SC2086
    docker run --rm $OPTS -u="$CONT_USER" --name "$CONT_NAME" \
        $MOUNTS \
        -e CI="$CI" \
        -e DIFF_LINT="$DIFF_LINT" \
        -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-""}" \
        -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-""}" \
        -e AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-""}" \
        --network=host \
        "$CI_IMAGE_NAME" "$CMD" "$@"
}
