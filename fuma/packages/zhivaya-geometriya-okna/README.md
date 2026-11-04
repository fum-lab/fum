# Живой приём геометрии окна на FUMA

Две первичные программы FUMA порождают два Swift-файла одного приложения: [помощник состояния](определение-помощника.json) и [окно Metal](определение-окна.json). Помощник вызывает существующие определения [приёмника геометрии](../priyom-geometrii-okna/) и [планировщика кадра](../okno-metal/) внутри того же процесса. Нового интерпретатора, очереди, framework или первичного Swift-компонента нет.

[Корпус помощника](примеры-помощника.json) и [корпус окна](примеры-окна.json) сохраняют исходный EXPECTED_ONLY_NOT_RUN. Фактические исходы находятся отдельно: [генераторы и сборка](результаты-генераторов.json), [живой запуск](результаты-живого-приёма.json), [контракт](контракт.json).

## Полученный результат

Все12 FUMA-сценариев выполнены по одному разу и полностью совпали с ожиданиями: два полных Swift и десять диагностик без исходника, rawexit0/stderr0. Из ACTUAL результатов извлечены Helper.swift13457Б/SHA ab996b28fe84c3ac2aea7da82a980e1b5c6d2ed84a16cb941521a7eb9c2d1cb9 и main.swift19960Б/SHA52b8f2ffd7b51d5945a21d86ce879a2bbc67f6bbcb5e2942c5531d9fb57d084c. Оба целиком совпали с полными эталонами; ручных правок не было.

Одна совместная сборка Swift6/import/link с существующим object/module прошла rawexit0/stdout0/stderr0. Получен бинарник3263496Б/SHA736390c18e54d748052dc7dd71067f9ce71e4f20498a047cf134a98170bf12aa.

Один новый ограниченный запуск своего окна действительно завершился rawexit0/stderr0. В нём наблюдались14 записей: шесть native-событий, шесть фактических результатов приёмника и два плана. Начальное content320×240точек/scale2/поверхность640×480 сменилось на content400×300/поверхность800×600. Request размера сам не содержал observed-геометрии и не повысил редакцию; отдельный callback повысил её1→2. Закрытие дало редакцию3, next7, closedtrue, candidatefalse.

Каждое новое событие получило предыдущее ACTUAL состояние, а результаты приёмника полностью совпали с предварительным корпусом после единственной разрешённой подстановки нового собственного runtimeidentity. Все шесть native input-hash независимо восстановлены из фактического события и предыдущего состояния. Только ACTUAL DTO событий1 и4 передан планировщику:2457600/3840000байт, ресурсовВыделено0. Это новый живой in-process маршрут, отдельно от прежней offline обработки.

Независимая162 приняла весь конечный состав:54 оригинальных IO,12генераторных случаев, оба ACTUAL Swift, одну сборку/link и один живой14записный проход. Root проверил и принял finalv2 23883Б/SHA4fbd000070e23945fe1fad70e1b29d466c2a20d49b6d4f69d1195128fbe68fed. В первой версии исправлена ровно одна фактическая фраза: восстановленные входы были compactUTF8/noLF и ихSHA равен nativeinputdigest; это не превращает AFTERHost-файлы в runtimeinput или доказательство fsync до каждого события. Другие JSONзначения и прежний отчёт сохранены. Проверка Source/фактических данных и пути производителя не является независимым OS/driver/syscall-аудитом.

## Конечный профиль

AST fum.программа-живой-геометрии.1, версия1, профиль1. У помощника узел помощник-состояния, у окна — окно-геометрии-А. Программы принимают только точный закрытый объект; произвольные Swift-строки или пути в код не интерполируются. Каждая:141значение/глубина12/root0/barebool0 при неизменных пределах16/8192.

Единственный сценарий:320×240 → запрос400×300 через600ms → реальный resize callback → кооперативное закрытие2200ms. Поддерживается только scale2 и целочисленный конечный профиль существующего приёмника. Лишний callback, иная геометрия, дробь или неправильный порядок не переименовываются в успешный нормальный путь: новый рендер удерживается, сохраняется диагностика и выполняется конечное закрытие/exit.

Помощник @MainActor переносит именно сырой dictionary ACTUAL result.state до следующего события. Native-счётчик1..6 и счётчик всех выводов разделены. Свидетельство FUMA не становится новым native-событием и не потребляется рекурсивно. Только текущие identity/generation/revision, notclosed и свежий actualDTO допускают вызов планировщика. Его результат сравнивается с тем же current snapshot после вычисления.

Перед drawable/после drawable/передpresent окно проверяет полный снимок. Логический pendingcandidate гасится доpresent/commit. Это локальный путь управления; успешное API-предъявление не подтверждает физическую однократность или видимый пиксель.

## Воспроизведение

Нужны [существующий bootstrap](../../../Прототипы/память-структурирующих-операторов/README.md), совместимые Swift6/macOS SDK и object/module библиотеки FUMStructuringOperatorMemory. Фактический build использовал сохранённые артефакты build110; чистый клон/иная ABI не квалифицированы этим запуском. Временные исходники, кэш и бинарник находятся в собственном частном каталоге вне Git.

