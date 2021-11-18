#!/bin/bash

set -euo pipefail

get_tag() {
    TAG=$(git tag | sort -V | tail -1)
    if [ "$TAG" == "" ]; then
        TAG="v0.0.0"
    fi

    # strip preceeding "v" from tag
    TAG="${TAG/v/}"

    # get tag parts disable check to quote
    # shellcheck disable=SC2206
    TAG_BITS=(${TAG//./ })
    VNUM1="${TAG_BITS[0]}"
    VNUM2="${TAG_BITS[1]}"
    VNUM3="${TAG_BITS[2]}"

    # empty args do patch
    if [ "$#" = "0" ]; then
        VNUM3="$((VNUM3+1))"
    fi

    while [[ "$#" -gt 0 ]]
    do
        key="$1"

        # bump version type based on arg passed
        case $key in
            patch)
            VNUM3=$((VNUM3+1))
            shift
            ;;
            minor)
            VNUM2=$((VNUM2+1))
            VNUM3=0
            shift
            ;;
            major)
            VNUM1=$((VNUM1+1))
            VNUM2=0
            VNUM3=0
            shift
            ;;
            # do not bump version
            keep)
            shift
            ;;
            *)
            VNUM3=$((VNUM3+1))
            shift
            ;;
        esac
    done

    echo "$VNUM1.$VNUM2.$VNUM3"
}
