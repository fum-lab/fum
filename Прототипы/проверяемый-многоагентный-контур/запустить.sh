#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$#" -eq 2 ] && [ "$1" = "acceptance" ] && [ "$2" = "all" ]; then
    repository_root=$(CDPATH= cd -- "$prototype_dir/../.." && pwd)
    set -- "$@" --repo-root "$repository_root"
fi

exec swift run \
    --package-path "$prototype_dir" \
    FUMWorkPackageProbe \
    "$@"
