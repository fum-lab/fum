# Inventarj i klassifikaciya shagov smoke

Svezhij iskhodnyij progon na etoj mashine postroil i uspeshno vyipolnil 76 shagov. Posle razdeleniya profilej yavnyij `--профиль полный --list` povtorno pokazal te zhe 76 shagov, a standartnyij `--list` — toljko 20 shagov polozhiteljnogo perechnya. Ni odin test, instrument ili istoricheskoye dokazateljstvo ne udalenyi: 56 isklyuchyonnyikh iz standarta shagov ostayutsya v yavnom polnom profile.

Kriterij standartnogo profilya — neposredstvennoye uchastiye v rabochem cikle dokumentacionnogo prototipa: istochnik i MSK-identichnostj sessii, zapros i otchyot, planirovaniye, perenosimostj Markdown, ssyilki i indeksyi, recency, proverochnyij zhurnal, svyaznostj sessii i sam kontrakt sostava smoke. Proverka koda, korobochnogo prototipa, istoricheskogo konvejyera ili neobyazateljnoj avtomatizacii otnositsya k polnomu libo otdeljnomu celevomu zapusku.

## Standartnyij profilj: proverki tekusjhego snimka

Eti vosemj shagov obrazuyut fiksirovannyij rannij prefiks imenno v ukazannom poryadke.

1. `Проверка структуры папок запросов` — celostnostj `запрос.md`, `отчёт.md`, shablonov, navigacii i `Журнал/README.md`.
2. `Сборка планового реестра` — vosproizvodimaya materializaciya proizvodnogo JSON iz kanonicheskikh kartochek.
3. `Проверка планового реестра` — nezavisimaya sverka toljko chto sobrannogo rezuljtata s istochnikami.
4. `Проверка машинно-локальных путей` — perenosimostj i publikacionnaya chistota Markdown-pamyati.
5. `Проверка двунаправленности вопросов` — susjhestvovaniye celej, tochnyij registr i obratnyiye ssyilki.
6. `Проверка тематического индекса README` — poljzovateljskij vkhod i polnoye pokryitiye nomernoj dokumentacii.
7. `Проверка recency-меток Markdown` — svezhestj sluzhebnyikh blokov i obsjhego indeksa.
8. `Проверка связности рабочей сессии` — zamyikaniye zaprosa, otchyota, Git-sostoyaniya, ssyilok, zhurnala proverok, soobsjheniya kommita i kornevogo seansa Codex.

Podgotovka do pervogo shaga otdeljno proveryayet `skills.include_instructions = false` i lokaljnostj vsekh putej `Инструменты/*/SKILL.md`. Eto obyazateljnaya nepechatayemaya granica obsjhego smoke-check po `AGENTS.md`.

## Standartnyij profilj: razreshyonnyiye avtonomnyiye naboryi

Posle rannego prefiksa vyipolnyayutsya rovno sleduyusjhiye dvenadcatj naborov v determinirovannom poryadke kanonicheskikh POSIX-klyuchej. Oni proveryayut realizaciyu samogo dokumentarnogo rabochego kontura, a ne vesj kod repozitoriya.

1. `Тесты fum-indeks-readme`.
2. `Тесты fum-kompleksnaya-proverka-repozitoriya`.
3. `Тесты fum-materialyi-zaprosov`.
4. `Тесты fum-moskovskoye-vremya-rabochej-sessii`.
5. `Тесты fum-obratnyiye-ssyilki-voprosov`.
6. `Тесты fum-otchyotyi-o-zapuskakh-proverok`.
7. `Тесты fum-proverka-mashinno-lokaljnyikh-putej`.
8. `Тесты fum-proyektnyiye-fajlyi`.
9. `Тесты fum-reyestr-planirovaniya`.
10. `Тесты fum-struktura-papok-zaprosov`.
11. `Тесты fum-svezhestj-markdown`.
12. `Тесты fum-svyaznostj-rabochej-sessii`.

V svezhem baseline eti dvenadcatj naborov summarno zanyali `42,642177 с`. Ikh katalogi razreshayutsya napryamuyu, bez obsjhego avtopoiska; otsutstviye, pustoj katalog ili vyikhod cherez simvolicheskuyu ssyilku zakryivayut podgotovku otkazom.

## Toljko polnyij profilj: dopolniteljnyiye proverki snimka

