---
name: fum-perenos-rabochikh-derevjyev
description: Stroitj plan bez zapisi i vozobnovlyatj perenos odnogo linked worktree s rekursivnyimi submodule na odnom tome.
---

# Perenos rabochikh derevjyev

Instrument peremesjhayet odin linked worktree celikom i vosstanavlivayet toljko yego Git-privyazki. Otslezhivayemyiye izmeneniya, otdeljnoye sostoyaniye indeksa, neotslezhivayemyiye i ignoriruyemyiye fajlyi sokhranyayutsya. Posle preryivaniya ta zhe komanda prodolzhayet sokhranyonnuyu operaciyu; zavershyonnyij povtor vozvrasjhayet prezhnyuyu kvitanciyu. Realjnyij perenos poljzovateljskikh derevjyev trebuyet otdeljnoj priyomki fakticheskogo dereva i vneshnikh privyazok.

## Podgotovka

Nuzhnyi Python 3.11+ i Git, podderzhivayusjhij `--path-format=absolute` i `--show-object-format`. Sobstvennyiye moduli berutsya iz togo zhe klona FUM: kanonicheskij JSON i chitatelj obyyektov iz `fum-snimki-indeksa`, atomarnyij perenos iz `fum-bratislavskaya-proyekciya-pamyati`. Obyichnyij zapusk perenosa i avtonomnyiye testyi ne trebuyut Swift, LinguisticKit, seti ili sekretov.

Iskhodnyij katalog dolzhen byitj shtatnyim linked worktree s Git-dir v `common-dir/worktrees/<имя>`. Yego submodule dolzhnyi byitj uzhe inicializirovanyi, a ikh Git-dir dolzhnyi nakhoditjsya v `modules/<имя секции>` neposredstvenno pod Git-dir roditelya. Imya sekcii `.gitmodules` mozhet otlichatjsya ot rabochego puti. Vse administrativnyiye katalogi ostayutsya vne peremesjhayemogo dereva.

Do rabotyi vladelec isklyuchayet drugikh pisatelej iskhodnogo dereva i vlozhennyikh repozitoriyev i rezerviruyet derevo shtatnyim `git worktree lock --reason fum-перенос:<UUID-владельца> <исходный-каталог>`. Instrument trebuyet tochnyij tekst etoj rezervacii i sokhranyayet yeyo posle perenosa. UUID i lock-fajl podtverzhdayut soglasovannoye vladeniye; oni ne ostanavlivayut process, kotoryij obkhodit etot protokol i prodolzhayet menyatj fajlyi.

Naznacheniye dolzhno otsutstvovatj. Yego roditelj, common-dir i otdeljnyij privatnyij katalog sostoyaniya dolzhnyi susjhestvovatj na tom zhe tome. Katalog sostoyaniya prinadlezhit tekusjhemu poljzovatelyu, imeyet rezhim `0700` i nakhoditsya vne oboikh rabochikh derevjyev i common-dir. Odin takoj katalog obsluzhivayet rovno odnu operaciyu i sokhranyayetsya posle yeyo zaversheniya.

## Privatnyiye privyazki i otkryityij plan

Podgotovjte vne publikuyemogo checkout JSON s shestjyu polyami:

| Pole         | Znacheniye                                               |
| ------------ | ------------------------------------------------------ |
| `схема`      | `fum.привязки-переноса.1`                              |
| `владелец`   | Kanonicheskij UUID, sovpadayusjhij s prichinoj Git-lock     |
| `источник`   | Tochnyij absolyutnyij fizicheskij korenj linked worktree    |
| `назначение` | Tochnyij absolyutnyij novyij korenj                         |
| `общий`      | Tochnyij absolyutnyij Git common-dir                       |
| `состояние`  | Otdeljnyij susjhestvuyusjhij privatnyij katalog etoj operacii |

Fajl imeyet kanonicheskoye kodirovaniye `канон.кодировать`: UTF-8, sortirovka klyuchej, otsutstviye neobyazateljnyikh probelov i odin zavershayusjhij LF. Dlya podgotovki iz otredaktirovannogo JSON mozhno vyizvatj iz kornya FUM sleduyusjhuyu komandu, peredav privatnyij fajl:

```text
python3 -B -c 'import json,sys; from pathlib import Path; sys.path.insert(0,"Инструменты/fum-snimki-indeksa/scripts"); import канон; путь=Path(sys.argv[1]); путь.write_bytes(канон.кодировать(json.loads(путь.read_text())))' '<приватный файл привязок>'
```

Plan vyivoditsya v stdout. Sam process ne sozdayot fajlov, zamkov ili bytecode i ne menyayet indeks. Perenapravleniye stdout v vyibrannyij fajl vyipolnyayet vyizyivayusjhij:

