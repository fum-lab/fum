# Bratislavskij yazyik

Bratislavskij yazyik — prinyatoye v FUM nazvaniye russkogo yazyika, zapisannogo latinicej kak proizvodnaya proyekciya russkogo kirillicheskogo istochnika. Eto proyektnyij termin, a ne nazvaniye slovackogo yazyika, ne smyislovoj perevod i ne zayavleniye o sootvetstvii ISO ili GOST.

Dlya [bratislavskoj versii pamyati FUM](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md) tochnoye preobrazovaniye zadayotsya LinguisticKit `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)` na zakreplyonnoj revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Kirillicheskaya [pamyatj FUM](pamyatj-FUM.md) ostayotsya yedinstvennyim redaktiruyemyim istochnikom, a latinskaya forma khranitsya vmeste s proiskhozhdeniyem i polnostjyu peresobirayetsya iz nego.

V fajlovoj proyekcii preobrazuyetsya ne toljko russkoye soderzhimoye, no i kazhdyij kirillicheskij komponent polnogo otnositeljnogo puti: imena katalogov, osnova imeni fajla i inyiye russkiye chasti puti. Neizmenivshiyesya tekhnicheskiye komponentyi tozhe uchityivayutsya v mashinnom otobrazhenii, chtobyi polnota puti ne zavisela ot togo, vstretilasj li v komponente kirillica.

## Svyazannyiye dokumentyi

- [Bratislavskaya versiya pamyati FUM](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)
- [Pamyatj FUM](pamyatj-FUM.md)
- [Vosproizvodimyiye avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 18:28:33 MSK -->
<!-- content-sha256: sha256:91275ed24649c88cdd0b7b2df671a923d04acdace971bb92908ed70ed4d18788 -->
<!-- FUM-MD-RECENCY:END -->
