# Otchyot 2026-09-11 12:00:09 MSK - Sravnitj dekodirovaniye UTF 8

Vosproizvodimoye sravneniye zaversheno na Apple M1 Max, Swift 6.4 Release. Pri odinakovyikh skalyarakh i UTF-32LE polnyij API interpretatora na vkhodakh okolo 256 KiB zanyal 29,77–64,11 ms, standartnyij strogij Swift — 1,17–1,95 ms. Raznica 21,10–33,38 raza otnositsya k dostupnyim API: interpretator dopolniteljno proveryayet opredeleniye, schitayet operacii, stroit trassu i khyeshi. Yego iskhodniki iz `f49eeee3fd80a87cd63391d6606dafa19cd6d2b8` ne izmenenyi.

Eta zapisj sokhranyayetsya kontroljnyim kommitom po yavnomu porucheniyu koordinatora. Finaljnaya priyomka yesjhyo ne vyipolnena: tyazhyoloye okno zanyato integratorom. Otkryityij predprosmotr soderzhit terminaljnyiye adresnyiye zapisi; `снимок.json` namerenno otsutstvuyet soglasno dopusku kontroljnoj tochki. Sleduyusjhij etap etoj zhe zadachi poluchit otdeljnuyu papku Zhurnala dlya polnogo dopuska.

## Poluchennyij rezuljtat

- [Rukovodstvo](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/sravneniye-dekodirovaniya.md) soderzhit komandyi chistogo vosproizvedeniya, korpus, 24 sravniteljnyikh itoga, propusknuyu sposobnostj, diagnosticheskiye medianyi i ogranicheniya.
- [Syiryiye nablyudeniya](materialyi/sravneniye-Release.json): 432 paketa v 48 ryadakh po devyatj srednikh, 48 kalibrovok, 72 otdeljnyikh diagnosticheskikh vyizova. Sborka i podgotovka JSON isklyuchenyi iz osnovnyikh ryadov; kontroljnaya summa obkhoditsya posle tajmera kazhdogo vyizova.
- [Korrektnostj Release](materialyi/korrektnostj-Release.json): 46 polozhiteljnyikh sochetanij i 14 strogikh otkazov. Ozhidayemyiye skalyaryi zadanyi literalami nezavisimo ot oboikh dekoderov. Nevernyij prefiks Swift otbrasyivayetsya, pozicii oshibok interpretatora zapisanyi otdeljno; skorostj oshibok i UTF-32BE ne izmeryalisj.
- [Standartnyij API](materialyi/standartnyij-dekoder.json) proveren v ustanovlennom interfejse i [arkhive pervichnogo Swift](../../Istochniki/URL/https/github.com/swiftlang/swift/blob/main/stdlib/public/core/Unicode.swift/source-index.md). `transcode` rabotayet s `stoppingOnError: true`; ispravlyayusjhij `String(decoding:as:)` ne ispoljzuyetsya.

## Otvetyi na komandyi i koordinaciya

Iskhodnoye nativnoye porucheniye prinyato kak otdeljnyij etap toj zhe vidimoj zadachi. Staryij zakryityij otchyot sokhranyon; novaya postavka ne zamenyayet sedjmoj vkhod prezhnej integracii avtomaticheski. Sokhranenyi [upravlyayusjhiye soobsjheniya](zapros.md) i [vidimyiye soderzhateljnyiye otvetyi](materialyi/dialog-etapa.md).

Oba utochneniya metodiki realizovanyi: dve materializovannyiye granicyi, chetyire korpusa, tri razmera, progrev, kalibrovka i devyatj chereduyusjhikhsya par. Koordinator predostavil okno bez nashikh sborok, proyekcii i smoke. Pervyij srez pokazal zametnuyu sistemnuyu nagruzku; posle povtornoj sverki polucheno utochneniye o dopustimosti obyichnoj poljzovateljskoj sessii. Sistemnyiye processyi ne izmenyalisj. [Oba sreza](materialyi/nagruzka.json) sokhranenyi; polnoye otsutstviye fonovoj rabotyi ne zayavlyayetsya. Okno osvobozhdeno srazu posle nablyudayemogo zaversheniya processa.

