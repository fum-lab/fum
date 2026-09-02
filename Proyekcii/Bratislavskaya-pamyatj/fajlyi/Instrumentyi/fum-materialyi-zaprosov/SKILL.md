---
name: fum-materialyi-zaprosov
description: Sokhranyatj ustojchivyiye URL v obsjhej papke Istochniki, a prinadlezhasjhiye odnomu zaprosu materialyi — vnutri yego papki Zhurnala. Ispoljzovatj obsjhij vkhod fum source archive dlya HTML-URL, specializirovannyij ChatGPT-share-kontur dlya rassharennyikh dialogov i kanonicheskij protokol publikacionnoj ochistki, snimkov i ssyilok.
---

# FUM Request Materials

Etot navyik fiksiruyet prikreplyayemyiye materialyi kak chastj pamyati FUM, sokhranyaya svyazj:
iskhodnyij zapros -> papka istochnikov -> proizvodnaya dokumentaciya ili instrument -> kommit.

## Osnovnoj protokol

1. Sozdaj ili obnovi fajl iskhodnogo zaprosa `Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md` po pravilam `AGENTS.md`; vremennoj prefiks imeni papki obyazatelen, tekst zaprosa sokhranyaj doslovno. Pri importe znanij iz ChatGPT-dialoga vyibiraj kratkoye nazvaniye zaprosa po soderzhaniyu dialoga posle pervichnogo izvlecheniya ili chteniya, a ne po obsjhemu faktu importa iz ChatGPT.
2. Dlya materiala s ustojchivyim URL ispoljzuj obsjhuyu kanonicheskuyu URL-papku `Источники/URL/<scheme>/<host>/<path...>/` ot kornya repozitoriya: cepochka katalogov povtoryayet skhemu, domen i putj URL. Povtornyiye zaprosyi na tot zhe URL dolzhnyi ssyilatjsya na etu zhe papku, a ne sozdavatj kopiyu. Dlya materiala bez ustojchivogo URL ispoljzuj prinadlezhasjhuyu zaprosu papku `Журнал/<имя-запроса>/материалы/источники/<описательное-название>/`.
3. Sokhranyaj istochnik maksimaljno syiro: URL, HTTP-zagolovki, telo otveta, vstroyennyiye JSON/potoki prilozheniya, izvlechyonnyiye soobsjheniya ili tekst, otchyot ob izvlechenii.
4. Ne kommitj sekretyi i lokaljnyiye sluzhebnyiye dannyiye. Redact `Set-Cookie`, tokenyi, lokaljnyiye IP/geometadannyiye zaprosa, sessionnyiye identifikatoryi, sluzhebnyiye request-id raspakovannyikh potokov i drugiye znacheniya, ne yavlyayusjhiyesya soderzhaniyem materiala. Kazhduyu redakciyu fiksiruj v otchyote.
5. V `запрос.md` ukazhi ssyilku na obsjhuyu URL-papku libo sobstvennuyu papku materiala i, kogda polezno, na otchyot ob izvlechenii ili osnovnyiye izvlechyonnyiye fajlyi. Yesli material vliyayet na trebovaniya, dokumentaciyu, glossarij ili instrumentyi, ukazhi eti ssyilki v razdele `## Повлиял на файлы` ili otdeljnom razdele `## Прикрепляемые материалы` fajla zaprosa.
6. Pered kommitom vyipolni `git status --short` i vklyuchi toljko osmyislennyiye izmeneniya tekusjhej sessii.

## Obsjhij vkhod dlya ustojchivogo HTML-URL

Pervyij obsjhij poljzovateljskij vkhod arkhivatora zapuskayetsya iz kornya repozitoriya:

```bash
./fum source archive "https://example.com/article" \
  --request "Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md"
```

Yesli korenj repozitoriya dobavlen v `PATH`, ta zhe komanda vyizyivayetsya kak `fum source archive`. Tonkij kornevoj vkhod peredayot URL i fajl zaprosa perenosimomu modulyu `scripts/source_archive.py`. Obyichnyij transport ispoljzuyet `curl`, a orkestraciya ne zavisit ot transporta: snachala v sosednem staging-kataloge polnostjyu sobirayetsya i proveryayetsya snimok, zatem on ustanavlivayetsya atomarno i toljko posle etogo fajl zaprosa poluchayet ssyilki.

Dlya HTML-URL obsjhij snimok soderzhit:

