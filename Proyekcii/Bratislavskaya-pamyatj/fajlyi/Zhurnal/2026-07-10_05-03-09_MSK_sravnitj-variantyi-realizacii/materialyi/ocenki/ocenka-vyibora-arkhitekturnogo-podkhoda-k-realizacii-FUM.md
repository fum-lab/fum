# Ocenka vyibora arkhitekturnogo podkhoda k realizacii FUM

Na tekusjhem sostoyanii repozitoriya blizhajshim pervyim shagom realizacii stoit vyibratj **repozitornyij gipersetevoj kontur**: ukreplyatj uzhe rabotayusjhuyu cepochku `исходный запрос -> память -> локальные автоматизации -> проверки -> Git-коммит -> наследование`. Eto ne otmenyayet sobstvennyij agentskij cikl, no zadayot poryadok: snachala zakrepitj to, chto uzhe podtverzhdeno kodom i proverkami, zatem poverkh etogo delatj minimaljnyij trassirovsjhik cikla.

Prakticheskij vyibor: **sejchas razvivatj Git/Codex/lokaljnuyu pamyatj kak pervyij proveryayemyij nositelj FUM, sleduyusjhim shagom podgotovitj malenjkij trassirovsjhik agentskogo cikla s modeljnoj zaglushkoj ili strogo opisannyim chistyim modeljnyim provajderom, a yedinoye lokaljnoye prilozheniye otlozhitj do poyavleniya ustojchivogo cikla i konturov fiksacii rezuljtata**.

## Snimok repozitoriya

Ocenka opirayetsya na lokaljnyij snimok `fum-lab/fum` ot 2026-07-10 i proverku GitHub-konteksta cherez podklyuchyonnyij konnektor. GitHub pokazal toljko vetku `master` i ne vernul otkryityikh ili nedavnikh PR, poetomu sravneniye ne yavlyayetsya sravneniyem branch-diff. Ono sopostavlyayet arkhitekturnyiye variantyi, uzhe opisannyiye v pamyati, s tem, chto realjno podtverzhdeno kodom tekusjhego `master`.

| Pokazatelj                                 | Znacheniye  |
| ------------------------------------------ | --------- |
| Git-kommit                                 | `520febf` |
| Vetka Git                                  | `master`  |
| Sostoyaniye rabochego dereva na moment snimka | chistyij    |
| Kolichestvo kommitov                        | 169       |
| Otslezhivayemyiye fajlyi                        | 642       |
| Markdown-fajlyi                             | 513       |
| Obsjhij obyyom strok v otslezhivayemyikh fajlakh   | 143392    |
| Obsjhij obyyom slov v Markdown-fajlakh         | 301982    |
| GitHub-vetki, najdennyiye konnektorom        | `master`  |
| Nedavniye PR, najdennyiye konnektorom         | net       |

## Sravnivayemyiye variantyi

**Repozitornyij gipersetevoj kontur** uzhe susjhestvuyet kak praktika i kod. Yego nositeli - `AGENTS.md`, fajlyi `Запросы/`, `Журнал/`, `Документация/`, `Планирование/`, `Оценки/`, lokaljnyiye avtomatizacii v `Инструменты/`, recency-metki, proverka svyaznosti sessii i Git-istoriya.

**Minimaljnyij trassirovsjhik agentskogo cikla** blizhe k celevomu agentnomu yadru FUM: celj, nablyudeniya, dejstviya, proverki, ostanovka, sostoyaniye i itog dolzhnyi statj otdeljnoj ispolnyayemoj trassoj. No v tekusjhem kode eto poka opisano kak MVP-kandidat, a ne realizovano kak runtime.

**Yedinoye lokaljnoye prilozheniye** luchshe vsego pokhozhe na budusjhuyu korobochnuyu formu dlya poljzovatelya. No ono zavisit ot dvukh predyidusjhikh sloyov: bez ustojchivoj pamyati sessii i bez trassirovsjhika cikla prilozheniye riskuyet statj obolochkoj bez proveryayemogo agentnogo yadra.

## Matrica vyibora

