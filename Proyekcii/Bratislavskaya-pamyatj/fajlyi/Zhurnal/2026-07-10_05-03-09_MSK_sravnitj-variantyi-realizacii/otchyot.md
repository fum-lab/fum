# Otchyot 2026-07-10 05:03:09 MSK - Sravnitj variantyi realizacii

Rabochaya sessiya sravnila arkhitekturnyiye variantyi blizhajshej realizacii FUM po tekusjhemu kodu i pamyati repozitoriya. GitHub-konnektor pokazal, chto v `fum-lab/fum` sejchas viden toljko `master` i net PR-kandidatov dlya sravneniya, poetomu analiz postroyen ne kak diff vetok, a kak ocenka variantov, uzhe opisannyikh v dokumentacii i podtverzhdyonnyikh tekusjhimi lokaljnyimi avtomatizaciyami.

Glavnyij vyivod: pervyim realizacionnyim podkhodom nuzhno schitatj repozitornyij gipersetevoj kontur na Git, Codex-praktike, lokaljnoj pamyati, proverkakh i Git-nasledovanii. Sobstvennyij agentskij cikl ostayotsya arkhitekturnyim yadrom sleduyusjhego shaga, no yego nuzhno nachinatj kak malenjkij trassirovsjhik s fiksturoj, modeljnoj zaglushkoj ili strogo opisannyim chistyim modeljnyim provajderom. Yedinoye lokaljnoye prilozheniye stoit derzhatj kak boleye pozdnij integrator korobochnoj stadii.

Otkryityij vopros o razvilke giperseti i agentskogo cikla perevedyon v chastichno proyasnyonnyiye: poryadok realizacii utochnyon, no kontrakt chistogo modeljnogo shaga dlya runtime poka ostayotsya otkryityim.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [Ocenka vyibora arkhitekturnogo podkhoda k realizacii FUM](materialyi/ocenki/ocenka-vyibora-arkhitekturnogo-podkhoda-k-realizacii-FUM.md)
- [Konfiguraciya sravniteljnoj ocenki](materialyi/ocenki/ocenka-vyibora-arkhitekturnogo-podkhoda-k-realizacii-FUM.json)
- [Razvilka giperseti i agentskogo cikla FUM](../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md)
- [Predlozheniya o sleduyusjhikh shagakh FUM](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- `python3 Инструменты/fum-estimates/scripts/build-estimate.py snapshot --output /tmp/fum-architecture-choice-snapshot.json` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-10_05-03-09_MSK_сравнить-варианты-реализации.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-10_05-03-09_MSK_сравнить-варианты-реализации.md` - proshlo, 14 shagov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f2d378fde1a01a10c6b26bba54ad36df88749c679d19e90fb657485cba5244d1 -->
<!-- FUM-MD-RECENCY:END -->
