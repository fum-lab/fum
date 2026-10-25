# Otchyot 2026-09-22 00:49:32 MSK - Vyipolnitj polnuyu proverku priyomki

Polnaya priyomochnaya proverka vyipolnena na izmenyonnom soderzhateljnom snimke posle ispravleniya recency i osvobozhdeniya vremennyikh Git-dannyikh. Finaljnyij zapusk `f863062b-55af-4b74-8b50-715353bfd7db` zavershyon uspeshno: vse 23 shaga proshli za 1 568,659 s. Dva prezhnikh otkaza sokhranenyi: `b8578d73-6fb7-495d-a549-6a7364085aba` ostanovilsya na ustarevshej recency-metke, a `b2b088ee-c5c3-4b80-9df4-bb6fbacdcf6b` zavershilsya bez sokhranyonnogo vremeni iz-za `No space left on device` posle 16 iz 23 shagov.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                           |
| ------------------------ | ------------ | ---------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | V etoj sessii otdeljnogo FIFO-ozhidaniya ne byilo       |
| Soderzhateljnaya rabota    | ne izmereno  | Podgotovka i povtor polnogo progona; otdeljnyiye granicyi ne izmeryalisj |
| Celevyiye proverki         | 85,551 s + 0 s | Dva neuspeshnyikh polnyikh zapuska sokhranenyi kak istoriya otkazov |
| Polnyij smoke-check       | 1 568,659 s  | Obyortka otchyotov, UUID `f863062b-55af-4b74-8b50-715353bfd7db` |
| Atomarnyij commit+handoff | ne izmereno  | Peredacha i kommit budut otdeljnyim etapom posle zakryitiya otchyota |

Granica profilya: ot zapuska polnoj proverki do uspeshnogo zaversheniya smoke-check; kommit i peredacha v etot interval ne vkhodyat.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:1aae0f163ad900986392f1e55f9b09be74520d1f4b9dfc10b870f8c4d60bc84e -->

| Vyizov                                                                                  | Dliteljnostj | Rezuljtat                                                                                                                                                    |
| -------------------------------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [FUM Pisatelj] Polnyij dokumentacionnyij smoke-check dlya zakryitoj priyomki                | 85,551 s     | neuspeshno — Polnyij smoke-check ostanovilsya na proverke recency: pered povtorom trebovalosj obnovitj proizvodnyij indeks.                                      |
| [FUM Pisatelj] Povtoritj polnyij dokumentacionnyij smoke-check posle ispravleniya recency | 0 s          | ne zaversheno — No space left on device na shage otchyotnoj obyortki posle 16 iz 23 proverok; obyortka ne smogla sokhranitj izmerennoye vremya i terminaljnyij snimok. |
| [FUM Pisatelj] Polnyij dokumentacionnyij smoke-check posle ochistki vremennyikh Git-dannyikh  | 1568,659 s   | uspeshno                                                                                                                                                      |

Obsjheye vremya pryamyikh zapuskov proverok: 1654,21 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Shag 5 «Primeneniye bratislavskoj proyekcii pamyati»: 12 011 vkhodnyikh i 12 011 celevyikh fajlov, 362,529 s.
- Shag 6 «Proverka bratislavskoj proyekcii pamyati»: manifest dejstvitelen, 160,111 s.
- Shag 11: 215 testov, `OK`, 165,337 s.
- Shag 17: 204 testa otchyotnoj obyortki, `OK`, 81,759 s.
- Shag 20: 361 test planovogo reyestra, `OK`, 457,422 s.
- Shag 23: 513 testov svyaznosti rabochej sessii, `OK`, 236,411 s.
- Ostaljnyiye 17 shagov takzhe zavershilisj uspeshno; itogovyij kod smoke-check — 0.

## Resheniya i ogranicheniya

- Vremya vtorogo otkaza ne byilo vosstanovleno: zapisj yavno pomechena `не завершено`, `125`, `0 нс`, s ukazaniyem prichinyi; eto ne schitayetsya uspeshnyim svideteljstvom.
- Iz sluzhebnogo repozitoriya Codex udalenyi toljko 1 488 nezanyatyikh `tmp_pack_*` (okolo 604,35 GiB); zhurnalyi FUM, rabochiye derevjya i Git-istoriya ne udalyalisj.
- Uspeshnyij polnyij progon podtverzhdayet dokumentacionnyij i priyomochnyij kontur planovogo rezuljtata. On ne podtverzhdayet vyipolneniye sleduyusjhej rabotyi `FUMA-НАБЛЮДЕНИЕ`, integraciyu v `master` ili native runtime.
- Posle zakryitiya etogo otchyota nuzhno obnovitj zapisj priyomki tochnyim kommitom i UUID finaljnogo zapuska.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [otkaz recency](materialyi/zapuski-proverok/1_b8578d73-6fb7-495d-a549-6a7364085aba.json)
- [otkaz iz-za mesta](materialyi/zapuski-proverok/2_b2b088ee-c5c3-4b80-9df4-bb6fbacdcf6b.json)
- [finaljnyij zapusk](materialyi/zapuski-proverok/3_f863062b-55af-4b74-8b50-715353bfd7db.json)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-22 00:52:03 MSK -->
<!-- content-sha256: sha256:4bfedfb7001e20d05895687d995b971af963fecd01c1d67c9b12b0f128ef8320 -->
<!-- FUM-MD-RECENCY:END -->
