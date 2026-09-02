---
name: fum-analitika-zavershyonnyikh-shagov
description: Istoricheskij kontrakt snyatoj periodicheskoj analitiki zavershyonnyikh shagov; sokhranyayetsya dlya chteniya prezhnikh sostoyanij i lokaljnyikh regressionnyikh testov, no ne razreshayet novyij zapusk ili host-effekt.
---

# Analitika zavershyonnyikh shagov

Instrument vyiveden iz ekspluatacii vmeste s periodicheskim heartbeat i universaljnyim dispetcherom. On sokhranyayetsya kak istoricheskij kontrakt formata prezhnikh sobyitij, pretenzij i kursora, a takzhe kak granica lokaljnyikh regressionnyikh testov. Etot navyik ne razreshayet sozdavatj rezervaciyu, pretenziyu, zadachu Codex, otchyot po porogu, dispetcherskoye podtverzhdeniye ili lyuboj inoj novyij vneshnij libo Git-effekt.

Chislo zavershenij, chislo kommitov i proshedsheye vremya boljshe ne sozdayut analiticheskoye zadaniye. Yesli analiticheskaya reviziya snova nuzhna, poljzovatelj zapuskayet yeyo otdeljnyim soderzhateljnyim zaprosom v novoj ruchnoj pishusjhej sessii. Predshestvuyusjhij marshrut s kartochkoj, exact [zadachej-prodolzheniyem vetki](../../Glossarij/obyazateljnoye-prodolzheniye-vetki.md), FIFO, `commit+handoff` i pryamyim selector sokhranyayetsya toljko kak istoricheskaya modelj.

## Sokhranyonnaya istoricheskaya sovmestimostj

Realizaciya, skhemyi i testyi ostayutsya v kataloge `Инструменты/fum-analitika-zavershyonnyikh-shagov/`, chtobyi prezhniye kommityi i sluzhebnyiye sostoyaniya mozhno byilo issledovatj vosproizvodimo. Istoricheskij kontrakt ispoljzoval:

- zhurnal `refs/fum/worktree-task-completion-ledgers/<checkout>/<branch_ref>` skhemyi `fum.журнал-завершённых-запусков.1`;
- specializirovannuyu pretenziyu `refs/fum/аналитика-завершённых-запусков/<checkout>/<branch_ref>`;
- zadaniye `master.completed-step-analysis` i tracked cursor v prezhnem obsjhem reyestre;
- fazyi `зарезервирована`, `привязана`, `подтверждена`, `очищена`, `передана` i `завершена`.

Eti zapisi ne yavlyayutsya dejstvuyusjhej ocheredjyu, waiting-biletom prodolzheniya, kartochkoj shaga ili polnomochiyem na zapusk. Sostoyaniye zadaniya v `Планирование/реестры-заданий-автоматизаций/master.json` terminaljno ravno `retired`. Skript sokhranyayetsya dlya regressionnyikh fikstur i otdeljnoj budusjhej migracii, no yego mutiruyusjhiye komandyi ne vyizyivayutsya rabochej sessiyej.

Susjhestvuyusjhiye sluzhebnyiye Git-ssyilki ne udalyayutsya ad hoc. Ikh poglosjheniye, arkhivirovaniye ili snyatiye trebuyet otdeljnogo iskhodnogo zaprosa, konechnogo inventarya, TDD-proverok i ograzhdyonnoj migracii. Prostoye nalichiye prezhnej ssyilki ne blokiruyet i ne zapuskayet novuyu rabotu.

## Proverka sovmestimosti

Avtonomnyiye testyi istoricheskoj realizacii ne trebuyut seti i mogut ispoljzovatjsya toljko kak lokaljnaya regressiya formatov. V rabochej sessii oni zapuskayutsya cherez [obyortku otchyotov o proverkakh](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) s tochnyim tekusjhim iskhodnyim zaprosom Zhurnala. Zelyonyij rezuljtat ne oznachayet, chto periodicheskaya analitika vnovj vvedena v ekspluataciyu.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [FUM-STEP-0096 — dobavitj analitiku po chislu zavershyonnyikh shagov](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0096-dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov.md)
- [iskhodnyij zapros — dobavitj analitiku po chislu zavershyonnyikh shagov](../../Zhurnal/2026-08-10_14-30-08_MSK_dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov/zapros.md)
- [obyazateljnoye prodolzheniye Git-vetki posle kommita](../../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:808295a69457d6ca2041f8bf9133eca930645036558b945c3ca81f387ee34a07 -->
<!-- FUM-MD-RECENCY:END -->
