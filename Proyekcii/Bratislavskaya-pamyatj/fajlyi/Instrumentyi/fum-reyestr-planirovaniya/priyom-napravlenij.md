# Priyom napravlenij FUMA

Priyom svyazyivayet podtverzhdyonnoye soobsjheniye, smyislovoye resheniye, sobstvennyij Zhurnal, unikaljnyiye nomera i kartochki s odnoj vneshnej popyitkoj Codex. Pervyij realjnyij priyom matematicheskogo napravleniya podtverzhdyon: sokhranenyi oficialjnyij otvet, tochnoye nachaljnoye porucheniye i ranneye nablyudeniye bazyi novoj zadachi. Itogovaya priyomka obsjhego obyyoma FUM-STEP-0201 svyazyivayetsya s [zakryityim dopuskom i sokhranyonnyim obyazateljstvom](../../Zhurnal/2026-09-11_10-00-32_MSK_zavershitj-priyom-napravlenij-FUMA/otchyot.md); predmetnyij rezuljtat kazhdoj sozdannoj zadachi prinimayetsya otdeljno.

## Obyichnyij zapusk

Rabotajte v svoyom worktree, v sobstvennoj vetke `codex/…` i otkryitoj rabochej sessii Zhurnala. Dlya nachala sleduyusjhej sessii ispoljzuyetsya obyichnyij `start` avtomatizacii strukturyi papok zaprosov. Zakryityij otchyot ne vozobnovlyayetsya.

Podgotovjte privatnyij JSON vkhoda vne publikuyemogo checkout. On soderzhit putj pervichnogo JSONL, UUID iskhodnoj zadachi, resheniye, otnositeljnyij putj sobstvennogo zaprosa, spisok sozdavayemyikh ili obnovlyayemyikh kartochek i raneye soglasovannyiye nomera libo `null`. Resheniye skhemyi `fum.решение-приёма.1` ssyilayetsya na konkretnyij ekzemplyar soobsjheniya i polnyij rassmotrennyij kontekst 0177. Agent otdeljno opredelyayet aktualjnostj, pozdniye utochneniya, smyisl otveta, predmetnyij obyyom i yavnoye razresheniye novoj zadachi. Avtomatizaciya ne vyivodit eti resheniya iz klyuchevyikh slov.

Komanda `Инструменты/fum-reyestr-planirovaniya/scripts/принять-направление.py` prinimayet obsjhiye parametryi `--корень-репозитория` i `--задача`, zatem odnu operaciyu:

| Operaciya | Dopolniteljnyiye parametryi | Rezuljtat |
| --- | --- | --- |
| `подготовить` | `--вход` | Tochnaya para v Zhurnale, kartochki, indeksyi i mashinnyij reyestr; sokhranyonnoye sobyitiye i svideteljstva |
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

Yesli v novom trebovanii propusjhena obyazateljnaya stroka statusa, podderzhana toljko yeyo strogaya vstavka: `Статус требования — ` s prezhnim emodzi iz imeni fajla v obratnyikh kavyichkakh i tochkoj, zatem pustaya stroka. Ona stanovitsya pervoj strokoj yedinstvennogo razdela s tochnyim zagolovkom `## Статус и границы` i pustoj strokoj posle zagolovka. Vse prezhniye bajtyi kartochki sokhranyayutsya. Susjhestvuyusjhaya ili povrezhdyonnaya deklaraciya, inoj emodzi, povtor razdela, skryitaya razmetka i izmeneniye granic otklonyayutsya. Etot ogranichennyij putj prednaznachen dlya obyichnogo Markdown bez HTML-razmetki, uglovyikh skobok i ograzhdenij koda; mashinnyij ID i zavershayusjhij blok svezhesti dopustimyi. Otkaz do dolgovechnoj zapisi namereniya ne raskhoduyet korrekciyu; posle zapisi razreshyon toljko yeyo tochnyij povtor.

