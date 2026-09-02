+++
schema_version = 1
card_id = "FUM-STEP-0056"
status = "completed"
+++
# Sobratj yedinyij lokaljnyij smoke-check repozitoriya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sobratj yedinyij lokaljnyij smoke-check repozitoriya, kotoryij zapuskayet testyi vsekh lokaljnyikh avtomatizacij, peresborku proveryayemyikh reyestrov, recency-proverku i proverku svyaznosti vyibrannoj rabochej sessii bez sekretov i setevyikh zavisimostej po umolchaniyu.

## Rezuljtat

Sozdana lokaljnaya avtomatizaciya [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) so skriptom `run-smoke-check.py` i testami; ona obnaruzhivayet testyi `Инструменты/*/tests`, peresobirayet i validiruyet planovyij reyestr, zapuskayet `fum-svezhestj-markdown --check`, proveryayet teplovuyu kartu grafa Obsidian cherez `fum-svezhestj-grafa-obsidian --check` i proveryayet svyaznostj vyibrannoj sessii cherez `fum-svyaznostj-rabochej-sessii`.

## Istochniki

- [iskhodnyij zapros 2026-07-01 14:02:57 MSK](../../Zhurnal/2026-07-01_14-02-57_MSK/zapros.md), [iskhodnyij zapros 2026-07-01 14:12:17 MSK](../../Zhurnal/2026-07-01_14-12-17_MSK/zapros.md), [iskhodnyij zapros 2026-07-01 15:35:24 MSK](../../Zhurnal/2026-07-01_15-35-24_MSK/zapros.md), [zhurnal 2026-07-01 15:35:24 MSK](../../Zhurnal/2026-07-01_15-35-24_MSK/otchyot.md), [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md), [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f6f57c8833bac22f6326c185966fcc3ae31240f07cb6fc5473692e03ed43a886 -->
<!-- FUM-MD-RECENCY:END -->
