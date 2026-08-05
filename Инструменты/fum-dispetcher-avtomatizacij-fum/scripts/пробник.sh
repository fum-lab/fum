#!/bin/sh
set -eu

python3 Инструменты/fum-dispetcher-avtomatizacij-fum/scripts/диспетчер-автоматизаций.py \
  проверить \
  --корень-рабочей-копии . \
  --реестр Планирование/реестры-заданий-автоматизаций/master.json \
  --схема Инструменты/fum-dispetcher-avtomatizacij-fum/схемы/реестр-заданий-v1.schema.json \
  --без-вывода

exec python3 Инструменты/fum-dispetcher-avtomatizacij-fum/scripts/диспетчер-автоматизаций.py \
  симулировать \
  --корень-рабочей-копии . \
  --реестр Инструменты/fum-dispetcher-avtomatizacij-fum/tests/фикстуры/корректный-реестр.json \
  --схема Инструменты/fum-dispetcher-avtomatizacij-fum/схемы/реестр-заданий-v1.schema.json \
  --наблюдения Инструменты/fum-dispetcher-avtomatizacij-fum/примеры/наблюдения-пробника.json \
  --json
