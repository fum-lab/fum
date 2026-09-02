# Otchyot 2026-07-17 12:33:01 MSK - Dobavitj panelj zapuska prototipov

V korne repozitoriya poyavilasj yedinaya terminaljnaya panelj `prototipyi.sh`. Yeyo imya namerenno zapisano russkim translitom latinicej: komandu mozhno nabratj v uzhe ispoljzuyemoj latinskoj raskladke, a dlya vyibora prototipa dostatochno cifryi.

Bez argumentov panelj avtomaticheski nakhodit vse tochki vkhoda `Прототипы/*/запустить.sh`, pokazyivayet ikh pronumerovannyij spisok i prinimayet nomer libo bezopasnyij vyikhod `q`. Ona ne zavisit ot tekusjhego rabochego kataloga. Dlya proverok i scenariyev dostupnyi `--list` bez zapuska i pryamoj vyibor nomerom s peredachej ostaljnyikh argumentov vyibrannomu prototipu. Blagodarya avtomaticheskomu obnaruzheniyu budusjhij ustojchivyij prototip poyavlyayetsya v paneli srazu posle dobavleniya prinyatogo `запустить.sh`.

## Resheniye po avtomatizacii

Kontrakt vklyuchyon v lokaljnuyu avtomatizaciyu `fum-prototype-launch` cherez TDD. Proveryayusjhij skript trebuyet ot kornevoj paneli ispolnyayemyij bit, shebang `#!/bin/sh` i korrektnyij POSIX shell-sintaksis. Testyi vyipolnyayut panelj toljko na vremennyikh bezopasnyikh fiksturakh: proveryayut sortirovannyij spisok iz drugogo kataloga, interaktivnyij vyibor i peredachu argumentov bez zapuska nastoyasjhikh Swift-prototipov.

## Proverki

- Krasnyij TDD-cikl podtverdil otsutstviye kornevoj paneli i yeyo validatora do realizacii.
- Posle realizacii desyatj avtonomnyikh testov `fum-prototype-launch` proshli bez oshibok.
- Spisok i pryamoj vyibor s peredachej `--help` uspeshno vyipolnenyi iz `/tmp`, nezavisimo ot tekusjhego kataloga.
- Interaktivnaya panelj pokazala oba prototipa i bezopasno zavershilasj po `q`.
- Strukturnaya proverka prinyala odnu kornevuyu panelj i dve tochki vkhoda prototipov.
- Planovyij reyestr, recency-metki, indeks Markdown-fajlov i teplovaya karta Obsidian peresobranyi i proverenyi.
- `git diff --check`, svyaznostj rabochej sessii i polnyij smoke-check iz 17 shagov proshli bez oshibok.

## Prodolzheniye

Otdeljnogo sleduyusjhego shaga dlya paneli ne ostalosj. Novyiye prototipyi dolzhnyi prodolzhatj poluchatj sobstvennyij bezopasnyij `запустить.sh`; obsjhaya panelj obnaruzhit ikh bez ruchnogo izmeneniya spiska.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [kornevaya panelj zapuska prototipov](../../prototipyi.sh)
- [indeks prototipov](../../Prototipyi/README.md)
- [avtomatizaciya proverki tochek vkhoda](../../Instrumentyi/fum-zapusk-prototipov/SKILL.md)
- [pravila repozitoriya](../../AGENTS.md)

## Istochniki

- [iskhodnyij zapros 2026-07-17 12:33:01 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0d4d2c64a0d28fbc154527bf0184a52a7ed9165bc5e43755a8f6f66f5ed598dc -->
<!-- FUM-MD-RECENCY:END -->
