+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0002"
"статус" = "снята"
+++
# Samovoljnaya otmena ozhidayusjhego FIFO-bileta

Ekspluatacionnyij status: kartochka snyata iz dejstvuyusjhego kontura, potomu chto ruchnaya posledovateljnaya skhema ne sozdayot FIFO-biletyi i ne vyipolnyayet avtomaticheskoye ozhidaniye. Opisaniye proyavleniya, mekhanizma i kriteriyev nizhe sokhranyayetsya kak istoricheskoye svideteljstvo i usloviye vozmozhnogo budusjhego vozvrata ocheredi, no ne predpisyivayet dejstviya tekusjhej sessii.

Kartochka sokhranyayet oshibochnuyu otmenu bessrochnogo ozhidayusjhego FIFO-bileta posle prodolzhiteljnogo shtatnogo sostoyaniya `waiting`. Ocheredj sokhranila celostnostj, odnako resheniye modeli zavershilo ozhidaniye bez poljzovateljskogo signala prekrasjheniya zadachi; sistemnoye host-ograzhdeniye yesjhyo ne realizovano.

## Nablyudayemyij sboj

Posle dliteljnogo neizmennogo `waiting` kornevoj agent otmenil sobstvennyij ozhidayusjhij bilet i obyyavil zadachu zablokirovannoj vmesto prodolzheniya ozhidaniya. Poljzovatelj yavno ispravil eto resheniye i potreboval sozdatj kartochku obnaruzhennoj problemyi.

## Granica povtoreniya

Kartochka okhvatyivayet otmenu ozhidayusjhego FIFO-bileta libo obyyavleniye zadachi zablokirovannoj toljko iz-za dliteljnosti ozhidaniya, chisla oprosov, vozvrata upravleniya modeli, nekhvatki konteksta ili otsutstviya vidimogo progressa.

Syuda ne otnosyatsya yavnaya otmena poljzovatelem prekrasjhyonnoj ili zamenyonnoj zadachi, fail-closed-otkaz ocheredi, narusheniye celostnosti FIFO, shtatnyij `reload_required`, a takzhe setevoj razryiv, posle kotorogo tot zhe bilet sokhranyayetsya i ozhidaniye shtatno prodolzhayetsya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                        | Effekt                                                                | Vosstanovleniye                                                                                                                                                                       |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0002/ПРОЯВЛЕНИЕ-0001` | [Otchyot rabochej sessii 2026-08-05](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/otchyot.md) fiksiruyet otmenu, poljzovateljskoye ispravleniye i mekhanizm riska. | Poteryana FIFO-poziciya; zadacha zavershila khod vmesto shtatnogo ozhidaniya. | Zadacha povtorno zaregistrirovalasj, dozhdalasj dopuska i sozdala [FUM-STEP-0130](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0130-ograditj-ozhidaniye-FIFO-ot-otmenyi-po-dliteljnosti.md). |

## Ozhidaniye i klassifikaciya

Eto nedorabotka: dejstvuyusjhij kontrakt ocheredi uzhe isklyuchal TTL i predpisyival zhdatj do dejstvennogo sostoyaniya. Dliteljnostj i neizmennoye `waiting` ne yavlyayutsya osnovaniyem blokirovki ili otmenyi. Poljzovateljskoye ispravleniye sokhraneno doslovno v [iskhodnom zaprose proyavleniya](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/zapros.md).

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon razryiv vyishe celostnoj ocheredi: posle host-vozvrata, vosstanovleniya konteksta ili szhatiya istorii resheniye snova prinimayet modelj, a dostupnaya komanda `cancel` prinimayet izvestnyiye identifikatoryi i ne trebuyet dokazateljstva yavnogo prekrasjheniya zadachi. Besshumnyij `wait-until-actionable` umenjshayet chislo takikh granic, no ne ograzhdayet sam putj otmenyi.

Vremennoye sderzhivaniye dayut bessrochnyij bilet, idempotentnyij `join`, pryamoj zapret schitatj `waiting` blokirovkoj i sokhraneniye pozicii pri preryivanii. Polnoye ustraneniye trebuyet mashinnogo vladeljca ozhidaniya i privilegirovannogo fail-closed-podtverzhdeniya zakonnoj otmenyi.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                              | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0130 — Ograditj ozhidaniye FIFO ot otmenyi po dliteljnosti](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0130-ograditj-ozhidaniye-FIFO-ot-otmenyi-po-dliteljnosti.md)                                             | Predotvrasjhayet samovoljnuyu otmenu, proveryayet vosstanovleniye i sokhranyayet yavnyij putj zakonnoj otmenyi. | `FUM-СБОЙ-0002/ПРОЯВЛЕНИЕ-0001` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet, chto aktivnyij sboj ne teryayet svyazannyij shag i dopustimyij iskhod.                           | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Obyichnyij modeljnyij putj ne mozhet snyatj ozhidayusjhij bilet iz-za vremeni, chisla oprosov, otsutstviya progressa ili nekhvatki konteksta.
- Zakonnaya otmena trebuyet aktualjnoye host-podtverzhdeniye prekrasjheniya libo zamenyi tochnoj zadachi i ne zatragivayet drugiye biletyi.
- Avtonomnyij scenarij proveryayet neizmennoye ozhidaniye, preryivaniye, vosstanovleniye, poddeljnoye podtverzhdeniye i gonku otmenyi s dopuskom.
- Zhivaya dvukhzadachnaya priyomka prokhodit neskoljko host-granic, sokhranyayet bilet i zavershayetsya shtatnyim dopuskom.
- FUM-STEP-0130 zavershena, a dokazateljstvo yeyo primenimyikh kriteriyev svyazano s etoj kartochkoj.

## Istochniki

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros proyavleniya](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/zapros.md)
- [otchyot o proyavlenii i vyibrannom prodolzhenii](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/otchyot.md)
- [istoriya ustraneniya kholostyikh vozvratov modeli](../Zhurnal/2026-07-22_14-53-29_MSK_ustranitj-kholostyiye-vozvratyi-ozhidaniya-ocheredi/otchyot.md)
- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:57:35 MSK -->
<!-- content-sha256: sha256:a2b66846afd4812a24c44403fa511a82b2b044c0e9e2a0f007f17bb5cb00f4cc -->
<!-- FUM-MD-RECENCY:END -->
