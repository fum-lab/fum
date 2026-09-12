# Priyom napravlenij FUMA

Priyom svyazyivayet podtverzhdyonnoye soobsjheniye, smyislovoye resheniye, sobstvennyij Zhurnal, unikaljnyiye nomera i kartochki s odnoj vneshnej popyitkoj Codex. Pervyij realjnyij priyom matematicheskogo napravleniya podtverzhdyon: sokhranenyi oficialjnyij otvet, tochnoye nachaljnoye porucheniye i ranneye nablyudeniye bazyi novoj zadachi. Itogovaya priyomka obsjhego obyyoma FUM-STEP-0201 svyazyivayetsya s [zakryityim dopuskom i sokhranyonnyim obyazateljstvom](../../Zhurnal/2026-09-11_10-00-32_MSK_zavershitj-priyom-napravlenij-FUMA/otchyot.md); predmetnyij rezuljtat kazhdoj sozdannoj zadachi prinimayetsya otdeljno.

## Obyichnyij zapusk

Rabotajte v svoyom worktree, v sobstvennoj vetke `codex/…` i otkryitoj rabochej sessii Zhurnala. Dlya nachala sleduyusjhej sessii ispoljzuyetsya obyichnyij `start` avtomatizacii strukturyi papok zaprosov. Zakryityij otchyot ne vozobnovlyayetsya.

Podgotovjte privatnyij JSON vkhoda vne publikuyemogo checkout. On soderzhit putj pervichnogo JSONL, UUID iskhodnoj zadachi, resheniye, otnositeljnyij putj sobstvennogo zaprosa, spisok sozdavayemyikh ili obnovlyayemyikh kartochek i raneye soglasovannyiye nomera libo `null`. Resheniye skhemyi `fum.решение-приёма.1` ssyilayetsya na konkretnyij ekzemplyar soobsjheniya i polnyij rassmotrennyij kontekst 0177. Agent otdeljno opredelyayet aktualjnostj, pozdniye utochneniya, smyisl otveta, predmetnyij obyyom i yavnoye razresheniye novoj zadachi. Avtomatizaciya ne vyivodit eti resheniya iz klyuchevyikh slov.

Komanda `Инструменты/fum-reyestr-planirovaniya/scripts/принять-направление.py` prinimayet obsjhiye parametryi `--корень-репозитория` i `--задача`, zatem odnu operaciyu:

| Operaciya | Dopolniteljnyiye parametryi | Rezuljtat |
| --- | --- | --- |
| `подготовить` | `--вход` | Tochnaya para v Zhurnale, kartochki, indeksyi i mashinnyij reyestr; sokhranyonnoye sobyitiye i svideteljstva |
| `исправить-отображение-основания` | `--поправка` | Adresnoye udaleniye odnogo konechnogo ASCII-probela proizvodnogo osnovaniya s otdeljnoj kvitanciyej; iskhodnyij priyom sokhranyayetsya |
| `закрепить` | `--событие`, `--коммит`, `--ветка` | Proverennyij manifest polnogo kommita postanovki |
| `допустить` | `--вход` | Odna sokhranyayemaya popyitka i tochnyiye argumentyi vneshnego instrumenta libo zapret povtornogo vyizova |
| `сохранить` | `--событие`, `--попытка`, `--ответ` | Neizmenyayemaya kvitanciya polnogo syirogo MCP-otveta iz privatnogo JSON |
| `подтвердить-начало` | `--источник`, `--коммит` | Ranneye podtverzhdeniye sobstvennoj novoj zadachi do pervoj zapisi checkout |
| `наблюдать` | `--событие`, `--корень-задачи`, `--идентификатор-задачи`, `--источник` | Sverka fakticheskogo dereva, nachaljnoj bazyi i pervoj modeli novoj zadachi |

Kazhdaya komanda ispolnyayetsya otdeljnyim processom Python 3. Uspekh vyivodit odin JSON v stdout; otkaz vozvrasjhayet kod 2 s poyasneniyem v stderr. Sam CLI ne otpravlyayet zaprosov Desktop i ne zapuskayet fonovuyu sluzhbu.

Posle `подготовить` proverjte tochnyij rezuljtat, zapolnite otchyot, obnovite recency i sokhranite proverennyij kommit svoyej vetki obyichnyim poryadkom. V etot kommit dolzhnyi vkhoditj ispolnyayemyiye instrumentyi, para Zhurnala, kartochki, indeksyi i mashinnyij reyestr. Peredajte polnyij OID i polnyij susjhestvuyusjhij ref v `закрепить`; pered vyizovom oni proveryayutsya povtorno. Sokhraneniye kartochki toljko v prompt ili vyibor default-vetki ne dayut dopuska. Do nablyudeniya novoj nachaljnoj bazyi ne dvigajte ref postanovki.

