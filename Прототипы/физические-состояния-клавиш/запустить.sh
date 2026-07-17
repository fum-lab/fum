#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$#" -eq 0 ]; then
    set -- matrix
fi

exec swift run \
    --package-path "$prototype_dir" \
    FUMInputProbe \
    "$@"
