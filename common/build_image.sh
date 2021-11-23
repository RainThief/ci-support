#!/usr/bin/env bash
set -eu

CI=${CI:-"false"}
SCAN=${SCAN:-"true"}
TAG="false"
INCREMENT="false"
GRYPE_SEVERITY=${GRYPE_SEVERITY:-"critical"}
USE_CACHE=${USE_CACHE:-"true"}
export USE_CACHE
DOCKERFILE=${DOCKERFILE:-"build/Dockerfile"}

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

usage() {
    echo ""
    echo "usage: $0 [-si]"
    echo "  -s | --scan         scan built image for vulnerabilities"
    echo "  -t | --tag          apply semver tag to image"
    echo "  -i | --increment    increment patch release for image tag; needs -t"
    echo ""
    echo "options required when using autogeneration of versions"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--scan)
        # @deprecated remove when all make files adjusted
        shift
        SCAN=true
        ;;
        -t|--tag)
        shift
        TAG=true
        ;;
        -i|--increment)
        shift
        INCREMENT=true
        ;;
        *)
        usage
        ;;
    esac
done

# shellcheck source=./common/docker.sh
source "$CI_SUPPORT_ROOT/common/docker.sh"

docker_login

# variant is to cache alternative docker file builds
VARIANT=${VARIANT:-""}
if [ "$VARIANT" != "" ]; then
    VARIANT="-$VARIANT"
fi
CACHE_IMAGE_NAME="$CI_IMAGE_NAME_BASE:${REPO_NAME}${VARIANT}"

if grep -i "as builder" "$DOCKERFILE"  > /dev/null && [ "$CI" == "true" ]; then
    STAGE_IMAGE_NAME="$CI_IMAGE_NAME_BASE:$REPO_NAME-builder$VARIANT"
    build_image_stage "$DOCKERFILE" "$STAGE_IMAGE_NAME" builder "$STAGE_IMAGE_NAME"
    build_image "$DOCKERFILE" "$CACHE_IMAGE_NAME" "$STAGE_IMAGE_NAME" "$CACHE_IMAGE_NAME"
else
    build_image "$DOCKERFILE" "$CACHE_IMAGE_NAME" "$CACHE_IMAGE_NAME"
fi

# @todo remove when grype available for the sad m1 users :(
if [ "$(uname -m)" == "arm64" ]; then SCAN=false; fi

if [ $SCAN == "true" ]; then
    echo_info "scanning image for vulnerabilties"
    OPTS="-it"

    # multiarch images will not be saved locally, pull to scan
    if [ "$ACTION" == "--push" ]; then
        docker pull "$CACHE_IMAGE_NAME"
    fi

    if [ "$CI" == "true" ]; then
        OPTS=""
    fi

    # shellcheck disable=SC2086
    docker run --rm \
        $OPTS \
        -v /var/run/docker.sock:/var/run/docker.sock \
        anchore/grype:v0.22 --fail-on "$GRYPE_SEVERITY" "$CACHE_IMAGE_NAME"
    exitonfail $? "vulnerabilities found in image $CACHE_IMAGE_NAME"

    echo_success "image scan passed"
fi

IMAGE_TAG="$(docker_branch_tag)"
docker tag "$CACHE_IMAGE_NAME" "$APP_IMAGE_NAME:$IMAGE_TAG"
echo_success "built image '$APP_IMAGE_NAME:$IMAGE_TAG' arch:$DOCKER_PLATFORM"

if [ "$CI" == "true" ]; then
    echo "::set-output name=GENERATED_IMAGE_NAME::$APP_IMAGE_NAME:$IMAGE_TAG"

    if [ "$IMAGE_TAG" == "latest" ] && [ "$TAG" == "true" ]; then

        # shellcheck source=./common/semver.sh
        source "$CI_SUPPORT_ROOT/common/semver.sh"

        if [ "$INCREMENT" == "true" ]; then
            RELEASE_TAG="$(get_tag "patch")"
        else
            RELEASE_TAG="$(get_tag "keep")"
        fi

        docker tag "$APP_IMAGE_NAME" "$APP_IMAGE_NAME:$RELEASE_TAG"
        docker push "$APP_IMAGE_NAME:$RELEASE_TAG"
        echo_success "released $APP_IMAGE_NAME:$RELEASE_TAG"
    fi

    docker push "$APP_IMAGE_NAME:$IMAGE_TAG"
fi
