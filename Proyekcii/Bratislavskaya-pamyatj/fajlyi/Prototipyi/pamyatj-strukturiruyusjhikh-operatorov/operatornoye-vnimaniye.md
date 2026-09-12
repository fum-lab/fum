# Dva opredeleniya operatornogo vnimaniya

Ogranichennoye rasshireniye obsjhego `AutomationExecutor` svyazyivayet nablyudeniye, znachimostj, vnimaniye, predlozheniye dejstviya, proverku rezuljtata i sostoyaniye prichinyi. Predmetnyiye usloviya prinadlezhat opredeleniyam [strukturiruyusjhikh operatorov](../../Glossarij/strukturiruyusjhij-operator-FUM.md) dlya aktualjnosti README i potrebnosti integracii. Adapteryi izvlekayut faktyi. Signal ne ispolnyayet dejstviye i ne predostavlyayet polnomochij.

Paket proshyol 52 Swift-testa, 23 Python-testa, strogij lint i skvoznoj Release-scenarij. Dostavka vetki i zaversheniye dokumentacionnoj priyomki uchityivayutsya otdeljno; RED/GREEN i profilj sokhranenyi v [otchyote realizacii](../../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/otchyot.md).

## Konechnyij graf

Novaya skhema opredeleniya `fum.определение-графа.2` imeyet polya `схема`, `идентификатор`, `версия`, `цель`, `идентичность`, `основания`, `узлы`, `обязательные`, `исходы`, `сигналы`. Versiya opredeleniya — polozhiteljnoye celoye chislo; skhema yazyika zadayotsya otdeljno. Iskhodnyiye opredeleniya `fum.определение-оператора.1`, nablyudeniya i prezhnij putj ispolneniya sokhranyayutsya.

Uzel zadayot `идентификатор`, `оператор`, `входы`. Podderzhanyi ravenstvo vyibrannyikh znachenij, vkhozhdeniye znacheniya v konechnyij spisok, `все`, `любой`, otricaniye raneye vyichislennogo usloviya, SHA-256 kanonicheskogo JSON-znacheniya i SHA-256 stroki UTF-8. Posledniye dve operacii vozvrasjhayut 64 shestnadcaterichnyikh znaka bez prefiksa; khyeshi vsego opredeleniya, parametrov i nablyudeniya ispoljzuyut `sha256:`. Selektor — obyyekt s yedinstvennyim polem: `поле` soderzhit massiv klyuchej vkhoda; `константа` — bukvaljnoye znacheniye; `узел` — imya predshestvuyusjhego uzla; `цель` — pustuyu stroku dlya podstanovki vyibrannoj celi opredeleniya. Komponent puti `$цель` vyibirayet celuyu stroku celi kak klyuch. Neizvestnyiye ssyilki i ciklyi otklonyayutsya do vyichisleniya.

Usloviye imeyet tri znacheniya: `да`, `нет`, `unknown`. Otsutstvuyusjheye pole ne ravno pustoj stroke ili nulyu. Obyazateljnoye usloviye dolzhno poluchitj `да`; lyuboj inoj iskhod sokhranyayet neizvestnostj nezavisimo ot chislennyikh vesov. Trassa pokazyivayet imya uzla, operator, khyeshi vyibrannyikh vkhodov i strokovyij rezuljtat. Selektoryi nakhodyatsya v khyeshiruyemom opredelenii. Obyazateljnyiye osnovaniya vyivodyatsya otdeljnoj tablicej uslovij; rolj signala `обязательный-критерий` otdeljno oboznachayet predmetnyij kriterij, narusheniye kotorogo ne ischezayet pri nulevom vese. Obsjhij kod ne znayet imyon README, vetok i predmetnyikh iskhodov.