Kazhdyij iz sleduyusjhikh chetyiryokh shagov sokhranyon, no ne nuzhen dlya obyichnoj rabotyi dokumentacionnogo prototipa.

1. `Проверка реестра названий автоматизаций` — kontrakt imyon koda i LinguisticKit.
2. `Проверка перевода объявлений кода` — vremennaya granica obsjhej kodovoj migracii.
3. `Проверка Git-зависимости LinguisticKit` — topologiya i reviziya vneshnej Git-zavisimosti.
4. `Проверка скриптов запуска прототипов` — tochki vkhoda korobochnyikh prototipov.

## Toljko polnyij profilj: Python-regressii vne yadra

Eti shestnadcatj naborov ostayutsya dostupnyimi cherez avtopoisk polnogo profilya. Istoricheskiye queue, dispatcher, autostart i branch-next konturyi sokhranenyi kak proiskhozhdeniye, no ne ispolnyayutsya obyichnoj ruchnoj dokumentacionnoj sessiyej.

1. `Тесты fum-sleduyusjhij-shag-vetki` — istoricheskij branch-next.
2. `Тесты fum-ocheredj-zadach-git-vetki` — istoricheskiye FIFO, pool, CAS i handoff.
3. `Тесты fum-dispetcher-avtomatizacij-fum` — istoricheskij dispatcher.
4. `Тесты fum-pochinka-avtozapuska` — istoricheskij autostart repair.
5. `Тесты fum-sborka-svodnoj-dokumentacii` — neobyazateljnaya sborka svodnoj dokumentacii.
6. `Тесты fum-proverka-trassyi-agentskogo-cikla` — otdeljnaya kodovaya trassa agentskogo cikla.
7. `Тесты fum-audit-pokryitiya-voprosov-i-otvetov` — otdeljnyij smyislovoj audit.
8. `Тесты fum-ocenki` — kontur ocenok.
9. `Тесты fum-svezhestj-grafa-obsidian` — istoricheskaya teplovaya karta ignored `graph.json`.
10. `Тесты fum-proverka-nazvanij-avtomatizacij` — kodovyij kontrakt imyon.
11. `Тесты fum-revjyu-prodelannoj-rabotyi` — kontur revjyu.
12. `Тесты fum-perevod-obyyavlenij-koda-na-russkij-yazyik` — migraciya obyyavlenij koda.
13. `Тесты fum-zapusk-prototipov` — korobochnyiye tochki vkhoda.
14. `Тесты fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok` — otdeljnoye preobrazovaniye fajlov.
15. `Тесты fum-proverka-git-zavisimostej` — Git-topologiya zavisimostej.
16. `Тесты fum-analitika-zavershyonnyikh-shagov` — istoricheskaya analitika zavershyonnyikh shagov.

## Toljko polnyij profilj: SwiftPM-testyi

Vse desyatj SwiftPM-testov otnosyatsya k korobochnyim prototipam, a ne k nablyudayemomu dokumentacionnomu prototipu.

1. `Тесты SwiftPM Прототипы/агентное-чтение-сетевой-среды`.
2. `Тесты SwiftPM Прототипы/воспроизводимое-пополнение-памяти`.
3. `Тесты SwiftPM Прототипы/живой-одноагентный-эпизод`.
4. `Тесты SwiftPM Прототипы/иерархия-функций-и-данных`.
5. `Тесты SwiftPM Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф`.
6. `Тесты SwiftPM Прототипы/память-структурирующих-операторов`.
7. `Тесты SwiftPM Прототипы/проверяемый-многоагентный-контур`.
8. `Тесты SwiftPM Прототипы/теневой-редактор-продолжений`.
9. `Тесты SwiftPM Прототипы/физические-состояния-клавиш`.
10. `Тесты SwiftPM Прототипы/чистый-модельный-шаг`.

## Toljko polnyij profilj: sborki i lint SwiftPM

Fiksirovannyij khvost soderzhit shestnadcatj sborok ispolnyayemyikh produktov i desyatj strogikh lint-proverok.

