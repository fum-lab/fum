# Privatnyij komplekt perekhvata zaversheniya

[Podgotovka](scripts/podgotovitj-komplekt-zaversheniya.py) izvlekayet odinnadcatj iskhodnikov iz odnogo tochnogo Git commit, sokhranyayet ikh iyerarkhiyu i pechatayet proveryayemogo kandidata Stop. Ona ne ustanavlivayet nastrojki, ne menyayet Trust, ne zapuskayet poluchennyij project-kod i ne sozdayot sostoyaniye realjnoj zadachi.

Versiya `fum.комплект-Stop.3` dobavlyayet k prezhnim vosjmi iskhodnikam obrabotchik soobsjhenij, chitatelj JSONL i klassifikator proiskhozhdeniya. Vse odinnadcatj fajlov proveryayutsya celikom. Staryiye sokhranyonnyiye komandyi versij 1/2 vklyuchayut sobstvennyij zagruzchik i ne perepisyivayutsya. Dlya novogo dopuska podgotovjte otdeljnyij komplekt versii 3 s yavnyim istochnikom JSONL; staraya skhema ne prinimayetsya kak novaya.

## Vkhod i rezuljtat

Obyazateljnyi polnyij 40-znachnyij lowercase commit OID, absolyutnyiye istochnik, privatnoye khranilisjhe, interpretator, derevo dannyikh guard, fakticheskij cwd zadachi i katalog sostoyaniya; otdeljno peredayutsya UUID i konkretnyiye otnositeljnyiye fajlyi progressa. Neobyazateljnyij plan takzhe otnositelen derevu dannyikh. `--источник` zadayot fizicheskij absolyutnyij checkout iskhodnogo koda, a obyazateljnyij `--исходник` — absolyutnyij JSONL kornevoj zadachi. Neobyazateljnyij `--кэш` ostayotsya privatnyim vne Git. Nedostupnyij JSONL ne chitayetsya pri podgotovke, chtobyi ne narushitj prioritet ostanovki poljzovatelya v guard. Sokrasjhyonnyiye OID, refs, tegi vmesto commit i format Git SHA-256 ne prinimayutsya.

Khranilisjhe zadayotsya vne lyubogo obnaruzhennogo Git-predka: zapresjhenyi `.git` lyubogo tipa i konservativno raspoznavayemyij bare-layout. Vse komponentyi privatnogo puti proveryayutsya bez simvolicheskikh ssyilok; roditelj dolzhen susjhestvovatj. Samo khranilisjhe sozdayotsya 0700 libo prinimayetsya s uzhe tochnyimi pravami i vladeljcem. Susjhestvuyusjheye poljzovateljskoye sostoyaniye ne ispravlyayetsya radi podgotovki.

Komanda zapuskayetsya iz sobstvennogo checkout. Nizhe vse uglovyiye oboznacheniya — plejskholderyi, ne gotovyiye mashinnyiye puti:

```text
python3 -I -S -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/подготовить-комплект-завершения.py --источник <абсолютный-репозиторий-источника> --commit <полный-OID> --хранилище <приватный-каталог-вне-Git> --интерпретатор <абсолютный-Python> --корень-репозитория <дерево-данных-guard> --ожидаемый-cwd <фактический-cwd-задачи> --codex-thread-id <UUID-задачи> --исходник <абсолютный-JSONL-задачи> --каталог-состояния <приватное-состояние-вне-Git> --файл-прогресса <относительный-результат>
```

Stdout soderzhit JSON so skhemoj `fum.кандидат-комплекта-Stop.3`, putyom komplekta, SHA-256 manifesta, samim manifestom, kandidatom `hooks` i spravochnyim SHA-256 zagruzchika. Vyivod soderzhit lokaljnyiye puti: yego sleduyet khranitj privatno, a ne bez proverki publikovatj v FUM. Pri otkaze stdout pust, kod 2 i ogranichennaya po naznacheniyu diagnostika v stderr; podgotovka ne vyidayot otkaz za gotovogo kandidata.

Manifest svyazyivayet commit, tree, odinnadcatj putej, iskhodnyiye blob OID, rezhim Git 100644, privatnyij rezhim 0400, razmer, SHA-256 i konfiguraciyu vyipolneniya. Bajtyi ne preobrazuyutsya. Itogovyij katalog imenuyetsya `stop-<SHA256-манифеста>`, katalogi vnutri imeyut 0500. Pomimo odinnadcati `.py` razreshyon toljko `манифест.json` 0400 i neobkhodimyiye katalogi. Odnoimyonnaya povrezhdyonnaya celj ne remontiruyetsya i ne zamenyayetsya; ispravleniye trebuyet otdeljnogo resheniya cheloveka.

## Proverka do ispolneniya

