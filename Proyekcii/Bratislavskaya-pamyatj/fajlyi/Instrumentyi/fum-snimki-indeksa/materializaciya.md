# Materializaciya zakreplyonnyikh bajtov

[Materializator](scripts/materializaciya.py) sozdayot obyichnyiye fajlyi iz povtorno proverennogo `fum.вход-снимка.1`. On nichego ne ispolnyayet, ne sozdayot indeks ili commit i ne razreshayet posleduyusjhij zapusk. Skhemyi vkhoda i dejstvuyusjhego run-v4/report-v3 ne izmenenyi. Zapisj v vyibrannoye naznacheniye razreshayet vyizyivayusjhaya storona; vkhodnoj plan ne yavlyayetsya razresheniyem vyipolnitj sebya.

## Vyizov

Obe komandyi prinimayut parametryi `проверить` iz [osnovnogo kontrakta](kontrakt.md) i dopolniteljno `--назначение <абсолютный путь>` i `--квитанция <абсолютный путь>`:

```text
python3 scripts/снимки-индекса.py --корень-репозитория <точный корень> материализовать --вход <файл> --конверт <файл> --реестр <каталог> --ожидаемый-коммит <полный OID> --ожидаемая-ветка <полный ref> --назначение <новый каталог> --квитанция <соседний файл>
python3 scripts/снимки-индекса.py --корень-репозитория <точный корень> проверить-материализацию --вход <файл> --конверт <файл> --реестр <каталог> --ожидаемый-коммит <полный OID> --ожидаемая-ветка <полный ref> --назначение <готовый каталог> --квитанция <соседний файл>
```

Neobyazateljnyij `--зависимости` peredayot prezhnyuyu lokaljnuyu kartu gitlink. Do materializacii tochnyiye bajtyi vkhoda uzhe zaregistrirovanyi v polnom doverennom reyestre. Oba vyizova zanovo proveryayut iskhodnyij vkhod, HEAD/ref, UUID i dostupnostj Git-obyyektov. Otsutstvuyusjhaya zapisj reyestra dayot otkaz. Polnota reyestra ostayotsya obyazateljstvom vyizyivayusjhej storonyi.

Naznacheniye — novyij neposredstvennyij rebyonok susjhestvuyusjhego kataloga ispolnitelya. Etot roditelj prinadlezhit tekusjhemu UID i imeyet tochnyij rezhim `0700`. Kvitanciya — obyichnyij sosednij fajl, yeyo putj otlichayetsya ot naznacheniya i imeni `<квитанция>.незавершено`. Simvolicheskiye ssyilki v marshrutakh zapresjhenyi. Naznacheniye, kvitanciya i marker ne peresekayut iskhodnyiye checkout, reyestr i realjnyiye git-dir/common-dir/objects vsekh podderzhannyikh zavisimostej. Proveryayutsya takzhe inode susjhestvuyusjhikh predkov, vklyuchaya registrovyiye aliases. Vneshniye Git alternates poka yavno otvergayutsya. Naznacheniye vnutri drugogo nablyudayemogo checkout ili bare Git tozhe zapresjheno.

## Fajlyi i nezavisimaya proverka

Pisatelj chitayet toljko syiryiye blob po polnyim OID, bez checkout, attributes, filjtrov i podstanovki zhivyikh fajlov. Obyichnyiye Git-rezhimyi vosproizvodyatsya kak `0644` i `0755`, katalogi — `0700`. Kazhdyij putj poluchayet novyij otdeljnyij inode. Pustyiye podderevjya sokhranyayutsya. Gitlink razvorachivayetsya po zakreplyonnomu commit/tree i polnomu manifestu obyyektov zavisimosti; yeyo zhivyiye izmeneniya ne uchastvuyut. Arkhiv ostayotsya neprozrachnyim fajlom. Symlink, specialjnyiye fajlyi, vlozhennyiye gitlink i zapresjhyonnyiye puti ne podderzhivayutsya.

Posle zapisi vyipolnyayetsya yesjhyo odna polnaya proverka vkhoda svezhimi chitatelyami Git. Nezavisimyij obkhod zanovo otkryivayet vse fakticheskiye fajlyi, schitayet SHA-256 i dlinu, sveryayet rezhim, vladeljca, `st_nlink == 1`, unikaljnostj inode, tochnyij perechenj fajlov i katalogov. On ne ispoljzuyet kvitanciyu ili buferyi pisatelya kak ozhidayemyiye bajtyi. Povtornyiye proverki imenovannyikh inode, sostava katalogov i mtime/ctime obnaruzhivayut podmenyi vo vremya chteniya. Podmena puti ne perenapravlyayet zapisj vo vneshnij kontroljnyij fajl: operacii ispoljzuyut zakreplyonnyiye deskriptoryi s `O_NOFOLLOW` i isklyuchiteljnyim sozdaniyem.

## Lokaljnaya kvitanciya

Kanonicheskij JSON s obyichnyim SHA-256 v pole `хэш_входа` imeyet tochnyiye polya:

- `схема: fum.материализация-снимка.1`;
- `идентификатор_задачи`, `идентификатор_раунда` iz vkhoda;
- `идентификатор_материализации` — nezavisimo vyivodimyij UUIDv5;
- `хэш_входа`, `дерево_входа`;
- `назначение` — tochnyij lokaljnyij absolyutnyij putj;
- `идентичность_каталога` — celyiye `устройство` i `инод`;
- `файлы` — polnyij massiv obyyektov `путь`, `режим`, `длина`, `хэш_байтов`, otsortirovannyij po bajtam UTF-8 puti;
- `каталоги` — polnyij massiv otnositeljnyikh putej katalogov v tom zhe poryadke, bez kornevogo pustogo puti;
- `исполнение_разрешено: false`, `коммит_разрешён: false`.