Iskhodyi perechislenyi v yavnom poryadke. Kazhdyij soderzhit usloviye, rezuljtat, prichinu, predlozheniye dejstviya i operaciyu nad pamyatjyu: aktivirovatj prichinu, sokhranitj prezhneye sostoyaniye, podtverditj snyatiye ili otmetitj neprimenimostj. Otsutstviye dokazannogo iskhoda dayot `unknown`. Sostoyaniye prichinyi uchityivayetsya otdeljno ot rassmotreniya i vnimaniya.

## Chuvstviteljnostj

Obyazateljnyiye parametryi `fum.параметры-чувствительности.1` soderzhat `версия`, `веса`, `порог`, `хэш`. Podderzhanyi celyiye vesa 0…100 dlya tochnogo nabora signalov opredeleniya i porog 0…10 000. Versiya — 1…1 000 000. Khyesh — SHA-256 kanonicheskogo JSON s vremenno pustyim polem `хэш`; probelyi oformleniya ne vliyayut. Otsutstviye, lishneye pole, neizvestnaya skhema, nepraviljnyij tip, vyikhod za predel libo nesovpadeniye khyesha dayut yavnyij otkaz.

Dlya kazhdogo obyyavlennogo signala sokhranyayutsya nablyudyonnoye usloviye, yedinica vklada 0 libo 1, ves, proizvedeniye i porog. Summa ne yavlyayetsya veroyatnostjyu, uverennostjyu ili dokazateljstvom istinnosti: ona zadayot prioritet rassmotreniya. Prioritet trebuyet vnimaniya pri summe ne nizhe poroga. Neizvestnostj obyazateljnogo fakta i dokazannaya prichina ne obnulyayutsya nizkim vesom. Khyeshi opredeleniya, parametrov i fakticheskikh istochnikov vyivodyatsya otdeljno; izmeneniye nastroyek ne svideteljstvuyet ob ustranenii.

## README

Identichnostj oblasti svyazyivayet repozitorij i tochnyij putj `README.md`. Tekusjhij commit ili khyesh README yavlyayutsya versiyami svideteljstva. Pervyij obyazateljnyij marshrut — pryamaya vidimaya ssyilka na `Приложения/FUMA/README.md`. Vtoroj adres dlya nezavisimogo A/B — prisutstvuyusjhij `Документация/README.md`.

Adapter chitayet ogranichennyiye syiryiye bajtyi, izvlekayet ssyilki i sokhranyayet dlya kazhdoj nachalo i konec diapazona UTF-8, SHA-256 diapazona i vsego iskhodnika. Polnyij prochitannyij srez pozvolyayet proveritj otsutstviye ssyilki. Kommentarii, kod i izobrazheniya ne schitayutsya vidimyimi ssyilkami. Razbor nezavisimo sopostavlyayetsya s susjhestvuyusjhim `check-readme-index`; tot proveryayet strukturu i navigaciyu, no ne smyislovuyu aktualjnostj. Recency vyichislyayetsya susjhestvuyusjhimi funkciyami i khranitsya otdeljno ot SHA-256 syiryikh bajtov.

Dokazannoye otsutstviye obyazateljnoj ssyilki dayot raskhozhdeniye. Izmeneniye znachimogo osnovaniya dayot povod peresmotretj yego; smyislovoye ustarevaniye iz khyesha ne vyivoditsya. Postoronniye fajlyi ne vkhodyat v zavisimosti. Nedostupnostj istochnika, narushennaya privyazka ili ustarevshij srez dayut `unknown`. Prezhnyaya aktivnaya prichina sokhranyayetsya.

Prosmotr ne raven rassmotreniyu. Rassmotreniye ne ravno ustraneniyu. Dlya snyatiya aktivnoj prichinyi nuzhnyi odnovremenno nalichiye obyazateljnoj ssyilki i novoye proverennoye svideteljstvo, svyazyivayusjheye tekusjhiye bajtyi README, tekusjhuyu versiyu osnovaniya i oblastj. Staroye podtverzhdeniye posle izmeneniya istochnika ne podkhodit. Povtor tekh zhe dannyikh vosproizvodit tot zhe JSON; novoye vremya ne podstavlyayetsya ispolnitelem skryito.

