# Kompaktnyij otvet nativnoj zadachi

[Python-etalon](scripts/kompaktnyij_otvet_zadachi.py) prinimayet sokhranyonnuyu obolochku `read_thread`, proveryayet polnyij SHA-256, razbirayet vlozhennuyu stroku JSON i vyibirayet pervyij podkhodyasjhij khod `newest_first`, zatem poslednij nepustoj `agentMessage` v yego massive `items`. Vyibrannyij obyyekt sokhranyayetsya celikom. Srez soderzhit sostoyaniye, oshibku tekusjhego khoda, metadannyiye vyibrannogo khoda, schyotchiki opusjhennyikh elementov i dvukhstupenchatyiye ukazateli na originalyi. Komandyi i rassuzhdeniya ne ispolnyayutsya i ne peredayutsya kak otvet.

[CLI](scripts/pokazatj-otvet-zadachi.py) trebuyet `--снимок`, `--sha256` i `--задача`. Neobyazateljnyij `--путь-в-результате` dobavlyayet absolyutnyij adres privatnogo artefakta. `--максимум-байтов` po umolchaniyu raven 16000 i vklyuchayet adres i zavershayusjhij LF. Prevyisheniye byudzheta oznachayet kod 2 i pustoj stdout; tekst ne usekayetsya. CLI ne pishet i ne obrasjhayetsya k API ili Git.

[Obsjhaya obyortka](scripts/adapter_otveta.cjs) eksportiruyet `прочитать_кратко(среда, параметры)`. Sreda predostavlyayet `инструменты`, `загрузить` i `сохранить`; v `functions.exec` im sootvetstvuyut `tools`, `load` i `store`. Parametryi — fizicheskij `корень` checkout, `задача`, absolyutnyij `снимок`, `ключ_кэша`, `режим` i `максимум_байтов`. Dlya etoj transportnoj obyortki dopustimyi 100–16000 bajtov. Ona poluchayet nativnyij otvet vnutri vyizova, sokhranyayet polnyij JSON i peredayot naruzhu toljko rezuljtat CLI. Vyizyivatj `text()` sleduyet toljko dlya vozvrasjhyonnogo sreza ili korotkogo otkaza. Eto yavno vyizyivayemyij pomosjhnik; globaljnyij perekhvat instrumentov ne ustanovlen.

Rezhim `новый` snachala invalidiruyet predyidusjheye prinyatoye sostoyaniye, proveryayet novyij putj vne lyubogo Git-predka i bez simvolicheskikh ssyilok, zatem delayet odin zapros API i odnu zapisj polnogo snimka. Katalog dolzhen susjhestvovatj; susjhestvuyusjhij fajl otklonyayetsya. Privatnyij katalog vyibirayetsya vne Git, v tom chisle vne skryitogo repozitoriya domashnego kataloga. Rezhim `сохранённый` trebuyet tochnogo sovpadeniya kornya, zadachi i puti s prinyatoj zapisjyu. On zanovo proveryayet SHA fajla i ne vyizyivayet API. Oshibka novogo zaprosa ne vyidayot prezhnij uspekh.

Pustyiye `items`, otsutstviye otveta i `hasMore=false` ne dokazyivayut zaversheniye ili polnotu istorii. Zhivoj istochnik pri chtenii snimka ne pereproveryayetsya. Neizvestnaya struktura, dublikatyi klyuchej i povrezhdyonnyij JSON otklonyayutsya; vosstanovleniye iz fragmentov zapresjheno. Malenjkij otvet bez soobsjhenij mozhet statj boljshe iz-za yavnyikh metadannyikh i ogranichenij. Polnyij snimok soderzhit tochnyiye bajtyi sobstvennoj serializacii MCP-obyyekta, a ne dokazannyiye transportnyiye bajtyi servera.

[Kontrakt sootvetstviya](../../Proyektyi/rabochij-kontekst/kontraktyi/otvet-zadachi.json), [vkhodnaya skhema](../../Proyektyi/rabochij-kontekst/kontraktyi/skhema-vkhoda-otveta.json) i [vyikhodnaya skhema](../../Proyektyi/rabochij-kontekst/kontraktyi/skhema-vyikhoda-otveta.json) opisyivayut tekusjhij etalon. Tekstovyiye dejstviya v kontrakte yesjhyo ne yavlyayutsya ispolnyayemyimi strukturiruyusjhimi operatorami. [Otdeljnyij dejstvuyusjhij srez](../../Proyektyi/rabochij-kontekst/operatornyiye-modeli-otveta.md) rasshiryayet konechnyij ispolnitelj i generiruyet modeli Swift Codable, Python i predmetnuyu proyekciyu iz odnogo opisaniya. API-obyortka sokhranyayet prezhnij Python-etalon. Codable sam ne opredelyayet vyibor polej i kanonicheskiye bajtyi.

Proverki i vosproizvedeniye iz kornya checkout:

```sh
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_компактный_ответ_задачи.py
node --test Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_адаптер_ответа.cjs
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_ответа_задачи.py --выход профиль.json
```

