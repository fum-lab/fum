# Otchyot 2026-07-22 10:31:30 MSK - Zapretitj absolyutnyiye puti v promptakh avtozadach

Promptyi obyichnyikh zadach, kotoryiye sozdayot pyatiminutnyij heartbeat-dispetcher, perevedenyi na puti otnositeljno kornya vyibrannogo proyekta. Ispravleniye primeneno i k vosproizvodimomu shablonu v pamyati FUM, i k uzhe zaregistrirovannomu aktivnomu heartbeat Codex.

## Rezuljtat

Absolyutnyij korenj klona boljshe ne kopiruyetsya v dochernij prompt. Sozdannaya zadacha poluchayet `AGENTS.md`, puti oboikh navyikov i tochnyiye `record_path`, `card_path` i `project_path` v repozitorno-otnositeljnoj forme. Svobodnyiye zadacha i kriterii takzhe zasjhisjhenyi fail-closed-usloviyem: absolyutnyij putj v peredavayemom znachenii ostanavlivayet sozdaniye do `create_thread` i snimayet toljko sobstvennyij claim dispetchera.

Absolyutnyij korenj sokhranyon vo vneshnem heartbeat toljko tam, gde bez nego neljzya odnoznachno vyibratj lokaljnyij proyekt i rabochij katalog. Eto lokaljnoye sostoyaniye ne perenositsya v sozdavayemuyu zadachu i ne stanovitsya chastjyu publikuyemoj pamyati.

## Audit prezhnego pravila

Yavnogo obsjhego zapreta v `AGENTS.md` i yego istorii ne byilo. Blizhajsheye pravilo otnositsya k konfiguracii avtozapuska interfejsa FUM, a neskoljko lokaljnyikh avtomatizacij nezavisimo ispoljzuyut otnositeljnyiye puti. Sam heartbeat byil isklyucheniyem s pervogo kommita i porodil dvenadcatj doslovno sokhranyonnyikh zaprosov s mashinno-lokaljnyim kornem. Eti istoricheskiye istochniki ostavlenyi bez izmenenij.

## TDD i proverka aktivnogo heartbeat

Regressionnyij test vyidelyayet iz shablona imenno kontrakt dochernego prompta. Krasnaya faza vosproizvela otsutstviye zapreta i nalichiye `<КОРЕНЬ_КЛОНА>/...`; zelyonaya faza trebuyet otnositeljnyiye `AGENTS.md` i puti navyikov, tochnyiye otnositeljnyiye puti zapisi, kartochki i proyekta, fail-closed-granicu dlya dinamicheskikh znachenij i otsutstviye kornya klona v dochernem uchastke. Otdeljno test sokhranyayet absolyutnyij korenj vo vneshnikh shagakh proverki rabochego dereva i vyibora proyekta.

Zaregistrirovannyij heartbeat obnovlyon shtatnyim instrumentom Codex. Mashinnaya sverka podtverdila sovpadeniye sokhranyonnogo vneshnego prompta s repozitornyim shablonom, sokhranyonnyiye aktivnyij status i pyatiminutnyij ritm i otsutstviye kornya klona v dochernem uchastke.

## Proverki

Polnyij avtonomnyij nabor dispetchera proshyol `42` testa, a nabor ocheredi — `31` test. Validaciya i chteniye sleduyusjhego shaga vetki, recency- i grafovaya proverki, proverka svyaznosti rabochej sessii, obsjhaya smoke-proverka repozitoriya i `git diff --check` zavershilisj uspeshno.

## Prodolzheniye

Vetochnyij rabochij nabor ne menyalsya: tekusjhij poljzovateljskij zapros ne vyipolnyayet `FUM-STEP-0023` i ne udovletvoryayet usloviye vozobnovleniya `FUM-STEP-0035`. Dopolniteljnaya kartochka ne nuzhna, potomu chto dejstvuyusjhij heartbeat ispravlen v etoj zhe sessii.

## Zatronutyiye materialyi

- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [shablon heartbeat-dispetchera](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [regressionnyiye testyi](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [iskhodnyij zapros o zapuske sleduyusjhikh shagov vetok](../2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:24d7b6e65a0c8d429896d7118b8d5be53a8eecfb24c3b129754705fbb8984245 -->
<!-- FUM-MD-RECENCY:END -->