Podgotovka sokhranyayet polnyiye bajtyi obsjhikh indeksov i tochnyiye pozicii paryi v Zhurnale. Poetomu zavershajte zakrepleniye i vneshnyuyu popyitku odnogo napravleniya do podgotovki sleduyusjhego v tom zhe dereve. Posle podgotovki sokhranyajte tekst pered vstavlennoj paroj neizmennyim; dopolneniya otchyota pomesjhajte posle neyo. Novyij etap poluchayet novuyu papku Zhurnala. Predvariteljnoye vyideleniye nomerov samo po sebe ne izmenyayet indeksyi.

## Ispravleniye negotovogo mestnogo priyoma

Yesli pervaya fajlovaya stadiya polnostjyu ustanovlena, no nastoyasjhij sborsjhik reyestra otklonil kartochki, odin raz mozhno yavno ispravitj ikh soderzhaniye. Priyom dolzhen ostavatjsya negotovyim, bez zakreplyonnoj postanovki, nablyudeniya i lyuboj vneshnej popyitki. Pervonachaljnyiye resheniye, porucheniye, nomera, puti, kartochki, indeksyi i para Zhurnala sokhranyayutsya. Korrekciya ne menyayet ID, zagolovki i statusyi i ne sozdayot novyikh kartochek.

V privatnom JSON podgotovjte tochnyij kontrakt:

```json
{
  "схема": "fum.исправление-плана-приёма.1",
  "событие": "<SHA-256 события исходного приёма>",
  "ожидаемый_план_sha256": "<канонический SHA-256 исходного объекта файлы>",
  "база": "<полный OID текущего этапа>",
  "ветка": "refs/heads/codex/…",
  "причина": "Исправить обратное отношение по действующему словарю.",
  "файлы": [{
    "путь": "Требования/🟡-существующая-карточка.md",
    "ожидаемый_sha256": "<SHA-256 точных исходных after-байтов>",
    "содержимое": "<полный исправленный UTF-8 текст карточки>"
  }]
}
```

Eto forma kontrakta; znacheniya v uglovyikh skobkakh neobkhodimo zamenitj proverennyimi znacheniyami. Khyesh plana vyichislyayetsya funkciyej `хэш` modulya `приём_направления` ot pervonachaljnogo obyyekta `файлы` sokhranyonnogo priyoma. Polnyij OID tekusjhego etapa peredayotsya yavno i dolzhen proiskhoditj ot iskhodnoj bazyi priyoma. Poka ispravleniye ne zaversheno, yego baza i vetka ne menyayutsya.

Vyizovite iz svoyego checkout:

```text
python3 -B Инструменты/fum-reyestr-planirovaniya/scripts/принять-направление.py --корень-репозитория . --задача <UUID своего корня> исправить-план --исправление <приватный JSON>
```

Do kartochechnyikh effektov komanda sveryayet vesj pervonachaljnyij nabor fajlov, povtorno poluchayet nastoyasjhij otkaz sborsjhika na iskhodnom snimke i sokhranyayet yego vmeste s neizmenyayemyim namereniyem ispravleniya. Eto novoye diagnosticheskoye nablyudeniye, a ne vosstanovlennyij tekst prezhnego otkaza. Zatem otdeljnyimi stadiyami ustanavlivayutsya ispravlennyiye kartochki i proverennyij polnyij reyestr. Toljko posle dolgovechnoj zapisi reyestra priyom stanovitsya gotovyim. Zakrepleniye i dopusk ispoljzuyut ispravlennyiye kartochki, sokhranyaya originalyi kak proiskhozhdeniye.

Posle preryivaniya povtorite **tu zhe komandu s tem zhe JSON** novyim processom. Dopuskayutsya toljko iskhodnyiye i uzhe ustanovlennyiye ispravlennyiye bajtyi; chuzhiye izmeneniya, sdvig bazyi i poyavivshayasya popyitka zakryivayut prodolzheniye. Obyichnaya `подготовить` pri nezavershyonnom ispravlenii ukazyivayet na `исправить-план`. Tochnyij povtor zavershyonnogo ispravleniya pri neizmennom sostoyanii vozvrasjhayet kvitanciyu bez novoj zapisi kartochek. Novoye ispravleniye gotovogo priyoma zapresjheno.