Vyikhod profilya napravlyayetsya vo vremennyij katalog ili materialyi sobstvennogo etapa. Nezavisimaya proverka skhem `Проекты/рабочий-контекст/проверить-контракт-ответа.py` ispoljzuyet otdeljno obyyavlennyij `jsonschema` 4.23.0; osnovnoj CLI ot nego ne zavisit. Realjnyiye zapusk i profilj: [otchyot etapa](../../Zhurnal/2026-09-14_15-01-38_MSK_sokratitj-otvetyi-nativnyikh-instrumentov/otchyot.md). Polnyij smoke-check i proyekciya v etoj kontroljnoj tochke ne vyipolnenyi.

## Smeshannaya posledovateljnostj i povtornoye ispoljzovaniye

[Profilj](tests/profilj-smeshannyikh-otvetov.cjs) vyizyivayet tot zhe adapter i nastoyasjhij Python CLI. Toljko `read_thread` zamenyon otkryitoj fiksturoj; fajl sokhranyayetsya nastoyasjhej zapisjyu, otvet i SHA proveryayutsya. Vyipolnyayutsya semj ciklov: novyij malyij i krupnyij otvetyi, zatem po dva sokhranyonnyikh chteniya kazhdogo; nachaljnyij razmer chereduyetsya. Chastota realjnoj ekspluatacii ne nablyudalasj, sostav etogo scenariya zadan yavno.

```sh
node --test Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_смешанный_профиль.cjs
node Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль-смешанных-ответов.cjs <файл-профиля>
```

Nuzhnyi Node.js i Python standartnoj postavki; izmereno na Node.js 26.8.2 i Python 3.14.7. Ukazhite vyikhodnoj fajl vo vremennom kataloge ili materialakh sobstvennogo etapa. Uspekh — kod 0, JSON-profilj na diske i kratkaya svodka stdout; otkaz — kod 2. Vse sozdannyiye profilem vremennyiye snimki udalyayutsya posle izmereniya; realjnyiye poljzovateljskiye snimki etot scenarij ne chitayet. Proveryayemyij original dostupen v kazhdom shage do etoj yavnoj ochistki. Oshibka ne zapisyivayet uspeshnyij profilj.

[Izmerennyiye 42 chteniya](../../Zhurnal/2026-09-14_17-07-43_MSK_izmeritj-smeshannuyu-posledovateljnostj-otvetov/materialyi/profilj-smeshannoj-posledovateljnosti.json) dali 116214 bajtov kompaktnogo JSON+LF protiv uslovnyikh 84026964 bajtov polnoj vyidachi na kazhdom shage. Diskovyij obyyom schitayetsya otdeljno po 14 unikaljnyim sokhranyonnyim fajlam: 28008988 bajtov. Vyipolnenyi 14 simulirovannyikh API-vyizovov, 14 zapisej fajlov, 70 lokaljnyikh komand, 28 zagruzok i 56 zapisej kyesha. Zhivyikh API-vyizovov — nolj. Kazhdyij iz 28 sokhranyonnyikh shagov povtoril prinyatyij rezuljtat i proveril polnyij SHA bez novogo API i zapisi fajla.

Mediana cikla iz shesti chtenij — 552,216 ms. Pervichnoye chteniye malogo/krupnogo otveta: 131,247/156,689 ms; sokhranyonnoye: 59,078/72,550 ms. Vremya vklyuchayet fakticheskiye subprocess i I/O. Podgotovka, kontrolj rezuljtata posle vyizova i udaleniye vremennogo kataloga isklyuchenyi; vlozhennyiye vremena uzhe vkhodyat v vremya shaga. Fajlovyij kyesh OS ne sbrasyivalsya. Vremya zaglushki ne yavlyayetsya zaderzhkoj API ili seti, vremya bazovogo polnogo scenariya ne izmereno; uskoreniye zhivoj rabotyi etim zamerom ne dokazano.

Malyij otvet vyiros 642 → 2763 bajta, krupnyij umenjshilsya 4000642 → 2771. Snizheniye summarnoj poleznoj vyidachi na 99,862% otnositsya toljko k zadannoj smesi 1:1. Pri odnikh malyikh otvetakh kompaktnyij format zdesj uvelichivayet obyyom primerno v 4,30 raza. Eti bajtyi vklyuchayut fakticheskij privatnyij putj i LF, no isklyuchayut sluzhebnuyu obolochku instrumentov, tekst vyizyivayusjhego koda i tokenizaciyu. Sam putj ne opublikovan. Sokhranyonnoye chteniye ne dokazyivayet svezhesti zhivogo sostoyaniya.

[Otchyot i granicyi priyomki](../../Zhurnal/2026-09-14_17-07-43_MSK_izmeritj-smeshannuyu-posledovateljnostj-otvetov/otchyot.md). Etot profilj otnositsya k prezhnej API/cache-obyortke; generaciya i primeneniye novogo Swift/Python-kontrakta izmerenyi otdeljno v yego rukovodstve.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 17:17:14 MSK -->
<!-- content-sha256: sha256:9ad1478231693cf79edfc252af34506d16b66d181e7bcea8a8f959be4958137c -->
<!-- FUM-MD-RECENCY:END -->
