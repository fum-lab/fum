---
name: fum-svyaznostj-rabochej-sessii
description: Proveryatj svyaznostj rabochej sessii FUM pered kommitom: navigaciyu zaprosov, zavershyonnostj shablonov, zhurnal i yego profilj vremeni, kornevoj Codex-Thread-ID v zaprose i tele kommita, obyazateljnoye kanonicheskoye MSK-vremya, razdel ispoljzovannyikh instrumentov, Markdown-ssyilki, registr putej, klassifikaciyu voprosov i otvetov, signalyi meta-zaprosov i Git-sostoyaniye.
---

# FUM Session Coherence

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoraya proveryayet, chto [rabochaya sessiya](../../Glossarij/rabochaya-sessiya.md) svyazana s [pamyatjyu FUM](../../Glossarij/pamyatj-FUM.md) kak vosproizvodimaya cepochka:

papka zaprosa -> iskhodnyij zapros i sosednij otchyot -> zatronutyiye fajlyi -> proverki -> kommit.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu pered kommitom rabochej sessii, vliyayusjhej na proyekt, posle zapuska `fum-svezhestj-markdown` i posle togo kak fajl zaprosa uzhe soderzhit razdelyi `## Идентификатор сеанса Codex`, `## Использованные инструменты`, `## Повлиял на файлы` i `## Проверки`. Polnuyu predkommitnuyu proverku zapuskaj s tem zhe fajlom soobsjheniya, kotoryij zatem budet peredan `git commit -F`. Dlya novyikh zaprosov nachinaya s zakreplyonnoj vremennoj granicyi parametryi `--commit-message-file` i `--codex-thread-id` obyazateljnyi; istoricheskiye zaprosyi sokhranyayut prezhnij kontrakt.

Avtomatizaciya osobenno polezna, kogda sessiya menyayet neskoljko oblastej pamyati: `Документация/`, `Глоссарий/`, `Инструменты/`, `Планирование/` i `Журнал/`.

## Promezhutochnyij kommit postoyannoj zadachi

Yavnyij flag --kontroljnaya-tochka primenyayetsya toljko k promezhutochnomu kommitu, razreshyonnomu poljzovatelem. Vse proverki zaprosa, soobsjheniya kommita, identifikatora, ssyilok, recency i Git-sostoyaniya sokhranyayutsya. Mashinnyij zhurnal dolzhen byitj otkryityim, soderzhatj toljko terminaljnyiye zapisi i tochnyij aktualjnyij predprosmotr; aktivnaya zapisj, snimok, zhurnal vozobnovleniya ili podmena bloka zapresjhayut dopusk. Rezhim po umolchaniyu ne menyayetsya. Proverka ne zakryivayet otchyot i ne zayavlyayet gotovnostj proyekcii ili finaljnogo rezuljtata.

## Resheniye o prodolzhenii zadachi

Pered zaversheniyem otveta i posle kommita etapa korenj chitayet ustojchivyij reyestr komandoj `scripts/проверить-продолжение-задачи.py --корень-репозитория . --codex-thread-id <корневой-UUID> --исходник <JSONL-корневой-задачи> --перед-завершением`. Dlya reyestra vtoroj versii neobyazateljnyij `--план <локальный-путь>` dolzhen sovpadatj s `план_этапа` reyestra; yego skhemyi i dokazateljstva opisanyi v [istoricheskom kontrakte v2](kontrakt-obyazateljstv-v2.md). Reyestr tretjyej versii obrabatyivayetsya otdeljnyim strogim chitatelem zakreplyonnogo importa: chastichnyij ostatok vsegda trebuyet prodolzheniya i ne dokazyivayet polnoye zaversheniye. Yavnyij istoricheskij plan v etom sluchaye proveryayetsya toljko kak otdeljnyij istochnik poljzovateljskoj ostanovki. Otdeljnyij read-only-vyizov posle kommita nakhoditsya vne uzhe zakryitogo zhurnala proverok. Bez `--перед-завершением` komanda vozvrasjhayet resheniye s kodom 0; s etim flagom kod 3 oznachayet obyazateljnoye prodolzheniye i zapresjhayet final. Kod 2 oznachayet nekorrektnyiye vkhodyi ili dokazateljstva i ne schitayetsya razresheniyem zavershitj zadachu.

Istoricheskaya skhema `fum.продолжение-задачи.1` ostayotsya chitayemoj s yavnyim `--план`, yesli reyestr nikogda ne poyavlyalsya v dostizhimoj istorii. Yeyo polya — `схема`, `задача`, `режим`, `остановка`, `работы`; u rabotyi — `идентификатор`, `действие`, `состояние`, `основание`, `свидетельство`. Dostupnaya rabota trebuyet null-svideteljstva, zavershyonnaya i ozhidayusjhaya — nepustoj stroki. V1 boljshe ne razreshayet terminaljnoye zaversheniye postoyannoj zadachi: s `--перед-завершением` zavershyonnyij perechenj vozvrasjhayet kod 3. Udaleniye rabochego reyestra ne otkryivayet obkhod cherez v1 dazhe v rezhime `разовая`. Pered neostanovochnyim resheniyem povtorno proveryayutsya otsutstviye reyestra, bajtyi plana i prochitannyikh istochnikov, a v Git-dereve takzhe HEAD. Eto proverka nablyudyonnoj stabiljnosti, ne atomarnaya zasjhita ot konkurentnoj zapisi. Citata ostanovki proveryayetsya kak celoye samostoyateljnoye soobsjheniye, a ne proizvoljnaya podstroka.

`--вид-коммита контрольный|итоговый-этапа` zapisyivayet obyyavlennyij kontekst, no ne dokazyivayet susjhestvovaniye kommita. Yego OID, derevo i posledovateljnostj daljnejshikh dejstvij otdeljno proveryayet korenj po Git i JSONL. `--профиль` vyivodit monotonnoye vremya i iskhod v stderr, sokhranyaya stdout mashinnyim resheniyem.

