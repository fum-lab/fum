+++
schema_version = 1
card_id = "FUM-STEP-0203"
status = "completed"
+++
# Otvyazatj svyaznostj ot lokaljnogo grafa Obsidian

## Zadacha

Ustranitj zavisimostj ssyilochnogo dopuska FUM ot neobyazateljnogo ignoriruyemogo `.obsidian/graph.json`. Sokhranitj stroguyu proverku ostaljnyikh ssyilok i zapret izmeneniya poljzovateljskogo sostoyaniya radi dopuska.

## Pochemu sejchas

Dva nezavisimyikh novyikh worktree poluchili sotni oshibok po istoricheskim ssyilkam. Lokaljnoye kopirovaniye grafa vosstanovilo sredu, no ne sdelalo obsjhij dokumentacionnyij kontur vosproizvodimyim iz klona. Povtor zakreplyon kak `FUM-СБОЙ-0052/ПРОЯВЛЕНИЕ-0002`.

## Naznacheniye

Koordinator naznachil realizaciyu otdeljnomu svobodnomu ispolnitelyu zadachi 0201. On proveryayet otsutstviye neobyazateljnogo grafa bez sozdaniya ili izmeneniya poljzovateljskogo fajla i sokhranyayet strogiye otkazyi ostaljnyikh ssyilok. Do prinyatogo kommita eta zapisj oboznachayet naznacheniye, a ne vyipolnennoye ispravleniye.

## Kriterii zaversheniya

- Zafiksirovan tochnyij kontrakt neobyazateljnoj lokaljnoj celi; on ne razreshayet proizvoljnyiye otsutstvuyusjhiye puti ili ssyilki vne checkout.
- TDD podtverzhdayet svezhij klon bez grafa, neizmennostj susjhestvuyusjhego grafa, otkaz na obyichnoj bitoj i registronevernoj ssyilke.
- Izmenyonnaya proverka prokhodit profilj i obosnovannyij etap optimizacii, zatem primenimyij obsjhij dopusk na chistom klone.
- Sboj 0052 zakryivayetsya toljko po vosproizvodimomu svideteljstvu; vremennoye kopirovaniye grafa ne vyidano za ispravleniye.

## Rezuljtat

Prinyat kommit `28f51c58fa8df4d20d33ef2f05dab758cb7a6f83`: uzkoye isklyucheniye tochnogo otsutstvuyusjhego `.obsidian/graph.json`, adresnyiye RED/GREEN i profilj. Chetyire gruppyi regressij povtorenyi kornem posle integracii. V publichnom neizmennom klone `9c39c9b3fde83c4ce11ba101897c1298c68d436d` materializovana obyyavlennaya zavisimostj LinguisticKit; prinyatyim proveryayusjhim kodom proverenyi vse 1598 kanonicheskikh Markdown-fajlov bez grafa, oshibok net. Do i posle derevo chisto i graf otsutstvuyet. Proverka ssyilok — primenimyij obsjhij dopusk etogo ispravleniya; polnyij dopusk integracii otnositsya k 0176 i proveryayetsya otdeljno.

[Tochnoye svideteljstvo klona](../../Zhurnal/2026-09-11_02-51-49_MSK_proveritj-postavku-FUMA-iz-klona/materialyi/ssyilki-chistogo-klona.json) razlichayet kommit vkhoda i kommit proveryayusjhego koda. [Iskhodnyij otchyot ispolnitelya](../../Zhurnal/2026-09-11_02-19-55_MSK_dopustitj-otsutstviye-lokaljnogo-grafa/otchyot.md) sokhranyayet pervyiye otkazyi, profilj i ogranichennuyu priyomku.

## Istochniki

- [Naznacheniye ispolnitelya](../../Zhurnal/2026-09-11_02-13-44_MSK_integrirovatj-postavku-FUMA/zapros.md).

- [Sboj 0052 i povtor 0002](../../Sboi/FUM-SBOJ-0052-svyaznostj-trebuyet-lokaljnyij-graf-Obsidian.md).
- [Zapros perenosa](../../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:9cdde2f909de55793f21362b280ed6fb92cda376d1007164139d2ffa0800f611 -->
<!-- FUM-MD-RECENCY:END -->
