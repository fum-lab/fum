# Otchyot 2026-09-15 19:04:26 MSK - Integrirovatj ispolneniye operatora FUMA

Podgotovlena proverennaya kontroljnaya tochka pervoj vertikali osnovnogo rantajma FUMA: yavnyiye opredeleniye i vkhod → susjhestvuyusjhij interpretator v processe prilozheniya → rezuljtat i nakopiteljnaya dolgovremennaya zapisj. Rezhim vyizyivayetsya iz nastoyasjhego `@main` do scenyi i razreshenij. SwiftPM i Xcode ispoljzuyut odni iskhodniki adaptera i lokaljnyiye paketyi interpretatora i pamyati.

Osnovnoj predmetnyij scenarij — sokhranyonnyij UTF-8 → Unicode-skalyaryi → UTF-32LE; `Aё🙂` dayot 12 ozhidayemyikh bajtov i tri shaga trassyi pravil. Vkhod s nevernyim UTF-8 otklonyayetsya. [Instrukciya](../../Prilozheniya/FUMA/macOS/docs/ispolneniye-operatora.md) soderzhit komandyi obeikh sborok, realjnyikh binarnikov, povtora i profilya.

Eto ogranichennaya postavka svoyej vetki ot `f93d35b62710953a4db275cf125a1af25cbf4c20`. Publikaciya vetki i yeyo integraciya kornem imeyut otdeljnyiye svideteljstva. Obsjhaya priyomka FUM, obnovleniye proizvodnoj proyekcii i zakryitiye vsej zadachi ne zayavlenyi.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                           |
| ------------------------ | ------------ | ---------------------------------------------------- |
| Dopusk i soderzhateljnaya rabota | ne izmereno | Ot sozdaniya svoyej vetki i papki zaprosa do podgotovki kontroljnoj tochki; otdeljnyij monotonnyij tajmer ne ustanovlen |
| Adresnyiye proverki i sborki | sm. tablicu nizhe | Realjnyiye pryamyiye processyi izmerenyi otchyotnoj obyortkoj; povtornyiye i neuspeshnyiye zapuski sokhranenyi |
| Profilirovaniye nastoyasjhikh binarnikov | 5 obrazcov na variant | Monotonnyiye metki processa i vlozhennyikh etapov; tochnyiye nanosekundyi sokhranenyi v otkryityikh profilyakh |
| Polnyij smoke-check i proyekciya | ne zapuskalisj | Po yavnoj granice kontroljnoj tochki kornya; sovmestnaya priyomka ostayotsya otdeljnoj |
| Publikaciya i posleduyusjhaya integraciya | ne izmereno | Ne vkhodyat vo vremennyiye intervalyi testovyikh processov; uspekh proveryayetsya tochnyimi Git OID otdeljno |

