# Otchyot 2026-07-06 13:52:08 MSK - Zakrepitj Swift yazyikom prototipov

Sessiya zakrepila proyektnoye resheniye: rabochiye prototipyi FUM po umolchaniyu pishutsya na Swift. Eto perevodit budusjhiye probyi korobochnoj realizacii v odin osnovnoj inzhenernyij stek i zaraneye zadayot ozhidaniye lokaljnoj sborki, testov, paketov i runtime-ogranichenij.

## Chto izmenilosj

- V [AGENTS.md](../../AGENTS.md) dobavleno pravilo: novyiye prototipyi v `Прототипы/` po umolchaniyu pishutsya na Swift, a isklyucheniya trebuyut yavnogo obyyasneniya v pasporte prototipa.
- V [Prototipakh](../../Prototipyi/README.md) dobavleno smyislovoye opisaniye Swift kak osnovnogo yazyika prototipnogo sloya i novyij punkt pasporta dlya sluchayev, kogda vyibran drugoj yazyik ili runtime.
- V stadii [korobochnoj realizacii FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md) Swift zafiksirovan kak osnovnoj stek rabochikh proverok budusjhikh perenosimyikh modulej.
- V [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) utochneno, chto uzhe aktualjnyiye prototipnyiye predlozheniya dolzhnyi nachinatjsya so Swift-steka, yesli net obosnovannogo isklyucheniya.

## Resheniye

Swift vyibran kak bazovoye pravilo, a ne kak zapret na issledovateljskiye isklyucheniya. Eto vazhno dlya FUM: osnovnoj stek dolzhen pomogatj budusjhej korobochnoj realizacii sobiratjsya v celjnyij produktovyij kontur, no otdeljnyiye proverki mogut trebovatj drugogo yazyika, formata dannyikh, vneshnego runtime ili etalonnogo okruzheniya. Takiye otkloneniya dolzhnyi byitj vidnyi v pasporte prototipa, chtobyi rezuljtat ne perenosilsya v arkhitekturu nezametno.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-06_13-52-08_MSK_закрепить-Swift-языком-прототипов.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-06_13-52-08_MSK_закрепить-Swift-языком-прототипов.md`

## Vozmozhnoye prodolzheniye

Pri sozdanii pervogo realjnogo Swift-prototipa stoit oformitj minimaljnyij shablon podpapki: `Package.swift`, testyi, pasport, lokaljnaya komanda proverki, ssyilki na trebovaniya i pole dlya obyyasneniya isklyuchenij. Sejchas shablon ne sozdan, potomu chto eta sessiya fiksirovala vyibor yazyika, a ne zapusk konkretnogo prototipa.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-06 13:52:08 MSK - Zakrepitj Swift yazyikom prototipov](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e84b31116f5efb1d5fdfb10ce155a6d745cea37288db0c5e7f204421185e1f21 -->
<!-- FUM-MD-RECENCY:END -->