V2 proveryayet monotonnostj vsego sokhranyonnogo reyestra po polnomu Git DAG, nastoyasjhiye kartochki HEAD, zakryityiye v4-dokazateljstva i tochnyiye bajtyi zayavlennyikh rezuljtatov. Yego prezhnyaya realizaciya sokhranena otdeljno v `scripts/обязательства_задачи_v2.py`. Chitatelj v3 v `scripts/обязательства_задачи.py` sokhranyayet stroguyu priyomku v3 i dopuskayet istoricheskij v2 toljko cherez zakreplyonnyij arkhiv i kartu importa; proveryayutsya vse versii i roditeljskiye ryobra, ponizheniye versii zapresjheno. Nomer reyestra, nomer zapisi zapuska i wire-skhema resheniya — raznyiye kontraktyi. Chastichnyij rezuljtat reyestra v3 sokhranyayetsya vnutri polya `обязательства` v wire-skheme `fum.решение-продолжения.2` s nepustyim ostatkom i resheniyem `продолжить`. Zavershyonnyij punkt plana i svobodnoye svideteljstvo ne pogashayut obyazateljstvo. Polnotu pervonachaljnogo reyestra, semantiku realizacii, dostatochnostj testov i nezavisimuyu podlinnostj ikh zapuska proveryayet korenj. Komanda ne perekhvatyivayet final na urovne Codex, ne sozdayot raspisaniye i ne vozobnovlyayet runtime; yeyo integraciya so Stop proveryayetsya otdeljno.

## Obyazateljnyij razbor dialoga

Pri vosstanovlenii i sverke dogovoryonnostej vyizyivayetsya [ostatok soobsjhenij](obrabotka-soobsjhenij.md) s yavnyimi kornem, kornevyim UUID i iskhodnyim JSONL:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обработать-сообщения-задачи.py --корень-репозитория . --codex-thread-id <UUID> --исходник <JSONL> остаток --без-записи
```

Originalyi i pozdnij kontekst razbirayutsya privatno; podtverzhdeniye obrabotki zapisyivayetsya otdeljno posle sokhraneniya dopustimoj komandyi, otveta i osnovaniya. Sostavnoj dopusk vyizyivayet tot zhe raschyot bez zapisi i posle nego povtorno sveryayet HEAD, bajtyi vkhodov obyazateljstv i ikh nablyudyonnuyu granicu. Kod 2 pri oshibke istochnika ili istorii ne dayot dopuska; kod 3 trebuyet razbora libo prodolzheniya. Ni vyizov, ni otmetka obrabotki sami po sebe ne dokazyivayut vyipolneniye porucheniya.

Otkryityij profilj celyikh processov guard i adaptera na 70 MiB vosproizvoditsya cherez otchyotnuyu obyortku:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/измерить-допуск-сообщений.py --повторов 3 --выход <профиль.json>
```

Tri scenariya: polnyij razbor s gotovyimi obyazateljstvami, ostatok soobsjhenij pri gotovoj rabote i ostatok obyazateljstv pri razobrannom dialoge. Proveryayutsya tochnaya iskhodnaya granica, otsutstviye zapisi kyesha, limit 65 536 bajtov i shtatnyiye 3 sekundyi. Podgotovka fiksturyi isklyuchena; fajlovyij kyesh OS ne ochisjhayetsya. [Izmereniya i nezavisimyij obzor](../../Zhurnal/2026-09-11_02-02-21_MSK_zakrepitj-dopusk-ostatka-soobsjhenij/otchyot.md) otnosyatsya k ukazannyim tam iskhodnikam i srede.

## Sinkhronnyij adapter Stop

`scripts/перехватить-завершение.py` prinimayet JSON nativnogo Stop iz stdin i vyizyivayet otdeljno naznachennyij guard. Adapter prednaznachen dlya POSIX runtime Codex 0.153.4. Fajl [shablona nastrojki](shablonyi/Stop.hooks.shablon.json) sam nichego ne podklyuchayet; konkretnoye vklyucheniye i proverku Trust vyipolnyayet koordinator otdeljnyim shagom.

Snachala proveryayutsya tochnyiye `session_id` i `hook_event_name: Stop`. Chuzhaya zadacha ili drugoye sobyitiye poluchayut `{}` bez vyizova guard i bez chteniya sostoyaniya. Yesli povrezhdyonnyij JSON, povtornyiye klyuchi, nevernyij UTF-8, razmer svyishe 65 536 bajtov ili nezakryityij vvod ne pozvolyayut dokazatj prinadlezhnostj, vozvrasjhayetsya toljko `systemMessage`. Posle ustanovleniya prinadlezhnosti proveryayutsya `cwd`, nepustoj `turn_id` i bulev `stop_hook_active`. Znacheniya `turn_id`, `stop_hook_active`, `transcript_path` i `last_assistant_message` ne dokazyivayut progress i ne sokhranyayutsya.

Interpretator adaptera i dochernij guard zapuskayutsya s `-I -S -B`. CLI peredayot guard tochnyiye `--корень-репозитория`, `--codex-thread-id`, obyazateljnyij `--исходник <JSONL>`, `--перед-завершением` i neobyazateljnyiye `--план`, `--кэш`. Istochnik zadayotsya v konfiguracii, a ne beryotsya iz `transcript_path` sobyitiya. Vyibor versii reyestra i plana ostayotsya obyazannostjyu guard.

Vneshnij otvet prinimayetsya toljko po zakryitoj skheme `fum.решение-продолжения.3`: rovno `схема`, `задача`, `решение`, `обязательства`, `сообщения`. Vlozhennoye resheniye obyazateljstv sokhranyayet prezhnij kontrakt wire v1/v2, vklyuchaya OID, dokazateljstva, ozhidaniye i nepustoj ostatok. Skhema reyestra, skhema zapuska i wire resheniya razlichayutsya. Staryij vneshnij wire otklonyayetsya: on ne podtverzhdayet proverku soobsjhenij.

