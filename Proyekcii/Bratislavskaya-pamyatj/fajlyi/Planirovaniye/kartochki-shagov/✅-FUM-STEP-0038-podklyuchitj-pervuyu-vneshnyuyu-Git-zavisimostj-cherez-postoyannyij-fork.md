+++
schema_version = 1
card_id = "FUM-STEP-0038"
status = "completed"
+++
# Podklyuchitj pervuyu vneshnyuyu Git-zavisimostj cherez postoyannyij fork

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Podklyuchitj pervuyu vneshnyuyu Git-zavisimostj cherez postoyannyij fork ryadom s aktualjnyim FUM i sozdatj TDD-avtomatizaciyu proverki vsej Git-topologii.

## Rezuljtat

Fork `fum-lab/LinguisticKit` sinkhronizirovan s originalom, vyibrannaya sovmestimaya reviziya podklyuchena kak submodule, a `fum-proverka-git-zavisimostej` avtonomno proveryayet vladeljca forka, roli remote, dostizhimostj revizii iz lokaljno poluchennyikh refs forka, `.gitmodules`, chistotu i gitlink.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md), [zhurnal](../../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/otchyot.md), [opisaniye zavisimosti](../../Zavisimosti/README.md), [avtomatizaciya proverki](../../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:43a163d3739f308db8f82fe3f72f9f58e6d40e6cc649e465ec3558d3f94b92dc -->
<!-- FUM-MD-RECENCY:END -->