## Integraciya

Identichnostj svyazyivayet repozitorij, iskhodnuyu postavku i vyibrannuyu stadiyu marshruta `fuma` → `master`. Nablyudyonnyij HEAD celi yavlyayetsya versiyej svideteljstva. Stadiya `master` prinimayet zakreplyonnyij rezuljtat stadii `fuma`, svyazannyij s iskhodnoj postavkoj; pryamoj pereskok s bokovoj vetki zapresjhyon.

Ancestry i priyomka vyichislyayutsya i pokazyivayutsya razdeljno. Polnoye zamyikaniye roditelej proveryayetsya po syiryim commit-obyyektam, s nezavisimyim pereschyotom OID. Otsutstviye obyyekta ne zamenyayetsya otricateljnyim ancestry. Zakryityij otchyot trebuyet tochnogo v3/report-v2, polnogo inventarya, neizmenyayemyikh fajlov, khyeshej i rezuljtata susjhestvuyusjhego proveryayusjhego. Svyazj otpechatka s postavkoj otdeljno vosstanavlivayetsya iz yeyo roditelya i realjnoj raznicyi derevjyev. Oblastj proverok sokhranyayetsya: dokumentacionnyij smoke ne stanovitsya proverkoj vsej funkcionaljnosti CLI. Nepodderzhannyij v4 ne prinimayetsya po analogii.

| Nablyudeniye                                                    | Predlagayemyij rezuljtat                                |
| ------------------------------------------------------------- | ---------------------------------------------------- |
| Proverennaya postavka yesjhyo ne vklyuchena v celj                    | Integrirovatj v vyibrannuyu oblastj                     |
| Toljko checkpoint libo predmetnaya postanovka                  | Razobratj nedostayusjhij dopusk                          |
| Istochnik uzhe ancestor, podkhodyasjhej kvitancii net                 | Proveritj podtverzhdeniye vklyucheniya                    |
| Vkhod otsutstvuyet, protivorechiv ili nepolon                      | Unknown s sokhraneniyem prezhnej aktivnoj prichinyi        |
| Vklyucheniye i sovpadayusjhaya kvitanciya podtverzhdenyi                  | Snyatj potrebnostj toljko vyibrannoj oblasti            |
| Podtverzhdena otmena                                            | Otmetitj neprimenimostj                               |
| Podtverzhdena utrata rezuljtata posle vklyucheniya                  | Razobratj utratu; povtornoye sliyaniye ancestor ne nuzhno   |

Kvitanciya ssyilayetsya na postavku, yeyo priyomku, vyibrannuyu oblastj i rezuljtat vklyucheniya. Chuzhoj OID ili chuzhaya kvitanciya dayut unknown. Ancestry samo po sebe ne dokazyivayet sokhrannostj rezuljtata posle revert. Nazvaniye kommita ne schitayetsya dokazateljstvom utratyi.

## Granica sreza

Zakryityij JSON prinimayet stroki, celyiye chisla, massivyi i obyyektyi. Bulevyi znacheniya, null i drobi ne vkhodyat v novyij vkhod, kak i v prezhnij parser. Predel — 65 536 bajtov na opredeleniye, parametryi ili vkhod; glubina 16, 8 192 uzla. Graf konechen i ne soderzhit obsjhego planirovsjhika. Predelyi i povrezhdeniye parametrov dayut neuspeshnyij kod CLI, a nedostatochnyiye predmetnyiye svideteljstva — vyichislennyij `unknown` s kodom 0. Kod 0 podtverzhdayet ispolneniye kontrakta; predmetnyij iskhod nakhoditsya v pole `результат` JSON.

