#!/usr/bin/env bash
set -u


CI_SUPPORT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/../"

# shellcheck source=./common/output.sh
source "$CI_SUPPORT_ROOT/common/output.sh"

# shellcheck source=./common/semver.sh
source "$CI_SUPPORT_ROOT/common/semver.sh"

# shellcheck source=./common/git.sh
source "$CI_SUPPORT_ROOT/common/git.sh"

set +e
is_main_branch
if [ $? -eq 1 ]; then
    echo_warning "not on main branch cannot release"
    exit 0
fi


if [ "$CI" == "true" ]; then

    RELEASE_TAG="$(get_tag "patch")"

    if [ "${CONVENTIONAL_COMMIT:=""}" == "true" ]; then

        if git log -n 1 | grep -E 'BREAKING CHANGE'; then
            RELEASE_TAG="$(get_tag "major")"
            echo_info "performing major release"
            return
        fi

        if git log -n 1 | grep -E 'fix\([[:alnum:]]+\):'; then
            RELEASE_TAG="$(get_tag "patch")"
            echo_info "performing patch release"
            return
        fi

        if git log -n 1 | grep -E 'feat\([[:alnum:]]+\):'; then
            RELEASE_TAG="$(get_tag "minor")"
            echo_info "performing minor release"
        fi
    fi

    git fetch "https://$GITHUB_TOKEN@$GIT_URL" --tags
    git tag "v$RELEASE_TAG"
    git push "https://$GITHUB_TOKEN@$GIT_URL" --tags
fi
