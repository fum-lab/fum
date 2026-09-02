# Iskhodnyij zapros 2026-06-24 14:33:08 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-06-24 14:22:45 MSK](../2026-06-24_14-22-45_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-06-24 14:41:33 MSK](../2026-06-24_14-41-33_MSK/zapros.md)

## Tekst zaprosa

> MVP-кандидат: архивирование прикрепляемых материалов — beryom v rabotu.

## Povliyal na fajlyi

- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Zhurnal/2026-06-24_14-33-08_MSK.md](otchyot.md)
- [Zaprosyi/2026-06-24_14-22-45_MSK.md](../2026-06-24_14-22-45_MSK/zapros.md)
- [Zaprosyi/2026-06-24_14-33-08_MSK.md](zapros.md)
- [Instrumentyi/fum-request-materials/SKILL.md](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)
- [Instrumentyi/fum-request-materials/scripts/archive-chatgpt-share.py](../../Instrumentyi/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py)
- [Instrumentyi/fum-request-materials/tests/test_archive_chatgpt_share.py](../../Instrumentyi/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py)
- [Planirovaniye/README.md](../../Planirovaniye/README.md)
- [Planirovaniye/dorozhnaya-karta.md](../../Planirovaniye/dorozhnaya-karta.md)
- [Planirovaniye/MVP-kandidatyi/README.md](../../Planirovaniye/MVP-kandidatyi/README.md)
- [Planirovaniye/MVP-kandidatyi/matrica-otbora.md](../../Planirovaniye/MVP-kandidatyi/matrica-otbora.md)
- [Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - snachala ozhidayemo upalo na otsutstvuyusjhikh funkciyakh `write_source_index` i `link_source_in_request_file`, zatem proshlo posle realizacii.
- `git diff --check` - proshlo bez zamechanij.
- Lokaljnaya proverka otnositeljnyikh Markdown-ssyilok v izmenyonnyikh Markdown-fajlakh - proshla, bityikh ssyilok ne najdeno.

## Opisaniye sdelannogo

[MVP-kandidat](../../Glossarij/MVP-kandidat.md) [arkhivirovaniye prikreplyayemyikh materialov](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) perevedyon v aktivnuyu rabotu. V planirovanii i dorozhnoj karte zafiksirovano, chto tekusjhij pervyij MVP-kontur FUM stroitsya vokrug lokaljnogo arkhivirovaniya vneshnikh materialov v [pamyati FUM](../../Glossarij/pamyatj-FUM.md).

Pervyij inzhenernyij inkrement vyipolnen v `Инструменты/fum-request-materials/`: dlya `archive-chatgpt-share.py` dobavlen proveryayemyij kontrakt `source-index.md` i idempotentnogo svyazyivaniya papki istochnika s fajlom [iskhodnogo zaprosa](../../Glossarij/iskhodnyij-zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3db5eb11c33922c762daa5591a4266594d8c23ecf09784954b68b8f4fe9e8340 -->
<!-- FUM-MD-RECENCY:END -->