`сообщения` soderzhit toljko pyatj skalyarov: celyiye neotricateljnyiye `всего`, `остаток`, `непроверенный_хвост` i bulevyi `полнота_источника`, `разбор_сообщений_завершён`. Tekstyi, puti i indeks JSONL naruzhu ne peredayutsya. Nepolnyij razbor trebuyet `продолжить`, dazhe yesli obyazateljstva zavershenyi libo ozhidayut otveta. Pustoj ostatok ne pogashayet obyazateljstva. Toljko podtverzhdyonnaya poljzovateljskaya ostanovka imeyet `сообщения: null` i proveryayetsya do chteniya JSONL, kyesha i byudzheta.

Pri oshibke argv adapter nezavisimo izvlekayet rovno odin kanonicheskij UUID i ogranichenno chitayet sobyitiye. Podtverzhdyonnyij celevoj Stop poluchayet diagnosticheskoye `continue:false`, chuzhaya zadacha — `{}`; guard i sostoyaniye ne vyizyivayutsya. Neodnoznachnyij UUID ili nerazobrannyij vvod dayut lishj diagnostiku. Staryij argv bez `--исходник`, sokrasjheniya parametrov i `--help` ne razreshayut zaversheniye. Ispravjte komandu ili podgotovjte novyij komplekt; sokhranyonnyij staryij zagruzchik avtomaticheski ne obnovlyayetsya.

| Iskhod guard                                  | Otvet adaptera pri exit 0                                                    |
| -------------------------------------------- | --------------------------------------------------------------------------- |
| Kod 3, resheniye `продолжить`                   | `decision: block`, determinirovannaya prichina sleduyusjhego dejstviya              |
| Kod 0, `завершить` ili `ожидать-ответа`        | `{}`                                                                        |
| Kod 0, `остановлено-пользователем`             | `continue: false`, prichina poljzovateljskoj ostanovki do chteniya byudzheta       |
| Oshibka, tajm-aut, nevernyij ili chuzhoj otvet     | Ogranichennyij `block` s diagnostikoj i trebovaniyem proveritj guard             |
| Predel povtorov ili obsjhij predel prodolzhenij  | `continue: false`; obyazateljstva yavno ne obyyavlyayutsya vyipolnennyimi             |
| Povrezhdeniye privatnogo sostoyaniya/uchyota        | Nemedlennaya diagnosticheskaya ostanovka: ogranichennostj cikla dokazatj neljzya   |

Po umolchaniyu stdin ogranichen odnoj sekundoj, guard — tremya; stdout i stderr guard chitayutsya razdeljno s predelom 65 536 bajtov kazhdyij. Pri prevyishenii limita ili signale ubirayetsya otdeljnaya gruppa guard. Soderzhimoye stderr ne popadayet v prichinu prodolzheniya. Nativnyij timeout dolzhen prevyishatj summu vnutrennikh granic: shablon zadayot 10 sekund. `SIGINT` i `SIGTERM` zavershayut tekusjhij vyizov i ne sozdayut prodolzheniye. `SIGKILL`, otkaz zapuska samogo interpretatora i nativnyij otkaz Trust ne mogut byitj prevrasjhenyi adapterom v otvet.

`--каталог-состояния` zadayot yavnyij privatnyij katalog vne checkout. Roditelj dolzhen susjhestvovatj; katalog sozdayotsya s pravami 0700, fajlyi — 0600. Proveryayutsya vladelec, tip, zhyostkiye i simvolicheskiye ssyilki; `flock` i atomarnaya zamena s `fsync` predotvrasjhayut poteryu schyotchikov pri povtornom vkhode. Sostoyaniye khranit toljko skhemu, UUID, chislo prodolzhenij i paryi khyesh–schyotchik. Povrezhdeniye ne sbrasyivayet byudzhet. Posle istecheniya byudzheta guard vsyo ravno proveryayetsya: poljzovateljskaya ostanovka sokhranyayet prioritet.

Kazhdyij `--файл-прогресса` perechislyayet konkretnyij rezuljtat otnositeljno kornya guard. Chitayetsya ne boleye 32 putej i 16 MiB summarno vmeste so scenariyem guard. Otpechatok zavisit ot soderzhimogo etikh fajlov i guard, vklyuchaya otsutstviye yesjhyo ne sozdannogo rezuljtata; otvet guard, oshibka, vremya i zhurnal ne vkhodyat v nego. Vozvrat k prezhnemu otpechatku prodolzhayet prezhnij schyotchik. Po umolchaniyu razreshenyi tri prodolzheniya na odin otpechatok i 64 summarno; izmeneniye nastroyek i sostoyaniya trebuyet otdeljnogo resheniya koordinatora. Bajtovoye izmeneniye yavlyayetsya nablyudayemyim priznakom, no samo po sebe ne dokazyivayet soderzhateljnoye vyipolneniye: eto proveryayet guard i koordinator. V shablone zadan reyestr obyazateljstv; pered podklyucheniyem sleduyet yavno dobavitj konkretnyiye rezuljtatyi tekusjhego etapa. Proizvoljnyij khyesh perepiski ili obsjhego Zhurnala dlya etogo neprigoden.

Podstanovka shablona trebuyet shesti absolyutnyikh putej: interpretator, derevo adaptera, derevo planirovsjhika, fakticheskij cwd runtime, privatnoye sostoyaniye i JSONL kornevoj zadachi. Nazvaniya yavlyayutsya plejskholderami, ne peremennyimi sredyi. Runtime mozhet rabotatj v primary checkout, odnovremenno proveryaya plan v sosednem dereve cherez yavnyij argument. Minimaljnoye mesto ustanovki — `hooks.json` ryadom s fakticheski aktivnyim proyektnyim sloyem `.codex/config.toml`; sosednij worktree avtomaticheski aktivnyim sloyem ne stanovitsya. Susjhestvuyusjhiye istochniki nuzhno snachala prochitatj: neskoljko Stop-handlers vyipolnyayutsya vmeste, a `continue:false` imeyet prioritet. Soderzhimoye susjhestvuyusjhikh nastroyek ne zamenyayetsya shablonom vslepuyu.

