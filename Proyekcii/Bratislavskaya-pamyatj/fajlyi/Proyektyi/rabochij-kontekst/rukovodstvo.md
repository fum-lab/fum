# Sinteticheskij sborsjhik rabochego konteksta

Odin yavnyij vyizov chitayet zaraneye podgotovlennyij fajl odnoj zadachi i vozvrasjhayet kompaktnyij JSON: celj, ogranicheniya, resheniya, obyazateljstva, zavisimosti i blizhajshiye dejstviya. Kazhdyij element svyazan s iskhodnoj strokoj i yeyo tochnyimi bajtami. Realizaciya prednaznachena dlya otkryitoj sintetiki s zaraneye razmechennyim smyislom; ona ne izvlekayet obyazateljstva iz proizvoljnogo razgovora.

Podgotovka sokhranena v promezhutochnoj kontroljnoj tochke. Okonchateljnyiye kriterii pervogo sreza ostayutsya nepogashennyimi do sovmestnoj priyomki po pravilam master v integracionnom dereve.

## Zapusk iz chistogo klona FUM

Nuzhen Python 3.10 ili noveye i yego standartnaya biblioteka. Vneshniye paketyi, setj, sekretyi i podmoduli dlya sborsjhika ne nuzhnyi. Sobstvennyiye fajlyi podpadayut pod kornevuyu [CC0](../../LICENSE); vneshniye komponentyi ne skopirovanyi.

```bash
python3 -I -S -B Проекты/рабочий-контекст/собрать-контекст.py --снимок Проекты/рабочий-контекст/фикстуры/снимок.json
```

Uspekh — kod 0 i odin JSON s zavershayusjhim LF v stdout. Kod 2 oznachayet, chto vkhod ne prinyat; stdout pust, stderr soderzhit diagnostiku bez lokaljnogo puti. Pometka `превышен_бюджет=1` yavlyayetsya rezuljtatom uspeshnogo raschyota, a ne skryityim usecheniyem ili otkazom processa. Sborsjhik ne sozdayot fajlyi, kyesh, obrabotku soobsjhenij, kvitancii, Git-kommityi i vneshniye dejstviya. Python zapusjhen bez zapisi bajtkoda. Vnutri processa snimok chitayetsya odin raz; zasjhita ot vrazhdebnogo izmeneniya fajla paralleljnyim pisatelem ne zayavlyayetsya. Vkhod obyazan byitj neizmennyim po usloviyu ispoljzovaniya.

## Vkhod i doveriteljnaya granica

Formaljnyij kontrakt khranitsya v [kontrakte formatov](kontrakt.json); ispolnyayemaya proverka — `разобрать` i `проверить_событие` v [sborsjhike](sborsjhik.py). Verkhnyaya versiya — `fum.вход-рабочего-контекста.1`. Obyazateljnyi UUID zadachi, identichnostj i podtverzhdyonnostj dostavki, fiksirovannoye UTC-vremya ocenki, zhelayemyij byudzhet UTF-8-bajtov, karta vyibrannyikh versij predmetnyikh oblastej i polnyij spisok obyyavlennyikh istochnikov.

Kazhdyij istochnik soderzhit svoj ID, versiyu, kontrakt, tot zhe UUID zadachi, dostupnostj, polnotu i tochnuyu stroku `данные` s JSONL. Polya `байты` i `хэш` otnosyatsya k UTF-8-bajtam **dekodirovannogo znacheniya** etoj stroki, vklyuchaya zavershayusjhiye LF, a ne k ekranirovannoj zapisi vnutri vneshnego JSON. Bajtyi dannyikh prinimayutsya toljko s kontraktom `fum.синтетические-события.1` i izvestnoj versiyej. Vesj peredannyij istochnik dolzhen sovpadatj s obyyavlennoj dlinoj i khyeshem; chteniye za menjshej obyyavlennoj granicej ne proizvoditsya. Nezakryitaya poslednyaya stroka otklonyayetsya.