Staticheskoye RO-revjyu dochernego `engine_review` proverilo API i novyiye iskhodniki bez zapisi i zapuska proverok. Otdeljnyij recenzent koordinatora proveril metodiku pyati fajlov, takzhe bez zapuskov. Koordinator proveril strukturu vsekh 432 paketov i chislenno pereschital vosemj krupnyikh ryadov. Polnyij nezavisimyij chislovoj pereschyot vsekh 48 ryadov vyipolnen imenno kornem etoj zadachi: pervonachaljnyij zapusk № 10 «Sveritj vse syiryiye ryadyi i izmeritj proveryayusjhij», zatem okonchateljnyij zapusk № 18 «Sveritj okonchateljnyiye ryadyi i profilj ispravlennogo proveryayusjhego», oba s kodom 0; [okonchateljnyij profilj i khyesh vkhoda](materialyi/profilj-proveryayusjhego-okonchateljnyij.json). Eti raznyiye svideteljstva ne podmenyayut drug druga.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj | Granicyi i sposob izmereniya                                               |
| ------------------------------ | ------------ | ------------------------------------------------------------------------ |
| Podgotovka koda i dokumentacii | ne izmereno  | Ot nachala etapa; nezavisimoye vremya bez perekryitij ne vosstanavlivalosj   |
| Sborka Release                 | 20.177 s     | Polnaya vneshnyaya obyortka zapuska № 4, vklyuchaya zapisj proiskhozhdeniya         |
| Proverka gotovogo Release      | 1.637 s      | Vneshnyaya obyortka zapuska № 5                                              |
| Process sravneniya              | 16,504 s     | Monotonnyij interval Python vokrug odnogo zapuska ispolnyayemogo fajla      |
| Serii i diagnostika            | 16,095 s     | Vlozhennyij interval Swift posle korrektnosti; ne skladyivayetsya s processom |
| Standartnyij smoke-check        | ne izmereno  | Predfinaljnaya dokumentacionnaya priyomka yesjhyo ne zapuskalasj                |

