# Tochnaya peredacha sinteticheskogo segmenta 0159

Kornevaya zadacha: `01a07d3d-d376-7ad2-aafc-67e4c25a67eb`. Osnovaniye i granica: [zapros](../zapros.md), [otchyot](../otchyot.md). Eto dochernij adresnyij rezuljtat dlya posleduyusjhej kornevoj priyomki, ne integraciya v master.

## Git i iskhodniki

- Vneshnij lokaljnyij Swift-kommit: `dd172958b0128cba73361eeac136e8bc66190230`, polnyij ref `refs/heads/codex/observation-container-01a07d3d`. Remote otsutstvuyet, publikacii net.
- Pervyij checkpoint novogo paketa: `9e754878d20ebd5f02df24df2c44f69c4c532870`.
- Prinyatyij kontejner: `dfdd1b65afd59666a696c29a024e0ca059497157`; yego paket ne imeyet diff. Posle itogovogo kommita nezavisimoye read-only-revjyu podtverdilo chistoye derevo.
- [Itogovyij manifest](iskhodniki-itoga.json): 17 fajlov, vklyuchaya 15 Swift-fajlov, SHA-256 kazhdogo. Dobavlen toljko `Packages/СнимокАгентскойЗадачи`; susjhestvuyusjheye prilozheniye ne menyalosj.
- FUM: polnyij ref `refs/heads/codex/контейнер-наблюдений-01a07d3d`; iskhodnyij HEAD etogo etapa `6dfe1870a9aa400dd595efabd7699c0b179d233a`; checkpoint `39a273896b3dd508153d8ef29a0b121b5a41dc35` tochno dostavlen v proverennyij origin. Itogovyij OID zhurnaljnogo kommita opredelyayetsya soderzhasjhim etot fajl kommitom i otdeljno peredayotsya vmeste s proverennyim udalyonnyim OID posle push.

## Vosproizvedeniye i svideteljstva

- 40 terminaljnyikh zapisej [v4](zapuski-proverok/), bez aktivnogo khvosta. №39: 35 testov/6 naborov GREEN, nolj otkazov, XCTest 0,565 s; №40: tochnyij staged diff vneshnego paketa.
- №34 — itogovaya release-sborka; №35 — [podtverzhdayusjhij profilj](profilj-itoga.json). Apple Swift 6.4, rezhim Swift 6, native SwiftPM, macOS arm64. Preduprezhdeniye o native build-system ne skryivayetsya; concurrency-preduprezhdenij itogovyij nabor ne dal.
- №36–38 — realjnaya zapisj 18 sinteticheskikh nablyudenij i dva nezavisimyikh processa replay. [JSON](primer-snimka.json) pri zapisi i vosstanovlenii sovpal pobajtovo. [Markdown](primer-snimka.md) poluchen iz toj zhe modeli; sluzhebnyij FUM-recency ne yavlyayetsya chastjyu CLI-vyivoda.
- Sinteticheskij demonstracionnyij kontejner ostavlen vne Git, v sobstvennom pakete `.build/пример-снимка.c0V7Ix/сегмент.fumobs`; SHA-256 `c0449df6d9c143416f02f620296e3e72e350e2184cf88b994f4828da6ccf0999`.
- Profilj 256 sobyitij: 597922 bajta khraneniya; chistaya sborka 21,933 ms, zapisj 640,598 ms, replay 576,585 ms, 32 povtora 3,715 ms/0 novyikh bajt. SHA kontejnera `596db8e0a06e4826ce8b4bbe28a9fb1a1bc8f58d493f01682b7d87b99f824632`; SHA snimka `083bae11a7571f6c9c436bae40cc5d92c8944f1c491bc86bcb1573dbb67ee448`.
- [Resheniye ob optimizacii](profilj-i-resheniye.md) soderzhit baseline, isklyuchyonnyij peresechyonnyij progon, sravneniye i granicyi prichinnogo vyivoda.

CLI paketa: `пример`, `собрать <абсолютный-вход> <абсолютный-корень> <json|markdown>`, `восстановить <абсолютный-корень> <поставщик> <хост> <ID> <json|markdown>`, `профиль <новый-существующий-корень> <1..256>`. Polnyij kontrakt i komandyi vosproizvedeniya nakhodyatsya v README paketa; kanonicheskij zapisannyij vkhod — `Примеры/пять-сценариев.json`.

## Ne zakryito etim segmentom

Polnyiye FUM-STEP-0159, FUM-STEP-0156 i FUM-REQ-0044 ostayutsya otkryityi. Zhivyiye API/JSONL, Accessibility, ScreenCapture, datchiki, razresheniya i prilozheniye FUMA ne podklyuchenyi. Svezhestj realjnyikh istochnikov, podtverzhdeniye fakticheskogo sostoyaniya Codex, perenosimostj serializacii na vse versii Foundation, ustojchivostj k potere pitaniya i proizvoljnyiye Unicode-ID ne zayavlenyi.

Obsjhaya priyomka FUM i aktualjnaya proyekciya vyipolnyayutsya roditeljskoj zadachej. Etot Zhurnal ostayotsya otkryitoj terminaljnoj kontroljnoj tochkoj bez polnogo smoke-check; 282 istoricheskiye ssyilki na otsutstvuyusjhij lokaljnyij graph.json — izvestnaya iskhodnaya granica, ne ustranyonnaya sozdaniyem poljzovateljskogo sostoyaniya. Doslovnyiye zaprosyi i staryiye syiryiye v4-zapisi sokhranenyi. Razreshyonnyij dochernij soderzhateljnyij obyyom ischerpan; integraciya trebuyet kornevoj proverki tochnyikh OID/bajtov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 14:43:06 MSK -->
<!-- content-sha256: sha256:b2e43dc8a848dc6befda091ac7629d9f3cfa2de3390c3659fc9619df05efe6d8 -->
<!-- FUM-MD-RECENCY:END -->
