# Otchyot 2026-07-01 15:35:24 MSK

## Glavnoye

Graf Obsidian nastroyen kak teplovaya karta uzlov po vremeni poslednego soderzhateljnogo redaktirovaniya Markdown-fajlov. Nastrojka sokhranena v otslezhivayemom fajle [.obsidian/graph.json](../../../../../.obsidian/graph.json), a yeyo peresborka oformlena kak lokaljnaya vosproizvodimaya avtomatizaciya.

## Chto izmenilosj

- Sozdana avtomatizaciya [fum-obsidian-graph-recency](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md) so skriptom `build-obsidian-graph-recency.py` i testami.
- Skript chitayet `FUM-MD-RECENCY`, gruppiruyet Markdown-fajlyi po vozrastu i zapisyivayet v `colorGroups` grafa Obsidian zaprosyi `path:"..."`.
- Obsjhij [fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) rasshiren proverkoj aktualjnosti teplovoj kartyi cherez `fum-obsidian-graph-recency --check`.
- V [dokumentacii o vosproizvodimyikh avtomatizaciyakh](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md), [indekse instrumentov](../../Instrumentyi/README.md), [reyestre sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) i [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) zafiksirovan novyij sloj.

## Resheniya

Teplovaya karta postroyena po putyam fajlov, a ne po poisku dat v soderzhimom. Eto vazhno, potomu chto datyi vstrechayutsya v indeksakh, zhurnalakh i zaprosakh kak obyichnyij tekst i mogli byi okrashivatj ne te uzlyi.

Cvetovyiye korzinyi idut ot goryachikh svezhikh uzlov k kholodnyim staryim: segodnya, odin-dva dnya, tri-semj dnej, vosemj-tridcatj dnej i starshe mesyaca. Ostaljnyiye nastrojki grafa sokhranyayutsya, no spisok `colorGroups` zamenyayetsya celikom, potomu chto heatmap yavlyayetsya celjnyim rezhimom okrashivaniya.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-obsidian-graph-recency/tests -p 'test_*.py'` - snachala ozhidayemo upalo do realizacii, zatem proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; obnovlenyi sluzhebnyiye recency-metki i indeks Markdown-fajlov.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo; `.obsidian/graph.json` peresobran kak heatmap.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-01_15-35-24_MSK.md` - proshlo 13 shagov, vklyuchaya 47 testov lokaljnyikh avtomatizacij, proverku planovogo reyestra, recency-check, heatmap-check i svyaznostj sessii.
- `git diff --check` - proshlo.

## Istochniki

- [iskhodnyij zapros 2026-07-01 15:35:24 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f36dba8798f16acb2e1fce66066d90f5b991b97bd0568bf093f32a328747ee65 -->
<!-- FUM-MD-RECENCY:END -->
