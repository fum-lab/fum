# Проверка привязки и восстановления

## Назначение

`проверка-восстановления.оператор.json` — чистое определение существующего FUMA `AutomationExecutor`, без нового Swift-пакета, диспетчера или файлового эффекта. Оно принимает descriptor агента вместе со свежими наблюдениями и возвращает решение по области записи, полноте восстановления из C, атрибуции инкарнации и повтору конкретного эффекта.

Область в примерах задана логическим ключом `arkhitektura/**`; абсолютные физические пути и секреты не входят в descriptor. Восстановление отдельно наблюдает локальные W и процесс, сравнивает полный ref, основу и cursor. В Git-снимке не требуется hash собственного будущего commit или полный transcript.

## Проверяемые инварианты

- Логический actor, parent, owner, grant, собственная память и полномочия совпадают.
- Общая память доступна только для чтения; текущему actor разрешена ровно одна собственная write-цель.
- Для собственного scope наблюдается ровно один активный writer; второй writer закрывает запись.
- Локальные branch/ref, worktree token, commit base и freshness cursor согласованы.
- Поле memory descriptor совпадает с own-memory actor; несовпадение закрывает и область записи, и восстановительную привязку.
- Пауза сохраняется. Неизвестный исход эффекта запрещает его повтор, но не восстановление памяти и не независимую работу.
- Источник/история/desired должны входить в commit C; чтение не зависит от собственного hash C и прошлого диалога.
- Отсутствие инкарнации оставляет атрибуцию неполной. Отсутствующие model runtime, API или секреты не объявляются доступными из Git и сами по себе не блокируют восстановление памяти.

Восстановительные поля `commit_contains_*` и сведения о внешней среде здесь являются typed input, а не самостоятельным доказательством Git-объекта. Вызывающая сторона должна прочитать C и выполнить fresh observe; текущий оператор не читает Git, не резервирует writer и не исполняет next action. Его 14 примеров передают агрегированный `observed`, а не два независимо свежих входа filesystem/Git; cross-source freshness остаётся отдельным конечным продолжением. Это проверяемый контракт-предложение, не массовая реализация восстановления, исполнительный адаптер или live-ready.

## Запуск

Из корня FUM укажи временный каталог сборки **вне checkout**:

```sh
: "${FUM_ARCH_BUILD_DIR:?укажите временный каталог вне checkout}"
swift run \
  --package-path 'Прототипы/память-структурирующих-операторов' \
  --scratch-path "$FUM_ARCH_BUILD_DIR" \
  FUMStructuringOperatorMemoryProbe исполнить \
  --определение arkhitektura/proverki/проверка-восстановления.оператор.json \
  --вход текст \
  < arkhitektura/proverki/примеры/положительный-синтетический.json
```

Команда возвращает FUMA observation; `результат.значение` — JSON решения оператора. Повторить для всех синтетических входов можно shell-циклом, подавая каждый файл `arkhitektura/proverki/примеры/*.json` на stdin. Не запускай сборку в исходном Package-каталоге: общий checkout read-only.

## Различающие примеры

| Вход | Логическая eligibility области записи | Память восстановима | Атрибуция полна | Следующее действие |
|---|---:|---:|---:|---|
| `положительный-синтетический` | да | да | да | продолжить desired |
| `дублирующий-писатель` | нет | да | да | новое наблюдение / эскалация |
| `чужой-грант` | нет | да | да | новое наблюдение / эскалация |
| `сдвинутая-база` | нет | да | да | новое наблюдение / эскалация |
| `неизвестный-эффект` | да для независимой работы | да | да | не повторять эффект |
| `устаревший-снимок` | нет | да | да | новое наблюдение / эскалация |
| `без-владельца` | нет | да | да | новое наблюдение / эскалация |
| `пауза` | нет | да | да | сохранить паузу |
| `без-памяти` | нет | нет | да | восстановление заблокировано |
| `чужая-область` (memory descriptor) | нет | нет | да | восстановление заблокировано |
| `неполный-коммит` / `без-исполнителя` | да | нет | да | восстановление заблокировано |
| `неизвестная-инкарнация` | да, только scope/grant | да | нет | RO-восстановление допустимо; эффект в прежнем W запрещён до fresh writer binding |
| `эффект-известно-неприменён` | да | да | да | сверить перед планом повтора |

