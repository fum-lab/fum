# FUM-MAP-AUTO-01: Lokaljnyiye avtomatizacii FUM

Eta kartochka fiksiruyet lokaljnyiye avtomatizacii FUM kak ispolnyayemyij sloj pamyati. Avtomatizaciya prevrasjhayet povtoryayemuyu proceduru v proveryayemyij organ dejstviya ili vospriyatiya: u neyo yestj vkhodyi, komanda zapuska, testyi, nablyudayemyij rezuljtat i granica primenimosti.

## Kartochka

- Identifikator: `FUM-MAP-AUTO-01`.
- Obyyekt sopostavleniya: lokaljnyiye avtomatizacii FUM.
- Sloj: ispolnyayemyij sloj pamyati.
- Nablyudatelj: agent rabochej sessii, soprovozhdayusjhij repozitorij chelovek i budusjhij FUM-uzel, sposobnyij zapuskatj lokaljnyiye proverki.
- Sootvetstviye obsjhej skheme: skript vyipolnyayet dejstviye, test fiksiruyet ozhidayemoye povedeniye, fixture zadayot nablyudayemuyu sredu, proverka vyipolnyayet otbor, sluzhebnyiye sledyi vrode `FUM-MD-RECENCY` svyazyivayut rezuljtat s sostoyaniyem pamyati.
- Sokhranyayemyiye invariantyi: procedura povtoryayema lokaljno bez sekretov po umolchaniyu, povedeniye opisano, rezuljtat proveryayem, izmeneniya prokhodyat cherez TDD pri razvitii avtomatizacii.
- Poteri nablyudayemosti: avtomatizaciya vidit toljko formalizovannyiye vkhodyi i ne zamenyayet smyislovuyu otvetstvennostj rabochej sessii; vneshniye servisyi i modeli mogut trebovatj lokaljnogo proveryayemogo sloya vmesto polnogo vosproizvedeniya.
- Perekhod k istochniku: obsjhiye trebovaniya raskryityi v dokumente [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md), a konkretnyiye instrumentyi opisanyi v papke [Instrumentyi](../../Instrumentyi/README.md).
- Granicyi analogii: kartochka primenima k ustojchivyim povtoryayemyim proceduram; razovaya ruchnaya operaciya stanovitsya kandidatom na avtomatizaciyu toljko posle yavnoj ocenki povtoryayemosti.
- Proverka: u avtomatizacii dolzhnyi byitj lokaljnaya komanda zapuska, testyi ili proverochnyij scenarij, opisaniye ogranichenij i zapisj v reyestre instrumentov, yesli ona povtorno ispoljzuyetsya v rabochikh sessiyakh.
- Status uverennosti: chastichno zakrepleno susjhestvuyusjhimi avtomatizaciyami; nuzhna yedinaya mashinno proveryayemaya kartochka dlya klassa avtomatizacij.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:33:38 MSK](../../Zhurnal/2026-07-02_11-33-38_MSK/zapros.md)

## Opornyiye dokumentyi

- [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md)
- [Instrumentyi](../../Instrumentyi/README.md)
- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:b3a935f1f95e82f67b4f9cfb8b41344dafea8a0ce7977d794a6464bd96cbef33 -->
<!-- FUM-MD-RECENCY:END -->
