# Otchyot 2026-07-10 05:38:47 MSK - Otvetitj o svyazi operatorov i interfejsa FUM uzla

Rabochaya sessiya otvetila na vopros o sootnoshenii strukturiruyusjhikh operatorov FUM i interfejsa FUM-uzla. Proverka susjhestvuyusjhej dokumentacii pokazala, chto eto otnosheniye uzhe zafiksirovano: operatornaya sistema dayot strukturnyij, obyyasniteljnyij i perevodyasjhij sloj, a interfejs FUM-uzla yavlyayetsya boleye shirokoj granicej, cherez kotoruyu etot sloj predyyavlyayetsya samomu uzlu, cheloveku, drugim uzlam, servisam i poduzlam.

Korotkaya formula otveta: strukturiruyusjhiye operatoryi zadayut, chto raspoznano, sobrano, svyazano, provereno i kak eto mozhno predyyavitj; interfejs FUM-uzla zadayot, komu, v kakoj forme, s kakimi pravami, trassami, podtverzhdeniyami i obratnyimi dejstviyami eto stanovitsya dostupno. Poetomu ekrannaya karta operatornogo grafa yavlyayetsya ne dekorativnyim UI, a interfejsnoj proyekciyej operatornoj pamyati, a dejstviye cheloveka v takoj karte vozvrasjhayetsya v operatornuyu sistemu kak proveryayemoye sobyitiye.

Novoj predmetnoj pravki v dokumentaciyu ne potrebovalosj: [interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md) uzhe soderzhit razdel o grafovom sloye pamyati i ekrannoj proyekcii sistemyi strukturiruyusjhikh operatorov, a [sistema strukturiruyusjhikh operatorov FUM](../../Dokumentaciya/33-sistema-strukturiruyusjhikh-operatorov-FUM.md) uzhe opisyivayet operatoryi predyyavleniya i obratnyiye sobyitiya interfejsa.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Sistema strukturiruyusjhikh operatorov FUM](../../Dokumentaciya/33-sistema-strukturiruyusjhikh-operatorov-FUM.md)
- [Strukturiruyusjhij operator FUM](../../Glossarij/strukturiruyusjhij-operator-FUM.md)
- [Sistema strukturiruyusjhikh operatorov FUM](../../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md)
- [Predlozheniya o sleduyusjhikh shagakh FUM](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-10_05-38-47_MSK_ответить-о-связи-операторов-и-интерфейса-FUM-узла.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-10_05-38-47_MSK_ответить-о-связи-операторов-и-интерфейса-FUM-узла.md` - proshlo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:9445e09335e8dfae99aa7fd5d29ee0a110cd9874c8e6283090a1b11e95573870 -->
<!-- FUM-MD-RECENCY:END -->
