---
name: fum-kompleksnaya-proverka-repozitoriya
description: Zapuskatj standartnyij lokaljnyij smoke-check dokumentacionnogo prototipa FUM po polozhiteljnomu perechnyu i, toljko po yavnomu vyiboru, polnyij repozitornyij profilj s avtopoiskom testov, SwiftPM, sborkami i lint.
---

# FUM Smoke Check

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) razdelyayet dve raznyiye priyomochnyiye zadachi. Standartnyij profilj `документационный`, vyibrannyij po umolchaniyu, byistro podtverzhdayet rabotosposobnostj nablyudayemogo dokumentacionnogo prototipa pered obyichnyim kommitom. Yavnyij profilj `полный` sokhranyayet prezhnij shirokij repozitornyij kontur dlya celevoj regressii avtomatizacij, Git-zavisimosti i korobochnyikh SwiftPM-prototipov, no nikogda ne zapuskayetsya avtomaticheski vmesto standartnogo.

Oba profilya rabotayut lokaljno, ne trebuyut sekretov, setevyikh zaprosov i vneshnikh servisov i izmeryayut monotonnoye wall-clock-vremya podgotovki, kazhdogo obyyavlennogo shaga i polnogo processa. Standartnyij profilj stroitsya neposredstvenno iz polozhiteljnogo perechnya: odinnadcatj live-proverok i trinadcatj avtonomnyikh naborov yadra — 24 shaga s proverkoj sessii i 23 s `--skip-session-coherence`. Lyogkij live-shag dekompozicii pravil neobkhodim dokumentacionnomu prototipu, potomu chto proveryayet vsegda zagruzhayemyij korenj i obyazateljnostj tematicheskikh marshrutov; avtonomnyiye testyi etoj avtomatizacii ostayutsya toljko v polnom profile. Standart ne vyipolnyayet obsjhij avtopoisk `Инструменты/*/tests`, shirokij `dump-package`, SwiftPM-testyi, sborki i lint prototipov i ne zagruzhayet istoriyu riska. Primeneniye proyekcii pri etom trebuyet lokaljnyiye Swift 5.9+ i materializovannyij tochnyij LinguisticKit i zapuskayet izolirovannuyu sluzhebnuyu Swift-obyortku. Novyij nabor testov ne popadayet v standart sam soboj: izmeneniye perechnya trebuyet osmyislennoj pravki i regressionnogo testa sostava.

Nulevoj kod vnutrennego proverochnogo processa oznachayet toljko, chto obyyavlennyij proverochnyij plan projden. Sam `run-smoke-check.py` ne vyipolnyayet Git-kommit: posle yego vyikhoda obyazateljnaya otchyotnaya obyortka yesjhyo sokhranyayet terminaljnuyu zapisj zapuska i zakryivayet khyeshirovannyij snimok. Zatem vyipolnyayutsya rovno odna finaljnaya peresborka `Proyekcii/**`, odin pryamoj nezavisimyij validator, tochnaya postanovka pokoleniya v indeks i ogranichennyiye proverki zamyikaniya. Polnaya ruchnaya sessiya s osmyislennyim diff schitayetsya zavershyonnoj toljko posle odnogo itogovogo lokaljnogo kommita na `refs/heads/master`; smoke-check ne sozdayot continuation, FIFO-handoff ili publikaciyu.

## Kogda ispoljzovatj

Ispoljzuj standartnyij profilj, kogda nuzhno:

- vyipolnitj obyazateljnyij priyomochnyij progon dokumentacionnoj rabochej sessii pered lokaljnyim kommitom;
- ubeditjsya, chto `.codex/config.toml` sokhranyayet `skills.include_instructions = false` i ne vozvrasjhayet vneshnij katalog navyikov v agentskij kontekst;
- proveritj, chto zaprosyi nakhodyatsya v `Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_slug]>/запрос.md`, otchyotyi lezhat ryadom, a starogo `Запросы/` i verkhneurovnevyikh zhurnaljnyikh otchyotov net;
- peresobratj i sveritj planovyij reyestr;
- polnostjyu peresobratj bratislavskuyu proyekciyu posle kanonicheskikh generatorov i nezavisimo proveritj yeyo manifest s bajtami;
- proveritj dejstvuyusjheye soderzhimoye na mashinno-lokaljnyiye puti i raskryitiye Swift `#filePath`;
- proveritj kompaktnostj kornevoj instrukcii i polnotu tematicheskogo indeksa v `Документация/README.md`;
- proveritj susjhestvovaniye, registr i obratnyiye ssyilki zayavlennyikh celej otkryityikh i chastichno proyasnyonnyikh voprosov;
- ubeditjsya, chto `FUM-MD-RECENCY` i indeks Markdown-fajlov svezhiye;
- proveritj svyaznostj vyibrannogo fajla `Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md`.

