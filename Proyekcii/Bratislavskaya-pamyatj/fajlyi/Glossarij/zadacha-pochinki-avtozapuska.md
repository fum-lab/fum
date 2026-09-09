# Zadacha pochinki avtozapuska

Zadacha pochinki avtozapuska — istoricheskij termin snyatogo heartbeat-kontura. Tak nazyivalasj otdeljno zaproshennaya kornevaya zadacha Codex, kotoraya diagnostirovala i pri neobkhodimosti ispravlyala otkaz [dispetchera avtomatizacij FUM](dispetcher-avtomatizacij-FUM.md) v lokaljnoj srede togo zhe proyekta.

Prezhnij zapuskatelj svyazyival odin `create_thread` s repair-fence, tochnyim sokhranyonnyim proyektom, vetkoj, vershinoj i FIFO-pokoleniyem. Remontnaya zadacha nablyudala host-raspisaniye, rezervaciyu, claim i polnyij prompt, zakreplyala novyij dopustimyij host-profilj TDD-fiksturoj i mogla obnovitj susjhestvuyusjhuyu avtomatizaciyu toljko na meste s zakryityim readback. Eti pravila sokhranyayutsya kak proiskhozhdeniye, no boljshe ne yavlyayutsya ekspluatacionnyim marshrutom.

V dejstvuyusjhem konture net avtozapuska, kotoryij mogla byi chinitj takaya zadacha. Poljzovatelj vruchnuyu zapuskayet kazhduyu pishusjhuyu sessiyu; ona posledovateljno vyipolnyayet soglasovannyiye etapyi i prodolzhayet dostupnuyu rabotu posle ikh proverennyikh lokaljnyikh kommitov. Predshestvuyusjhaya skhema s [obyazateljnyim prodolzheniyem vetki](obyazateljnoye-prodolzheniye-vetki.md) i sokhranyonnyij prompt pochinki yavlyayutsya istoricheskimi spravkami. Kornevoj `./sbrositj.sh` sbrasyivayet lokaljnuyu FIFO kak chelovecheskij break-glass, no ne vozobnovlyayet avtozapusk i ne sozdayot prodolzheniye.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 22:56:33 MSK — Proanalizirovatj opyit pochinki i sozdatj instrument pochinki avtozapuska](../Zhurnal/2026-08-05_22-56-33_MSK_proanalizirovatj-opyit-pochinki-i-sozdatj-instrument-pochinki-avtozapuska/zapros.md)

## Opornyiye materialyi

- [Obyazateljnoye prodolzheniye Git-vetki posle kommita](../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [Istoricheskij dispetcher avtomatizacij FUM](dispetcher-avtomatizacij-FUM.md)
- [iskhodnyij zapros 2026-08-05 21:02:54 MSK — Ispravitj avtozapusk](../Zhurnal/2026-08-05_21-02-54_MSK_ispravitj-avtozapusk/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 00:22:39 MSK -->
<!-- content-sha256: sha256:449f588b9a8e15ee064945be72dd5867f579fe514e87f6d28493da2c6dc55607 -->
<!-- FUM-MD-RECENCY:END -->
