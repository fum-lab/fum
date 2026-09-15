# Obratnaya dostavka prinyatogo sreza

Konechnyij [ispolnitelj](scripts/obratnaya-dostavka.py) stroit adresnyij plan dlya yavno vyibrannyikh feature-vetok i pozvolyayet kazhdomu vladeljcu primenitj srez v sobstvennom checkout. On sokhranyayet namereniye do merge i uznayot fakticheskoye sostoyaniye posle preryivaniya. Komandyi ne zapuskayut raspisaniye, dispatcher ili zadachi Codex. Kommit, push i resheniye o priyome vyipolnyayutsya otdeljnyimi stadiyami.

Ispolnitelj proveren na otkryityikh vremennyikh Git-repozitoriyakh, vklyuchaya realjnuyu shtatnuyu otchyotnuyu obyortku. Neizmennyiye gitlink dopuskayutsya bez rekursivnogo obnovleniya; izmenyayemyiye gitlink otklonyayutsya. Uzkaya otchyotnaya proverka sokhranyayet otdeljno derevo sliyaniya i itogovoye derevo so sluzhebnyimi zapisyami. Nativnaya aktivaciya vladeljca, polnaya proverka konkretnoj vetki i yeyo integraciya ostayutsya otdeljnyimi dejstviyami koordinatora i vladeljca.

## Vkhod koordinatora

Nuzhnyi Python 3.11+ na POSIX, Git s `merge-tree --write-tree` i dostupnyiye lokaljnyiye Git-obyyektyi. Provereno na Python 3.14.7 i Git 2.54.0. Zagruzka otsutstvuyusjhikh obyyektov vyipolnyayetsya otdeljno vladeljcem; avtomaticheskogo fetch net. Polnyiye OID imeyut dlinu formata sootvetstvuyusjhego repozitoriya. Ssyilki na iskhodniki FUM razreshayutsya iz tekusjhego monorepozitoriya; ustanovka storonnikh paketov ne trebuyetsya.

Privatnyij JSON vkhoda soderzhit rovno `источник`, `получатели`, `владельцы`. Posledneye pole — fizicheskij putj JSON-reyestra: klyuchom sluzhit fizicheskij korenj poluchatelya, znacheniyem — obyyekt `задача` s native UUID i `ref` s polnoj vetkoj `refs/heads/codex/...`. Vetka i korenj prinadlezhat odnomu naznachennomu pisatelyu. Eto kooperativnoye naznacheniye, ne mekhanizm autentifikacii protiv subyyekta s temi zhe pravami OS.

`получатели` — yavnyij nepustoj spisok obyyektov `корень`, `причина`, `зависимость`. V poslednem pole sokhranyayetsya `unknown`, kogda predmetnaya zavisimostj ne dokazana. Sovmestimaya stroka-korenj oznachayet yavnyij interes koordinatora i zavisimostj `unknown`. Instrument ne vyivodit zainteresovannostj iz tematicheskogo skhodstva i ne rassyilayet kazhdyij novyij zhurnaljnyij kommit.

`источник` soderzhit:

- `корень`, `ref`, `коммит`, `владелец`: fizicheskij checkout, tochnyij polnyij ref, yego polnyij OID A i UUID vladeljca istochnika;
- `срез`: polnyij OID S, kotoryij dolzhen uzhe prisutstvovatj v baze kazhdogo poluchatelya;
- `приёмка`: obyyekt `путь`, `sha256` dlya obyichnogo JSON-fajla resheniya v A.

Resheniye imeyet skhemu `fum.решение-приёмки-среза.1`, tochnyiye `коммит` S i `дерево` S, UUID `проверяющий`, `состояние: принят промежуточный срез`, nepustuyu `граница` i nepustyiye `свидетельства`. Kazhdoye svideteljstvo soderzhit `путь` obyichnogo fajla v A i SHA-256 yego tochnyikh bajtov. S dolzhen byitj predkom A. Koordinator sokhranyayet resheniye posle sobstvennoj proverki: instrument proveryayet svyazj i celostnostj predstavlennyikh svideteljstv, no ne vosproizvodit proverki i ne udostoveryayet lichnostj avtora. Kontroljnaya tochka bez takogo resheniya ne prinimayetsya. `полная_приёмка` vsegda `false`; strogij chitatelj polnogo zakryitogo otchyota ostayotsya otdeljnyim instrumentom.

Versiya prinyatogo istochnika zavisit ot S i resheniya. A pozvolyayet khranitj resheniye bez nevozmozhnoj ssyilki kommita na samogo sebya; v feature perenositsya imenno S. Istochnik i vse poluchateli povtorno sveryayutsya pered vyidachej plana. Proverennyij plan soderzhit tochnyiye OID i tree, ref, UUID, korni, prichinyi vyibora, otpechatok reyestra i determinirovannyij identifikator.