Vyibiraj polnyij profilj otdeljno, kogda izmenyon neobyazateljnyij instrument, Git-zavisimostj, Swift-kod ili politika paketov libo kogda nuzhen shirokij audit vsekh sokhranyonnyikh regressij. On avtomaticheski obnaruzhivayet vse Python-naboryi, proveryayet ostatok perevoda obyyavlenij i reyestr nazvanij avtomatizacij, razbirayet vse SwiftPM-manifestyi i vyipolnyayet Swift-testyi, sborki produktov i lint.

## Komanda zapuska

Standartnyij proverochnyij etap rabochej sessii:

```bash
python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --commit-message-file <путь-к-файлу-сообщения> \
  --codex-thread-id <корневой-CODEX_THREAD_ID>
```

Dlya zaprosov s imenem roditeljskoj papki nachinaya s `2026-07-14_02-31-47_MSK_добавлять-идентификатор-сеанса-Codex` oba novyikh parametra obyazateljnyi; istoricheskiye zaprosyi mozhno proveryatj bez nikh. Spisok standartnyikh proverochnyikh komand bez ikh zapuska:

```bash
python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --list
```

Standartnyij `--list` ne vyizyivayet Swift, avtopoisk testov ili chteniye analiticheskoj istorii. Polnyij profilj i yego spisok vyibirayutsya toljko yavno:

```bash
python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --commit-message-file <путь-к-файлу-сообщения> \
  --codex-thread-id <корневой-CODEX_THREAD_ID> \
  --профиль полный
```

Dlya prosmotra polnogo plana dobavlyayetsya `--list`. Toljko v etom sochetanii `Package.swift` ocenivayutsya lokaljnyim `swift package dump-package` s offline-flagami; testyi, sborka i lint pri prosmotre ne zapuskayutsya.

Chastichnyij lokaljnyij zapusk bez proverki konkretnoj rabochej sessii:

```bash
python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py \
  --skip-session-coherence
```

## Chto zapuskayetsya

Standartnyij profilj vyipolnyayet dve fazyi. Snachala idut odinnadcatj live-proverok v tochnom poryadke: struktura papok zaprosov; otdeljnyiye sborka i proverka planovogo reyestra; primeneniye i nezavisimaya proverka bratislavskoj proyekcii; mashinno-lokaljnyiye puti; dekompoziciya pravil agentov; dvunapravlennostj voprosov; tematicheskij indeks README; Markdown-recency; svyaznostj sessii. Zatem po kanonicheskomu POSIX-klyuchu sleduyut trinadcatj yavno razreshyonnyikh naborov:

- `fum-bratislavskaya-proyekciya-pamyati`;
- `fum-indeks-readme`;
- `fum-kompleksnaya-proverka-repozitoriya`;
- `fum-materialyi-zaprosov`;
- `fum-moskovskoye-vremya-rabochej-sessii`;
- `fum-obratnyiye-ssyilki-voprosov`;
- `fum-otchyotyi-o-zapuskakh-proverok`;
- `fum-proverka-mashinno-lokaljnyikh-putej`;
- `fum-proyektnyiye-fajlyi`;
- `fum-reyestr-planirovaniya`;
- `fum-struktura-papok-zaprosov`;
- `fum-svezhestj-markdown`;
- `fum-svyaznostj-rabochej-sessii`.

Kazhdyij katalog obyazan susjhestvovatj vnutri checkout kak obyichnyij lokaljnyij katalog i soderzhatj khotya byi odin obyichnyij `test_*.py`. Otsutstviye, pustoj nabor ili podmena simvolicheskoj ssyilkoj ostanavlivayut podgotovku. Lokaljnyij ignored `.obsidian/graph.json` i istoricheskij generator yego teplovoj kartyi ne trebuyutsya standartnomu profilyu.

Polnyij profilj sokhranyayet chetyire prezhniye fazyi: Swift-razbor i zagruzka zakryitoj istorii; rasshirennyij rannij prefiks; risk-uporyadochennyiye avtomaticheski najdennyiye Python- i Swift-testyi; fiksirovannyij khvost sborok i lint. Statistika polnogo profilya chitayetsya toljko iz zapisej s nablyudeniyami `fum.test-run.v2` i `fum.test-run.v3`, vkhodyasjhikh v polnostjyu proverennyiye zakryityiye snimki `fum.test-run-report.v1` ili `fum.test-run-report.v2`. Otkryityiye sessii i istoricheskiye v1-zapisi nablyudenij ne dayut; podgotovlennyij, vosstanavlivayemyij ili povrezhdyonnyij zhurnal zakryivayet podgotovku otkazom. Standartnyij profilj istoriyu ne chitayet, poetomu staryij povrezhdyonnyij snimok ne prevrasjhayet byistryij dokumentacionnyij progon v skryituyu shirokuyu proverku.

