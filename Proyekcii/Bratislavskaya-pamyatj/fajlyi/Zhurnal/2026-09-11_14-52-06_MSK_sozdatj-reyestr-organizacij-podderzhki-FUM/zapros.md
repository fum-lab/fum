# Iskhodnyij zapros 2026-09-11 14:52:06 MSK - Sozdatj reyestr organizacij podderzhki FUM

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-09-11 13:39:59 MSK - Prinyatj napravleniye finansirovaniya FUM](../2026-09-11_13-39-59_MSK_prinyatj-napravleniye-finansirovaniya-FUM/zapros.md)
- Sleduyusjhij zapros: [2026-09-11 16:12:17 MSK - Zavershitj priyomku reyestra podderzhki FUM](../2026-09-11_16-12-17_MSK_zavershitj-priyomku-reyestra-podderzhki-FUM/zapros.md)

## Tekst zaprosa

````text
Переданное поручение задачи 01a08d77-2060-7701-9f44-ff04769d8a6e:

Реализуй первый конечный результат нового направления привлечения финансирования и ресурсов для развития FUM: воспроизводимую автоматизацию ведения, обновления и проверки реестра подходящих организаций и формирования понятных списков, затем выпусти заполненный первый проверенный реестр. Работай по сохранённой карточке постановки и требованию финансирования-и-ресурсов-развития-FUM. География — Россия; некоммерческая ориентация подтверждена, зарегистрированная НКО и юридическая форма не подтверждены.

Исходный набор уже сохранён в Журнал/2026-09-11_13-39-59_MSK_принять-направление-финансирования-FUM/материалы/исследования/организации-поддержки-FUM.json: два исследования от 11.09.2026, 9 и 7 организаций. Прими все 16 записей с исходным авторством, датами и ограничениями; не приписывай себе новое чтение страниц исследователей. Используй готовый поиск и адресно сверяй актуальность, неоднозначности и пробелы. Для каждого исходного кандидата сохрани исход — подходит для конкретного следующего шага, условный, недоступный или требует уточнения — с доказательством; неизвестное не превращается в положительный допуск. Сохрани уже замеченные ограничения Яндекса, VK, расходов Selectel и лицензий SSWG.

Реестр различает фонды и грантодателей, пожертвования и спонсорство, вычислительные и материальные ресурсы, научно-образовательных и технологических партнёров; деньги, кредиты, скидки и техническое сотрудничество не смешиваются. Для каждой записи нужны устойчивый ID, официальный источник и дата проверки, конкретная взаимная польза, вид поддержки, требования к заявителю и применимость к России, известные ограничения и unknown, проверенные сроки/условия, следующий минимальный шаг. Истёкший срок, тематическая близость и факт существования организации не дают статус доступной программы. Правило устаревания должно быть явным и воспроизводимым по заданной дате.

Используй существующие источниковые и шаблонные механизмы репозитория. Новый код вводи только для недостающего повторяемого процесса с адресным TDD, воспроизводимым профилем и решением об оптимизации. Сохрани обычные отслеживаемые исходники, данные, открытые фикстуры, команды воспроизведения и понятный интерфейс запуска в тематических каталогах монорепозитория. Сформируй первый читаемый список автоматизацией и проверь повтор из сохранённых данных, дубли, происхождение, неизвестные и истёкшие условия. Для финансовых и правовых условий опирайся на официальные актуальные источники; факт регистрации НКО не выдумывай.

Полученный реестр не означает полученного финансирования. Внешние письма, обращения, регистрации, подачи заявок, платежи и изменение лицензии не разрешены. Можно подготовить конкретные материалы для дальнейшего явного решения человека. Первым сообщением подтверди точную начальную базу, физический корень, полный ref, свой native UUID и фактическую модель; раннюю проверку базы выполни по добавленной адаптером команде до первой записи. Пиши только в своём дереве. Тяжёлый полный smoke согласуй с координатором 01a07d3d-d376-7ad2-aafc-67e4c25a67eb: после текущей интеграции приоритет имеет benchmark; адресные проверки доступны. Модель выбрана gpt-6-astra, ultra. Сохраняй содержательные этапы своими проверенными коммитами с обычным точным push и передай конечные OID, реестр, проверки, профиль и ограничения координатору и задаче приёма 01a08d77-2060-7701-9f44-ff04769d8a6e.

