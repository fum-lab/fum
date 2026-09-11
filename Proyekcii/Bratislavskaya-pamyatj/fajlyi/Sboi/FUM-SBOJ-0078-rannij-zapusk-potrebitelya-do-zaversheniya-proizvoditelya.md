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

## Ozhidaniye i klassifikaciya

Sleduyusjhaya zavisimaya fajlovaya stadiya dopustima posle nablyudayemogo uspeshnogo zaversheniya predyidusjhej. Eto oshibka poryadka ispolneniya. 0043 zasjhisjhayet vkhod uzhe rabotayusjhej proverki ot izmeneniya; 0010 sokhranyayet rannij otkaz obsjhego shell-vyizova; novyij 0079 kasayetsya dejstviya posle uzhe izvestnogo otkaza. Ni odna iz etikh granic ne podmenyayet ranneye otsutstviye terminaljnogo rezuljtata.

## Mekhanizm i sistemnoye ustraneniye

Dostupnyij protokol sredyi uzhe razlichayet zhivuyu sessiyu i okonchateljnyij exit_code. Ogranichennoye vosstanovleniye ispoljzuyet etot protokol: dozhdatjsya terminaljnogo rezuljtata proizvoditelya, pri neuspekhe sokhranitj iskhod i ne nachinatj zavisimyij potrebitelj, pri uspekhe peresobratj proizvodnyij reyestr i dozhdatjsya yego rezuljtata do validacii. Takoye vosstanovleniye vyipolneno dlya epizoda. Universaljnyij mashinnyij zapret rannego zapuska i novyij obsjhij orkestrator ne realizovanyi i ne zayavlyayutsya.

## Svyazannyiye shagi

[STEP 0214](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0214-proveritj-vosstanovleniye-posledovateljnosti-zavisimyikh-stadij.md) prinimayet tochnyiye svideteljstva ogranichennogo vosstanovleniya po `FUM-СБОЙ-0078/ПРОЯВЛЕНИЕ-0001`. [Smezhnaya kartochka 0043](FUM-SBOJ-0043-izmeneniye-proveryayemogo-snimka-do-zaversheniya-proverki.md) sokhranyayet otdeljnyij mekhanizm; novoye yeyo proyavleniye ne dobavlyayetsya.

## Kriterii zakryitiya

Pervichnyiye vyizovyi podtverzhdayut rannij start do terminaljnogo rezuljtata proizvoditelya. Sokhranenyi vse chetyire iskhoda, a zavershyonnyij proizvoditelj predshestvuyet uspeshnoj peresborke i validacii s nuzhnoj kartochkoj. Proveryayemyij ogranichennyij sposob vosstanovleniya opisan bez obesjhaniya universaljnogo predotvrasjheniya; STEP 0214 prinyal etu tochnuyu granicu. Polnaya priyomka obsjhego instrumenta ne podmenyayetsya razovyim uspeshnyim povtorom.

## Istochniki

- [Iskhodnyiye komandyi i otchyot epizoda](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/zapros.md), [posledovateljnostj i utochneniye klassifikacii](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/otchyot.md).
- [Sokhraneniye otdeljnoj diagnostiki](../Zhurnal/2026-09-11_15-48-40_MSK_prinyatj-planirovaniye-Gosuslug/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:58:22 MSK -->
<!-- content-sha256: sha256:9f9f1826d271662ffe340eb2c1bde7791d5cd63241c5252d7c288b73da46c87d -->
<!-- FUM-MD-RECENCY:END -->
