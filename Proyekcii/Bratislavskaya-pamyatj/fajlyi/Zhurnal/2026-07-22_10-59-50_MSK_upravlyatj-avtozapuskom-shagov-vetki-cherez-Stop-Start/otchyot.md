# Otchyot 2026-07-22 10:59:50 MSK - Upravlyatj avtozapuskom shagov vetki cherez Stop Start

Avtozapusk sleduyusjhikh shagov vetki poluchil shtatnoye ruchnoye upravleniye iz kartochki avtomatizacii v prikreplyonnoj dispetcherskoj zadache. Susjhestvuyusjhij heartbeat mozhno ostanovitj cherez `Stop` i vozobnovitj cherez `Start` bez vtorogo raspisaniya, otdeljnogo flaga pauzyi ili izmeneniya vetochnogo rabochego nabora.

## Rezuljtat

`Stop` perevodit tu zhe heartbeat-avtomatizaciyu v `PAUSED` i zapresjhayet yeyo budusjhiye planovyiye tiki. `Start` vozvrasjhayet yeyo v `ACTIVE` s prezhnimi celevoj zadachej, promptom i pyatiminutnyim raspisaniyem. Shtatnyij interfejs ostayotsya vnutri zadachi, k kotoroj prikreplena avtomatizaciya; neprozrachnyiye lokaljnyiye identifikatoryi ne perenosyatsya v pamyatj FUM.

Pravilo zakrepleno v `AGENTS.md`, obsjhej dokumentacii vosproizvodimyikh avtomatizacij, navyike sleduyusjhego shaga vetki i shablone vneshnego heartbeat. Reyestr instrumentov teperj pryamo otrazhayet prosmotr i izmeneniye sostoyaniya avtomatizacii cherez shtatnyij kontrakt Codex.

## Semantika ostanovki i vozobnovleniya

Ostanovka vliyayet toljko na budusjhiye srabatyivaniya raspisaniya. Uzhe nachavshijsya tik ili sozdannaya obyichnaya zadacha prodolzhayut zhitj nezavisimo ot statusa heartbeat; ikh claim i mesto v FIFO ne osvobozhdayutsya. Statusyi `ready`, `paused` i `blocked` v rabochem nabore opisyivayut ispolnimostj kartochek i ne vyivodyatsya iz `PAUSED` ili `ACTIVE` vneshnej avtomatizacii.

Vozobnovleniye ne yavlyayetsya komandoj nemedlennogo zapuska. Sleduyusjhij planovyij tik snova prokhodit dve proverki nablyudayemogo prostoya, `show`, claim i FIFO. Yesli prezhnij claim yesjhyo susjhestvuyet, `already_claimed` predotvrasjhayet povtor. Yego osvobozhdeniye ostayotsya otdeljnyim fenced-vosstanovleniyem po nablyudyonnomu `lease_id` i vneshnemu dokazateljstvu okonchateljnoj ostanovki prezhnej zadachi.

## TDD i proverka zhivogo heartbeat

Regressionnyij test snachala podtverdil krasnoye sostoyaniye: shablon ne opisyival Stop/Start i ikh svyazj s `PAUSED`/`ACTIVE`. Posle obnovleniya on proveryayet operatorskuyu poverkhnostj, sokhraneniye yedinstvennoj avtomatizacii i zapretyi otmenyatj tekusjhij tik, snimatj claim, obkhoditj proverki prostoya ili FIFO.

Zhivoj heartbeat proshyol kontroliruyemyij cikl `ACTIVE → PAUSED → ACTIVE` shtatnyim instrumentom Codex. Oba promezhutochnyikh sostoyaniya prochitanyi iz sokhranyonnoj konfiguracii, a sravneniye podtverdilo neizmennostj privyazannoj zadachi, prompta i raspisaniya. Itogovyij status — `ACTIVE`.

## Proverki

Avtonomnyij nabor sleduyusjhego shaga vetki proshyol `43` testa, vklyuchaya novuyu regressiyu Stop/Start; FIFO-ocheredj proshla `31` test. Validaciya rabochego nabora i `show` podtverdili neizmennyij `ready` pokoleniya `FUM-STEP-0023`. Polnyij smoke-check repozitoriya zavershil vse `37` shagov: lokaljnyiye avtomatizacii, oba SwiftPM-paketa, strogij lint, reyestryi, ssyilki, recency, graf Obsidian i svyaznostj rabochej sessii.

## Prodolzheniye

Rabochij nabor aktivnoj vetki ne menyalsya: etot zapros ne vyipolnyayet `FUM-STEP-0023` i ne udovletvoryayet usloviye vozobnovleniya `FUM-STEP-0035`. Novaya kartochka shaga ne nuzhna, potomu chto operatorskoye upravleniye dejstvuyusjhim heartbeat zaversheno v etoj sessii.

## Zatronutyiye materialyi

- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [shablon heartbeat-dispetchera](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [regressionnyiye testyi](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [iskhodnyij zapros o zapuske sleduyusjhikh shagov vetok](../2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [oficialjnyij spravochnik zaplanirovannyikh zadach Codex](https://developers.openai.com/codex/app/automations)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2a466e698e94f7c7365fafa5dd3ec10601b3d88cffde51d82952fb4f23c58bb5 -->
<!-- FUM-MD-RECENCY:END -->
