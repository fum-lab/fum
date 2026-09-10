# Otchyot 2026-09-09 14:58:37 MSK - Nakaplivatj statistiku vyizovov iz zhurnala

Ogranichennyij importyor zavershyonnogo prefiksa Codex JSONL realizovan: atomarnaya gruppa sobyitij i granicyi v prinyatom kontejnere, vosstanovleniye posle perezapuska, CLI JSON/Markdown, 35 GREEN i izmerennyiye optimizacii. Itogovyij Swift commit `85dccce282821a890e5e65539b4f22b895b52887`, tree `12dcada40e1e715f3ede0efdd578c74d4f42ea7b`; rabocheye derevo chistoye. [Manifest importyora](materialyi/iskhodniki-importyora.json) fiksiruyet 20 fajlov. Realjnyij privatnyij JSONL ne chitalsya; integraciya i priyomka vsego FUM ostayutsya kornyu.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| FIFO / handoff | neprimenimo | Staryij konvejyer ne zapuskalsya; sobstvennyiye izolirovannyiye worktree |
| Soderzhateljnaya rabota | ne izmereno | Nachalo etapa 14:58:37 MSK; polnyij monotonnyij interval sessii ne sokhranyon |
| Pryamyiye proverki i sborki | nizhe | v4 uchityivayet kazhdyij process, vklyuchaya RED, oshibki fikstur i povtoryi |
| Itogovyiye 35 XCTest | 3,670 s | №47; otdeljno SwiftPM build 0,89 s, oni ne zamenyayut dliteljnostj vneshnego vyizova |
| Itogovyij rabochij import | 1,127347 s | №40, 105356966 publichnyikh sinteticheskikh bajtov, 16609 strok |
| Povtor rabochego prefiksa | 0,118136 s | №40; snova prochitanyi vse 105356966 bajtov, bez rosta schyotchikov/kontejnera |
| Obsjhij smoke-check FUM | ne zapuskalsya | Obsjhaya priyomka i proyekciya prinadlezhat kornyu |

