# Dispetcher avtomatizacij FUM

Dispetcher avtomatizacij FUM — istoricheskij snyatyij termin dokumentacionnogo prototipa. On oboznachal postoyannyij planovyij kontur odnoj prikreplyonnoj zadachi Codex, heartbeat, vetochnogo reyestra zadanij, dispetcherskikh rezervacij i specializirovannyikh adapterov. Kontur nablyudal lokaljnuyu vetku i host, vyibiral rabotu po raspisaniyu ili porogu sobyitij i sozdaval otdeljnuyu FIFO-zadachu.

Etot mekhanizm boljshe ne yavlyayetsya dejstvuyusjhej chastjyu FUM i ne dayot runtime-polnomochij. Vmeste s nim snyatyi planovyij heartbeat, postoyannaya upravlyayusjhaya zadacha, obsjheye rezervirovaniye zapuskov, analiticheskij zapusk po nakoplennyim zaversheniyam i avtomaticheskoye vosstanovleniye po sleduyusjhemu tiku. Sokhranivshiyesya realizacii, sluzhebnyiye refs i istoricheskiye materialyi dopustimyi toljko kak proiskhozhdeniye, sovmestimostj ili osnovaniye bezopasnoj migracii; ikh nalichiye ne oznachayet aktivnogo avtozapuska.

Predyidusjhej zamenoj byilo [obyazateljnoye prodolzheniye vetki](obyazateljnoye-prodolzheniye-vetki.md): sessiya do kommita sozdavala dochernyuyu zadachu, dozhidalasj FIFO-bileta i vyipolnyala atomarnyij commit+handoff. Etot kontur tozhe otlozhen. Sejchas poljzovatelj vruchnuyu zapuskayet odnu pishusjhuyu sessiyu v pervichnom checkout `refs/heads/master`; ona vyipolnyayet odin soderzhateljnyij zapros, sozdayot ne boleye odnogo lokaljnogo kommita i zavershayetsya bez sleduyusjhej zadachi i avtomaticheskogo selector.

## Svyazannyiye dokumentyi

- [Obyazateljnoye prodolzheniye Git-vetki posle kommita](../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [Obyazateljnoye prodolzheniye vetki](obyazateljnoye-prodolzheniye-vetki.md)
- [Sleduyusjhij shag vetki](sleduyusjhij-shag-vetki.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:a581a3724ebe842e1edd733267ae88fd95250fcc0530d4c695f10fcedf2049a7 -->
<!-- FUM-MD-RECENCY:END -->