Caller заранее выбирает и закрепляет fum_bootstrap, fum_private, fum_swiftc, fum_sdk, fum_product_dir. Создаёт tmp/module-cache внутри fum_private. Получает ACTUAL цели генерации и сравнивает каждый полный JSON результат с предварительным ожиданием:

```sh
jq -c '.случаи[0].вход' fuma/packages/zhivaya-geometriya-okna/примеры-помощника.json > "$fum_private/helper.input.json"
"$fum_bootstrap" исполнить --определение fuma/packages/zhivaya-geometriya-okna/определение-помощника.json --вход текст < "$fum_private/helper.input.json" > "$fum_private/helper.observation.json"
jq -e -j 'if .схема == "fum.наблюдение-оператора.2" and .результат.тип == "текст" then (.результат.значение | fromjson | .исходник) else error("Неверное наблюдение") end' "$fum_private/helper.observation.json" > "$fum_private/Helper.swift"
jq -c '.случаи[0].вход' fuma/packages/zhivaya-geometriya-okna/примеры-окна.json > "$fum_private/window.input.json"
"$fum_bootstrap" исполнить --определение fuma/packages/zhivaya-geometriya-okna/определение-окна.json --вход текст < "$fum_private/window.input.json" > "$fum_private/window.observation.json"
jq -e -j 'if .схема == "fum.наблюдение-оператора.2" and .результат.тип == "текст" then (.результат.значение | fromjson | .исходник) else error("Неверное наблюдение") end' "$fum_private/window.observation.json" > "$fum_private/main.swift"
```

Точная проверенная форма общей сборки:

```sh
TMPDIR="$fum_private/tmp" CLANG_MODULE_CACHE_PATH="$fum_private/module-cache" "$fum_swiftc" -swift-version 6 -parse-as-library -module-name FUMALiveGeometryAdapter -module-cache-path "$fum_private/module-cache" -sdk "$fum_sdk" -I "$fum_product_dir" "$fum_private/Helper.swift" "$fum_private/main.swift" "$fum_product_dir/FUMStructuringOperatorMemory.o" -framework Foundation -framework AppKit -framework Metal -framework QuartzCore -o "$fum_private/FUMALiveGeometryAdapter"
```

У приложения ровно три абсолютных аргумента: текущая красная .metallib из FUMA→MSL, определение приёмника, определение планировщика. RuntimecompileMSL, offscreenpixel, CGWindowlist и screenshot не вызываются. Перед своим конкретным запуском caller отдельно проверяет SHA/regular/nofollow/owner/физические пути и текущий effectscope:

```sh
"$fum_private/FUMALiveGeometryAdapter" "$fum_red_metallib" "$fum_repo/fuma/packages/priyom-geometrii-okna/определение.json" "$fum_repo/fuma/packages/okno-metal/определение.json"
```

Эта форма команды — инструкция воспроизведения, не grant из входных данных. Фактические проверки запускаются через существующую отчётную обёртку с внешними deadline120с дляbuild и15с дляonewindowjob/отдельной группой процессов и boundedcleanup. jobs1 обозначает один внешний вызов; внутренний параллелизм Swift-driver/потоков не измерялся и отдельно не ограничивался. Bytecaps/jobs1 не являются RSS/network/GPUmemory ограничителем. Синхронная FUMA на mainActor может задержать UI/таймеры; время<3с не заявлено.

## Свидетельства и граница

Native-схема fum.сигнал-геометрии-окна.1 сохраняет только фактические свойства своего окна. Отдельные свидетельства fum.свидетельство-живого-приёма-геометрии.1 и fum.свидетельство-живого-плана-геометрии.1 содержат ACTUAL state/DTO/полный результат/хэши. Предельный вывод32записи, каждая≤16384Б; фактически14записей/16059Б, максимум1742Б в строке. Частные UUID/windowNumber/framepositions/wholetrace не публикуются, windowNumber processlocal и не globalcapturebinding.

Statecarry хранится внутри процесса перед следующим событием. Частные восстановленные входы и ожидаемые результаты создавались ПОСЛЕ Host для проверки содержимого и не выдаются за файлы, использованные runtime, либо fsync до каждого события.

Все presentationConfirmed осталисьfalse. Планы не являются разрешением выделения; ресурсовВыделено0 — поле планировщика, не аудит nativeheap/GPUmemory. GPUcompletion, видимые пиксели окна, общий float/scale/generationprofile, полный AOT/selfhosting и NativeStop не доказаны. Страховка остаётся активной.

[Текущий Журнал](../../../Журнал/2026-11-04_07-54-03_MSK_проверить-живой-приём-геометрии-на-FUMA/запрос.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-11-04 08:24:30 MSK -->
<!-- content-sha256: sha256:aa4bab18e0881f8215ea22f260fba24cc0a9bd81ee83ac05db745eb89a7c08b9 -->
<!-- FUM-MD-RECENCY:END -->