Granica profilya: papka zaprosa otkryita 2026-09-15 19:04:26 MSK; izmerenyi toljko realjno obyornutyiye pryamyiye processyi i yavnyiye intervalyi CLI. Ikh summa ne yavlyayetsya kalendarnoj dliteljnostjyu rabotyi. Sborki ogranichenyi dvumya zadaniyami; regressii zapuskayut binarniki posledovateljno. FIFO i avtomaticheskaya peredacha ne ispoljzovalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                          | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------ | ------------ | --------- |
| [Integrator FUMA] RED — ispolneniye, povtor i otkazyi zapisi                     | 30,791 s     | neuspeshno |
| [Integrator FUMA] GREEN — ispolneniye, povtor i otkazyi zapisi                   | 7,371 s      | neuspeshno |
| [Integrator FUMA] GREEN — fizicheskij putj zhurnala i chetyire scenariya            | 4,879 s      | uspeshno   |
| [Integrator FUMA] Nastoyasjhij SwiftPM-vkhod — povtoryi, otkazyi i profilj           | 3,467 s      | uspeshno   |
| [Integrator FUMA] SwiftPM — okonchateljnaya sborka i scenarii API                | 4,857 s      | uspeshno   |
| [Integrator FUMA] Xcode — FUMA.app s lokaljnyim ispolnitelem i pamyatjyu          | 24,455 s     | uspeshno   |
| [Integrator FUMA] SwiftPM CLI — UTF-32, trassa, istoriya i profilj              | 1,758 s      | uspeshno   |
| [Integrator FUMA] FUMA.app — nastoyasjhij vkhod, UTF-32, povtoryi i profilj         | 1,921 s      | uspeshno   |
| [Integrator FUMA] Tochnyij diff — otsutstviye oshibok probelov                     | 0,079 s      | uspeshno   |
| [Integrator FUMA] Publikacionnaya chistota — mashinno-lokaljnyiye puti              | 33,314 s     | neuspeshno |
| [Integrator FUMA] Indeks kontroljnoj tochki — tochnyij diff                       | 0,039 s      | neuspeshno |
| [Integrator FUMA] Indeks kontroljnoj tochki — tochnaya granica probelov fiksturyi  | 0,042 s      | uspeshno   |
| [Integrator FUMA] SwiftPM — itogovaya otkryitaya fikstura i profilj               | 1,703 s      | uspeshno   |
| [Integrator FUMA] Xcode — itogovaya otkryitaya fikstura i profilj                 | 1,534 s      | uspeshno   |
| [Integrator FUMA] Itogovyij indeks — proverka probelov vsekh fajlov              | 0,041 s      | uspeshno   |
| [Integrator FUMA] Zaregistrirovannyij LinguisticKit — tochnyij gitlink dlya ssyilok | 0,602 s      | neuspeshno |
| [Integrator FUMA] LinguisticKit — svyazannyij Git-katalog i zakreplyonnaya reviziya | 0,564 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 117,417 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- RED: chetyire scenariya provalilisj na zaglushke sokhraneniya posle uspeshnoj sborki. Pervonachaljnyij GREEN vyiyavil tri otkaza `ENOTDIR`: Foundation mog vozvrasjhatj logicheskij vremennyij putj vmesto fizicheskogo. Adapter i fikstura ispoljzuyut `realpath`; sleduyusjhij GREEN i okonchateljnyij zapusk prokhodyat vse chetyire testa.
- Swift-testyi podtverzhdayut nakopleniye, povtor posle udaleniya iskhodnyikh fajlov, otkaz neizvestnogo operatora do zapisi, inyyekciyu `ENOSPC` bez izmeneniya prezhnikh bajtov i oshibku `fsync` bez uspeshnoj kvitancii s sokhraneniyem podtverzhdyonnogo prefiksa.
- Realjnyij SwiftPM-binarnik prokhodit polnyij Python-scenarij. Xcode sobral `FUMA.app`; osnovnoj ispolnyayemyij fajl prilozheniya prokhodit tot zhe scenarij. Poslednij proveryayet UTF-32LE i trassu, tochnyij determinirovannyij povtor s novoj zapisjyu, smeshannyiye flagi razreshenij, povtornyiye/nepolnyiye argumentyi, nevernyiye opredeleniye i UTF-8, putj vnutri Git, simvolicheskuyu ssyilku, neprivatnyij katalog i sokhrannostj nepolnogo khvosta.
- Obyichnyiye peremennyiye putej rantajma namerenno zadanyi nedopustimyimi. Vmeste s rannim `exit` v `@main` i otkazom smeshannyikh flagov eto podtverzhdayet ogranichennyij CLI-putj do obyichnoj inicializacii prilozheniya. Interaktivnyij graficheskij seans ne proveryalsya.
- Chteniye finaljnogo koda pomosjhnikom ne vyiyavilo konkretnyikh defektov. Zamechaniye ob aktivacii profilya bez flaga ispravleno do okonchateljnyikh sborok: peredayotsya `nil`.
- V sborkakh ostalisj prezhniye preduprezhdeniya ustarevshikh OpenGL API i lokaljnoj versii macOS biblioteki mpv. Rabota na minimaljnoj macOS 14 ne proverena; podpisj i rasprostraneniye prilozheniya etim zapuskom ne podtverzhdayutsya.
- Obsjhij skaner mashinno-lokaljnyikh putej vernul kod `1`: dva `error.posix-absolute` v neizmenyonnom `Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_устойчивые_свидетельства.py`, stroki 183 i 199. Bajtyi sverenyi s bazovyim HEAD; sobstvennyij delta ne soderzhit diagnostirovannyikh narushenij. Eto prezhnij neproshedshij dopusk bazyi, peredavayemyij kornyu dlya sovmestnoj priyomki; chuzhoj proverochnyij instrument i yego politika ne izmenyalisj. Polnyij zakhvat stdout sokhranyon vne Git, SHA-256 `7a8bf029ace515aaaf74f52f3952ec93bfe3c357a1fb5f1a9988ebe2a1ab3648`.
- Pervaya proverka indeksirovannogo diff obnaruzhila konechnyiye probelyi otkryitogo vkhoda normalizacii. Proveren tochechnyij atribut, odnako yego format otsutstvuyet v dejstvuyusjhem proyekcionnom kontrakte; on isklyuchyon iz postavki. V fajlovoj fiksture udalenyi toljko konechnyiye probelyi, povtorenyi obe korotkiye regressii nastoyasjhikh binarnikov s novyimi profilyami. Swift-test sokhranyayet proverku konechnyikh probelov v strokovom literale. Ispolnyayemyiye iskhodniki ne izmenilisj; novaya sborka ne trebovalasj.
- Pervyij read-only-dopusk kontroljnoj tochki nashyol chetyire nedostupnyiye istoricheskiye ssyilki v otsutstvuyusjhem LinguisticKit. Zavisimostj materializovana polnocennyim klonom forka, oba remote poluchenyi, vyibran prezhnij tochnyij gitlink. GitHub API podtverdil publichnyij fork `fum-lab/LinguisticKit`, roditelya `Roman-Kerimov/LinguisticKit` i CC0-1.0. Pervyij adresnyij validator otklonil vstroyennyij `.git` klona; shtatnyij `absorbgitdirs` perenyos yego v administrativnuyu oblastj toljko sobstvennogo worktree. Povtornyij validator proveryayet svyazannuyu topologiyu; iskhodniki zavisimosti, `.gitmodules` i gitlink ne izmenenyi.

