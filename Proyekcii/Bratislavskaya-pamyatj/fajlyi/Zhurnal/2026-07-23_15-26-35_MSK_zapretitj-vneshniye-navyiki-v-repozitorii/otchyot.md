# Otchyot 2026-07-23 15:26:35 MSK - Zapretitj vneshniye navyiki v repozitorii

Novyiye zadachi FUM posle zagruzki proyektnoj konfiguracii boljshe ne poluchayut obsjhij katalog navyikov sredyi i ne dolzhnyi tratitj khod na proverku vneshnej instrukcii, prezhde chem vernutjsya k pravilam repozitoriya. Yedinstvennyim istochnikom navyikov stanovyatsya yavnyiye lokaljnyiye `Инструменты/*/SKILL.md`, a pri otsutstvii podkhodyasjhego navyika rabota prodolzhayetsya neposredstvenno po `AGENTS.md` i materialam tekusjhego checkout.

## Rezuljtat

V `.codex/config.toml` zakrepleno `skills.include_instructions = false`. Lokaljnoye sravneniye modeljnogo vkhoda `codex debug prompt-input` podtverdilo, chto nastrojka ubirayet obsjhij blok kataloga navyikov. `AGENTS.md`, indeks instrumentov i lokaljnaya instrukciya glossariya zakreplyayut boleye stroguyu povedencheskuyu granicu: vneshniye `SKILL.md` neljzya iskatj, otkryivatj dlya ocenki ili sravneniya i primenyatj.

Ispolnitelj obsjhego smoke-check razbirayet proyektnyij TOML do postroyeniya shagov i prinimayet toljko tochnoye logicheskoye znacheniye `false`. On takzhe razreshayet simvolicheskiye ssyilki lokaljnyikh `SKILL.md` i otklonyayet vyikhod za korenj checkout. Otsutstvuyusjhaya sekciya, znacheniye `true`, stroka vmesto logicheskogo znacheniya, povrezhdyonnyij TOML ili vneshnij putj ostanavlivayut proverku. Regressiya zasjhisjhayet sokhrannostj nastrojki i fajlovoj granicyi, a yeyo fakticheskoye primeneniye tekusjhimi standalone- i Desktop-runtime otdeljno podtverzhdeno sravneniyem modeljnogo vkhoda; povedeniye neizvestnoj budusjhej versii etim ne obesjhayetsya.

## Profilj vremeni vyipolneniya

| Stadiya                        | Dliteljnostj             | Granicyi i sposob izmereniya                                                                                                           |
| ----------------------------- | -----------------------: | ------------------------------------------------------------------------------------------------------------------------------------ |
| Ozhidaniye dopuska FIFO         | 1464,9 s (24 min 24,9 s) | Mashinnyiye `registered_at_epoch` i `admitted_at_epoch` bileta ocheredi; aktivnoj rabotoj ne schitayetsya.                                  |
| Analiz i proyektirovaniye       |    542,7 s (9 min 2,7 s) | Raznostj mashinnyikh epoch-otmetok dopuska i pervoj pravki; tri paralleljnyikh read-only-audita ne summiruyutsya.                           |
| Realizaciya i celevyiye proverki |  791,0 s (13 min 11,0 s) | Ot pervoj pravki do zapuska polnogo smoke-check; vklyuchayet kod, dokumentaciyu, celevyiye testyi, runtime-proverki, revjyu i generatoryi.    |
| Predfinaljnyij smoke-check     |   190,9 s (3 min 10,9 s) | Polnyij progon `39/39`; wall-clock izmeren monotonnyim tajmerom vokrug komandyi na tekusjhej mashine.                                      |

Granica profilya: ot atomarnoj registracii FIFO-bileta do zaversheniya predfinaljnogo polnogo smoke-check — `2989,5` sekundyi (`49 мин 49,5 с`); povtornyiye proverki izmenivshegosya otchyota, staging i atomarnyij commit+handoff nakhodyatsya posle etoj granicyi.

## Granica resheniya

Nastrojka vliyayet na novyiye zadachi posle zagruzki proyektnoj konfiguracii. Ona ne mozhet udalitj instrukcii, uzhe peredannyiye nachatoj sessii, poetomu tekusjhaya rabota dopolniteljno soblyudala novyij zapret vruchnuyu i ne otkryivala vneshnij navyik. Ogranicheniye otnositsya k navyikam `SKILL.md`; drugiye dostupnyiye instrumentyi reguliruyutsya samostoyateljnyimi pravilami.

## Prodolzheniye

Novaya kartochka shaga ne nuzhna: konfiguraciya, pravila i avtomaticheskaya zasjhita zavershenyi etoj rabochej sessiyej. Rabochij nabor vetki ostayotsya bez izmenenij.

## Proverki

TDD-regressiya snachala vosproizvela otsutstviye validatora. Posle realizacii `18/18` testov obsjhego smoke-check pokryili otsutstvuyusjhij i povrezhdyonnyij TOML, nevernyiye tipyi i znacheniya, vklyucheniye proverki v plan i simvolicheskuyu ssyilku naruzhu. Samostoyateljnyij i vstroyennyij Desktop-runtime Codex sokhranili proyektnyij `AGENTS.md` v modeljnom vkhode i ubrali iz nego markeryi obsjhego kataloga navyikov. Predfinaljnyij polnyij smoke-check proshyol `39/39` shagov za `190,9` sekundyi; posle zapisi izmereniya povtoryayutsya toljko recency, graf Obsidian, svyaznostj sessii i `git diff --check`.

## Zatronutyiye materialyi

- [proyektnaya konfiguraciya Codex](<../../.codex/config.toml>)
- [pravila repozitoriya](../../AGENTS.md)
- [indeks instrumentov](../../Instrumentyi/README.md)
- [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [lokaljnyij navyik glossariya](../../Instrumentyi/fum-glossarij/SKILL.md)
- [kontrakt obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [ispolnitelj obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py)
- [regressionnyiye testyi obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/tests/test_run_smoke_check.py)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:043e763ce94c19a2c88d07beb980c804bddce6d6be2687dbcef9a5f1d93dabbb -->
<!-- FUM-MD-RECENCY:END -->