Granica profilya: v4 №1–49 okhvatyivayet fakticheskiye adresnyiye testyi, sborki, profilj, yazyikovuyu proverku i proverki tochnogo indeksa/ravenstva otchyota. Read-only-osmotr, analiz, redaktirovaniye, perenos, materializaciya zakreplyonnoj zavisimosti, kommityi i push ne vklyuchenyi v summu call-time. Zaklyuchiteljnyiye recency, exact preview i proverka kontroljnoj tochki zamyikayut izmenivshijsya otchyot otdeljno i ne porozhdayut povtor polnogo kontura.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                      | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------ | ------------ | --------- |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 18,274 s     | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 4,126 s      | uspeshno   |
| [Razrabotchik statistiki] Posle perenosa: 12 Swift-testov statistiki                        | 18,719 s     | uspeshno   |
| [Razrabotchik statistiki] Tochnyij indeks yadra statistiki                                     | 0,018 s      | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 3,255 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 2,732 s      | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 2,928 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 1,901 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 1,744 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 3,027 s      | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 3,601 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 3,928 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 3,691 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 5,41 s       | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 4,688 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 4,674 s      | uspeshno   |
| [Razrabotchik statistiki] Inventarj imyon paketa statistiki                                  | 0,321 s      | uspeshno   |
| [Razrabotchik statistiki] Regressiya bezopasnogo perevoda imyon                               | 1,468 s      | uspeshno   |
| [Razrabotchik statistiki] Sukhoj plan russkikh obyyavlenij                                     | 0,135 s      | uspeshno   |
| [Razrabotchik statistiki] Russkiye imena: RED do preobrazovaniya                              | 0,258 s      | neuspeshno |
| [Razrabotchik statistiki] Polnyij sukhoj plan russkikh obyyavlenij                              | 0,144 s      | uspeshno   |
| [Razrabotchik statistiki] Russkiye imena: GREEN posle preobrazovaniya                         | 0,295 s      | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 6,494 s      | uspeshno   |
| [Razrabotchik statistiki] Release-sborka profilya statistiki                                 | 9,082 s      | uspeshno   |
| [Razrabotchik statistiki] Profilj do optimizacii: 32 vyizova                                 | 0,558 s      | uspeshno   |
| [Razrabotchik statistiki] Profilj do optimizacii: 2048 vyizovov i 8 MiB nerelevantnyikh dannyikh | 0,993 s      | uspeshno   |
| [Razrabotchik statistiki] RED: krajneye smesjheniye do arifmetiki                               | 2,405 s      | neuspeshno |
| [Razrabotchik statistiki] Khyesh iskhodnogo boljshogo otchyota                                     | 0,349 s      | uspeshno   |
| [Razrabotchik statistiki] RED: rabochaya stroka i bezopasnyij profilj                          | 2,328 s      | neuspeshno |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 7,257 s      | uspeshno   |
| [Razrabotchik statistiki] Release posle gruppirovki i novyikh byudzhetov                        | 5,567 s      | uspeshno   |
| [Razrabotchik statistiki] Profilj posle optimizacii: 32 vyizova                              | 0,519 s      | uspeshno   |
| [Razrabotchik statistiki] Profilj posle optimizacii: 2048 vyizovov                           | 0,573 s      | uspeshno   |
| [Razrabotchik statistiki] Publichnyij rabochij profilj: 105356966 bajtov i 16609 strok         | 2,876 s      | uspeshno   |
| [Razrabotchik statistiki] Khyesh boljshogo otchyota posle optimizacii                             | 0,297 s      | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 6,168 s      | uspeshno   |
| [Razrabotchik statistiki] Release posle ogranicheniya vremennyikh obyyektov strok                | 4,532 s      | uspeshno   |
| [Razrabotchik statistiki] Finaljnyij malyij profilj s osvobozhdeniyem vremennyikh obyyektov        | 0,506 s      | uspeshno   |
| [Razrabotchik statistiki] Finaljnyij boljshoj profilj s osvobozhdeniyem vremennyikh obyyektov      | 0,625 s      | uspeshno   |
| [Razrabotchik statistiki] Finaljnyij rabochij profilj s osvobozhdeniyem vremennyikh obyyektov      | 2,984 s      | uspeshno   |
| [Razrabotchik statistiki] Statistika JSONL: adresnyiye Swift-testyi                            | 7,156 s      | uspeshno   |
| [Razrabotchik statistiki] Itogovaya proverka russkikh obyyavlenij                              | 0,295 s      | uspeshno   |
| [Razrabotchik statistiki] Tochnyij indeks dolgovechnogo importyora                              | 0,022 s      | neuspeshno |
| [Razrabotchik statistiki] Itogovyij khyesh boljshogo otchyota                                      | 0,293 s      | uspeshno   |
| [Razrabotchik statistiki] Povtor proverki indeksa posle udaleniya pustyikh strok EOF           | 0,042 s      | uspeshno   |
| [Razrabotchik statistiki] RED oracle: validnaya sverkhlimitnaya stroka pri otklyuchyonnoj zasjhite  | 3,961 s      | neuspeshno |
| [Razrabotchik statistiki] GREEN: 35 testov s tochnyim oracle limita i vosstanovlennoj zasjhitoj | 5,339 s      | uspeshno   |
| [Razrabotchik statistiki] Tochnyij itogovyij indeks posle usileniya oracle                      | 0,041 s      | uspeshno   |
| [Razrabotchik statistiki] Tochnyij indeks FUM: zhurnal i manifest importyora                    | 0,022 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 156,621 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:5285f91dc1dde926df9f4e2660dc88c3aed818f20aec1fc07ad99abd8854c8ca.
Kontekst soderzhimogo: sha256:bb810ca52bbe1197dea9781ba5997ef23d9dedda6a6f893e264e8eb10ceb2f8b.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Produktovyij profilj i optimizaciya

