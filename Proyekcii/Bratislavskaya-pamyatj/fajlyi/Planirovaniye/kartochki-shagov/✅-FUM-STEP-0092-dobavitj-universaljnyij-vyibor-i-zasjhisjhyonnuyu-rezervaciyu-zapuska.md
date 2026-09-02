+++
schema_version = 1
card_id = "FUM-STEP-0092"
status = "completed"
+++
# Dobavitj universaljnyij vyibor i zasjhisjhyonnuyu rezervaciyu zapuska

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Realizovatj poverkh kontrakta FUM-STEP-0091 chistoye vyichisleniye gotovnosti, determinirovannyij vyibor ne boleye odnogo zadaniya za heartbeat i compare-and-swap-rezervaciyu tochnogo pokoleniya. Obsjhij claim dolzhen byitj nezavisim ot kartochochnogo `branch_ref + step_id`, sokhranyatj popyitku sozdaniya zadachi i ne pozvolyatj staromu pokoleniyu povtoritj effekt posle izmeneniya konfiguracii.

## Rezuljtat

[Lokaljnyij dispetcher](../../Instrumentyi/fum-dispetcher-avtomatizacij-fum/SKILL.md) chisto vyichislyayet gotovnostj iz validnyikh reyestra i yavno peredannyikh nablyudenij, ne chitaya sistemnyiye chasyi. Komanda `выбрать` stroit tipizirovannoye `trigger_occurrence` i vozvrasjhayet ne boleye odnogo zadaniya po dokumentirovannomu poryadku tipa nastupleniya, sobstvennogo sroka, `приоритет` i `job_id`. `paused`, `blocked`, nenastupivshiye i ne proshedshiye usloviya zadaniya isklyuchayutsya iz vyibora, ne blokiruya nezavisimoye gotovoye. `run_key` yavlyayetsya SHA-256 kanonicheskogo obyyekta iz `job_id`, `spec_generation` i tochnogo `trigger_occurrence`.

Zasjhisjhyonnaya rezervaciya khranitsya v sluzhebnoj Git-ssyilke, oblastj kotoroj opredelyayetsya fizicheskoj rabochej kopiyej, polnyim `branch_ref` i `job_id`, a ne kartochochnyimi `step_id` ili `selection.id`. Kanonicheskoye soderzhimoye zakreplyayet vershinu vyibora, identichnostj, skhemu, pokoleniye i khyesh reyestra, pokoleniye zadaniya, nastupleniye, `run_key`, kursor do zapuska i UUID kliyentskoj popyitki. Razobrannyij reyestr vyibora dopolniteljno sveryayetsya s tem zhe Git-snimkom, tochnaya vershina kotorogo vkhodit v sravneniye i zamenu, poetomu konkurentnaya smena `HEAD` i fajla zakryivayet staryij vyibor. Pervichnaya zapisj i perekhod pered vneshnej granicej atomarno ispoljzuyut sravneniye i zamenu; tochnyij povtor toj zhe popyitki do granicyi idempotenten, a staroye pokoleniye, chuzhaya popyitka, neterminaljnoye vladeniye i neopredelyonnyij iskhod zakryivayutsya otkazom.

Zhiznennyij cikl razlichayet rezervaciyu, otmetku vozmozhnogo vyizova, vneshne podtverzhdyonnoye sozdaniye zadachi i terminaljnoye zaversheniye. Sozdaniye zadachi samo ne schitayetsya uspekhom i ne prodvigayet kursor; uspekh trebuyet otdeljnogo podtverzhdeniya rezuljtata, bezopasnoye osvobozhdeniye dopustimo toljko do vozmozhnogo effekta, a neopredelyonnostj zapresjhayet avtomaticheskij povtor. Avtonomnyiye testyi na vremennyikh Git-repozitoriyakh proveryayut kollizii processov, restartyi, smenu pokoleniya, nezavisimyiye zadaniya i vse perekhodyi, ne izmenyaya rabochuyu kopiyu proyekta.

Kanonicheskij reyestr `master` ostayotsya pustyim. Shag ne vyizyivayet Codex host, ne sozdayot ispolniteljskuyu zadachu, ne migriruyet prikreplyonnuyu avtomatizaciyu i ne realizuyet vneshnij effekt; eta integracionnaya granica sokhranena dlya FUM-STEP-0093.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-05_09-07-08_MSK_dobavitj-universaljnyij-vyibor-i-zasjhisjhyonnuyu-rezervaciyu-zapuska/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [FUM-STEP-0091 — kontrakt universaljnogo dispetchera](✅-FUM-STEP-0091-zakrepitj-kontrakt-universaljnogo-dispetchera-avtomatizacij-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:8e200810c3e8a92c48040f6ba676cf128a56bac690222b89c47d57a4a345cf71 -->
<!-- FUM-MD-RECENCY:END -->
