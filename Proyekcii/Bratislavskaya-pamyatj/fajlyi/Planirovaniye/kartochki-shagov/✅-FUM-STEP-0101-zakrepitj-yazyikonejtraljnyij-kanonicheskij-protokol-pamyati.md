+++
schema_version = 1
card_id = "FUM-STEP-0101"
status = "completed"
+++
# Zakrepitj yazyikonejtraljnyij kanonicheskij protokol pamyati

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Opredelitj versionnyij yazyikonejtraljnyij bajtovyij profilj kanonicheskikh sobyitij i pokolenij pamyati, sozdatj granichnyiye golden vectors i podtverditj ikh ne meneye chem dvumya realizaciyami. Swift ostayotsya osnovnyim runtime; vtoraya uzkaya realizaciya proveryayet perenosimostj protokola, a ne zamenyayet produktovyij stek.

## Rezuljtat

Profilj `fum.memory.canonical-json.v1` zakrepil yedinstvennyiye bajtyi sobyitij i pokolenij pamyati: strogij UTF-8, ASCII-imena polej v bajtovom poryadke, massivyi s sokhraneniyem poryadka, neotricateljnyiye celyiye do `2^53−1`, tochnyiye pravila Unicode i ekranirovaniya, otsutstviye probelov i konechnogo perevoda stroki, a takzhe zapret `null`, drobnyikh i neodnoznachnyikh znachenij. Profilj yavlyayetsya prikladnyim podmnozhestvom JCS i I-JSON, sovmestimyim s fakticheskim domenom pamyati.

Swift-runtime poluchil sobstvennyiye parser i writer, kotoryiye ne ispoljzuyut Foundation-serializaciyu dlya kanonicheskikh bajtov i vyichislyayut vse SHA-256 toljko iz rezuljtata profilya. Pokoleniye perevedeno na skhemu `3`, a `CURRENT` — na skhemu `2`; oba nositelya yavno nazyivayut profilj i ne pereopredelyayut prezhniye skhemyi molcha.

Obsjhij corpus soderzhit polozhiteljnyiye sobyitiya, programmu, nachaljnoye i prodolzhennoye pokoleniya, `CURRENT`, granichnyiye Unicode i chisla, izvestnyiye SHA-256 i klassyi otkazov. Swift i uzkij nezavisimyij Python-verifier pobajtovo sovpadayut na odnom manifest i odinakovo otklonyayut nedopustimyiye libo nekanonicheskiye vkhodyi. Avtonomnyiye testyi povtorno porozhdayut tochnyiye golden bytes iz produktovogo runtime.

## Istochniki

- [iskhodnyij zapros o vyipolnenii FUM-STEP-0101](../../Zhurnal/2026-07-28_08-47-18_MSK_zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati/zapros.md)
- [yazyikonejtraljnyij kanonicheskij protokol pamyati](../../Dokumentaciya/47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)
- [FUM-STEP-0100 — avarijnaya soglasovannostj](✅-FUM-STEP-0100-dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a848934997dd8dd18ab82ea171ebf1b79a097e9371f361a7ec6937ad0c5edbe6 -->
<!-- FUM-MD-RECENCY:END -->
