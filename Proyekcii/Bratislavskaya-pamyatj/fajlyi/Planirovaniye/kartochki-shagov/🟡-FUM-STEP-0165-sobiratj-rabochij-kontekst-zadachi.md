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

## Planovoye utochneniye: vspominaniye po kommitam

Mekhanizm vspominaniya vkhodit v preimusjhestvenno algoritmicheski vyichislyayemoye JSON-sostoyaniye organov chuvstv FUMA. V kompaktnom rabochem kontekste on dolzhen predstavlyatj povod vernutjsya k razboru khoda zadachi. Interval zadayotsya konfiguraciyej v kommitakh; 10 — primer iz iskhodnoj komandyi. Vopros «Vsyo li idyot khorosho» illyustriruyet povod dlya vnimaniya i ne yavlyayetsya dostatochnyim kriteriyem kachestva.

Tekusjhij soglasovannyij rezuljtat — utochneniye susjhestvuyusjhikh plana, modeli vnimaniya, kataloga detektorov, deklarativnyikh scenariyev i pasporta budusjhego eksperimenta. Plan fiksiruyet proiskhozhdeniye intervala, vyibrannuyu zadachu i vetku, podtverzhdyonnuyu tochku otschyota, pravilo schyota kommitov i sliyanij, sostav signala i priznaki neizvestnosti. Konkretnyiye proyektnyiye resheniya, kotoryim poka ne khvatayet osnovaniya, sokhranyayutsya otkryityimi. Kommit sam po sebe ne dokazyivayet progress po obyazateljstvam.

V kriteriyakh budusjhego ispolnyayemogo sreza predusmatrivayutsya konfiguriruyemyij interval i yego granicyi, povtor na tekh zhe vkhodakh, vosstanovleniye, dubli, sliyaniya, smena vetki ili istorii, nedostupnostj dannyikh, pozdneye izmeneniye i otmena. Chteniye, vozniknoveniye signala, podtverzhdyonnoye rassmotreniye i ispolnennoye dejstviye razlichayutsya. Neizvestnostj i otsutstviye dannyikh ne prevrasjhayutsya v otvet «vsyo khorosho»; pokaz voprosa ne oznachayet obrabotki soobsjheniya ili vyipolneniya obyazateljstva.

Plan pereispoljzuyet podgotovlennuyu osnovu rabochego konteksta, primenimyiye kontraktyi FUM-STEP-0177 i dostupnyiye pokazateli FUM-STEP-0160 s yavnyimi versiyami i granicami podklyucheniya. Otsutstvuyusjhij adapter ostayotsya zavisimostjyu. Budusjhij TDD i profilj predusmatrivayut nezavisimyij etalon sokhrannosti obyazateljstv, sopostavimyiye vkhodyi, stoimostj chteniya istorii i vyichisleniya signala i obosnovannoye resheniye ob optimizacii. Nezapolnennyij pasport ne schitayetsya izmereniyem.

Eto utochneniye ne poruchayet tekusjhemu planovomu etapu sozdavatj sborsjhik, ispolnyatj budusjhiye scenarii ili podklyuchatj mekhanizm k realjnomu rabochemu ciklu. Kriterii budusjhego sreza sokhranyayut posleduyusjhij obyyom realizacii. Mekhanizm ne vyivodit fiksirovannogo raspisaniya, hooks, heartbeat, avtomaticheskogo vyizova modeli ili novyikh vneshnikh polnomochij iz odnogo intervala i primernogo voprosa. Gotovnostj planovogo utochneniya ne zakryivayet polnyij FUM-STEP-0165.

## Podgotovlennaya osnova

[Plan i granicyi](../rabochij-kontekst-zadachi/README.md), [modelj vnimaniya](../rabochij-kontekst-zadachi/modelj-vnimaniya.md), [katalog detektorov](../rabochij-kontekst-zadachi/detektoryi.json), [deklarativnyiye scenarii priyomki](../rabochij-kontekst-zadachi/scenarii-priyomki.json) i [pasport budusjhego eksperimenta](../rabochij-kontekst-zadachi/pasport-eksperimenta.json) podgotovlenyi dlya realizacii. Eto plan, testovaya matrica i format budusjhikh izmerenij; sborsjhik, ispolnitelj scenariyev i avtomaticheskaya obratnaya svyazj poka ne realizovanyi.

## Istochniki

- [FUM-SBOJ-0070-neotfiljtrovannoye-media-v-tekstovom-vyivode](../../Sboi/FUM-SBOJ-0070-neotfiljtrovannoye-media-v-tekstovom-vyivode.md) — tochnoye osnovaniye aktualizacii `FUM-СБОЙ-0070/ПРОЯВЛЕНИЕ-0002`; [registraciya i nezavisimoye revjyu](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md). Utochnyayetsya proiskhozhdeniye uzhe pokazannogo ogranichennogo vosstanovleniya, novoye vyipolneniye shaga ne zayavlyayetsya.
- [Planovoye utochneniye o vspominanii po kommitam i JSON-sostoyanii](../../Zhurnal/2026-09-11_07-44-52_MSK_prinyatj-matematiku-i-rabochij-kontekst/zapros.md).
- [Neobrabotannyiye soobsjheniya i pozdniye utochneniya](🟡-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md).
- [Vopros ob ispoljzovanii kontekstnogo okna i iskhodnyij prioritet avtomatizacii](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).
- [Nablyudeniya i granicyi tekusjhej ocenki](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/otchyot.md).
- [Statistika vyizovov](🟡-FUM-STEP-0160-nakaplivatj-statistiku-vyizovov.md).
- [Snimok sostoyaniya zadachi](🟡-FUM-STEP-0159-sobratj-snimok-agentskogo-runtime-i-interfejsa.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:184e74cc8194fd856f9bbc9de45d1031a7fed2635df55d299d6eb7dbc8ef7279 -->
<!-- FUM-MD-RECENCY:END -->
