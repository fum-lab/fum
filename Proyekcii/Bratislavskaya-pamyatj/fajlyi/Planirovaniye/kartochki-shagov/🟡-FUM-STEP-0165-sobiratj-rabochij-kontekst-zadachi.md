+++
schema_version = 1
card_id = "FUM-STEP-0165"
status = "active"
+++
# Sobiratj rabochij kontekst zadachi

## Zadacha

Avtomaticheski formirovatj ogranichennyij rabochij srez odnoj zadachi iz dolgovechnogo Zhurnala, reyestra obyazateljstv i nablyudenij s proiskhozhdeniyem. V srez vkhodyat celj, primenimyiye ogranicheniya, prinyatyiye resheniya, zavisimosti, tekusjhiye sostoyaniya i blizhajshiye dejstviya; podrobnyiye dokazateljstva dostupnyi po tochnyim ukazatelyam.

## Pochemu sejchas

Razbor tekusjhego cikla pokazal povtornoye chteniye pravil i rezuljtatov, dlinnyiye instrumentaljnyiye vyivodyi i smesheniye upravleniya napravleniyami s detalyami ispolneniya. Eto kachestvennoye nablyudeniye, ne chislennaya ocenka doli poleznogo konteksta. Prinyatyij prioritet avtomatizacii trebuyet proveritj takoj sposob na nakoplennoj statistike vyizovov i vremeni vosstanovleniya.

## Kriterii zaversheniya

- Odin yavno ukazannyij kornevoj identifikator opredelyayet granicu istochnikov; chastnyiye pervichnyiye dannyiye ostayutsya na razreshyonnom nositele.
- Dlya kazhdogo vyivoda sokhranyayutsya istochnik i yego versiya, polnota okhvata i priznaki neizvestnosti, protivorechiya libo ustarevaniya.
- Pasport vkhoda fiksiruyet podtverzhdyonnuyu granicu dostavki, vremya ocenki, oblastj i limit sreza. Pri nedostatochnom limite polnota ne zayavlyayetsya; ustarevayut zavisimyiye vyivodyi, a ne vsya istoriya avtomaticheski.
- Povtornoye postroyeniye na tekh zhe vkhodakh vosproizvodit srez; pozdnyaya otmena, izmeneniye ogranicheniya i nezavershyonnoye obyazateljstvo ne teryayutsya posle vosstanovleniya.
- Srez ne zamenyayet obyazateljnoye chteniye dejstvuyusjhikh instrukcij, pervichnyij tekst komandyi pri susjhestvennoj neodnoznachnosti ili neobkhodimoye razresheniye. Sluzhebnyij hook i final ne prevrasjhayutsya v komandu cheloveka ili dokazateljstvo zaversheniya.
- Adresnoye raskryitiye podrobnostej sokhranyayet iskhodnyij poryadok i tochnyiye ssyilki na dannyiye; sokrasjheniye ne perepisyivayet iskhodnuyu istoriyu.
- TDD, profilj i sravneniye na odinakovom nabore zadach izmeryayut obyyom peredannyikh dannyikh, povtornyiye chteniya, chislo ruchnyikh vyizovov i vremya vosstanovleniya pri odinakovoj polnote obyazateljstv. Porog poleznosti obosnovan izmereniyami; procent effektivnosti zaraneye ne naznachayetsya.
- Nezavisimyij etalon korrektnosti predshestvuyet ocenke ekonomii; obsjhij limit akkaunta, zatratyi processa i zadacha ne smeshivayutsya. Resursnyiye pokazaniya imeyut istochnik, vremya i oblastj, a nedostupnyiye schyotchiki ostayutsya neizvestnyimi. Proveryayetsya stoimostj samogo nablyudeniya i effekt razreshyonnoj korrekcii.

## Podgotovlennaya osnova

[Plan i granicyi](../rabochij-kontekst-zadachi/README.md), [modelj vnimaniya](../rabochij-kontekst-zadachi/modelj-vnimaniya.md), [katalog detektorov](../rabochij-kontekst-zadachi/detektoryi.json), [deklarativnyiye scenarii priyomki](../rabochij-kontekst-zadachi/scenarii-priyomki.json) i [pasport budusjhego eksperimenta](../rabochij-kontekst-zadachi/pasport-eksperimenta.json) podgotovlenyi dlya realizacii. Eto plan, testovaya matrica i format budusjhikh izmerenij; sborsjhik, ispolnitelj scenariyev i avtomaticheskaya obratnaya svyazj poka ne realizovanyi.

## Istochniki

- [Vopros ob ispoljzovanii kontekstnogo okna i iskhodnyij prioritet avtomatizacii](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).
- [Nablyudeniya i granicyi tekusjhej ocenki](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/otchyot.md).
- [Statistika vyizovov](🟡-FUM-STEP-0160-nakaplivatj-statistiku-vyizovov.md).
- [Snimok sostoyaniya zadachi](🟡-FUM-STEP-0159-sobratj-snimok-agentskogo-runtime-i-interfejsa.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 17:38:45 MSK -->
<!-- content-sha256: sha256:f07eba9d8f193af33691da11593f5c5406f1f8a0dc7e845d4c59e31a9e0425e8 -->
<!-- FUM-MD-RECENCY:END -->