Posle otdeljnogo razresheniya koordinator sveryayet istochnik, komandu, timeout i sinkhronnostj v shtatnom spiske hooks, zatem poljzovatelj proveryayet i doveryayet tochnomu opredeleniyu. V CLI etot spisok otkryivayetsya `/hooks`; aktualjnuyu poverkhnostj Desktop proveryayut otdeljno. Izmenyonnoye opredeleniye snova trebuyet Trust. Obkhod doveriya, redaktirovaniye yego khranilisjha i samopodklyucheniye adapterom otsutstvuyut. Do nablyudayemogo nativnogo vyizova neljzya obyyavlyatj hook podklyuchyonnyim. Uzhe pokazannyij final ne skryivayetsya: blokirovka prosit sleduyusjhij khod toj zhe zadachi.

Dlya adresnyikh proverok ispoljzuyetsya `tests/test_перехват_завершения.py`. `scripts/измерить-перехват-завершения.py` izmeryayet pyatj povtorov pyati sinteticheskikh scenariyev: chuzhaya zadacha, obyichnyij i predeljnyij vvod, rezuljtat 15 MiB, tajm-aut guard. Flag adaptera `--профиль` vyivodit v stderr toljko razmeryi, monotonnyiye intervalyi i maksimaljnuyu pamyatj; stdout ostayotsya mashinnyim resheniyem. Proverki i profilj zapuskayutsya cherez otchyotnuyu obyortku sobstvennoj sessii.

`scripts/проверить-интеграцию-перехвата.py --корень-guard <абсолютный-корень>` ispoljzuyet realjnyiye guard v2 i yego sinteticheskiye Git-fiksturyi: nezavershyonnoye obyazateljstvo bez sleduyusjhej rabotyi, ozhidaniye, oshibka, poljzovateljskaya ostanovka, prinyatyij rezuljtat i nezakommichennaya granica plana. Proveryayutsya iskhodyi i samogo guard, i adaptera. Fiksturyi sozdayutsya toljko vo vremennyikh katalogakh; bajtkod vneshnikh modulej ne zapisyivayetsya. Do i posle sravnivayutsya khyeshi guard, fiksturyi i vsekh yego zavisimostej; rezuljtat soderzhit ikh khyeshi, HEAD i priznak nezakommichennogo snimka. Eto proverka mezhprocessnogo kontrakta, ne dokazateljstvo nativnoj ustanovki, Trust ili sleduyusjhego khoda Desktop.

V shablone dopolniteljno zamenyayetsya otnositeljnyij putj plana etapa; reyestr, plan i modulj guard vkhodyat v izmeryayemyij progress. Privatnoye sostoyaniye zapresjheno pod lyubyim Git-predkom, vklyuchaya skryityiye repozitorii domashnego kataloga. Aktivnyim mozhet byitj poljzovateljskij, a ne proyektnyij sloj: yego vyibirayet koordinator po realjnomu runtime. Trust zakreplyayet opredeleniye hook, no ne bajtyi Python po ukazannomu puti; pered vklyucheniyem nuzhno sveritj khyeshi sokhranyonnyikh proverennyikh skriptov. Vlozhennyij variant `продолжить/null/[]` dopustim toljko s tochnoj istoricheskoj prichinoj o nevozmozhnosti dokazatj zaversheniye postoyannoj zadachi planom v1. On trebuyet sverki polnogo obyyoma; nezakommichennaya granica v2 po-prezhnemu vozvrasjhayetsya kak oshibka guard.

## Privatnyij komplekt Stop

[Podgotovitelj i kontrakt](privatnyij-komplekt.md) vosproizvodimo izvlekayut odinnadcatj tochnyikh iskhodnikov iz odnogo commit, proveryayut cepochku Git-derevjyev i sokhranyayut privatnyij komplekt s manifestom. Komanda kandidata zakreplyayet inline-zagruzchik, khyesh manifesta i izolirovannyij Python; chuzhiye fajlyi, nevernyiye prava i povrezhdyonnyij komplekt otklonyayutsya. Nastrojki, Trust i nastoyasjheye sostoyaniye podgotovka ne sozdayot. Shablon `Stop.hooks.шаблон.json` ostayotsya toljko poyasnyayusjhim primerom.

Pered primeneniyem koordinator chitayet kontrakt, sveryayet konkretnyij kandidat i dejstvuyusjhij sloj runtime. Sluzhebnyij HookPrompt ne pripisyivayetsya cheloveku po odnoj roli user; yego proiskhozhdeniye i fakticheskoye prodolzheniye modeli proveryayutsya otdeljno. Nativnoye podklyucheniye ne vyivoditsya iz uspeshnyikh sinteticheskikh testov ili nalichiya privatnogo kataloga.

## Proiskhozhdeniye soobsjhenij

Chistaya funkciya `scripts/происхождение_сообщений.py`, `классифицировать_сообщение(сообщение)`, prinimayet syiroj payload `response_item/message` do obyyedineniya fragmentov i normalizacii metadata. Vozvrasjhayet rovno `человек`, `служебный hook`, `служебный контекст` ili `неоднозначный`. Polnaya soglasovannaya annotaciya poljzovateljskogo vvoda imeyet prioritet nad bukvaljnyim XML; chastichnaya ili neizvestnaya annotaciya ne vklyuchayet XML-fallback. Otsutstvuyusjhiye svideteljstva ne udostoveryayut lichnostj i ne dokazyivayut zapusk hook. Funkciya ne chitayet JSONL, ne sokhranyayet arkhiv i ne izmenyayet payload. Vyizyivayusjhij sloj sokhranyayet pervichnyiye zapisi, otdeljnyiye povtoreniya i yavnuyu neodnoznachnostj.

