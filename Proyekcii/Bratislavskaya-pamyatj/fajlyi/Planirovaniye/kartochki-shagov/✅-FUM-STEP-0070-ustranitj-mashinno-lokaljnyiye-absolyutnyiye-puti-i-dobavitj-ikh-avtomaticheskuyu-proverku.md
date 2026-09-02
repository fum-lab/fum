+++
schema_version = 1
card_id = "FUM-STEP-0070"
status = "completed"
+++
# Ustranitj mashinno-lokaljnyiye absolyutnyiye puti i dobavitj ikh avtomaticheskuyu proverku

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Ustranitj dejstvuyusjhiye mashinno-lokaljnyiye absolyutnyiye puti, opredelitj uzkuyu tipizirovannuyu politiku dopustimyikh sistemnyikh, istoricheskikh i testovyikh sluchayev i dobavitj proveryayemyij skaner soderzhimogo v obsjhij smoke-check repozitoriya.

## Rezuljtat

Pyatj dejstvuyusjhikh mashinno-lokaljnyikh putej v navyike glossariya i reyestre instrumentov zamenenyi perenosimyimi formami. First-party Swift-prototip poluchayet korenj tekusjhego checkout v runtime cherez `FUM_REPOSITORY_ROOT` i boljshe ne zavisit ot `#filePath`; otdeljno zafiksirovanyi granica Debug-metadannyikh i upstream-ogranicheniye `LinguisticKitBuildTool` bez izmeneniya submodule.

Dochernij prompt prokhodit rekursivnuyu mashinnuyu proverku vsekh strokovyikh polej do `show` i zapisi claim. Tri Markdown-generatora otklonyayut neperenosimyiye path-polya do zapisi, a svyaznostj otklonyayet absolyutnyiye i vyikhodyasjhiye za korenj Markdown-ssyilki. Novaya [proverka mashinno-lokaljnyikh putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md) dayot stabiljnyij tipizirovannyij otchyot po `git ls-files`, a obsjhij smoke-check yavno zapuskayet yeyo i padayet na iskusstvennoj mashinno-lokaljnoj regressii. Doslovnyiye zaprosyi i vneshniye arkhivyi ostayutsya report-only-proiskhozhdeniyem, a uzkiye isklyucheniya zakreplenyi po kategoriyam, prichinam i otpechatkam.

## Istochniki

- [iskhodnyij zapros](../../Zhurnal/2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/zapros.md), [audit](../../Zhurnal/2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/materialyi/revjyu/2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.md), [zhurnal](../../Zhurnal/2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/otchyot.md)
- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md), [zhurnal](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/otchyot.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:39dd41cc3e6b09d02f5fef845f742a55e2bf7ccea8481725b9865f34052c7756 -->
<!-- FUM-MD-RECENCY:END -->