Ocenki kachestvennyiye. V kolonkakh «kod», «proveryayemostj», «yadro» i «demo» boljsheye znacheniye luchshe. V kolonkakh «cena» i «risk» menjsheye znacheniye luchshe.

| Variant                                   | Kod | Proveryayemostj | Yadro | Cena | Risk | Demo | Vyivod                                                                                          |
| ----------------------------------------- | --: | ------------: | ---: | ---: | ---: | ---: | ---------------------------------------------------------------------------------------------- |
| Repozitornyij gipersetevoj kontur          |   5 |             5 |    4 |    2 |    1 |    3 | Luchshij pervyij shag: uzhe yestj kod, proverki i rabochaya disciplina nasledovaniya.                   |
| Minimaljnyij trassirovsjhik agentskogo cikla |   2 |             4 |    5 |    4 |    3 |    4 | Luchshij sleduyusjhij shag: proveryayet yadro FUM, no trebuyet uzkoj fiksturyi i chistogo modeljnogo shaga. |
| Yedinoye lokaljnoye prilozheniye               |   1 |             3 |    4 |    5 |    4 |    5 | Siljnyij produktovyij obraz, no prezhdevremenen kak pervyij inzhenernyij khod.                        |

## Kodovyiye svideteljstva

Tekusjhij repozitorij uzhe soderzhit neskoljko ispolnyayemyikh lokaljnyikh avtomatizacij, kotoryiye podderzhivayut gipersetevoj kontur kak zhivuyu praktiku:

- [fum-svyaznostj-rabochej-sessii](../../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py) proveryayet navigaciyu zaprosov, nalichiye zhurnala, razdel instrumentov, ssyilki i publikacionnuyu chistotu rabochej sessii.
- [fum-svezhestj-markdown](../../../../Instrumentyi/fum-svezhestj-markdown/scripts/update-md-recency.py) obnovlyayet sluzhebnyiye metki svezhesti Markdown-fajlov i indeks po vremeni soderzhateljnogo redaktirovaniya.
- [fum-reyestr-planirovaniya](../../../../Instrumentyi/fum-reyestr-planirovaniya/scripts/build-planning-registry.py) sobirayet mashinno chitayemyij reyestr trebovanij, variantov realizacii i kandidatov iz planovyikh dokumentov.
- [fum-ocenki](../../../../Instrumentyi/fum-ocenki/scripts/build-estimate.py) sozdayot repozitornyiye snimki i proveryayet strukturu ocenochnyikh materialov.
- Naboryi testov v `Инструменты/*/tests/` podtverzhdayut, chto eto ne toljko dokumentacionnaya dogovoryonnostj, a lokaljno proveryayemyij kod.

Dlya sobstvennogo agentskogo cikla takikh kodovyikh svideteljstv poka menjshe. Yestj siljnaya proyektnaya ramka v [MVP-kandidate ispolnyayemogo agentskogo cikla](../../../../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md), format trassyi i [proveryayemyij kontrakt chistogo modeljnogo shaga](../../../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md) s povtoryayemoj zaglushkoj, no otdeljnyij runtime, integriruyusjhij nablyudeniye, modeljnyij vyizov, dejstviye, proverku i prodolzheniye, yesjhyo otsutstvuyet.

## Arkhitekturnyij vyivod

Pervyim arkhitekturnyim podkhodom sleduyet vyibratj ne «Git vmesto agentskogo cikla», a **Git-gipersetj kak opornyij substrat dlya rozhdeniya sobstvennogo cikla**. Ona uzhe obespechivayet proiskhozhdeniye, nasledovaniye, proverku, zhurnalirovaniye, lokaljnyiye pravila, perenosimyiye avtomatizacii i prostranstvo dlya otbora variantov. Obsjhij kontrakt i zaglushka chistogo modeljnogo shaga uzhe proverenyi, no nachinatj s avtonomnogo runtime vsyo yesjhyo prezhdevremenno bez conformance-profilya realjnoj LLM i nablyudayemoj integracii, kotoraya ne perekladyivayet cikl na Codex.

