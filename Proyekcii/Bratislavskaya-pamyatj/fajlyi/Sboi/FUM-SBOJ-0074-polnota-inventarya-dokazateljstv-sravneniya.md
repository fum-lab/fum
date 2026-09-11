+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0074"
"статус" = "устранена"
+++
# Nepolnyij inventarj dokazateljstv sravneniya

Ustraneniye ogranicheno yavno proverennyim konturom sravneniya dekodirovaniya. Nomer vyidelen koordinatorom posle sverki integracionnogo dereva i rezervov, chto sokhraneno v [iskhodnom zaprose](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/zapros.md).

## Nablyudayemyij sboj

Pervonachaljnyij proveryayusjhij prinimal pustoj ili nepolnyij nabor khyeshej i 24 kopii odnogo vernogo itoga. Na tom zhe etape adresnaya obyortka yazyikovogo inventarya poluchila nolj fajlov iz-za ekranirovannyikh kirillicheskikh putej Git i oshibochno vyiglyadela uspeshnoj. Realjnyij raw ne byil podmenyon; nepolnyim okazalosj usloviye dokazateljstva.

## Granica povtoreniya

Komplektnostj svideteljstva dannogo sravneniya: tochnyij nabor 21 iskhodnika, 24 unikaljnyikh itoga protiv 48 grupp po 9 paketov i nepustoj adresnyij spisok izmenyonnyikh iskhodnikov. Raznyiye chastnyiye prichinyi obyyedinenyi odnoj granicej: proveryayusjhij ne vprave soobsjhatj uspekh do podtverzhdeniya polnogo vkhodnogo inventarya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                         | Effekt                                                | Vosstanovleniye                 |
| ------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------ |
| `FUM-СБОЙ-0074/ПРОЯВЛЕНИЕ-0001` | [Otchyot i pryamyiye zapuski](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/otchyot.md) | Finaljnaya priyomka otlozhena do adresnogo podtverzhdeniya | Ogranichennaya mera i GREEN nizhe |

## Mekhanizm i ogranichennoye vosstanovleniye

Kvantifikaciya toljko po imeyusjhimsya elementam pozvolyala pustoj libo povtornyij domen. Pervoye usileniye vsyo yesjhyo vyivodilo sostav iz proveryayemogo kataloga: pri odnovremennoj potere fajla i yego zapisi domen suzhalsya nezametno. Eto dopolniteljnaya lokalizaciya togo zhe nezakonchennogo dopuska dannogo proyavleniya. Okonchateljnyij proveryayusjhij zakreplyayet nezavisimyij konechnyij perechenj 21 puti i otdeljno sveryayet s nim kvitanciyu i katalog, zatem khyeshi. Testovaya kopiya stroitsya iz polnyikh Sources/Tests, nezavisimo ot proveryayemoj kvitancii. Unikaljnyiye klyuchi itogov i polnoye pokryitiye grupp takzhe obyazateljnyi. Adresnaya vyiborka Git ispoljzuyet NUL-razdelyonnyiye puti i otklonyayet pustoj/nepolnyij nabor; poluchenyi vosemj fakticheskikh fajlov. Rezuljtat pervogo nulevogo okhvata otozvan kak yazyikovoj dopusk.

## Kriterii zakryitiya

Semj adresnyikh testov otklonyayut podmenyi proiskhozhdeniya, medianyi, poteryu paryi, povtoryi itogov i odnovremennuyu poteryu iskhodnika i zapisi; podlinnyij raw polnostjyu pereschityivayetsya. Adresnyij inventarj imeyet dokazanno nepustoj sostav. Pereimenovannyij test razlichayetsya s izmerennyim snimkom; yego iskhodnyiye bajtyi ne udalenyi iz kvitancii.

## Podtverzhdeniye ustraneniya

RED № 16 vosproizvyol obkhodyi, GREEN № 17 vyipolnil shestj testov, № 18 pereschital vse ryadyi. № 19 obnaruzhil vosemj fajlov cherez NUL-puti. Posle ispravleniya imeni testa sokhranyon iskhodnyij snimok; № 21 podtverdil strogij otkaz na tekusjhem otlichayusjhemsya teste, № 22–23 proverili vosstanovlennyiye 21 iskhodnik i vse itogi. Kolichestvo 72 diagnosticheskikh profilej proveryayetsya otdeljno ot ikh soderzhateljnoj metodiki. Finaljnaya priyomka postavki ostayotsya otdeljnoj granicej i etim lokaljnyim statusom ne podmenyayetsya.

Dopolniteljnyij RED № 29 vosproizvyol sovmestnuyu poteryu iskhodnika i zapisi; GREEN № 30 vyipolnil semj testov. № 31 povtorno proveril neizmenyonnyiye 432 paketa, 24 itoga i nezavisimyij sostav 21 iskhodnika. [Profilj okonchateljnoj meryi](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/materialyi/profilj-nezavisimogo-inventarya.json) fiksiruyet pyatj vyizovov s medianoj 2,326 ms; dopolniteljnaya optimizaciya ne obosnovana.

## Istochniki

- [Komanda i utochneniya](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/zapros.md).
- [Rukovodstvo sravneniya](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/sravneniye-dekodirovaniya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 13:02:34 MSK -->
<!-- content-sha256: sha256:e71a4c158b6cf759640f3fd2e8269c0c14810dabf47aed9b7f39aefee228f392 -->
<!-- FUM-MD-RECENCY:END -->
