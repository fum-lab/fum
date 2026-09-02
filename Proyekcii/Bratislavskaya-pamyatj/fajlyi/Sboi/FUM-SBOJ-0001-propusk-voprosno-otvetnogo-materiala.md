+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0001"
"статус" = "активна"
+++
# Propusk voprosno-otvetnogo materiala ob FUM

Kartochka sokhranyayet propusk otdeljnogo materiala `Вопросы и ответы/` posle soderzhateljnogo otveta na pryamoj poljzovateljskij vopros o susjhnosti FUM. Konkretnyij material vosstanovlen, a obyazannostj zakreplena v pravilakh, no kartochka ostayotsya aktivnoj do poyavleniya mashinnoj proverki, sposobnoj obnaruzhitj povtor togo zhe propuska.

## Nablyudayemyij sboj

Doslovnyij vopros `Chto takoye FUM?` poluchil soderzhateljnyij rabochij otvet, no ne byil sokhranyon v otdeljnom svyazannom voprosno-otvetnom materiale. Poljzovatelj ukazal na raneye soglasovannoye ozhidaniye, posle chego propusk byil vosstanovlen v toj zhe kornevoj zadache i papke zaprosa.

## Granica povtoreniya

Kartochka okhvatyivayet otvechennyij doslovnyij poljzovateljskij vopros, kotoryij neposredstvenno otnositsya k prirode, ustrojstvu, svojstvam, principam, modeli, arkhitekture, povedeniyu ili granicam FUM, okanchivayetsya znakom `?`, polezen kak povtorno chitayemaya spravka, no ne poluchayet otdeljnyij svyazannyij material v `Вопросы и ответы/`. Poleznostj, otnosheniye k susjhnosti FUM i soderzhateljnostj otveta proveryayutsya vruchnuyu; tekusjhij vopros proshyol etu smyislovuyu proverku v istochnike proyavleniya.

Syuda ne otnosyatsya sluzhebnyiye voprosyi o repozitorii i instrumentakh, komandyi, nevoprositeljnyiye prosjbyi, otkryityiye protivorechiya bez soderzhateljnogo otveta i voprosno-otvetnyij material s drugoj dokazannoj prichinoj povrezhdeniya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                      | Effekt                                                    | Vosstanovleniye                                                                                                                                                         |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0001/ПРОЯВЛЕНИЕ-0001` | [Poljzovateljskoye ispravleniye i otchyot rabochej sessii](../Zhurnal/2026-08-03_17-01-51_MSK_zakrepitj-sistemnoye-ustraneniye-nedorabotok/otchyot.md) fiksiruyut iskhodnyij propusk i primenimoye ozhidaniye. | Otvet ne voshyol v adresuyemuyu voprosno-otvetnuyu pamyatj FUM. | Sozdan material [«Chto takoye FUM»](<../Voprosyi i otvetyi/2026-08-03_17-01-51_MSK_zakrepitj-sistemnoye-ustraneniye-nedorabotok.md>), a obyazannostj dobavlena v `AGENTS.md`. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka: nablyudayemyij rezuljtat razoshyolsya s yavno ispravlennyim poljzovatelem ozhidaniyem, a dejstvuyusjhiye pravila posle vosstanovleniya trebuyut sokhranyatj kazhdyij podkhodyasjhij vopros i otvet odnovremenno v papke zaprosa i otdeljnom svyazannom materiale. Primenimaya granica zakreplena v [pravilakh rabochikh sessij](../AGENTS.md) i [pravilakh razdela voprosov i otvetov](<../Voprosyi i otvetyi/README.md>).

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon normativnyij probel prezhnego pravila: ono opisyivalo dopustimostj voprosno-otvetnogo materiala, no ne pryamuyu obyazannostj sozdatj yego. Pravilo i konkretnyij propusk ispravlenyi. Ostatochnyij mekhanizm povtoreniya — otsutstviye zakryitoj avtomaticheskoj sverki doslovnyikh otvechennyikh voprosov s otdeljnyimi materialami i ikh obratnyimi ssyilkami.

Vremennoye sderzhivaniye obespechivayut pryamoye pravilo rabochej sessii, audit pokryitiya i globaljnaya proverka obratnyikh ssyilok. Polnoye sistemnoye ustraneniye trebuyet mashinno proveryayemogo kontura kartochek sboyev i regressionnoj fiksturyi tochnogo propusjhennogo voprosa v obsjhem smoke-check.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                                  | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ------------------------------- |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Predotvrasjhayet povtor, validiruyet dopustimyij iskhod kartochki i proveryayet regressiyu propusjhennogo voprosa. | `FUM-СБОЙ-0001/ПРОЯВЛЕНИЕ-0001` |

## Kriterii zakryitiya

- Lokaljnaya avtomatizaciya zakryito proveryayet indeks i obyazateljnyiye polya kartochek sboyev, ikh proyavleniya, dopustimyij iskhod i dvustoronniye svyazi s aktualjnyimi shagami.
- Regressionnaya fikstura obnaruzhivayet otvechennyij vopros o susjhnosti FUM bez otdeljnogo svyazannogo materiala i prinimayet tot zhe sluchaj posle sozdaniya materiala.
- Proverka vklyuchena v obsjhij smoke-check i rabotayet bez seti i sekretov.
- FUM-STEP-0114 zavershena, a dokazateljstvo vyipolneniya yeyo primenimyikh kriteriyev svyazano s etoj kartochkoj.

## Istochniki

- [iskhodnyij zapros o sistemnom ustranenii nedorabotok](../Zhurnal/2026-08-03_17-01-51_MSK_zakrepitj-sistemnoye-ustraneniye-nedorabotok/zapros.md)
- [otchyot o propuske i yego lokaljnom vosstanovlenii](../Zhurnal/2026-08-03_17-01-51_MSK_zakrepitj-sistemnoye-ustraneniye-nedorabotok/otchyot.md)
- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:00:56 MSK -->
<!-- content-sha256: sha256:cd04b245acae85d323eb4a45fec0190f2b82d0636a476f5bb5cc05ee09eae7db -->
<!-- FUM-MD-RECENCY:END -->
