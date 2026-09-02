---
name: fum-struktura-papok-zaprosov
description: Planiruyet, primenyayet i proveryayet yedinuyu strukturu papok zaprosov v Zhurnale, a takzhe po proverennyim khranimyim shablonam atomarno nachinayet novuyu sessiyu.
---

# Struktura papok zaprosov

Navyik zamenyayet ruchnoj massovyij perenos i povtoryayemoye ruchnoye sozdaniye sessij. On svodit iskhodnyij zapros, otchyot i odnoznachno prinadlezhasjhiye im artefaktyi v odin agregat:

```text
Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-имя]>/
  запрос.md
  отчёт.md
  материалы/
```

Prefiks vremeni obyazatelen i dolzhen byitj kalendarno vozmozhnyim. Istoricheskoye imya mozhet sostoyatj toljko iz prefiksa. Novaya papka poluchayet prefiks i kratkoye imya.

Dlya novoj rabochej sessii obyazateljnyi i `запрос.md`, i `отчёт.md`. Istoricheskaya papka mozhet ne soderzhatj `отчёт.md` toljko togda, kogda otdeljnogo otchyota ne susjhestvovalo do migracii; avtomatizaciya ne sozdayot takoj otchyot zadnim chislom.

## Kanonicheskiye shablonyi

[Shablon zaprosa](shablonyi/zapros.md.shablon) i [shablon otchyota](shablonyi/otchyot.md.shablon) yavlyayutsya yedinstvennyim kanonicheskim karkasom novyikh fajlov, sozdavayemyikh komandoj `start`. Suffiks `.шаблон`, a ne `.md`, namerenno isklyuchayet eti fajlyi iz indeksa proizvodnyikh Markdown-dokumentov, recency-metok i grafa Obsidian.

Shablon zaprosa soderzhit rovno po odnomu polyu `{{метка_времени}}`, `{{заголовок}}`, `{{предыдущий_запрос}}`, `{{следующий_запрос}}`, `{{текст_запроса}}` i `{{идентификатор_сеанса}}`. Shablon otchyota soderzhit rovno po odnomu polyu `{{метка_времени}}` i `{{заголовок}}`. Neizvestnoye, otsutstvuyusjheye, povtornoye, perestavlennoye ili povrezhdyonnoye pole, nevernyij H1, izmeneniye obyazateljnogo poryadka H2, skryitiye karkasa kommentariyem ili ogradoj, nevyirovnennaya tablica libo otsutstviye karkasa profilya vremeni ostanavlivayet `start` do zapisi. Simvolicheskaya ssyilka v puti shablona i vyikhod fajla iz kanonicheskogo kataloga takzhe otklonyayutsya. Podstanovka vyipolnyayetsya odnim prokhodom po iskhodnomu shablonu, poetomu doslovnyij poljzovateljskij tekst s posledovateljnostjyu vida `{{поле}}` ne interpretiruyetsya povtorno.

Kazhdyij trebuyusjhij zaversheniya smyislovoj blok sozdayotsya s markerom `<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->`. Pered kommitom agent zamenyayet instrukcii fakticheskim soderzhaniyem i udalyayet vse takiye markeryi; nezavisimaya proverka svyaznosti otklonyayet lyuboj ostavshijsya marker v zaprose ili otchyote, krome bukvaljnogo sovpadeniya vnutri doslovnogo `## Текст запроса`. Podrazdel pryamyikh proverok dopolniteljno ogranichen rovno odnoj otkryitoj paroj `FUM-CHECK-RUNS:BEGIN` i `FUM-CHECK-RUNS:END`: [avtomatizaciya otchyotov o zapuskakh proverok](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) zamenyayet toljko etot upravlyayemyij blok i ne perepisyivayet ostaljnoj otchyot.

Komanda `start` prinimayet toljko nepustoj massiv nepustyikh soobsjhenij, kanonicheskij lowercase UUID kornevogo seansa, sessionnuyu metku iz dopustimyikh simvolov, nachinayusjhuyusya s russkogo infinitiva, i tochnyij zagolovok, vosproizvodimo vyivedennyij iz etoj metki. Komanda `validate` proveryayet dejstvuyusjhij kontrakt oboikh khranimyikh shablonov vmeste so strukturoj repozitoriya. Ona ne trebuyet, chtobyi zavershyonnyiye istoricheskiye dokumentyi sovpadali s tekusjhim karkasom. Avtonomnyiye testyi chitayut te zhe fajlyi, podtverzhdayut fakticheskoye vliyaniye ikh soderzhimogo na generaciyu, otkaz do zapisi pri povrezhdenii i sovmestimostj rezuljtata s nezavisimyimi proverkami svyaznosti rabochej sessii.

## Komandyi

Vse komandyi zapuskayutsya iz kornya checkout:

```bash
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py plan --repo-root .
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py apply --repo-root .
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py validate --repo-root .
git show HEAD:Журнал/README.md | python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py reindex --repo-root . --baseline-markdown -
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py repair-plan --repo-root . --base-revision <точный-full-commit-OID>
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py repair --repo-root . --base-revision <точный-full-commit-OID>
```