## Izmereniye i resheniye ob optimizacii

| Variant | Process, ms | Vkhod, ms | Dekodirovaniye, ms | Ispolneniye, ms | Sokhraneniye, ms |
| --- | --- | --- | --- | --- | --- |
| Iskhodnyij SwiftPM | 70,817125 | 3,988625 | 0,511833 | 0,650667 | 3,070833 |
| Itogovyij SwiftPM | 70,730125 | 3,677791 | 0,484375 | 0,654833 | 2,799917 |
| Itogovyij Xcode | 75,300500 | 2,896792 | 0,506500 | 0,654292 | 2,945291 |

Eto medianyi pyati posledovateljnyikh vyizovov normalizacii na odnom otkryitom vkhode vnutri kazhdogo varianta s nakopleniyem zapisej. Vremya processa vklyuchayet zapusk Swift/Foundation i vyivod otveta. Chetyire vneshnikh etapa i vlozhennyiye intervalyi ne skladyivayutsya drug s drugom. Sborka isklyuchena. Iskhodnyij profilj poluchen do otklyucheniya nenuzhnogo priyomnika metok; on svyazan s prezhnim binarnikom, a ne s okonchateljnyimi iskhodnikami. Itogovaya fajlovaya fikstura otlichayetsya otsutstviyem konechnyikh probelov; dva itogovyikh adresnyikh zapuska chastichno perekryivalisj. Eti serii ne yavlyayutsya kontroliruyemyim sravneniyem skorosti. Vyichislitelj zanimayet meneye millisekundyi na etikh vkhodakh, poetomu optimizaciya algoritma ne obosnovana; otklyuchyon toljko nenuzhnyij sbor metok bez flaga.