- `source-url.txt` — iskhodnyij ustojchivyij URL;
- `response.headers.txt` — HTTP-zagolovki s udalyonnyimi znacheniyami `Set-Cookie`;
- `response.body.html` — telo HTML-otveta v iskhodnyikh bajtakh transporta;
- `extracted-text.md` — vidimyij tekst bez `script`, `style`, `template` i `svg`;
- `structured-data.json` — raspoznannyiye JSON-LD-dannyiye, yesli oni prisutstvuyut i korrektnyi;
- `source-index.md` — chelovekochitayemyij vkhod v snimok;
- `extraction-report.md` — transport, rezuljtat izvlecheniya, redakcii i ogranicheniya;
- `snapshot-manifest.json` — tochnyij perechenj vsekh fajlov ustanovlennogo snimka.

Peremennyiye `FUM_SOURCE_ARCHIVE_TEST_FIXTURE_DIR` i `FUM_SOURCE_ARCHIVE_TEST_FAILPOINT` yavlyayutsya toljko avtonomnyimi testovyimi tochkami podmenyi. Pervaya napravlyayet tot zhe CLI na lokaljnyiye `response.headers.txt` i `response.body.html`, vtoraya dopuskayet toljko pozdnij sboj `after-build` posle polnoj proverki staging i do ustanovki. Oni ne yavlyayutsya aljternativnyim poljzovateljskim protokolom i ne nuzhnyi pri obyichnom arkhivirovanii.

## Celostnostj povtornogo snimka

`archive-chatgpt-share.py` sobirayet kazhdyij novyij snimok v skryitom sosednem staging-kataloge na toj zhe fajlovoj sisteme, ne zapisyivaya promezhutochnyiye rezuljtatyi v kanonicheskuyu URL-papku. Pered ustanovkoj skript sozdayot `snapshot-manifest.json` skhemyi `fum.request-materials.snapshot-manifest.v1` i proveryayet tochnoye ravenstvo otsortirovannogo spiska `managed_files` fakticheskomu naboru fajlov staging.

Pervyij snimok ustanavlivayetsya atomarnyim pereimenovaniyem kataloga. Povtornyij snimok zamenyayet susjhestvuyusjhij katalog odnim obmenom direktorij: `RENAME_SWAP` na macOS ili `RENAME_EXCHANGE` na Linux. Yesli sistemnyij vyizov ili fajlovaya sistema ne podderzhivayet atomarnyij obmen, povtor zakryivayetsya s oshibkoj do izmeneniya kanonicheskogo snimka; dvukhshagovaya zamena cherez vremenno otsutstvuyusjhij kanonicheskij putj ne dopuskayetsya.

Posle uspeshnogo obmena novyij kanonicheskij katalog uzhe yavlyayetsya zafiksirovannyim celyim snimkom. Ssyilka dobavlyayetsya v fajl zaprosa cherez vremennyij sibling i atomarnyij `os.replace`, poetomu I/O-sboj ne dolzhen usekatj prezhnij tekst zaprosa. Nevozmozhnostj dobavitj ssyilku vyivoditsya kak otdeljnoye preduprezhdeniye `request_file_linked error` i ne vyidayotsya za neuspeshnoye arkhivirovaniye uzhe ustanovlennogo snimka. Ochistka prezhnego snimka iz staging vyipolnyayetsya best-effort; yesli skryityij sosednij `.staging-*` ostalsya posle commit, skript yavno preduprezhdayet ob etom. Takoj katalog ne vkhodit v novyij manifest, ne schitayetsya kanonicheskim istochnikom i dolzhen byitj otdeljno proveren kak lokaljnyij vremennyij ostatok pered kommitom.

## Proverki

Lokaljnyiye testyi skriptov navyika zapuskayutsya bez setevyikh vyizovov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-materialyi-zaprosov/tests -p 'test_*.py'
```

Pri izmenenii skriptov snachala dobavlyaj ili obnovlyaj test ozhidayemogo povedeniya, zatem menyaj realizaciyu i povtoryaj zapusk testov. Skvoznoj avtonomnyij kontrakt obsjhego vkhoda ispoljzuyet fiksturu `tests/fixtures/simple-html/` i posledovateljnostj `v1 -> v2 -> поздний сбой`: pervyij snimok soderzhit JSON-LD, vtoroj udalyayet otsutstvuyusjhij strukturnyij fajl, a pozdnij sboj ostavlyayet vtoroj snimok pobajtno neizmennyim. Regressionnyij nabor specializirovannogo ChatGPT-share-vkhoda dopolniteljno vklyuchayet posledovateljnosti `полный снимок -> неполный снимок`, `полный снимок -> поздний сбой staging` i otkaz bez zapisi, kogda atomarnyij obmen katalogov nedostupen.

## ChatGPT share

Dlya rassharennyikh chatov ChatGPT ispoljzuj skript:

```bash
python3 Инструменты/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py \
  "https://chatgpt.com/share/<id>" \
  --request-file "Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md"
