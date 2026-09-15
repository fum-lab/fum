# Polnyij lokaljnyij zakhvat vyivoda

[CLI](scripts/zakhvatitj-vyivod.py) zapuskayet yavno peredannyij spisok argumentov bez obolochki. Do vyidachi v kontekst [modulj](scripts/zakhvat_vyivoda.py) sokhranyayet stdout i stderr kak otdeljnyiye binarnyiye fajlyi. Obsjhaya vyidacha soderzhit sostoyaniye, razmeryi, SHA i adres manifesta. Soderzhimoye raskryivayetsya otdeljnyim zaprosom diapazona s proverkoj polnogo SHA kanala.

Nuzhnyi Python 3.10+ i POSIX s gruppami processov, neblokiruyusjhimi kanalami, `fsync`, `O_NOFOLLOW`, `O_DIRECTORY`. Provereno na macOS s Python 3.14.7. Eto yavnyij lokaljnyij vkhod; MCP i nedostupnyij runtime sami k nemu ne podklyuchenyi. Komanda sokhranyayet svoi obyichnyiye polnomochiya: `shell=False` ne yavlyayetsya pesochnicej.

## Ispoljzovaniye

Predusloviye API i CLI — kooperativnaya modelj: zapusjhennyij process doveren, etot zakhvat yavlyayetsya yedinstvennyim pisatelem privatnogo kataloga, konkurentnoj podmenyi kataloga, fajlov, ssyilok i specialjnyikh fajlov net. Proverki fizicheskogo puti, prav i SHA pomogayut vyiyavlyatj oshibki vnutri etoj modeli; oni ne zasjhisjhayut proizvoditelya ot vrazhdebnogo processa s temi zhe pravami. Izolyaciya sredstvami OS i pesochnica ne realizovanyi. Kvitanciya pokazyivayet eto polem `модель_доверия`; pole obyyavlyayet predposyilku, ne dokazyivayet yeyo vyipolneniye.

Python-vkhod `захватить_с_хэшем` vozvrasjhayet manifest i SHA tochnyikh serializovannyikh bajtov, kotoryiye proizvoditelj peredal ustojchivoj ustanovke. CLI poluchayet ozhidayemyij SHA neposredstvenno iz etogo rezuljtata, a zatem proveryayet prochitannyij fajl po nemu. Povtornoye chteniye boljshe ne naznachayet samomu sebe ozhidayemyij khyesh. Sovmestimyij `захватить` po-prezhnemu vozvrasjhayet toljko manifest. Peredannyij SHA obnaruzhivayet raskhozhdeniye pri posleduyusjhem chtenii; eto ne dokazateljstvo otsutstviya vsekh vozmozhnyikh podmen vo vremya rabotyi proizvoditelya.

Iz kornya FUM, zameniv plejskholderyi fakticheskimi znacheniyami:

```bash
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/захватить-вывод.py --каталог <новый-приватный-физический-каталог> --бюджет 16000 запустить --корень <рабочий-корень> --задача <uuid-задачи> --тайм-аут 60 --предел-байтов 134217728 -- <исполняемый-файл> <аргументы>
```

Katalog dolzhen byitj novyim, yego roditelj — susjhestvuyusjhim; vesj putj fizicheskij, bez simvolicheskikh ssyilok, vne lyubogo Git checkout. Prava kataloga 0700, novyikh fajlov 0600. Povtor imeni otkazyivayet do zapuska. Vyizov, argumentyi, rabochij katalog i iskhodnyiye potoki privatnyi i v Git ne popadayut. Peredacha syuda uzhe razreshyonnoj komandyi ne rasshiryayet yeyo polnomochiya.

Otvet soderzhit SHA `манифест.json`. Sokhranite yego dlya posleduyusjhikh chtenij:

```bash
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/захватить-вывод.py --каталог <тот-же-каталог> --бюджет 16000 представить --sha256 <sha256-манифеста>
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/захватить-вывод.py --каталог <тот-же-каталог> --бюджет 16000 прочитать --sha256 <sha256-манифеста> --канал stderr --начало 0 --число 256
```