Privatnyiye predki dolzhnyi prinadlezhatj tekusjhemu UID libo sisteme. Zapisj gruppyi/prochikh dopustima toljko u takogo doverennogo predka so sticky-bit; obyichnyij world-writable predok otklonyayetsya. Eto sokhranyayet dopustimostj standartnogo obsjhego vremennogo kataloga, ne razreshaya drugomu vladeljcu zamenyatj privatnuyu cepochku.

Pri izvlechenii proveryayutsya SHA-1 samogo commit, kazhdogo promezhutochnogo tree i konechnyikh blobs. Sleduyusjhij OID beryotsya iz uzhe proverennyikh binarnyikh bajtov roditeljskogo tree; vyivod `ls-tree` ne sluzhit samostoyateljnyim dokazateljstvom cepochki. Proverka ne polagayetsya na avtomaticheskuyu sverku SHA pri obyichnom chtenii Git-obyyekta. Eto ogranicheniye provereno sinteticheskoj staticheskoj podmenoj subtree i soglasuyetsya s [putyom chteniya obyyektov Git 2.54](https://raw.githubusercontent.com/git/git/v2.54.0/object-file.c).

Granica privatnogo puti takzhe otklonyayet administrativnyij katalog `HEAD + commondir`, ne chitaya soderzhimoye `commondir` i ne perekhodya po nemu: Git podderzhivayet vyinesennyij obsjhij katalog obyyektov, chto zakrepleno v [raspoznavanii Git-kataloga](https://raw.githubusercontent.com/git/git/v2.54.0/setup.c). Proverka konservativnaya: pokhozhij sluzhebnyij layout tozhe otklonyayetsya.

Doveryayemaya command soderzhit vesj inline-zagruzchik, bukvaljnyij SHA-256 manifesta, tochnyij putj komplekta i UUID. Ona ispoljzuyet `exec`, ochisjhennoye okruzheniye `env -i`, fiksirovannyij `PATH` i absolyutnyij nastoyasjhij Python s `-I -S -B`. Podstanovka putej vyipolnyayetsya cherez `shlex.join`, vklyuchaya kavyichki i znaki obolochki. Flagi izolyacii dochernego guard dolzhnyi byitj uzhe vklyuchenyi v iskhodnyij adapter commit; vneshnij `-S` sam po sebe ne nasleduyetsya rebyonkom.

Zagruzchik do ispolneniya project-koda sveryayet zakryituyu skhemu manifesta, polnyij inventarj, vladeljca, tochnyiye rezhimyi, obyichnyij tip fajlov, chislo zhyostkikh ssyilok 1, razmeryi, SHA-256 i Git blob SHA-1. Kazhdyij iskhodnik ogranichen 1 MiB, manifest — 64 KiB. Lishniye `.py`, `.pyc`, `__pycache__`, neizvestnyiye fajlyi i katalogi, ssyilki, specfajlyi i nevernyiye polya oznachayut otkaz. Adapter ispolnyayetsya cherez `compile/exec` iz uzhe prochitannyikh proverennyikh bajtov s nastoyasjhim `__file__`. Sosedniye moduli nakhodyatsya po sokhranyonnoj iyerarkhii:

- `scripts/перехватить-завершение.py`;
- `scripts/проверить-продолжение-задачи.py`;
- `scripts/обработка_сообщений.py`, `scripts/сообщения_задачи.py` togo zhe navyika;
- `Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py`;
- `scripts/обязательства_задачи.py`, `scripts/обязательства_задачи_v2.py` i `scripts/история_пути_гита.py` togo zhe navyika;
- `Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py`, `закрытый_отчёт_из_гита.py` i `связь_отпечатка_с_коммитом.py` v tom zhe kataloge otchyotnoj obyortki.

Uspeshnyij zagruzchik ne chitayet stdin, ne dobavlyayet sluzhebnyij stdout i ne perekhvatyivayet `SystemExit` adaptera. Toljko pri sobstvennom otkaze on chitayet ne boleye 65 536 bajtov za odnu sekundu: dokazannyij UUID+Stop poluchayet diagnosticheskoye `continue:false`, neizvestnoye ili chuzhoye sobyitiye — lishj `systemMessage`. Eto ne utverzhdeniye vyipolneniya obyazateljstv. Signalyi i otkaz samogo interpretatora ne prevrasjhayutsya v fiktivnyij uspeshnyij JSON.

Podgotovka serializuyet publikaciyu cherez privatnyij `flock`, sobirayet otdeljnyij vremennyij katalog, proveryayet yego, sinkhroniziruyet i pereimenovyivayet. Povtor prinimayet susjhestvuyusjhij komplekt toljko posle polnoj proverki, ne menyaya yego bajtyi, prava i mtime. Ostatki avarijnoj podgotovki avtomaticheski ne razyiskivayutsya i ne udalyayutsya. Neuspeshnyij tekusjhij vremennyij katalog ubirayetsya toljko po izvestnomu sobstvennomu puti.

## Granica doveriya i vklyucheniya

Trust opredeleniya zakreplyayet stroku s zagruzchikom i khyeshem manifesta, no ne yavlyayetsya globaljnyim doveriyem vsem budusjhim bajtam po puti. Interpretator, yego stdlib, OS i vyibrannyij Git ostayutsya vneshnej doverennoj osnovoj; ikh bajtyi manifest ne attestuyet. Provereno na POSIX macOS, Python 3.14.7 i Git 2.54.0; zagruzka stdlib trebuyet Python 3.11 ili noveye. Proverka tipov/rezhimov ne zayavlyayet zasjhitu ot zlonamerennoj konkurentnoj podmenyi tem zhe UID. Read-only rezhimyi ne yavlyayutsya neizmenyayemyimi flagami OS.

Privatnyij komplekt ne zamenyayet dannyiye guard: reyestr, plan, kartochki i Git-obyyektyi chitayutsya iz otdeljno naznachennogo nastoyasjhego dereva. Mezhdu proverkoj i lenivyim chteniyem sosednego koda ne zayavlyayetsya zasjhita ot atak vladeljca fajlov. Sostoyaniye i native Trust takzhe ne vkhodyat v manifest; ogranicheniye prodolzhenij ostayotsya obyazannostjyu adaptera.

Koordinator otdeljno proveryayet vyivod, vyibrannyij commit, odinnadcatj SHA, fakticheskij cwd, puti, limityi i dejstvuyusjhij sloj nastroyek. Zatem chelovek doveryayet konkretnomu opredeleniyu v shtatnoj poverkhnosti Codex. Eta avtomatizaciya ne pishet `hooks.json`, `trusted_hash`, poljzovateljskiye nastrojki ili chuzhoj checkout. Imya otdeljnogo iskhodnogo primera u koordinatora — `Stop.hooks.шаблон.json`; dlya podgotovki on ne yavlyayetsya ispolnyayemyim vkhodom.

## Vosproizvodimyiye proverki

[Adresnyij nabor](tests/test_komplekt_zaversheniya.py) ispoljzuyet toljko vremennyiye sinteticheskiye Git-repozitorii. [Skvoznoj scenarij i profilj](scripts/proveritj-komplekt-zaversheniya.py) prinimayet `--источник` i tochnyij `--commit`, izvlekayet fiksturyi togo zhe commit i proveryayet shestj iskhodov realjnogo guard cherez podgotovlennyiye komplektyi. Dlya kazhdogo iskhoda izmerenyi pervyij process podgotovki, idempotentnyij povtor, tri goryachikh processa s guard i pyatj otdeljnyikh proverok celostnosti. Izmeritelj pechatayet toljko sinteticheskiye rezuljtatyi i khyeshi; vremennyiye absolyutnyiye puti v otchyot ne vkhodyat.

Oba scenariya zapuskayutsya cherez [otchyotnuyu obyortku](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) sobstvennogo etapa. Testyi i profilj ne ustanavlivayut native hook i ne dokazyivayut nablyudeniye realjnoj sleduyusjhej iteracii modeli v tom zhe `run_turn`. Kontroljnaya tochka s chistyim Git takzhe ne zamenyayet etu otdeljnuyu chelovecheskuyu priyomku.

Po peredannomu auditu zakreplyonnogo runtime blokirovka sokhranyayetsya kak `response_item` s `HookPrompt role=user`, zatem prodolzhayetsya tot zhe `run_turn`, bez novogo `TurnStarted`. `HookStarted/Completed` ne sokhranyayutsya v JSONL i ignoriruyutsya `thread_history`. Rolj `user` takogo sluzhebnogo soobsjheniya ne dokazyivayet chelovecheskoye proiskhozhdeniye ili novyiye polnomochiya; tochnuyu klassifikaciyu i native nablyudeniye vyipolnyayet koordinator. Podgotovitelj ne ispoljzuyet eti soobsjheniya kak vkhod.

## Proiskhozhdeniye

- [Zapros podgotovki](../../Zhurnal/2026-09-09_13-23-25_MSK_podgotovitj-privatnyij-komplekt-zaversheniya/zapros.md).
- [Otchyot, TDD i syiryiye izmereniya](../../Zhurnal/2026-09-09_13-23-25_MSK_podgotovitj-privatnyij-komplekt-zaversheniya/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:33:08 MSK -->
<!-- content-sha256: sha256:7a62205cd748fcfcbe561b9273d6b1d1585d50641e7724f4f08e1b61b3b58a00 -->
<!-- FUM-MD-RECENCY:END -->