Chitatelj Git mozhet vremenno materializovatj proverennyiye obyyektyi vne checkout, chtobyi nastoyasjhij Git vosproizvyol binarnyij diff. On ne menyayet refs, indeks ili obyyektnuyu bazu proyekta, ne obrasjhayetsya k seti i udalyayet vremennyiye dannyiye posle chteniya. Tochnyiye istochniki sokhranyayutsya otkryityimi fiksturami; nedostupnostj obyazateljnogo obyyekta chestno ostayotsya neizvestnostjyu.

Polnyij yazyik grafov, emocii, subyyektivnoye perezhivaniye, Metal, hooks, raspisaniye, avtonomnaya fabrika, merge, push i zapusk zadach ne vkhodyat v mekhanizm. Rassmotreniye signala ne zapisyivayet obrabotku 0177. Prikladnoj srez ne zakryivayet vesj STEP0165 i REQ0044.

## Pamyatj sleduyusjhego nablyudeniya

Pole rezuljtata `память` gotovo dlya peredachi kak `прежнее` sleduyusjhego strukturirovannogo vkhoda. Ono soderzhit sostoyaniye, aktivnuyu prichinu, yeyo oblastj i osnovaniya s ustojchivyim kriteriyem. Pole `прежнее` sokhranyayet iskhodnyij signal otdeljno. Pri unknown libo chuzhoj oblasti pamyatj ostayotsya pobajtovo tem zhe kanonicheskim znacheniyem: staraya prichina ne perenositsya v novuyu stadiyu. Vremya, parametryi i nablyudyonnyij target HEAD ne vkhodyat v identichnostj integracionnogo signala.

Rassmotreniye khranitsya otdeljno. Utrata rezuljtata posle revert imeyet kriterij `сохранность-результата`; dejstvuyusjhaya kvitanciya vklyucheniya bez novoj proverki vosstanovleniya etu prichinu ne snimayet. Novyij proverennyij srez README mozhet podtverditj sootvetstviye izmenivshemusya osnovaniyu bez pravki samogo dokumenta. Vo vsekh sluchayakh resheniye grafa yavlyayetsya predlozheniyem, a pole polnomochiya ostayotsya `не предоставлено`.

## Proiskhozhdeniye i oblastj doveriya

[Sborsjhik README](Sborsjhiki/faktyi_vnimaniya.py) chitayet obyichnyiye fajlyi s tochnyim registrom, povtorno sveryayet ikh versii, sokhranyayet syiryiye UTF-8-bajtyi README, diapazonyi ssyilok i khyesh polnogo izvlecheniya. Vidimostj Markdown sveryayetsya s susjhestvuyusjhim `check-readme-index.py`; recency izvlekayetsya susjhestvuyusjhim `update-md-recency.py`. Proveryayusjhij i yego iskhodniki imeyut zakreplyonnyij v opredelenii khyesh. Opciya `--проверить-результат` otdeljno vosproizvodit proverku konechnogo kriteriya i svyazyivayet yeyo s tekusjhim README, vyibrannyim osnovaniyem i prezhnej prichinoj. Ona ne vyichislyayet sostoyaniye potrebnosti.

Graf proveryayet svyazi poluchennogo nablyudeniya, a fizicheskoye izvlecheniye ostayotsya otvetstvennostjyu obyyavlennogo sborsjhika. Samosoglasovannyij paket, celikom poddelannyij vyizyivayusjhej storonoj vmeste so vsemi iskhodnikami i utverzhdeniyami, ne autentificiruyetsya JSON-khyeshami. Etot CLI ne yavlyayetsya granicej vyidachi polnomochij ili mekhanizmom elektronnoj podpisi. Otkryityiye otricateljnyiye fiksturyi proveryayut narushennyiye svyazi, nepodderzhannyiye skhemyi i protivorechiya; oni ne zayavlyayut zasjhitu ot komprometacii proveryayusjhego processa.