Diapazon peredayot tochnyiye bajtyi v base64. Proveryayutsya SHA manifesta i vsego sokhranyonnogo kanala, vyiborka sobirayetsya v tom zhe prokhode. Polnota iskhodnogo zakhvata i nalichiye sleduyusjhego diapazona razlichayutsya. Boljshoj zapros ne obrezayetsya molcha: yesli rezuljtat s metadannyimi, base64 i LF ne pomesjhayetsya, vyidayotsya otkaz. Byudzhet 100–1048576 bajtov otnositsya ko vsemu rezuljtatu adaptera; otdeljnoj kvitancii v stderr net. Spravka i oshibki sintaksisa argumentov do zapuska ne yavlyayutsya protokolom rezuljtata zakhvata.

Kod CLI 0 oznachayet podgotovlennoye predstavleniye i zavershivshuyusya lokaljnuyu zapisj; kod dochernego processa nakhoditsya vnutri otveta. Nenulevoj kod dochernego processa ne prepyatstvuyet polnomu sokhraneniyu oboikh kanalov. Kod CLI 2 oboznachayet otkaz zakhvata, predstavleniya ili zapisi. Posle chastichnoj zapisi vtoroj JSON ne dobavlyayetsya. Polucheniye otveta modeljyu ostayotsya `unknown`: uspeshnaya zapisj v lokaljnyij kanal ne yavlyayetsya kvitanciyej poluchatelya.

## Polnota i nablyudeniya

Polnyij zakhvat trebuyet okonchaniya oboikh kanalov, koda zaversheniya dochernego processa i ustojchivoj zapisi fajlov i konechnogo manifesta. Snachala sokhranyayetsya vyizov, zatem potoki i ogranichennaya trassa, zatem iskhodnyij manifest. Obrabotchik zapuskayetsya posle etoj granicyi. Konechnyij manifest ustanavlivayetsya cherez vremennyij fajl i pereimenovaniye s sinkhronizaciyej kataloga.

Tajm-aut pokryivayet ozhidaniye processa i oboikh kanalov. Potomok, uderzhivayusjhij kanal, ne dayot lozhnogo uspeshnogo okonchaniya. Pri prevyishenii vremeni ili obsjhego predela stdout+stderr processnaya gruppa ostanavlivayetsya; sokhranyonnyij prefiks yavno nepolon. Rovno dopustimoye chislo bajtov pri okonchanii oboikh kanalov prinimayetsya. Polnyij proizvedyonnyij obyyom posle ostanovki neizvesten. Potomki, vyishedshiye iz gruppyi, ne obyyavlyayutsya ostanovlennyimi. Neustojchivaya zapisj ne poluchayet uspeshnogo konechnogo manifesta. Povtornyij zapusk posle vozmozhnogo vneshnego effekta ne vyipolnyayetsya avtomaticheski.

`наблюдения.jsonl` khranit pervyiye 4096 nablyudyonnyikh chtenij: nomer, kanal, smesjheniye, chislo prochitannyikh i sokhranyonnyikh bajtov, SHA sokhranyonnoj chasti. Ostaljnyiye chteniya uchityivayutsya schyotchikom propuska. Eto poryadok chteniya adapterom, ne tochnoye cheredovaniye iskhodnyikh zapisej dvukh nezavisimyikh kanalov. Predel khraneniya otnositsya k iskhodnyim potokam; vyizov, ogranichennaya trassa, manifestyi i proizvodnoye predstavleniye trebuyut dopolniteljnogo diska. Tokenyi i obsjhaya stoimostj zadachi ne izmeryayutsya.

Yavnyij `--обработчик остаток` povtorno ispoljzuyet [susjhestvuyusjhij detektor](detektor-byudzheta-vyivoda.md) toljko posle polnogo zakhvata s fakticheskim kodom 0 ili 3. Yego vnutrennij byudzhet — 16000 bajtov; rezuljtat i otdeljnaya kvitanciya sokhranyayutsya privatno. V obsjhij otvet popadayut sostoyaniye obrabotchika, razmer i SHA rezuljtata. Oshibka JSON ne unichtozhayet originalyi i ne podmenyayet polnotu iskhodnogo zakhvata. Avtomaticheskogo opredeleniya skhemyi ili otkata k drugomu obrabotchiku net.