```text
python3 -B <путь-исполнителя> наблюдать --вход <приватный-вход.json>
python3 -B <путь-исполнителя> поручения --план <план.json> --владельцы <владельцы.json> --каталоги <каталоги.json>
```

`каталоги.json` svyazyivayet kazhdyij fizicheskij korenj s yego otdeljnyim privatnyim katalogom kvitancij. Komanda `поручения` vozvrasjhayet `threadId` i gotovyij `prompt`, tochnyiye adresa, plan i sostoyaniye «yesjhyo ne otpravleno». Koordinator mozhet peredatj `threadId` i `prompt` v instrument soobsjhenij susjhestvuyusjhej zadachi Codex i zatem adresno nablyudatj yeyo otvet. Lokaljnaya vyidacha JSON ne dokazyivayet otpravku, aktivaciyu ili polucheniye. Povtor vneshnego vyizova s neizvestnyim iskhodom trebuyet issledovaniya koordinatorom; etot ispolnitelj ne vyizyivayet nativnyiye instrumentyi samostoyateljno.

## Signal nedostavki

| Otnosheniye             | Chto nablyudalosj                                 | Dejstviye vladeljca                                      |
| --------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| v predkakh             | S vkhodit v istoriyu poluchatelya                   | Podtverditj priyom; merge ne nuzhen                        |
| ravnoye derevo         | Derevjya ravnyi pri razlichnoj istorii              | Podtverditj smyislovuyu sverku                             |
| ekvivalentnyiye patchi    | Vse dostupnyiye patchi ekvivalentnyi                 | Snachala sveritj smyisl; avtomaticheskij merge zapresjhyon     |
| vyiborochnyij perenos    | Yestj ekvivalentnyiye patchi vmeste s inyim ostatkom  | Otdeljnoye resheniye i novyij plan; tekusjhij apply otkazyivayet  |
| nedostavlennyiye kommityi | S ne predok, dokazannoj ekvivalentnosti net       | Dopustimo primeneniye yavno naznachennomu vladeljcu         |

`сигнал_недоставки` oznachayet nedostavlennostj kommitov ili trebuyusjhuyu issledovaniya ekvivalentnostj. Eto ne dokazateljstvo otsutstvuyusjhego smyisla. Prichina vyibora, zavisimostj i granica priyomki nakhodyatsya ryadom s signalom. `подтверждение: unknown` v plane ne pogashayetsya chteniyem plana; otdeljnaya kvitanciya soderzhit resheniye poluchatelya i yego osnovaniye.

## Cikl vladeljca

Process zapuskayetsya iz sobstvennogo fizicheskogo kornya. `CODEX_THREAD_ID`, `--задача`, naznacheniye reyestra i UUID poluchatelya dolzhnyi sovpadatj. Vse komandyi vladeljca poluchayut odni i te zhe `--план`, `--корень`, `--задача`, `--владельцы`, `--каталог`.

```text
python3 -B <путь-исполнителя> применить <общие-аргументы>
python3 -B <путь-исполнителя> состояние <общие-аргументы>
python3 -B <путь-исполнителя> проверить <общие-аргументы> -- <программа-проверки> <аргументы>
python3 -B <путь-исполнителя> коммит <общие-аргументы>
python3 -B <путь-исполнителя> публикация <общие-аргументы>
python3 -B <путь-исполнителя> получение <общие-аргументы> --основание <решение-владельца>
```

`применить` trebuyet chistyikh tracked-fajlov i indeksa. Do merge on sokhranyayet iskhodnyij HEAD, istochnik, rasschitannoye derevo merge i protected-fajlyi. Vyipolnyayetsya `merge --no-commit --no-ff --no-overwrite-ignore`, bez stash, reset, vyibora storon, force i avtomaticheskogo kommita. Konflikt ostayotsya v indekse i fajlakh vladeljca. Povtor takogo primeneniya uznayot konflikt i ne zapuskayet merge snova. Vneshneye ruchnoye razresheniye konflikta trebuyet otdeljnoj priyomki; etot segment yego ne prisvaivayet.

Proverochnaya komanda doverennaya i dolzhna sokhranyatj derevo; obyichnyiye stdout/stderr prokhodyat susjhestvuyusjhij polnyij zakhvat v privatnyij katalog s SHA. Neuspekh, tajm-aut i nepolnyij zakhvat ne dayut stadiyu `проверено`. Dlya proverki cherez shtatnuyu obyortku FUM ispoljzuyetsya sleduyusjhij uzkij rezhim.


### Proverka so shtatnyim otchyotom