Proveryayemaya postavka — commit002bb953671fa82b2144e7ec506d4975df977e3c; proiskhozhdeniye i profilj nakhodyatsya v [sobstvennom otchyote postavki](../../Zhurnal/2026-09-09_14-30-04_MSK_razlichatj-proiskhozhdeniye-soobsjhenij/otchyot.md). Kornevoye podklyucheniye k chteniyu dialoga ne yavlyayetsya nativnyim podklyucheniyem Stop.

## Komanda zapuska

Dlya vosstanovleniya iskhodnogo dialoga dostupen [polnyij chitatelj soobsjhenij](soobsjheniya-zadachi.md). On sokhranyayet vse ekzemplyaryi i uskoryayet povtornyij razbor JSONL s proverkoj prezhnego prefiksa. Vtoroj segment dobavlyayet [istoriyu obrabotki i polnyij ostatok](obrabotka-soobsjhenij.md): proverku sokhranyonnyikh komandyi, otveta, osnovaniya i pozdnego konteksta. Obyazateljnyij bezzapisnyij vkhod i sostavnoj zavershayusjhij dopusk zakreplenyi pravilami FUM-STEP-0177. Chastnyij kyesh i polnyij vyivod ostayutsya vne Git.

```bash
python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --commit-message-file <путь-к-файлу-сообщения> \
  --codex-thread-id <корневой-CODEX_THREAD_ID>
```

Po umolchaniyu proverka chitayet `git status --short --untracked-files=all` cherez `git -c core.quotepath=false`, chtobyi puti na kirillice sravnivalisj s razdelom `## Повлиял на файлы`, a novyiye katalogi raskryivalisj do konkretnyikh fajlov. Yavnaya Markdown-ssyilka na susjhestvuyusjhij katalog ogranichenno pokryivayet toljko yego potomkov; skhodnyij strokovyij prefiks i sosednij katalog ne pokryivayutsya.

Globaljnyiye fajlovyiye proverki ispoljzuyut obsjhij inventarj [fum-proyektnyiye-fajlyi](../fum-proyektnyiye-fajlyi/SKILL.md). Poetomu `.build`, `.swiftpm`, katalogi kyeshej, `.obsidian/plugins` i `.obsidian/themes` ne stanovyatsya vkhodami proverki ssyilok, voprosno-otvetnyikh materialov ili navigacii zaprosov. Isklyuchyonnyij fajl ne mozhet sdelatj ssyilku na otsutstvuyusjhij proyektnyij dokument formaljno korrektnoj.

Dlya izolirovannoj proverki fajlov i ssyilok bez Git-sostoyaniya mozhno ispoljzovatj:

```bash
python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --skip-git-status
```

## Chto proveryayetsya