Podderzhana rovno odna korrekciya. Yesli yeyo sobstvennyiye smyislovyiye dannyiye oshibochnyi i reyestr snova otkazyivayet, drugoye ispravleniye avtomaticheski ne prinimayetsya: namereniye i effektyi ostayutsya dostupnyimi dlya otdeljnoj sverki. Ne redaktirujte privatnoye sostoyaniye vruchnuyu i ne vyizyivajte native pri negotovom rezuljtate.

Adresnaya otkryitaya proverka: `python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_исправления_приёма.py`. Neboljshoj profilj: `python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_исправления_приёма.py --выход <профиль.json>`. Oba zapuska vyipolnyayutsya cherez otchyotnuyu obyortku svoyej sessii; setj i vneshnyaya zadacha ne nuzhnyi.

## Adresnaya popravka otobrazheniya osnovaniya

Uzkaya operaciya `исправить-отображение-основания` ispravlyayet rovno odin konechnyij ASCII-probel sintezirovannogo polya `основание` uzhe podgotovlennogo i zakreplyonnogo priyoma. Ona ne menyayet smyisl, chelovecheskuyu komandu, otvet, iskhodnyij plan ili private-zapisj priyoma. Tekusjhij HEAD i sobstvennyij ref dolzhnyi sovpadatj s iskhodnyim bind; vneshnyaya popyitka yesjhyo ne dolzhna susjhestvovatj. Povtornoye `подготовить` starogo priyoma posle popravki ostayotsya zakryityim otkazom na izmenyonnom otobrazhenii: prezhnyaya para proveryayetsya po iskhodnomu kommitu, yeyo diapazonyi ne vyidayutsya za novyiye.

Privatnyij JSON soderzhit toljko sleduyusjhiye polya:

```json
{
  "схема": "fum.поправка-отображения-основания.1",
  "событие": "<SHA-256 исходного события>",
  "база": "<полный OID закреплённого коммита>",
  "ветка": "refs/heads/codex/…",
  "роль": "основание",
  "свидетельство": {"путь": "Журнал/<исходный этап>/отчёт.md", "начало": 1, "конец": 2, "sha256": "<исходный SHA-256 диапазона>"},
  "после_sha256": "<SHA-256 того же основания без единственного конечного ASCII-пробела>",
  "запрос": "Журнал/<новый этап>/запрос.md",
  "причина": "Адресное исправление производного отображения с сохранением исходного свидетельства.",
  "исходный_отказ": {"путь": "Журнал/<исходный этап>/материалы/запуски-проверок/<номер_UUID>.json", "sha256": "<SHA-256 неизменной записи>", "идентификатор": "<UUID запуска>", "код": 2}
}
```

Vse oboznachennyiye znacheniya, vklyuchaya pozicii, zamenyayutsya proverennyimi faktami. Soderzhimoye fajla na zamenu vkhod ne prinimayet. Novyiye bajtyi vyichislyayutsya toljko iz obyichnogo Git blob zakreplyonnogo kommita udaleniyem poslednego `0x20` prinyatogo diapazona; vesj ostaljnoj otchyot dolzhen pobajtno sovpadatj. Proveryayutsya rolj, tochnyij diapazon, oba khyesha, iskhodnoye sintezirovannoye pole i polnyij manifest bind.

Komanda zapuskayetsya iz svoyego checkout:

```text
python3 -B Инструменты/fum-reyestr-planirovaniya/scripts/принять-направление.py --корень-репозитория . --задача <UUID своего корня> исправить-отображение-основания --поправка <приватный JSON>
```

Novyij etap Zhurnala dolzhen uzhe susjhestvovatj. V nyom sokhranyayetsya kvitanciya `материалы/поправка-основания-<событие>.json` s iskhodnyim sobyitiyem i manifestom, tochnyimi before/after-khyeshami, roljyu, diapazonom, prichinoj i neizmennyim izvestnyim kodom 2. Operaciya ispoljzuyet susjhestvuyusjhij kontrakt otdeljnoj fajlovoj stadii `этапы`; versiya i polya obsjhego khranilisjha ne menyayutsya, staryiye potrebiteli prodolzhayut yego chitatj. Iskhodnyiye E0, yego stadii, postanovka i zapisi proverok sokhranyayutsya. Ni nomera, ni native, ni obrabotka 0177 ne zapuskayutsya.