Granica profilya: nachalo etapa 2026-09-11 12:00:09 MSK; pryamyiye adresnyiye zapuski do aktualjnogo predprosmotra kontroljnoj tochki. Vremya ozhidaniya okna otdeljno ne izmeryalosj. Zaklyuchiteljnaya read-only-proverka kontroljnoj tochki, kommit i otpravka nakhodyatsya vne etoj granicyi; finaljnyij smoke i proyekciya budut v sleduyusjhem etape. Vlozhennyiye vremena ne pribavlyayutsya k vneshnemu processu.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                         | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj] RED strogogo standartnogo dekodirovaniya i upakovki LE                                | 16,156 s     | neuspeshno |
| [Korenj] RED korpusa i dvukh granic rezuljtata stenda                                          | 2,21 s       | neuspeshno |
| [Korenj] GREEN strogogo dekodera i korpusa sravneniya                                          | 9,022 s      | uspeshno   |
| [Korenj] Sobratj Release stenda sravneniya s proiskhozhdeniyem                                    | 20,177 s     | uspeshno   |
| [Korenj] Proveritj korpus i strogiye otkazyi gotovogo Release                                   | 1,637 s      | uspeshno   |
| [Korenj] Izmeritj parnoye strogoye dekodirovaniye UTF-8 v Release                                | 17,313 s     | uspeshno   |
| [Korenj] RED nezavisimoj proverki statistiki i proiskhozhdeniya                                  | 0,079 s      | neuspeshno |
| [Korenj] GREEN nezavisimoj proverki statistiki i proiskhozhdeniya                                | 0,084 s      | uspeshno   |
| [Korenj] Proveritj russkiye imena testov svideteljstva                                         | 0,087 s      | uspeshno   |
| [Korenj] Sveritj vse syiryiye ryadyi i izmeritj proveryayusjhij                                        | 0,092 s      | uspeshno   |
| [Korenj] Adresno inventarizirovatj obyyavleniya novyikh fajlov                                    | 0,239 s      | uspeshno   |
| [Korenj] Proveritj publikacionnuyu chistotu mashinnyikh putej pered proyekciyej                      | 22,679 s     | neuspeshno |
| [Korenj] Lokalizovatj otkaz mashinnyikh putej s sokhraneniyem polnogo vyivoda                       | 22,36 s      | neuspeshno |
| [Korenj] GREEN mashinnyikh putej posle perenosimyikh primerov TMPDIR                               | 22,442 s     | uspeshno   |
| [Korenj] Proveritj svyaznostj zapolnennogo etapa pered finaljnoj priyomkoj                      | 40,552 s     | uspeshno   |
| [Korenj] RED obyazateljnogo sostava iskhodnikov i unikaljnogo pokryitiya itogov                   | 0,13 s       | neuspeshno |
| [Korenj] GREEN obyazateljnogo sostava iskhodnikov i unikaljnogo pokryitiya itogov                 | 0,131 s      | uspeshno   |
| [Korenj] Sveritj okonchateljnyiye ryadyi i profilj ispravlennogo proveryayusjhego                      | 0,131 s      | uspeshno   |
| [Korenj] Povtoritj adresnyij inventarj po tochnyim NUL-razdelyonnyim putyam Git                     | 0,244 s      | uspeshno   |
| [Korenj] Proveritj obnaruzheniye pereimenovannogo Swift-testa bez izmeneniya dekodera            | 8,724 s      | uspeshno   |
| [Korenj] Podtverditj otkaz prezhnego raw pri izmenyonnom imeni testa                            | 0,078 s      | neuspeshno |
| [Korenj] Proveritj otricateljnyiye sluchai na tochnom snimke izmerennyikh iskhodnikov                | 0,133 s      | uspeshno   |
| [Korenj] Pereschitatj raw na vosstanovlennyikh 21 iskhodnike i izmeritj okonchateljnyij proveryayusjhij | 0,078 s      | uspeshno   |
| [Korenj] Podtverditj okonchateljnyiye obyyavleniya vosjmi fajlov po NUL-putyam Git                  | 0,233 s      | uspeshno   |
| [Korenj] Sobratj planovyij reyestr s dvumya zakryityimi ogranichennyimi sboyami                       | 0,498 s      | uspeshno   |
| [Korenj] Proveritj okonchateljnuyu svyaznostj i indeks podgotovlennoj postavki                   | 40,207 s     | uspeshno   |
| [Korenj] Proveritj exact diff i neizmennostj izmerennogo dekodera i raw                       | 0,132 s      | uspeshno   |
| [Korenj] Vosproizvesti dokumentirovannoye vosstanovleniye snimka i pobajtovuyu tablicu           | 0,134 s      | uspeshno   |
| [Korenj] Otkaz pri odnovremennoj potere iskhodnika i zapisi — RED                              | 0,133 s      | neuspeshno |
| [Korenj] Nezavisimyij perechenj iskhodnikov i semj regressij — GREEN                             | 0,132 s      | uspeshno   |
| [Korenj] Profilj nezavisimogo sostava iskhodnikov i pereschyot iskhodnogo zamera                  | 0,125 s      | uspeshno   |
| [Korenj] Inventarj obyyavlenij posle nezavisimogo perechnya iskhodnikov                           | 0,252 s      | uspeshno   |
| [Korenj] Obnovitj planovyij reyestr posle okonchateljnogo podtverzhdeniya polnotyi                  | 0,458 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 227,082 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Dva celevyikh RED-progona fiksiruyut otsutstvovavshiye kontraktyi strogogo standartnogo puti i korpusa. Posle realizacii vse tri adresnyikh Swift-testa proshli; zatem otdeljno podtverzhdyon sobrannyij Release. Prinimayemyiye 42 testa prezhnego interpretatora ne povtoryalisj, yego kod ne menyalsya.

Nezavisimyij proveryayusjhij proshyol sobstvennyij RED/GREEN: chetyire testa zakrepili prinyatiye nastoyasjhego profilya i otkaz pri podmene medianyi, potere paryi ili podmene khyesha iskhodnika. Posle perevoda sobstvennogo Python-parametra cherez lokaljnuyu avtomatizaciyu chetyire testa povtorno proshli. Pervonachaljnyij profilj pyati vyizovov proveryayusjhego: mediana 2,323 ms; opravdannoj optimizacii takogo korotkogo proveryayusjhego ne vyiyavleno. Iskhodnyij interpretator po pryamomu ogranicheniyu zadachi ne optimizirovalsya, stend sokhranil izmerennuyu realizaciyu.

