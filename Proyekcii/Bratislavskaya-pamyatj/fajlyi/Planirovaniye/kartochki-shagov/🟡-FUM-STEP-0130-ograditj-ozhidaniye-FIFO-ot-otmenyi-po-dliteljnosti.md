+++
schema_version = 1
card_id = "FUM-STEP-0130"
status = "active"
+++
# Ograditj ozhidaniye FIFO ot otmenyi po dliteljnosti

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Perenesti zhiznennyij cikl ozhidayusjhego kornevogo FIFO-bileta iz neobyazateljnoj disciplinyi modeli v mashinno ograzhdyonnyij host- ili orkestracionnyij kontur. Neizmennoye sostoyaniye `waiting` dolzhno uderzhivatjsya libo idempotentno vozobnovlyatjsya bez resheniya modeli, a udaleniye bileta dolzhno dopuskatjsya toljko po tochnomu mashinno nablyudayemomu vneshnemu signalu prekrasjheniya ili zamenyi etoj zadachi, no ne po dliteljnosti ozhidaniya, chislu oprosov ili otsutstviyu progressa.

## Pochemu sejchas

Nablyudeno realjnoye proyavleniye mekhanizma, uzhe zapresjhyonnogo dejstvuyusjhim kontraktom: posle prodolzhiteljnogo neizmennogo `waiting` kornevoj agent otmenil sobstvennyij bilet i obyyavil zadachu zablokirovannoj vmesto prodolzheniya ozhidaniya. Ocheredj uzhe ne imeyet TTL, sokhranyayet staryij bilet i predostavlyayet besshumnyij `wait-until-actionable`, poetomu yeyo avtonomnyiye testyi podtverzhdayut celostnostj FIFO, no ne ograzhdayut resheniye modeli vyizvatj dostupnyij `cancel`. Vozvratyi host, vosstanovleniye konteksta i obsjhaya evristika blokirovki ostavlyayut risk povtoreniya.

## Kriterii zaversheniya

- Krasnyij skvoznoj scenarij vosproizvodit tochnuyu posledovateljnostj `join → waiting → несколько неизменных host-возвратов или прерывание → попытка отмены либо объявления блокировки`; dliteljnyiye intervalyi modeliruyutsya sobyitiyami ili virtualjnyim vremenem, a ne realjnyim mnogochasovyim ozhidaniyem.
- Mashinnyij supervizor khranit tochnyiye `task_id`, `ticket_id`, `seq` i podtverzhdyonnyij `HEAD`; neizmennoye `waiting` privodit toljko k prodolzheniyu togo zhe ozhidaniya i ne vozvrasjhayetsya modeli kak soderzhateljnyij rezuljtat ili osnovaniye zavershitj zadachu.
- Posle preryivaniya processa, poteri otveta, perezagruzki konteksta ili szhatiya istorii tot zhe `task_id` vyipolnyayet idempotentnyij `join` i vozobnovlyayet ozhidaniye, sokhranyaya iskhodnyiye bilet i FIFO-poziciyu libo poluchaya uzhe susjhestvuyusjheye pokoleniye vladeljca.
- Obyichnyij modeljnyij putj ne mozhet udalitj ozhidayusjhij bilet toljko po `task_id` i izvestnomu `ticket_id`. Otmena trebuyet host-podtverzhdeniya yavnogo prekrasjheniya ili zamenyi tochnoj zadachi i ograzhdayetsya aktualjnyim sostoyaniyem ocheredi; stroka prichinyi, istyoksheye vremya, chislo oprosov, nekhvatka konteksta i otsutstviye progressa dokazateljstvom ne schitayutsya.
- Otsutstvuyusjheye, poddeljnoye, ustarevsheye ili otnosyasjheyesya k drugoj zadache host-podtverzhdeniye zakryivayet otmenu. Gonka otmenyi s dopuskom takzhe zavershayetsya bez snyatiya vladeljca ili chuzhogo bileta.
- Zakonnaya otmena udalyayet rovno odin podtverzhdyonnyij ozhidayusjhij bilet, ne zatragivayet vladeljca, predshestvennikov i posledovatelej i ne oslablyayet strogij FIFO.
- Avtonomnyij poddeljnyij host bez seti i sekretov proveryayet neizmennoye ozhidaniye cherez neskoljko okon, preryivaniye zhivogo processa, vosstanovleniye konteksta, yavnuyu poljzovateljskuyu otmenu, poddeljnoye i ustarevsheye podtverzhdeniye i gonku s peredachej ocheredi.
- Zhivaya priyomka na Codex-host podtverzhdayet, chto vtoraya iz dvukh kornevyikh zadach perezhivayet neskoljko host-granic bez samovoljnogo `cancel`, zatem poluchayet `reload_required`, perechityivayet `HEAD`, vyipolnyayet `ack-head` i dopuskayetsya.
- `AGENTS.md`, navyik ocheredi i arkhitekturnyiye dokumentyi yavno isklyuchayut shtatnoye `waiting` iz osnovanij priznatj zadachu zablokirovannoj; avtonomnyiye testyi i obsjhaya kompleksnaya proverka prokhodyat.

## Istochniki

- [FUM-SBOJ-0002 — Samovoljnaya otmena ozhidayusjhego FIFO-bileta](../../Sboi/FUM-SBOJ-0002-samovoljnaya-otmena-ozhidayusjhego-FIFO-bileta.md) — osnovaniye `FUM-СБОЙ-0002/ПРОЯВЛЕНИЕ-0001`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/zapros.md)
- [pravilo sistemnogo ustraneniya zamechennyikh nedorabotok](../../AGENTS.md)
- [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [ustraneniye kholostyikh vozvratov ozhidaniya ocheredi](../../Zhurnal/2026-07-22_14-53-29_MSK_ustranitj-kholostyiye-vozvratyi-ozhidaniya-ocheredi/zapros.md)
- [FUM-STEP-0031 — skvoznoj progon dvukh realjnyikh kornevyikh zadach](🟡-FUM-STEP-0031-provesti-skvoznoj-progon-dvukh-realjnyikh-kornevyikh-zadach-Codex-v-odnom-checkout.md)
- [FUM-STEP-0114 — proveryayemyij kontur sistemnogo ustraneniya nedorabotok](🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:00:56 MSK -->
<!-- content-sha256: sha256:12a86234028290dacdbb8ff9d2f9dad7f8a3ff12056d602c2d0d8c375364ba4c -->
<!-- FUM-MD-RECENCY:END -->
