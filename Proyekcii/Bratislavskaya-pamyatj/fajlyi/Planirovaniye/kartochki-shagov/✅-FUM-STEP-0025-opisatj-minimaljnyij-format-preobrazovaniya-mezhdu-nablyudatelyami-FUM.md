+++
schema_version = 1
card_id = "FUM-STEP-0025"
status = "completed"
+++
# Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Opisatj minimaljnyij format preobrazovaniya mezhdu [nablyudatelyami FUM](../../Glossarij/nablyudatelj-FUM.md): iskhodnyij sloj, profilj nablyudatelya, nablyudayemyiye signalyi, sokhranyayemyiye invariantyi, poteri informacii, proverku obratimosti ili neobratimosti perekhoda, a takzhe marshrut k istochniku polnoj informacii ili yavnuyu otmetku nevozmozhnosti takogo perekhoda.

## Rezuljtat

Sozdan [minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md) versii `1`. Odna napravlennaya JSON-zapisj fiksiruyet tochnyiye iskhodnuyu i celevuyu storonyi, profili nablyudatelej, pryamoj metod, sploshnuyu kartu signalov, proveryayemyiye invariantyi, yavnyiye poteri, vyivod ob obratimosti i nezavisimo proveryayemyij marshrut k iskhodnomu sloyu.

[JSON Schema](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json) zapresjhayet neizvestnyiye polya, a [semanticheskij validator](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py) proveryayet ssyilochnuyu celostnostj i pokryitiye. Dve lokaljnyiye fiksturyi podtverzhdayut tochnyij UTF-8 round-trip i neobratimoye izvlecheniye pervogo Markdown-zagolovka cherez nablyudayemuyu kolliziyu raznyikh iskhodnyikh tel; obe obnaruzhivayutsya iz materializovannogo konteksta postavki i sveryayut otnositeljnyij marshrut s SHA-256 iskhodnoj statji.

Granica rezuljtata ogranichena odnim perekhodom dokumentacionnogo prototipa. Format ne yavlyayetsya runtime, kompilyatorom, transportom, obsjhej metrikoj poterj ili razresheniyem dostupa; polnota istochnika ogranichena yavno nazvannoj proyekciyej i zakreplyonnyim sostoyaniyem i podtverzhdayetsya ischerpyivayusjhim inventaryom yeyo signalov.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md), [zhurnal](../../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/otchyot.md)
- [iskhodnyij zapros 2026-06-26 11:39:57 MSK](../../Zhurnal/2026-06-26_11-39-57_MSK/zapros.md), [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md), [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](../../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md), [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8a8426e61e6db2cb3ee07ec17ef0905c3185878a4a149263a558780ae13bd7c0 -->
<!-- FUM-MD-RECENCY:END -->
