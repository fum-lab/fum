# Nablyudayemaya istoriya modeli i usiliya

[Komanda](scripts/sokhranitj-istoriyu-modeli.py) chitayet yavno naznachennyij native JSONL i sokhranyayet otdeljnyij JSON istorii v sobstvennoj papke Zhurnala. Ona importiruyet pervoye nablyudeniye paryi `payload.model`/`payload.effort` iz `turn_context`, posleduyusjhiye smenyi i nablyudeniya posle propuska. Povtornyiye ravnyiye paryi uvelichivayut chislo nablyudenij, no ne chislo sobyitij. Posledneye nablyudeniye sokhranyayetsya otdeljno s tochnyim proiskhozhdeniyem.

Nuzhnyi Python 3.10+ i POSIX. Susjhestvuyusjhiye katalogi naznacheniya sozdayutsya pri podgotovke svoyej paryi Zhurnala. Istochnik i privatnyij kursor ostayutsya vne Git; putj istorii nakhoditsya vnutri yavno vyibrannogo checkout. Process — yedinstvennyij pisatelj istorii i kursora. Avtozapusk i izmeneniye nastroyek Codex otsutstvuyut.

## Zapusk

Iz svoyego fizicheskogo kornya, zameniv plejskholderyi:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/сохранить-историю-модели.py --корень-репозитория <корень> --исходник <native.jsonl> --задача-источника <UUID-источника> --кэш <приватный-курсор.json> --история <свой-Журнал/материалы/история.json>
```

Povtoritj tu zhe komandu dlya inkrementaljnogo priyoma. `--без-записи` vyichislyayet rezuljtat bez sozdaniya istorii, kursora, zamka ili katalogov. Pri sovpadenii stat (ustrojstvo, inode, razmer, mtime, ctime) i SHA realizacii v doverennom lokaljnom istochnike povtor ne chitayet iskhodnyiye bajtyi i ne proveryayet soderzhimoye nezavisimo zanovo; pri roste khyeshiruyet prezhnij prefiks i razbirayet lishj zavershyonnyij khvost. Novyij kursor mozhet podtverditj uzhe susjhestvuyusjhuyu istoriyu toljko pri tochnom sovpadenii rezuljtata; inoj iskhod trebuyet otdeljnoj sverki.

Dlya podgotovki soobsjheniya kommita dobavitj odnovremenno `--основа-коммита <файл>` `--сообщение-коммита <новый-приватный-файл>` `--codex-thread-id <корневой-UUID>`. Osnova soderzhit polnyij iskhodnyij zapros i yedinstvennyij poslednij trejler `Codex-Thread-ID`. Generator iz rezuljtata togo zhe importa vstavlyayet upravlyayemyij blok s otdeljnyimi sovmestimyimi polyami `model` i `effort`, native UUID, vremenem i SHA stroki. Kornevoj UUID mozhet otlichatjsya ot native UUID ispolnitelya. Tochnyij uzhe sformirovannyij suffiks vozvrasjhayetsya neizmennyim. Generator ne udalyayet i ne preobrazuyet iskhodnoye telo; pri drugom suffikse s konechnyim markerom otkazyivayet i trebuyet iskhodnuyu osnovu. Citatyi s markerami vnutri tela sokhranyayutsya doslovno. Dlya CLI kazhdyij vyikhodnoj fajl novyij i sozdayotsya srazu s pravami 0600, do pervoj zapisi. Posle podgotovki vyipolnyayetsya shtatnaya proverka svyaznosti s tem zhe fajlom; komanda ne kommitit i ne oslablyayet proverku.

Yesli posledneye nablyudeniye otsutstvuyet libo priyom nepolon, soobsjheniye kommita ne sozdayotsya. Istoriya, uzhe importirovannaya do otkaza podgotovki soobsjheniya, sokhranyayetsya. Poetomu oshibka podgotovki kommita ne oznachayet otsutstviye effekta importa.

## Kontrakt dannyikh i rezuljtatov

Istoriya `fum.история-модели.1` khranit native UUID, SHA pervoj stroki `session_meta`, zavershyonnuyu granicu i SHA prefiksa, razmer snimka, nepolnyij khvost, chislo nablyudenij, sobyitiya, propuski i posledneye nablyudeniye. Sobyitiye soderzhit otdeljnyiye modelj i usiliye, iskhodnuyu strokovuyu metku vremeni, predyidusjhuyu paru, vid sobyitiya i poziciyu: nachalo vklyuchiteljno, konec isklyuchiteljno, SHA-256 tochnoj stroki vmeste s LF. Neizvestnyiye prichina i iniciator sokhranyayutsya kak `unknown`: nativnyij kontrakt `turn_context` ne zadayot dostovernogo kontrakta etikh polej, proizvoljnyiye odnoimyonnyiye polya ne interpretiruyutsya.

Soderzhimoye ostaljnyikh sobyitij, poljzovateljskiye soobsjheniya, otvetyi, instrukcii i syiroj JSONL ne eksportiruyutsya. Nerazbirayemaya zavershyonnaya stroka i nepolnoye `turn_context` poluchayut poziciyu i prichinu propuska; u nepolnoj paryi dopolniteljno sokhranyayutsya dostupnyiye modelj, usiliye i vremya, a otsutstvuyusjhiye libo nekorrektnyiye znacheniya oboznachayutsya `unknown`; sravneniye paryi posle nikh nachinayetsya zanovo. Nezavershyonnaya stroka ostayotsya vne zavershyonnoj granicyi i perechityivayetsya posle dopisyivaniya. Otsutstviye sobyitij mezhdu nablyudeniyami nikogda ne obyyavlyayetsya otsutstviyem pereklyuchenij.

Kompaktnaya kvitanciya `fum.приём-истории-модели.1` soderzhit schyotchiki, posledneye nablyudeniye, SHA polnogo artefakta, polnotu snimka, pozdneye dopisyivaniye, neobkhodimostj izmeneniya i profilj. Ona ne vyivodit massiv sobyitij. Polnyij priyom predshestvuyet predstavleniyu. Nolj `новых_наблюдений` oznachayet toljko otsutstviye novyikh nablyudenij otnositeljno kursora; pole `переключения_между_наблюдениями_известны` vsegda `false`.

- Kod 0 — polnyij priyom nablyudayemogo snimka.
- Kod 3 — sokhranyonnyij chastichnyij priyom: propuski, nepolnyij khvost libo pozdneye dopisyivaniye. Posmotretj pozicii v istorii, zatem ispravitj istochnik ili povtoritj chteniye zavershyonnogo khvosta. Istoricheskij propusk ne ischezayet posle posleduyusjhego uspeshnogo nablyudeniya.
- Kod 2 — otkaz: chuzhoj UUID, zamena/usecheniye, izmenivshijsya prefiks, povrezhdeniye sostoyaniya, narusheniye granicyi ili oshibka podgotovki kommita. Sokhranivshiyesya fajlyi trebuyut sverki; avtomaticheskogo sbrosa istorii net.

Privatnyij kursor zasjhisjhyon SHA i zamkom; pered zamenoj istorii on sokhranyayet podgotovlennuyu fazu s ozhidayemyim SHA prezhnego fajla. Povtor posle sboya zavershayet toljko dokazannyij perekhod, v tom chisle yesli istochnik uspel vyirasti. Istoriya zamenyayetsya atomarno; prezhniye sobyitiya ostayutsya tem zhe prefiksom massiva. Izmeneniye realizacii zakryivayet staryij kursor otkazom: dlya migracii nuzhen novyij kursor i yavnaya sverka istorii. Udaleniye uzhe sokhranyonnoj istorii takzhe yavlyayetsya otkazom.

## Proverki i profilj

Cherez shtatnuyu otchyotnuyu obyortku:

```text
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_история_модели.py
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_истории_модели.py
```

Sinteticheskiye testyi proveryayut proiskhozhdeniye, deduplikaciyu, rost, povrezhdeniye, usecheniye, zamenu, otsutstviye zapisi, granicyi putej, vosstanovleniye i polya kommita. Profilj sozdayot 74,97 MB, semj nablyudenij i izmeryayet pervyij priyom, povtor i povtor bez zapisi. Podgotovka isklyuchena; kyesh OS ne ochisjhayetsya. Vremena otnosyatsya k API, ne k polnomu processu CLI; SHA iskhodnikov vkhodyat v rezuljtat. Otdeljnogo algoritmicheskogo uskoreniya sverkh inkrementaljnogo puti ne zayavlyayetsya.

## Granicyi doveriya

Pereispoljzuyutsya strogij JSON-dekoder, SHA, ogranicheniye stroki, proverka obyichnogo fajla, metka FS, sverka snimka, zamok i atomarnaya ustanovka iz [chitatelya soobsjhenij](scripts/soobsjheniya_zadachi.py). Otbor `turn_context` samostoyateljnyij: soobsjheniya ne zagruzhayutsya v publichnuyu istoriyu. Neizmennyij stat — kooperativnoye nablyudeniye FS, a ne zasjhita ot vladeljca mashinyi, sposobnogo soglasovanno podmenitj istochnik i kursor. Simvolicheskiye ssyilki i `..` v naznachennyikh putyakh zapresjhenyi; vrazhdebnaya konkurentnaya zamena predkov ne pokryivayetsya. Polnota ne dokazyivayet otsutstviye nevidimyikh pereklyuchenij i ne dokazyivayet prinyatiye rezuljtata kornem.

## Istochniki

- [Postanovka i iskhodnaya chetyiryokhstrochnaya istoriya](../../Zhurnal/2026-09-15_18-29-25_MSK_zakrepitj-vosemj-reshenij-obrabotki/otchyot.md).
- [Ispolneniye avtomatizacii](../../Zhurnal/2026-09-15_19-05-01_MSK_sokhranyatj-nablyudayemuyu-istoriyu-modeli/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:26:11 MSK -->
<!-- content-sha256: sha256:dbe4d70743355a98d155039cfc658884a4730c775211388350bdefcc2ac046eb -->
<!-- FUM-MD-RECENCY:END -->