## Styik s yazyikom operatorov

Poljzovateljskoye trebovaniye: LLM vidit, chto vyipolnyayetsya avtomaticheski i kak, i nastraivayet eto cherez yazyik opisaniya strukturiruyusjhikh operatorov. Sejchas [opisaniye dejstviya](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Sources/FUMStructuringOperatorMemory/OpredeleniyeOperatora.swift) i [ispolnitelj](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Sources/FUMStructuringOperatorMemory/IspolneniyeOperatorov.swift) podderzhivayut konechnyiye vyichisleniya nad tekstom, bajtami i strukturnyim kontraktom. Zakhvat processov v nikh otsutstvuyet.

Sleduyusjhij soglasuyemyij styik: tipizirovannyij shag zakhvata v susjhestvuyusjhem opredelenii, yavnyij ispolnitelj effekta v prinimayusjhem sloye i vyizov etogo Python-modulya. Politika shaga dolzhna upravlyatj tajm-autom, khraneniyem i predstavleniyem; nablyudeniye svyazyivayet SHA opredeleniya, tochnogo vyizova i rezuljtata. Nepodderzhannyij shag i nepodklyuchyonnyij ispolnitelj dolzhnyi otkazyivatj do zapuska. Boljshiye potoki ostayutsya vne znachenij Swift-interpretatora. Dokazateljstvo integracii — izmeneniye opisaniya menyayet fakticheskij iskhod skvoznogo Swift→Python-vyizova s proveryayemyimi SHA.

Eto adresnaya granica daljnejshego podklyucheniya, ne realizovannyij operator ili novyij paralleljnyij yazyik. Postanovku yazyika i nablyudayemosti vedyot otdeljnaya zadacha koordinatora; zdesj sokhranenyi nablyudayemyiye faktyi zakhvata. Podgotovlennoye dejstviye, zapusk, rezuljtat i dostavka ne obyyedinyayutsya odnim priznakom uspekha.

## Proverki i profilj

[Proverki](tests/test_zakhvat_vyivoda.py) okhvatyivayut binarnyiye potoki, nenulevoj kod, povtor, tajm-aut, kvotu, uderzhaniye kanalov, zapisj, adresnyiye SHA, obrabotchik i CLI. [Profilj](tests/profilj_zakhvata_vyivoda.py) zapuskayet pyatj novyikh processov po 4 MiB na kazhdyij kanal i proveryayet oba polnyikh SHA. Komandyi vyipolnyayutsya cherez prinyatyij uchyot zapuskov proverok:

```bash
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_захват_вывода.py
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_захвата_вывода.py
```

[Sokhranyonnyij profilj](https://github.com/fum-lab/fum/blob/cb3adea7267ecb6a66c0d2399e6f1fd21afc181e/Журнал/2026-09-15_15-36-20_MSK_сохранять-полный-вывод-инструментов/материалы/профиль-захвата.json): 8388608 iskhodnyikh bajtov, 1492 bajta metadannyikh predstavleniya, mediana zakhvata 45,651 ms, predstavleniya 0,368 ms, raskryitiya 256 bajtov s polnyim SHA kanala 2,486 ms. Iskhodnyiye bajtyi ne poteryanyi; kompaktnyiye metadannyiye ne zamenyayut ikh chteniye. Uskoreniye protiv drugoj realizacii, ekonomiya tokenov i polucheniye modeljyu ne izmerenyi.

Istochnik: [zapros i utochneniya](https://github.com/fum-lab/fum/blob/cb3adea7267ecb6a66c0d2399e6f1fd21afc181e/Журнал/2026-09-15_15-36-20_MSK_сохранять-полный-вывод-инструментов/запрос.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 16:48:05 MSK -->
<!-- content-sha256: sha256:a1a4a82e5ac9499d5d67f1ae8f4868602541c83578b1ec0692939b92304db8b4 -->
<!-- FUM-MD-RECENCY:END -->