Dlya etogo puti takzhe otklonyayutsya otdeljnyiye stroki iz defisov ili znakov ravenstva s otstupom do tryokh probelov: oni mogut oformitj yesjhyo odin zagolovok Setext. Ogranicheniye dejstvuyet nezavisimo ot teksta zagolovka i konservativno okhvatyivayet gorizontaljnyiye razdeliteli takogo vida. Obyichnoye ispravleniye s neizmennyim razdelom statusa sokhranyayet prezhnij kontrakt.

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

Dlya izmereniya vosstanovleniya propusjhennoj stroki peredajte profilyu `--сценарий 'пропущенный статус'`. On ispoljzuyet sokhranyonnoye otkryitoye soderzhaniye pervogo trebovaniya finansirovaniya, nastoyasjhij reyestr i tri nezavisimyiye Git-fiksturyi; vlozhennyiye intervalyi proverok granic, reyestra i ustanovki neljzya summirovatj s obsjhim vremenem korrekcii. Bez parametra sokhranyayetsya prezhnij scenarij obratnogo otnosheniya.

## Yavnoye naznacheniye raneye prinyatyikh napravlenij

Odin pozdnij chelovecheskij zapros mozhet naznachitj ot odnogo do shesti raneye sokhranyonnyikh napravlenij. Novyij konechnyij paket ne menyayet prezhneye resheniye s `задача=null`, iskhodnyiye sobyitiya, nomera, kvitancii ili zakryityiye zapisi Zhurnala. Dlya konkretnogo udvoyeniya chisla aktivnyikh derevjyev vyibran rovno nabor 0181, 0216, 0220, 0221, 0165 i 0224. Ispolnitelj ne vyibirayet napravleniya i ne dobirayet novyiye stroki samostoyateljno.

Privatnyij vkhod skhemyi `fum.пакет-отложенных-назначений.1` soderzhit `источник`, `исходная_задача`, obsjheye `решение` prezhnej formyi s `задача=null`, `разрешения`, sobstvennyij `запрос` i massiv `назначения`. Kazhdaya stroka zadayot stabiljnoye `направление`, `исходная_постановка`, `файлы_запуска`, predmetnyiye `объём`, `актуальность`, `поздние`, `ограничения`, soderzhateljnyij `антидубликат` i tochnuyu `задача` s rezhimom `создать`, nablyudyonnyim `projectId`, `title` i polnyim `поручение`. Obsjheye resheniye i razresheniya proveryayutsya po nastoyasjhemu polnomu pervichnomu istochniku; otdeljnyiye stroki yavlyayutsya proizvodnyimi naznacheniyami, a ne dopolniteljnyimi chelovecheskimi soobsjheniyami.

Istoricheskaya postanovka soderzhit tochnyiye `коммит`, `дерево`, `событие`, `сохранённая_запись_sha256` i polnyij slovarj `файлы` s SHA-256. Dlya sokhranyonnogo priyoma trebuyetsya vesj prezhnij manifest i neizmennaya zapisj. Istoricheskij istochnik bez takogo priyoma yavno soderzhit dva `null`; izvestnyij priyom togo zhe kommita neljzya skryitj etim sposobom. Nalichiye zavisimoj kartochki v inoj zadache samo po sebe ne dokazyivayet sovpadeniya predmetnogo naznacheniya. Korenj proveryayet vladeljcev i peresecheniya po dostupnomu polnomu inventaryu i sokhranyayet osnovaniye v `антидубликат`. Vse predmetnyiye iskhodnyiye fajlyi vne istoricheskogo Zhurnala vkhodyat v novyij nabor zapuska; sovremennyiye obsjhiye indeksyi sokhranyayut sobstvennyiye soglasovannyiye versii.