[Chitatelj obyyektov](Sborsjhiki/obyyektyi_vnimaniya.py) proveryayet polnyiye SHA-1 OID po syiryim obyyektam. Arkhiv ogranichen 64 MiB i 8 192 obyyektami; otdeljnyij obyyekt — 8 MiB, zamyikaniye istorii i derevjyev — po 4 096. Glubina dereva ogranichena 64, razvyornutaya raznica — 32 768 zapisyami putej i 16 MiB vyivoda Git. Razmer live-obyyekta proveryayetsya do chteniya soderzhimogo; nakoplennyij dekodirovannyij kyesh ogranichen 64 MiB. Polnyij obkhod roditelej obyazatelen i dlya polozhiteljnogo ancestry. Dlya diff sozdayotsya otdeljnyij vremennyij Git-kontekst vne checkout, bez chteniya lokaljnoj konfiguracii i `info/attributes` prinimayusjhego repozitoriya. Otslezhivayemyiye `.gitattributes` etim pervyim profilem otklonyayutsya. Imena vetok, refs, rabochij indeks i obyyektnaya baza proyekta ne menyayutsya.

Portable-profilj yavno zadayot `--abbrev=8`: staroye avtomaticheskoye sokrasjheniye OID zaviselo ot razmera obyyektnoj bazyi. Sokhranyayutsya standartnyiye pravila Git diff, vklyuchaya raspoznavaniye pereimenovanij, bez external diff i textconv. Sovpadeniye s sokhranyonnyim v3-otpechatkom proveryayetsya tochno; otlichayusjhijsya rezuljtat ne podbirayetsya i ne prinimayetsya po analogii.

[Tri realjnyiye postavki](Sborsjhiki/primeryi_integracii.py) vosproizvodyatsya iz [otkryitogo arkhiva](Proverki/vnimaniye/git-obyyektyi.json) bez lokaljnogo dopolneniya obyyektov. Dlya c7 vosstanovlena tochnaya svyazj zakryitogo report-v2; 8d imeyet proverennyij otkryityij checkpoint. U f49 strukturno proveren report-v2 i dokazano polozhiteljnoye ancestry, no svyazj sokhranyonnogo otpechatka s postavkoj ne vosstanovlena takzhe v live Git. Eto otdeljnaya neizvestnostj, kotoraya ne razreshayet povtornoye sliyaniye predka ili lozhnyij resolved. Sostoyaniye priyomki i ancestry vyivodyatsya razdeljno.

Demonstracionnyij sborsjhik formiruyet nablyudeniye stadii fuma dlya tryokh zakreplyonnyikh primerov. Konechnyiye vkhodyi stadii master, kvitancii, otmenyi, revert i posledovateljnaya pamyatj predstavlenyi nezavisimyimi sinteticheskimi JSON-fiksturami i peredayutsya obsjhemu CLI. Oni yavno nazvanyi otkryitoj fiksturoj i ne vyidayutsya za realjnyiye kvitancii integracii.

## Vosproizvedeniye iz kornya FUM

Paket trebuyet macOS 14+, Swift 6.0+ i Python 3.11+. Obsjhij ispolnitelj napisan na Swift. Sborsjhiki ispoljzuyut Python dlya neposredstvennogo povtornogo primeneniya uzhe prinyatyikh chitatelej v3, indeksa README i recency; otdeljnaya realizaciya etikh proveryayusjhikh ne sozdayotsya. SwiftPM-zavisimosti ne dobavlyayutsya; ispoljzuyutsya sistemnyiye Foundation/CryptoKit i standartnaya biblioteka Python. Dlya chteniya realjnogo arkhiva nuzhen Git. Sobstvennyij kod ostayotsya pod CC0 proyekta; licenzii ispoljzuyemyikh Swift, SDK i Git sokhranyayut samostoyateljnoye dejstviye, storonniye biblioteki v paket ne kopiruyutsya. Dokumentacionnaya proyekciya ispoljzuyet otdeljno zaregistrirovannyij LinguisticKit `837e2ce107b97ee7b9d3344c9fe99142281fe393`: yego fakticheskij LICENSE — CC0 1.0 Universal, otdeljnyij NOTICE v zakreplyonnom dereve otsutstvuyet. Eta zavisimostj ne dobavlyayetsya v Swift-paket vnimaniya; yeyo [inicializaciya](../../Zavisimosti/README.md) nuzhna obsjhemu dokumentacionnomu konturu.

