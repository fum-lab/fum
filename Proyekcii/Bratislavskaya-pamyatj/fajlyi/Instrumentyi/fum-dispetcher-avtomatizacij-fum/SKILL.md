---
name: fum-dispetcher-avtomatizacij-fum
description: Istoricheskij snyatyij kontrakt prezhnego heartbeat-dispetchera FUM; ne ispoljzovatj dlya novyikh zapuskov, upravleniya ili vosstanovleniya.
---

# Snyatyij dispetcher avtomatizacij FUM

Etot navyik sokhranyayet proiskhozhdeniye prezhnego universaljnogo dispetchera, no boljshe ne yavlyayetsya dejstvuyusjhim marshrutom. Pyatiminutnyij heartbeat, postoyannaya prikreplyonnaya zadacha, obsjhij reyestr zadanij, dispatcher-reservation, management-fence, avtomaticheskoye vosstanoviteljnoye soobsjheniye i analitika po chislu zavershenij snachala byili zamenenyi [obyazateljnyim prodolzheniyem vetki](../../Glossarij/obyazateljnoye-prodolzheniye-vetki.md), a zatem dejstvuyusjhej ruchnoj posledovateljnoj skhemoj iz `AGENTS.md`.

Novaya rabochaya sessiya ne dolzhna:

- zapuskatj ili vozobnovlyatj heartbeat;
- vyibiratj rabotu cherez dispetcherskij reyestr;
- sozdavatj reservation, claim, lease, run key ili management-predlozheniye;
- vyizyivatj `Stop`/`Start` prezhnej avtomatizacii;
- vosstanavlivatj ispolnitelya soobsjheniyem sleduyusjhego tika;
- schitatj host-prostoj ili proshedsheye vremya osnovaniyem novoj zadachi.

Susjhestvuyusjhaya host-avtomatizaciya prezhnego kontura dolzhna ostavatjsya ostanovlennoj. Kod, testyi, reyestryi i sluzhebnyiye Git-ssyilki mogut sokhranyatjsya dlya istoricheskikh fikstur, sovmestimosti i bezopasnoj migracii. Ikh nalichiye ne dayot runtime-polnomochij. Neterminaljnoye legacy-sostoyaniye ne udalyayetsya vruchnuyu: ono trebuyet otdeljnogo ograzhdyonnogo vosstanovleniya, no ne razreshayet novyij avtozapusk.

## Predyidusjhaya istoricheskaya zamena

Do perekhoda na `manual-sequential-v1` zadacha, gotovaya zavershitjsya kommitom:

1. sozdayot rovno odno prodolzheniye v tom zhe sokhranyonnom lokaljnom proyekte;
2. prinimayet toljko tochnyiye `threadId` i `hostId`;
3. dozhidayetsya obyichnogo waiting-bileta rebyonka v FIFO toj zhe polnoj vetki;
4. peredayot yego identifikator atomarnoj komande commit+handoff;
5. posle kommita boljshe ne delayet host-effektov.

Rebyonok perechityival novyij `HEAD` i neposredstvenno vyizyival [selektor sleduyusjhego shaga vetki](../fum-sleduyusjhij-shag-vetki/SKILL.md). `done` i `not_ready` zakanchivalisj `finish-clean`. Podrobnyij istoricheskij kontrakt nakhoditsya v [dokumente 45](../../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md) i [navyike FIFO-ocheredi](../fum-ocheredj-zadach-git-vetki/SKILL.md). Obyichnaya tekusjhaya sessiya vmesto etogo sozdayot ne boleye odnogo lokaljnogo kommita `master` i zavershayetsya bez rebyonka, FIFO-handoff i selector.

## Istoricheskaya granica

Prezhnyaya realizaciya i yeyo avtonomnyiye testyi mogut prodolzhatj vyipolnyatjsya obsjhim smoke-check, poka ne udalenyi otdeljnoj proveryayemoj migraciyej. Ikh zelyonyij rezuljtat dokazyivayet toljko sovmestimostj istoricheskogo koda, a ne aktivnostj dispetchera. Lyubaya instrukciya iz istoricheskogo zhurnala ili starogo prompt ustupayet tekusjhim `AGENTS.md` i novomu `HEAD`.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 05:48:39 MSK — Zakrepitj kontrakt universaljnogo dispetchera avtomatizacij FUM](../../Zhurnal/2026-08-05_05-48-39_MSK_zakrepitj-kontrakt-universaljnogo-dispetchera-avtomatizacij-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:a6199b62582492b266db5f7d6c31074aa9fa18cac3a38d2e7ddb9a6bd470295f -->
<!-- FUM-MD-RECENCY:END -->
