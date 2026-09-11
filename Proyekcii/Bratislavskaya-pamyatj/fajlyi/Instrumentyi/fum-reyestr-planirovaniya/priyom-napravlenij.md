# Priyom napravlenij FUMA

Priyom svyazyivayet podtverzhdyonnoye soobsjheniye, smyislovoye resheniye, sobstvennyij Zhurnal, unikaljnyiye nomera i kartochki s odnoj vneshnej popyitkoj Codex. Realizaciya proveryayetsya v FUM-STEP-0201; pervyij realjnyij matematicheskij zapusk i okonchateljnaya priyomka yesjhyo ne zavershenyi. Otkryityiye fiksturyi podtverzhdayut mestnuyu mekhaniku i ispolneniye adaptera, no ne podmenyayut nablyudeniye nastoyasjhej novoj zadachi.

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

## Vneshnyaya granica Codex

Sokhranyonnyij `адаптер-codex.js` ispolnyayetsya sredoj, imeyusjhej tri yavno predostavlennyiye vozmozhnosti. `подготовить` vyizyivayet odnorazovuyu komandu `допустить`; `исполнить` peredayot yeyo argumentyi oficialjnomu `create_thread` libo `send_message_to_thread` soglasno sokhranyonnoj operacii; `сохранить` sokhranyayet polnyij otvet cherez odnoimyonnuyu CLI-komandu. Do sozdaniya proyekt proveryayetsya oficialjnyim `list_projects`, vklyuchaya `isGitRepository`. Eto interfejs vozmozhnostej sredyi, ne otdeljnyij Node-servis s dostupom k vnutrennej baze Codex.

Modelj i rassuzhdeniye peredayutsya yavno: `gpt-6-astra`, `ultra`. Novaya zadacha ispoljzuyet worktree i `startingState` s zakreplyonnyim ref. Pervoye porucheniye soderzhit putj postanovki, polnyij kommit i komandu rannego podtverzhdeniya. Nachaljnyij kommit beryotsya odnovremenno iz nativnoj metainformacii JSONL i tekusjhego chistogo dereva; posle nachala rabotyi on ne vosstanavlivayetsya po pozdnemu HEAD. Pozdneye chteniye trebuyet uzhe sokhranyonnogo rannego podtverzhdeniya.

Pri preryivanii mezhdu sokhraneniyem popyitki i otvetom povtor vozvrasjhayet prezhnyuyu popyitku s `разрешён_вызов: false`. Ne vyizyivajte instrument snova po otsutstviyu zadachi v kratkom spiske. Sokhranyonnyij `clientThreadId` oznachayet nezavershyonnoye sozdaniye. Svyazyivaniye rezuljtata trebuyet tochnogo pervonachaljnogo nativnogo porucheniya ot svoyego kornya i rannego podtverzhdeniya bazyi, a ne odnogo pokhozhego nazvaniya. Yesli eti svideteljstva nedostupnyi, iskhod ostayotsya neizvestnyim.

Fajlyi privatnogo sostoyaniya i polnyiye JSONL ne publikuyutsya. Dopustimyij itog nablyudeniya zapisyivayetsya v sleduyusjhij otkryityij otchyot svoyej zadachi; ni sozdaniye zadachi, ni priyom yeyo postanovki ne oznachayet ispolneniya vsego predmetnogo obyazateljstva 0177.

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
- [Kartochka obsjhego ispolnitelya](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0201-avtomatizirovatj-priyom-napravlenij-FUMA.md).
- [Kommit postanovki, rannyaya baza i adapter](../../Zhurnal/2026-09-11_03-32-33_MSK_svyazatj-priyom-s-kommitom-postanovki/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 05:00:59 MSK -->
<!-- content-sha256: sha256:2e9e6c2efeb052c2dda5787d56bc20aeb365f0b51a771057310bc683dcd6d4d7 -->
<!-- FUM-MD-RECENCY:END -->
