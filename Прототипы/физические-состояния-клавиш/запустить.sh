#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$#" -eq 0 ] || [ "$1" = "guide" ] || [ "$1" = "gui" ]; then
    if [ "$#" -gt 0 ]; then
        shift
    fi

    exec swift run \
        --package-path "$prototype_dir" \
        FUMInputGuide \
        "$@"
fi

exec swift run \
    --package-path "$prototype_dir" \
    FUMInputProbe \
    "$@"
