# Koordinaciya predposyilki integracii

Istochnik — kvalificirovannyiye soobsjheniya iz zadachi `01a07d3d-d376-7ad2-aafc-67e4c25a67eb`, a ne novyiye soobsjheniya cheloveka etoj zadachi. Polnyiye pervichnyiye sobyitiya s lokaljnyimi putyami sokhranenyi privatno. Publikacionnaya zapisj nizhe peredayot resheniya i sokhranyayet otpechatki originalov.

- 2026-09-15T20:31:18.936Z; SHA-256 pervichnoj stroki `a08251ebd2ff7763f8db6340c6ce7cd081138646200d43377ef13b5e270561ea`.
- 2026-09-15T20:36:14.262Z; SHA-256 pervichnoj stroki `07fd5c5364095afce77579efaab03199ee8e41ed0140e065aa4f54510b0ab3fd`.

Koordinator vozobnovil ispolneniye uzhe zaproshennoj integracii v susjhestvuyusjhej vidimoj zadache. Vyidelen odin novyij pishusjhij korenj etapa v linked worktree strogo ot M; prezhneye derevo, indeks i ref `codex/совместимость-master-FUMA-0175-01a09047` i nezavershyonnoye0227 ostayutsya priostanovlennyimi i ne menyayutsya. Native-zadacha ne sozdayotsya, novaya istoriya staroj vetki ne perepisyivayetsya. Tochnaya granica — tri fajla podgotovlennoj politiki dlya zakreplyonnogo L, sobstvennyij Zhurnal i adresnyij checkpoint. Prezhneye read-only-ogranicheniye etogo proyekta snyato dannyim naznacheniyem; ostaljnaya pauza sokhranyayetsya.