- `plan` toljko chitayet checkout i vyivodit versionnyij JSON-plan s otnositeljnyimi putyami. Odinakovyiye derevjya v raznyikh klonakh dayut odinakovyij plan.
- `apply` stroit tot zhe plan, zaraneye gotovit vse novyiye bajtyi, atomarno ustanavlivayet fajlyi i pri lyubom sboye vosstanavlivayet bajtyi, rezhimyi fajlov i sostoyaniye indeksa.
- `validate` zakryito otklonyayet nevernyiye imena, simvolicheskiye ssyilki, kollizii, sirotskiye otchyotyi, nepolnyij indeks, aktivnyiye ssyilki na prezhnyuyu strukturu i povrezhdeniye kanonicheskikh shablonov.
- `reindex` peresobirayet toljko razdel indeksa, ne menyaya ostaljnoj `README.md`. Podannyij cherez `--baseline-markdown -` prezhnij Markdown sluzhit istochnikom kurirovannyikh strok; ssyilka kazhdoj stroki privoditsya k `отчёт.md` libo `запрос.md` po fakticheskomu sostavu papki. Povtor idempotenten.
- `start` do pervoj zapisi proveryayet kanonicheskiye stem, metku, proizvodnyij zagolovok, UUID seansa, nepustoj massiv soobsjhenij i sami shablonyi, zatem zapolnyayet ikh, atomarno sozdayot `запрос.md` i `отчёт.md`, obnovlyayet navigaciyu predyidusjhego zaprosa i indeks. Podpisj kazhdogo soseda beryotsya iz yego fakticheskogo H1, a ne vosstanavlivayetsya iz slug. Povtor s temi zhe bajtami idempotenten; drugoye soderzhaniye susjhestvuyusjhej papki yavlyayetsya konfliktom.
- `repair-plan` po tochnomu polnomu commit OID vosstanavlivayet staryij inventarj i iskhodnyij plan vo vremennom izolirovannom Git-snimke. On ne menyayet checkout, index, refs ili vneshneye sostoyaniye; vyivod soderzhit tochnyiye before/after SHA-256 zatragivayemyikh fajlov.
- `repair` atomarno primenyayet tot zhe dokazateljnyij repair. On zamenyayet toljko te celi semantic Markdown-ssyilok, dlya kotoryikh staroye znacheniye i ozhidayemaya novaya baza dokazanyi snimkom, i privodit podpisi navigacii k kanonicheskim. Identichnostj ssyilki zadayotsya yeyo strochnyim kontekstom bez destination i poryadkom vkhozhdeniya: odinakovaya stroka puti v dvukh raznyikh ssyilkakh ne dayot prava smeshivatj ikh celi. Vesj `## Текст запроса` ostayotsya bajtovo neizmennyim; povtor idempotenten.

Primer starta; JSON-massiv v stdin khranit kazhdoye soobsjheniye poljzovatelya doslovno:

```bash
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py start \
  --repo-root . \
  --session-stem 2026-08-03_12-00-00_MSK_создать-краткую-запись \
  --label создать-краткую-запись \
  --title 'Создать краткую запись' \
  --codex-thread-id 00000000-0000-0000-0000-000000000000 \
  --messages-json -
```

## Granicyi perenosa

Artefakt perenositsya toljko pri rovno odnom dokazannom vladeljce. Dlya revjyu i ocenok dokazateljstvom sluzhit yavnaya ssyilka `request_file` ili Markdown-ssyilka. Paket istochnika trebuyet dvustoronnyuyu ssyilku mezhdu paketom i zaprosom. Sovpadeniye imeni ili vremeni ne schitayetsya vladeniyem. `Источники/URL/` i obsjhiye tematicheskiye materialyi ne perenosyatsya.

V `## Текст запроса` bajtyi ne menyayutsya. Syiryiye URL-snimki i ne-Markdown payload-fajlyi istochnika ne perepisyivayutsya. `Источники/URL/**/source-index.md` yavlyayetsya metadannyimi, poetomu v nyom perebaziruyutsya toljko semantic-ssyilki; sosedniye `response.body.*` ostayutsya bajtovo neizmennyimi. V Markdown-metadannyikh perenosimogo paketa, vklyuchaya appshot-kontekst i otchyot ob izvlechenii, perebaziruyutsya toljko celi semantic-ssyilok; ostaljnoj tekst sokhranyayetsya. Ssyilki s inline-code v podpisi uchityivayutsya naravne s ostaljnyimi. V JSON menyayutsya toljko dokazanno aktivnyiye `request_file`, `report_file`, `config_file`, `exceptions[].path` mashinnoj politiki i `provenance_refs` zhivogo kontura. Istoricheskiye `checks[].command`, obyyektyi s zakreplyonnyim `git:commit` i khyesh-svyazannyiye neizmenyayemyiye paketyi sokhranyayutsya.

Plan dayot perenosimuyu osnovu dlya budusjhego vyiravnivaniya vetok i forkov, no sam navyik ne vyipolnyayet fetch, merge, rebase, commit ili push.

## Proverki avtomatizacii

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-struktura-papok-zaprosov/tests -p 'test_*.py'
```

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-04 20:45:26 MSK - Formirovatj otchyotyi o zapuskakh testov](../../Zhurnal/2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 15:48:19 MSK - Shablonizirovatj fajlyi zaprosov i otchyotov](../../Zhurnal/2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 23:50:44 MSK -->
<!-- content-sha256: sha256:024d3003265aa07a682b8c4c702a2f3c59f33a832e54ceddba9183d84aa580c4 -->
<!-- FUM-MD-RECENCY:END -->