Otkaz zakryivayet inoj diff, druguyu rolj ili bazu, chelovecheskij tekst, nezavershyonnoye vozobnovleniye otchyota, podgotovlennyij libo zakryityij snimok, aktivnuyu zapisj proverki, izmeneniye sostava prezhnikh proverok, kolliziyu kvitancii, simlink ili hardlink. Pod obsjhim zamkom povtorno proveryayutsya drugiye potrebiteli togo zhe fizicheskogo otchyota. Odinakovyij otnositeljnyij putj v nezavisimom worktree sam po sebe ne yavlyayetsya etim fajlom. Svyazannyiye posledniye zapisi 0177 blokiruyut popravku nezavisimo ot polya aktualjnosti, vklyuchaya `отменено`; povrezhdeniye ili usecheniye istorii takzhe ne dokazyivayet otsutstviye svyazi. Proveryayutsya tekusjhiye istorii i ikh versii v iskhodnom kommite.

Posle preryivaniya povtoryayetsya tot zhe JSON pri tom zhe HEAD. Toljko sobstvennaya sokhranyonnaya stadiya razreshayet before/after; tretji bajtyi, novoye namereniye i sdvig nezavershyonnoj bazyi otklonyayutsya. Zavershyonnaya stadiya prinimayet toljko tochnyij after, bez vosstanovleniya iskhodnogo probela. Obyichnoye posleduyusjheye obnovleniye recency yavlyayetsya otdeljnoj proizvodnoj zapisjyu i ne vyidayotsya za pobajtovyij povtor etoj operacii. Polnyij otchyot ne perestraivayetsya. Priyomka novogo etapa proveryayet nastoyasjhij summarnyij `git diff --check <исходная L> <новый C>`, sokhranyaya prezhnij neuspekh v C0.

Adresnyiye proverki: `python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_отображения_основания.py`. Malyij profilj: `python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_отображения_основания.py --выход <профиль.json>`. Oba vyizova vyipolnyayutsya otchyotnoj obyortkoj novogo etapa. Etot putj ne sluzhit obsjhim redaktorom svideteljstv i ne ustranyayet smyislovyiye raskhozhdeniya staroj postanovki.

## Vneshnyaya granica Codex

Sokhranyonnyij `адаптер-codex.js` ispolnyayetsya sredoj, imeyusjhej tri yavno predostavlennyiye vozmozhnosti. `подготовить` vyizyivayet odnorazovuyu komandu `допустить`; `исполнить` peredayot yeyo argumentyi oficialjnomu `create_thread` libo `send_message_to_thread` soglasno sokhranyonnoj operacii; `сохранить` sokhranyayet polnyij otvet cherez odnoimyonnuyu CLI-komandu. Do sozdaniya proyekt proveryayetsya oficialjnyim `list_projects`, vklyuchaya `isGitRepository`. Eto interfejs vozmozhnostej sredyi, ne otdeljnyij Node-servis s dostupom k vnutrennej baze Codex.

Modelj i rassuzhdeniye peredayutsya yavno: `gpt-6-astra`, `ultra`. Novaya zadacha ispoljzuyet worktree i `startingState` s zakreplyonnyim ref. Pervoye porucheniye soderzhit putj postanovki, polnyij kommit i komandu rannego podtverzhdeniya. Nachaljnyij kommit beryotsya odnovremenno iz nativnoj metainformacii JSONL i tekusjhego chistogo dereva; posle nachala rabotyi on ne vosstanavlivayetsya po pozdnemu HEAD. Pozdneye chteniye trebuyet uzhe sokhranyonnogo rannego podtverzhdeniya.

Pri preryivanii mezhdu sokhraneniyem popyitki i otvetom povtor vozvrasjhayet prezhnyuyu popyitku s `разрешён_вызов: false`. Ne vyizyivajte instrument snova po otsutstviyu zadachi v kratkom spiske. Sokhranyonnyij `clientThreadId` oznachayet nezavershyonnoye sozdaniye. Svyazyivaniye rezuljtata trebuyet tochnogo pervonachaljnogo nativnogo porucheniya ot svoyego kornya i rannego podtverzhdeniya bazyi, a ne odnogo pokhozhego nazvaniya. Yesli eti svideteljstva nedostupnyi, iskhod ostayotsya neizvestnyim.

Fajlyi privatnogo sostoyaniya i polnyiye JSONL ne publikuyutsya. Dopustimyij itog nablyudeniya zapisyivayetsya v sleduyusjhij otkryityij otchyot svoyej zadachi; ni sozdaniye zadachi, ni priyom yeyo postanovki ne oznachayet ispolneniya vsego predmetnogo obyazateljstva 0201.