Vse vkhodyi sozdanyi otkryityim generatorom paketa. «Rabochij» nabor povtoryayet toljko soobsjhyonnyiye kornem razmeryi, a ne soderzhimoye ili chislo sobyitij chastnogo JSONL. Generaciya i fsync vyipolnyayutsya pered tajmerom, poetomu istochnik progret. Vremya izmereno `DispatchTime`, pamyatj — `ru_maxrss` vsego processa Darwin v bajtakh; eto maksimum processa, ne chistyiye vyideleniya importyora. Odin zamer na scenarij ne yavlyayetsya statisticheskim benchmark.

| Itogovyij nabor | Bajtyi / stroki | Vyizovyi / instrumentyi | Import, ms | Povtor, ms | Otchyot v pamyati, ms | JSON, ms | Replay, ms | Pik processa, MiB |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Malyij | 10325 / 65 | 32 / 32 | 5,537 | 0,485 | 0,068 | 1,397 | 2,496 | 10,844 |
| Boljshoj | 9054449 / 4113 | 2048 / 2048 | 266,293 | 17,171 | 5,746 | 90,105 | 141,051 | 56,438 |
| Rabochij | 105356966 / 16609 | 2048 / 2048 | 1127,347 | 118,136 | 5,845 | 85,706 | 136,314 | 66,391 |

- Do optimizacii boljshoj nabor: import 380,852 ms, povtor 129,479 ms, postroyeniye otchyota 119,404 ms. Povtornyij polnyij filjtr po vsem vyizovam dlya kazhdogo instrumenta zamenyon yedinstvennoj gruppirovkoj. Neposredstvenno posle neyo: 262,247 / 16,350 / 5,142 ms sootvetstvenno. Algoritmicheskaya chastj gruppirovki boljshe ne trebuyet O(instrumentyi × vyizovyi); sortirovki ostayutsya.
- Rabochij profilj zatem vyiyavil uderzhaniye vremennyikh Foundation-obyyektov: pik 353239040 bajtov (336,875 MiB), yesjhyo do importa 195690496 bajtov posle generacii. Lokaljnyij `autoreleasepool` na kazhduyu stroku chitatelya i generatora snizil itogovyij pik do 69615616 bajtov (66,391 MiB), do importa — 20217856 bajtov. Import 1,119 → 1,127 s: uskoreniye etogo prokhoda ne zayavleno.
- Razmer maksimaljnoj rabochej sinteticheskoj stroki — 3326896 bajtov; paket — 1931892 bajta, JSON-otchyot — 4808827 bajtov. Khyesh rabochej fiksturyi do/posle sovpadayet: `b9ffd417578d3f805223edfef1171a871b882b031ce6644c4db6086a49f399c5`.
- Tochnyij boljshoj JSON s LF do i posle obeikh optimizacij sokhranyayet SHA-256 `a8379466439a2e709e4b5cde510565fd8136074f38de8453cdaa8c010effddb4` (№28, №35, №44). Eto dopolneniye k testam, ne dokazateljstvo vsekh vkhodov.
- [Syiryiye chislennyiye rezuljtatyi i khyeshi izmerennyikh versij](materialyi/profili-izmerenij.json), [prezhnij algoritm uchyota](materialyi/uchyot-do-optimizacii.swift.txt). Izmerennyij release-binarnyij fajl ne vklyuchyon v Git; posle profilya pereimenovanyi testovyiye fajlyi, usilen oracle limita i udalenyi tri pustyiye stroki EOF. Ispolnyayemaya semantika produkta sokhranena; khyesh binarnogo fajla ne obyyavlyayetsya vosproizvodimostjyu sborki tochnogo kommita.

## Proverki i obnaruzhennyiye oshibki

