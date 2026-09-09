+++
schema_version = 1
card_id = "FUM-STEP-0154"
status = "active"
+++
# Proveryatj granicu zaversheniya postoyannoj zadachi

## Zadacha

Opredelitj i proveritj meru protiv neobosnovannogo zaversheniya otveta posle promezhutochnogo libo itogovogo kommita etapa pri nalichii razreshyonnoj nezavershyonnoj rabotyi. Sokhranitj zapret starogo avtomaticheskogo konvejyera sleduyusjhikh zadach i ne podmenyatj prodolzheniye tekusjhego khoda raspisaniyem.

## Pochemu sejchas

[FUM-SBOJ-0027/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0027-zaversheniye-otveta-posle-promezhutochnogo-kommita.md) proizoshlo pri uzhe zapisannom pravile prodolzheniya. Proverka nalichiya normyi okazalasj nedostatochnoj granicej povedeniya.

Povtor [FUM-SBOJ-0027/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0027-zaversheniye-otveta-posle-promezhutochnogo-kommita.md) posle priyomki uskoreniya delayet etu rabotu prioritetnoj po [novoj komande](../../Zhurnal/2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/zapros.md).

## Utochneniye posle povtornoj ostanovki

[FUM-SBOJ-0027/PROYAVLENIYE-0003](../../Sboi/FUM-SBOJ-0027-zaversheniye-otveta-posle-promezhutochnogo-kommita.md) vernul kartochku v aktivnuyu rabotu: spisok etapa poteryal roditeljskiye obyazateljstva realizacii. Nuzhnyi ustojchivyij reyestr, proverka sokhraneniya obyazateljstv po Git-istorii i adapter k shtatnoj granice Stop tekusjhego runtime. Uspekh dokumenta ili otdeljnogo etapa ne zakryivayet realizaciyu.

## Kriterii zaversheniya

- RED/GREEN vosproizvodit poteryu obyazateljstva, podmenu realizacii planom i zavershyonnuyu podzadachu pri aktivnom roditele; realjnyiye rezuljtatyi chitayutsya nezavisimo ot svobodnoj stroki svideteljstva.
- Vozmozhnostj i fakticheskij status Stop-hook proverenyi otdeljno ot repozitornogo CLI; ostanovka poljzovatelya i otsutstviye progressa ne prevrasjhayutsya v beskonechnyij cikl.
- Opredelenyi nablyudayemyiye sostoyaniya i dopustimyiye osnovaniya zaversheniya, vklyuchaya yavnuyu ostanovku poljzovatelem.
- Najdena proveryayemaya mera na dostupnoj granice upravleniya tekusjhej zadachej libo dokazano otsutstviye takoj mashinnoj vozmozhnosti s yavno ogranichennoj proceduroj vosstanovleniya.
- Posle kontroljnogo i itogovogo kommitov etapa nablyudayetsya vyipolneniye razreshyonnogo sleduyusjhego dejstviya bez novogo poljzovateljskogo soobsjheniya; eto svideteljstvo ne obyyavlyayetsya universaljnoj garantiyej.
- Rezuljtat i ogranicheniya svyazanyi s tochnyim proyavleniyem sboya; status kartochki izmenyon po fakticheskomu dokazateljstvu.

## Predyidusjhij ogranichennyij rezuljtat

Prinyata ogranichennaya procedurnaya mera: lokaljnyij CLI proveryayet proiskhozhdeniye zayavlennogo perechnya rabot, razlichayet dostupnuyu rabotu, ozhidaniye, ischerpaniye obyyoma i yavnuyu ostanovku. Kod 3 pri dostupnom punkte zapresjhayet final. Trinadcatj celevyikh testov i obsjhaya priyomka proshli; profilj i ogranicheniya sokhranenyi v [otchyote ispravleniya](../../Zhurnal/2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/otchyot.md).

Posle kontroljnogo kommita 39c40194655fbe27e851abfea17c5c432dca5a9f rabota prodolzhilasj bez novogo soobsjheniya. Posle itogovogo kommita f5cb17c4d1de779e9be944e6ae114798cd35ed5f vyipolnenyi proverka resheniya i nachalo integracii dochernego rezuljtata; [svideteljstvo po Git i JSONL](../../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/materialyi/svideteljstvo-prodolzheniya.json) fiksiruyet otsutstviye promezhutochnoj poljzovateljskoj komandyi.

Mera ne perekhvatyivayet final na urovne Codex i ne vozobnovlyayet nedostupnyij runtime. Polnotu razreshyonnogo obyyoma, smyisl osnovanij i dejstviteljnostj svideteljstv proveryayet korenj; rezuljtat ne obyyavlyayetsya garantiyej povedeniya vsekh budusjhikh ispolnitelej.

## Istochniki

- [Sistemnoye ispravleniye i PROYAVLENIYE-0003](../../Zhurnal/2026-09-09_11-39-26_MSK_predotvratitj-poteryu-obyazateljstv-postoyannoj-zadachi/zapros.md).

- [Komandyi postoyannoj zadachi](../../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [FUM-SBOJ-0027/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0027-zaversheniye-otveta-posle-promezhutochnogo-kommita.md).
- [FUM-SBOJ-0027/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0027-zaversheniye-otveta-posle-promezhutochnogo-kommita.md).
- [Prioritetnoye ispravleniye](../../Zhurnal/2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/zapros.md).
- [Dejstvuyusjhaya granica kommita](../../AGENTS.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 12:06:38 MSK -->
<!-- content-sha256: sha256:db0c430de9c03ae655b633cbff6727c8a095783a7a2bdccf85df0c37a994557f -->
<!-- FUM-MD-RECENCY:END -->
