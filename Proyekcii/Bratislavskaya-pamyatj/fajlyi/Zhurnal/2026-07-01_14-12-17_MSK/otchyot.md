# Otchyot 2026-07-01 14:12:17 MSK

## Glavnoye

Sobran yedinyij lokaljnyij smoke-check repozitoriya FUM. Teperj bazovyij regressionnyij kontur zapuskayetsya odnoj komandoj: testyi lokaljnyikh avtomatizacij, peresborka proveryayemogo planovogo reyestra, recency-proverka i proverka svyaznosti vyibrannoj rabochej sessii.

## Chto izmenilosj

- Sozdana avtomatizaciya [fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) so skriptom `run-smoke-check.py`.
- Dobavlenyi testyi, kotoryiye fiksiruyut spisok shagov polnogo smoke-check, chastichnyij rezhim bez proverki sessii i trebovaniye `--request` dlya polnogo zapuska.
- Obnovlenyi [Instrumentyi/README.md](../../Instrumentyi/README.md), [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) i dokument [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md).
- Predlozheniye o smoke-check pereneseno v istoriyu vyipolnennyikh predlozhenij v [planirovanii](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md).

## Resheniya

Smoke-check avtomaticheski obnaruzhivayet katalogi `Инструменты/*/tests`, chtobyi novyiye lokaljnyiye avtomatizacii s testami popadali v obsjhij progon bez otdeljnoj ruchnoj nastrojki.

Proveryayemyiye reyestryi poka predstavlenyi planovyim JSON-reyestrom. Yesli v proyekte poyavitsya novyij proveryayemyij reyestr, yego nuzhno dobavitj v scenarij smoke-check yavno i zakrepitj ozhidaniye testom.

Polnyij rezhim trebuyet fajl zaprosa cherez `--request`, potomu chto proverka svyaznosti rabochej sessii ne imeyet bezopasnogo znacheniya po umolchaniyu.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` - proshlo, 3 testa.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-01_14-12-17_MSK.md` - proshlo, 11 shagov, 7 testovyikh naborov, 41 test.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_14-12-17_MSK.md` - proshlo.

## Istochniki

- [iskhodnyij zapros 2026-07-01 14:12:17 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a81b47e5da1ff1257ee8d0b06941200aad8c3cb334cb0ce78d2739fdf4551431 -->
<!-- FUM-MD-RECENCY:END -->
