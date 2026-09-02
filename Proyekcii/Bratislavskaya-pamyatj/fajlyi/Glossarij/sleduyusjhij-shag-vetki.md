# Sleduyusjhij shag vetki

## Status

Eto istoricheskij selector otlozhennogo konvejyera. V dejstvuyusjhej ruchnoj posledovateljnoj skheme novaya pishusjhaya sessiya poyavlyayetsya toljko po yavnomu poljzovateljskomu zaprosu; `branch-next-step.py show` avtomaticheski ne vyizyivayetsya i kartochku ne zapuskayet.

V otlozhennoj skheme sleduyusjhij shag vetki — versionnyij nabor kandidatov na prodolzheniye konkretnoj imenovannoj [vetki rabotyi](vetka-rabotyi.md). Zapisj khranit polnyij lokaljnyij ref, sostoyaniye `open` ili `done`, proyekt i zasjhisjhyonnyiye khyeshem ssyilki na aktualjnyiye [kartochki shagov](kartochka-shaga.md); zadacha, kriterii i istochniki chitayutsya iz kartochek.

Nabor ne yavlyayetsya [kartochkoj cepochki shagov](kartochka-cepochki-shagov.md). Kartochka cepochki zakreplyayet konechnuyu posledovateljnostj i sobstvennuyu vetku, a nabor sleduyusjhego shaga sluzhit selektorom tekusjhikh kandidatov uzhe vyibrannoj vetki. On ne sozdayot i ne pereklyuchayet Git-vetki.

Skhema `5` razlichayet `dispatch = automatic`, `paused` i `blocked`. `automatic` oznachayet dopustimostj kartochki dlya pryamogo [obyazateljnogo prodolzheniya vetki](obyazateljnoye-prodolzheniye-vetki.md), a ne raspisaniye ili fonovyij tik. Gotovnostj vyichislyayetsya na tekusjhem `HEAD` iz tochnogo statusa kartochki i `requires_completed_card_ids`; svobodnyij tekst `resume_condition` ne otkryivayet `paused` ili `blocked`.

Dopusjhennaya zadacha-prodolzheniye sama vyizyivayet read-only `validate` i `show`. Selektor proveryayet polnyij ref tekusjhej vetki, kanonichnostj nabora, susjhestvovaniye kartochek, ikh soderzhateljnyiye SHA-256, zavisimosti i bezopasnostj kazhdogo gotovogo kandidata, zatem determinirovanno vozvrasjhayet ne boleye odnogo `ready`. Pri `done` ili `not_ready` zadacha delayet `finish-clean` i ne sozdayot sleduyusjhuyu sessiyu.

Periodicheskij heartbeat, obsjhij dispetcher, host-inventarizaciya prostoya, reservation, lease i kartochochnyij claim v dejstvuyusjhij vyibor ne vkhodyat. FIFO tekusjhego checkout ostayotsya yedinstvennyim pravom zapisi, a kazhdyij uspeshnyij kommit sam zaraneye podgotavlivayet sleduyusjhuyu zadachu. Analitika ili inaya povtoryayemaya rabota vklyuchayetsya obyichnoj kartochkoj etogo zhe nabora, yesli yeyo kriterii dejstviteljno gotovyi.

Izmeneniye puti kartochki, yeyo soderzhateljnogo khyesha, rezhima `dispatch`, massiva zavisimostej ili usloviya vozobnovleniya trebuyet novogo `step_id`. Vyipolnennaya kartochka perevoditsya v istoricheskij status i udalyayetsya iz kandidatov tem zhe proverennyim kommitom; ostavshiyesya kandidatyi poluchayut svezhiye khyeshi i pokoleniya. Pustoj okonchateljnyij nabor stanovitsya `done`.

## Svyazannyiye dokumentyi

- [Obyazateljnoye prodolzheniye Git-vetki posle kommita](../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [Lokaljnyij kontrakt selektora](../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [Rabochiye naboryi sleduyusjhikh shagov](../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK — Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-22 03:38:35 MSK — Razreshitj vyipolneniye dostupnyikh kartochek shagov](../Zhurnal/2026-07-22_03-38-35_MSK_razreshitj-vyipolneniye-dostupnyikh-kartochek-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 11:56:54 MSK -->
<!-- content-sha256: sha256:ef8d8464466a23c318f3779e158a84908a9d33a47894ec70092fa3af98fa9aa2 -->
<!-- FUM-MD-RECENCY:END -->