Adresnyiye proverki i posleduyusjhaya regressiya v1:

```sh
swift test --package-path Прототипы/память-структурирующих-операторов --scratch-path "${TMPDIR:-/tmp}/fum-operator-attention-build" --jobs 2 --filter ПроверкиВнимания
swift test --package-path Прототипы/память-структурирующих-операторов --scratch-path "${TMPDIR:-/tmp}/fum-operator-attention-build" --jobs 2
python3 -B -m unittest discover -s Прототипы/память-структурирующих-операторов/Проверки -p 'test_*внимания.py'
```

Pervoye opredeleniye na otkryitom otsutstvii ssyilki:

```sh
swift run --package-path Прототипы/память-структурирующих-операторов --scratch-path "${TMPDIR:-/tmp}/fum-operator-attention-build" --jobs 2 FUMStructuringOperatorMemoryProbe внимание --определение Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/Определения/актуальность-README.json --параметры Прототипы/память-структурирующих-операторов/Проверки/внимание/актуальность-README-обычные.json < Прототипы/память-структурирующих-операторов/Проверки/внимание/README-без-ссылки.json
```

Dlya vtorogo opredeleniya peredayutsya `потребность-интеграции.json`, `потребность-интеграции-обычные.json` i `интеграция-проверенная.json` iz tekh zhe katalogov. Fajlyi s suffiksami `-пониженные` i `-нулевые` zadayut aljternativnuyu chuvstviteljnostj bez izmeneniya faktov. Tochnaya [tablica ozhidayemyikh iskhodov](Proverki/vnimaniye/sluchai.json) vklyuchayet polozhiteljnyiye, otricateljnyiye i posledovateljnyiye sluchai.

Chteniye susjhestvuyusjhikh neizmenyayemyikh svideteljstv:

```sh
python3 -B Прототипы/память-структурирующих-операторов/Сборщики/примеры_интеграции.py
```

Sborka profiliruyemogo ispolnyayemogo produkta vyipolnyayetsya otdeljno:

```sh
swift build --package-path Прототипы/память-структурирующих-операторов --scratch-path "${TMPDIR:-/tmp}/fum-operator-attention-build" --jobs 2 -c release --product FUMStructuringOperatorMemoryProbe
```

[Skvoznoj profilj](Proverki/proveritj-i-izmeritj-vnimaniye.py) prinimayet `--бинарник` s poluchennyim ispolnyayemyim produktom i `--выход` s vneshnim fajlom JSON. On proveryayet vsyu tablicu, obe smenyi opredeleniya i parametrov, polnyij cikl README i tri realjnyiye postavki, zatem trizhdyi izmeryayet kazhdoye opredeleniye odnim neizmennyim binarnikom. Dlya README otdeljno izmeryayetsya sbor faktov i proverka rezuljtata; dlya Git — chteniye arkhiva i vosstanovleniye svideteljstv. `--профиль` samogo CLI vyivodit razdeljnyiye monotonnyiye stadii zagruzki, razbora, grafa i trassyi v stderr; JSON-nablyudeniye ostayotsya v stdout. Profilj ne vklyuchayet sborku i ne obyyavlyayet ochistku kyesha OS.

Fakticheskiye zapuski realizacii zapisanyi [otchyotnoj obyortkoj](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md). Ikh rezuljtatyi, RED/GREEN i soglasovaniye tyazhyolyikh okon nakhodyatsya v [zhurnale realizacii](../../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/otchyot.md).


### Fakticheskij kornevoj README