Pervonachaljnaya adresnaya inventarizaciya № 11 imela nulevoj okhvat iz-za ekranirovannyikh kirillicheskikh putej Git; yeyo kod 0 ne yavlyayetsya uspeshnyim yazyikovyim dopuskom. Posle chteniya tochnyikh NUL-razdelyonnyikh putej № 19 proveril vosemj fakticheskikh fajlov. Najdenyi nasledovannyij `package`, vneshnij metod `setUpClass` i sobstvennoye imya Swift-testa s latinskim suffiksom. Imya perevedeno lokaljnoj avtomatizaciyej; tri tekusjhikh Swift-testa zatem proshli v № 20. [Itogovyij adresnyij inventarj](materialyi/obyyavleniya.json) razlichayet eti sluchai. Istoricheskij obsjhij ostatok ne pereopredelyalsya; obsjhij shirokij yazyikovoj kontur ne obyyavlyayetsya projdennyim.

Recenzent koordinatora obnaruzhil dva obkhoda pervonachaljnogo proveryayusjhego: pustoye/nepolnoye proiskhozhdeniye i povtor odnogo itoga vmesto polnogo pokryitiya. Dopolniteljnyij RED vosproizvyol oba sluchaya; posle proverki tochnogo inventarya istochnikov i unikaljnogo pokryitiya itogov GREEN vyipolnil shestj testov. Ispravlennyij proveryayusjhij povtorno pereschital neizmenyonnyij raw; itogovaya tablica pobajtovo sovpala. Novyij profilj pyati vyizovov dal medianu 3,175 ms. Neboljshaya stoimostj boleye strogoj proverki ne opravdyivayet dopolniteljnoj optimizacii. Dlya 72 diagnosticheskikh vyizovov proveryayetsya toljko kolichestvo, ikh vnutrenniye metki ne obyyavlyayutsya polnostjyu validirovannyimi. [Predyidusjhij iskhodnik](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Proverki/etalonyi-profilya/proveryayusjhij-do-usileniya.py) sokhranyon s tochnyim iskhodnyim khyeshem, chtobyi vosproizvodilosj proiskhozhdeniye pervonachaljnogo profilya; dlya aktualjnoj proverki ispoljzuyetsya usilennyij fajl.

Deshyovyij skaner do proyekcii otklonil pyatj strok komand rukovodstva s absolyutnyim primerom vremennogo kataloga. Adresnaya lokalizaciya sokhranila polnyij vyivod vne Git. Perenosimyiye primeryi ispoljzuyut sistemnyij TMPDIR; neizmenyonnyij skaner zatem proshyol s kodom 0. Pravila isklyuchenij ne rasshiryalisj. Iz arkhiva Swift pered publikaciyej udalenyi identifikatoryi zaprosa i posetitelya, region i cookie; soderzhateljnyij iskhodnik sokhranyon.

Predfinaljnyij standartnyij smoke-check i proverki zamyikaniya yesjhyo predstoyat. Iskhodnyiye nablyudeniya i kod gotovyi; finaljnaya priyomka ne podmenyayetsya gotovnostjyu stenda.

Pozdneye RO-revjyu `engine_review` obnaruzhilo dopolniteljnyij probel toj zhe granicyi polnotyi: sovmestnaya poterya fajla i yego zapisi umenjshala inventarj proveryayemogo kataloga. № 29 vosproizvyol otkaz ozhidaniya testa; posle nezavisimogo perechnya 21 puti i nezavisimogo postroyeniya testovoj kopii № 30 vyipolnil semj testov. № 31 pereschital prezhnij raw, [pyatj vyizovov](materialyi/profilj-nezavisimogo-inventarya.json) dali medianu 2,326 ms. Sostav kvitancii, katalog i bajtyi teperj proveryayutsya otdeljno; profilj ne obosnovyivayet dopolniteljnuyu optimizaciyu. Izmerennyij stend ne menyalsya i povtorno ne zapuskalsya. Finaljnoye staticheskoye revjyu `engine_review` podtverdilo zakryitiye etogo obkhoda i sootvetstviye rukovodstva; recenzent ne zapuskal proverki. № 32 podtverdil vosemj iskhodnikov bez novyikh sobstvennyikh latinskikh obyyavlenij, № 33 peresobral planovyij reyestr.

