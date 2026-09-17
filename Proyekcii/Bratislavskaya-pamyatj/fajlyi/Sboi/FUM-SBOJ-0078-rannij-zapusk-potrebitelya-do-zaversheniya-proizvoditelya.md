+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0078"
"статус" = "активна"
+++
# Rannij zapusk potrebitelya do zaversheniya proizvoditelya

## Nablyudayemyij sboj

Korenj zapustil sborku reyestra, kogda vyizov primeneniya paketa diagnostiki yesjhyo vernul zhivoj session_id 14134, a yego zaversheniye ne byilo podtverzhdeno. Sborka zavershilasj uspeshno, no ostavila prezhnij reyestr. Posle zaversheniya primeneniya validator dostoverno otklonil ustarevshiye dannyiye.

## Granica povtoreniya

Zavisimyij potrebitelj zapuskayetsya do nablyudeniya terminaljnogo iskhoda proizvoditelya neobkhodimyikh fajlov. Susjhestvovaniye process/session_id i vozvrat upravleniya srede oshibochno prinimayutsya za razresheniye sleduyusjhej stadii. Nalozheniye fajlovoj zapisi imenno na korotkij interval sborki ne dokazano.

## Proyavleniya

- `FUM-СБОЙ-0078/ПРОЯВЛЕНИЕ-0001`: [sborka 2b9a0059](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/zapuski-proverok/4_2b9a0059-1ddc-42f1-9e5c-e6ae6ba74dcf.json) vernula 0 za 0,424805416 s i sokhranila prezhnij reyestr; [validaciya 71d6ca0f](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/zapuski-proverok/5_71d6ca0f-b76a-4ee7-9e37-74650fe34160.json) posle terminaljnogo uspekha proizvoditelya vernula 1 za 0,483123959 s s `registry is stale`. Vosstanovleniye: posledovateljno [sborka 57def88c](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/zapuski-proverok/6_57def88c-28fe-4815-90c9-3c2632e4d4fe.json) i [validaciya 6852657d](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/zapuski-proverok/7_6852657d-4a30-4451-803c-dffc38aa1b71.json) dali kod 0; tekusjhij reyestr vklyuchayet STEP 0213. Vse iskhodyi sokhranenyi, neuspekh ne zamenyon uspeshnyim povtorom.

`FUM-СБОЙ-0078/ПРОЯВЛЕНИЕ-0002`: Sol high sozdal `abc217c2760c6cbeb778833116a619ba8df644ad` do terminaljnogo iskhoda svyaznosti. Rannij otvet 20:57:35.034 UTC soderzhal toljko pustoj vyivod; commit podtverzhdyon v 20:57:42.777, a proverka zavershilasj v 20:57:56.176 s kodom 1. Prezhnij vyizov vyivodil toljko `r.output` i teryal status processa. [Tochnyiye native stroki, bajtovyiye intervalyi i SHA](../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/granicyi-pervichnyikh-sobyitij.json) i [korrekciya utverzhdeniya](../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/korrekciya-istorii.md) sokhranyayut osnovaniye. Effekt: opublikovan kommit bez uspeshnogo dopuska. Eto povtor zapuska zavisimogo dejstviya do izvestnogo iskhoda proizvoditelya; kod 1 stal izvesten pozdneye, poetomu epizod ne zamenyayetsya klassifikaciyej dejstviya posle uzhe izvestnogo otkaza.

Novoye proyavleniye vozvrasjhayet kartochku v aktivnoye sostoyaniye. Prezhnyaya ogranichennaya priyomka 0001 ostayotsya istoricheski dejstviteljnoj dlya svoyego cikla. Dlya tekusjhego epizoda sokhranyayutsya vse otkazyi, novaya svyaznostj dolzhna terminaljno zavershitjsya s kodom 0 do novogo kommita; obsjhij zapret yesjhyo ne realizovan.

## Ozhidaniye i klassifikaciya

Sleduyusjhaya zavisimaya fajlovaya stadiya dopustima posle nablyudayemogo uspeshnogo zaversheniya predyidusjhej. Eto oshibka poryadka ispolneniya. 0043 zasjhisjhayet vkhod uzhe rabotayusjhej proverki ot izmeneniya; 0010 sokhranyayet rannij otkaz obsjhego shell-vyizova; novyij 0079 kasayetsya dejstviya posle uzhe izvestnogo otkaza. Ni odna iz etikh granic ne podmenyayet ranneye otsutstviye terminaljnogo rezuljtata.

