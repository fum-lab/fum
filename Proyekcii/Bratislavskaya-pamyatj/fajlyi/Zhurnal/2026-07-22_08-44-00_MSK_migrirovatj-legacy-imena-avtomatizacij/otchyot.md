# Otchyot 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij

Tochnyij legacy-nabor avtomatizacij perenesyon na imena, poluchennyiye zhivyim LinguisticKit iz russkikh smyislovyikh istochnikov. Shestnadcatj lokaljnyikh katalogov teperj ispoljzuyut kanonicheskiye slug, deklarativnaya avtomatizaciya pokazyivayet latinskuyu formu, a reyestr boljshe ne soderzhit aktivnyikh isklyuchenij `legacy` i `legacy_display`.

## Rezuljtat migracii

| Prezhneye imya                  | Russkij smyislovoj istochnik         | Forma LinguisticKit                  | Novoye imya kataloga                       |
| ---------------------------- | ---------------------------------- | ------------------------------------ | ---------------------------------------- |
| `fum-branch-next-step`       | `следующий шаг ветки`              | `sleduyusjhij shag vetki`            | `fum-sleduyusjhij-shag-vetki`            |
| `fum-doc-aggregation`        | `сборка сводной документации`      | `sborka svodnoj dokumentacii`        | `fum-sborka-svodnoj-dokumentacii`        |
| `fum-estimates`              | `оценки`                           | `ocenki`                             | `fum-ocenki`                             |
| `fum-glossary`               | `глоссарий`                        | `glossarij`                          | `fum-glossarij`                          |
| `fum-md-recency`             | `свежесть Markdown`                | `svezhestj Markdown`                 | `fum-svezhestj-markdown`                 |
| `fum-obsidian-graph-recency` | `свежесть графа Obsidian`          | `svezhestj grafa Obsidian`           | `fum-svezhestj-grafa-obsidian`           |
| `fum-planning-registry`      | `реестр планирования`              | `reyestr planirovaniya`              | `fum-reyestr-planirovaniya`              |
| `fum-project-files`          | `проектные файлы`                  | `proyektnyiye fajlyi`                | `fum-proyektnyiye-fajlyi`                |
| `fum-prototype-launch`       | `запуск прототипов`                | `zapusk prototipov`                  | `fum-zapusk-prototipov`                  |
| `fum-question-backlinks`     | `обратные ссылки вопросов`         | `obratnyiye ssyilki voprosov`        | `fum-obratnyiye-ssyilki-voprosov`        |
| `fum-readme-index`           | `индекс README`                    | `indeks README`                      | `fum-indeks-readme`                      |
| `fum-request-materials`      | `материалы запросов`               | `materialyi zaprosov`                | `fum-materialyi-zaprosov`                |
| `fum-session-coherence`      | `связность рабочей сессии`         | `svyaznostj rabochej sessii`         | `fum-svyaznostj-rabochej-sessii`         |
| `fum-session-time`           | `московское время рабочей сессии`  | `moskovskoye vremya rabochej sessii` | `fum-moskovskoye-vremya-rabochej-sessii` |
| `fum-smoke-check`            | `комплексная проверка репозитория` | `kompleksnaya proverka repozitoriya` | `fum-kompleksnaya-proverka-repozitoriya` |
| `fum-work-review`            | `ревью проделанной работы`         | `revjyu prodelannoj rabotyi`         | `fum-revjyu-prodelannoj-rabotyi`         |

Deklarativnoye imya `построение описания FUM для адресата` poluchilo otobrazhayemuyu formu `postroyeniye opisaniya FUM dlya adresata`; putj samogo russkoyazyichnogo dokumenta sokhranyon kirillicheskim. Reyestr teperj soderzhit `19` tekusjhikh repozitornyikh i `5` otobrazhayemyikh imyon pri pustyikh `legacy` i `legacy_display`.

## Granica primenimosti

Migraciya menyayet toljko identichnosti: katalogi, deklarativnyij zagolovok, ssyilki, konfiguracionnyiye puti i komandyi vyizova. Algoritmyi, CLI, dannyiye, profili i raspisaniya ne menyalisj. V zhivoj heartbeat-avtomatizacii zamenenyi toljko puti k kontraktu sleduyusjhego shaga; yeyo imya, pyatiminutnoye raspisaniye, status i ostaljnoj prompt sokhranenyi.

Iskhodnyiye tekstyi zaprosov i snimki v `Источники/` ostavlenyi doslovnyimi. Istoricheskiye prostyiye upominaniya prezhnikh imyon ostayutsya istoriyej, a naznacheniya lokaljnyikh Markdown-ssyilok perevedenyi na susjhestvuyusjhiye novyiye puti. Reviziya `837e2ce107b97ee7b9d3344c9fe99142281fe393`, gitlink, tablica `.ru` i fork/upstream LinguisticKit ne izmenenyi. Khyesh vremennogo Swift-lint-isklyucheniya obnovlyon toljko iz-za vklyuchyonnogo v zasjhisjhyonnyij snimok novogo puti `swift-format.json`.

## Proverki

Krasnaya TDD-faza pokazala vse shestnadcatj legacy-zapisej i prezhnij deklarativnyij zagolovok. Posle migracii proshli `21/21` test proverki imyon i zhivoj vyizov LinguisticKit dlya `19` avtomatizacij. Vse ostaljnyiye lokaljnyiye naboryi testov proshli na novyikh putyakh; smoke `--list` posle tochechnogo obnovleniya khyesha postroil polnyij plan iz `36` shagov, a itogovyij smoke-check proshyol vse `36/36` shagov.

Planovyij reyestr proshyol `19/19` testov, build i validate; vetochnyij kontrakt — `41/41`, validate i fenced `show` novogo `master-fum-step-0030-ready-v1`. Audit podtverdil susjhestvovaniye i registr `901` migrirovannoj ssyilki, neizmennostj vsekh `231` prezhnikh blokov iskhodnogo teksta zaprosov, `.gitmodules` i gitlink LinguisticKit. Recency, graf Obsidian, svyaznostj polnogo spiska iz `315` putej i `git diff --check` proshli na itogovom snimke.

`FUM-STEP-0033` zavershena. V rabochem nabore `master` novyim yedinstvennyim `ready` vyibran `FUM-STEP-0030`; trebuyusjhaya otdeljnogo poljzovateljskogo razresheniya `FUM-STEP-0035` sokhranena kak `blocked`.

## Zatronutyiye materialyi

- [reyestr nazvanij avtomatizacij](../../Instrumentyi/reyestr-nazvanij-avtomatizacij.json)
- [proverka nazvanij avtomatizacij](../../Instrumentyi/fum-proverka-nazvanij-avtomatizacij/SKILL.md)
- [deklarativnaya avtomatizaciya opisaniya dlya adresata](../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md)
- [vyipolnennaya kartochka FUM-STEP-0033](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0033-migrirovatj-legacy-imena-avtomatizacij-na-kontrakt-LinguisticKit.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [kontrakt transliteracii nazvanij avtomatizacij](../2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)
- [sessiya podklyucheniya LinguisticKit](../2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c8ec81b711b911a4f5e75750870a031018161203f5054e1f96f0a02517bcb29f -->
<!-- FUM-MD-RECENCY:END -->
