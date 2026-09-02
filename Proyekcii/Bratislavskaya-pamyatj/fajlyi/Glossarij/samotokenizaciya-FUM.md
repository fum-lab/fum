# Samotokenizaciya FUM

Samotokenizaciya FUM - sposobnostj [FUM](FUM.md) vyivoditj poleznyiye yedinicyi potoka iz samikh dannyikh: ot bajtovyikh regulyarnostej i skryityikh kodov do grafemopodobnyikh, morfemopodobnyikh, slovopodobnyikh, frazovyikh i sobyitijnyikh yedinic.

Termin ne oznachayet, chto u sistemyi net nikakikh iskhodnyikh predposyilok. U [FUM](FUM.md) ostayutsya universaljnyiye kriterii: predskazyivatj prodolzheniye potoka, szhimatj opyit, ekonomitj pamyatj i vyichisleniya, sokhranyatj poleznyiye abstrakcii i udalyatj bespoleznyiye. No sistema ne dolzhna zaraneye schitatj obyazateljnyimi konkretnyiye lingvisticheskiye znaniya vrode `UTF-8`, probela kak granicyi slova, ponyatiya slova, morfemyi ili chasti rechi.

Yesli chelovek, LLM ili avtomatizaciya uzhe znayut prostyiye strukturnyiye elementyi domena, samotokenizaciya mozhet ispoljzovatj ikh kak nachaljnyiye gipotezyi: morfemyi, slovoformyi s paradigmami, soglasuyemyiye slovosochetaniya, predlozheniya, bloki koda ili TeX-komandyi. Eti elementyi pomogayut byistreye stroitj razbor potoka, no ostayutsya peresmatrivayemyimi i dolzhnyi podtverzhdatjsya poljzoj v konkretnyikh dannyikh. Pri zakreplenii oni oformlyayutsya kak [strukturiruyusjhiye operatoryi FUM](strukturiruyusjhij-operator-FUM.md), chtobyi odna i ta zhe forma mogla rabotatj v obe storonyi: potok -> struktura i struktura -> potok.

Rezuljtat samotokenizacii khranitsya kak veroyatnostnaya mnogourovnevaya reshyotka: odin fragment potoka mozhet imetj neskoljko konkuriruyusjhikh razborov, a boleye vyisokiye urovni mogut peresmatrivatj nizkourovnevuyu segmentaciyu, yesli drugaya narezka luchshe uchastvuyet v predskazanii, szhatii i roste [modulej FUM](modulj-FUM.md).

## Svyazannyiye dokumentyi

- [Potokovaya samostrukturizaciya FUM](../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md)
- [Obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](../Dokumentaciya/08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-08 09:27:58 MSK -->
<!-- content-sha256: sha256:ed86255942c288ab5c6d6eba936b2d5bd10e32f4c41f9eaf4a772967ae7b09e5 -->
<!-- FUM-MD-RECENCY:END -->