| Operaciya | Parametryi posle obsjhikh `--корень-репозитория` i `--задача` | Rezuljtat |
| --- | --- | --- |
| `предпросмотр-назначений` | `--вход` | Proverennyij konechnyij plan i yego SHA-256 bez sozdaniya kataloga sostoyaniya, zamka, rezervov ili fajlov |
| `подготовить-назначения` | `--вход`, `--ожидаемый-план-sha256` | Neizmenyayemoye namereniye vsego paketa i otdeljnyiye tochnyiye materialyi naznachenij v novom Zhurnale |
| `закрепить-назначения` | `--пакет`, `--коммит`, `--ветка` | Obsjhij novyij kommit zapuska s materialami, tekusjhimi kartochkami, indeksami, reyestrom i ispolnyayemyimi instrumentami |
| `допустить-назначение` | `--вход`, `--направление` | Odna dolgovechnaya popyitka i strukturirovannyiye argumentyi oficialjnogo `create_thread` |
| `сохранить-назначение` | `--пакет`, `--направление`, `--попытка`, `--ответ` | Polnyij neizmenyayemyij otvet MCP; `clientThreadId` ostayotsya ozhidaniyem |
| `наблюдать-назначение` | `--пакет`, `--направление`, `--корень-задачи`, `--идентификатор-задачи`, `--источник` | Proverka tochnogo pervonachaljnogo porucheniya i rannego podtverzhdeniya bazyi novoj zadachi |

Odin ekzemplyar chelovecheskogo soobsjheniya zadayot odin neizmenyayemyij paket. Sostav ne vkhodit v yego klyuch i posle podgotovki ne menyayetsya. Klyuch stroki svyazyivayet paket, stabiljnyij STEP i istoricheskij kommit; novyij kommit zapuska zakreplyayetsya otdeljno i odnokratno. Zamena iskhodnogo ili novogo kommita posle namereniya libo neizvestnogo vneshnego iskhoda ne sozdayot novoj popyitki. Pered pervyim vneshnim vyizovom proverenyi vse stroki, a pered kazhdyim novyim dopuskom povtorno proveryayutsya vesj paket, aktualjnostj istochnika i uderzhivayemaya vetka. Kod ne vyizyivayet MCP: poluchennyiye argumentyi peredayot oficialjnyij instrument tekusjhego kornya, zatem polnyij otvet sokhranyayetsya otdeljnoj komandoj.

Posle preryivaniya tochnyij povtor prodolzhayet ustanovku toljko ozhidayemyikh bajtov; zakryityij Zhurnal ne vozobnovlyayetsya. Posle sokhraneniya popyitki povtor vozvrasjhayet `разрешён_вызов=false` dazhe pri neizvestnom rezuljtate. Ostaljnyiye yesjhyo ne dopusjhennyiye stroki mogut poluchitj svoi pervyiye popyitki. Vetka obsjhego zapuska uderzhivayetsya do rannego nablyudeniya vsekh sozdannyikh zadach. Susjhestvuyusjhaya operaciya `подтвердить-начало` vnutri kazhdoj novoj zadachi sokhranyayetsya bez izmeneniya. Protivorechivyiye identifikatoryi polnogo otveta ili nesovpadeniye pervonachaljnogo porucheniya ne prinimayutsya za nablyudeniye.

Adresnyiye proverki nakhodyatsya v `tests/test_отложенных_назначений.py`. Malyiye vremennyiye Git/JSONL-fiksturyi proveryayut realjnyiye granicyi khranilisjha i processyi CLI; otdeljnyiye testyi izoliruyut sborsjhik reyestra i istochnik ispolnyayemogo koda, poetomu sami eti podstanovki ne dokazyivayut gotovnostj polnogo rabochego checkout. Ni podgotovka paketa, ni sozdaniye zadach ne zavershayet predmetnyiye obyazateljstva.

