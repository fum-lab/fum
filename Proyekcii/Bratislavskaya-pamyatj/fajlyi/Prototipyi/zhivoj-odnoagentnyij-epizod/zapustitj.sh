#!/bin/sh

set -eu

prototype_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case "${1-}" in
  recorded|live)
    mode=$1
    shift
    if [ "$#" -gt 1 ]; then
      echo "Использование: $0 $mode [пустой-run-directory]." >&2
      exit 2
    fi

    temporary_run_dir=
    if [ "$#" -eq 0 ]; then
      temporary_run_dir=$(mktemp -d -t fum-live-episode)
      run_dir=$temporary_run_dir
      cleanup() {
        if [ -n "$temporary_run_dir" ] && [ -d "$temporary_run_dir" ]; then
          rm -rf -- "$temporary_run_dir"
        fi
      }
      trap cleanup 0
      trap 'exit 129' HUP
      trap 'exit 130' INT
      trap 'exit 143' TERM
    else
      run_dir=$1
      if [ ! -d "$run_dir" ]; then
        echo "Run directory должен заранее существовать как каталог: $run_dir" >&2
        exit 2
      fi
      first_entry=$(find "$run_dir" -mindepth 1 -maxdepth 1 -print -quit)
      if [ -n "$first_entry" ]; then
        echo "Run directory должен быть пустым: $run_dir" >&2
        exit 2
      fi
    fi

    swift run \
      --package-path "$prototype_dir" \
      FUMLiveEpisodeHarness \
      "$mode" \
      "$run_dir"
    exit $?
    ;;
esac

exec swift run \
  --package-path "$prototype_dir" \
  FUMLiveEpisodeProbe \
  "$@"
