#!/bin/sh
set -eu
prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$prototype_dir/../../Приложения/FUMA/сценарии/запустить-оператор.sh" "$@"
