+++
schema_version = 1
card_id = "FUM-STEP-0068"
status = "completed"
+++
# Sdelatj povtornoye arkhivirovaniye odnogo URL atomarnoj zamenoj upravlyayemogo snimka cherez staging-katalog i manifest fajlov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sdelatj povtornoye arkhivirovaniye odnogo URL atomarnoj zamenoj upravlyayemogo snimka cherez staging-katalog i manifest fajlov; dobavitj test polnogo snimka s posleduyusjhim nepolnyim ili neuspeshnyim povtorom.

## Rezuljtat

Arkhivator sobirayet novyij snimok otdeljno, proveryayet tochnyij `snapshot-manifest.json` i ustanavlivayet yego atomarnyim obmenom katalogov. Polnyij snimok s posleduyusjhim nepolnyim udalyayet staryiye uslovnyiye fajlyi, sboj do commit sokhranyayet prezhnij katalog, a nepodderzhivayemyij exchange zakryivayetsya bez zapisi; 21 avtonomnyij test prokhodit.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md), [zhurnal](../../Zhurnal/2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/otchyot.md), [fum-materialyi-zaprosov](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md), [revjyu proyekta](../../Zhurnal/2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:b49faa2b0568c546ba03bdb97b2f05534e22da4b0490360e3a0103c526278009 -->
<!-- FUM-MD-RECENCY:END -->