- №1: 12 predmetnyikh RED, 36 utverzhdenij pri uspeshnoj kompilyacii; №2 i №3: 12 GREEN. Do №3 obyortka otkazala yesjhyo do zapisi/processa iz-za nematerializovannogo gitlink. LinguisticKit vosstanovlen shtatnyim `submodule update --no-fetch --checkout --reference` na prezhnem `837e2ce107b97ee7b9d3344c9fe99142281fe393`, gitlink ne izmenyon.
- №5–6: publichno dekodirovannyiye sobyitiya teperj prokhodyat strogij preflight do uchyota; 15 GREEN. Kandidat NUL-puti uzhe otklonyalsya Foundation v teste; dobavlennaya yavnaya proverka yavlyayetsya dopolniteljnoj zasjhitoj, a ne dokazannyim prezhnim obkhodom.
- №7–10: RED/GREEN khraneniya, 22 GREEN. Pervaya fikstura oshibochno sokhranyala alias kataloga posle Foundation-resolving i poluchala ENOTDIR; ispravlena na POSIX realpath, zatem vosproizvedyon predmetnyij RED. Pervaya popyitka realizacii ne skompilirovalasj iz-za dvukh otsutstvuyusjhikh `try`; otkaz sokhranyon.
- №11–14: CLI, restart, povrezhdeniye, fsync/short-write, konkuriruyusjhij pisatelj, read-only, zapret vyikhoda v Git, nevozmozhnyiye razryivyi proiskhozhdeniya i zamena imeni kornya; 31 GREEN. Ispravlenyi dve oshibki fikstur: putj k CLI byil vzyat iz xctest-runner, a porog korotkoj zapisi 7 lezhal vnutri uzhe susjhestvuyusjhej 8-bajtovoj signaturyi i ne sozdaval khvosta. Posle korrekcii vosproizvedyon predmetnyij RED.
- №15–16: profilj RED/GREEN, 32 GREEN. №17–23: inventarj imyon, 11 regressionnyikh testov kanonicheskogo preobrazovatelya, prochitannyij dry-plan, sobstvennyij RED na 34 nenuzhnyikh latinskikh obyyavleniya i GREEN posle tochnogo preobrazovaniya. Pervyij vyivod plana byil usechyon toljko interfejsom; polnyij plan prochitan povtornyim vyizovom. Swift: 32 GREEN.
- №27: predmetnyij RED `Int.min` v dekodirovannom sobyitii avarijno zavershil xctest signalom 5; preflight perenesyon do arifmetiki proiskhozhdeniya. №29: RED boljshoj stroki i zapisi profilya cherez simvolicheskuyu ssyilku. №30: 35 GREEN; profilj zaraneye proveryayet fizicheskij pustoj katalog, ogranichenno chitayet yego zapisi cherez readdir.
- №36 i №41: 35 GREEN posle osvobozhdeniya vremennyikh obyyektov i okonchateljnogo pereimenovaniya testovyikh fajlov. №42: konechnyij yazyikovoj perechenj pust; razreshenyi toljko tochnyiye vneshniye isklyucheniya. №43 obnaruzhil tri pustyiye stroki EOF v indekse; udalenyi, №45 uspeshen. Posle №41 ispolnyayemaya semantika ne menyalasj.
- Zaklyuchiteljnoye read-only-revjyu nashlo false-green v oracle zavershyonnoj sverkhlimitnoj stroki: probelyi + LF byili nevalidnyim JSON, a test prinimal lyubuyu oshibku. Fikstura zamenena validnyim JSON, oracle trebuyet imenno `.предел`. №46 — proverka chuvstviteljnosti testa pri vremenno snyatyikh dvukh zasjhitakh stroki: dva RED-utverzhdeniya (net oshibki / nevernyij `.формат`). Obe zasjhityi pobajtovo vosstanovlenyi; №47 — 35 GREEN, №48 — tochnyij indeks bez probeljnyikh oshibok. Eto ispravleniye testa, ne novyij defekt prinyatoj realizacii; okonchateljnaya ispolnyayemaya semantika sovpadayet s izmerennoj.
- Swift 6, Apple Swift 6.4, native SwiftPM; preduprezhdeniye ob ustarevanii native build-system sokhranyayetsya. Testyi ispoljzuyut publichnyiye fiksturyi, vklyuchaya sinteticheskuyu stroku >1 MiB i otkaz >4 MiB. API zhivyikh zadach i chuzhiye JSONL ne ispoljzovalisj.
- V prezhnej kontroljnoj tochke oformleniye otchyota odin raz useklo zakryivayusjhij marker: tochnaya stroka vosstanovlena do recency. Zatem svyaznostj nashla chetyire novyiye bityiye ssyilki iz-za sostavnogo Unicode-napisaniya imeni otchyota posle perenosa; dvukhshagovyim pereimenovaniyem vosstanovleno kanonicheskoye imya. Syiryiye zapisi zapuskov ne menyalisj. Istoricheskiye 282 oshibki schitayutsya otdeljno.

