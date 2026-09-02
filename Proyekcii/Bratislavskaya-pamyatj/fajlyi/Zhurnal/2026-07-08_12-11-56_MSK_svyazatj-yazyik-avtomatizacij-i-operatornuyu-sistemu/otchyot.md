# Otchyot 2026-07-08 12:11:56 MSK - Svyazatj yazyik avtomatizacij i operatornuyu sistemu

Sessiya zakrepila svyazj mezhdu [yazyikom avtomatizacij FUM](../../Glossarij/yazyik-avtomatizacij-FUM.md) i [sistemoj strukturiruyusjhikh operatorov FUM](../../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md): yazyik avtomatizacij yavlyayetsya ispolnyayemoj proyekciyej toj chasti operatornoj sistemyi, kotoruyu uzhe mozhno stabilizirovatj sintaksisom, tipami, effektami, proverkami, trassami i lokaljnyim zapuskom.

## Chto izmenilosj

- V dokumente [LLM-oriyentirovannyij yazyik avtomatizacij](../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md) dobavlen razdel o svyazi s operatornoj sistemoj.
- V [sisteme strukturiruyusjhikh operatorov FUM](../../Dokumentaciya/33-sistema-strukturiruyusjhikh-operatorov-FUM.md) utochneno, chto yazyik avtomatizacij ne yavlyayetsya vneshnim dopolneniyem: kazhdaya yego konstrukciya dolzhna imetj operatornyij profilj.
- [Obzor proyekta](../../Dokumentaciya/00-obzor-proyekta.md), [vosproizvodimyiye avtomatizacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md) i [arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md) poluchili korotkiye svyazki mezhdu yazyikom avtomatizacij i sistemoj operatorov.
- Glossarnyiye statji [yazyik avtomatizacij FUM](../../Glossarij/yazyik-avtomatizacij-FUM.md) i [sistema strukturiruyusjhikh operatorov FUM](../../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md) fiksiruyut yazyik avtomatizacij kak ispolnyayemuyu proyekciyu verkhnikh operatornyikh form.
- [Planirovaniye sleduyusjhikh shagov](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) utochnilo, chto budusjhij Swift-prototip operatornoj pamyati dolzhen proveryatj perekhod ot operatora k konstrukcii yazyika avtomatizacij i obratnuyu svyazj ot trassyi zapuska k operatornoj sisteme.

## Resheniye

Novaya liniya ne sozdayot otdeljnyij samostoyateljnyij DSL poverkh FUM. Ona utochnyayet obsjhij princip: snachala FUM uchitsya videtj ustojchivyiye formyi kak operatoryi raspoznavaniya, porozhdeniya, proverki i obyyasneniya; zatem chastj etikh operatorov poluchayet ispolnyayemuyu formu v yazyike avtomatizacij; posle zapuska trassyi avtomatizacij vozvrasjhayutsya v operatornuyu sistemu kak material dlya utochneniya, oslableniya, otbora ili otkloneniya operatorov.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-08_12-11-56_MSK_связать-язык-автоматизаций-и-операторную-систему.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-08_12-11-56_MSK_связать-язык-автоматизаций-и-операторную-систему.md`

## Vozmozhnoye prodolzheniye

Otdeljnoye novoye predlozheniye ne trebuyetsya: aktualjnyij Swift-prototip operatornoj pamyati uzhe dolzhen proveryatj operatornyij graf kak obsjhij yazyik mezhdu potokom, pamyatjyu, LLM, avtomatizaciyami, modulyami i dejstviyem. Teperj kriterij prototipa utochnyon: on dolzhen pokazatj, kak povtoryayemaya operatornaya forma stanovitsya konstrukciyej yazyika avtomatizacij i kak trassa ispolneniya vozvrasjhayet proverochnyiye dannyiye v sistemu operatorov.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-08 12:11:56 MSK - Svyazatj yazyik avtomatizacij i operatornuyu sistemu](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e8a46170a41d42e1f2dc908fa969305a67e30f6272278e3538c5f8bed087ebef -->
<!-- FUM-MD-RECENCY:END -->
