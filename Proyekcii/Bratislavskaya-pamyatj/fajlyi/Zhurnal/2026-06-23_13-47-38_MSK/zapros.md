# Iskhodnyij zapros 2026-06-23 13:47:38 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-06-23 13:26:21 MSK](../2026-06-23_13-26-21_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-06-23 13:55:41 MSK](../2026-06-23_13-55-41_MSK/zapros.md)

## Tekst zaprosa

> Davaj budem stremitjsya vosproizvoditj lokaljno v pamyati etogo repozitoriya vse avtomatizacii, kotoryiye myi ispoljzuyem, i budem pisatj testyi, kotoryiye proveryayut ikh rabotu. Budem ispoljzovatj TDD.

## Povliyal na fajlyi

- [AGENTS.md](../../AGENTS.md)
- [.gitignore](../../.gitignore)
- [README.md](../../README.md)
- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Glossarij/README.md](../../Glossarij/README.md)
- [Glossarij/TDD.md](../../Glossarij/TDD.md)
- [Glossarij/avtomatizaciya-FUM.md](../../Glossarij/avtomatizaciya-FUM.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/fum-request-materials/SKILL.md](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)
- [Instrumentyi/fum-request-materials/tests/test_archive_chatgpt_share.py](../../Instrumentyi/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py)
- [Zaprosyi/2026-06-23_13-26-21_MSK.md](../2026-06-23_13-26-21_MSK/zapros.md)

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - proshlo, 6 testov.

## Opisaniye sdelannogo

V pravila rabochej sessii dobavleno trebovaniye stremitjsya lokaljno vosproizvoditj ispoljzuyemyiye [avtomatizacii FUM](../../Glossarij/avtomatizaciya-FUM.md) v [pamyati FUM](../../Glossarij/pamyatj-FUM.md), sokhranyatj proveryayemyiye lokaljnyiye sloi dlya vneshnikh zavisimostej i razvivatj novyiye ili izmenyayemyiye avtomatizacii cherez [TDD](../../Glossarij/TDD.md). Dokumentaciya o vosproizvodimyikh avtomatizaciyakh dopolnena razdelom o lokaljnom vosproizvedenii, testakh i granicakh vneshnikh servisov. Dobavlen glossarnyij termin `TDD`. Dlya uzhe susjhestvuyusjhej avtomatizacii `fum-request-materials` dobavlenyi lokaljnyiye `unittest`-testyi, proveryayusjhiye redaktirovaniye chuvstviteljnyikh dannyikh, izvlecheniye potokovyikh chastej, dekodirovaniye tablicyi React Router i izvlecheniye soobsjhenij.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:b6a78e3f9fed8e9b9808005a9bed501b96c18a8bfee8a4eaf53cdb307af03a7e -->
<!-- FUM-MD-RECENCY:END -->