Nedostupnyij istochnik mozhet imetj tochnyiye sokhranyonnyiye istoricheskiye dannyiye s proveryayemyimi khyeshem i versiyej. Oni ostayutsya v rezuljtate s neizvestnoj tekusjhej aktualjnostjyu; obyazateljstva iz nikh ne ischezayut. Yesli dannyikh nikogda ne byilo, `данные`, `байты` i `хэш` ravnyi null, polnota lozhna. Pustyiye istochniki 0177 i 0160 v fiksture — yavnyiye nepodklyuchyonnyiye zavisimosti, bez vyidumannogo API. Nesovpadeniye khyesha, povrezhdyonnyij JSON i neizvestnyij format dayut otkaz vsego vyizova; povrezhdyonnyiye bajtyi ne prevrasjhayutsya v uspeshnyij pustoj srez. Poslednij dostovernyij snimok khranit vyizyivayusjhaya storona.

Kazhdaya stroka uzhe razmechena kak `утверждение`, `отмена`, `приёмка` ili `сообщение`. U neyo otdeljnyiye ID, prichinnyij `порядок` i obyyavlennoye proiskhozhdeniye: chelovek, delegirovaniye, agent, sluzhebnoye, instrument ili citata. Sborsjhik proveryayet formu etikh annotacij, no ne udostoveryayet lichnostj i ne dokazyivayet ikh pravdivostj. Realjnyij adapter i smyislovaya priyomka proizvoljnyikh iskhodnikov ostayutsya za predelami pervoj versii. Odnogo teksta «gotovo», roli user ili soobsjheniya instrumenta nedostatochno dlya zaversheniya obyazateljstva.

Obsjhij vkhod ogranichen 8 MiB, chislo istochnikov — 32, chislo sobyitij — 4096. Povtor ID, povtor prichinnogo nomera, neizvestnyiye polya, povtor klyucha JSON, ciklyi zavisimostej i nekorrektnyiye tipyi otklonyayutsya. Eto konechnyiye inzhenernyiye predelyi sinteticheskogo formata, a ne izmerennyiye predelyi realjnyikh istochnikov 0177/0160. Sobyitiya s odinakovyim tekstom i raznyimi ID sokhranyayutsya otdeljno.

## Proizvodnyiye sostoyaniya

Utverzhdeniye imeyet kategoriyu, predmet, tezis, zavisimosti, neobyazateljnuyu oblastj s versiyej, neobyazateljnyij srok godnosti s politikoj i osnovaniyem, a takzhe neobyazateljnyiye dlya kratkogo rezuljtata podrobnosti. Karta vyibrannyikh versij otlichayet, naprimer, proverku koda A ot tekusjhego koda B. Vremya polucheniya ne vyibirayet pobeditelya v protivorechii. Obsjhego sroka godnosti vsekh zapisej net.

Podtverzhdyonnaya otmena trebuyet obyyavlennogo chelovecheskogo proiskhozhdeniya, izvestnoj dostavki, polnogo dostupnogo istochnika i vsekh izvestnyikh boleye rannikh celej. Ona otmenyayet toljko ukazannyiye utverzhdeniya. Delegirovannaya, citirovannaya ili sluzhebnaya otmena sokhranyayetsya kak nepodtverzhdyonnaya i delayet zatronutoye osnovaniye neopredelyonnyim. Versiya 1 ne opredelyayet delegirovannyiye polnomochiya po odnoj metke.

Raznyiye tezisyi odnogo predmeta, kategorii i versii oblasti obrazuyut konflikt, yesli utverzhdeniya yavno ne otmenenyi. Obsjhaya gruppa khranitsya odin raz; kazhdaya zapisj ssyilayetsya na yeyo ID. Eto konservativnaya proverka razmechennyikh dannyikh, a ne semanticheskoye sravneniye yestestvennogo yazyika. Yesli dva sovmestimyikh fakta razlichnyi, podgotovitelj dolzhen datj im raznyiye predmetyi.