Nizhe komandyi perechislenyi po vidam proverok dlya spravki. Avtopoisk, SwiftPM-testyi, sborki i lint otnosyatsya toljko k yavnomu polnomu profilyu; dve komandyi proyekcii vkhodyat v standart i vnutri svoyej zakryitoj granicyi vyizyivayut izolirovannuyu Swift-obyortku LinguisticKit.

Pri zapuske lyubogo profilya cherez obyazateljnuyu obyortku otchyotov snachala sozdayotsya kanonicheskij konvert `fum.smoke-test-observations.v1` s UUID i `план: null`. Do ispolneniya pervogo rannego shaga smoke-check atomarno dobavlyayet tochnyij uporyadochennyij plan analiticheskikh testov vyibrannogo profilya. Yesli rannyaya proverka otkazyivayet, tekusjhaya terminaljnaya v3-zapisj sokhranyayet plan i pustyiye nablyudeniya: eto dopustimyij fail-fast do pervogo testa. Pered kazhdyim dostignutyim testom sokhranyayetsya tekusjhij shag, a posle iskhoda — fakticheskij prefiks. Obyortka proveryayet kanonichnostj klyuchej, polnotu uspeshnogo plana, yedinstvennyij poslednij neuspekh pri fail-fast i soglasovannostj dliteljnostej. Pri tajm-aute dostignutyij tekusjhij test dobavlyayetsya kak `не завершено`, pri vneshnem signale — kak `прервано`. Plan, nablyudeniya i shestipolevoj profilj proverki khyeshiruyemo vstraivayutsya v v3-zapisj; istoricheskaya v2 ostayotsya chitayemoj. Peremennyiye capability udalyayutsya iz okruzheniya kazhdogo vlozhennogo shaga.

Pered postroyeniyem spiska shagov avtomatizaciya razbirayet `.codex/config.toml` standartnyim TOML-parserom i trebuyet tochnoye logicheskoye znacheniye `skills.include_instructions = false`. Zatem ona razreshayet simvolicheskiye ssyilki kazhdogo `Инструменты/*/SKILL.md` i otklonyayet putj, vyishedshij za korenj checkout. Otsutstvuyusjhij, sintaksicheski nevernyij ili oslablennyij proyektnyij konfig, slomannaya ssyilka i vneshnij putj ostanavlivayut kak obyichnyij zapusk, tak i rezhim `--list` do ostaljnyikh proverok. Eta staticheskaya proverka zasjhisjhayet sokhrannostj proyektnogo kontrakta, no ne obesjhayet povedeniye neizvestnoj budusjhej versii Codex ili zapuska s yavnyim pereopredeleniyem nastrojki; primenimostj tekusjhikh runtime otdeljno proveryayetsya cherez ikh modeljnyij vkhod.

Obyichnyij zapusk pechatayet mashinochitayemyiye stroki `smoke-timing <JSON>`. Zapisi `manifest` poyavlyayutsya toljko v polnom profile i izmeryayut kazhdyij vyizov `swift package dump-package`; `preparation` okhvatyivayet podgotovku spiska, `step` — obyyavlennyij shag, a `total` — polnyij interval. Nevozmozhnostj zapustitj vlozhennyij process stabiljno oboznachayetsya `exit_code: 127`, a oshibka podgotovki zavershayet smoke-check s kodom `2`. Vlozhennyiye dliteljnosti ne skladyivayutsya s `total` kak nezavisimyiye vyizovyi. Rezhim `--list` ne zapuskayet obyyavlennyiye shagi; standartnyij spisok ne vyipolnyayet Swift-podgotovku, polnyij — vyipolnyayet toljko razbor manifestov.

