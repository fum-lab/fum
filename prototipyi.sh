#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prototypes_dir="$repo_dir/Прототипы"

print_usage() {
    printf '%s\n' \
        "Использование: $0 [--list | номер [аргументы-прототипа...]]" \
        "" \
        "Без аргументов открывает панель запуска прототипов FUM." \
        "--list выводит пронумерованный список без запуска." \
        "Номер запускает выбранный прототип и передаёт ему остальные аргументы."
}

list_prototypes() {
    prototype_count=0

    for prototype_launcher in "$prototypes_dir"/*/запустить.sh; do
        [ -f "$prototype_launcher" ] || continue
        prototype_count=$((prototype_count + 1))
        prototype_dir=${prototype_launcher%/запустить.sh}
        prototype_name=${prototype_dir##*/}
        printf '%s) %s\n' "$prototype_count" "$prototype_name"
    done

    if [ "$prototype_count" -eq 0 ]; then
        printf '%s\n' "Не найдено ни одного прототипа с точкой входа запустить.sh." >&2
        return 1
    fi
}

select_launcher() {
    requested_number=$1
    selected_launcher=

    case $requested_number in
        ''|*[!0-9]*|0)
            return 1
            ;;
    esac

    prototype_number=0
    for prototype_launcher in "$prototypes_dir"/*/запустить.sh; do
        [ -f "$prototype_launcher" ] || continue
        prototype_number=$((prototype_number + 1))
        if [ "$prototype_number" -eq "$requested_number" ]; then
            selected_launcher=$prototype_launcher
            return 0
        fi
    done

    return 1
}

launch_number() {
    requested_number=$1
    shift

    if ! select_launcher "$requested_number"; then
        printf 'Нет прототипа с номером %s.\n' "$requested_number" >&2
        return 2
    fi
    if [ ! -x "$selected_launcher" ]; then
        printf 'Точка входа не исполняема: %s\n' "$selected_launcher" >&2
        return 2
    fi

    exec "$selected_launcher" "$@"
}

if [ "$#" -gt 0 ]; then
    case $1 in
        --help|-h)
            print_usage
            exit 0
            ;;
        --list)
            if [ "$#" -ne 1 ]; then
                printf '%s\n' "После --list не должно быть аргументов." >&2
                exit 2
            fi
            list_prototypes
            exit 0
            ;;
        -*)
            printf 'Неизвестный параметр: %s\n' "$1" >&2
            print_usage >&2
            exit 2
            ;;
        *)
            launch_number "$@"
            ;;
    esac
fi

printf '%s\n\n' "Панель запуска прототипов FUM"
list_prototypes
printf '%s\n' "q) Выйти"

while true; do
    printf '\n%s' "Введите номер прототипа: "
    if ! IFS= read -r requested_number; then
        printf '\n'
        exit 0
    fi

    case $requested_number in
        q|Q)
            exit 0
            ;;
    esac

    if select_launcher "$requested_number"; then
        if [ ! -x "$selected_launcher" ]; then
            printf 'Точка входа не исполняема: %s\n' "$selected_launcher" >&2
            continue
        fi
        exec "$selected_launcher"
    fi

    printf 'Нет прототипа с номером %s. Введите номер из списка или q.\n' \
        "$requested_number" >&2
done
