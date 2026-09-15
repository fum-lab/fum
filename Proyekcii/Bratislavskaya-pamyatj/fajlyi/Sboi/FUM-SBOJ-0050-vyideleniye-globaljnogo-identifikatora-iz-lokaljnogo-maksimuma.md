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
| FUM-SBOJ-0050/PROYAVLENIYE-0003 | V HEAD4dd5a7f33913b17f705e512be1826314da89a4c4 kartochka0009 imela0001–0004; novyij epizod byil vremenno nazvan0005. Snimok6bf2f53fc76069b02ba1eae3ed31235716f0f1cd uzhe soderzhit0001–0016. [Sverka i rezerv](https://github.com/fum-lab/fum/blob/8d89a695d6f099091a13d3ce60c924c7098105f2/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_13-30-58_MSK_%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%B8%D1%82%D1%8C-%D0%BF%D0%BE%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D1%83-Windows-VM-%D0%BD%D0%B0-macOS/%D0%BC%D0%B0%D1%82%D0%B5%D1%80%D0%B8%D0%B0%D0%BB%D1%8B/%D0%BA%D0%BE%D0%BE%D1%80%D0%B4%D0%B8%D0%BD%D0%B0%D1%86%D0%B8%D1%8F-%D0%BD%D0%BE%D0%BC%D0%B5%D1%80%D0%B0-%D0%BF%D1%80%D0%BE%D1%8F%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F.json); [istoriya epizoda](https://github.com/fum-lab/fum/blob/8d89a695d6f099091a13d3ce60c924c7098105f2/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_13-30-58_MSK_%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%B8%D1%82%D1%8C-%D0%BF%D0%BE%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D1%83-Windows-VM-%D0%BD%D0%B0-macOS/%D0%BC%D0%B0%D1%82%D0%B5%D1%80%D0%B8%D0%B0%D0%BB%D1%8B/%D0%BD%D0%B0%D0%B1%D0%BB%D1%8E%D0%B4%D0%B5%D0%BD%D0%B8%D0%B5-%D0%BF%D0%BE%D0%B2%D1%82%D0%BE%D1%80%D0%B0-0009.json). | Odna sostavnaya identichnostj0009/0005 stala oboznachatj raznyiye epizodyi; kolliziya obnaruzhena do kommita i publikacii novogo nablyudeniya. | Posle sverki50rabochikh derevjyev i soglasovaniya vladeljcev koordinator zakrepil0009/0017. Vse prezhniye0001–0016, iskhodnyijOID i istoriya vremennogo nomera sokhranenyi; STEP0198 dopolnen. |

### FUM-SBOJ-0050/PROYAVLENIYE-0004

Pri podgotovke arkhivnogo etapa sobstvennyij nekommichennyij chernovik poteri abzaca poluchil nomer 0091 iz lokaljnogo maksimuma. Koordinator soobsjhil o chuzhom rezerve 0091; pisatelj podtverdil yego chteniyem obsjhego sostoyaniya. [Kvitanciya i granica vosstanovleniya](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/materialyi/rezerv-sboya.json) svyazyivayut zanyatyij nomer, sobyitiye vyidachi sobstvennogo 0106 i tochnuyu bazu. Predvariteljnaya kartochka ne kommitilasj i ne publikovalasj; ispravlenyi toljko sobstvennyij chernovik i zhivyiye ssyilki.

Lokaljnoye proyavleniye 0003 uzhe zanyato drugoj vetkoj: pri read-only-sverke obnaruzhena kartochka v refs/heads/planirovaniye na 8d89a695d6f099091a13d3ce60c924c7098105f2, blob 3c6169629780dd0a4d8d1cc6b46ef553c9d15b27. Gotovaya stroka proyavleniya 0003 perenesena s sokhraneniyem teksta i zamenoj dvukh otsutstvuyusjhikh lokaljnyikh ssyilok tochnyimi ssyilkami na tot zhe kommit; [proiskhozhdeniye perenosa](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/materialyi/proiskhozhdeniye-proyavleniya-0050-0003.json) sokhranyayet obe formyi i khyeshi istochnikov. Prezhniye proyavleniya 0001 i 0002 ne perepisanyi. Dlya novogo nablyudeniya 0004 proverenyi dostupnyiye vetki i derevjya; nomer [podtverzhdyon koordinatorom](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/materialyi/koordinaciya-proyavleniya-0050-0004.json). Vosstanovleniye cherez susjhestvuyusjhij raspredelitelj ne dokazyivayet nevozmozhnosti povtornogo ruchnogo obkhoda, poetomu sboj ostayotsya aktivnyim.

## Mekhanizm i granica

Gipoteza obsjhego mekhanizma podtverzhdayetsya sposobom obeikh ocenok: lokaljnoye otsutstviye nomera oshibochno byilo prinyato za otsutstviye v obsjhem prostranstve. Odinakovyij identifikator susjhnosti dolzhen sokhranyatjsya mezhdu nezavisimyimi vetkami, a razlichnyiye susjhnosti odnogo semejstva dolzhnyi imetj raznyiye ID. Problema otnositsya k koordinacii vyideleniya, a ne k rabote parsera trebovanij, chitatelya JSONL ili dannyim Git committer.

Susjhestvuyusjhiye kartochki drugikh mekhanizmov ne dayut obsjhej meryi i regressionnoj granicyi dlya mezhvetochnogo vyideleniya. Tekusjhaya oblastj — soglasovannyiye paralleljnyiye vetki i sokhranyonnyiye rezervyi FUM; ona ne obyyavlyayet universaljnyij globaljnyij reyestr vsekh klonov.

## Vosstanovleniye

Obyichnyij posleduyusjhij kommit perenosit parsernuyu kartochku 0046 v 0048, soglasovanno obnovlyayet tekusjhij ID i zhivyiye ssyilki i sokhranyayet istoricheskij ID, pervyij kommit i prichinu perekhoda. Chuzhiye kartochki 0046 i 0047, refs i opublikovannaya istoriya ne perepisyivayutsya. Kolliziya ne yavlyayetsya novyim proyavleniyem samogo parsernogo sboya.

Ruchnoye soglasovaniye tekusjhikh rezervov vosstanavlivayet vozmozhnostj prodolzhatj seriyu, no ne ustranyayet mekhanizm sleduyusjhego konkurentnogo naznacheniya.

## Svyazannyiye shagi

- [FUM-STEP-0198 — mezhvetochnaya sverka i vyideleniye](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0198-proveritj-i-soglasovatj-mezhvetochnoye-vyideleniye-identifikatorov.md), osnovaniya — lokaljnyiye proyavleniya 0001, 0002, 0003 i 0004; posledneye utochnyayet granicu ruchnogo obkhoda susjhestvuyusjhego raspredelitelya.

## Kriterii zakryitiya

Proverennyij sposob chteniya polnoj obyyavlennoj mezhvetochnoj oblasti i soglasovannogo vyideleniya obnaruzhivayet sokhranyonnyiye proyavleniya 0001–0004, vklyuchaya sostavnyiye nomera i ruchnoj obkhod susjhestvuyusjhego raspredelitelya, isklyuchayet konkuriruyusjhiye uspeshnyiye rezervyi odnogo nomera i ne obyyavlyayet nomer svobodnyim pri nedostupnom libo izmenivshemsya vkhode. Tochnyiye kriterii realizacii i proverki nakhodyatsya v svyazannom shage; odin perenos 0046→0048 ne zakryivayet 0050.

## Istochniki

- [Oshibka lokaljnogo vyibora 0091 i vosstanovleniye cherez obsjhij rezerv](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/otchyot.md) — FUM-SBOJ-0050/PROYAVLENIYE-0004.

- [Porucheniye i koordinaciya](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/zapros.md).
- [Otchyot proverki fakticheskikh snimkov](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/otchyot.md).
- [Indeks sboyev](README.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 02:51:59 MSK -->
<!-- content-sha256: sha256:8579e4649c8b3be31ba636617e6291537639936d7e918dd813d645e92e230d1d -->
<!-- FUM-MD-RECENCY:END -->
