# Сохранённая последовательность выделения переноса Issues

Эта последовательность создаёт узкую source-ветку от ROOT `4a2375a4dcbe1495b5afe520185795a00acaff9b`. Она берёт содержимое из проверенного source Q `5f4bd1dc0207db975ee7f4d11106c56ec5a6e05b`, но Q не становится родителем partial-source. Старые опубликованные `444f7342862d6371d5a020f27ae20fca8dad9fd7`, `50e30ff3f050995904cd211df1b97e5b16637826` и их ref не переписываются.

## Закрытые входы и область

- ROOT M: `4a2375a4dcbe1495b5afe520185795a00acaff9b`.
- Source Q: `5f4bd1dc0207db975ee7f4d11106c56ec5a6e05b`, parent `c4ef8e7ccbbc53e3916494954dc908ad7406dc5e`, tree `cde9e0e2246bd5a3b5a8f08793f482f44d6a6962`.
- `4a:Issues`, `8b23:ishjyusyi`, `Q:ishjyusyi` обязаны иметь один tree OID `8684ce2dc5e8ce699f6e2e5626b83549118b2edf`.
- Разрешённая дельта: перенос всего `Issues/` в `ishjyusyi/` (527 одинаковых blobs/modes); `README.md`; `Инструменты/fum-materialyi-zaprosov/SKILL.md`; `Инструменты/fum-materialyi-zaprosov/внимание-к-обсуждениям-GitHub.md`; `Журнал/2026-11-01_14-02-15_MSK_пилот-переноса-памяти-Issues/{запрос.md,отчёт.md}`.
- STOP implementation/result, `iskhodniki/aktualizaciya-putej/rukovodstvo.md` и любые остальные Q-изменения запрещены в partial-source дереве. Q остаётся только provenance.

## Воспроизводимый порядок

Запускать из чистого собственного worktree на ref `fum-lab/fum/integraciya/master`, после readback `HEAD=50e30ff3f050995904cd211df1b97e5b16637826`. Один писатель. Убедиться, что refs `fum-lab/fum/integraciya/partial-issues/master` и `fum-lab/fum/integraciya/candidate-issues/master` свободны.

1. Создать отдельную partial-source ветку от точного M:

   ```sh
   git switch -c fum-lab/fum/integraciya/partial-issues/master 4a2375a4dcbe1495b5afe520185795a00acaff9b
   test "$(git rev-parse HEAD)" = 4a2375a4dcbe1495b5afe520185795a00acaff9b
   test "$(git rev-parse 4a2375a4dcbe1495b5afe520185795a00acaff9b:Issues)" = 8684ce2dc5e8ce699f6e2e5626b83549118b2edf
   test "$(git rev-parse 5f4bd1dc0207db975ee7f4d11106c56ec5a6e05b:ishjyusyi)" = 8684ce2dc5e8ce699f6e2e5626b83549118b2edf
   ```

2. Переместить каталог локальным rename (сохраняет физические байты) и выбрать только прямые ссылки и исходные записи:

   ```sh
   git mv Issues ishjyusyi
   git restore --source=5f4bd1dc0207db975ee7f4d11106c56ec5a6e05b --staged --worktree -- README.md Инструменты/fum-materialyi-zaprosov/SKILL.md Инструменты/fum-materialyi-zaprosov/внимание-к-обсуждениям-GitHub.md 'Журнал/2026-11-01_14-02-15_MSK_пилот-переноса-памяти-Issues/запрос.md' 'Журнал/2026-11-01_14-02-15_MSK_пилот-переноса-памяти-Issues/отчёт.md'
   ```

3. Закрыть staged boundary до коммита: ровно 527 `R100`, 3 `M`, 2 `A`; source/target archive OID равен `8684ce2d…`; целевые root/skill/journal blobs равны blobs Q; нет STOP, другого руководства, дополнительных или unstaged изменений. `git diff --cached --check` должен быть пуст. Получить tree `T` через `git write-tree`, проверить `git rev-parse T:ishjyusyi` и состав diff.
4. Создать обычный commit `partialC` на этой ветке. Проверить raw: единственный parent `4a2375a4dcbe1495b5afe520185795a00acaff9b`; source Q не parent/ancestor; exact diff соответствует allowlist. Автор и committer — наблюдаемые и явно проверенные; без изменения общей Git-конфигурации.
5. Отдельный candidate ref создать от опубликованного Rules C `444f7342862d6371d5a020f27ae20fca8dad9fd7`, затем `git merge --no-ff --no-commit partialC`. Проверить staged tree и точные родители до commit; кандидатный merge обязан иметь parents `[444f734…, partialC]`, не Q и не `50e30ff…`.
6. Зафиксировать candidate C только после проверки exact diff/index/автора. Обычный exact push каждого собственного ref в единственный проверенный `origin`; отдельно подтвердить оба OID через `git ls-remote`. ROOT acceptance, runtime и production из этих шагов не следуют.

Доказанная отрицательная граница: полный Q имеет дополнительные изменения STOP и руководства. Их исключение из дерева не исключает их из ancestry Q, поэтому Q не допускается как второй parent partial-source.
