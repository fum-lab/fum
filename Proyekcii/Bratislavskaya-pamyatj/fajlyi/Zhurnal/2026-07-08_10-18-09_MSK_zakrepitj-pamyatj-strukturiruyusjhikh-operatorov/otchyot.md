# Otchyot 2026-07-08 10:18:09 MSK - Zakrepitj pamyatj strukturiruyusjhikh operatorov

Sessiya utochnila nizhneye yadro budusjhego FUM: [pamyatj FUM](../../Glossarij/pamyatj-FUM.md) dolzhna khranitj [strukturiruyusjhiye operatoryi](../../Glossarij/strukturiruyusjhij-operator-FUM.md) kak proveryayemuyu formu predvariteljnyikh znanij. Takiye operatoryi mogut vyivoditjsya iz syirogo potoka, zadavatjsya chelovekom, predlagatjsya LLM ili utochnyatjsya avtomatizaciyej, no zakreplyayutsya toljko po poljze dlya predskazaniya, szhatiya, porozhdeniya i dejstviya.

## Chto izmenilosj

- V [potokovoj samostrukturizacii FUM](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md) zakrepleno, chto pamyatj strukturiruyusjhikh operatorov yavlyayetsya minimaljnyim yadrom pervoj realizacii, a ne prosto slovaryom poverkh samotokenizacii.
- V [modeli pamyati FUM](../../Dokumentaciya/01-modelj-pamyati-FUM.md) opisano, chto operatornaya pamyatj dolzhna khranitj predvariteljnyiye znaniya, kandidatov, prichinyi otkaza i neodnoznachnosti, a nedostayusjhij element potoka dolzhen schitatjsya diagnosticheskim sobyitiyem.
- V [arkhitekture FUM](../../Dokumentaciya/22-arkhitektura-FUM.md) operatornaya pamyatj opisana kak sloj tipizacii vkhodnogo potoka, kotoryij delayet potok kompaktneye dlya kontekstnogo okna LLM i trebuyet proverki novyikh operatorov.
- V glossarii utochnyon termin [Strukturiruyusjhij operator FUM](../../Glossarij/strukturiruyusjhij-operator-FUM.md): operator mozhet zadavatjsya zaraneye, popolnyatjsya vo vremya analiza i ne dolzhen prevrasjhatj oshibku vkhodnogo potoka v ustojchivoye pravilo.
- V [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) minimaljnyij Swift-prototip suffiksno-prediktivnoj pamyati i samotokenizacii utochnyon kak prototip pamyati strukturiruyusjhikh operatorov s LLM-popolneniyem, szhatiyem, obratnyim porozhdeniyem i otkaznyimi fiksturami.

## Resheniye

Otdeljnaya avtomatizaciya ne sozdavalasj: zapros utochnyayet arkhitekturnoye trebovaniye i kriterii prototipa, a ne povtoryayemuyu proceduru tekusjhej rabochej sessii. Blizhajshaya vosproizvodimaya forma - lokaljnyij Swift-prototip, kotoryij sravnivayet svobodnyij razbor potoka, zaraneye zadannuyu pamyatj operatorov i LLM-popolneniye etoj pamyati.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-08_10-18-09_MSK_закрепить-память-структурирующих-операторов.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-08_10-18-09_MSK_закрепить-память-структурирующих-операторов.md`

## Vozmozhnoye prodolzheniye

Pri sozdanii prototipa nuzhno zalozhitj fiksturyi, gde odin i tot zhe potok soderzhit poleznuyu novuyu formu, oshibku vkhoda i shum. Eto pozvolit proveritj, umeyet li pamyatj operatorov otlichatj rasshireniye tipizacii ot zagryazneniya pamyati.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-08 10:18:09 MSK - Zakrepitj pamyatj strukturiruyusjhikh operatorov](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:77421bf7f0e07cfdac5a93ce6fa9ee055f447e8e9c2e7a9b6d7708718824cab0 -->
<!-- FUM-MD-RECENCY:END -->