- Obsjhaya struktura prokhodit `fum-struktura-papok-zaprosov`: kataloga `Запросы/` net, neposredstvenno v `Журнал/` iz Markdown-fajlov dopustim toljko `README.md`, a kazhdaya papka zaprosa imeyet obyazateljnyij vremennoj prefiks `YYYY-MM-DD_HH-MM-SS_MSK`, obyazateljnyij `запрос.md` i neobyazateljnyij katalog `материалы/`. U novoj rabochej sessii obyazatelen takzhe sosednij `отчёт.md`; yego otsutstviye dopustimo toljko u istoricheskogo zaprosa, dlya kotorogo otchyot ne susjhestvoval do migracii.
- Identichnostj, data i korotkoye nazvaniye zaprosa berutsya toljko iz imeni roditeljskoj papki; zagolovok sootvetstvuyet etomu imeni. Nachinaya s imeni `2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов` korotkoye nazvaniye dolzhno nachinatjsya s glagola v infinitive, a istoricheskiye zaprosyi do etogo pravila ostayutsya dopustimyimi dlya obratnoj sovmestimosti.
- Nachinaya s imeni `2026-07-14_02-31-47_MSK_добавлять-идентификатор-сеанса-Codex`, rovno odin razdel `## Идентификатор сеанса Codex` soderzhit yedinstvennuyu nepustuyu stroku s korrektnyim `Codex-Thread-ID`; obyazateljnyij `--codex-thread-id` sovpadayet s identifikatorom kornevoj zadachi, a obyazateljnyij `--commit-message-file` - s poslednim odnoimyonnyim Git trailer tela soobsjheniya.
- Razdel `## Навигация по запросам` tekusjhego zaprosa ukazyivayet na praviljnyiye predyidusjhij i sleduyusjhij `Журнал/*/запрос.md`, a sosednij zapros ssyilayetsya obratno. Ssyilki sopostavlyayutsya po polnostjyu razreshyonnoj celi, a ne po obsjhemu basename `запрос.md`.
- Ryadom s `запрос.md` susjhestvuyet `отчёт.md` so ssyilkoj na sosednij zapros. Nachinaya s imeni `2026-07-23_14-47-43_MSK_включать-профиль-времени-в-отчёты-журнала` otchyot soderzhit razdel `## Профиль времени выполнения`, tablicu s tochnyimi kolonkami `Стадия | Длительность | Границы и способ измерения`, ne meneye dvukh nepustyikh strok stadij i stroku `Граница профиля:`. Nachinaya s imeni `2026-07-27_16-12-29_MSK_учитывать-все-проверочные-вызовы-в-профиле-времени` tot zhe razdel soderzhit podrazdel `### Прямые запуски проверок`, tablicu s tochnyimi kolonkami `Вызов | Длительность | Результат` i stroku `Общее время прямых запусков проверок:`. Kazhdyij pryamoj zapusk testa ili proverki, vklyuchaya neuspeshnyij, prervannyij i povtornyij, zanimayet otdeljnuyu stroku; dliteljnostj zapisyivayetsya neotricateljnyim chislom sekund s zapyatoj ili tochkoj v roli desyatichnogo razdelitelya, a rezuljtat nachinayetsya so statusa `успешно`, `неуспешно`, `прервано` ili `не завершено`. Itog raven arifmeticheskoj summe dliteljnostej vsekh strok dazhe pri perekryitii zapuskov. Odin pryamoj vyizov sostavnoj smoke-proverki uchityivayetsya odin raz; yeyo vlozhennyiye shagi mogut byitj pokazanyi kak detalizaciya, no ne dubliruyut vklad v summu pryamyikh zapuskov. Nachinaya s imeni `2026-08-04_20-45-26_MSK_формировать-отчёты-о-запусках-тестов` proverka dopolniteljno vyizyivayet [fum-otchyotyi-o-zapuskakh-proverok](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md): zakryityij otchyot obyazan pobajtovo sovpadatj s khyeshirovannyim snimkom i vsemi fakticheskimi JSON-zapisyami, a perekhodnyij zhurnal obyazan otsutstvovatj. Otkryityij predprosmotr mozhet promezhutochno susjhestvovatj mezhdu vyizovami, no strogaya proverka prinimayet yego toljko pri nalichii khotya byi odnoj zapisi `выполняется`; novaya aktivnaya zapisj skhemyi `fum.test-run.v3` pri etom obyazana sokhranyatj `план: null`, pustyiye nablyudeniya, zakryityij shestipolevoj profilj i pustyiye terminaljnyiye polya, dazhe yesli vneshnij capability-konvert smoke-check uzhe soderzhit analiticheskij plan vyibrannogo profilya. Istoricheskiye v1/v2 ostayutsya chitayemyimi formatami, a boleye ranniye otchyotyi sokhranyayut ruchnoj istoricheskij kontrakt.
- Tekusjhiye `запрос.md` i `отчёт.md` ne soderzhat marker `<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->`; bukvaljnoye sovpadeniye vnutri doslovnogo razdela `## Текст запроса` ne pereinterpretiruyetsya i ne schitayetsya nezavershyonnoj zagotovkoj.
- Razdel `## Использованные инструменты` prisutstvuyet, soderzhit spisok i ssyilku na [reyestr sistemnyikh prilozhenij i instrumentov](../reyestr-sistemnyikh-prilozhenij-i-instrumentov.md). Nachinaya s imeni `2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex` obsjhaya zapisj `Codex - версия не раскрывается средой` otklonyayetsya: prilozheniye, runtime, CLI, modelj i kontraktyi agentskoj sessii dolzhnyi byitj kvalificirovanyi razdeljno. Nachinaya s imeni `2026-07-17_10-25-41_MSK_предотвращать-смещение-времени-сессий` razdel obyazan fiksirovatj ispoljzovaniye `fum-moskovskoye-vremya-rabochej-sessii`.
- Razdel `## Повлиял на файлы` soderzhit lokaljnyiye Markdown-ssyilki na zatronutyiye susjhestvuyusjhiye fajlyi, vklyuchaya tekusjhij `запрос.md` i sosednij `отчёт.md`. Massovoye izmeneniye mozhet yavno nazvatj susjhestvuyusjhij katalog i tem samyim pokryitj toljko yego susjhestvuyusjhikh potomkov. Dlya otsutstvuyusjhej posle tekusjhej sessii tochnoj celi ispoljzuyetsya stroka `- Удалённый файл: \`<putj>\``, для удалённых непосредственных файлов остающегося каталога — `- Удалённые непосредственные файлы каталога: \`<путь>/\``, a dlya celikom udalyonnogo dereva — `- Удалённое поддерево: \`<putj>/\``. Существующий обычный файл, снятый только с Git-учёта и сохранённый как локальное состояние, указывается строкой `- Снят с Git-учёта и сохранён локально: \`<путь>\``; proverka trebuyet exact staged deletion i sovpadeniye puti s Git ignore-pravilom. Marker neposredstvennyikh fajlov trebuyet susjhestvuyusjhij katalog i ne pokryivayet vlozhennyiye puti; udalyonnoye podderevo obyazano otsutstvovatj, nakhoditjsya vnutri repozitoriya i pokryivayet toljko sobstvennyikh potomkov.
- Aktivnyiye lokaljnyiye Markdown-ssyilki vo vsyom repozitorii ukazyivayut na susjhestvuyusjhiye celi, ostayutsya vnutri repozitoriya, a registr kazhdogo komponenta puti sovpadayet s realjnyim imenem fajla ili kataloga. Doslovnyij razdel `## Текст запроса` kanonicheskogo `Журнал/<stem>/запрос.md` schitayetsya syiroj oblastjyu proiskhozhdeniya i ne pereinterpretiruyetsya posle perenosa fajla; ssyilki do i posle nego ostayutsya aktivnyimi. Takoye zhe uzkoye pravilo dejstvuyet toljko mezhdu yedinstvennoj praviljnoj paroj `<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->` i `<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->` v neposredstvennom Markdown-fajle kataloga `Источники/URL/https/chatgpt.com/share/<id>/`, yesli pered nachaljnyim markerom stoit zagolovok `## Диалог`: eto doslovnyiye dannyiye vneshnego razgovora, no ssyilki sluzhebnoj shapki, indeksa i otchyota arkhiva prodolzhayut proveryatjsya. Povtornyiye, neparnyiye i pomesjhyonnyiye v drugoj katalog markeryi ne sozdayut isklyucheniya. POSIX-absolyutyi, Windows/UNC-puti, `file://` i otnositeljnyiye vyikhodyi za korenj otklonyayutsya; obyichnyiye vneshniye URL ne proveryayutsya.
- Kazhdyij fajl `Вопросы и ответы/*.md`, krome README, soderzhit nepustoj razdel `## Вопрос`, poslednij soderzhateljnyij simvol kotorogo raven `?`. Eto formaljnaya zasjhita nablyudayemogo priznaka, a ne lingvisticheskoye dokazateljstvo voprositeljnoj semantiki.
- Zatronutyiye Markdown-fajlyi, krome kanonicheskikh `Журнал/*/запрос.md`, ne soderzhat pokhozhij na poljzovateljskij meta-zapros o pravilakh [pamyati FUM](../../Glossarij/pamyatj-FUM.md), poryadke [rabochej sessii](../../Glossarij/rabochaya-sessiya.md), `AGENTS.md` ili papkakh zaprosov bez ssyilki na konkretnyij iskhodnyij `запрос.md`.
- Zatronutyiye Markdown-fajlyi, krome kanonicheskikh `Журнал/*/запрос.md`, ne nachinayutsya so spravochnogo bloka proiskhozhdeniya: `Источники требований`, `Источники`, `Опорные документы`, `Опорные материалы`, `Внешний материал`, `Затронутая документация` i pokhozhiye bloki dolzhnyi idti posle osnovnogo soderzhaniya pered `FUM-MD-RECENCY`.
- Zatronutyiye Markdown-fajlyi ne soderzhat Mermaid-podpisej uzlov, kotoryiye nachinayutsya s Markdown-markera spiska vrode `1. `, `1) `, `- `, `* ` ili `+ `, potomu chto Obsidian mozhet otobrazhatj takiye uzlyi kak `Unsupported markdown: list`.
- Avtomatizaciya `fum-svezhestj-markdown` podtverzhdayet svezhestj sluzhebnyikh recency-metok i indeksa `Индексы/markdown-файлы-по-времени-редактирования.md`, yesli etot lokaljnyij instrument yestj v repozitorii.
- Vse puti iz tekusjhego `git status --short` perechislenyi tochno libo vkhodyat v yavno nazvannyij susjhestvuyusjhij katalog, mnozhestvo udalyonnyikh neposredstvennyikh fajlov ostayusjhegosya kataloga ili otsutstvuyusjheye udalyonnoye podderevo iz razdela `## Повлиял на файлы`; lishniye vremennyiye fajlyi, kyeshi, sosedniye puti i otladochnyiye artefaktyi vyizyivayut oshibku.

