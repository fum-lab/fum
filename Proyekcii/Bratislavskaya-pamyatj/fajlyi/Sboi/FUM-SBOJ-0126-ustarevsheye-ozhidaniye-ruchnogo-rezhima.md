+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0126"
"статус" = "активна"
+++
# Ustarevsheye ozhidaniye ruchnogo rezhima v repozitornom teste

## Nablyudayemyij sboj

Repozitornyij test istoricheskoj diagnostiki ozhidal `manual-sequential-v2`, khotya tochnyij AGENTS proveryayemogo checkout zadayot `manual-sequential-v1`. Posle ispravleniya otdeljnogo formata kriteriya test doshyol do etogo sravneniya i zavershilsya otkazom.

## Granica povtoreniya

Ozhidaniye testa, chitayusjhego nastoyasjhij repozitorij, otstalo ot kanonicheskogo rezhima etogo repozitoriya. Otdeljnyiye istoricheskiye fiksturyi v1/v2 zadayut sobstvennyiye vkhodyi; ikh versii ne izmenyayutsya. Oshibka spiska kriteriyev otnositsya k otdeljnoj kartochke 0125.

## Proyavleniya

### FUM-SBOJ-0126/PROYAVLENIYE-0001

[Adresnyij zapusk 25](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/25_e65c1e9f-438e-425e-af1b-23882139d210.json) zavershilsya kodom 1 za 1.403242042 s. Chteniye kartochek i prezhnyaya diagnostika proshli; fakticheskij rezuljtat soderzhal `reason=manual-sequential-v1`, a ozhidaniye — `reason=manual-sequential-v2`. [Nablyudeniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-ustarevshego-ozhidaniya.json) sokhranyayet tochnyiye versii, SHA, stroku i iskhodnyij RED.

## Ozhidaniye i klassifikaciya

Ozhidaniye repozitornogo testa sootvetstvuyet tochnomu [AGENTS](../AGENTS.md) etogo checkout i prednaznacheniyu komandyi `show`: vernutj ruchnoj rezhim i sostoyaniye `done`, sokhranyaya zapret istoricheskogo zapuska. Nomer naznachen obsjhim raspredelitelem po sobyitiyu `context-legacy-mode-expectation-01a0930d-red25`.

## Mekhanizm i sistemnoye ustraneniye

V odnom strokovom literale ozhidaniya zamenyon ASCII-simvol `2` na `1`. Runtime, kanonicheskij rezhim i otdeljnyiye v1/v2-fiksturyi sokhranenyi. [Pobajtovoye svideteljstvo](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/proverka-odnobajtovogo-ozhidaniya.json) podtverzhdayet yedinstvennyij izmenyonnyij bajt i sovpadeniye vsekh 1412 obyyavlenij fajla s obsjhim inventaryom. Obsjhaya rannyaya sverka zavisimosti repozitornogo testa ot kanonicheskogo rezhima yesjhyo ne podklyuchena; yeyo granica sokhranena v STEP0174. Kartochka ne razreshayet novoye napravleniye ili istoricheskij avtokonvejyer.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — rannyaya sverka ozhidaniya rezhima po osnovaniyu FUM-SBOJ-0126/PROYAVLENIYE-0001.

## Kriterii zakryitiya

Rannyaya adresnaya proverka vyiyavlyayet rassinkhronizaciyu ozhidaniya realjnogo checkout i kanonicheskogo rezhima do dorogoj proyekcii. Dopustimyij ruchnoj rezhim prokhodit, nepodkhodyasjheye ozhidaniye otvergayetsya; izolirovannyiye istoricheskiye v1/v2-fiksturyi prodolzhayut proveryatj svoi vkhodyi. Yedinichnoye ispravleniye tekusjhego literala samo po sebe ne dokazyivayet podklyucheniye etoj meryi.

## Nablyudayemoye vosstanovleniye

[Povtor 26](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/26_5ef8de0d-1c24-455d-a869-8318c6d2cf82.json) uspeshen: odin test, vneshnij process 1.449292750 s. Usloviye i dannyiye scenariya sokhranenyi; razlichayetsya odin bajt ozhidaniya. Zameryi ne pokazyivayut osnovaniya dlya algoritmicheskoj optimizacii; uskoreniye ne zayavlyayetsya. Polnaya priyomka ostayotsya otdeljnoj rabotoj.

## Istochniki

- [Komanda raspredeleniya i iskhodnyij zapros](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).
- [Otchyot i izmereniya](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/otchyot.md).
- [Test tekusjhego repozitoriya](../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:05:57 MSK -->
<!-- content-sha256: sha256:4f7a5bd21106480454d2376461ce87e7a20bae0b86a04175f941b331d90fac5b -->
<!-- FUM-MD-RECENCY:END -->