1. `Сборка SwiftPM-продукта Прототипы/агентное-чтение-сетевой-среды: FUMNetworkEnvironmentProbe`.
2. `Строгий lint SwiftPM Прототипы/агентное-чтение-сетевой-среды`.
3. `Сборка SwiftPM-продукта Прототипы/воспроизводимое-пополнение-памяти: FUMMemoryPopulationProbe`.
4. `Строгий lint SwiftPM Прототипы/воспроизводимое-пополнение-памяти`.
5. `Сборка SwiftPM-продукта Прототипы/живой-одноагентный-эпизод: FUMLiveCandidateAcceptanceProbe`.
6. `Сборка SwiftPM-продукта Прототипы/живой-одноагентный-эпизод: FUMLiveEpisodeHarness`.
7. `Сборка SwiftPM-продукта Прототипы/живой-одноагентный-эпизод: FUMLiveEpisodeProbe`.
8. `Сборка SwiftPM-продукта Прототипы/живой-одноагентный-эпизод: FUMLiveEpisodeWorker`.
9. `Строгий lint SwiftPM Прототипы/живой-одноагентный-эпизод`.
10. `Сборка SwiftPM-продукта Прототипы/иерархия-функций-и-данных: FUMFunctionHierarchyProbe`.
11. `Строгий lint SwiftPM Прототипы/иерархия-функций-и-данных`.
12. `Сборка SwiftPM-продукта Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф: FUMTensorGraphProbe`.
13. `Строгий lint SwiftPM Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф`.
14. `Сборка SwiftPM-продукта Прототипы/память-структурирующих-операторов: FUMStructuringOperatorMemoryProbe`.
15. `Строгий lint SwiftPM Прототипы/память-структурирующих-операторов`.
16. `Сборка SwiftPM-продукта Прототипы/проверяемый-многоагентный-контур: FUMWorkPackageProbe`.
17. `Сборка SwiftPM-продукта Прототипы/проверяемый-многоагентный-контур: FUMWritingSubnodePassportProbe`.
18. `Строгий lint SwiftPM Прототипы/проверяемый-многоагентный-контур`.
19. `Сборка SwiftPM-продукта Прототипы/теневой-редактор-продолжений: FUMShadowEditor`.
20. `Сборка SwiftPM-продукта Прототипы/теневой-редактор-продолжений: FUMShadowProbe`.
21. `Строгий lint SwiftPM Прототипы/теневой-редактор-продолжений`.
22. `Сборка SwiftPM-продукта Прототипы/физические-состояния-клавиш: FUMInputGuide`.
23. `Сборка SwiftPM-продукта Прототипы/физические-состояния-клавиш: FUMInputProbe`.
24. `Строгий lint SwiftPM Прототипы/физические-состояния-клавиш`.
25. `Сборка SwiftPM-продукта Прототипы/чистый-модельный-шаг: FUMModelStepProbe`.
26. `Строгий lint SwiftPM Прототипы/чистый-модельный-шаг`.

## Samyiye dorogiye isklyuchyonnyiye shagi baseline

Pyatj samyikh dorogikh isklyuchyonnyikh testovyikh shagov zanyali `2499,957425 с`, to yestj `83,954%` vsego iskhodnogo progona yesjhyo do uchyota ostaljnyikh isklyuchenij.

1. `Тесты SwiftPM Прототипы/проверяемый-многоагентный-контур` — `1142,329108 с`.
2. `Тесты fum-ocheredj-zadach-git-vetki` — `559,963323 с`.
3. `Тесты fum-dispetcher-avtomatizacij-fum` — `472,298326 с`.
4. `Тесты SwiftPM Прототипы/живой-одноагентный-эпизод` — `166,991406 с`.
5. `Тесты fum-sleduyusjhij-shag-vetki` — `158,375782 с`.

Vse 38 analiticheskikh naborov baseline zanyali `2816,310377 с`; dvenadcatj standartnyikh — `42,642177 с`; isklyuchyonnyiye analiticheskiye naboryi — `2773,668200 с`.

## Istochniki

- [iskhodnyij zapros](../zapros.md)
- [otchyot rabochej sessii](../otchyot.md)
- [baseline-zapisj polnogo smoke](zapuski-proverok/1_33a19fcd-ea04-4b0e-b2b0-90cb9071bc86.json)
- [lokaljnyij navyik smoke-check](../../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [pasport dokumentacionnogo prototipa](../../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 15:00:57 MSK -->
<!-- content-sha256: sha256:3ab5a07c03276d8c06da06dc51fe9416e08855c3f23086d4fa27aa63ed3df0d7 -->
<!-- FUM-MD-RECENCY:END -->
