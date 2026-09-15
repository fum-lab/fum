#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export SWIFTCI_USE_LOCAL_DEPS=1

exec swift run \
    --package-path "$prototype_dir/.." \
    FUMStructuringOperatorMemoryProbe \
    "$@"
