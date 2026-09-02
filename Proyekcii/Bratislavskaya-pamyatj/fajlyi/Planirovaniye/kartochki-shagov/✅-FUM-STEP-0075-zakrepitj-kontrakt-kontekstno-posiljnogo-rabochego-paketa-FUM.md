+++
schema_version = 1
card_id = "FUM-STEP-0075"
status = "completed"
+++
# Zakrepitj kontrakt kontekstno posiljnogo rabochego paketa FUM

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Nachatj v tochnom kataloge `Прототипы/проверяемый-многоагентный-контур/` samostoyateljnyij bezokonnyij SwiftPM-prototip [proveryayemogo mnogoagentnogo kontura FUM](../../Glossarij/proveryayemyij-mnogoagentnyij-kontur-FUM.md) s versionirovannogo mashinochitayemogo kontrakta odnogo [kontekstno posiljnogo ispolnyayemogo shaga](../../Trebovaniya/🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md). Rabochij paket dolzhen do nachala modeljnoj ili izmenyayusjhej rabotyi opisyivatj odnu osnovnuyu postavku, ogranichennyij nabor vkhodov, dopustimuyu oblastj izmenenij, isklyucheniya, zavisimosti, proverki, peredachu rezuljtata i razdeljnyij byudzhet chteniya, rabotyi, proverok, otveta i rezerva. Lokaljnyij predpuskovoj analizator dolzhen vozvrasjhatj toljko proveryayemoye resheniye `ready` ili `split_required` i zakryivatjsya otkazom na nepolnom libo protivorechivom pakete.

Soderzhateljnyiye izmeneniya realizacii ogranichenyi novyim katalogom prototipa, yego strokoj v `Прототипы/README.md` i registraciyej paketa v politike obsjhego smoke-check. Razreshenyi toljko obyazateljnyiye sluzhebnyiye artefaktyi tekusjhej rabochej sessii: iskhodnyij zapros, zhurnal, zaversheniye etoj kartochki, novyij vetochnyij vyibor i vyikhodyi shtatnyikh generatorov planovogo reyestra, recency i grafa. Ne izmenyatj susjhestvuyusjhiye prototipyi, produktovyij runtime, setevyiye ili modeljnyiye adapteryi, ocheredj FIFO i mekhanizm claim sleduyusjhego shaga.

## Rezuljtat

V kataloge `Прототипы/проверяемый-многоагентный-контур/` sozdan samostoyateljnyij SwiftPM-paket bez seti i vneshnikh zavisimostej. Kontrakt versii 1 zakryivayet neizvestnyiye i povtornyiye JSON-polya, trebuyet rovno odnu osnovnuyu postavku, celj, konechnyij khyeshirovannyij manifest vkhodov, ogranichennuyu oblastj izmenenij s isklyucheniyami, razreshyonnyiye zavisimosti, proverki, peredachu i otdeljnyiye byudzhetyi chteniya, rabotyi, proverki, otveta i rezerva.

Predpuskovoj analizator ne vyizyivayet modelj i ne izmenyayet poljzovateljskiye dannyiye. On chitayet toljko perechislennyiye vkhodyi otnositeljno otkryitogo deskriptora yavnoj rabochej oblasti, zapresjhayet simvolicheskiye ssyilki, zhyostko ogranichivayet prochitannyiye bajtyi i sveryayet fakticheskij SHA-256 obyichnogo neizmenivshegosya fajla. Dlya polnogo, neprotivorechivogo paketa analizator vyidayot kanonicheskij otchyot `ready`, a dlya nepolnogo libo protivorechivogo — toljko `split_required` s ustojchivo otsortirovannyimi mashinochitayemyimi kodami. Polozhiteljnaya i pyatj obyazateljnyikh otricateljnyikh fikstur, trinadcatj avtonomnyikh testov, sborka, strogij Swift-format lint i zapusk probnika podtverzhdayut kontrakt; README otdeljno fiksiruyet, chto deklarativnyij byudzhet ne dokazyivayet fakticheskij raskhod konteksta i ne yavlyayetsya chislovoj veroyatnostjyu pomesjhayemosti.

Prototip zaregistrirovan v indekse prototipov i strogoj SwiftPM-politike obsjhego smoke-check. Pasport raspredelyonnogo epizoda, obsjhaya pamyatj, proiskhozhdeniye vkladov, nezavisimaya proverka, vyibor i zhivoj mnogoagentnyij runtime ostayutsya za granicej rezuljtata.

## Istochniki

- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-26 18:56:09 MSK — Zakrepitj kontrakt kontekstno posiljnogo rabochego paketa FUM](../../Zhurnal/2026-07-26_18-56-09_MSK_zakrepitj-kontrakt-kontekstno-posiljnogo-rabochego-paketa-FUM/zapros.md)
- [trebovaniye o kontekstno posiljnyikh ispolnyayemyikh shagakh](../../Trebovaniya/🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md)
- [kartochka shaga](../../Glossarij/kartochka-shaga.md)
- [pasport dokumentacionnogo prototipa i pervogo korobochnogo sreza](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c01ad51e0545dcb93d5c23087728a13acb786215ba90ff4f16ccc45de683a7d6 -->
<!-- FUM-MD-RECENCY:END -->