```text
python3 -B Инструменты/fum-perenos-rabochikh-derevjyev/scripts/перенос.py план --привязки '<приватный файл привязок>' > '<файл плана>'
```

Plan `fum.план-переноса.1` soderzhit vladeljca, identichnostj operacii, khyesh privatnyikh privyazok, khyeshi identichnostej katalogov, iskhodnyiye HEAD, polnyiye refs i indeksyi kazhdogo repozitoriya, otnositeljnyiye marshrutyi Git-dir/common-dir, snimki dannyikh i razreshyonnyij perechenj remonta s khyeshami staryikh i budusjhikh bajtov. On ne raskryivayet fizicheskikh absolyutnyikh kornej. Pri prosmotre sopostavlyajte yego s privatnyim fajlom privyazok: odni khyeshi ne obyyasnyayut cheloveku naznacheniye kataloga.

## Primeneniye i vozobnovleniye

Posle prosmotra zapustite:

```text
python3 -B Инструменты/fum-perenos-rabochikh-derevjyev/scripts/перенос.py применить --привязки '<приватный файл привязок>' --план '<сохранённый файл плана>' --владелец '<UUID-владельца>'
```

Pervyij vyizov zanovo vyivodit plan iz fakticheskogo sostoyaniya. Pod otdeljnyim postoyannyim `flock` sokhranyayetsya namereniye s tochnyimi privatnyimi bajtami remonta; zatem vyipolnyayutsya fazyi `перемещение`, `ремонт`, `сверка`, `завершён`. Pereimenovaniye ne zamenyayet susjhestvuyusjheye naznacheniye. Posle nego snachala sinkhroniziruyetsya roditelj naznacheniya, zatem roditelj istochnika.

Remont ogranichen `.git` perenosimyikh rabochikh katalogov, obratnyim `gitdir` linked worktree i strokami `core.worktree` shtatnyikh submodule. Ostaljnyiye bajtyi konfiguracii sokhranyayutsya. Pered kazhdyim izmeneniyem proveryayutsya dannyiye, indeksyi, HEAD, refs i dopustimyiye staryiye/novyiye bajtyi privyazok. Zamena kazhdogo fajla i prodvizheniye kursora dolgovechnyi. Sosedniye worktree, refs, indeksyi i soderzhimoye primary checkout instrument ne izmenyayet.

Pri preryivanii povtorite **tu zhe komandu s temi zhe fajlami i UUID** novyim processom. V okne posle rename instrument uznayot tot zhe katalog po identichnosti, chitayet Git cherez sokhranyonnyij administrativnyij putj i yavno zadannoye rabocheye derevo, povtorno zakreplyayet katalogi i prodolzhayet remont. Povtornoye peremesjheniye ne vyipolnyayetsya. To zhe otnositsya k poteryannomu otvetu posle zaversheniya.

Kod `0` soprovozhdayetsya JSON-kvitanciyej `fum.результат-переноса.1`. Kod `2` oznachayet yavnyij otkaz. Profilj v stderr otdelyon ot rezuljtata. Pri otkaze sokhranite plan, privyazki i vesj privatnyij katalog sostoyaniya; ne ispravlyajte yego polya vruchnuyu i ne pyitajtesj vosstanovitjsya cherez `clean`, `prune`, `remove`, peresozdaniye worktree ili inicializaciyu submodule. Izmenivshiyesya dannyiye, tretji bajtyi konfiguracii, zanyataya celj i povrezhdyonnyij zhurnal trebuyut otdeljnoj sverki. Yesli do ustanovki `операция.json` ostalsya `подготовка.tmp`, novyij process yavno otkazyivayet i sokhranyayet yego pobajtovo, dazhe kogda fajl pust, polnostjyu zapisan ili soderzhit neizvestnyiye bajtyi. Derevo v etom okne yesjhyo ne peremesjheno. Avtomaticheskoye vozobnovleniye garantiruyetsya toljko posle dolgovechnoj ustanovki pervichnogo namereniya; ochistka rannego ostatka trebuyet otdeljnoj sverki vladeljcem.

## Proverki i profilj

Iz chistogo klona FUM, bez inicializacii vneshnikh zavisimostej:

```text
python3 -B -m unittest discover -s Инструменты/fum-perenos-rabochikh-derevjyev/tests -p 'test_*.py'
python3 -B Инструменты/fum-perenos-rabochikh-derevjyev/tests/профиль.py --выход '<файл измерений.json>' --повторы 3
```

V agentskoj sessii komandyi vyipolnyayutsya cherez otchyotnuyu obyortku svoyego Zhurnala. Fikstura stroit tri sobstvennyikh lokaljnyikh Git-repozitoriya, linked worktree, dva urovnya submodule, raznyiye indeksnyiye/rabochiye bajtyi i ignoriruyemyiye dannyiye. Drajver avarij — otdeljnyij testovyij process; u rabochego CLI net komandyi avarijnogo zaversheniya.

