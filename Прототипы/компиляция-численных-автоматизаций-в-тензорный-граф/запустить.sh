#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case ${1-} in
    benchmark)
        shift
        exec swift run \
            -c release \
            --package-path "$prototype_dir" \
            FUMTensorGraphProbe \
            benchmark \
            "$@"
        ;;
    *)
        exec swift run \
            --package-path "$prototype_dir" \
            FUMTensorGraphProbe \
            "$@"
        ;;
esac