## Resheniya i ogranicheniya kontrakta

- Istochnik — toljko yavno zadannyij fajl i strogoye sovpadeniye lowercase UUID s pervoj zavershyonnoj `session_meta.payload.id`. Vyibirayutsya toljko chetyire call/output-tipa `response_item`. SHA prefiksa vklyuchayet vse zavershyonnyiye stroki; proiskhozhdeniye sobyitiya — nomer, diapazon [nachalo, konec), SHA iskhodnoj stroki s LF i versiya kontrakta.
- Polnyij povtornyij prokhod podtverzhdayet SHA i chislo strok na prezhnej dolgovechnoj granice do append. Odna zapisj kontejnera atomarno svyazyivayet novyiye normalizovannyiye sobyitiya i novuyu granicu; otdeljnogo cursor net. Posle append/fsync publikuyetsya novyij uchyot. Posle oshibki append ekzemplyar zakryit otkazom do pereotkryitiya; povtor neizmennogo prefiksa povtoryayet sinkhronizaciyu iskhodnogo poslednego paketa bez rosta.
- Identichnostj — UUID zadachi + call_id; napravleniye razlichayet vyizov i output. Novyij nastoyasjhij ID ne skhlopyivayetsya po imeni instrumenta. Tochnyij dublj ne uvelichivayet pryamoj schyotchik; izmenyonnyiye syiryiye bajtyi libo nesovmestimyiye normalizovannyiye polya togo zhe klyucha otklonyayutsya. Otsutstvuyusjhij/null ID rezuljtata ne sozdayot vyizov, nesovmestimoye semejstvo ne sopryagayetsya.
- Polnyiye arguments/output, sistemnyiye soobsjheniya i skryityiye rassuzhdeniya otsutstvuyut v normalizovannyikh sobyitiyakh i diagnostike. Dopustimyiye identifikatoryi ogranichenyi ASCII i 256 bajtami; khyesh ne yavlyayetsya anonimizaciyej. V doverennom iskhodnike sami imena/ID mogut soderzhatj chuvstviteljnyiye svedeniya, poetomu rezuljtat sokhranyayetsya vne Git.
- Byudzhetyi: blok 64 KiB, zavershyonnaya stroka/khvost 4 MiB, vkhod 256 MiB, 100000 strok, 8192 normalizovannyikh sobyitij za vsyu istoriyu vklyuchaya dubli, 256 paketov, 8 MiB na paket; glubina 16, 8192 klyucha v stroke, 200000 klyuchej v pakete. Prevyisheniye zakryito otklonyayetsya bez prodvizheniya granicyi. Eto ogranichennyij importyor, ne neogranichennoye khranilisjhe.
- Peredannyiye realjnyiye razmeryi pomesjhayutsya v fajlovyij/strochnyij byudzhet. Pozdnij srez kornya: 106007603 bajta, 1853 stroki call i 1918 strok output, vmeste 3771 potencialjnoye sobyitiye — menjshe 8192. Eto soobsjhyonnyiye kolichestva, a ne vyipolnennaya zdesj proverka soderzhimogo; profilj ne dokazyivayet, chto privatnyij vkhod budet prinyat po vsem ogranicheniyam ili chto vse stroki obrazuyut paryi.
- Chastichnyij khvost vozvrasjhayet upravleniye i prezhnyuyu granicu; sleduyusjhij yavnyij import smozhet prinyatj zavershyonnuyu stroku. Net sleep, raspisaniya ili fonovogo ozhidaniya. Kod CLI 0 oznachayet priyom zavershyonnogo prefiksa, ne EOF, konec zadachi ili uspekh instrumenta.
- Timestamp v1 — strogij UTC 1970–2100, drobj do 9 cifr; otsutstvuyusjheye/nevernoye vremya ne zamenyayetsya nulyom. Neotricateljnaya zaderzhka paryi — raznostj nablyudyonnyikh log-vremyon, ne dliteljnostj ispolneniya; output ne dokazyivayet uspekh. Universaljnyikh porogov avtomatizacii net.
- Predpolagayutsya doverennyiye roditeljskiye katalogi i neizmennyij istochnik vo vremya prokhoda. Nablyudyonnyiye inode/size/mtime/ctime i zamena puti otklonyayutsya, no zasjhita ot vrazhdebnoj soglasovannoj gonki prostranstva imyon ili in-place-izmeneniya ne zayavlena. Avtomaticheskogo remonta/usecheniya povrezhdyonnogo kontejnera net.
- Prinyatyiye `Packages/КонтейнерНаблюдений` i `Packages/СнимокАгентскойЗадачи` ne imeyut diff otnositeljno `dd172958b0128cba73361eeac136e8bc66190230`. Budusjhij otdeljnyij adapter snimka smozhet povtorno ispoljzovatj granicu/proiskhozhdeniye; EOF/final/HookPrompt ne dokazyivayut zaversheniye zadachi.
- Primenyayetsya kontroljnaya tochka otkryitogo terminaljnogo zhurnala, ne polnaya priyomka FUM. Izvestnyiye 282 ssyilki na otsutstvuyusjhij ignoriruyemyij `.obsidian/graph.json` ne ispravlyayutsya sozdaniyem poljzovateljskogo sostoyaniya. Proyekciya neizmenna: pokoleniye `ba6f1c7907478a638c9f0fda6d93f6da37a7fcf5`, obyyavlennyij plan `sha256:448211f8b8fccef2c8c4f471cb0c9b62bcd9dcc431352f5a8de33b03803d912f`; novyiye kanonicheskiye fajlyi yesjhyo ne pokryityi.