Источник постановки: Журнал/2026-09-11_13-39-59_MSK_принять-направление-финансирования-FUM/запрос.md; точный коммит 73c52866e565061b48ee67e164d5d178c5c8d8cd.
Приём направления: c39b9a1346ae7468d4b0f154ecaafa95de1f39c1297aa1f7c0552588061689de. Объём: реализация.
До первой записи в checkout после чтения маршрута проверь собственные HEAD, полный ref и физический корень. Вызови сохранённую в этом коммите команду Инструменты/fum-reyestr-planirovaniya/scripts/принять-направление.py с общими --корень-репозитория и --задача, затем подтвердить-начало с --источник собственного первичного JSONL и --коммит 73c52866e565061b48ee67e164d5d178c5c8d8cd. При несовпадении останови запись и сообщи фактические значения. После раннего подтверждения выполни поручение в своём worktree, проверь результат и сохрани полезный коммит. Планирование направления само по себе не разрешает предметную реализацию.

````

````text
Переданное поручение задачи 01a08d77-2060-7701-9f44-ff04769d8a6e:

Начальная база 73c52866e565061b48ee67e164d5d178c5c8d8cd совпадает, native detached worktree допустимо перевести в собственную новую ветку как обычную подготовку этой уже созданной задачи. Создай в своём /Users/fum/.codex/worktrees/3cd3/FUM новую уникальную ветку refs/heads/codex/реестр-организаций-поддержки-01a0904a от текущего точного73c, предварительно убедившись, что этого ref нет и дерево чистое. Это снимает остановку только из-за detached HEAD; повторное создание задачи и изменение базы не нужны. Сразу повтори штатный подтвердить-начало с собственным исходным JSONL и тем же OID до содержательной записи checkout. Передай результат команды, точные ref/HEAD/физический корень и путь собственного первичного JSONL для моего штатного наблюдать. После успешного раннего подтверждения продолжай исходный конечный объём. Запрошенные модель/режим сохраняются gpt-6-astra/ultra.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Координатор получил раннее доказательство точного73c52866 и своей3cd3, Astra/ultra. Detached HEAD — наблюдаемое начальное состояние штатно создаваемого native worktree, само по себе не требует нового разрешения пользователя или восстановления чужого ref. Сначала сохрани фактический исход обязательного подтвердить-начало до записи и согласуй его с владельцем0201; если ранний допуск успешен и исключён второй писатель, создай свою новую свободную codex/... ветку от этого же неизменного OID обычным способом, не меняя исходную ветку постановки. При конкретном машинном отказе передай точный текст и продолжай независимое чтение, не обходя его. Тяжёлое окно сейчас уже у Linux VM01a08fe2-d0c2-7ef3-b980-6bb5f8edbe97, benchmark завершён и доставлен c7cd5d33; старый порядок из исторической постановки не актуален. Согласуй со мной первый тяжёлый запуск, лёгкие адресные проверки допустимы. Финансовые внешние обращения не входят в эту задачу.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Уточнение после чтения точного кода73c: постановка_задачи.py:112 требует раннее подтверждение до первой записи файлов checkout, но наблюдать:81 вызывает _наблюдать_владельца и тем самым уже требует symbolic ref. Само исходное нативное доказательство сверяет commit_hash, а не первоначальное имя ветки. Значит нормальная последовательность здесь: сохранить наблюдённый отказ на detached; исключить чужого писателя; создать свою свободную codex/... ветку от неизменного73c52866 без изменения файлов/индекса; сразу подтвердить-начало на всё ещё чистом дереве и том же исходном JSONL; затем запись Журнала. Это не обход проверки и не перезапись чужого ref. Моя предыдущая условная фраза «если ранний допуск успешен, создай ветку» задавала неверный порядок для текущей реализации — заменена этой последовательностью. Новый код или новый автомат перехода для этого не нужен. При конкретном следующем отказе сохрани его и сообщи.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Для координации общей диагностики есть ли у тебя неопубликованное/зарезервированное проявление FUM-СБОЙ-0059? 0201 ждёт следующий согласованный номер для собственного отказа correction; корень сверяет занятость. Не назначай локальный номер по своему максимуму. Это короткая сверка, текущую работу продолжай.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Получил16 организаций/23 варианта, GREEN10 и измерения. Сейчас тяжёлое окно уже передано подготовке master01a09047; VM временно ведёт только лёгкую диагностику/код. После master ранее обещан возврат VM для завершения подготовки гостя. Твой стандартный smoke поставлен следующим после освобождения этих согласованных операций, отдельное подтверждение пришлю. Пока закончи точность Потанина, интерфейс, RO и checkpoint+push с открытым отчётом и явным остатком, если финальная каноническая часть готова; ожидание окна не повод терять проверенный промежуточный результат. Широкий --профиль полный не нужен. Максимум6.99мс помечай границей конкретного профиля и не сравнивай с общими сетевыми/проверочными затратами.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Короткая сверка составного ID: есть ли у тебя неопубликованное или зарезервированное проявление FUM-СБОЙ-0043? 0201 сохраняет свой эпизод незавершённого apply одновременно с зависимым build. RO по52worktree/128refs нашёл только0001; прежде резерва0002 корень исключает частные резервы действующих писателей. Ответь кратко и продолжай свою работу, дополнительной проверки/остановки не требуется.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Запрос резерва уже передан владельцу распределителя0201 (01a08d77-2060-7701-9f44-ff04769d8a6e) с точными границами и запретом выводить значения. Он согласует номера и передаст их; не выполняй повторное выделение. Содержательную очистку и адресные проверки продолжай. Четыре границы обновления/сроков принимай только по конкретным воспроизведениям. Тяжёлое окно остаётся после M, затем Linux VM.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Обновление очередности: тяжёлое окно передано Linux VM, пока M делает лёгкое необходимое расширение Git-читателя на новый формат закрытого отчёта. Твой standard full следующий после фактического окончания гостевого этапа. До этого продолжай адресные проверки, чистый checkpoint и документацию; повторного разрешения на уже согласованную работу не нужно.
````