1. Toljko v polnom profile nakhodit vse katalogi `Инструменты/*/tests`, soderzhasjhiye `test_*.py`, i zapuskayet dlya kazhdogo:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s <tests-dir> -p 'test_*.py'
```

2. Toljko v polnom profile nakhodit vse `Прототипы/*/Package.swift`, poluchayet fakticheskiye produktyi i puti celej cherez:

```bash
swift package \
  --package-path <путь-к-пакету> \
  --disable-dependency-cache \
  --manifest-cache none \
  --disable-prefetching \
  --disable-netrc \
  --disable-keychain \
  --disable-automatic-resolution \
  dump-package
```

Dlya kazhdogo paketa avtomatizaciya zapuskayet avtonomnyiye testyi:

```bash
swift test \
  --package-path <путь-к-пакету> \
  --disable-dependency-cache \
  --manifest-cache none \
  --disable-prefetching \
  --disable-netrc \
  --disable-keychain \
  --disable-automatic-resolution
```

Kazhdyij obyyavlennyij ispolnyayemyij produkt sobirayetsya otdeljno:

```bash
swift build \
  --package-path <путь-к-пакету> \
  --disable-dependency-cache \
  --manifest-cache none \
  --disable-prefetching \
  --disable-netrc \
  --disable-keychain \
  --disable-automatic-resolution \
  --product <имя-продукта>
```

Po umolchaniyu vse puti celej i `Package.swift` prokhodyat strogij lint:

```bash
swift format lint \
  --configuration Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-format.json \
  --strict \
  --recursive \
  <путь-к-пакету>/Package.swift \
  <пути-целей>
```

Centraljnaya [konfiguraciya formattera](swift-format.json) fiksiruyet nabor pravil i parametrov vmesto zavisimosti ot neyavnogo fajla sredyi. Fajlyi `.swift-format-ignore` zapresjhenyi vo vsej primenimoj iyerarkhii, potomu chto oni mogut molcha isklyuchitj yavno peredannyij Swift-fajl dazhe iz strogogo lint.

Pravilo `IdentifiersMustBeASCII` yavno otklyucheno, chtobyi strogij lint razreshal kirillicheskiye Swift-identifikatoryi. Ispolnitelj po-prezhnemu peredayot `--strict`; ostaljnyiye pravila centraljnoj konfiguracii ne oslablyayutsya.

[Politika SwiftPM-paketov](swift-package-policy.json) skhemyi `2` khranit ozhidayemyij inventarj paketov, ispolnyayemyikh produktov i tochnyij allowlist pryamyikh lokaljnyikh package- i product-svyazej. Ischeznuvshij paket ili produkt, novyij nezaregistrirovannyij paket i nesovpadeniye s fakticheskim `dump-package` ostanavlivayut smoke-check. Paket bez zavisimostej obyazan yavno khranitj `"localDependencies": []`: prezhnyaya strogaya granica dlya nego ne oslablyayetsya.

Minimaljnaya razreshyonnaya kompoziciya vyiglyadit tak:

```json
{
  "schemaVersion": 2,
  "defaultMode": "strict",
  "packages": [
    {
      "package": "Прототипы/consumer",
      "executableProducts": ["ConsumerCLI"],
      "localDependencies": [
        {
          "package": "Прототипы/provider",
          "identity": "provider",
          "products": [
            {
              "target": "ConsumerCLI",
              "product": "ProviderLibrary"
            }
          ]
        }
      ]
    },
    {
      "package": "Прототипы/provider",
      "executableProducts": ["ProviderCLI"],
      "localDependencies": []
    }
  ],
  "exceptions": []
}
```

`package` vsegda yavlyayetsya kanonicheskim repo-relative-putyom rovno k odnomu sosednemu verkhneurovnevomu paketu `Прототипы/<имя>`. `identity` sovpadayet s fakticheskoj package identity iz `dump-package`. Kazhdyij element `products` zadayot tochnuyu svyazj potreblyayusjhej celi `target` s bibliotechnyim produktom `product` provajdera; lishnyaya, ischeznuvshaya ili pereimenovannaya svyazj schitayetsya drejfom. Zavisimostj v `Package.swift` zapisyivayetsya yedinstvennoj perenosimoj literaljnoj formoj `.package(path: "../provider")`. Imenovannyiye, vyichislyayemyiye, absolyutnyiye, nekanonicheskiye i dopolniteljnyiye argumentyi ne dopuskayutsya.

Chtobyi staticheskaya granica ne raskhodilasj s itogovyim obyyektom SwiftPM, manifest ogranichen deklarativnoj formoj: posle direktivyi tools version razreshyon toljko `import PackageDescription`, zatem rovno odin `let package = Package(...)` i nikakogo koda posle zakryivayusjhej skobki. Pole `dependencies:` samogo etogo inicializatora yavlyayetsya literaljnyim massivom razreshyonnyikh vyizovov. Vspomogateljnaya fabrika, alias, backtick-vyizov, neispoljzuyemyij allowlist-marker i posleduyusjhaya mutaciya `package.dependencies` zakryivayutsya otkazom.

SwiftPM neizbezhno vozvrasjhayet `fileSystem.path` absolyutnyim. Smoke-check raskryivayet simvolicheskiye ssyilki, vyipolnyayet `realpath`-proverku susjhestvovaniya i nakhozhdeniya vnutri kornya repozitoriya i `Прототипы/`, posle chego normalizuyet putj obratno v tochnyij repo-relative-vid i sopostavlyayet yego s politikoj i iskhodnyim literalom. Vyikhod za lyubuyu granicu, self-dependency, povtor package path ili identity, povtor product-svyazi i cikl zakryivayutsya otkazom. Tak zhe do testov i sborki otklonyayutsya source-control-, registry-, neizvestnyiye i binary-zavisimosti, neodnoznachnaya vneshnyaya `byName`-svyazj, uslovnaya product-svyazj i product, kotoryij provajder fakticheski ne eksportiruyet kak biblioteku.

Chtobyi dobavitj zavisimostj:

1. Zaregistriruj potrebitelya i provajdera v `packages`; dlya ostaljnyikh paketov sokhrani pustyiye allowlist.
2. Dobavj potrebitelyu kanonicheskij `.package(path: "../<сосед>")` i yavnuyu `.product(name: ..., package: ...)` v konkretnuyu celj.
3. V `localDependencies` zafiksiruj repo-relative-putj provajdera, identity iz svezhego lokaljnogo `dump-package` i vse tochnyiye paryi `target`/`product`.
4. Zapusti testyi avtomatizacii, zatem yavnyij profilj `--профиль полный`. Ne dobavlyaj razresheniye radi uzhe nablyudayemogo drejfa: snachala proverj proiskhozhdeniye izmenivshejsya identity ili svyazi.

Offline-flagi odinakovo primenyayutsya k `dump-package`, `swift test` i `swift build`. Kontur ne zagruzhayet zavisimosti i ne ispoljzuyet poljzovateljskiye credential- i dependency-kyeshi; lokaljnyij putj yavlyayetsya yedinstvennyim razreshyonnyim transportom mezhdu paketami.

Yesli vremennoye lint-isklyucheniye neobkhodimo, ono obyazano soderzhatj prichinu, kriterij snyatiya, susjhestvuyusjhij istochnik i SHA-256 centraljnoj konfiguracii, `Package.swift` i Swift-fajlov celej. Isklyucheniye pechatayetsya v polnom zapuske i yego `--list`; lyuboye izmeneniye zasjhisjhyonnogo snimka ostanavlivayet polnyij profilj kak ustarevshaya politika. Tekusjhaya politika ne soderzhit isklyuchenij.

3. Proveryayet strukturu papok zaprosov i kontrakt ikh kanonicheskikh shablonov:

```bash
python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py \
  validate \
  --repo-root .
```

Proverka trebuyet obyazateljnyij vremennoj prefiks imeni roditeljskoj papki i `запрос.md`, dopuskayet `материалы/`, zapresjhayet prezhnij `Запросы/` i razreshayet neposredstvenno v `Журнал/` toljko `README.md` sredi Markdown-fajlov. Dlya novoj rabochej sessii obyazatelen sosednij `отчёт.md`; istoricheskaya papka mozhet ostavatjsya bez nego toljko pri otsutstvii otchyota do migracii. Tem zhe vyizovom zakryito proveryayutsya tochnyiye polya, aktivnyij karkas, obyazateljnyiye razdelyi, poryadok zagolovkov i vyiravnivaniye tablic khranimyikh shablonov `запрос.md.шаблон` i `отчёт.md.шаблон`; avtopoisk testov otdeljno podtverzhdayet generaciyu po etim fajlam, otkaz pri nezapolnennom markere i nezavisimuyu validaciyu rezuljtata.

4. Peresobirayet mashinno chitayemyij planovyij reyestr:

```bash
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py build \
  --output Планирование/реестр-требований-вариантов-и-кандидатов.json
```

5. Proveryayet svezhestj planovogo reyestra:

```bash
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py validate \
  --registry Планирование/реестр-требований-вариантов-и-кандидатов.json
```

6. Polnostjyu peresobirayet i atomarno ustanavlivayet bratislavskuyu proyekciyu iz uzhe obnovlyonnogo kanonicheskogo sloya:

```bash
python3 Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py применить \
  --корень-репозитория . \
  --контракт Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json
```

7. Nezavisimo vyivodit ozhidayemyiye bajtyi i proveryayet ustanovlennoye pokoleniye:

```bash
python3 Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py проверить-манифест \
  --корень-репозитория . \
  --контракт Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json \
  --манифест Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json
```

8. Toljko v polnom profile proveryayet reyestr nazvanij avtomatizacij:

```bash
python3 Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py \
  --repo-root . \
  --registry Инструменты/реестр-названий-автоматизаций.json
```

Kanonicheskij reyestr nakhoditsya v sostoyanii `ready`, poetomu polnyij profilj trebuyet materializovannyij paket i zhivoj vyizov LinguisticKit. Posle svezhego klonirovaniya snachala nuzhno [inicializirovatj submodule i lokaljnyij `upstream`](../../Zavisimosti/README.md); perevod reyestra v `blocked` ne yavlyayetsya dopustimyim obkhodom etoj operacii.

9. Proveryayet soderzhimoye na mashinno-lokaljnyiye puti:

```bash
python3 Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/proveritj-mashinno-lokaljnyiye-puti.py \
  --repo-root .
```

Proverka ispoljzuyet Git-inventarj, pechatayet stabiljnyiye obezlichennyiye kategorii i otlichayet dejstvuyusjhiye narusheniya ot tipizirovannyikh sistemnyikh, testovyikh, istoricheskikh i vneshnikh sluchayev. Oba profilya ostanavlivayutsya na lyuboj novoj first-party-regressii.

10. Toljko v polnom profile proveryayet perevod first-party obyyavlenij koda srazu posle skanera mashinno-lokaljnyikh putej:

```bash
python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py \
  проверить \
  --корень-репозитория . \
  --снимок Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/остаток-объявлений-кода.json
```

Snimok khranit tochnyij vremennyij ostatok yesjhyo ne perevedyonnyikh obyyavlenij na moment poetapnoj migracii. On ne yavlyayetsya obsjhim allowlist ili postoyannyim isklyucheniyem: lyuboye novoye neperevedyonnoye obyyavleniye ili rasshireniye ostatka ostanavlivayet smoke-check. Po mere perevoda snimok osmyislenno sokrasjhayut vmeste s kodom; yego rost zapresjhyon.

11. Toljko v polnom profile avtonomno proveryayet Git-topologiyu podklyuchyonnogo LinguisticKit:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py check \
  --repo-root . \
  --fork-url https://github.com/fum-lab/LinguisticKit.git \
  --upstream-url https://github.com/Roman-Kerimov/LinguisticKit.git \
  --path Зависимости/LinguisticKit \
  --revision 837e2ce107b97ee7b9d3344c9fe99142281fe393
```

12. Toljko v polnom profile proveryayet obyazateljnyiye tochki vkhoda vsekh ustojchivyikh prototipov:

```bash
python3 Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py
```

13. Proveryayet dvunapravlennostj otkryityikh i chastichno proyasnyonnyikh voprosov:

```bash
python3 Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py
```

14. Proveryayet kornevuyu instrukciyu i otdeljnyij tematicheskij indeks dokumentacii:

```bash
python3 Инструменты/fum-indeks-readme/scripts/check-readme-index.py \
  --repo-root .
```

15. Proveryayet recency-metki bez zapisi:

```bash
python3 Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py --check
```

16. Istoricheski proveryal teplovuyu kartu grafa Obsidian bez zapisi:

```bash
python3 Инструменты/fum-svezhestj-grafa-obsidian/scripts/build-obsidian-graph-recency.py \
  --check
```

Posle perekhoda na `manual-sequential-v1` etot shag isklyuchyon iz smoke-check: `.obsidian/graph.json` yavlyayetsya ignored poljzovateljskim sostoyaniyem. Komanda sokhranena kak otdeljnaya ruchnaya utilita i testovaya fikstura; opornaya data teplovoj kartyi ne menyayetsya avtomaticheski.

17. Proveryayet svyaznostj vyibrannoj rabochej sessii:

```bash
python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --commit-message-file <путь-к-файлу-сообщения> \
  --codex-thread-id <корневой-CODEX_THREAD_ID>
```

## Proverki avtomatizacii

Lokaljnyiye testyi samoj avtomatizacii zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-kompleksnaya-proverka-repozitoriya/tests -p 'test_*.py'
```

Testyi snachala fiksiruyut profiljnuyu granicu: po umolchaniyu vyibirayetsya `документационный`, yego sostav i poryadok ravnyi tochnomu polozhiteljnomu perechnyu, vklyuchaya tochnyiye argumentyi posledovateljnyikh `применить` i `проверить-манифест`, lishnij katalog testov ignoriruyetsya, a otsutstvuyusjhij, pustoj ili vyinesennyij simvolicheskoj ssyilkoj razreshyonnyij nabor zakryivayet podgotovku otkazom. Standartnyij `--list` ne vyizyivayet avtopoisk, Swift-kontur i istoriyu; `--профиль полный --list` sokhranyayet prezhnij razbor manifestov i pokazyivayet vse tyazhyolyiye komandyi bez ikh ispolneniya. Polnyij profilj sokhranyayet prezhnij avtopoisk, risk-sortirovku i fiksirovannyij Swift-khvost.

Ostaljnoj nabor fiksiruyet bazovyij kontrakt: smoke-check trebuyet otklyuchyonnuyu peredachu obsjhego kataloga navyikov v proyektnoj konfiguracii, otklonyayet vyikhod lokaljnogo `SKILL.md` za korenj cherez simvolicheskuyu ssyilku, schitayet avarijnyij signal i nezavershivshijsya dostignutyij test oshibkoj, ne schitayet vneshneye preryivaniye oshibkoj, sokhranyayet toljko dostignutyij fail-fast-prefiks i ne peredayot capability-peremennyiye dochernim shagam. Polnoprofiljnyiye testyi sveryayut inventarj SwiftPM-paketov i produktov, `dump-package`, `swift test`, sborku kazhdogo ispolnyayemogo produkta, strogij lint i politiku lokaljnyikh zavisimostej. Obsjhiye testyi zakreplyayut strukturu zaprosov, planovyij reyestr, mashinno-lokaljnyiye puti, kornevuyu instrukciyu, indeks dokumentacii, voprosyi, recency i svyaznostj sessii.

Regressiya skhemyi `2` sozdayot nastoyasjhuyu lokaljnuyu SwiftPM-kompoziciyu i proveryayet allowlist pryamyikh zavisimostej, normalizaciyu putej, sovpadeniye identity i product-svyazej, ciklyi i zapresjhyonnyiye vneshniye zavisimosti. Vnedryayemyij monotonnyij tajmer zakreplyayet stabiljnyiye zapisi dliteljnosti kazhdogo shaga i polnogo intervala pri uspekhe i oshibke. Otdeljnyij skvoznoj test sozdayot otslezhivayemuyu first-party-regressiyu i podtverzhdayet ostanovku ispolnitelya na skanere mashinno-lokaljnyikh putej.

## Granica avtomatizacii

Smoke-check ne zamenyayet smyislovuyu proverku izmenenij, publikacionnuyu chistotu diff i resheniye agenta o tom, kakiye fajlyi nuzhno kommititj. On obyyedinyayet lokaljnyiye strukturnyiye proverki i ostanavlivayetsya na pervom upavshem shage, chtobyi oshibka ostavalasj nablyudayemoj i ne maskirovalasj sleduyusjhimi komandami.

Pryamoj nulevoj vyikhod etoj komandyi neljzya soobsjhatj kak zavershyonnyij uspekh smoke-sessii. Kornevaya zadacha snachala zamyikayet zhurnaljnyiye dokazateljstva bez povtornogo polnogo progona, odin raz peresobirayet i napryamuyu validiruyet okonchateljnuyu `Proyekcii/**`, tochno indeksiruyet proverennoye sostoyaniye i sozdayot odin itogovyij lokaljnyij kommit na `refs/heads/master`. Lyubaya posleduyusjhaya kanonicheskaya mutaciya vozvrasjhayet rabotu do finaljnogo smoke. Perekhodnaya sessiya, vpervyiye vvodyasjhaya `manual-sequential-v1`, zavershayet etot yedinstvennyij kommit prezhnim atomarnyim protokolom k chisto zavershayusjhemu mostu; posleduyusjhiye sessii ocheredj i selector ne vyizyivayut.

Yesli vo vremya vyipolnyayusjhegosya smoke-check obnaruzhen uzhe podtverzhdyonnyij defekt, delayusjhij proveryayemyij snimok zavedomo neprinimayemyim, kornevoj agent nemedlenno preryivayet dochernij process shtatnyim signalom. Obyazateljnaya obyortka otchyotov sokhranyayet iskhod `прервано`; posle ispravleniya zanovo zapuskayetsya tot zhe vyibrannyij profilj, i imenno novyij uspeshnyij progon stanovitsya priyomochnyim.

Yesli v repozitorii poyavlyayetsya novyij proveryayemyij reyestr, yego dobavlyayut v standart toljko pri dokazannoj neobkhodimosti dokumentacionnomu prototipu i zakreplyayut ozhidaniye testom. Novyij `Инструменты/<имя>/tests` avtomaticheski vkhodit lishj v polnyij profilj; dlya standartnogo trebuyetsya otdeljnoye obosnovannoye izmeneniye polozhiteljnogo perechnya.

Obnaruzheniye SwiftPM namerenno ogranicheno ustojchivyimi prototipami vida `Прототипы/<имя>/Package.swift`, poetomu kyeshi `.build`, `.swiftpm` i paketyi tranzitivnyikh zavisimostej ne stanovyatsya samostoyateljnyimi vkhodami smoke-check. Razreshayutsya toljko pryamyiye lokaljnyiye svyazi mezhdu zaregistrirovannyimi sosednimi paketami; tranzitivnaya dostizhimostj ne zamenyayet allowlist pryamoj svyazi. Lokaljnaya sluzhebnaya obyortka ispoljzuyet LinguisticKit toljko cherez otdeljno proveryayemyij Git submodule. Rezuljtat `dump-package` zavisit ot lokaljnogo Swift toolchain i platformyi, poetomu neizvestnaya struktura manifesta ili otsutstviye ispolnyayemogo produkta schitayetsya oshibkoj, a ne osnovaniyem tikho propustitj sborku.

Tekusjhij Swift-kontur prednaznachen dlya macOS: vse paketyi trebuyut macOS 14 ili noveye, Swift 6.0 ili noveye i Xcode s komandami `swift` i `swift format`, a sborki smoke-check yavlyayutsya otladochnyimi sborkami SwiftPM po umolchaniyu. Centraljnaya konfiguraciya ne soderzhit imyon pravil, otsutstvuyusjhikh v Swift 6.0, no boleye staryij formatter mozhet ignorirovatj neizvestnyiye yemu dopolniteljnyiye parametryi, poetomu identichnaya semantika lint mezhdu raznyimi versiyami toolchain ne obesjhayetsya. Prinyatyij snimok polnostjyu proveren na Swift 6.4 i Xcode 27.0; eto nablyudayemaya tekusjhaya sreda, a ne obesjhaniye binarnoj sovmestimosti so vsemi budusjhimi toolchain.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-14 18:59:37 MSK — Isklyuchitj dublirovaniye polnoj regressii](../../Zhurnal/2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)
- [iskhodnyij zapros realizacii FUM-STEP-0129](../../Zhurnal/2026-09-01_11-19-59_MSK_realizovatj-bratislavskuyu-proyekciyu-pamyati/zapros.md)

- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-08-08 07:56:16 MSK — Pochinitj avtozapusk FUM](../../Zhurnal/2026-08-08_07-56-16_MSK_pochinitj-avtozapusk-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-06 20:56:43 MSK — Optimizirovatj rabotu testov](../../Zhurnal/2026-08-06_20-56-43_MSK_optimizirovatj-rabotu-testov/zapros.md)
- [iskhodnyij zapros 2026-08-06 15:14:50 MSK — Sdelatj README instrukciyej ispoljzovaniya FUM](../../Zhurnal/2026-08-06_15-14-50_MSK_sdelatj-README-instrukciyej-ispoljzovaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-06 11:22:33 MSK - Dobavitj analitiku poryadka zapuska testov](../../Zhurnal/2026-08-06_11-22-33_MSK_dobavitj-analitiku-poryadka-zapuska-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 15:48:19 MSK - Shablonizirovatj fajlyi zaprosov i otchyotov](../../Zhurnal/2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)
- [iskhodnyij zapros 2026-07-27 16:12:29 MSK - Uchityivatj vse proverochnyiye vyizovyi v profile vremeni](../../Zhurnal/2026-07-27_16-12-29_MSK_uchityivatj-vse-proverochnyiye-vyizovyi-v-profile-vremeni/zapros.md)
- [iskhodnyij zapros 2026-07-23 18:12:05 MSK - Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla](../../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-23 15:26:35 MSK - Zapretitj vneshniye navyiki v repozitorii](../../Zhurnal/2026-07-23_15-26-35_MSK_zapretitj-vneshniye-navyiki-v-repozitorii/zapros.md)
- [iskhodnyij zapros 2026-07-14 02:31:47 MSK - Dobavlyatj identifikator seansa Codex](../../Zhurnal/2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-17 12:20:17 MSK - Sozdatj skriptyi zapuska prototipov](../../Zhurnal/2026-07-17_12-20-17_MSK_sozdatj-skriptyi-zapuska-prototipov/zapros.md)
- [iskhodnyij zapros 2026-07-20 15:34:46 MSK - Vklyuchitj SwiftPM v obsjhij smoke check](../../Zhurnal/2026-07-20_15-34-46_MSK_vklyuchitj-SwiftPM-v-obsjhij-smoke-check/zapros.md)
- [iskhodnyij zapros 2026-07-20 23:08:44 MSK - Vosstanovitj obratnyiye ssyilki voprosov](../../Zhurnal/2026-07-20_23-08-44_MSK_vosstanovitj-obratnyiye-ssyilki-voprosov/zapros.md)
- [iskhodnyij zapros 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../../Zhurnal/2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-21 12:18:37 MSK - Zakrepitj transliteraciyu nazvanij avtomatizacij](../../Zhurnal/2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK — Aktualizirovatj fork i podklyuchitj LinguisticKit](../../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)
- [iskhodnyij zapros 2026-07-22 09:33:05 MSK - Snyatj lint isklyucheniye tenevogo redaktora prodolzhenij](../../Zhurnal/2026-07-22_09-33-05_MSK_snyatj-lint-isklyucheniye-tenevogo-redaktora-prodolzhenij/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)
- [kartochka shaga FUM-STEP-0070](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0070-ustranitj-mashinno-lokaljnyiye-absolyutnyiye-puti-i-dobavitj-ikh-avtomaticheskuyu-proverku.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 17:52:20 MSK -->
<!-- content-sha256: sha256:dfe03c7aac560cabe25b5aace35ba53d7475d8a8ade1e43beff06417cb781e1e -->
<!-- FUM-MD-RECENCY:END -->