Pozdneye peredano doslovnoye utochneniye cheloveka: «No myordzh cherez PR ostayotsya zhe v sile?» Korenj podtverdil: predposyilka tozhe peredayotsya otdeljnyim PR; master v obkhod PR ne prodvigayetsya. Obsjhaya PR/Actions-priyomka tochnogo C yesjhyo ne realizovana. Dannyij etap ne prinimayet PR i ne menyayet master. [Issue1](https://github.com/fum-lab/fum/issues/1) i [draftPR2](https://github.com/fum-lab/fum/pull/2) otnosyatsya k peredannoj koordinatorom svyazi osnovnoj integracii; predposyilka poluchayet otdeljnuyu peredachu.

Soderzhateljnyij otvet ispolnitelya: podgotovitj novuyu izolirovannuyu vetku ot M, sveritj neizmennuyu ordinary policy419 i candidate432, sokhranitj adresnyij checkpoint i peredatj OID dlya otdeljnogo PR. Polnyij smoke i finaljnaya proyekciya zhdut soglasovannogo okna. Avtomatizacii PR/Actions i priyomka master etim checkpoint ne dokazyivayutsya.

## Vidimyiye otvetyi ispolnitelya

### 2026-09-15T20:31:43.518Z

````text
Начинаю предпосылку в отдельном дереве от M. Сначала сверю правила, владельца и точный пакет, затем проведу адресные проверки и сохраню checkpoint в новой ветке. Дерево a6f5 с 0227 останется приостановленным.

````

### 2026-09-15T20:33:19.596Z

````text
Новое дерево создано строго от `e95d7f5d1ef6387454b7825932cfbd737e600473`; новая ветка — `codex/политика-интеграции-01ca9886-01a09047`. Нативные метаданные подтверждают `gpt-6-astra / ultra`. Оформляю этап и проверяю пакет; старое дерево остаётся без записи.

````

### 2026-09-15T20:36:31.288Z

````text
Уточнение о PR принято: подготовлю коммит предпосылки и передам его для отдельного PR. Checkpoint не будет означать готовность к слиянию: согласование PR/Actions с приёмкой точного коммита остаётся отдельной работой координатора.

````

### 2026-09-15T20:40:45.077Z

````text
Адресная сверка прошла: 432 исключения по 125 файлам L, из них 13 новых; обычная политика M сохранена. Независимый обзор подтвердил входные OID и три файла пакета. Сейчас идёт проверка публикационных путей, после неё — заключительная связность checkpoint.

````


### 2026-09-15T20:46:54.980Z

````text
Восстанавливаю состояние этапа политики: проверю подготовленный индекс и результат последней команды, затем выполню допуск контрольной точки. Работа 0227 остаётся на паузе; интеграция в master сохраняется через PR.

````

### 2026-09-15T20:48:16.725Z

````text
В индексе только три файла политики и материалы текущего этапа. Отчёт сохраняет исходный RED, успешную сверку 432 исключений и успешную проверку публикационных путей. Полная приёмка отмечена как невыполненная; проверяю условия сохранения контрольной точки.

````

## Utochneniye prinimayusjhego puti PR

Kvalificirovannoye soobsjheniye koordinatora; eto peredannoye issledovaniye, ne sobstvennaya proverka GitHub. Pervichnaya stroka: SHA-256 `923e065f2ea83be3c4a5bacaf388613b3c4651668e597661d88a9ed8959bbc3c`.

````text
Read-only исследование PR-пути: GitHub GraphQL updateRefs даёт атомарный beforeOid M → afterOid C force=false; https://docs.github.com/en/graphql/reference/git#updaterefs. Но это проверка ref, не PR/reviews/checks; косвенная метка merged сама не доказывает допуск. Предпочтительное предложение: показать именно C в head PR, проверить фактические protection/rulesets, required checks/reviews по C, затем продвигать тот же C только после доказанного PR-допуска. Merge queue/linear history/ограничения locally created merge могут быть несовместимы; ничего не обходить. Текущий конкретный объём предпосылки не расширяю; сначала сохранённый checkpoint, затем отдельный PR, master не двигать. Итог исследования ещё сохраню в FUM.
````

Otvet ispolnitelya: prinyatj ogranicheniye obyyoma; sokhranitj kontroljnuyu tochku sobstvennoj vetki i peredatj yeyo dlya otdeljnogo PR. Nablyudyonnyiye proverki i sokhrannostj starogo dereva peredanyi koordinatoru. Predlozheniye updateRefs ne schitayetsya gotovyim prinimayusjhim mekhanizmom.

### 2026-09-15T20:50:23.564Z

````text
Независимая сверка подтвердила сохранность старого дерева, индекса и 13 неотслеживаемых файлов. Уточнение координатора о PR принято. Запускаю заключительную проверку связности контрольной точки; после её успеха сохраню и опубликую собственную ветку.

````

### 2026-09-15T20:52:06.324Z

````text
Связность выявила три причины отказа: в отчёте нет строки «Граница профиля», предыдущий запрос с обновлённой навигацией не указан среди затронутых файлов, а в новом дереве отсутствуют файлы закреплённого LinguisticKit, на которые ссылаются старые документы. Исправляю оформление и проверяю штатный способ подготовить эту зависимость.

````

### 2026-09-15T20:55:26.187Z

````text
Ошибки оформления исправлены. Для LinguisticKit найден штатный путь подготовки: собственная копия точной ревизии с проверкой обоих remote. Свидетельства повторов FUM-СБОЙ-0051 и 0071 переданы координатору для записи в актуальные карточки ведущей ветки.

````

### 2026-09-15T20:56:26.910Z

````text
Использую локальный навык `fum-proverka-git-zavisimostej` для подготовки уже зарегистрированного LinguisticKit. Его gitlink и `.gitmodules` останутся прежними. После этого повторю связность на исправленном оформлении.

````

## Peredacha povtorov koordinatoru

Koordinator podtverdil, chto vnesyot pervichnyiye nablyudeniya v susjhestvuyusjhiye aktualjnyiye kartochki0051/0071 i svyazannyiye shagi v fuma posle chteniya svideteljstva i polucheniya OID. Perenos istoricheskikh kartochek v uzkuyu predposyilku pryamo isklyuchyon. Podtverzhdeniye proiskhozhdeniya sokhraneno privatno; SHA-256 pervichnoj stroki `77e8d70eb443986e360a1feeeb5aa9e454b793d700eb3cfe601ff6ebebd9d62b`. Ispolnitelj peredal putj sobstvennogo pervichnogo materiala i yego SHA-256 `f34c62d5bd807de07d9041fe398ab1c05e8fed8a48c33e41cf993df2dee2fc2e`; OID peredayotsya posle fakticheskogo kommita.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:58:37 MSK -->
<!-- content-sha256: sha256:32b85e27e814a4cc22d4942b622cbeead6ae57e6f4a7395fc059dd8051c3d37a -->
<!-- FUM-MD-RECENCY:END -->
