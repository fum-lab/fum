+++
schema_version = 1
card_id = "FUM-STEP-0005"
status = "completed"
+++
# Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Proveritj kontrakt chistogo modeljnogo shaga dlya [ispolnyayemogo agentskogo cikla](../MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md): lokaljnaya LLM, proveryayemaya zaglushka ili rezhim `Codex CLI`, kotoryij rabotayet kak prostoj LLM-provajder bez sobstvennogo agentskogo cikla.

## Rezuljtat

Sozdan [kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md) versii `1`, mashinnaya JSON Schema i [Swift-prototip s determinirovannoj zaglushkoj](../../Prototipyi/chistyij-modeljnyij-shag/README.md). Kontrakt peredayot polnyij kontekst yavno, sveryayet identichnostj provajdera, zapresjhayet instrumentyi, fajlyi i setj, ogranichivayet vkhod, vyikhod i vremya, svyazyivayet kanonicheskij otvet s vkhodom i ostavlyayet vyivod inertnyim tekstom dlya vneshnego runtime.

Avtonomnyiye testyi podtverzhdayut povtoryayemostj zaglushki, UTF-8-metriki, izmeneniye khyesha vmeste s kontekstom, strogiye polya, zapret effektnyikh capabilities, obyazateljnoye soobsjheniye `user`, oshibku limita i inertnostj shell-podobnogo teksta. Proverka ne podklyuchayet realjnuyu LLM: lokaljnyij Ollama-kontur ostayotsya chastichnyim svideteljstvom, a `Codex CLI` ne prinyat bez dokazannogo model-only-rezhima, isklyuchayusjhego sobstvennyij agentskij cikl.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md), [otchyot rabochej sessii](../../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/otchyot.md)
- [iskhodnyij zapros 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla](../../Zhurnal/2026-07-03_15-36-48_MSK_utochnitj-razvilku-giperseti-i-agentskogo-cikla/zapros.md), [otkryityij vopros o razvilke giperseti i agentskogo cikla FUM](../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md), [MVP-kandidat ispolnyayemogo agentskogo cikla](../MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md), [otkryityij vopros o kriteriyakh lokaljnoj LLM i vyidelennoj mashinyi](../../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md), [graf zavisimostej elementov korobochnoj realizacii FUM](../stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:62a64c98a5ef596a8d5b54cff37c44f7458ca1c94a6f485037c0d1df8cf9f623 -->
<!-- FUM-MD-RECENCY:END -->
