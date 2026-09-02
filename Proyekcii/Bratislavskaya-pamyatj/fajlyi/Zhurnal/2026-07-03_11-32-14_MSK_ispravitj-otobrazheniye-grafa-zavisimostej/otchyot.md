# Otchyot 2026-07-03 11:32:14 MSK - Ispravitj otobrazheniye grafa zavisimostej

V rabochej sessii ispravleno otobrazheniye Mermaid-grafa zavisimostej korobochnoj realizacii FUM v Obsidian. Prichina byila v tom, chto podpisi uzlov nachinalisj s `0.`, `1.`, `2.` i daljshe; Mermaid-podpisi razbiralisj kak Markdown, a Obsidian pokazyival v uzlakh `Unsupported markdown: list`.

V dokumente [grafa zavisimostej](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md) podpisi uzlov perevedenyi na format `Этап N - ...`. Smyisl i poryadok zavisimostej ne izmenenyi: pravka kasayetsya sovmestimosti vizualjnogo predstavleniya s Markdown-renderingom.

Chtobyi defekt ne vernulsya, v [AGENTS.md](../../AGENTS.md) dobavleno pravilo ne nachinatj Mermaid-podpisi uzlov s Markdown-markerov spiskov. Lokaljnaya avtomatizaciya [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) poluchila regressionnyij test i proverku Mermaid-blokov v zatronutyikh Markdown-fajlakh.

Susjhestvuyusjheye predlozheniye o perevode ruchnogo grafa zavisimostej v mashinno chitayemyij sloj planirovaniya ostavleno aktualjnyim: eta oshibka dopolniteljno pokazyivayet, chto vazhnyiye planovyiye svyazi luchshe imetj v proveryayemoj strukturnoj forme, a ne toljko v ruchnom Mermaid-tekste.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest Инструменты/fum-session-coherence/tests/test_check_session_coherence.py -k mermaid` - snachala ozhidayemo upal do realizacii proverki, zatem proshyol posle realizacii.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-03_11-32-14_MSK_исправить-отображение-графа-зависимостей.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-03_11-32-14_MSK_исправить-отображение-графа-зависимостей.md` - proshlo, 14 shagov.

## Istochniki

- [iskhodnyij zapros 2026-07-03 11:32:14 MSK - Ispravitj otobrazheniye grafa zavisimostej](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:513e1f1b3133ca26dc0a29bf00e4ddc02898a48c5bc001b5ae0688bb8ce5b539 -->
<!-- FUM-MD-RECENCY:END -->
