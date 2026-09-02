#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

exec swift run \
    --package-path "$prototype_dir" \
    FUMFunctionHierarchyProbe \
    "$@"