Posle sborki Release sleduyusjhij zapusk chitayet tekusjhiye fajlyi i sokhranyayet vkhod, signal i pamyatj vne checkout:

```sh
fum_attention_dir="$(mktemp -d /tmp/fum-attention-demo.XXXXXX)"
fum_attention_bin="${TMPDIR:-/tmp}/fum-operator-attention-build/release/FUMStructuringOperatorMemoryProbe"
python3 -B Прототипы/память-структурирующих-операторов/Сборщики/факты_внимания.py --корень-репозитория . --репозиторий FUM --задача демонстрация --время 2026-09-11T18:00:00Z > "$fum_attention_dir/вход.json"
"$fum_attention_bin" внимание --определение Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/Определения/актуальность-README.json --параметры Прототипы/память-структурирующих-операторов/Проверки/внимание/актуальность-README-обычные.json < "$fum_attention_dir/вход.json" > "$fum_attention_dir/сигнал.json"
python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))["память"],ensure_ascii=False))' "$fum_attention_dir/сигнал.json" > "$fum_attention_dir/память.json"
```

Dlya sleduyusjhego nablyudeniya sborsjhik poluchayet `--прежнее "$fum_attention_dir/память.json"`. Fajl obratnoj svyazi imeyet tochnuyu formu `{"рассмотрение":"рассмотрено","проверка":{}}` i peredayotsya cherez `--обратная-связь`. Posle ispravleniya prichinyi dopolniteljnyij `--проверить-результат Приложения/FUMA/README.md` zanovo proveryayet tekusjhiye bajtyi; poluchennyij vkhod snova peredayotsya tomu zhe ispolnitelyu. Mekhanizm ne perepisyivayet README. U uzhe sootvetstvuyusjhego README potrebnostj snachala ne voznikayet.

### Polnyij vosproizvodimyij cikl i realjnyiye postavki

Odin scenarij vyipolnyayet `расхождение → рассмотрено при расхождении → изменение с ожиданием проверки → resolved`. On sozdayot vremennuyu kopiyu dvukh vyibrannyikh osnovanij, beryot syiryiye README iz otkryityikh fikstur, kazhdyij raz vyizyivayet nastoyasjhij sborsjhik i peredayot imenno `память` predyidusjhego otveta. Izmeneniye ssyilki i novoye svideteljstvo pokazanyi raznyimi shagami. Polya `цикл_README` vyikhodnogo profilya sokhranyayut kazhdyij rezuljtat i pamyatj.

Etot zhe scenarij chitayet tri zakreplyonnyikh Git-primera iz arkhiva, peredayot kazhdyij otdeljnyij JSON tomu zhe binarniku i sokhranyayet priyomku otdeljno ot ancestry v `реальные_примеры`. Sborsjhik `примеры_интеграции.py` sam vyidayot tri stroki JSONL: vesj yego potok ne yavlyayetsya odnim vkhodnyim JSON ispolnitelya.

```sh
python3 -B Прототипы/память-структурирующих-операторов/Проверки/проверить-и-измерить-внимание.py --бинарник "$fum_attention_bin" --выход "$fum_attention_dir/профиль.json"
```

## Istochniki

- [Postanovka STEP0218](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0218-obnovitj-README-i-realizovatj-srez-aktualjnosti.md).
- [Modelj vnimaniya](../../Planirovaniye/rabochij-kontekst-zadachi/modelj-vnimaniya.md), [DETEKTOR-02](../../Planirovaniye/rabochij-kontekst-zadachi/detektoryi.json) i [KONTEKST-02–04](../../Planirovaniye/rabochij-kontekst-zadachi/scenarii-priyomki.json).
- [Komanda realizacii i pozdniye utochneniya](../../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 00:16:42 MSK -->
<!-- content-sha256: sha256:473b351a2de34da55dd46f1026d2b91d7c6cc91fef71104e7ca0c7860c82dcf0 -->
<!-- FUM-MD-RECENCY:END -->
