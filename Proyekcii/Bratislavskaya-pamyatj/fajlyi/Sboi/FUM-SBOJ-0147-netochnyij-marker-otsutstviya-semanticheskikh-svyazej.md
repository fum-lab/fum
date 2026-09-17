+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0147"
"статус" = "устранена"
+++
# Netochnyij marker otsutstviya semanticheskikh svyazej

## Nablyudayemyij sboj

Pervonachaljnyij vkhod chipovoj postanovki zamenil tochnuyu stroku otsutstviya semanticheskikh svyazej rasshirennoj formulirovkoj i poyasneniyem. Nastoyasjhij sborsjhik otklonil trebovaniye FUM-REQ-0078: `malformed semantic relation`. Kartochki i iskhodnaya para uzhe byili ustanovlenyi; priyom ostavalsya negotovyim.

## Granica povtoreniya

Odin iskhodnyij priyom s netochnyim libo smeshannyim s poyasneniyem markerom otsutstviya semanticheskikh svyazej schitayetsya odnim proyavleniyem. Eto narusheniye vkhodnogo kontrakta, a ne prezhnyaya nevozmozhnostj vyirazitj pustoj graf iz [0048](FUM-SBOJ-0048-nevozmozhnostj-vyirazitj-trebovaniye-bez-semanticheskikh-svyazej.md) i ne oshibochnaya obratnaya para iz [0058](FUM-SBOJ-0058-oshibochnaya-obratnaya-para-trebovanij-pri-priyome.md). Defekt validatora ne nablyudalsya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                        | Effekt                                              | Vosstanovleniye                                                                                                                                    |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0147/ПРОЯВЛЕНИЕ-0001` | [Pervichnyij otkaz](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/materialyi/otkaz-pervichnogo-priyoma.json) i [nablyudayemyij kod 2](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/materialyi/nablyudeniye-podgotovki-chipov.json). | Priyom negotov; kommit i vneshnyaya popyitka ne sozdanyi. | Shtatnaya yedinstvennaya korrekciya ustanovila tochnyij marker, sokhranila nomera, resheniye, pervonachaljnyij plan i iskhodnuyu paru; nastoyasjhij reyestr sobran. |

## Ozhidaniye i klassifikaciya

Razdel «Semanticheskiye svyazi» pri otsutstvii svyazej soderzhit rovno «Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.». Svyazj so smezhnyim shagom khranitsya vne etogo razdela. Vruchnuyu podgotovlennyij vkhod narushil kanonicheskij kontrakt trebovanij; otkaz sborsjhika pravilen.

## Mekhanizm i ogranichennoye vosstanovleniye

Korenj obyyedinil mashinnuyu deklaraciyu s soderzhateljnyim poyasneniyem. Predusmotrennaya operaciya `исправить-план` proverila sokhranyonnyij pervonachaljnyij otkaz i tochnyij plan, zatem izmenila toljko razreshyonnyiye bajtyi kartochek. Povtornaya podgotovka s novyim vkhodom i oslableniye parsera ne primenyalisj. [Rezuljtat korrekcii](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/materialyi/rezuljtat-ispravleniya-chipov.json) podtverzhdayet `готов=true`, prezhniye FUM-REQ-0078/FUM-STEP-0229 i khyesh `5ea02778111b4a90fcb90709208a66cd44d795c272092f1d4f209e7327923e99`.

## Svyazannyiye shagi

Otdeljnyij STEP ne trebuyetsya dlya uzhe vyipolnennogo ogranichennogo vosstanovleniya sredstvami priyoma 0201. Status otnositsya k proveryayemomu vosstanovleniyu etogo klassa vkhoda; obsjhaya bezoshibochnostj budusjhej podgotovki i vyipolneniye apparatnogo STEP0229 ne zayavlyayutsya.

## Kriterii zakryitiya

Tochnyij marker prinimayetsya nastoyasjhim sborsjhikom, netochnyiye i smeshannyiye variantyi otvergayutsya. Korrekciya sokhranyayet prezhniye identifikatoryi, pervonachaljnyij otkaz i resheniye, a realjnyij priyom vozvrasjhayetsya k gotovnosti do kommita i vneshnego dejstviya. Odnorazovyij korrekcionnyij kontrakt ostayotsya strogim.

## Podtverzhdeniye ustraneniya

Pervichnoye otricateljnoye nablyudeniye i realjnaya uspeshnaya korrekciya sokhranenyi vyishe. [Susjhestvuyusjhij adresnyij nabor](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_pustyiye_svyazi_trebovanij.py) razlichayet tochnyij marker, netochnuyu stroku, povtor i dobavlennoye poyasneniye; yego zapusk i validaciya nastoyasjhego reyestra vkhodyat v obyazateljnuyu adresnuyu proverku [tekusjhego otchyota](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/otchyot.md). Ispolnyayemyij kod pri etom ne izmenyon.

## Istochniki

- [Iskhodnoye porucheniye i oblastj etapa](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/zapros.md).
- [Kontrakt korrekcii](../Instrumentyi/fum-reyestr-planirovaniya/priyom-napravlenij.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:17:19 MSK -->
<!-- content-sha256: sha256:34deea97ebea5059d447969f15b415b498a62951651ac1baad47b7007a077fbd -->
<!-- FUM-MD-RECENCY:END -->