## Mekhanizm i sistemnoye ustraneniye

Dostupnyij protokol sredyi uzhe razlichayet zhivuyu sessiyu i okonchateljnyij exit_code. Ogranichennoye vosstanovleniye ispoljzuyet etot protokol: dozhdatjsya terminaljnogo rezuljtata proizvoditelya, pri neuspekhe sokhranitj iskhod i ne nachinatj zavisimyij potrebitelj, pri uspekhe peresobratj proizvodnyij reyestr i dozhdatjsya yego rezuljtata do validacii. Takoye vosstanovleniye vyipolneno dlya epizoda. Universaljnyij mashinnyij zapret rannego zapuska i novyij obsjhij orkestrator ne realizovanyi i ne zayavlyayutsya.

Ogranichennaya priyomka podtverzhdena nezavisimyim chteniyem pervichnyikh vyizovov: zaversheniye proizvoditelya v 12:06:56.414 UTC predshestvuyet povtornoj sborke v 12:09:23.013, yeyo terminaljnyij uspekh v 12:09:30.994 — validacii v 12:09:40.472 i uspekhu v 12:09:52.633. Sleduyusjhij realjnyij cikl sokhranil tot zhe poryadok: terminaljnyij uspekh primeneniya paketa 0078/0214, zatem podgotovka Gosuslug so sborkoj, zatem otdeljnaya validaciya e89798bb-3119-4c3b-b692-95ac167affb7 s kodom 0. Reyestr kommita 0219773d4a6c695739f8a2c53d4e5d4780632b0e soderzhit shagi 0213, 0214 i 0215. [Priyomka tochnoj granicyi](../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/otchyot.md) ne obesjhayet obsjhego mashinnogo predotvrasjheniya i ne pogashayet aktualjnuyu priyomku instrumenta 0201.

## Svyazannyiye shagi

[STEP 0214](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0214-proveritj-vosstanovleniye-posledovateljnosti-zavisimyikh-stadij.md) prinimayet tochnyiye svideteljstva ogranichennogo vosstanovleniya po `FUM-СБОЙ-0078/ПРОЯВЛЕНИЕ-0001`. [Smezhnaya kartochka 0043](FUM-SBOJ-0043-izmeneniye-proveryayemogo-snimka-do-zaversheniya-proverki.md) sokhranyayet otdeljnyij mekhanizm; novoye yeyo proyavleniye ne dobavlyayetsya.

## Kriterii zakryitiya

Povtor `FUM-СБОЙ-0078/ПРОЯВЛЕНИЕ-0002` dvustoronne svyazan s aktivnyim [FUM-STEP-0170](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0170-sokhranyatj-neizmennostj-vkhoda-do-zaversheniya-proverki.md): otdeljnaya regressiya dolzhna zapresjhatj zavisimyij kommit do terminaljnogo uspekha dopuska. Etot kriterij dopolnyayet iskhodnuyu zasjhitu neizmennosti vkhoda; razovyij praviljnyij poryadok tekusjhego kommita ne obyyavlyayet zaversheniye obsjhej meryi.

Pervichnyiye vyizovyi podtverzhdayut rannij start do terminaljnogo rezuljtata proizvoditelya. Sokhranenyi vse chetyire iskhoda, a zavershyonnyij proizvoditelj predshestvuyet uspeshnoj peresborke i validacii s nuzhnoj kartochkoj. Proveryayemyij ogranichennyij sposob vosstanovleniya opisan bez obesjhaniya universaljnogo predotvrasjheniya; STEP 0214 prinyal etu tochnuyu granicu. Polnaya priyomka obsjhego instrumenta ne podmenyayetsya razovyim uspeshnyim povtorom.

## Istochniki

- [Iskhodnyiye komandyi i otchyot epizoda](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/zapros.md), [posledovateljnostj i utochneniye klassifikacii](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/otchyot.md).
- [Sokhraneniye otdeljnoj diagnostiki](../Zhurnal/2026-09-11_15-48-40_MSK_prinyatj-planirovaniye-Gosuslug/zapros.md).
- [Prinyatj ogranichennoye vosstanovleniye](../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:01:16 MSK -->
<!-- content-sha256: sha256:53daac011ec632cdfa567c874f59a7b429058e54a2427a21bbe93e4506febe38 -->
<!-- FUM-MD-RECENCY:END -->