Итоговый прогон: 14 synthetic JSON inputs; результат и индивидуальные хэши входа, определения и observation сохранены в `результаты-проверки-2.jsonl`. Все ожидаемые решения сверены отдельным `jq -se` утверждением. Первый прогон `результаты-проверки.jsonl` сохранён как происхождение, но superseded: в нём не сравнивался memory descriptor scope; исправленный v2-контрпример его ловит. Текущий граф использует лимит из 64 объявлений узлов существующего `ГрафJSON`; новые общие условия нельзя бесконечно добавлять к этому preflight.

Все входы синтетические. Положительный пример не утверждает фактическую инкарнацию или наличие внешнего runtime; в нём выбранные API-параметры и runtime report представлены раздельно, а API и секреты выключены. Prefix `371ceea4` используется только как переданный ROOT контрпример неизвестной атрибуции; эта проверка не устанавливает породивший его процесс.

Прямые поздние требования человека сохранены: «Nablyudeniye stejta fajlovoj sistemyi, nablyudeniye stejta gita.» и «Upravleniye stejtom budet ekvivalentno obnovleniyu stejta fajlovoj sistemyi i gita.» Они требуют отдельного finite слоя для источников наблюдения и исполнительного адаптера FS/Git; текущий preflight этого не заявляет.

## Независимое продолжение родителя и live writer binding

Первый restore-preflight решает свою ограниченную часть: typed eligibility scope/grant, память из C и запрет повтора неизвестного эффекта. Его поле `write_scope_eligible=true` не доказывает physical writer binding и не разрешает эффект в старом W. Опубликованные 14 исходов сохранены без изменений: `unknown-incarnation` по-прежнему даёт restoration-ready и неполную attribution, но write-effect при неизвестной live binding должен блокироваться следующим контрактом.

Контракт v1 `граница-независимого-продолжения.v1.оператор.json` и пять его запусков оставлены как происхождение в `результаты-независимого-продолжения.jsonl`. V2 в `граница-независимого-продолжения.оператор.json` разделяет `memory_recovery_ready`, `read_only_work_available`, `logical_write_scope_eligible`, `live_writer_binding` и `effect_allowed`. Проверка требует fresh binding `fresh-bound` для write-effect. Неизвестный binding позволяет продолжить независимое RO-действие, если память и read scope готовы, но запрещает запись в прежний W. Выбранная модель/API и runtime report сохраняются отдельно; неизвестный runtime не закрывает несвязанное действие, а блокирует только конкретное действие с `required_for_action=true`.

Критерий отсутствия общего ROOT-gate: при разрешённой собственной write-области, `live_binding.writer=fresh-bound`, `dependency=independent`, `requires_root_acceptance=false` родитель может продолжить локальный write-effect даже при pending peer acceptance. Если действие зависит от `peer-output`, оно ждёт приёмки непосредственного ребёнка родителем. ROOT ожидается только при явном `requires_root_acceptance=true`. Неизвестный dependency классифицируется, не подменяясь ожиданием ROOT.

| Вход v2 | Результат | Установленная граница |
|---|---|---|
| `продолжение-независимой-задачи-при-чужой-приёмке-v2` | `continue-independent-effect` | собственная привязка fresh; чужая приёмка не блокирует независимое действие |
| `зависимое-действие-до-приёмки-ребёнка-v2` | `await-direct-parent-acceptance` | ждёт только непосредственную приёмку |
| `зависимое-действие-после-приёмки-ребёнка-v2` | `continue-after-direct-parent-acceptance-effect` | parent acceptance достаточна для зависимости |
| `общая-интеграция-до-приёмки-root-v2` | `await-root-acceptance` | общая интеграционная граница принадлежит ROOT |
| `неизвестная-зависимость-сверху-v2` | `classify-dependency` | неизвестность зависимости не выдаётся за root gate |
| `неизвестная-привязка-писателя-ro-v2` | `continue-independent-read-only` | память и RO доступны, effect запрещён |
| `неизвестная-привязка-писателя-эффект-v2` | `observe-live-writer-binding` | restoration-ready не разрешает запись без свежей binding |
| `неизвестная-модель-по-нужна-действию-v2` | `await-required-model-runtime` | локальный blocker только для явно model-dependent действия; ROOT не требуется |

