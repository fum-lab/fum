#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$#" -eq 0 ] || [ "$1" = "guide" ] || [ "$1" = "gui" ]; then
    if [ "$#" -gt 0 ]; then
        shift
    fi

    repository_root=$(CDPATH= cd -- "$prototype_dir/../.." && pwd)
    FUM_REPOSITORY_ROOT=$repository_root
    export FUM_REPOSITORY_ROOT

    exec swift run \
        --package-path "$prototype_dir" \
        FUMInputGuide \
        "$@"
fi

exec swift run \
    --package-path "$prototype_dir" \
    FUMInputProbe \
    "$@"