Minimaljnyij agentskij cikl nuzhno delatj sleduyusjhim, no v siljno ogranichennoj forme: scenarij, celj, lokaljnyiye vkhodyi, allowlist dejstvij, modeljnaya zaglushka ili dokazannyij rezhim chistogo provajdera, mashinno chitayemaya trassa, chelovekochitayemoye rezyume i odna fikstura, gde povtornyij zapusk dayot tot zhe strukturnyij rezuljtat ili obyyasnimoye raskhozhdeniye.

Yedinoye lokaljnoye prilozheniye luchshe schitatj integratorom korobochnoj stadii. Yego polezno proyektirovatj uzhe sejchas kak formu poljzovateljskogo kontura, no realizovyivatj pervyim riskovanno: ono byistro nachnyot trebovatj interfejs, podtverzhdeniya, poisk, dejstviye i sokhraneniye rezuljtata ranjshe, chem budet proveren sobstvennyij cikl.

## Resheniye po otkryitoj razvilke

Otkryityij vopros o razvilke giperseti i agentskogo cikla poluchayet chastichnoye proyasneniye. Poryadok realizacii mozhno schitatj vyibrannyim:

1. ukrepitj repozitornyij gipersetevoj kontur kak dejstvuyusjhij prototip pamyati, proiskhozhdeniya, otbora i nasledovaniya;
2. sozdatj minimaljnyij trassirovsjhik agentskogo cikla kak sleduyusjhij proveryayemyij artefakt;
3. toljko posle etogo sobiratj yedinoye lokaljnoye prilozheniye kak poljzovateljskuyu poverkhnostj korobochnoj realizacii.

Vopros ne zakryivayetsya polnostjyu: strukturnyij kontrakt i proveryayemaya zaglushka uzhe opredelenyi, no ostayutsya nepodtverzhdyonnyimi realjnaya lokaljnaya LLM, integraciya modeljnogo vyizova v runtime i trassu i nalichiye u `Codex CLI` rezhima, kotoryij ne podmenyayet soboj vesj agentskij cikl.

## Status metodiki

Ocenka sozdana vruchnuyu kak sravniteljnaya arkhitekturnaya matrica. Lokaljnaya avtomatizaciya [fum-ocenki](../../../../Instrumentyi/fum-ocenki/SKILL.md) ispoljzovana dlya snimka repozitoriya i kak opornyij kontrakt oformleniya ocenochnyikh materialov, no yeyo tekusjhij format rasschitan na diapazonyi, a ne na sravneniye variantov po kriteriyam.

Blizhajshij shag k avtomatizacii - dobavitj v `fum-ocenki` otdeljnyij rezhim sravniteljnyikh arkhitekturnyikh ocenok: spisok variantov, kriterii, vesa, ssyilki na kodovyiye svideteljstva, itogovyij poryadok realizacii i status svyazannyikh otkryityikh voprosov.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 18:12:05 MSK - Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla](../../../2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-10 05:03:09 MSK - Sravnitj variantyi realizacii](../../zapros.md)
- [iskhodnyij zapros 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla](../../../2026-07-03_15-36-48_MSK_utochnitj-razvilku-giperseti-i-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK - Zafiksirovatj poshagovyij otbor realizacii](../../../2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)

## Opornyiye materialyi

- [Arkhitektura FUM](../../../../Dokumentaciya/22-arkhitektura-FUM.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../../../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../../../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [MVP-kandidat: ispolnyayemyij agentskij cikl](../../../../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [MVP-kandidat: pamyatj rabochej sessii](../../../../Planirovaniye/MVP-kandidatyi/01-pamyatj-rabochej-sessii/README.md)
- [MVP-kandidat: yedinaya tochka lokaljnoj rabotyi](../../../../Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)
- [Matrica otbora MVP-kandidatov](../../../../Planirovaniye/MVP-kandidatyi/matrica-otbora.md)
- [Razvilka giperseti i agentskogo cikla FUM](../../../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md)
- [Konfiguraciya sravniteljnoj ocenki](ocenka-vyibora-arkhitekturnogo-podkhoda-k-realizacii-FUM.json)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:16f3e8847dee8a56842fc1c2ba418b1a8f028f1004f4e130049616081f3eeccd -->
<!-- FUM-MD-RECENCY:END -->
