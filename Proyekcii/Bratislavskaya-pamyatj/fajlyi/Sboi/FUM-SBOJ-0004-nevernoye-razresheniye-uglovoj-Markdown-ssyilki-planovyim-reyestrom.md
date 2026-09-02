+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0004"
"статус" = "активна"
+++
# Nevernoye razresheniye uglovoj Markdown-ssyilki planovyim reyestrom

Kartochka sokhranyayet obnaruzhennoye raskhozhdeniye mashinnogo planovogo reyestra s kanonicheskoj Markdown-ssyilkoj. Ssyilka s probelami, zaklyuchyonnaya v uglovyiye skobki, ukazyivayet iz kartochki shaga na susjhestvuyusjhij fajl, no proizvodnyij reyestr sokhranyayet nesusjhestvuyusjhuyu celj, a sobstvennaya validaciya reyestra prinimayet yeyo.

## Nablyudayemyij sboj

V istochnikakh FUM-STEP-0114 zapisana ssyilka s podpisjyu «pravila razdela voprosov i otvetov» i korrektnoj uglovoj celjyu `<../../Вопросы и ответы/README.md>`. Posle shtatnoj peresborki v dvukh proizvodnyikh predstavleniyakh `source_links` poyavilsya `target` `Планирование/карточки-шагов/Вопросы и ответы/README.md>`, kotorogo v repozitorii net. Shtatnaya komanda validacii mashinnogo planovogo reyestra zavershilasj uspeshno i ne obnaruzhila raskhozhdeniye.

## Granica povtoreniya

Kartochka okhvatyivayet postroyeniye i proverku repozitorno-otnositeljnyikh celej lokaljnyikh Markdown-ssyilok v mashinnom planovom reyestre, kogda adres zaklyuchyon v uglovyiye skobki dlya sokhraneniya probelov v puti.

Syuda ne otnosyatsya vneshniye URL, doslovnyiye istochniki, globaljnaya proverka Markdown-ssyilok vne planovogo reyestra i povrezhdeniya ssyilok s drugoj dokazannoj prichinoj. Odinakovyij nevernyij putj bez obsjhej meryi ispravleniya trebuyet otdeljnoj klassifikacii.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                                                                                                                                                    | Effekt                                                                                                                                                                                          | Vosstanovleniye                                                                                                                                                                                                                           |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0004/ПРОЯВЛЕНИЕ-0001` | [Mashinnyij planovyij reyestr](../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json) soderzhit nesusjhestvuyusjhuyu proizvodnuyu celj dlya korrektnoj ssyilki iz [FUM-STEP-0114](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md), a [otchyot tekusjhej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet uspeshnyij zapusk validatora. | Proizvodnoye proiskhozhdeniye shaga ukazyivayet na otsutstvuyusjhij fajl; potrebitelj `source_links` mozhet ne najti kanonicheskij istochnik, a uspeshnaya validaciya sozdayot lozhnoye svideteljstvo celostnosti. | Kanonicheskaya Markdown-ssyilka ostavlena bez iskazheniya, izvestnoye proyavleniye yavno zafiksirovano etoj kartochkoj, a ispravleniye vyineseno v FUM-STEP-0132. Do yego zaversheniya korrektnostj proizvodnyikh `source_links` ne schitayetsya dokazannoj. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka mashinnoj proizvodnoj pamyati: planovyij reyestr dolzhen vosproizvodimo razreshatj lokaljnuyu ssyilku otnositeljno kartochki i sokhranyatj susjhestvuyusjhuyu repozitorno-otnositeljnuyu celj `Вопросы и ответы/README.md`. Yego validator dolzhen zakryito otklonyatj nesusjhestvuyusjhuyu, registronevernuyu ili vyikhodyasjhuyu za korenj celj vmesto uspeshnogo rezuljtata.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdenyi dva mekhanicheskikh fakta: postroitelj sozdayot celj s nevernoj bazoj i ostatochnyim simvolom `>`, a validator ne proveryayet yeyo susjhestvovaniye kak lokaljnogo puti. Konkretnaya operaciya parsera, kotoraya privodit k takomu rezuljtatu, poka yavlyayetsya gipotezoj i dolzhna byitj ustanovlena krasnoj fiksturoj, a ne utverzhdeniyem etoj kartochki.

Vremennoye sderzhivaniye obespechivayut kanonicheskaya Markdown-ssyilka, globaljnyiye proverki svyaznosti fakticheskikh ssyilok i yavnyij otkaz schitatj `source_links` polnostjyu attestovannyimi. Polnoye ustraneniye trebuyet obsjhego razbora uglovyikh i obyichnyikh lokaljnyikh adresov, tochnogo razresheniya otnositeljno iskhodnogo fajla i zakryitoj proverki proizvodnoj celi.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                      | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------ | ------------------------------- |
| [FUM-STEP-0132 — Ispravitj razresheniye uglovyikh Markdown-ssyilok planovyim reyestrom](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0132-ispravitj-razresheniye-uglovyikh-Markdown-ssyilok-planovyim-reyestrom.md)                 | Vosproizvodit proyavleniye, ispravlyayet postroyeniye celi i zakryito proveryayet yeyo susjhestvovaniye. | `FUM-СБОЙ-0004/ПРОЯВЛЕНИЕ-0001` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj proyavleniya, dopustimogo iskhoda i dvustoronnej svyazi s shagom.         | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Krasnaya fikstura vosproizvodit tochnuyu ssyilku `<../../Вопросы и ответы/README.md>` iz kartochki shaga i poluchayemuyu sejchas nesusjhestvuyusjhuyu celj.
- Postroitelj udalyayet toljko sintaksicheskiye uglovyiye ogranichiteli, razreshayet adres otnositeljno iskhodnoj kartochki i sokhranyayet tochnuyu celj `Вопросы и ответы/README.md`.
- Validnaya obyichnaya zapisj puti s `%20` vmesto probelov i uglovaya zapisj togo zhe lokaljnogo puti s syiryimi probelami dayut odinakovoye mashinnoye predstavleniye bez poteri fragmenta ili znachimyikh simvolov puti.
- Validator zakryito otklonyayet nesusjhestvuyusjhuyu, registronevernuyu, sintaksicheski povrezhdyonnuyu i vyikhodyasjhuyu za korenj lokaljnuyu celj.
- Mashinnyij planovyij reyestr peresobran, regressionnyiye testyi i obsjhij smoke-check prokhodyat, a FUM-STEP-0132 zavershena s dokazateljstvom primenimyikh kriteriyev etoj kartochki.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [mashinnyij planovyij reyestr](../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [kartochka shaga s kanonicheskoj ssyilkoj](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:28:57 MSK -->
<!-- content-sha256: sha256:db059d8d3d516d7801076c6a114228de338e827df3398866db9a791cd63222ff -->
<!-- FUM-MD-RECENCY:END -->