```

Skript po umolchaniyu sokhranyayet v papku istochnikov `Источники/URL/https/chatgpt.com/share/<id>/`. `--output-dir` ispoljzuyetsya toljko dlya yavnogo nestandartnogo razmesjheniya, a `--source-name` sokhranyon dlya sovmestimosti i ne nuzhen dlya obyichnogo URL-puti.

V papke istochnikov sokhranyayutsya:

- `source-url.txt` - iskhodnaya ssyilka.
- `chatgpt-share.headers.txt` - HTTP-zagolovki s redaktirovannyimi cookie.
- `chatgpt-share.html` - HTML-otvet s redaktirovannyim lokaljnyim bootstrap-sostoyaniyem.
- `chatgpt-share.script-XX.txt` - krupnyiye skriptovyiye bloki i potokovyiye dannyiye prilozheniya.
- `chatgpt-share.initial-state.json` - redaktirovannoye nachaljnoye sostoyaniye stranicyi, yesli ono najdeno.
- `chatgpt-share.react-router-stream.txt` - izvlechyonnyij potok React Router.
- `chatgpt-share.decoded-data.json` - raspakovannyiye dannyiye dialoga, yesli format raspoznan.
- `chatgpt-share.messages.json` - polnyij strukturnyij sloj izvlechyonnyikh soobsjhenij v poryadke dialoga.
- `<название-диалога-в-kebab-case>.md` - oformlennyij chelovekochitayemyij sloj dialoga.
- `source-index.md` - chelovekochitayemyij indeks istochnika so ssyilkami na oformlennyij sloj, otchyot i strukturnyiye fajlyi.
- `extraction-report.md` - otchyot o sposobe izvlecheniya, kolichestve soobsjhenij i redakciyakh.
- `snapshot-manifest.json` - tochnyij otsortirovannyij perechenj vsekh fajlov, kotoryimi upravlyayet ustanovlennyij snimok, vklyuchaya sam manifest.

Oformlennyij Markdown-fajl dolzhen byitj nazvan po chelovekochitayemomu nazvaniyu dialoga iz istochnika ili bezopasnomu fallback-nazvaniyu, naprimer `запуск-долгоживущей-цепочки.md`. Zagolovok pervogo urovnya raven etomu nazvaniyu, a soobsjheniya imeyut chitayemyiye russkiye podpisi rolej. Sluzhebnyiye soobsjheniya, vyivodyi instrumentov i mashinnyiye JSON-vyizovyi ne vklyuchayutsya v oformlennyij sloj; oni sokhranyayutsya v `chatgpt-share.messages.json`.

TeX-formulyi v oformlennom Markdown-sloye privodyatsya k formatu, kotoryij Obsidian otobrazhayet cherez MathJax: blochnyiye formulyi pishutsya v `$$ ... $$`, a strochnyiye formulyi - v `$...$`. Syiroj strukturnyij sloj ne normalizuyetsya radi otobrazheniya.

Yesli v papke istochnika yestj `source-index.md`, ukazhi v nyom chelovekochitayemoye nazvaniye dialoga i ssyilku na oformlennyij Markdown-fajl s nazvaniyem dialoga, chtobyi istochnik mozhno byilo ponyatj bez otkryitiya syirogo JSON ili HTML.

Skript takzhe obnovlyayet fajl, peredannyij cherez `--request-file`: dobavlyayet razdel `## Прикрепляемые материалы` so ssyilkami na papku istochnika, `source-index.md` i `extraction-report.md`. Povtornyij zapusk dlya togo zhe zaprosa i istochnika ne dolzhen dublirovatj eti ssyilki.

Yesli skript ne smog izvlechj soobsjheniya, ostavj syiroj HTML, zagolovki, potokovyiye bloki i otchyot s prichinoj. Ne vyidumyivaj otsutstvuyusjhij tekst dialoga.

## Drugiye materialyi

Dlya neraspoznannogo formata sokhranyaj naiboleye blizkij k syiromu sloj, kotoryij realjno poluchen:

- dlya URL - zagolovki, telo otveta, effective URL, kod otveta i datu izvlecheniya;
- dlya fajlov - originaljnyij fajl bez normalizacii i otdeljnyij otchyot o proiskhozhdenii;
- dlya dinamicheskikh stranic - HTML, skrinshot ili tekst DOM, yesli oni dostupnyi, plyus opisaniye ogranicheniya.

Yesli material nevozmozhno poluchitj iz-za dostupa, istecheniya share-ssyilki ili zasjhityi, zafiksiruj eto v otchyote i v fajle zaprosa.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-20 22:05:19 MSK - Sdelatj povtornoye arkhivirovaniye istochnika atomarnyim](../../Zhurnal/2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:99c90be987d835f991ad102ec2e9899a21b53bdb34561bbc0f6b5df7f9e2db07 -->
<!-- FUM-MD-RECENCY:END -->
