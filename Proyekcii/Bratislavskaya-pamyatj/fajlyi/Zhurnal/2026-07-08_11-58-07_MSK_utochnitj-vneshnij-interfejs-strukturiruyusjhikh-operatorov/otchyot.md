# Otchyot 2026-07-08 11:58:07 MSK - Utochnitj vneshnij interfejs strukturiruyusjhikh operatorov

Sessiya utochnila rolj [sistemyi strukturiruyusjhikh operatorov FUM](../../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md): eto ne toljko obsjhij grafovyij yazyik mezhdu sloyami FUM, no i vneshnij simvolicheskij interfejs mezhdu neyavnyimi znaniyami cheloveka i neyavnyimi znaniyami LLM.

## Chto izmenilosj

- V [sisteme strukturiruyusjhikh operatorov FUM](../../Dokumentaciya/33-sistema-strukturiruyusjhikh-operatorov-FUM.md) utochnyon razdel obyyasnimosti: chelovek i LLM sovmestno vyinosyat znaniya v operatornuyu formu, a algoritmyi proveryayut operatoryi na potokakh, vyiyavlyayut oshibki i nedostayusjhiye strukturyi.
- [Potokovaya samostrukturizaciya](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md), [modelj pamyati](../../Dokumentaciya/01-modelj-pamyati-FUM.md) i [obzor proyekta](../../Dokumentaciya/00-obzor-proyekta.md) poluchili korotkiye svyazki s etoj formulirovkoj.
- Glossarnyiye statji [sistema strukturiruyusjhikh operatorov FUM](../../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md) i [strukturiruyusjhij operator FUM](../../Glossarij/strukturiruyusjhij-operator-FUM.md) teperj pryamo fiksiruyut interfejs mezhdu neyavnyimi znaniyami cheloveka i LLM.
- [Planirovaniye sleduyusjhikh shagov](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) utochnilo budusjhij Swift-prototip: on dolzhen proveryatj ne toljko operatornyij graf, no i svyazku neyavnoye znaniye -> operator -> algoritmicheskaya proverka -> povtornoye ispoljzovaniye.

## Resheniye

Novaya formulirovka ne sozdayot otdeljnuyu vetku arkhitekturyi. Ona delayet tochneye uzhe vyidelennuyu liniyu operatornoj pamyati: znaniye stanovitsya prigodnyim dlya FUM togda, kogda ono vyineseno v proveryayemyiye operatoryi, primeneno k potokam, proshlo proverku na oshibki i ostatki i mozhet byitj snova ispoljzovano chelovekom, LLM, avtomatizaciyej ili modulem.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-08_11-58-07_MSK_уточнить-внешний-интерфейс-структурирующих-операторов.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-08_11-58-07_MSK_уточнить-внешний-интерфейс-структурирующих-операторов.md`

## Vozmozhnoye prodolzheniye

Otdeljnogo novogo predlozheniya ne trebuyetsya: aktualjnyij Swift-prototip operatornoj pamyati uzhe dolzhen proveryatj sistemu operatorov kak obsjhij yazyik mezhdu potokom, pamyatjyu, LLM, avtomatizaciyami, modulyami i dejstviyem. Teperj kriterij prototipa utochnyon: on dolzhen pokazatj, kak neyavnoye znaniye cheloveka i LLM stanovitsya proveryayemoj operatornoj formoj i povtorno ispoljzuyetsya posle algoritmicheskoj proverki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-08 11:58:07 MSK - Utochnitj vneshnij interfejs strukturiruyusjhikh operatorov](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0afb627293255c33c84829616a713625d7dee078523e405e0492e27dc6f88225 -->
<!-- FUM-MD-RECENCY:END -->