Do primeneniya vladelec sokhranyayet zapros, otkryityij otchyot i prezhniye terminaljnyiye zapisi v svoyej vetke. Oni dolzhnyi popastj v rasschitannoye derevo sliyaniya. Zapros soderzhit obsjhij kornevoj UUID; on mozhet otlichatjsya ot native UUID vladeljca. Otchyot zaraneye imeyet aktualjnuyu recency-metku so stabiljnyim khyeshem bez upravlyayemogo bloka. Dostavka ne sozdayot novyij zapros i ne obnovlyayet recency, indeksyi libo proyekciyu.

```text
python3 -B <путь-исполнителя> проверить <общие-аргументы> --запрос-проверки <Журнал-сессии/запрос.md> --корневая-задача <корневой-UUID> -- <адресная-проверка> <аргументы>
git add -- <точный-путь-отчёта> <точный-путь-новой-записи>
python3 -B <путь-исполнителя> индекс <общие-аргументы>
```

Proverka fiksiruyet odin tochnyij zapros, iskhodnyiye bajtyi vsekh fajlov i rezhimyi, prezhniye zapisi, derevo sliyaniya i zaraneye naznachennyij UUID zapuska. Vyizyivayetsya nastoyasjhaya otchyotnaya obyortka klassa `адресная`, zatem shtatnyij `предпросмотр`. Pered predprosmotrom dopustim toljko pervonachaljnyij otchyot libo uzhe sformirovannyij tochnyij rezuljtat; postoronnyaya pravka ne perezapisyivayetsya. Obyortke otvedyon zadannyij `--тайм-аут`, vneshnemu zakhvatu — yesjhyo 10 sekund dlya terminalizacii.

Dopustim rovno odin novyij terminaljnyij JSON naznachennogo UUID v standartnom kataloge i tochnyij rezuljtat generatora vnutri `FUM-CHECK-RUNS`. Staryiye zapisi, zapros, bajtyi vne marker, vse drugiye fajlyi i protected-dannyiye zavisimostej ostayutsya neizmennyimi. Novaya chuzhaya, nezavershyonnaya libo proizvoljnaya zapisj, snimok, perekhodnyij zhurnal i skryityij lishnij obyyekt indeksa otklonyayutsya. V kvitancii skhemyi `fum.квитанция-обратной-доставки.2` pole `отчёт` khranit granicu i otsortirovannuyu `разница` s rezhimami i SHA-256. Kvitancii pervogo segmenta ostayutsya chitayemyimi.

Uspeshnaya proverka dayot `ожидается индекс`. Puti dlya yavnogo `git add` nakhodyatsya v `отчёт.разница`; instrument sam indeks ne podgotavlivayet. Komanda `индекс` sveryayet pobajtovuyu raznicu i trebuyet, chtobyi derevo indeksa byilo rovno derevom sliyaniya plyus prinyatyiye sluzhebnyiye fajlyi. Toljko posle etogo voznikayet `проверено`; pole `дерево` soderzhit itogovoye derevo, a `отчёт.дерево_слияния` — iskhodnoye proveryayemoye. Kommit sveryayetsya s itogovyim derevom i tochnyimi dvumya roditelyami.

Pri potere otveta zakhvata chitayutsya tot zhe privatnyij manifest, polnyij vyivod i naznachennyij UUID. Uzhe zavershyonnaya proverka ne povtoryayetsya; tochnyij predprosmotr mozhno zavershitj posle preryivaniya. Otsutstvuyusjhij manifest ili aktivnyij terminal zakryivayut dejstviye. Neuspekh sokhranyayet otchyot i stadiyu `проверка не пройдена`; on ne razreshayet indeks i kommit. Ispravleniye koda i novaya proverka trebuyut otdeljnoj soglasovannoj granicyi, bez udaleniya sokhranyonnyikh zapisej. Etot adresnyij rezhim ne podmenyayet polnyij smoke i zakryitiye polnogo otchyota konkretnoj vetki.

Posle proverki vladelec otdeljno sozdayot razreshyonnyij kommit. Komanda `коммит` toljko nablyudayet yego: trebuyutsya rovno roditeli `[прежний HEAD, S]` i proverennoye derevo. Posle obyichnogo razreshyonnogo push komanda `публикация` sveryayet yedinstvennyij push-adres `origin` i polnyij udalyonnyij OID odnoimyonnoj vetki. `получение` otdeljno fiksiruyet resheniye vladeljca. Polya kommita, publikacii i priyoma ne vyivodyatsya drug iz druga.

## Preryivaniye i ogranicheniya

