+++
schema_version = 1
card_id = "FUM-STEP-0125"
status = "active"
+++
# Podklyuchitj realjnyij pul poduzlov v kompozicionnoj sborke

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Posle otdeljnogo yavnogo razresheniya materializovatj otdeljnuyu kompozicionnuyu sborku, dolgovechnyiye fork-repozitorii universaljnyikh ispolnitelej `fum-yadro`, `fum-optimizator` i `fum-pisatelj`, a takzhe otdeljnogo zaraneye zaregistrirovannogo celevogo agenta-poluchatelya dlya proverki perenosa navyika, i zakrepitj ikh submodule-registracii. Zafiksirovatj tochnyiye remote, refs, roli, dostup, publikacionnyiye granicyi, marshrutyi pull request i pervonachaljnyij host-marshrut odnogo Codex Desktop k zhivyim klonam; daljnejshiye shagi kazhdoj vetki dolzhnyi zapuskatjsya yeyo obyazateljnyim prodolzheniyem posle kommita, a ne obsjhim heartbeat ili dochernim dispetcherom.

## Pochemu sejchas

Lokaljnaya priyomka mozhet dokazatj protokol, no ne sozdayot vneshniye repozitorii, submodule ili Codex-zadachi i ne dayot polnomochij na publikaciyu. Realjnaya topologiya trebuyet otdeljnogo razresheniya tochnyikh vneshnikh effektov.

## Kriterii zaversheniya

- Poljzovatelj yavno razreshil tochnyiye URL i ustojchivyiye identichnosti vsekh chetyiryokh dochernikh repozitoriyev, polnyiye refs, urovenj dostupa, sozdaniye libo ispoljzovaniye fork, submodule-izmeneniya, push i host-zadachi.
- Otdeljnyiye core i assembly obrazuyut aciklichnyij graf; universaljnyiye fork-poduzlyi nasleduyut core, a assembly zakreplyayet ikh opublikovannyiye commits gitlink-zapisyami.
- Zaregistrirovanyi tri ustojchivyiye identichnosti `fum-yadro`, `fum-optimizator` i `fum-pisatelj`; ikh pasporta sokhranyayut obsjhij universaljnyij profilj i razdeljnyiye predpochtiteljnyiye roli bez neyavnogo rasshireniya polnomochij.
- Dlya posleduyusjhej proverki perenosa zaraneye zaregistrirovan otdeljnyij celevoj agent-poluchatelj, yesjhyo ne poluchivshij vyibrannyij perenosimyij navyik: pasport zakreplyayet yego ustojchivuyu identichnostj, URL, dostup, registraciyu assembly, iskhodnyij gitlink i tochnoye pokoleniye core.
- `master` kazhdogo fork raven zakreplyonnomu opublikovannomu pokoleniyu upstream, rolevaya pamyatj zhivyot otdeljno, a publikacionno chistyiye vetki imeyut tochnyiye razreshyonnyiye celi pull request.
- Zhivaya proverka zerkal zakryivayetsya otkazom, yesli `origin` sovpadayet s `upstream`, upstream ukazyivayet ne na zaregistrirovannyij core, `master` soderzhit lokaljnyij commit ili raskhoditsya s opublikovannyim pokoleniyem, pokoleniye naznacheniya ustarelo, pasport rebyonka otsutstvuyet libo ne sovpadayet s registraciyej ili gitlink ne yavlyayetsya potomkom zakreplyonnoj sinkhronizirovannoj osnovyi.
- Kazhdyij rebyonok imeyet sobstvennyiye pravila, branch-scoped FIFO, obyazateljnoye prodolzheniye vetki, pryamoj selector i otdeljnyij zhivoj klon vne materializovannogo submodule; lokaljnyiye sluzhebnyiye refs i kvitancii ne publikuyutsya.
- Odin zaregistrirovannyij ekzemplyar Codex Desktop sozdayot pervonachaljnuyu [sessiyu shaga FUM](../../Glossarij/sessiya-shaga-FUM.md) v nuzhnom zhivom klone; kazhdyij yeyo kommit zaraneye sozdayot otdeljnoye prodolzheniye toj zhe vetki. Sovmestimyiye vetki raznyikh cepochek mogut ispolnyatjsya paralleljno, a zavisimyiye shagi odnoj linejnoj cepochki vyibirayutsya posledovateljno samim prodolzheniyem.
- Svezhij klon assembly vosstanavlivayet tochnyiye dostupnyiye detached-snimki, a otdeljnyij zhivoj klon rebyonka — yego vetku i kanonicheskoye sostoyaniye bez prezhnego host-processa.
- Publikacionnyij audit podtverzhdayet otsutstviye privatnoj pamyati, sekretov, mashinnyikh putej i nedostupnyikh submodule v zayavlennom publichnom grafe.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0124 — avtonomnaya priyomka paralleljnyikh poduzlov](🟡-FUM-STEP-0124-provesti-avtonomnuyu-priyomku-paralleljnyikh-universaljnyikh-poduzlov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:93ae070e133fb1b76cc742800f09c953b488a13aec001f15f5fca8cae51c1561 -->
<!-- FUM-MD-RECENCY:END -->
