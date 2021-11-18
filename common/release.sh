#!/usr/bin/env bash
set -eu

CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/semver.sh
source "$CI_SUPPORT_ROOT/common/semver.sh"

RELEASE_TAG="$(get_tag "patch")"

if [ "$CI" == "true" ]; then
    git fetch "https://$GITHUB_TOKEN@$GIT_URL" --tags
    git tag "v$RELEASE_TAG"
    git push "https://$GITHUB_TOKEN@$GIT_URL" --tags
fi
