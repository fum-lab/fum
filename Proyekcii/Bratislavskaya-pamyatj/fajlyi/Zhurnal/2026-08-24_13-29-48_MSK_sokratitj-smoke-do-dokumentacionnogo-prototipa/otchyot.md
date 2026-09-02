# Otchyot 2026-08-24 13:29:48 MSK - Sokratitj smoke do dokumentacionnogo prototipa

Rabochaya sessiya izmerila iskhodnyij shirokij smoke do izmeneniya production, zatem perevela obyichnyij zapusk na polozhiteljnyij perechenj minimaljno zamknutyikh proverok dokumentacionnogo prototipa. Tyazhyolyiye testyi i sborochnyiye konturyi sokhranenyi dlya otdeljnogo yavnogo polnogo zapuska. Na odnoj mashine iskhodnyiye 76 shagov uspeshno proshli za `2977,779 с`, a itogovyiye 20 — za `116,049 с`: vremya sokratilosj na `2861,730 с`, ili `96,103%`, i zapusk uskorilsya v `25,660` raza.

## Profilj vremeni vyipolneniya

| Stadiya                              | Dliteljnostj | Granicyi i sposob izmereniya                                                                  |
| ----------------------------------- | ------------ | ------------------------------------------------------------------------------------------- |
| Proverka dopuska i pravil           | ne izmereno  | Ot pervoj read-only-sverki `HEAD` do gotovnosti kanonicheskogo zhurnala                       |
| Ozhidaniye dopuska FIFO               | 0 s          | Ne primenimo v dejstvuyusjhej ruchnoj posledovateljnoj skheme                                    |
| Iskhodnyij shirokij smoke              | 2977,779 s   | Monotonnoye wall-clock-vremya obyazateljnoj obyortki do izmeneniya production; terminal success  |
| Soderzhateljnaya rabota               | ne izmereno  | Ot inventarya iskhodnogo plana do gotovoj realizacii polozhiteljnogo perechnya                   |
| Celevyiye proverki                    | ne izmereno  | Ot pervogo RED do zaversheniya adresnyikh GREEN- i corruption-proverok                          |
| Itogovyij standartnyij smoke          | 116,049 s    | Monotonnoye wall-clock-vremya poslednego zapisyivayemogo smoke; terminal success, 20/20 shagov   |
| Lokaljnyij kommit i read-only-sverka | ne izmereno  | Odin obyichnyij commit na `refs/heads/master`; posle nego toljko read-only-proverka rezuljtata |

Granica profilya: nachata 2026-08-24 13:29:48 MSK; okhvatyivayet proverku dopuska, baseline, realizaciyu, celevyiye proverki, itogovyij smoke i lokaljnyij kommit, no ne vklyuchayet istoricheskuyu FIFO.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:f376da52355f117d0796097bee2dd8385f7beb6c3799b18f6e1fac0f7d207f43 -->

| Vyizov                                                                                 | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Iskhodnyij standartnyij smoke do izmeneniya                              | 2977,779 s   | uspeshno   |
| [kornevoj agent] Inventarj iskhodnogo standartnogo smoke cherez --list                  | 0,092 s      | neuspeshno |
| [kornevoj agent] Inventarj iskhodnogo standartnogo smoke cherez --list s commit-context | 9,753 s      | uspeshno   |
| [kornevoj agent] RED: sostav i podgotovka standartnogo smoke                          | 0,208 s      | neuspeshno |
| [kornevoj agent] RED: polozhiteljnyij perechenj dokumentacionnyikh naborov                 | 0,18 s       | neuspeshno |
| [kornevoj agent] GREEN: sostav i poryadok profilej smoke                               | 0,238 s      | uspeshno   |
| [kornevoj agent] GREEN: polnyij avtonomnyij nabor ispolnitelya smoke                     | 24,834 s     | uspeshno   |
| [kornevoj agent] Spisok standartnogo dokumentacionnogo smoke                          | 0,132 s      | uspeshno   |
| [kornevoj agent] Spisok yavnogo polnogo smoke                                          | 10,381 s     | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: proyektnyij fajlovyij inventarj                   | 0,508 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: moskovskoye vremya sessii                        | 0,297 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: struktura zaprosov i otchyotov                   | 9,32 s       | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: mashinnyij zhurnal proverok                       | 7,645 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: svyaznostj rabochej sessii                       | 2,579 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: svezhestj Markdown                              | 0,24 s       | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: planovyij reyestr                                | 3,875 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: obratnyiye ssyilki voprosov                       | 0,274 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: indeksyi README                                 | 0,646 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: mashinno-lokaljnyiye puti                         | 2,373 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: materialyi zaprosov                             | 0,489 s      | uspeshno   |
| [kornevoj agent] Kontroliruyemyiye porchi: sostav profilej smoke                          | 23,449 s     | uspeshno   |
| [kornevoj agent] Celevaya proverka obyyavlenij koda                                     | 28,237 s     | neuspeshno |
| [kornevoj agent] Inventarj ostatka obyyavlenij koda                                    | 22,709 s     | uspeshno   |
| [kornevoj agent] Obnovleniye sokrasjhyonnogo snimka obyyavlenij koda                       | 22,436 s     | uspeshno   |
| [kornevoj agent] Proverka sokrasjhyonnogo snimka obyyavlenij koda                         | 22,708 s     | uspeshno   |
| [kornevoj agent] Obnovleniye Markdown-recency posle dokumentacii profilej              | 0,691 s      | uspeshno   |
| [kornevoj agent] Obnovleniye recency posle predprosmotra otchyota                        | 0,668 s      | uspeshno   |
| [kornevoj agent] Struktura zaprosov i otchyotov posle dokumentacii                      | 13,129 s     | uspeshno   |
| [kornevoj agent] Sborka planovogo reyestra pered priyomkoj                              | 0,373 s      | uspeshno   |
| [kornevoj agent] Proverka planovogo reyestra pered priyomkoj                            | 0,345 s      | uspeshno   |
| [kornevoj agent] Publikacionnaya chistota mashinnyikh putej                                | 14,599 s     | uspeshno   |
| [kornevoj agent] Obratnyiye ssyilki voprosov posle dokumentacii                          | 5,797 s      | uspeshno   |
| [kornevoj agent] Indeksyi README posle dokumentacii                                    | 0,274 s      | uspeshno   |
| [kornevoj agent] Proverka Markdown-recency pered priyomkoj                             | 0,625 s      | uspeshno   |
| [kornevoj agent] Obnovleniye Markdown-recency pered itogovyim smoke                     | 0,664 s      | uspeshno   |
| [kornevoj agent] Itogovyij standartnyij smoke dokumentacionnogo prototipa               | 116,049 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3324,596 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Svezhij baseline do production-izmenenij zavershilsya terminal success: 76 shagov, `2977,701 с` po vnutrennemu tajmeru i `2977,778883 с` po obyazateljnoj vneshnej obyortke.
- TDD snachala dal dva ozhidayemyikh RED na prezhnem avtopoiske i yesjhyo tri RED na otsutstvii tochnogo polozhiteljnogo perechnya, zatem vesj nabor ispolnitelya zavershil 68 testov uspeshno.
- Dvenadcatj nezavisimo zapusjhennyikh naborov podtverdili controlled-corruption-granicyi proyektnogo inventarya, MSK-vremeni, strukturyi zaprosov, khyeshirovannogo zhurnala, svyaznosti, recency, planning, obratnyikh ssyilok, README, mashinno-lokaljnyikh putej, materialov i sostava smoke.
- Standartnyij `--list` za `0,012 с` pokazal rovno 20 shagov i ne vyizval avtopoisk, Swift ili istoriyu. Yavnyij `--профиль полный --list` za `10,255 с` snova pokazal vse 76 shagov, vklyuchaya tyazhyolyiye komandyi toljko kak plan.
- Itogovyij novyij standartnyij smoke zavershilsya terminal success na toj zhe mashine: 20/20 shagov, `115,962 с` po vnutrennemu tajmeru i `116,048745 с` po obyazateljnoj vneshnej obyortke.

