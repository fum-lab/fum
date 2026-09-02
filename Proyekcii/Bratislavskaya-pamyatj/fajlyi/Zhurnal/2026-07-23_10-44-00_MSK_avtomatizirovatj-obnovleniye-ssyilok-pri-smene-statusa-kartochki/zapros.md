# Iskhodnyij zapros 2026-07-23 10:44:00 MSK - Avtomatizirovatj obnovleniye ssyilok pri smene statusa kartochki

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-23 10:22:00 MSK - Opisatj shablon scenariya modeljnoj sredyi](../2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi/zapros.md)
- Sleduyusjhij zapros: [2026-07-23 11:50:58 MSK - Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md)

## Tekst zaprosa

```text
Проверка связности нашла ровно два ожидаемых последствия git mv: исторические списки затронутых файлов ссылались на прежний 🟡-путь карточки. Исправляю только адреса этих ссылок на новый ✅-путь, добавляю оба файла в текущий список влияния и повторно генерирую recency/граф.

Nuzhno ispravitj etu problemu. Veroyatno, pri izmenenii statusa nuzhno delatj prostuyu algoritmicheskuyu avtozamenu po vsem tekstam.
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f8de4-cf58-7e33-882f-63551ca0cf4e

## Rezuljtat

Smena zhiznennogo statusa ili opisateljnogo imeni [kartochki shaga](../../Glossarij/kartochka-shaga.md) perevoditsya s ruchnogo `git mv` na lokaljnuyu TDD-proverennuyu komandu planovogo reyestra. Komanda sokhranyayet Git-pereimenovaniye, vyivodit novyij putj iz neizmenyayemogo `card_id`, statusa i opisaniya, sinkhroniziruyet status v TOML i indekse i zamenyayet prezhneye imya fajla vo vsekh dostupnyikh tekstovyikh materialakh proyekta.

Doslovnyij blok `## Текст запроса` i syiryiye materialyi `Источники/` ostayutsya neizmennyimi kak pervichnyiye istochniki. Avtozamena dejstvuyet na zhivyiye ssyilki, spiski vliyaniya, mashinnyiye zapisi i ostaljnyiye tekstovyiye predstavleniya; poetomu istoricheskij payload prodolzhayet svideteljstvovatj o fakticheskom vkhode, a navigaciya ukazyivayet na aktualjnyij putj.

Vse novyiye versii fajlov i rezervnyiye kopii podgotavlivayutsya do `git mv`, a sboj ustanovki otkatyivayet uzhe zamenyonnyiye bajtyi i sam Git-perenos. Nedostupnyij vetochnyij selektor i dublikat `card_id`, v tom chisle v novoj yesjhyo ne otslezhivayemoj kartochke, ostanavlivayut komandu do mutacii.

## Status avtomatizacii

Povedeniye zakrepleno v susjhestvuyusjhej avtomatizacii `fum-reyestr-planirovaniya`, chtobyi operaciya smenyi kartochnogo puti i proverka kartochnogo kontrakta ne raskhodilisj mezhdu raznyimi instrumentami. Regressionnyiye testyi vosproizvodyat oba najdennyikh istoricheskikh spiska, uglovyiye skobki Markdown-celi, mashinnyij putj i doslovnyij iskhodnyij zapros.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-reyestr-planirovaniya`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya dopuska, kanonicheskogo vremeni, izmeneniya kartochnogo kontrakta, generacii i itogovoj priyomki.
- Poverkhnostj Codex Desktop i kontraktyi `functions.*` i `collaboration.*` — otdeljnyiye versii tekusjhej sessiyej ne raskryivayutsya; ispoljzovanyi dlya lokaljnyikh komand, patch-pravok, plana i paralleljnyikh read-only-auditov.
- Git, Python, ripgrep i Zsh — versii i sposobyi proverki zafiksirovanyi v reyestre; ispoljzovanyi dlya poiska, TDD, tekstovoj zamenyi, Git-pereimenovaniya i proverok.

## Povliyal na fajlyi

Kazhdyij putj itogovogo Git-sostoyaniya perechislen yavno dlya predkommitnoj proverki svyaznosti.

- [.obsidian/graph.json](<../../../../../.obsidian/graph.json>)
- [AGENTS.md](../../AGENTS.md)
- [Zhurnal/2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Zaprosyi/2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi.md](../2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi/zapros.md)
- [Zaprosyi/2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki.md](zapros.md)
- [Glossarij/kartochka-shaga.md](../../Glossarij/kartochka-shaga.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/fum-reyestr-planirovaniya/SKILL.md](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md)
- [Instrumentyi/fum-reyestr-planirovaniya/scripts/rename-step-card.py](../../Instrumentyi/fum-reyestr-planirovaniya/scripts/rename-step-card.py)
- [Instrumentyi/fum-reyestr-planirovaniya/tests/test_rename_step_card.py](../../Instrumentyi/fum-reyestr-planirovaniya/tests/test_rename_step_card.py)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Planirovaniye/kartochki-shagov/README.md](../../Planirovaniye/kartochki-shagov/README.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)

## Proverki

- Avtonomnyij TDD-nabor `fum-reyestr-planirovaniya` podtverzhdayet Git-pereimenovaniye, sinkhronizaciyu statusa, zamenu prezhnego imeni vo vsekh zhivyikh tekstovyikh predstavleniyakh, otkat vnedryonnogo sboya zapisi i fail-closed-proverki dublikatov i vetochnyikh zapisej pri neizmennosti pervichnyikh istochnikov.
- Planovyij reyestr, recency-metki, graf Obsidian, svyaznostj rabochej sessii, `git diff --check` i polnyij smoke-check prokhodyat pered atomarnyim kommitom ocheredi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8eede1073189185f89facbbe4842c6bd6a4e352fbc366bf6a15ab750a817b7e3 -->
<!-- FUM-MD-RECENCY:END -->