## Resheniya i ogranicheniya

MAD — mediannoye absolyutnoye otkloneniye devyati srednikh paketov, a koefficiyent — otnosheniye median; doveriteljnyij interval ne vyichislyalsya. Dlya 48 ryadov MAD sostavlyayet 0,091–2,507% medianyi. Vnutrenniye metki — otdeljnaya diagnostika, ne chistoye dekodirovaniye. Na krupnom ASCII + LE mediana polnogo diagnosticheskogo vyizova 63,865 ms, trassyi i khyeshej 49,514 ms, ispolneniya 14,056 ms i proverki 0,306 ms. Eto osnovaniye daljnejshego issledovaniya posle otdeljnogo naznacheniya, bez novogo obyazateljstva optimizacii v dannom etape.

Posle pereimenovaniya testa № 21 podtverdil otkaz prezhnego raw na otlichayusjhemsya tekusjhem iskhodnike. Tochnyij prezhnij test sokhranyon, vosstanovleniye 21 iskhodnika vyipolneno vne checkout; № 22 vyipolnil shestj testov proveryayusjhego na etom snimke, № 23 pereschital raw i sokhranil [okonchateljnyij profilj](materialyi/profilj-proveryayusjhego-snimok.json). Izmerennyij snimok, tekusjhiye imena testov i ikh proverki yavno razlichayutsya; raw i yego Tests-khyeshi ne perepisyivalisj.

[Kartochka vremennyikh putej](../../Sboi/FUM-SBOJ-0073-perenosimyiye-primeryi-vremennyikh-putej.md) i [kartochka polnotyi dokazateljstv](../../Sboi/FUM-SBOJ-0074-polnota-inventarya-dokazateljstv-sravneniya.md) fiksiruyut ogranichennoye vosstanovleniye. Novyiye nomera vyidelenyi koordinatorom; nezaproshennyij planovyij shag ne sozdavalsya.

Rabota provedena v sobstvennoj vetke ot `f49eeee3fd80a87cd63391d6606dafa19cd6d2b8`. Publikaciya novogo kommita i yego integraciya razlichayutsya; izmeneniye `master` v etom obyyome ne naznacheno. [Ogranichennyij plan](materialyi/plan-prodolzheniya.json) sokhranyayet sostoyaniye etapa. Dlya vosproizvedeniya sokhranyayutsya iskhodniki, otkryityiye literalyi, tochnyiye khyeshi, parametryi i syiryiye nablyudeniya; vremennaya sborka ostayotsya vne Git.

## Ostatok posle kontroljnoj tochki

Po osvobozhdenii soglasovannogo okna nuzhnyi novyij zhurnaljnyij etap, standartnyij dokumentacionnyij smoke kak poslednyaya okhvachennaya proverka, proverka plana i zakryitiye novogo otchyota, finaljnaya generaciya i nezavisimaya proverka proyekcii, itogovyij kommit i podtverzhdyonnaya otpravka. Staryiye adresnyiye zapisi etoj kontroljnoj tochki sokhranyayutsya neizmennyimi i ne zamenyayut novyij finaljnyij dopusk.

Kontroljnaya tochka sokhranyayet prezhnyuyu proyekciyu prinyatogo `f49eeee3fd80a87cd63391d6606dafa19cd6d2b8`: SHA-256 manifesta `7962b6658ceb8986f3bf55dea149329a12bddaa6d98a60fb215f9b1f1a1ac5b9`, khyesh plana `f260cbf5da33bc32397229e80664a6492afac4886024450fac398e7158bc51dd`. Novyiye kanonicheskiye fajlyi sravneniya v eto pokoleniye yesjhyo ne vkhodyat; aktualjnostj proyekcii ne zayavlyayetsya. Tochnyij proverennyij vkhod pokoleniya khranitsya v pole `исходный_снимок` manifesta.

## Istochniki

- [Zapros i utochneniya](zapros.md).
- [Predyidusjhij prinyatyij etap](../2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 13:02:34 MSK -->
<!-- content-sha256: sha256:17aa3754fd5a97f3868ed445f7281f2c27ed28217b55903cfddd730b8a383dc0 -->
<!-- FUM-MD-RECENCY:END -->