UUIDv5 vyichislyayetsya standartnyim `uuid.NAMESPACE_URL` ot UTF-8 teksta kanonicheskogo obyyekta `хэш_входа`, `назначение`, `каталог` s device/inode. Eto vosproizvodimaya metka privyazki, a ne podpisj, istoriya vladeniya inode ili dokazateljstvo polnomochij. Sluchajnyij UUID vremennoj operacii ispoljzuyetsya toljko v markere i imeni podgotoviteljnogo fajla; eto drugaya identichnostj.

Kvitanciya imeyet rezhim `0600`, ostayotsya vne materializacii i publichnogo checkout. Proveryayusjhij samostoyateljno peresozdayot vse ozhidayemyiye polya i sravnivayet kanonicheskiye bajtyi celikom; UUID iz kandidata ne stanovitsya ozhidayemyim znacheniyem. Lishneye pole, chuzhoj UUID, input/tree/hash, drugoj putj ili inode dayut otkaz. Kopiya kataloga s prezhnej kvitanciyej ne prinimayetsya. Povtor `материализовать` pri nalichii sobstvennogo zavershyonnogo rezuljtata vyipolnyayet toljko novuyu proverku. Susjhestvuyusjheye naznacheniye bez tochnoj kvitancii ne ochisjhayetsya i ne perezapisyivayetsya.

## Otkaz i dolgovechnostj

Do sozdaniya naznacheniya isklyuchiteljnyim sozdaniyem zapisyivayetsya marker nezavershyonnosti; sinkhroniziruyutsya on i roditelj. Sinkhroniziruyutsya zapisannyiye fajlyi i katalogi snizu vverkh. Toljko posle svezhego vkhoda i nezavisimoj sverki zapisyivayetsya vremennaya kvitanciya, sinkhroniziruyetsya yeyo soderzhimoye, ona ustanavlivayetsya bez zamenyi chuzhogo fajla i sinkhroniziruyetsya roditelj. Zatem snimayetsya sobstvennyij marker i snova sinkhroniziruyetsya roditelj. Proveryayusjhij otvergayet lyuboye prisutstviye markera. Hardlink primenyayetsya lishj na vremya atomarnoj ustanovki sluzhebnoj kvitancii, ne dlya fajlov snimka; posle ustanovki ona obyazana imetj odnu ssyilku.

Korotkaya zapisj, nulevaya zapisj nepustogo bloka, ENOSPC, oshibka fsync ili nablyudayemaya podmena zapresjhayut uspeshnyij vozvrat. Chastichnyij katalog i sledyi operacii sokhranyayutsya dlya diagnostiki; avtomaticheskogo udaleniya i vozobnovleniya net. Dlya novoj popyitki nuzhen novyij yavno vyibrannyij putj. Posle sboya poslednego fsync vozvrat markera yavlyayetsya best effort: povtornaya operaciya tozhe mozhet otkazatj. Ostatochnaya kvitanciya — toljko kandidat dlya novoj polnoj nezavisimoj sverki. Avariya posle dolgovechnoj zapisi, na zavershayusjhej granice snyatiya markera, ne dokazyivayet uspeshnoye zaversheniye processa; proveryayusjhij ustanavlivayet lishj tekusjheye sootvetstviye bajtov. Dolgovechnostj ogranichena garantiyami `os.fsync` i fajlovoj sistemyi; zasjhita ot lyubogo vrazhdebnogo processa togo zhe UID ne obesjhayetsya.

## Profilj

[Vosproizvodimyij profilj](tests/profilirovatj-materializaciyu.py) prinimayet `--размеры 2,100 --выход <файл> [--сравнить <прежний файл>]`. On proveryayet malyij i uvelichennyij vkhodyi s povtornyimi/unikaljnyimi blob, rezhimami `0644/0755` i zavisimostjyu. Sokhranyayutsya versii iskhodnikov i runtime, otdeljnyiye vremena podgotovki, proverki vkhoda, chteniya Git, sozdaniya, nezavisimoj sverki i fsync, obyyom, chislo chtenij i pik Python heap cherez tracemalloc. Pamyatj dochernego Git ne izmeryayetsya. Intervalyi vlozhenyi i ne skladyivayutsya. Sravneniye trebuyet tochnogo sovpadeniya vkhodnyikh bajtov i polnogo manifesta; lokaljnyiye inode, puti i UUID kvitancii v perenosimoye sravneniye ne vkhodyat.

## Istochniki

- [Komanda materializovatj zakreplyonnyij vkhod](../../Zhurnal/2026-09-09_14-12-34_MSK_materializovatj-zakreplyonnyij-vkhod/zapros.md).
- [Iskhodnyij proyekt kontrakta 0155](../../Zhurnal/2026-09-08_19-07-59_MSK_utochnitj-kontrakt-snimkov-indeksa/materialyi/planyi/kontrakt-snimkov-indeksa.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 14:41:44 MSK -->
<!-- content-sha256: sha256:f706e4e31dfb0c12f99ea07b2e7f3e751cd63fd249bc35a8aea0d04a009fa460 -->
<!-- FUM-MD-RECENCY:END -->
