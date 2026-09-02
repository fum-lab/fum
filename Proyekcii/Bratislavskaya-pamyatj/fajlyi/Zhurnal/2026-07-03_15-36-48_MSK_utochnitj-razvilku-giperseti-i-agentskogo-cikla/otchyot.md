# Otchyot 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla

Sessiya zafiksirovala novyij otkryityij vopros v prakticheskom vyibore pervogo dejstvuyusjhego prototipa [FUM](../../Glossarij/FUM.md). S odnoj storonyi, tekusjhaya Git-infrastruktura, Codex, Obsidian-pamyatj, zaprosyi, zhurnalyi, proverki i kommityi uzhe pozvolyayut razvivatj dejstvuyusjhij prototip gipersetevoj FUM. S drugoj storonyi, yesli celj sostoit v sobstvennom vlozhenii agentskikh ciklov drug v druga, FUM nuzhen upravlyayemyij modeljnyij shag, a ne toljko vneshnij agentskij runtime.

## Chto izmenilosj

- Sozdan otkryityij vopros o [razvilke giperseti i agentskogo cikla FUM](../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md).
- V voprose o [kriteriyakh lokaljnoj LLM i vyidelennoj mashinyi](../../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md) dobavlena svyazj s novoj razvilkoj.
- [MVP-kandidat ispolnyayemogo agentskogo cikla](../../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md) teperj yavno trebuyet fiksirovatj kontrakt modeljnogo shaga ili otsutstviye realjnogo LLM-provajdera v pervom progone.
- Stadiya i graf [korobochnoj realizacii FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md) utochnenyi: etapyi trassyi i runtime dolzhnyi otlichatj sobstvennyij cikl FUM ot vneshnego cikla Codex.
- V [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) dobavleno predlozheniye proveritj kontrakt chistogo modeljnogo shaga: lokaljnaya LLM, zaglushka ili strogo neciklicheskij rezhim `Codex CLI`.

## Resheniye

Razvilka ne svoditsya k vyiboru modeli ili zheleza. Ona opredelyayet poryadok realizacii: mozhno byistro usilitj gipersetevoj prototip na Git + Codex, no dlya dokazateljstva rekursivnogo agentskogo yadra nuzhen otdeljnyij minimaljnyij runtime s prozrachnyim modeljnyim shagom.

Prakticheskaya poziciya sessii: ne vyidavatj rabochuyu sessiyu vo vneshnem agente za sobstvennyij agentskij cikl FUM. Do proverki provajdera dopustimyi tri raznyiye formyi rezuljtata: gipersetevoj prototip pamyati, specifikaciya trassyi s fiksturoj ili zaglushkoj i runtime s realjnyim chistyim LLM-provajderom.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-03_15-36-48_MSK_уточнить-развилку-гиперсети-и-агентского-цикла.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-03_15-36-48_MSK_уточнить-развилку-гиперсети-и-агентского-цикла.md`

## Vozmozhnoye prodolzheniye

Blizhajshaya proveryayemaya rabota - sdelatj malenjkij eksperiment s kontraktom modeljnogo shaga: odna fikstura agentskogo cikla, odin rezhim bez realjnoj modeli, odin rezhim s vyibrannyim LLM-provajderom i otchyot o tom, mozhno li schitatj provajdera chistyim modeljnyim shagom.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:12f6344d280020d78159a4c7506b9195ed2ee932374ba8710d2430e0c92edd4f -->
<!-- FUM-MD-RECENCY:END -->
