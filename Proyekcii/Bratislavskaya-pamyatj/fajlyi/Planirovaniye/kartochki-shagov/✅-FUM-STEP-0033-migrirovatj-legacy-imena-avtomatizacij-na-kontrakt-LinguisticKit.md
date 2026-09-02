+++
schema_version = 1
card_id = "FUM-STEP-0033"
status = "completed"
+++
# Migrirovatj legacy-imena avtomatizacij na kontrakt LinguisticKit

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Migrirovatj tochnyij legacy-nabor prezhnikh repozitornyikh i deklarativnyikh imyon avtomatizacij na zhivoj kontrakt LinguisticKit bez izmeneniya povedeniya avtomatizacij.

## Rezuljtat

Shestnadcatj prezhnikh repozitornyikh imyon avtomatizacij zamenenyi tochnyimi slug, poluchennyimi iz russkikh smyislovyikh istochnikov zhivyim LinguisticKit. Odno deklarativnoye imya poluchilo vyichislennuyu otobrazhayemuyu latinskuyu formu; reyestr soderzhit `19` tekusjhikh repozitornyikh i `5` otobrazhayemyikh imyon pri pustyikh massivakh `legacy` i `legacy_display`.

Migraciya ogranichena identichnostyami, putyami, ssyilkami i konfiguracionnyimi vyizovami. Algoritmyi, CLI, profili, raspisaniya i povedeniye avtomatizacij ne menyalisj; gitlink, zakreplyonnaya reviziya, tablica i fork/upstream-kontrakt LinguisticKit sokhranenyi. Istoricheskiye iskhodnyiye tekstyi zaprosov i materialyi istochnikov ne perepisyivalisj, a lokaljnyiye Markdown-ssyilki perevedenyi na susjhestvuyusjhiye novyiye puti.

Krasnaya faza TDD nablyudayemo vyiyavila vesj legacy-nabor i prezhnij deklarativnyij zagolovok. Posle migracii proshli `21/21` test proverki imyon i zhivaya proverka `19` repozitornyikh avtomatizacij cherez LinguisticKit; ostaljnyiye lokaljnyiye kontraktyi i obsjhij smoke-check proverenyi na novyikh putyakh v svyazannoj rabochej sessii.

## Istochniki

- [iskhodnyij zapros o vyipolnenii migracii](../../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md), [zhurnal](../../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/otchyot.md)
- [iskhodnyij zapros o forkakh Git-zavisimostej](../../Zhurnal/2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/zapros.md), [zhurnal](../../Zhurnal/2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/otchyot.md), [iskhodnyij zapros o transliteracii](../../Zhurnal/2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md), [proverka nazvanij avtomatizacij](../../Instrumentyi/fum-proverka-nazvanij-avtomatizacij/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:44e7d31969cdda1db5ee21ae8a2934d3cb16136f5f064c06d05b90ea73666d17 -->
<!-- FUM-MD-RECENCY:END -->