Pervyij RED prerval process posle realjnogo peremesjheniya kataloga i do remonta; novyij process obnaruzhil otsutstviye realizacii vosstanovleniya. GREEN podtverzhdayet vosstanovleniye togo zhe kataloga, sokhraneniye dannyikh, OID, refs i indeksov i tochnyij povtor. Dopolniteljnyiye scenarii proveryayut obe formyi privyazok, otkazyi, konkuriruyusjhij povtor, kazhduyu susjhestvennuyu fazu i otkaz sinkhronizacii posle rename.

Profilj razlichayet sbor plana, povtornuyu proverku, pereimenovaniye, remont, sverku, vozobnovleniye i tochnyij povtor. On sokhranyayet versii sredyi, SHA-256 iskhodnikov i iskhodnyiye intervalyi. Vremya roditelya vklyuchayet detej; intervalyi ne skladyivayutsya povtorno. Iskhodnyij profilj i itog proverki nakhodyatsya v [otchyote realizacii](../../Zhurnal/2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/otchyot.md).

## Granicyi podderzhki

Provereno na macOS arm64, Git 2.54.0 i Python 3.14.7. Linux ispoljzuyet susjhestvuyusjhij `renameat2`-primitiv, odnako sobstvennogo zapuska etogo perenosa na Linux yesjhyo net; podderzhka platformyi ne prinyata. Windows i perenos mezhdu tomami ne podderzhanyi. Fikstura drugogo toma proveryayet otkaz podmenoj nablyudayemogo `st_dev`; ispyitaniye realjnogo vtorogo toma ne zayavlyayetsya.

Podderzhanyi otnositeljnyiye i absolyutnyiye `.git` i `core.worktree`, attached linked korenj i attached/detached shtatnyiye submodule, obyichnyij indeks, lokaljnyiye izmeneniya i UTF-8-imena. Soderzhimoye payload symlink sokhranyayetsya bez perekhoda po nemu; vneshniye otnositeljnyiye ssyilki ne perebaziruyutsya i trebuyut otdeljnoj proverki posle peremesjheniya.

Do perenosa otklonyayutsya neinicializirovannyiye i nestandartnyiye vlozhennyiye repozitorii, bare-korenj, detached linked korenj, konfliktnyij indeks, split/sparse index, yavno zadannyiye `extensions.worktreeConfig`, `core.sparseCheckout` ili `core.splitIndex` (vklyuchaya `false`), vklyucheniya `include/includeIf`, neodnoznachnyij `core.worktree`, Git-lock-fajlyi operacij v administrativnom poddereve vyibrannogo worktree, symlink i kollizii registra v upravlyayusjhikh putyakh, upravlyayusjhiye simvolyi, kavyichka i obratnaya kosaya cherta v putyakh, specialjnyiye fajlovyiye obyyektyi i vlozhennyiye toma. Sharedindex i neshtatnyiye vneshniye Git-dir ne remontiruyutsya.

Modelj predpolagayet dobrosovestnogo yedinstvennogo pisatelya i doverennyij privatnyij katalog sostoyaniya. Nablyudeniya i khyeshi obnaruzhivayut drejf, no ne dayut zasjhityi ot namerennoj soglasovannoj poddelki vsekh svideteljstv tem zhe poljzovatelem ili podmenyi predkov mezhdu proverkoj i sistemnyim vyizovom. Uspeshnyiye processnyiye avarii i `fsync`-fiksturyi ne yavlyayutsya ispyitaniyem otklyucheniya pitaniya libo garantiyej konkretnogo fajlovogo ustrojstva.

Rezuljtat ne menyayet proyektyi Codex i vneshniye prilozheniya. Pered pervyim zhivyim perenosom otdeljno prinimayutsya svezhiye vladelec, rezervirovaniye i polnaya topologiya vyibrannogo dereva, fakticheskij tom, novyij marshrut, vneshniye puti Codex/Obsidian/sborok i sostoyaniye fonovyikh processov. Istoricheskij pul i avtomaticheskoye prodolzheniye ne podklyuchayutsya.

## Istochniki

- [Postanovka FUM-STEP-0207](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0207-realizovatj-perenos-rabochikh-derevjyev.md).
- [FUM-REQ-0066](../../Trebovaniya/🟡-vozobnovlyayemyij-perenos-rabochikh-derevjyev.md).
- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:03:10 MSK -->
<!-- content-sha256: sha256:f7d761a80e67faacff023a6eddc95d04f1cfc37efdc41b43d29600ece6cf9b35 -->
<!-- FUM-MD-RECENCY:END -->