````text
Переданное поручение задачи 01a08d77-2060-7701-9f44-ff04769d8a6e:

Общий распределитель долговечно выделил для твоего существующего объёма 0212: FUM-СБОЙ-0081 — архив HTML сохраняет служебные данные запроса, событие 8af3d0eb76a5a87e1ad2ba1704885cb3c8244849a1c50373a7ed5fa8d757fee6; FUM-СБОЙ-0082 — повтор родительского URL удаляет самостоятельный вложенный снимок, событие 4bedf74f8260a4ec018ac4e598c060c4a4f475fb83b7fe4d291873b203dda0f0. Карточки и точные доказательства пишешь только в своём дереве, новые STEP не выделены. Для X-Trace-Id/X-SP-CRID механизм существующей CF-Ray/0020 подходит; история и 40 деревьев содержат только 0001–0002. Согласование отсутствия чужого приватного резерва 0020/0003 ещё идёт у координатора; до подтверждения не записывай локальный номер. CSRF и диагностический IP относить к 0081 только в части фактически находящейся в HTML; чувствительные значения в переписку и карточки не копировать. Устранение пока требует твоих проверок; моя выдача не является приёмкой исправлений.
````

````text
Переданное поручение задачи 01a08d77-2060-7701-9f44-ff04769d8a6e:

Локальный резерв подтверждён: FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0003 для X-Trace-Id/X-SP-CRID в HTTP-заголовках. Точная карточка: Сбои/FUM-СБОЙ-0020-публикация-служебного-CF-Ray-в-снимке-источника.md. История и 40 деревьев проверены; координатор получил отсутствие частных резервов от M, Linux и своего корня, ты номера не назначал. Согласование долговечно сохранено отдельно: глобальное хранилище выдаёт только STEP/REQ/СБОЙ и не имеет API локальных проявлений. Записывай 0003 в своём дереве, сохрани 0001–0002 и прежнее ограниченное доказательство; новое проявление возвращает активную диагностику с актуальным шагом. HTML и вложенные URL остаются отдельными 0081/0082.
````

````text
Переданное поручение задачи 01a08d77-2060-7701-9f44-ff04769d8a6e:

