#!/bin/sh
set -eu

# Применение и NO_OP закрыты до проверки происхождения дерева и восстановления после прерывания.
printf '%s\n' 'ОТКАЗ: форматирование ещё не имеет проверенной границы применения и NO_OP' >&2
exit 2

root="$(git rev-parse --show-toplevel)"
cd "$root"
marker="fuma/manifest-path-format.v1.json"
paths="fuma/manifest-path-format.v1.paths"
version="fum.fuma.path-format.1"

if [ -f "$marker" ] && [ -f "$paths" ] && [ ! -e "Приложения/FUMA" ]; then
    {
        IFS= read -r saved_version || true
        if [ "$saved_version" = "$version" ] && grep -Fq "\"$version\"" "$marker"; then
            valid=1
            while IFS= read -r path; do
                [ -n "$path" ] || continue
                if [ ! -f "$path" ]; then valid=0; break; fi
            done
            if [ "$valid" -eq 1 ]; then
                printf 'NO_OP %s\n' "$version"
                exit 0
            fi
        fi
    } < "$paths"
fi

swift run --package-path "$root/fuma/format" --scratch-path "/tmp/fuma-path-format-v1" fuma-format --apply