## Resheniya i ogranicheniya

- Zapisj zhurnala i recency do baseline yavlyayetsya sluzhebnoj podgotovkoj tekusjhej sessii, a ne izmeneniyem production-plana smoke.
- Sravneniye opirayetsya na fakticheskiye uspeshnyiye progonyi odnoj mashinyi; pri zametnom vneshnem shume zameryi povtoryayutsya libo ogranicheniye yavno fiksiruyetsya.
- Standart soderzhit vosemj live-proverok i dvenadcatj tochnyikh avtonomnyikh naborov. Katalogi razreshayutsya napryamuyu; otsutstviye, pustoj nabor ili vyikhod simvolicheskoj ssyilkoj zakryivayut podgotovku otkazom.
- Testyi, istoricheskiye instrumentyi i SwiftPM-konturyi ne udalenyi. Oni ostayutsya dostupnyimi toljko cherez otdeljnyij yavnyij polnyij ili celevoj zapusk i ne poluchayut avtomaticheskogo marshruta iz standartnogo smoke.
- Istoricheskij ostatok latinskikh Python-obyyavlenij sokratilsya na odno imya (`16195 → 16194`); snimok obnovlyon kanonicheskoj avtomatizaciyej i povtorno sovpal.

## Polnyij inventarj i stoimostj

[Inventarj i klassifikaciya](materialyi/inventarj-shagov-smoke.md) perechislyayut vse 76 iskhodnyikh shagov: 20 sokhranenyi v standarte, 56 perevedenyi toljko v yavnyij polnyij profilj. Dvenadcatj sokhranyonnyikh unit-naborov zanimali `42,642177 с`, a isklyuchyonnyiye analiticheskiye naboryi — `2773,668200 с`.

Sopostavleniye vneshnego wall-clock odnoj mashinyi dayot `2977,778883 − 116,048745 = 2861,730138 с` absolyutnogo sokrasjheniya. Otnositeljnoye sokrasjheniye ravno `96,102842%`, itogovyij zapusk zanimayet `3,897158%` prezhnego vremeni, a otnosheniye dliteljnostej ravno `25,659725×`.

Samyiye dorogiye isklyuchyonnyiye shagi: SwiftPM-test proveryayemogo mnogoagentnogo kontura (`1142,329108 с`), istoricheskaya ocheredj Git-vetki (`559,963323 с`), dispetcher avtomatizacij (`472,298326 с`), zhivoj odnoagentnyij epizod (`166,991406 с`) i sleduyusjhij shag vetki (`158,375782 с`).

Otdeljnyij shirokij zapusk vyipolnyayetsya toljko yavno:

```bash
python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --commit-message-file <путь-к-файлу-сообщения> \
  --codex-thread-id <корневой-CODEX_THREAD_ID> \
  --профиль полный
```

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [inventarj i klassifikaciya vsekh shagov](materialyi/inventarj-shagov-smoke.md)
- [pasport dokumentacionnogo prototipa](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)
- [lokaljnyij navyik smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 15:10:10 MSK -->
<!-- content-sha256: sha256:3e9d1a8256d9215fb5fcc65d967d31a5dbc38f0deb6e48e1f9ed6e196bdaa7c9 -->
<!-- FUM-MD-RECENCY:END -->
