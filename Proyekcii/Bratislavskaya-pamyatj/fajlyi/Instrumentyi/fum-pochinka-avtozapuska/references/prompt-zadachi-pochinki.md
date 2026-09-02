# Istoricheskaya spravka o prompte zadachi pochinki avtozapuska

Eta stranica sokhranyayet proiskhozhdeniye snyatogo prompta otdeljnoj zadachi pochinki avtozapuska. Ona ne yavlyayetsya ispolnyayemyim prompt, runtime-konvertom ili instrukciyej dlya sozdaniya novoj zadachi. Istoricheskiye renderer, komandyi i fiksturyi navyika ne dayut polnomochij izmenyatj, zapuskatj ili zamenyatj host-avtomatizaciyu.

## Snyatyij kontur

Prezhnyaya zadacha pochinki diagnostirovala zhivoj heartbeat po sloyam host-raspisaniya, FIFO, reyestra dispetchera, rezervacii, claim i pobajtovogo prompt. Repair-fence svyazyival odnu popyitku s tochnyimi vetkoj, vershinoj, zadachej i pokoleniyem. Nablyudyonnyij drejf host-skhemyi snachala zakreplyalsya obezlichennoj padayusjhej TDD-fiksturoj, zatem susjhestvuyusjhij prompt mog obnovlyatjsya na meste s zakryityim readback.

Periodicheskij avtozapusk i yego pochinka boljshe ne vkhodyat v dejstvuyusjhij kontur. Istoricheskiye repair-ssyilki i formatyi sokhranyayutsya toljko dlya sovmestimosti, proiskhozhdeniya i ograzhdyonnoj budusjhej migracii; oni ne yavlyayutsya waiting-biletami prodolzheniya i ne razreshayut host-effekt.

## Predyidusjhij kontur obyazateljnogo prodolzheniya

Do `manual-sequential-v1` osmyislennyij kommit zaraneye svyazyivalsya s tochnoj zadachej-prodolzheniyem toj zhe Git-vetki. Roditelj podtverzhdal FIFO-bilet rebyonka i atomarno peredaval yemu vetku vmeste s kommitom; rebyonok perechityival novyij `HEAD` i vyizyival pryamoj vetochnyij selector. Sejchas etot profilj otlozhen: kazhduyu pishusjhuyu sessiyu zapuskayet poljzovatelj, a ona zavershayetsya bez continuation.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [kontrakt istoricheskogo navyika pochinki avtozapuska](../SKILL.md)
- [iskhodnyij zapros o sozdanii instrumenta pochinki](../../../Zhurnal/2026-08-05_22-56-33_MSK_proanalizirovatj-opyit-pochinki-i-sozdatj-instrument-pochinki-avtozapuska/zapros.md)
- [kontrakt FIFO-ocheredi](../../fum-ocheredj-zadach-git-vetki/SKILL.md)
- [istoricheskij kontrakt dispetchera avtomatizacij FUM](../../fum-dispetcher-avtomatizacij-fum/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:47:26 MSK -->
<!-- content-sha256: sha256:e19b66ea200ed7dc90b29a86acea205201b7b1e06a1fe52ccd2fbebee9b9112b -->
<!-- FUM-MD-RECENCY:END -->
