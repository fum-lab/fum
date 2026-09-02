# Otchyot 2026-07-20 23:08:44 MSK - Vosstanovitj obratnyiye ssyilki voprosov

Sessiya vosstanovila vidimostj otkryityikh i chastichno proyasnyonnyikh neopredelyonnostej vo vsekh materialakh, kotoryiye dejstviteljno zavisyat ot ikh razresheniya. Avtonomnaya proverka teperj uderzhivayet dvunapravlennostj mezhdu aktivnyimi voprosami i zayavlennyimi celyami v polnom smoke-check.

## Iskhodnoye sostoyaniye

Odnorazovyij audit revjyu fiksiroval 21 otsutstvuyusjhuyu obratnuyu ssyilku sredi 69 celej v `Документация/` i `Планирование/`. Rasshirennaya strukturnaya sverka vsekh ssyilok razdelov `Затронутая документация` nashla 85 celej i 31 otsutstvuyusjhuyu obratnuyu ssyilku pri 14 otkryityikh ili chastichno proyasnyonnyikh voprosakh.

Do vosstanovleniya ssyilok kazhdaya celj proverena po smyislu dvumya nezavisimyimi prokhodami. Vse 85 zayavlennyikh celej dejstviteljno zavisyat ot sootvetstvuyusjhej nereshyonnoj chasti voprosa; oshibochnyikh celej, kotoryiye trebovali byi pravki samogo voprosa, ne najdeno. Dlya 31 otsutstvovavshej svyazi obratnaya ssyilka dobavlena ryadom s zavisimyim tezisom, a v shesti korotkikh glossarnyikh statjyakh — v nizhnij razdel svyazannyikh dokumentov.

## TDD

Krasnaya faza nachalasj s testov susjhestvuyusjhej celi bez obratnoj ssyilki, nesusjhestvuyusjhej celi, nesovpadayusjhego registra pryamogo i obratnogo puti, otkryitogo i chastichno proyasnyonnogo statusa i ignorirovaniya proyasnyonnogo voprosa. Nabor ozhidayemo padal iz-za otsutstvuyusjhego scenariya, a test smoke-check — iz-za otsutstvuyusjhego shaga.

Posle pervoj zelyonoj realizacii nezavisimoye revjyu nashlo fail-open kraya Markdown-parsinga. Regressii otdeljno zakrepili obyazateljnostj oboikh statusnyikh razdelov indeksa, otsutstviye ili pustotu razdela celej, pustuyu i fragment-only celj, ne-Markdown-fajl, zagolovki i ssyilki vnutri fenced-primerov, smeshannyiye markeryi fence, izobrazheniya, inline-code, HTML-kommentarii, ekranirovannuyu psevdossyilku, vneshnij symlink i fakticheskiye kodyi zaversheniya CLI. Itogovyij avtonomnyij nabor soderzhit 21 test.

## Proverka dvunapravlennosti

Novaya lokaljnaya avtomatizaciya [fum-question-backlinks](../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/SKILL.md) poluchayet sostav aktivnyikh voprosov toljko iz razdelov `Открытые вопросы` i `Частично прояснённые вопросы` indeksa `Вопросы/README.md`. Dlya kazhdoj lokaljnoj ssyilki iz yedinstvennogo nepustogo razdela `## Затронутая документация` ona proveryayet susjhestvovaniye Markdown-fajla, tochnyij registr puti, otsutstviye dublya i khotya byi odnu vidimuyu Markdown-ssyilku obratno na vopros.

Izobrazheniya, inline-code, HTML-kommentarii, fenced-bloki i fragment-only ssyilki ne zaschityivayutsya. Pustaya, nesusjhestvuyusjhaya ili ne-Markdown-celj ostanavlivayet proverku. Kontekstnyiye ssyilki na vopros iz zaprosov, zhurnalov i drugikh materialov ne trebuyut obratnogo obyyavleniya celi: obyazateljnostj voznikayet toljko iz yavno zayavlennoj zatronutoj dokumentacii.

Na fakticheskoj pamyati proverka podtverzhdayet 14 aktivnyikh voprosov i 85 zayavlennyikh celej. Ona vklyuchena otdeljnyim obyazateljnyim shagom v [fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) posle proverki tochek vkhoda prototipov i do recency-kontura; setj i sekretyi ne ispoljzuyutsya.

## Prodolzheniye

Vyipolnennyij `master-restore-question-backlinks-v1` zamenyon gotovyim shagom `master-stabilize-service-generators-v1`. Sleduyusjhaya sessiya dolzhna cherez TDD otdelitj strukturnuyu svezhestj ot tekusjhej datyi i isklyuchitj `.build`, `.swiftpm` i kyeshi iz vkhodov recency, grafa Obsidian i svyaznostnyikh obkhodov.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-question-backlinks/tests -p 'test_*.py'` — 21 test prokhodit.
- `python3 Инструменты/fum-question-backlinks/scripts/check-question-backlinks.py` — 14 aktivnyikh voprosov, 85 zayavlennyikh celej.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` — 14 testov prokhodyat.
- Novaya zapisj `master-stabilize-service-generators-v1`, `git diff --check` i polnyij `fum-smoke-check` s proverkoj tekusjhej rabochej sessii prokhodyat.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [revjyu proyekta 2026-07-18](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)
- [indeks voprosov](../../Voprosyi/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2e67ceadac2d2bf4187fb0555af0b4ec2ad0b181985d7a35b3f7477a643788fc -->
<!-- FUM-MD-RECENCY:END -->
