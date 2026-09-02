# Iskhodnyij zapros 2026-06-24 15:45:41 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-06-24 15:35:16 MSK](../2026-06-24_15-35-16_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-06-24 15:54:42 MSK](../2026-06-24_15-54-42_MSK/zapros.md)

## Tekst zaprosa

> Sozdaj avtomatizaciyu sozdaniya agregacij neskoljkikh statej v odnu statjyu na obsjhuyu, analogichno predyidusjhej zadache s arkhitekturoj.

## Povliyal na fajlyi

- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Dokumentaciya/22-arkhitektura-FUM.md](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/fum-doc-aggregation/SKILL.md](../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/SKILL.md)
- [Instrumentyi/fum-doc-aggregation/scripts/build-doc-aggregation.py](../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/scripts/build-doc-aggregation.py)
- [Instrumentyi/fum-doc-aggregation/tests/test_build_doc_aggregation.py](../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/tests/test_build_doc_aggregation.py)
- [Zhurnal/2026-06-24_15-45-41_MSK.md](otchyot.md)
- [Zaprosyi/2026-06-24_15-35-16_MSK.md](../2026-06-24_15-35-16_MSK/zapros.md)
- [Zaprosyi/2026-06-24_15-45-41_MSK.md](zapros.md)

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - proshlo.
- `git diff --check` - proshlo bez zamechanij.
- Proverka otnositeljnyikh Markdown-ssyilok v izmenyonnyikh Markdown-fajlakh - proshla, bityikh ssyilok ne najdeno.

## Opisaniye sdelannogo

Sozdana lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) `fum-doc-aggregation` dlya sborki i proverki svodnyikh statej [proizvodnoj dokumentacii](../../Glossarij/proizvodnaya-dokumentaciya.md) iz neskoljkikh opornyikh dokumentov.

Avtomatizaciya soderzhit instrukciyu primeneniya, generator Markdown-karkasa, validator zavershyonnogo dokumenta i lokaljnyiye testyi, kotoryiye fiksiruyut kontrakt: ssyilka na iskhodnyij zapros, vse opornyiye dokumentyi, obyazateljnyiye razdelyi, princip nezamesjheniya istochnikov i otsutstviye chyornovyikh markerov v zavershyonnoj statjye.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6aeb1bbc27e2fcf8c916854de7ebcc7a02bbd8ecdf285a3cfc8853ecf6eb2c9a -->
<!-- FUM-MD-RECENCY:END -->