Otmena, konflikt, neizvestnoye osnovaniye, nedostupnyij istochnik, smena versii i istecheniye zayavlennogo sroka rasprostranyayut neprigodnostj toljko na zavisimyiye vyivodyi. Nezavisimyij fakt ostayotsya aktualjnyim v svoyej oblasti. U kazhdogo vyivoda sokhranyayutsya neposredstvennaya prichina, ssyilki na predkov i ikh prichinyi; cepochka raskryivayetsya bez dogadki. `актуально` oznachayet prigodnostj toljko otnositeljno prinyatogo snimka.

Otdeljnaya chelovecheskaya priyomka adresuyet boleye ranneye obyazateljstvo i soderzhit nezavisimyiye boleye ranniye utverzhdeniya kategorii «resheniye» kak dokazateljstva. Vse celi dolzhnyi susjhestvovatj; nedostupnoye, otsutstvuyusjheye ili ustarevsheye dokazateljstvo ne zakryivayet obyazateljstvo. Sobstvennoye obyazateljstvo ne dopuskayetsya kak pryamoye dokazateljstvo. Eto proverka svyazej **yavno prinyatoj sinteticheskoj priyomki**, a ne proverka realjnyikh testov, rezuljtatov, avtora ili integracii. Zavershyonnoye obyazateljstvo ne dokazyivayet vyipolneniye ostaljnyikh.

Pole `ближайшие_действия` perechislyayet toljko aktualjnyiye v snimke utverzhdeniya etoj kategorii. Eto dannyiye dlya chteniya, bez ispolneniya ili vyidachi razreshenij. Pri neizvestnoj dostavke oni ne obyyavlyayutsya aktualjnyimi.

## Byudzhet, vosproizvedeniye i raskryitiye

Vyikhod versii `fum.рабочий-контекст.1` svyazyivayet UUID, SHA-256 **polnyikh syiryikh bajtov vneshnego vkhoda**, versii sborsjhika i istochnikov, dostavku i vremya ocenki. Povtor odnikh i tekh zhe bajtov dayot te zhe bajtyi rezuljtata nezavisimo ot vremeni zapuska i puti fajla. Inoye formatirovaniye vneshnego JSON menyayet khyesh vkhoda. Profilirovochnyiye metki ne vkhodyat v stdout.

Vse tezisyi, obyazateljstva, otmenyi, konfliktyi, neizvestnostj, prichinyi i ukazateli obyazateljnyi. Oni sokhranyayutsya pri byudzhete 0 i 1. Sokrasjhayetsya toljko prefiks neobyazateljnyikh podrobnostej. Yesli obyazateljnaya chastj boljshe byudzheta, rezuljtat soderzhit yeyo celikom, `превышен_бюджет=1`, tochnyij `размер_байт` i nepolnotu podrobnostej. Flag — celoye 0 ili 1 postoyannoj dlinyi: eto pozvolyayet tochno uchityivatj razmer JSON bez kolebaniya dlinyi logicheskikh slov. Byudzhet zhelayemyij, a ne zhyostkij predel kanala; potrebitelyu s zhyostkim predelom sleduyet zaraneye umenjshitj vkhod.

`полнота_источников` i `подробности_полны` nezavisimyi. Polnyij spisok podrobnostej ne ustranyayet nedostupnyij istochnik. Polnota otnositsya toljko k obyyavlennomu inventaryu, a ne ko vsem soobsjheniyam realjnoj zadachi. Yesli istochnika net v inventare, sborsjhik ne znayet o yego susjhestvovanii.

Ukazatelj soderzhit ID i versiyu istochnika, nomer stroki ot 1, poluotkryityij diapazon UTF-8-bajtov `[начало, конец)` i SHA-256 stroki s LF. Dlya raskryitiya vozjmite znacheniye `данные` sootvetstvuyusjhego istochnika, kodirujte yego v UTF-8, vyidelite diapazon i sverjte khyesh. Nezavisimyij test proveryayet kazhdyij ukazatelj po sokhranyonnyim bajtam.