Privatnyij katalog imeyet prava 0700 i lezhit vne lyubogo Git-predka, vklyuchaya domashnij repozitorij i bare-repozitorij. Na poluchatelya ispoljzuyetsya odin stabiljnyij katalog; odnovremenno dejstvuyet odin pisatelj. `flock`, atomarnaya ustanovka i `fsync` sokhranyayut kvitancii. Nachatoye namereniye otlichayet novyij katalog ot chastichno poteryannoj istorii. Povrezhdeniye ili poterya svideteljstv zakryivayut dejstviye; polnoye udaleniye vsekh privatnyikh sledov i vrazhdebnaya konkurentnaya podmena nakhodyatsya vne modeli.

Posle preryivaniya komanda `состояние` mozhet dolgovechno utochnitj stadiyu po nablyudayemomu Git. Sovpavshiye HEAD/MERGE_HEAD/ORIG_HEAD i derevo uznayut primeneniye posle poteri otveta. Kommit posle proverki uznayotsya bez povtornogo kommita. Yesli namereniye byilo zapisano, no effekta net, vozvrasjhayetsya ustojchivoye `эффект не подтверждён`; povtor merge ne vyipolnyayetsya. Nezavershyonnaya proverka ostayotsya nepodtverzhdyonnoj.

Otkazyivayutsya detached HEAD, drugaya vetka ili UUID, sdvig plana, drugoye nezavershyonnoye sliyaniye, rebase/cherry-pick/revert/bisect, index-lock, skryityiye flagi indeksa, sparse/shallow checkout, vneshniye filjtryi i merge-drajveryi, simvoljnyiye tracked-fajlyi i izmenyayemyiye gitlink. Neizmennyiye materializovannyiye zavisimosti dolzhnyi imetj ozhidayemyij HEAD i chistyij indeks/kod. Ikh ignored-fajlyi takzhe sokhranyayutsya. Neinicializirovannyiye neizmennyiye zavisimosti ne materializuyutsya. Nerelevantnyiye untracked/ignored sokhranyayutsya; peresecheniye vkhodyasjhego puti s nimi zakryivayet primeneniye.

Kod CLI `0` oznachayet uspeshnoye nablyudeniye ukazannoj stadii, `2` — otkaz ili nepodderzhannyij vkhod, `3` — konflikt, nepodtverzhdyonnyij effekt libo neuspeshnuyu proverku. Realjnyiye puti, argv i syiryiye vyivodyi privatnyi; v Git ostayutsya iskhodniki, otkryityiye testyi i obezlichennyij profilj.

## Proverki i profilj

[Adresnyij nabor](tests/test_obratnaya_dostavka.py), [scenarii otchyotov](tests/test_dostavka_otchyota.py) i [profilj](tests/profilj_obratnoj_dostavki.py) ispoljzuyut vremennyiye otkryityiye repozitorii. V FUM zapuskatj cherez obyichnuyu otchyotnuyu obyortku:

```text
python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p 'test_*достав*.py'
python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_обратной_доставки.py --выход <профиль.json>
```

[Profilj otchyotnogo etapa](tests/profilj_otchyotnoj_dostavki.py) izmeryayet realjnuyu obyortku, predprosmotr, podgotovku vladeljcem i sverku indeksa.

Pervonachaljnyij profilj razlichayet nablyudeniye, postroyeniye plana i primeneniye; podgotovka isklyuchena, vlozhennyiye intervalyi ne summiruyutsya povtorno. On ne izmeryayet nativnuyu aktivaciyu, svoyevremennostj dostavki, setj ili rabotu na polnom FUM.

## Istochniki

- [Postanovka prioritetnoj rabotyi](../../Zhurnal/2026-09-15_16-58-55_MSK_zapustitj-prioritetnyiye-paralleljnyiye-rabotyi/zapros.md).
- [Proverki i granicyi pervogo etapa](https://github.com/fum-lab/fum/blob/2f55f909d5d73fbca17b93497b587090414f0ed7/Журнал/2026-09-15_17-09-52_MSK_реализовать-обратную-доставку-интеграций/отчёт.md).
- [Sovmestimostj so shtatnyim otchyotom](https://github.com/fum-lab/fum/blob/2f55f909d5d73fbca17b93497b587090414f0ed7/Журнал/2026-09-15_17-52-03_MSK_совместить-доставку-с-отчётной-обёрткой/отчёт.md).
- Pereispoljzovanyi kanonicheskij JSON, proverka putej i ustojchivaya zapisj [priyoma napravlenij](scripts/priyom_napravleniya.py), a takzhe [polnyij zakhvat](../fum-svyaznostj-rabochej-sessii/polnyij-zakhvat-vyivoda.md). Yego staroye khranilisjhe vnutri git-common-dir ne ispoljzuyetsya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 18:24:06 MSK -->
<!-- content-sha256: sha256:301e601dca589e387eb4014d215a78c190706fe66ee484ae337ad49283d3cde0 -->
<!-- FUM-MD-RECENCY:END -->
