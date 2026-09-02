# Otchyot 2026-06-24 14:33:08 MSK

## Glavnoye

[Arkhivirovaniye prikreplyayemyikh materialov](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) perevedeno iz spiska [MVP-kandidatov](../../Glossarij/MVP-kandidat.md) v aktivnuyu rabotu. Eto delayet pervyim vyibrannyim MVP-konturom FUM vkhodnoj sloj [pamyati](../../Glossarij/pamyatj-FUM.md): vneshnij material dolzhen stanovitjsya lokaljnyim istochnikom s proiskhozhdeniyem, indeksom, otchyotom ob izvlechenii i ssyilkoj iz fajla zaprosa.

## Chto izmenilosj

- V planirovanii zafiksirovan tekusjhij vyibor: aktivnyim MVP-kandidatom stalo arkhivirovaniye prikreplyayemyikh materialov.
- [Dorozhnaya karta](../../Planirovaniye/dorozhnaya-karta.md) i [dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md) dopolnenyi minimaljnyim kontraktom etogo kontura.
- V `archive-chatgpt-share.py` dobavleno sozdaniye `source-index.md` i obnovleniye fajla zaprosa, peredannogo cherez `--request-file`.
- Testyi `fum-request-materials` rasshirenyi TDD-proverkoj: snachala byil zafiksirovan krasnyij rezuljtat na otsutstvuyusjhem kontrakte, zatem realizaciya dovedena do prokhozhdeniya testov.

## Znacheniye dlya proyekta

Vyibor etogo MVP delayet vneshniye materialyi ne prilozheniyem k dialogu, a polnocennyim vkhodom [pamyati FUM](../../Glossarij/pamyatj-FUM.md). Teperj blizhajshaya razrabotka budet proveryatj ne toljko sokhraneniye HTML ili JSON, no i navigacionnuyu prigodnostj istochnika: u nego dolzhen byitj chelovekochitayemyij indeks, otchyot o granicakh izvlecheniya i obratnaya ssyilka iz [iskhodnogo zaprosa](../../Glossarij/iskhodnyij-zapros.md).

Pervyij inkrement ostayotsya uzkim i poleznyim: on ne obesjhayet universaljnyij arkhivator vsekh formatov, no ukreplyayet uzhe susjhestvuyusjhij kontur ChatGPT share i zadayot kontrakt dlya sleduyusjhikh tipov materialov.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - snachala ozhidayemo upalo na otsutstvuyusjhikh funkciyakh, zatem proshlo posle realizacii.
- `git diff --check` - proshlo bez zamechanij.
- Lokaljnaya proverka otnositeljnyikh Markdown-ssyilok v izmenyonnyikh Markdown-fajlakh - proshla, bityikh ssyilok ne najdeno.

## Istochniki

- [iskhodnyij zapros 2026-06-24 14:33:08 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:17ba55c510268c517b661db84dba61be16d36db65030b49c0f2ca5deeeac50b1 -->
<!-- FUM-MD-RECENCY:END -->