Staryij vkhod A posle vkhoda B vosproizvodit A, ogranichennyij yego sobstvennoj dostavkoj. On ne obnaruzhivayet otsutstvuyusjhuyu v nyom otmenu iz B. Dlya sokhraneniya pozdnej otmenyi peredayut novyij polnyij snimok s pervonachaljnyimi dannyimi i otmenoj. Kyesh, tekusjhij opros i dolgovechnyiye perekhodyi A → B → A zdesj ne realizovanyi.

## Proverki i profilj

Komandyi samostoyateljnogo vosproizvedeniya iz klona:

```bash
python3 -B -m unittest discover -s Проекты/рабочий-контекст/tests -p 'test_*.py'
python3 -B Проекты/рабочий-контекст/профиль.py --выход <путь-к-временному-файлу-профиля>
```

Otdeljnaya proverka formaljnoj skhemyi ispoljzuyet `jsonschema` 4.23.0. Dlya neyo sozdayotsya vremennoye okruzheniye vne checkout i ustanavlivayetsya [zafiksirovannyij nabor](zavisimosti-proverki-skhemyi.txt); eta podgotovka mozhet trebovatj setj. Posle ustanovki sama proverka avtonomna. Ona zapuskayetsya Python etogo okruzheniya komandoj `python3 -B Проекты/рабочий-контекст/проверить-контракт.py`. Proveryayetsya metaskhema Draft 2020-12, otkryityij vkhod, vyikhod pri chetyiryokh byudzhetakh i shestj zaraneye zadannyikh nevozmozhnyikh pasportov. Nabor izmeren na Python 3.14.7; sborsjhik i osnovnoj profilj obkhodyatsya standartnoj bibliotekoj. Izmereniye RSS v profile podderzhivayet macOS i Linux.

[Staticheskij etalon](fiksturyi/etalon.json) podgotovlen do realizacii po nezavisimomu chteniyu postanovki. On ne vyichislyayetsya sborsjhikom. Snachala proveryayutsya sokhrannostj obyazateljstv i zapretyi lozhnoj priyomki; zatem izmeryayutsya obyyom, monotonnoye vremya i RSS svezhego processa. Malyij profilj vklyuchayet 21 iskhodnoye sobyitiye i konfliktuyusjhiye naboryi iz 20, 100 i 400 obyazateljstv, po tri povtora. Podgotovka ne vkhodit vo vnutrennyuyu sborku; RSS okhvatyivayet vesj worker. Vlozhennyiye intervalyi ne summiruyutsya povtorno. Tokenyi, akkauntnyiye limityi, zhivyiye metriki zadachi i effekt realjnoj ekspluatacii neizvestnyi.

Iskhodnyij variant, tochnyiye zameryi do/posle, resheniye ob optimizacii i ogranicheniya nakhodyatsya v [otchyote etapa](../../Zhurnal/2026-09-12_03-42-08_MSK_realizovatj-sinteticheskij-rabochij-kontekst/otchyot.md). Porog polnogo 0165 etim malyim profilem ne ustanovlen.

## Vosproizvedeniye izmerennyikh prezhnikh variantov

V materialakh otchyota `исходный-срез.json` i `оптимизированный-срез.json` soderzhat rovno po shestj prezhnikh fajlov: putj, SHA-256 i iskhodnyiye bajtyi s yavnyim kodirovaniyem base64. Eto otkryityiye istoricheskiye dannyiye; tekusjhaya postavka nakhoditsya v obyichnyikh fajlakh ryadom s rukovodstvom. Imena polej prezhnego varianta otlichayutsya ot konechnogo v1 po sokhranyonnomu sopostavleniyu.

Dlya vosstanovleniya vyiberite novyij pustoj vremennyij katalog vne checkout. Peredajte putj nuzhnogo kontejnera i putj etogo kataloga vmesto parametrov:

```bash
python3 -B - <контейнер.json> <новый-временный-каталог> <<'PY'
import base64, hashlib, json, sys
from pathlib import Path, PurePosixPath
контейнер = json.loads(Path(sys.argv[1]).read_text())
assert контейнер['схема'] == 'fum.архив-исходных-байтов.1'
assert контейнер['кодирование'] == 'base64'
каталог = Path(sys.argv[2])
assert not каталог.exists()
каталог.mkdir(parents=True)
for имя, запись in контейнер['файлы'].items():
    путь = PurePosixPath(имя)
    assert not путь.is_absolute() and '..' not in путь.parts
    данные = base64.b64decode(запись['данные'], validate=True)
    assert hashlib.sha256(данные).hexdigest() == запись['хэш']
    файл = каталог.joinpath(*путь.parts)
    файл.parent.mkdir(parents=True, exist_ok=True)
    файл.write_bytes(данные)
PY
python3 -B <временный-каталог>/профиль.py --выход <путь-к-результату>
```

## Sokhranyonnyij plan i ostatok

[Polnaya kartochka 0165](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) ostayotsya aktivnoj. Vse pyatj istoricheskikh planovyikh materialov iz `186b0360a31b97184773757634976257d0f86495`, vklyuchaya deklarativnyiye sluchai 01–28, sokhranenyi. Ogranichennaya realizaciya peresekayetsya s nimi tak:

- 01–04: sinteticheskiye svojstva otmenyi, versij, nedostupnosti i zavisimogo ustarevaniya.
- 05: tochnyij povtor i raznyiye ID; ustojchivyij kyesh i istoriya perekhodov ne realizovanyi.
- 06: otdeljnaya priyomka protiv soobsjheniya «gotovo»; realjnyiye proverki i integraciya ne nablyudayutsya.
- 07: sokhranenyi obyyavlennyiye vidyi proiskhozhdeniya; syiroj dialog i adapter 0177 ne klassificiruyutsya.
- 08: yavnyij nedostatochnyij byudzhet i tochnyiye ukazateli.
- 09–10: lishj princip kachestva pered ekonomiyej i malyij profilj; zhivyiye resursyi i korrektiruyusjhiye dejstviya ne realizovanyi.
- 11–25: polnostjyu ostayutsya planom — vnimaniye, detektoryi, obratnaya svyazj, schyot kommitov, signalyi, epokhi i vosstanovleniye.
- 26–28: toljko peresecheniye s otmenoj dannyikh, otsutstviyem zapisi obrabotki, obyyavlennyimi versiyami/dostupnostjyu i stoimostjyu etogo CLI. Adapteryi, perekhodyi vnimaniya i realjnyiye dejstviya otsutstvuyut.

Sokhranenyi budusjhiye obyazateljstva adapterov 0177/0160, nezavisimoj priyomki realjnyikh istochnikov, izmereniya vosstanovleniya i daljnejshej integracii. Etot srez ne obyyavlyayet realizovannyim vesj princip vosproizvedeniya sostoyaniya ili vesj istoricheskij nabor.

## Svyazannyij nativnyij srez

[Operatornyiye modeli otveta](operatornyiye-modeli-otveta.md) opisyivayut otdeljnyij dejstvuyusjhij kontrakt: odno opisaniye porozhdayet Swift Codable, Python-modeli i kompaktnuyu proyekciyu nativnogo otveta. Sinteticheskij sborsjhik vyishe sokhranyayet svoyu prezhnyuyu oblastj.

## Istochniki

- [Tochnoye konechnoye naznacheniye i utochneniya](../../Zhurnal/2026-09-12_03-42-08_MSK_realizovatj-sinteticheskij-rabochij-kontekst/zapros.md).
- [Istoricheskaya postanovka i polnyij manifest](../../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/naznacheniya/FUM-STEP-0165.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 17:04:07 MSK -->
<!-- content-sha256: sha256:514a9972ee87e1a6039837dd21e3361732ec41be62cb268640d7756cab54d6dd -->
<!-- FUM-MD-RECENCY:END -->
