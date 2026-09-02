+++
schema_version = 1
card_id = "FUM-STEP-0074"
status = "completed"
+++
# Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj [bezokonnyij Swift-prototip](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md): sokhranyatj atomarnyiye pokoleniya pamyati i prodolzhatj obrabotku posle perezapuska, proveryatj skhodimostj inkrementaljnogo puti s polnyim replay i vyivoditj iz prinyatoj pamyati inertnuyu deklarativnuyu modelj predstavleniya. Realjnyij renderer i ispolneniye porozhdyonnogo koda v shag ne vkhodyat.

## Rezuljtat

[Bezokonnyij Swift-prototip](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) sokhranyayet kanonicheskiye neizmenyayemyiye pokoleniya s versiyami skhemyi i politiki, ssyilkoj na predyidusjheye pokoleniye, khyeshem vkhodov, snimkom, trassoj, inertnoj modeljyu predstavleniya i dostatochnyim proiskhozhdeniyem. Novyij fajl pokoleniya podgotavlivayetsya do atomarnoj zamenyi `CURRENT`; nesovmestimyij, povrezhdyonnyij ili prervannyij kandidat ne smesjhayet posledneye podtverzhdyonnoye sostoyaniye.

Otdeljnyiye zapuski `bootstrap`, `continue` i `show` podtverzhdayut vosstanovleniye posle perezapuska. Avtonomnaya fikstura dokazyivayet kanonicheskuyu skhodimostj polnogo replay i prodolzheniya po snimku, trasse i modeli predstavleniya, proiskhozhdeniye elementa `memory.next-stage`, a takzhe preobrazovaniye dopustimogo namereniya `remember` obratno v programmu sobyitij s versiyami skhemyi i politiki.

Modelj predstavleniya vyivoditsya toljko iz prinyatogo snimka operatorom `fum.view-projection.operator.v1`, ostayotsya `headless` i ne soderzhit polya ispolnyayemogo koda. Renderer, SwiftUI, ispolneniye porozhdyonnogo Swift-koda i utverzhdeniye o zhiznesposobnom GUI ne dobavlenyi; [otkryityij vopros o granice GUI](../../Voprosyi/2026-07-24_10-44-28_MSK_granica-GUI-iz-vnutrennikh-mekhanizmov-FUM.md) ostayotsya dejstvuyusjhim.

## Istochniki

- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [pasport nachaljnogo korobochnogo prototipa FUM](../../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)
- [trebovaniye FUM-REQ-0020](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [trebovaniye FUM-REQ-0021](../../Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2c0ff67526cf6d829d6f2397c432ee03543643a47c64634ca570287a982fed84 -->
<!-- FUM-MD-RECENCY:END -->
