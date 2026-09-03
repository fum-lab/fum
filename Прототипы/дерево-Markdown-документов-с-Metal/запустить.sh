#!/bin/sh
set -eu

if [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
    printf '%s\n' \
        "Использование: $0 [путь-к-репозиторию]" \
        "       $0 диагностика [путь-к-репозиторию]" \
        "" \
        "Открывает Metal-дерево Markdown-документов репозитория." \
        "Команда «диагностика» без GUI проверяет Metal и печатает JSON-отчёт."
    exit 0
fi

if [ "$#" -eq 0 ]; then
    set -- "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
elif [ "$1" = "диагностика" ] && [ "$#" -eq 1 ]; then
    set -- "диагностика" "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
fi

exec swift run \
    --package-path "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" \
    ДеревоДокументов \
    "$@"