Tochnyiye nablyudeniya: [iskhodnyij SwiftPM](materialyi/profili/iskhodnyij-SwiftPM.json), [itogovyij SwiftPM](materialyi/profili/itogovyij-SwiftPM.json), [itogovyij Xcode](materialyi/profili/itogovyij-Xcode.json), serii do izmeneniya fiksturyi [SwiftPM](materialyi/profili/do-pravki-fiksturyi-SwiftPM.json) i [Xcode](materialyi/profili/do-pravki-fiksturyi-Xcode.json). Itogovyiye profili svyazyivayut binarniki, opredeleniya, otkryituyu fiksturu i iskhodniki SHA-256. V nikh net privatnyikh putej i poljzovateljskikh dannyikh. Profilj ne menyayet determinirovannoye nablyudeniye; eto provereno sravneniyem vyizovov s flagom i bez nego.

## Resheniya i ogranicheniya

- Povtorno ispoljzovan susjhestvuyusjhij `КонтейнерНаблюдений`: `fsync`, blokirovka, proverka celostnosti, nakopleniye i otkaz pri nepolnom khvoste ostayutsya v odnoj biblioteke. Opredeleniye razbirayetsya susjhestvuyusjhim dekoderom; pryamoj vyizov susjhestvuyusjhego interpretatora ne ispoljzuyet IPC.
- Polnaya prinyataya zapisj khranit tochnyiye iskhodnyiye i kanonicheskiye bajtyi opredeleniya, tochnyiye bajtyi i tip vkhoda, versiyu profilya predelov, rezuljtat i trassu. Sluchajnyij identifikator i vremya otnosyatsya k opisaniyu kontejnera i otdelenyi ot determinirovannogo payload. Povtor proveryayet profilj i khyesh rezuljtata do dobavleniya novogo nablyudeniya.
- Pri otkaze sinkhronizacii zapisj mozhet statj vidimoj bez vyidannoj kvitancii. Eto yavno opisano; avtomaticheskij povtor i udaleniye khvosta ne vyipolnyayutsya. Apparatnoye otklyucheniye pitaniya ne ispyitano. Rotaciya segmenta i potokovaya obrabotka porciyami ne vkhodyat v etu vertikalj.
- Otkryityij terminaljnyij zhurnal proverok sokhranyayetsya kak kontroljnaya tochka. Polnyij smoke-check, zakryitiye otchyota i aktualjnoye pokoleniye proyekcii nuzhnyi dlya otdeljnoj sovmestnoj priyomki u kornya.
- V etoj vetke sokhraneno iskhodnoye pokoleniye `Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json` iz bazovogo HEAD: khyesh vkhodnogo inventarya `sha256:651149712a44cbaefb8a7c90d7d2d48eb22bda9f4386dd4a089ecd220b33a724`, khyesh plana `sha256:a31fe342a679fd229086934e99ea600304dbd6b18e474eebb77719e3621d3024`. Politika `sha256:5ecd1d393cb59ab5ccfaeebc9d43a6c93476125547698c47283e6a348af6fb21`. Eto prochitannoye proiskhozhdeniye prezhnego pokoleniya; zdesj ono zanovo ne proveryalosj i otstayot ot dobavlennyikh kanonicheskikh fajlov.
- Vetka prednaznachena dlya nastoyasjhego merge-kommita kornem. Obsjhiye Zhurnal, navigaciya i indeks svezhesti trebuyut smyislovogo sliyaniya s tekusjhej `fuma`; predmetnyij kod ne kopiruyetsya v otdeljnuyu linejnuyu istoriyu. Neprinyatyikh storonnikh izmenenij v sobstvennyij obyyom ne dobavleno.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:42:24 MSK -->
<!-- content-sha256: sha256:4c13fd20a9269c188d39a450b53b0b8e828217d1d622a578a96b7264ff99d4e6 -->
<!-- FUM-MD-RECENCY:END -->
