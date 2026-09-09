# Otchyot 2026-09-08 22:21:18 MSK - Obnovitj LinguisticKit dlya Swift Concurrency

V otdeljnoj vetke forka podgotovlena podderzhka Swift 6: obsjhiye tablicyi stanovyatsya neizmenyayemyimi i bezopasno peredayutsya mezhdu zadachami. Ustranyon takzhe testovyij import, blokirovavshij Release-ekstraktor. Izmeneniya opublikovanyi v forke i dostavlenyi v [upstream PR №14](https://github.com/Roman-Kerimov/LinguisticKit/pull/14).

## Otvetyi na upravlyayusjhiye komandyi

- Paralleljnaya rabota: prinyata rolj FUM Razrabotchik; u dochernej rabotyi sobstvennyiye FUM worktree i vetka, a biblioteka razrabatyivayetsya v otdeljnom polnocennom klone. Chuzhiye rabochiye derevjya ne izmenyayutsya. Kornevoj identifikator proiskhozhdeniya sokhranyon.
- Publikaciya vetok: posle soderzhateljnyikh proverennyikh kommitov b868465 i dd583a4 vyipolnenyi obyichnyiye push toljko svoyej codex-vetki forka. Ni master, ni upstream napryamuyu ne izmenyalisj.
- Obnovleniye LinguisticKit i PR: vyibranyi tools 6.3 i yavnyij Swift 6 language mode. Istochniki vyibora — oficialjnyij vyipusk Swift 6.3 i rukovodstvo migracii Concurrency. Lokaljnyij Swift 6.4 otlichayetsya ot minimaljnoj versii paketa; otdeljnyij uspeshnyij CI podtverdil Swift 6.3.3 na Ubuntu 24.04 i macOS 15.

## Izmeneniye i sovmestimostj

ScriptTable teperj final i checked Sendable. Yego indeksyi, naboryi bukv i maksimaljnyiye dlinyi formiruyutsya v init i posle publikacii ne izmenyayutsya. Publichnyiye Script i MathAlphanumericType, a takzhe vnutrennij reyestr tozhe Sendable. Klass prezhde ne byil open i ne imel publichnogo konstruktora, poetomu vneshneye nasledovaniye ne byilo dostupno. Ravenstvo po identichnosti i publichnyiye signaturyi preobrazovanij sokhranenyi.

Preobrazovaniye ostayotsya sinkhronnoj rabotoj CPU na ispolnitele vyizyivayusjhego koda. Ne dobavlenyi iskusstvennyiye async-obyortki, obsjhij actor, unchecked Sendable ili otklyucheniye strogikh proverok. README biblioteki obyyasnyayet ispoljzovaniye iz zadach, poryadok rezuljtatov, nagruzku i granicu otmenyi.

BuildTool ispoljzuyet obyichnyij import i uzkij package-dostup k nuzhnyim opisatelyam. Vse Release-produktyi sobirayutsya bez enable-testing. JSON Extracted ostayotsya pobajtno prezhnim.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj         | Granicyi i sposob izmereniya                                                                 |
| ------------------------------ | -------------------- | ------------------------------------------------------------------------------------------ |
| Profilj iskhodnoj biblioteki    | 4,217 s              | Pryamoj process 7; semj svezhikh zapuskov, monotonnoye vremya                                   |
| Profilj obnovlyonnoj biblioteki | 4,679 s              | Pryamoj process 12; tot zhe korpus i chislo povtorov                                          |
| Soderzhateljnaya rabota          | ne izmereno          | Analiz, kod, dokumentaciya, revjyu i publikaciya ne izmeryalisj otdeljnyim nepreryivnyim tajmerom |
| Adresnyiye proverki              | sm. tablicu zapuskov | Kazhdyij vyizov uchtyon obyortkoj; nekotoryiye sborki perekryivalisj                                |
| Polnaya priyomka FUM             | ne vyipolnyalasj       | Otlozhena do integracii kornem; tekusjhij otchyot otkryit                                        |

Granica profilya: ot pervogo adresnogo zapuska etoj rabotyi do poslednej uchtyonnoj kontroljnoj proverki. Ozhidaniye CI i finaljnaya peredacha ne vklyuchenyi; summa processov ne ravna kalendarnoj dliteljnosti i ne pribavlyayetsya k stadiyam.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                         | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------- | ------------ | --------- |
| [LinguisticKit] Iskhodnaya sborka LinguisticKit v rezhime Swift 6                                | 11,852 s     | neuspeshno |
| [LinguisticKit] Iskhodnaya biblioteka dlya profilya v sovmestimom rezhime Swift 5                  | 14,974 s     | uspeshno   |
| [LinguisticKit] RED konkurentnogo ispoljzovaniya LinguisticKit                                 | 4,482 s      | neuspeshno |
| [LinguisticKit] GREEN strogoj Concurrency i kholodnyikh paralleljnyikh preobrazovanij              | 15,343 s     | neuspeshno |
| [LinguisticKit] Sborka odinakovogo izmeritelya dlya iskhodnoj biblioteki                         | 3,376 s      | uspeshno   |
| [LinguisticKit] Proveritj konkurentnyiye scenarii posle ispravleniya testovoj makrokomandyi       | 5,095 s      | uspeshno   |
| [LinguisticKit] Profilj iskhodnoj biblioteki na neizmennom korpuse FUM                         | 4,217 s      | uspeshno   |
| [LinguisticKit] Regressiya vsekh preobrazovanij v rezhime Swift 6                                | 2,105 s      | uspeshno   |
| [LinguisticKit] Proveritj vse produktyi paketa v optimizirovannoj sborke                       | 15,311 s     | neuspeshno |
| [LinguisticKit] GREEN optimizirovannoj sborki s paketom vmesto testovogo importa              | 14,048 s     | uspeshno   |
| [LinguisticKit] Sborka odinakovogo izmeritelya dlya obnovlyonnoj biblioteki                      | 2,644 s      | uspeshno   |
| [LinguisticKit] Profilj obnovlyonnoj biblioteki na tom zhe korpuse FUM                          | 4,679 s      | uspeshno   |
| [LinguisticKit] Proveritj konkurentnyiye obrasjheniya pod Thread Sanitizer                         | 27,974 s     | uspeshno   |
| [LinguisticKit] Proveritj izvlecheniye tablic Release i neizmennostj ikh bajtov                  | 0,502 s      | uspeshno   |
| [LinguisticKit] Proveritj dokumentirovannyiye komandyi Swift Build i vse testyi                   | 9,008 s      | uspeshno   |
| [LinguisticKit] Proveritj tochnyij diff LinguisticKit pered kontroljnyim kommitom                | 0,018 s      | uspeshno   |
| [LinguisticKit] Proveritj ispravleniye ustanovsjhika Swift v CI                                  | 0,016 s      | uspeshno   |
| [LinguisticKit] Iskhodnyij Release-ekstraktor dlya sravneniya s yavno vklyuchyonnyim testovyim importom | 13,957 s     | uspeshno   |
| [LinguisticKit] Profilj iskhodnogo i novogo Release-ekstraktora s tochnoj sverkoj JSON          | 1,121 s      | uspeshno   |
| [LinguisticKit] Proveritj strukturu Zhurnala dochernej rabotyi                                   | 12,645 s     | uspeshno   |
| [LinguisticKit] Proveritj publikacionnuyu chistotu novyikh materialov FUM                         | 17,827 s     | uspeshno   |
| [LinguisticKit] Proveritj tochnyij indeks zhurnaljnoj kontroljnoj tochki                          | 0,021 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 181,215 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:3e5bad71bf11fc5bbf9d7d20453eb7b267aa788eb6dd17def5fbc90ae28f3129.
Kontekst soderzhimogo: sha256:d532d1d99f2c0e7efa416c7d3a89c56cd9e29d58b9393bd95d20039fefdcd4ed.
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

## Proverki

- RED 1 i 3: shtatnyij iskhodnik ne prokhodit Swift 6 iz-za obsjhikh non-Sendable znachenij; budusjhiye konkurentnyiye scenarii takzhe ne sobirayutsya.
- Pervaya popyitka GREEN 4 obnaruzhila oshibku raspolozheniya try vnutri novoj testovoj makrokomandyi. Ispravlenyi toljko testovyiye vyirazheniya; uspeshnyij zapusk 6 podtverdil tri konkurentnyikh scenariya.
- Zapuski 8 i 15: 32 prezhnikh XCTest i 3 novyikh testa prokhodyat v Swift 6 s preduprezhdeniyami kak oshibkami, vklyuchaya standartnyij Swift Build.
- Zapusk 13: tri novyikh scenariya proshli Thread Sanitizer.
- RED 9 / GREEN 10: polnyij Release raneye padal na @testable import; posle package-dostupa vse produktyi sobirayutsya.
- Profili 7 i 12 sokhranyayut tochnyiye bajtyi korpusa i rezuljtatov; ekstraktor otdeljno sveryayet vse Extracted JSON.
- Pervyij GitHub CI ne doshyol do kompilyacii: ustanovsjhik setup-swift v2 ne raspoznal 6.3.3. V dd583a4 on zamenyon na zakreplyonnyij commit v3/Swiftly s sokhraneniyem proverki podpisi. Etot otkaz ne vyidan za defekt biblioteki.

## Resheniye ob optimizacii

Semj zapuskov iskhodnogo i novogo variantov ispoljzuyut odin Swift 6.4 i Release -O, korpus 53 713 bajt iz tochnoj revizii FUM. Iskhodniku prishlosj yavno vyibratj Swift 5, poskoljku Swift 6 ne sobirayetsya; eto ogranicheniye otrazheno v [profile](materialyi/profili/sravneniye.json).

Mediana podgotovki russkoj tablicyi vyirosla s 1,091 do 1,851 ms, pervogo preobrazovaniya izmenilasj so 137,256 do 134,722 ms, tryokh povtorov — s 402,874 do 399,847 ms. Podgotovka ostaljnyikh tablic vyirosla s 0,856 do 2,887 ms; obsjhij pik rezidentnoj pamyati — s 13 959 168 do 14 286 848 bajt. Raznica pamyati otnositsya ko vsemu processu. Vse vyikhodyi sovpali pobajtno. Neboljshaya stoimostj podgotovki prinyata radi neizmenyayemogo sostoyaniya; uskoreniye tyoplogo puti ne dokazano, dopolniteljnyiye keshi i blokirovki ne opravdanyi.

[Profilj ekstraktora](materialyi/profili/ekstraktor.json) otdeljno sokhranyayet semj iskhodnyikh i novyikh zapuskov i khyeshi vsekh JSON. Iskhodnyij Release dlya izmereniya potreboval enable-testing i Swift 5; novyij ne trebuyet obkhodov. Mediana polnogo processa sostavila 14,172 ms u iskhodnogo i 16,725 ms u novogo varianta. Izmenyon kontrakt dostupa, algoritm serializacii sokhranyon; dopolniteljnaya optimizaciya etogo puti ne nuzhna.

## Zaklyuchiteljnaya proverka kontroljnoj tochki

Pervyij read-only dopusk obnaruzhil otsutstviye ignoriruyemogo lokaljnogo graph.json v novom worktree i lishnij pustoj abzac pered trejlerom vremennogo soobsjheniya kommita. Lokaljnoye sostoyaniye Obsidian skopirovano bez perezapisi iz pervichnogo checkout toljko v sobstvennoye derevo i ostayotsya vne Git; istoricheskiye ssyilki sokhranenyi. Razdelitelj pered trejlerom ispravlen bez izmeneniya doslovnyikh komand. Povtor dopuska neobkhodim dlya proverki etikh ispravlenij i vyipolnyayetsya vne mashinnogo profilya po granice kontroljnoj tochki.

## Resheniya i ogranicheniya

- [FUM-SBOJ-0032](../../Sboi/FUM-SBOJ-0032-obsjhiye-izmenyayemyiye-tablicyi-LinguisticKit.md) i [FUM-SBOJ-0033](../../Sboi/FUM-SBOJ-0033-testovyij-import-ekstraktora-LinguisticKit.md) imeyut raznyiye mekhanizmyi i regressionnyiye granicyi.
- Nezavisimyij revjyuyer proveril tochnyij kommit dd583a4031c5af2147c5c2b85d522ef76b018fff, ispolnyayemyij kod, API, testyi, profili i CI; ostavshikhsya obosnovannyikh zamechanij net. Polnoye lokaljnoye derevo i syiryiye logi khranyatsya vne publichnogo FUM.
- Kontroljnaya tochka FUM ne obyyavlyayetsya finaljnoj priyomkoj. Proizvodnaya oblastj Proyekcii sokhranena iz bazyi 9b9c456e0be6ce409f21f4653b6caa09d132f3d7 i otstayot ot novyikh kanonicheskikh materialov.
- CI 34271986351 zavershyon uspeshno na obeikh OS: 32 XCTest i 3 novyikh testa, Release-sborka vsekh produktov, neizmennostj Extracted. PR №14 otkryit v Roman-Kerimov/LinguisticKit iz fum-lab:codex/swift-concurrency-01a07d3d; publikaciya proverena. Ostalosj peredatj kornyu zhurnaljnuyu kontroljnuyu tochku. Obnovleniye gitlink FUM i sliyaniye upstream PR ne vkhodyat v dochernyuyu zapisj.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Pervoye izmeneniye biblioteki](https://github.com/fum-lab/LinguisticKit/commit/b8684654b2a16b04852b5b4cb0ec29e23c354939).
- [Vyipusk Swift 6.3](https://www.swift.org/blog/swift-6.3-released/).
- [Migraciya bibliotechnyikh API dlya Concurrency](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/libraryevolution/).
- [Upstream PR №14](https://github.com/Roman-Kerimov/LinguisticKit/pull/14).
- [Pervyij CI](https://github.com/fum-lab/LinguisticKit/actions/runs/34271323065) i [povtor s Swiftly](https://github.com/fum-lab/LinguisticKit/actions/runs/34271986351).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 23:15:03 MSK -->
<!-- content-sha256: sha256:2868e90806f536d53a5798b8e9ec5f3fcaa64d9aa92651fc694ccbc0fe64cbc6 -->
<!-- FUM-MD-RECENCY:END -->