RO не нашёл равной карточки в доступных worktrees и 61 вершине refs. Выданы две точные границы в существующий STEP 0212: FUM-СБОЙ-0083 — пропуск распаковки HTTP gzip перед декодированием HTML, событие 907de935373a35df5c41c76db6954f04260eaa1eac58323330a131ff3614d429; FUM-СБОЙ-0084 — пропуск проверки формата PDF перед HTML-извлечением, событие 6d4d6d6c335e9381e8f75a982914c08e32befb769e73e659f1a7579bd4252b97. Распаковка не предотвращает HTML-разбор PDF; отказ PDF не исправляет сжатый HTML — независимые меры и регрессионные границы. Свяжи их сценарием сжатого PDF, сохрани исходные RED и принадлежность одному этапу без новой широкой задачи. Резервы долговечны; 9 PDF/26 HTML/GREEN53 пока отмечены как твои сведения, а не моя приёмка.
````

````text
Переданное поручение задачи 01a07d3d-d376-7ad2-aafc-67e4c25a67eb:

Пакет M уже полностью подготовил вход нового v3-этапа и ждёт только тяжёлое окно. Linux ещё завершает профиль повтора. Сохраняю обещанный следующий слот для твоего полного прогона, если к моменту освобождения VM твоя подготовка будет завершена. Сообщи фактическую готовность входа и оставшиеся адресные исправления; если они ещё идут, свободное окно передадим готовому M, а затем тебе. Это координация исполнения, повторного разрешения на работу не требуется.
````

## Identifikator seansa Codex

Codex-Thread-ID: 01a0904a-f98e-70b1-8ea6-a0202ff4de7a

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md).
- Prilozheniye Codex Desktop — otdeljnaya versiya ne zaprashivalasj; aktivnyij vstroyennyij runtime Codex CLI 0.153.4 podtverzhdyon pervichnyim JSONL. Samostoyateljnyij Codex CLI ne zapuskalsya. Aktivnaya modelj gpt-6-astra, rezhim ultra podtverzhdenyi turn_context; docherniye RO-ispolniteli nasledovali modelj.
- `functions.exec`, `exec_command`, `apply_patch`, `write_stdin`, `clock.curr_time`, `web.run`, `collaboration` i Codex app `send_message_to_thread`, `wait_threads`, `load_workspace_dependencies` — kontraktyi tekusjhej sredyi, samostoyateljnyiye versii ne raskryityi. Ispoljzovanyi chteniye oficialjnyikh istochnikov, lokaljnaya rabota i razreshyonnaya koordinaciya zadach.
- Python 3.14.7; Git 2.54.0 (Apple Git-157); curl 8.7.1; pypdf 6.10.0 iz bundled runtime. Dlya vosproizvedeniya samogo reyestra dostatochno standartnoj biblioteki Python.
- `fum-moskovskoye-vremya-rabochej-sessii` — kanonicheskaya para vremeni 2026-09-11_14-52-06_MSK / 2026-09-11 14:52:06 MSK.
- Lokaljnyiye `fum-dekompoziciya-pravil-agentov`, `fum-struktura-papok-zaprosov`, `fum-materialyi-zaprosov`, `fum-reyestr-planirovaniya`, `fum-otchyotyi-o-zapuskakh-proverok`, `fum-svyaznostj-rabochej-sessii`, `fum-svezhestj-markdown`, `fum-proverka-git-zavisimostej` — versii zadayutsya bazoj 73c52866e565061b48ee67e164d5d178c5c8d8cd i tochnyim diff etapa. Pereispoljzovanyi shablonnyij mekhanizm, normalizaciya putej, atomarnaya zapisj i profilj `fum-snimki-indeksa`.

## Proverki

- Vse pryamyiye testyi i profili zapisanyi [mashinnoj obyortkoj](materialyi/zapuski-proverok/) i otrazhenyi v [otchyote](otchyot.md). Ozhidayemyiye RED i realjnyiye promezhutochnyiye otkazyi sokhranenyi, ne zamenenyi uspekhom.
- Adresnyij nabor reyestra: 15 testov. Istochnikovyij nabor: 53 testa. Povtor iz sokhranyonnyikh dannyikh prokhodit bez seti. Sostav i datyi uslovij sveryali otdeljnyiye RO-ispolniteli.
- Pered kontroljnoj tochkoj vyipolnyayutsya tochnaya sverka diff/indeksa, recency i read-only dopusk svyaznosti; finaljnyij standartnyij smoke yesjhyo ozhidayet soglasovannogo resursnogo okna.

