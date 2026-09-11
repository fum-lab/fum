+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0050"
"статус" = "активна"
+++
# Vyideleniye globaljnogo identifikatora iz lokaljnogo maksimuma

## Nablyudayemyij sboj

Pri paralleljnom planirovanii nomer kartochki byil vyibran iz sostoyaniya sobstvennogo checkout bez podtverzhdeniya zanyatosti v drugikh aktivnyikh vetkakh. Dva razlichnyikh sboya poluchili FUM-SBOJ-0046. Zatem lokaljnaya ocenka svobodnogo 0047 ne uchla opublikovannuyu kartochku zadachi fuma. Koordinator obnaruzhil oba raskhozhdeniya do obsjhej integracii.

## Proyavleniya

| Lokaljnyij nomer               | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                     | Effekt                                                                                                  | Vosstanovleniye                                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| FUM-SBOJ-0050/PROYAVLENIYE-0001 | Snimok `68996460643a50d47cfc6e121b34cc0911639f26` soderzhit 0046 o dopisyivanii JSONL; kommit planirovaniya `0246844fe15ba51e48327005b33bc78b668f813a` soderzhit 0046 o pustyikh semanticheskikh svyazyakh. [Sverka istochnikov](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/otchyot.md). | Nomer odnogo semejstva oboznachayet raznyiye susjhnosti v vetkakh, prednaznachennyikh k posleduyusjhej integracii.   | Koordinator soglasoval perenos parsernoj kartochki v 0048 s sokhraneniyem prezhnego ID i kommita.                      |
| FUM-SBOJ-0050/PROYAVLENIYE-0002 | Posle prosmotra svoyej vetki korenj planirovaniya predlozhil 0047 dlya drugoj zadachi. Snimok `a16976d8a5dcac2710340f752134b595e1de1331` uzhe soderzhit 0047 o committer. [Koordinacionnyiye soobsjheniya](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/zapros.md).                      | Peredano nevernoye utverzhdeniye o svobode nomera; povtornaya kartochka pod 0047 po etomu sovetu ne sozdana. | Koordinator ostanovil naznacheniye i zakrepil neperesekayusjhiyesya rezervyi; sleduyusjhij shag 0198 svyazyivayet oba proyavleniya. |

## Mekhanizm i granica

Gipoteza obsjhego mekhanizma podtverzhdayetsya sposobom obeikh ocenok: lokaljnoye otsutstviye nomera oshibochno byilo prinyato za otsutstviye v obsjhem prostranstve. Odinakovyij identifikator susjhnosti dolzhen sokhranyatjsya mezhdu nezavisimyimi vetkami, a razlichnyiye susjhnosti odnogo semejstva dolzhnyi imetj raznyiye ID. Problema otnositsya k koordinacii vyideleniya, a ne k rabote parsera trebovanij, chitatelya JSONL ili dannyim Git committer.

Susjhestvuyusjhiye kartochki drugikh mekhanizmov ne dayut obsjhej meryi i regressionnoj granicyi dlya mezhvetochnogo vyideleniya. Tekusjhaya oblastj — soglasovannyiye paralleljnyiye vetki i sokhranyonnyiye rezervyi FUM; ona ne obyyavlyayet universaljnyij globaljnyij reyestr vsekh klonov.

## Vosstanovleniye

Obyichnyij posleduyusjhij kommit perenosit parsernuyu kartochku 0046 v 0048, soglasovanno obnovlyayet tekusjhij ID i zhivyiye ssyilki i sokhranyayet istoricheskij ID, pervyij kommit i prichinu perekhoda. Chuzhiye kartochki 0046 i 0047, refs i opublikovannaya istoriya ne perepisyivayutsya. Kolliziya ne yavlyayetsya novyim proyavleniyem samogo parsernogo sboya.

Ruchnoye soglasovaniye tekusjhikh rezervov vosstanavlivayet vozmozhnostj prodolzhatj seriyu, no ne ustranyayet mekhanizm sleduyusjhego konkurentnogo naznacheniya.

## Svyazannyiye shagi

- [FUM-STEP-0198 — mezhvetochnaya sverka i vyideleniye](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0198-proveritj-i-soglasovatj-mezhvetochnoye-vyideleniye-identifikatorov.md), osnovaniye — oba lokaljnyikh proyavleniya 0001 i 0002.

## Kriterii zakryitiya

Proverennyij sposob chteniya polnoj obyyavlennoj mezhvetochnoj oblasti i soglasovannogo vyideleniya obnaruzhivayet oba sokhranyonnyikh proyavleniya, isklyuchayet konkuriruyusjhiye uspeshnyiye rezervyi odnogo nomera i ne obyyavlyayet nomer svobodnyim pri nedostupnom libo izmenivshemsya vkhode. Tochnyiye kriterii realizacii i proverki nakhodyatsya v svyazannom shage; odin perenos 0046→0048 ne zakryivayet 0050.

## Istochniki

- [Porucheniye i koordinaciya](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/zapros.md).
- [Otchyot proverki fakticheskikh snimkov](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/otchyot.md).
- [Indeks sboyev](README.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:02:09 MSK -->
<!-- content-sha256: sha256:c5af23b57056682d3cdfd42bc32b7787a9e972dd293e895ece4327d2b54b51a2 -->
<!-- FUM-MD-RECENCY:END -->
