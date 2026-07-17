#!/bin/sh
set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
    printf '%s\n' \
        "Использование: $0 [путь-к-текстовому-файлу]" \
        "" \
        "Запускает графический теневой редактор продолжений." \
        "Имя установленной модели задаётся в интерфейсе или через FUM_LLM_MODEL."
    exit 0
fi

exec swift run \
    --package-path "$prototype_dir" \
    FUMShadowEditor \
    "$@"
