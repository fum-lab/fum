# Otchyot 2026-07-17 12:20:17 MSK - Sozdatj skriptyi zapuska prototipov

Dva dejstvuyusjhikh Swift-prototipa poluchili yedinoobraznyiye ispolnyayemyiye tochki vkhoda `запустить.sh`. Dlya zapuska boljshe ne nuzhno pomnitj imya Swift-produkta, dlinnyij `--package-path` ili predvariteljno perekhoditj v katalog paketa: kazhdyij skript sam opredelyayet svoyo raspolozheniye i peredayot dopolniteljnyiye argumentyi prototipu.

Tenevoj redaktor zapuskayetsya kak graficheskoye prilozheniye, prinimayet neobyazateljnyij putj k tekstovomu fajlu i podderzhivayet spravku bez otkryitiya GUI. Klaviaturnyij prototip po umolchaniyu vyivodit bezopasnuyu vosproizvodimuyu matricu istochnikov; cherez tot zhe skript dostupnyi proverki sredyi i ustrojstv, a zapisj fizicheskikh sobyitij po-prezhnemu trebuyet otdeljnoj yavnoj komandyi.

Novyij kontrakt rasprostranyon na budusjhiye prototipyi cherez `AGENTS.md` i indeks `Прототипы/README.md`. Chtobyi pravilo ne ostalosj toljko tekstom, sozdana lokaljnaya avtomatizaciya `fum-prototype-launch`: ona proveryayet nalichiye `запустить.sh` u kazhdogo kataloga-prototipa s pasportom, ispolnyayemyij bit, shebang `#!/bin/sh` i korrektnostj POSIX shell-sintaksisa. Proverka vklyuchena v obsjhij smoke-check.

## Resheniye po avtomatizacii

Proverka tochek vkhoda realizovana cherez TDD. Avtonomnyiye testyi pokryivayut korrektnyij skript, otsutstviye kataloga prototipov, otsutstviye fajla, otsutstviye ispolnyayemogo bita, nevernyij shebang, sintaksicheskuyu oshibku i ignorirovaniye sluzhebnyikh katalogov bez pasporta prototipa. Smoke-check poluchil otdeljnyij obyazateljnyij shag, poetomu novyij prototip bez prostoj tochki vkhoda ne projdyot obsjhij proverochnyij kontur.

## Proverki

- Krasnyij TDD-cikl podtverdil otsutstviye proveryayusjhego skripta i shaga smoke-check do realizacii.
- Shestj testov `fum-prototype-launch` proshli bez oshibok.
- Pyatj testov `fum-smoke-check` proshli bez oshibok.
- Strukturnaya proverka prinyala obe tochki vkhoda.
- `теневой-редактор-продолжений/запустить.sh --help` uspeshno vyipolnen iz `/tmp` bez zapuska GUI.
- `физические-состояния-клавиш/запустить.sh` uspeshno sobral probnik iz `/tmp` i vyivel vosproizvodimuyu matricu.
- `swift test` proshyol 30 testov tenevogo redaktora i 16 testov klaviaturnogo prototipa; GUI-produkt redaktora otdeljno sobran.
- Planovyij reyestr, recency-metki, indeks Markdown-fajlov i teplovaya karta Obsidian peresobranyi i proverenyi.
- `git diff --check`, svyaznostj rabochej sessii i polnyij smoke-check iz 17 shagov proshli bez oshibok.

## Prodolzheniye

Otdeljnogo sleduyusjhego shaga dlya infrastrukturyi zapuska ne trebuyetsya: pravilo i avtomaticheskaya zasjhita uzhe dejstvuyut. Pri sozdanii kazhdogo sleduyusjhego prototipa yego poleznyij bezopasnyij scenarij bez argumentov nuzhno vyibratj po smyislu i opisatj v pasporte; potencialjno chuvstviteljnyiye dejstviya dolzhnyi ostavatjsya toljko yavno vklyuchayemyimi komandami.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [pravila repozitoriya](../../AGENTS.md)
- [indeks prototipov](../../Prototipyi/README.md)
- [tenevoj redaktor prodolzhenij](../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md)
- [fizicheskiye sostoyaniya klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [avtomatizaciya proverki tochek vkhoda](../../Instrumentyi/fum-zapusk-prototipov/SKILL.md)

## Istochniki

- [iskhodnyij zapros 2026-07-17 12:20:17 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a70b0ad5f939d0dfc75dd7b06993f987914df0c0d172359d21cd31adffc23570 -->
<!-- FUM-MD-RECENCY:END -->
