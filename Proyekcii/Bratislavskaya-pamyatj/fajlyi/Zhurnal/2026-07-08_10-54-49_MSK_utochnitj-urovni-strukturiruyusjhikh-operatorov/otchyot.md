# Otchyot 2026-07-08 10:54:49 MSK - Utochnitj urovni strukturiruyusjhikh operatorov

Sessiya utochnila, chto [strukturiruyusjhiye operatoryi FUM](../../Glossarij/strukturiruyusjhij-operator-FUM.md) obrazuyut iyerarkhiyu semanticheskikh svyazej. Nizhniye operatoryi mogut opisyivatj yazyik, pisjmennostj i formu zapisi, a boleye vyisokiye operatoryi svyazyivayut konstrukcii cherez obsjhij smyisl i poetomu mogut soyedinyatj russkiye i anglijskiye strukturyi.

## Chto izmenilosj

- V glossarii [strukturiruyusjhij operator FUM](../../Glossarij/strukturiruyusjhij-operator-FUM.md) opisan kak element dereva svyazej: ot operatorov suffiksa, okonchaniya, transliteracii i variantov zapisi do mezhyyazyikovyikh semanticheskikh operatorov.
- V [modeli pamyati FUM](../../Dokumentaciya/01-modelj-pamyati-FUM.md), [arkhitekture](../../Dokumentaciya/22-arkhitektura-FUM.md) i [potokovoj samostrukturizacii](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md) zafiksirovano razlicheniye yazyikovo-specifichnyikh i mezhyyazyikovyikh urovnej operatornoj pamyati.
- V [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) budusjhij Swift-prototip dopolnen fiksturami dlya nizkourovnevyikh formaljnyikh svyazej i vyisokourovnevyikh russko-anglijskikh semanticheskikh svyazej.

## Resheniye

Otdeljnaya novaya avtomatizaciya ne sozdavalasj. Povtoryayemaya chastj rabotyi ostayotsya v budusjhem prototipe pamyati strukturiruyusjhikh operatorov: on dolzhen proveryatj ne toljko vyiigryish szhatiya i porozhdeniya, no i urovenj svyazi, na kotorom operator primenyayetsya.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-08_10-54-49_MSK_уточнить-уровни-структурирующих-операторов.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-08_10-54-49_MSK_уточнить-уровни-структурирующих-операторов.md`

## Vozmozhnoye prodolzheniye

Pri realizacii prototipa nuzhno podgotovitj paryi fikstur: poverkhnostnaya normalizaciya odnoj yazyikovoj formyi, naprimer kirillicheskoj i latinskoj zapisi, i otdeljnyij primer mezhyyazyikovogo svyazyivaniya russkoj i anglijskoj konstrukcii cherez obsjhij smyisl. Eto pomozhet ne smeshatj transliteraciyu, morfologiyu i semanticheskij perenos v odin tip operatora.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-08 10:54:49 MSK - Utochnitj urovni strukturiruyusjhikh operatorov](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:9a55522fbf7efde7db27097f87e2620881e03cfd7c8bdd3e4bfd4cf9ffad8b6e -->
<!-- FUM-MD-RECENCY:END -->