## Lokaljnaya proverka

Iz kornya FUM zapustite adresnyij nabor cherez otchyotnuyu obyortku svoyej rabochej sessii:

```text
python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_приём_направления.py
```

Profilj na otkryitom vkhode zapuskayetsya komandoj:

```text
python3 -B Инструменты/fum-reyestr-planirovaniya/scripts/измерить-приём.py --выход <профиль.json>
```

On sozdayot vremennyij Git-repozitorij s 40 kommitami i izmeryayet 12 raznyikh vyidach paryi STEP/REQ i 12 povtorov. Podgotovka ne vklyuchena. Sam JSON soderzhit iskhodnyiye intervalyi, versiyu Python i SHA realizacii; fikstura ne trebuyet seti i sekretov.

## Sokhranyayemyiye granicyi

Sostoyaniye nakhoditsya v otdeljnom privatnom kataloge vnutri fakticheskogo Git common-dir. Vse svyazannyiye worktree poluchayut odin fajl sostoyaniya i postoyannyij otdeljnyij fajl `flock`. Skaniruyutsya dostupnyiye vetki i ikh dostizhimaya istoriya, vklyuchaya kartochki, vpervyiye dobavlennyiye sliyaniyem. Sdvig spiska refs trebuyet novogo chteniya. Proverennyij snimok istorii povtorno ispoljzuyetsya toljko pri sovpadenii vsekh refs/OID i SHA realizacii. Ischeznoveniye kartochki ili vetki ne osvobozhdayet uzhe uchtyonnyij nomer.

Ruchnoj rezerv importiruyetsya s proiskhozhdeniyem i ostayotsya zanyatyim. Vyideleniye gruppyi nomerov vozvrasjhayetsya toljko posle zapisi, sinkhronizacii fajla, atomarnoj zamenyi i sinkhronizacii kataloga. Povrezhdyonnyij ili ischeznuvshij zhurnal ne sbrasyivayetsya. Zasjhita ne obesjhayet obnaruzhitj soglasovannuyu zamenu vsekh privatnyikh svideteljstv vladeljcem mashinyi i ne koordiniruyet nezavisimyiye klonyi ili ruchnyikh pisatelej, obkhodyasjhikh protokol.

Vneshnyaya popyitka sokhranyayetsya do vyizova. Pri neizvestnom iskhode novoye sozdaniye zapresjheno; sokhraneniye togo zhe poluchennogo otveta mozhno povtoritj. Proverki istochnika i kommita vyipolnyayutsya pod tem zhe zamkom do pervoj popyitki. Nezavisimyij pisatelj JSONL ne uchastvuyet v etoj tranzakcii: atomarnostj intervala ot poslednego chteniya do vneshnego API ne zayavlyayetsya.

Fajlovaya stadiya snachala sokhranyayet tochnyij plan iskhodnyikh i budusjhikh bajtov. Posle preryivaniya ona dopuskayet toljko eti dva sostoyaniya kazhdogo fajla; neozhidannyiye izmeneniya trebuyut sverki. Proverka kommita chitayet vse ozhidayemyiye fajlyi iz yego dereva: chastichnyij kommit ne yavlyayetsya polnoj postavkoj. Avtomatizaciya ne kommitit i ne publikuyet Git sama.

## Istochniki

- [Adresnaya popravka proizvodnogo osnovaniya](../../Zhurnal/2026-09-11_18-02-02_MSK_ispravitj-otobrazheniye-osnovaniya-priyoma/zapros.md).

- [Iskhodnyiye komandyi i obyyom](../../Zhurnal/2026-09-11_01-40-19_MSK_avtomatizirovatj-priyom-napravlenij-FUMA/zapros.md).
- [Kartochka obsjhego ispolnitelya](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0201-avtomatizirovatj-priyom-napravlenij-FUMA.md).
- [Kommit postanovki, rannyaya baza i adapter](../../Zhurnal/2026-09-11_03-32-33_MSK_svyazatj-priyom-s-kommitom-postanovki/zapros.md).
- [Podtverzhdyonnyij pervyij matematicheskij zapusk](../../Zhurnal/2026-09-11_05-03-47_MSK_podtverditj-matematicheskij-zapusk/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:06:10 MSK -->
<!-- content-sha256: sha256:f0fdd99c98aec55af1a4642ff380a06d9bdfa8270bc6fa2d609c48c27f1a063f -->
<!-- FUM-MD-RECENCY:END -->