## Otvetyi, proiskhozhdeniye i peredacha

- Iskhodnoye delegirovaniye vyipolneno v ogranichennom pakete, bez rasshireniya na v4/runtime item_completed, zhivyiye API i vyivod parent po vremeni. Trebovaniya, kartochka i obsjhaya integraciya ne izmenenyi.
- Peredannaya transliteraciya sokhranena doslovno v [zaprose](zapros.md), proiskhozhdeniye — soobsjhyonnaya kornem zavershyonnaya stroka 15699. Kornevoj istochnik poluchen v commit `670a1fda352b34668d87000602e76e246aefa22f`, susjhestvovaniye commit provereno lokaljno: [tochnyij zapros kornya](https://github.com/fum-lab/fum/blob/670a1fda352b34668d87000602e76e246aefa22f/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_14-35-59_MSK_%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%B8%D1%82%D1%8C-%D0%BD%D0%B0%D1%82%D0%B8%D0%B2%D0%BD%D0%BE%D0%B5-%D0%BF%D1%80%D0%BE%D0%B4%D0%BE%D0%BB%D0%B6%D0%B5%D0%BD%D0%B8%D0%B5-%D0%B7%D0%B0%D0%B4%D0%B0%D1%87%D0%B8/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md). Svyazannyiye FUM-REQ-0045 i FUM-STEP-0160 prinadlezhat kornyu i zdesj ne redaktirovalisj.
- Ukazaniye izolyacii vyipolneno: FUM ref `refs/heads/codex/статистика-вызовов-01a07d3d` ot `583704422445f32cf732f2625e6b5818880fd274`, Swift ref `refs/heads/codex/call-statistics-01a07d3d` ot `dd172958b0128cba73361eeac136e8bc66190230`. [Perenos](materialyi/perenos-napravleniya.md) sveril SHA i rezhimyi 8+8 fajlov; staryiye derevjya chistyi, rezerv sobstvennoj deljtyi sokhranyon vne checkout. Pervaya tochka: FUM `9ea6d959e06e486c02057607da352371ec6b3535`, Swift `fe068f68483ce79647dcca9f8303f569b9870063`; FUM push proveren tochnyim ls-remote.
- Utochneniye o razmere realizovano bez chteniya chastnogo soderzhimogo: limityi uvelichenyi do 4/256 MiB, dobavlenyi boljshaya stroka, prevyisheniye byudzheta i rabochij publichnyij profilj. Chislo sobyitij ostayotsya otdeljnoj granicej budusjhego realjnogo importa.
- Read-only-ispolnitelj zavershil prosmotr staged diff: krome ispravlennogo oracle susjhestvennyikh defektov ne nashyol; on ne pisal i ne zapuskal proverki. Vse ispravlennyiye podtverzhdyonnyiye defektyi svyazanyi vyishe s RED/GREEN. Posledneye usileniye oracle svereno kornem i provereno №46–48.
- Lokaljnyij navyik perevoda obyyavlenij opredelil proveryayemuyu kartu, dry-plan i leksicheskiye zamenyi sobstvennyikh imyon, a ne svobodnoye pereimenovaniye. [Karta](materialyi/karta-russkikh-imyon.json), [konechnyiye isklyucheniya](materialyi/isklyucheniya-imyon.json), [obrasjheniya](materialyi/pereimenovaniya-obrasjhenij.json) sokhranyayut proiskhozhdeniye. `Package.swift/package`, `@main/main`, pole `sha256` v1 i obyazateljnyij testovyij prefiks sokhranenyi po tochnomu vneshnemu kontraktu.
- Po utochneniyu dlya arkhivnogo snimka: publichnyij read-only API `прочитатьПрефикс(_:задача:после:) throws -> ПрочитанныйПрефикс` nakhoditsya vo vneshnem pakete `Packages/СтатистикаВызовов/Sources/СтатистикаВызовов/Чтение.swift`, tipyi granicyi/proiskhozhdeniya — sosednij `Контракт.swift`. On ne pishet kontejner, no svyazan so statistikoj: vozvrasjhayet toljko call/output-sobyitiya i itogovuyu granicu/razmer khvosta, ne obsjhij potok strok ili arkhivnyiye soobsjheniya. Universaljnogo chistogo reader API dlya snimka sejchas net; nepodgotovlennyij refaktoring ne vyipolnyalsya. Propusk prezhde prinyatogo prefiksa predpolagayet doverennuyu raneye proverennuyu granicu, kotoruyu etot API sam po sebe dolgovechno ne ustanavlivayet.
- Swift OID/tree, 35 GREEN, profili i tochnyij publichnyij API/yego ogranicheniye peredanyi roditeljskoj zadache. Proverka prodolzheniya posle Swift commit vernula kod 3 / «peredacha»; rabota fakticheski prodolzhena obnovleniyem manifesta i oformleniyem FUM checkpoint. Svyaznostj pered Swift commit vernula toljko prezhniye 282 ssyilki graph.json, novyikh oshibok net; eto ogranichennyij dopusk, ne uspeshnaya polnaya priyomka.
- [Plan](materialyi/planyi/plan.md) i [mashinnoye prodolzheniye](materialyi/planyi/prodolzheniye.json) fiksiruyut vyipolnennyij dochernij obyyom. Posle FUM commit vyipolnyayutsya read-only-proverka, razreshyonnyij push tochnoj vetki i peredacha yego OID; obsjhaya priyomka/realjnyij import ne obyyavlyayutsya zavershyonnyimi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 16:26:03 MSK -->
<!-- content-sha256: sha256:e77309f4c4c3f24260e69165a33efd70ecf91423be5fbdc2f1dddf740b873d50 -->
<!-- FUM-MD-RECENCY:END -->