## Proverki avtomatizacii

Lokaljnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p 'test_*.py'
```

V tablice pryamyikh zapuskov ekranirovannyij Markdown-razdelitelj `\|` ostayotsya chastjyu yachejki. Podrazdel, tablica ili itog vnutri fenced code ili HTML-kommentariya ne schitayutsya strukturoj otchyota. Arifmetika i diagnostika itoga sokhranyayut fakticheskuyu desyatichnuyu razryadnostj vsekh strok, a ne globaljnuyu tochnostj Decimal po umolchaniyu.

Testyi fiksiruyut bazovyij kontrakt: uspeshnaya sessiya prokhodit pri perechislennyikh izmenyonnyikh fajlakh; identichnostj i istoricheskiye vremennyiye granicyi berutsya iz imeni roditeljskoj papki; papka bez polnogo vremennogo prefiksa otklonyayetsya; navigaciya proveryayet tochnyiye celi pri odinakovom basename; novyiye korotkiye nazvaniya nachinayutsya s infinitiva; nezapolnennyij marker shablona vne doslovnogo teksta zaprosa otklonyayetsya; istoricheskaya obsjhaya zapisj versii Codex i istoricheskij otchyot bez profilya vremeni sokhranyayut obratnuyu sovmestimostj; bukvaljnyij vopros s `?` dopustim. Novyij zhurnaljnyij profilj prinimayet otdeljnyiye stroki povtornyikh zapuskov so statusami uspekha, neuspekha, preryivaniya i nezavershyonnosti, tochnuyu arifmeticheskuyu summu ikh dliteljnostej i aktivnuyu v3-zapisj toljko s `план: null`, pustyimi nablyudeniyami, zakryityim shestipolevyim profilem i terminaljnyimi `null`; istoricheskiye v1/v2 ostayutsya chitayemyimi. Otsutstviye podrazdela, tablicyi, strok ili itoga, nevernaya yedinica dliteljnosti, neizvestnyij status i nesovpadayusjhaya summa dayut oshibku. Dlya novyikh zaprosov otsutstvuyusjhiye obyazateljnyiye argumentyi, otsutstvuyusjhij, perenesyonnyij na druguyu stroku, nekorrektnyij ili dochernij `Codex-Thread-ID`, povtornyij razdel, lishnij tekst, psevdotrejler, otsutstvuyusjhij, dublirovannyij ili nesovpadayusjhij nastoyasjhij trailer v tele kommita, nekvalificirovannaya zapisj versii, otsutstviye `fum-moskovskoye-vremya-rabochej-sessii` posle zakreplyonnoj granicyi, otsutstviye sosednego otchyota ili obyazateljnogo tablichnogo profilya vremeni, bitaya ili registronevernaya Markdown-ssyilka, voprosno-otvetnyij fajl bez voprosa ili bez konechnogo `?`, vozmozhnyij nezavedyonnyij meta-zapros bez ssyilki na konkretnyij `Журнал/*/запрос.md`, verkhnij spravochnyij blok proiskhozhdeniya, Mermaid-podpisj uzla s Markdown-markerom spiska, ustarevshaya recency-proverka i neozhidannyij putj v Git-sostoyanii dayut oshibku. Marker dejstviteljno udalyonnogo fajla uchastvuyet pri proverke Git-sostoyaniya bez fiktivnoj ssyilki, a dlya susjhestvuyusjhej celi otklonyayetsya. Otdeljnaya fikstura podtverzhdayet, chto `.build/checkouts/vendor/README.md`, `.swiftpm` i kyeshi ne uchastvuyut v fajlovyikh obkhodakh i ne skryivayut bityiye proyektnyiye ssyilki.

## Granica avtomatizacii

Otdeljnaya komanda [ostatka obyazateljstv](ostatok-obyazateljstv.md) chitayet prinyatyij reyestr zadachi i vyibirayet dostupnuyu rabotu po proverennyim etapam. Ona vyizyivayetsya yavno; obyichnaya proverka svyaznosti ne zapuskayet yeyo avtomaticheski i ne poluchayet polnomochij prodolzhatj ili zavershatj zadachu.

Skript proveryayet strukturnuyu svyaznostj rabochej sessii, no ne podmenyayet smyislovuyu proverku dokumentacii. Agent po-prezhnemu otvechayet za korrektnostj trebovanij, publikacionnuyu chistotu soderzhaniya, polnotu spiska instrumentov, umestnostj zatronutyikh fajlov i kachestvo kommita.

Mashinnyij zhurnal pozvolyayet dokazatj tochnoye sootvetstviye zafiksirovannyikh zapuskov, snimka i Markdown, no ne mozhet obnaruzhitj process, namerenno zapusjhennyij v obkhod obyazateljnoj obyortki. Za soblyudeniye granicyi zapuska otvechayut korenj i subagentyi. Pri perekryitii pryamyikh zapuskov ikh arifmeticheskaya summa yavlyayetsya agregirovannyim call-time, a ne kalendarnyim wall-clock; obsjhiye granicyi sessii i stadij po-prezhnemu opisyivayutsya otdeljno v osnovnoj tablice profilya.

Proverka lokaljnyikh Markdown-ssyilok i registra ikh putej vyipolnyayetsya po vsem Markdown-fajlam repozitoriya, chtobyi oshibka, skryitaya na nechuvstviteljnoj k registru fajlovoj sisteme, ne ostavalasj v pamyati do sluchajnoj pravki konkretnogo fajla. Isklyuchayutsya toljko formaljno raspoznannyiye doslovnyiye diapazonyi iskhodnogo zaprosa i oformlennogo ChatGPT-share; narusheniye strukturyi ikh markerov zakryivayet isklyucheniye i vozvrasjhayet obyichnuyu globaljnuyu proverku ssyilok.

Proverka kataloga `Вопросы и ответы/` takzhe vyipolnyayetsya globaljno, a ne toljko po spisku fajlov tekusjhej sessii. Ona proveryayet formaljnyij bukvaljnyij priznak voprosa i ne ocenivayet kachestvo ili polnotu soderzhateljnogo otveta.

Proverka meta-zaprosov yavlyayetsya evristikoj. Ona isjhet formulirovki o voprose, utochnenii, otvete ili proverke poljzovatelya v kontekste pravil pamyati, poryadka rabochej sessii, `AGENTS.md` ili papok zaprosov; eto rannij signal, a ne dokazateljstvo, chto zapros dejstviteljno propusjhen.

Proverka Git-sostoyaniya sravnivayet toljko puti. Ona ne reshayet, nuzhno li vklyuchatj konkretnoye soderzhimoye v kommit; pered staging agent vsyo ravno dolzhen prosmotretj diff i isklyuchitj sekretyi, lokaljnoye sostoyaniye i mashinnyij musor.

## Istochniki trebovanij

- [Razrabotatj perekhvat zaversheniya](../../Zhurnal/2026-09-09_12-13-51_MSK_razrabotatj-perekhvat-zaversheniya/zapros.md).
- [Oficialjnyij kontrakt hooks](https://learn.chatgpt.com/docs/hooks#stop).
- [Obrabotchik Stop Codex rust-v0.153.4](https://raw.githubusercontent.com/openai/codex/rust-v0.153.4/codex-rs/hooks/src/events/stop.rs).

- [iskhodnyij zapros 2026-08-14 18:59:37 MSK — Isklyuchitj dublirovaniye polnoj regressii](../../Zhurnal/2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-06 20:56:43 MSK — Optimizirovatj rabotu testov](../../Zhurnal/2026-08-06_20-56-43_MSK_optimizirovatj-rabotu-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 20:45:26 MSK - Formirovatj otchyotyi o zapuskakh testov](../../Zhurnal/2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 15:48:19 MSK - Shablonizirovatj fajlyi zaprosov i otchyotov](../../Zhurnal/2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)
- [iskhodnyij zapros 2026-07-27 16:12:29 MSK - Uchityivatj vse proverochnyiye vyizovyi v profile vremeni](../../Zhurnal/2026-07-27_16-12-29_MSK_uchityivatj-vse-proverochnyiye-vyizovyi-v-profile-vremeni/zapros.md)
- [iskhodnyij zapros 2026-07-23 14:47:43 MSK - Vklyuchatj profilj vremeni v otchyotyi zhurnala](../../Zhurnal/2026-07-23_14-47-43_MSK_vklyuchatj-profilj-vremeni-v-otchyotyi-zhurnala/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:39:29 MSK - Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)
- [iskhodnyij zapros 2026-07-10 05:59:58 MSK - Utochnitj uchyot versij ChatGPT i Codex](../../Zhurnal/2026-07-10_05-59-58_MSK_utochnitj-uchyot-versij-ChatGPT-i-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-10 06:28:42 MSK - Ispravitj klassifikaciyu zaprosa](../../Zhurnal/2026-07-10_06-28-42_MSK_ispravitj-klassifikaciyu-zaprosa/zapros.md)
- [iskhodnyij zapros 2026-07-14 02:31:47 MSK - Dobavlyatj identifikator seansa Codex](../../Zhurnal/2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:25:41 MSK - Predotvrasjhatj smesjheniye vremeni sessij](../../Zhurnal/2026-07-17_10-25-41_MSK_predotvrasjhatj-smesjheniye-vremeni-sessij/zapros.md)
- [iskhodnyij zapros 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../../Zhurnal/2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:33:08 MSK -->
<!-- content-sha256: sha256:109cb7ca701ba3ea26251db90dd8036052cf6ae0b708c577beeccc8f8bc5da8c -->
<!-- FUM-MD-RECENCY:END -->