Восемь запусков существующего FUMA Probe и независимое `jq -s` утверждение дали все ожидаемые решения. V2 individual input, observation и FUMA semantic definition hashes сохранены в `результаты-независимого-продолжения-2.jsonl`. Это синтетическая проверка контракта; 39 App-узлов и фактическая маршрутизация не наблюдались этим агентом.

Для текущего continuation operator FUMA semantic definition digest равен `83e2e986fb932edbb66a45e915adbdcfbdae060f4b2cb5a217e3da6b4d0c2e6f`; raw JSON file SHA-256 — `003aba15a04d7ff684fbe82bef636dc8b84d0eac621ef7805c6830e8c34fa4c0`. Первые пять v1 исходов и определение оставлены отдельными файлами как происхождение.

## Различие FUMA semantic digest и raw file SHA-256

`результаты-проверки-2.jsonl` называет `428c354f...88d4` полем `definition_hash`: это SHA-256 канонического typed preimage, а не исходного файла. Для restore-preflight raw JSON SHA-256 равен `d72f18e907c0c42c5af721cb30464641f90b3ee4f3b3ed9edc8bce7c790f2557`; raw Git blob OID — `a7a8b5e4e492fc1e40fcc6cd178e9772ff720ac1`.

Существующая реализация в `Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/ИсполнениеОператоров.swift:430` считает SHA256 от `каноническиеДанные(определение.представление)`. `ОпределениеОператора.данные()` возвращает те же канонические bytes (`ОпределениеОператора.swift:187-195`); encoder задан в `ЗакрытыйРазбор.swift:203-206` как JSONEncoder с `.sortedKeys` и `.withoutEscapingSlashes`. Для старого определения typed preimage составляет 17,171 байт без добавленного LF и SHA-256 равен `428c354fb543f5ded1101944a6377ed5a05dc0f2b5c1c02d51a16a9d5cec88d4`. Поэтому исходные 14 outputs сохраняют корректный semantic digest; append-only correction уточняет его смысл, не переписывая результаты.

Воспроизводимый способ получить именно typed preimage использует существующий Swift package/module, без нового Package и без Python:

```sh
: "${FUM_ARCH_BUILD_DIR:?укажите временный каталог вне checkout}"
swift build \
  --package-path 'Прототипы/память-структурирующих-операторов' \
  --scratch-path "$FUM_ARCH_BUILD_DIR"
FUM_MODULE_DIR="$(swift build --show-bin-path \
  --package-path 'Прототипы/память-структурирующих-операторов' \
  --scratch-path "$FUM_ARCH_BUILD_DIR")"
cat > "$FUM_ARCH_BUILD_DIR/definition-preimage.swift" <<'SWIFT'
import Foundation
import FUMStructuringOperatorMemory
let raw = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let definition = try ОпределениеОператора.разобрать(raw)
FileHandle.standardOutput.write(try definition.данные())
SWIFT
swiftc -I "$FUM_MODULE_DIR" \
  "$FUM_ARCH_BUILD_DIR/definition-preimage.swift" \
  "$FUM_MODULE_DIR/FUMStructuringOperatorMemory.o" \
  -o "$FUM_ARCH_BUILD_DIR/definition-preimage"
"$FUM_ARCH_BUILD_DIR/definition-preimage" \
  arkhitektura/proverki/проверка-восстановления.оператор.json \
  > "$FUM_ARCH_BUILD_DIR/definition-preimage.json"
wc -c "$FUM_ARCH_BUILD_DIR/definition-preimage.json"
shasum -a 256 "$FUM_ARCH_BUILD_DIR/definition-preimage.json"
```

Для сравнения raw-file hash считай непосредственно на JSON-файле через `shasum -a 256`; не подменяй им `definition_hash` из FUMA observation.