## Povliyal na fajlyi

- [Tekusjhij zapros](zapros.md), [otchyot](otchyot.md) i [materialyi](materialyi/).
- [Navigaciya Zhurnala](../README.md) i [predyidusjhij zapros](../2026-09-11_13-39-59_MSK_prinyatj-napravleniye-finansirovaniya-FUM/zapros.md) — toljko navigacionnaya obratnaya ssyilka.
- [Reyestr podderzhki](../../Planirovaniye/finansirovaniye-i-resursyi/), [avtomatizaciya planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/) i [avtomatizaciya istochnikov](../../Instrumentyi/fum-materialyi-zaprosov/).
- [Obsjhij perechenj instrumentov](../../Instrumentyi/README.md), [planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json), [kartochki shagov](../../Planirovaniye/kartochki-shagov/).
- [Snimki oficialjnyikh istochnikov](../../Istochniki/URL/https/) — novyiye materialyi dannoj zadachi.
- [Kartochki sboyev i indeks](../../Sboi/), [indeks Markdown-recency](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md).

## Prikreplyayemyiye materialyi

- [Istochnik: ITMO Opensource](../../Istochniki/URL/https/opensource.itmo.ru/_root/)
- [Indeks istochnika](../../Istochniki/URL/https/opensource.itmo.ru/_root/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/opensource.itmo.ru/_root/extraction-report.md)
- [Istochnik: Institut sistemnogo programmirovaniya im. V.P. Ivannikova RAN](../../Istochniki/URL/https/www.ispras.ru/_root/)
- [Indeks istochnika](../../Istochniki/URL/https/www.ispras.ru/_root/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.ispras.ru/_root/extraction-report.md)
- [Istochnik: Centr razvitiya cifrovyikh servisov Fonda prezidentskikh grantov](../../Istochniki/URL/https/xn--p1acnb.xn--p1ai/_root/)
- [Indeks istochnika](../../Istochniki/URL/https/xn--p1acnb.xn--p1ai/_root/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/xn--p1acnb.xn--p1ai/_root/extraction-report.md)
- [Istochnik: CK NTI](../../Istochniki/URL/https/ai.mipt.ru/_root/)
- [Indeks istochnika](../../Istochniki/URL/https/ai.mipt.ru/_root/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/ai.mipt.ru/_root/extraction-report.md)
- [Istochnik: Konkursyi | Rossijskij nauchnyij fond](../../Istochniki/URL/https/www.rscf.ru/contests/)
- [Indeks istochnika](../../Istochniki/URL/https/www.rscf.ru/contests/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.rscf.ru/contests/extraction-report.md)
- [Istochnik: xn--80afcdbalict6afooklqi5o.xn--p1ai](../../Istochniki/URL/https/xn--80afcdbalict6afooklqi5o.xn--p1ai/public/home/about/)
- [Indeks istochnika](../../Istochniki/URL/https/xn--80afcdbalict6afooklqi5o.xn--p1ai/public/home/about/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/xn--80afcdbalict6afooklqi5o.xn--p1ai/public/home/about/extraction-report.md)
- [Istochnik: «Professionaljnoye razvitiye»](../../Istochniki/URL/https/fondpotanin.ru/competitions/konkurs-professionalnogo-razvitiya/)
- [Indeks istochnika](../../Istochniki/URL/https/fondpotanin.ru/competitions/konkurs-professionalnogo-razvitiya/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/fondpotanin.ru/competitions/konkurs-professionalnogo-razvitiya/extraction-report.md)
- [Istochnik: fasie.ru](../../Istochniki/URL/https/fasie.ru/programs/programma-start/)
- [Indeks istochnika](../../Istochniki/URL/https/fasie.ru/programs/programma-start/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/fasie.ru/programs/programma-start/extraction-report.md)
- [Istochnik: Mikrograntyi](../../Istochniki/URL/https/sk.ru/grant-financial-support/microgrants/)
- [Indeks istochnika](../../Istochniki/URL/https/sk.ru/grant-financial-support/microgrants/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/sk.ru/grant-financial-support/microgrants/extraction-report.md)
- [Istochnik: Skidki, grantyi i specialjnyiye usloviya | Yandex Cloud](../../Istochniki/URL/https/yandex.cloud/ru/all-offers/)
- [Indeks istochnika](../../Istochniki/URL/https/yandex.cloud/ru/all-offers/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/yandex.cloud/ru/all-offers/extraction-report.md)
- [Istochnik: VK Dobro](../../Istochniki/URL/https/dobro.mail.ru/about/)
- [Indeks istochnika](../../Istochniki/URL/https/dobro.mail.ru/about/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/dobro.mail.ru/about/extraction-report.md)
- [Istochnik: Grant do 30 000 bonusov na oblako Selectel](../../Istochniki/URL/https/selectel.ru/services/cloud/grant/)
- [Indeks istochnika](../../Istochniki/URL/https/selectel.ru/services/cloud/grant/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/selectel.ru/services/cloud/grant/extraction-report.md)
- [Istochnik: Join — ALT Linux Wiki](../../Istochniki/URL/https/www.altlinux.org/Join/)
- [Indeks istochnika](../../Istochniki/URL/https/www.altlinux.org/Join/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.altlinux.org/Join/extraction-report.md)
- [Istochnik: Tekhnologicheskiye partneryi ROSA - sovmestimostj PO i oborudovaniya](../../Istochniki/URL/https/rosa.ru/tech-partners/)
- [Indeks istochnika](../../Istochniki/URL/https/rosa.ru/tech-partners/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/rosa.ru/tech-partners/extraction-report.md)
- [Istochnik: Statj tekhnologicheskim partnyorom | Astra Linux](../../Istochniki/URL/https/astra.ru/ready-for-astra/become-tech-partner/)
- [Indeks istochnika](../../Istochniki/URL/https/astra.ru/ready-for-astra/become-tech-partner/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/astra.ru/ready-for-astra/become-tech-partner/extraction-report.md)
- [Istochnik: www.swift.org](../../Istochniki/URL/https/www.swift.org/sswg/incubation-process.html/)
- [Indeks istochnika](../../Istochniki/URL/https/www.swift.org/sswg/incubation-process.html/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.swift.org/sswg/incubation-process.html/extraction-report.md)
- [Istochnik: Vyi ne robot?](../../Istochniki/URL/https/help.yandex.ru/business/)
- [Indeks istochnika](../../Istochniki/URL/https/help.yandex.ru/business/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/help.yandex.ru/business/extraction-report.md)
- [Istochnik: Registraciya fonda - VK Dobro](../../Istochniki/URL/https/dobro.mail.ru/funds/registration/)
- [Indeks istochnika](../../Istochniki/URL/https/dobro.mail.ru/funds/registration/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/dobro.mail.ru/funds/registration/extraction-report.md)
- [Istochnik: 1 000 000 bonusov dlya startapov ot Selectel](../../Istochniki/URL/https/selectel.ru/services/startups-grant/)
- [Indeks istochnika](../../Istochniki/URL/https/selectel.ru/services/startups-grant/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/selectel.ru/services/startups-grant/extraction-report.md)
- [Istochnik: astra.ru](../../Istochniki/URL/https/astra.ru/ready-for-astra/become-tech-partner/docs/affiliate_program/)
- [Indeks istochnika](../../Istochniki/URL/https/astra.ru/ready-for-astra/become-tech-partner/docs/affiliate_program/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/astra.ru/ready-for-astra/become-tech-partner/docs/affiliate_program/extraction-report.md)
- [Istochnik: Statj partnyorom - NTC IT ROSA: programma dlya proizvoditelej, integratorov i ISV](../../Istochniki/URL/https/rosa.ru/become-partner/)
- [Indeks istochnika](../../Istochniki/URL/https/rosa.ru/become-partner/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/rosa.ru/become-partner/extraction-report.md)
- [Istochnik: ALT Linux Team | proyekt Sisyphus («Sizif»)](../../Istochniki/URL/https/www.basealt.ru/alt-linux/)
- [Indeks istochnika](../../Istochniki/URL/https/www.basealt.ru/alt-linux/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.basealt.ru/alt-linux/extraction-report.md)
- [Istochnik: Komandyi i produktyi](../../Istochniki/URL/https/ai.mipt.ru/products/)
- [Indeks istochnika](../../Istochniki/URL/https/ai.mipt.ru/products/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/ai.mipt.ru/products/extraction-report.md)
- [Istochnik: Sovmestimostj | BaseALT](../../Istochniki/URL/https/www.basealt.ru/product-compatibility/)
- [Indeks istochnika](../../Istochniki/URL/https/www.basealt.ru/product-compatibility/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.basealt.ru/product-compatibility/extraction-report.md)
- [Istochnik: Glavnaya stranica | Portal razrabotchika ROSA](../../Istochniki/URL/https/developer.rosa.ru/_root/)
- [Indeks istochnika](../../Istochniki/URL/https/developer.rosa.ru/_root/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/developer.rosa.ru/_root/extraction-report.md)
- [Istochnik: Statj uchastnikom proyekta "Skolkovo"](../../Istochniki/URL/https/sk.ru/applicants-actions/)
- [Indeks istochnika](../../Istochniki/URL/https/sk.ru/applicants-actions/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/sk.ru/applicants-actions/extraction-report.md)
- [Istochnik: OpenFix — poluchite nagradu za vklad v Linux-kommjyuniti](../../Istochniki/URL/https/promo.selectel.ru/openfix/)
- [Indeks istochnika](../../Istochniki/URL/https/promo.selectel.ru/openfix/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/promo.selectel.ru/openfix/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/83a0acab-1de2-4959-b0fe-2c7ec1223c2d.selstorage.ru/OpenFix_rules.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/83a0acab-1de2-4959-b0fe-2c7ec1223c2d.selstorage.ru/OpenFix_rules.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/83a0acab-1de2-4959-b0fe-2c7ec1223c2d.selstorage.ru/OpenFix_rules.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/files.selectel.ru/docs/ru/promo-rules-grant-cloud.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/files.selectel.ru/docs/ru/promo-rules-grant-cloud.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/files.selectel.ru/docs/ru/promo-rules-grant-cloud.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/files.selectel.ru/docs/ru/startups-grant-contitions.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/files.selectel.ru/docs/ru/startups-grant-contitions.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/files.selectel.ru/docs/ru/startups-grant-contitions.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/fondpotanin.ru/upload/iblock/8d5/9h1w1u1d45dwt4z516u6tc1tupmodzvf.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/fondpotanin.ru/upload/iblock/8d5/9h1w1u1d45dwt4z516u6tc1tupmodzvf.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/fondpotanin.ru/upload/iblock/8d5/9h1w1u1d45dwt4z516u6tc1tupmodzvf.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/ias.rscf.ru/app/ext/user/conf/contests/docs/2026/131.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/ias.rscf.ru/app/ext/user/conf/contests/docs/2026/131.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/ias.rscf.ru/app/ext/user/conf/contests/docs/2026/131.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/sk.ru/documents/3202/Polozheniye_ob_otbore_Mikrograntyi_na_kompensaciyu_raskhodov.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/sk.ru/documents/3202/Polozheniye_ob_otbore_Mikrograntyi_na_kompensaciyu_raskhodov.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/sk.ru/documents/3202/Polozheniye_ob_otbore_Mikrograntyi_na_kompensaciyu_raskhodov.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/www.rscf.ru/upload/iblock/592/9npmqcrcqyu313w1ke5nwe6rjxy5nle2.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/www.rscf.ru/upload/iblock/592/9npmqcrcqyu313w1ke5nwe6rjxy5nle2.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.rscf.ru/upload/iblock/592/9npmqcrcqyu313w1ke5nwe6rjxy5nle2.pdf/extraction-report.md)
- [Istochnik: Oficialjnyij PDF uslovij podderzhki](../../Istochniki/URL/https/www.rscf.ru/upload/iblock/7ef/roobwviv105zmd68ojee7b07u3wsg0un.pdf/)
- [Indeks istochnika](../../Istochniki/URL/https/www.rscf.ru/upload/iblock/7ef/roobwviv105zmd68ojee7b07u3wsg0un.pdf/source-index.md)
- [Otchyot ob izvlechenii](../../Istochniki/URL/https/www.rscf.ru/upload/iblock/7ef/roobwviv105zmd68ojee7b07u3wsg0un.pdf/extraction-report.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:22:35 MSK -->
<!-- content-sha256: sha256:325ec702ae9ae123b1ae3c1ea591f684e7e0241669ad4292f24223425935c729 -->
<!-- FUM-MD-RECENCY:END -->