Komanda `python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_отложенных_назначений.py --выход <профиль.json>` cherez otchyotnuyu obyortku izmeryayet tri otdeljnyiye podgotovki shesti sinteticheskikh naznachenij. V profilj vkhodyat predprosmotr, pervaya podgotovka, tochnyij povtor i vlozhennyiye granicyi chteniya istochnika, proverki istoricheskikh manifestov i dolgovechnoj ustanovki. Metki vyizyivayut nastoyasjhiye funkcii; proveryayutsya ravenstvo povtora, tochnyiye shestj fajlov i otsutstviye vneshnikh popyitok. Sozdaniye fiksturyi, zakrepleniye kommita i vneshnij MCP ne vkhodyat v izmeryayemuyu oblastj. Stoimostj neboljshogo JSONL neljzya perenositj na boljshoj rabochij istochnik bez otdeljnogo izmereniya.

## Vyizov oficialjnyikh instrumentov

Sokhranyonnyij `адаптер-codex.js` ispolnyayetsya sredoj, imeyusjhej tri yavno predostavlennyiye vozmozhnosti. `подготовить` vyizyivayet odnorazovuyu komandu `допустить`; `исполнить` peredayot yeyo argumentyi oficialjnomu `create_thread` libo `send_message_to_thread` soglasno sokhranyonnoj operacii; `сохранить` sokhranyayet polnyij otvet cherez odnoimyonnuyu CLI-komandu. Do sozdaniya proyekt proveryayetsya oficialjnyim `list_projects`, vklyuchaya `isGitRepository`. Eto interfejs vozmozhnostej sredyi, ne otdeljnyij Node-servis s dostupom k vnutrennej baze Codex.

Modelj i rassuzhdeniye peredayutsya yavno: `gpt-6-astra`, `ultra`. Novaya zadacha ispoljzuyet worktree i `startingState` s zakreplyonnyim ref. Pervoye porucheniye soderzhit putj postanovki, polnyij kommit i komandu rannego podtverzhdeniya. Nachaljnyij kommit beryotsya odnovremenno iz nativnoj metainformacii JSONL i tekusjhego chistogo dereva; posle nachala rabotyi on ne vosstanavlivayetsya po pozdnemu HEAD. Pozdneye chteniye trebuyet uzhe sokhranyonnogo rannego podtverzhdeniya.

Prilozheniye mozhet podgotovitj novyij worktree s detached HEAD na praviljnom kommite. Posle chteniya marshruta ispolnitelj proveryayet tochnyij OID i chistotu fajlov i indeksa, zatem bez dopolniteljnogo razresheniya sozdayot svobodnuyu sobstvennuyu vetku `codex/…` ot togo zhe OID. Susjhestvuyusjhiye vetki ne peremesjhayutsya. Posle povtornoj sverki OID, polnogo ref, fizicheskogo kornya i chistotyi vyipolnyayetsya `подтвердить-начало` s pervonachaljnyim JSONL; toljko posle uspekha sozdayotsya Zhurnal i nachinayutsya soderzhateljnyiye zapisi. Otkaz prezhdevremennogo podtverzhdeniya iz-za otsutstviya symbolic ref sokhranyayetsya, yesli takoj vyizov uzhe proizoshyol. Nesovpadeniye nachaljnogo kommita ili chuzhiye izmeneniya trebuyut otdeljnoj sverki.

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

- [Iskhodnyiye komandyi i obyyom](../../Zhurnal/2026-09-11_01-40-19_MSK_avtomatizirovatj-priyom-napravlenij-FUMA/zapros.md).
- [Kartochka obsjhego ispolnitelya](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0201-avtomatizirovatj-priyom-napravlenij-FUMA.md).
- [Kommit postanovki, rannyaya baza i adapter](../../Zhurnal/2026-09-11_03-32-33_MSK_svyazatj-priyom-s-kommitom-postanovki/zapros.md).
- [Podtverzhdyonnyij pervyij matematicheskij zapusk](../../Zhurnal/2026-09-11_05-03-47_MSK_podtverditj-matematicheskij-zapusk/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 01:09:27 MSK -->
<!-- content-sha256: sha256:84c1213704f5cb59000f83779e2c8e89ca1d32921ea926c8d65675561328b4d7 -->
<!-- FUM-MD-RECENCY:END -->
