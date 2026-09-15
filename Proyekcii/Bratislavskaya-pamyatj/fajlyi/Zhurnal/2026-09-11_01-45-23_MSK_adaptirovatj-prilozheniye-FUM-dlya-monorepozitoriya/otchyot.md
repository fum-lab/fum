# Otchyot 2026-09-11 01:45:23 MSK - Adaptirovatj prilozheniye FUM dlya monorepozitoriya

Podgotovlena proveryayemaya kontroljnaya tochka: 13 iz 39 iskhodnyikh fajlov sokhranenyi pobajtno, 26 adaptirovanyi; dobavlenyi 9 fajlov, vklyuchaya konechnyij manifest. Fajlyi nakhodyatsya v `Приложения/FUMA/macOS`. Kanonicheskij katalog ne peresekayetsya s chetyirjmya paketami FUMA, kotoryiye perenosit korenj. V FUM na baze `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d` net pobajtnyikh sovpadenij s etimi 39 blob. Samostoyateljnyij prototip fizicheskikh klavish sokhranyayetsya otdeljno: yego kontrakt perekhodov/monotonnogo vremeni otlichayetsya ot CGEvent-monitora prilozheniya, kotoryij takzhe sokhranyayet simvolyi, myishj i prokrutku.

Istochnik — tochnyij main `39eb66a29c0be6844e73bcb8072e68b914ea7387`, derevo `c31fc5711fc0e90898ce102eec8cecc5f190d110`: 39 obyichnyikh fajlov, 429019 iskhodnyikh bajtov. Chitalisj toljko zakreplyonnyiye Git blobs. Iskhodnyij repozitorij i yego rabota ne izmenyalisj. Publichnogo promezhutochnogo kommita s prezhnimi mashinnyimi putyami net. Fakticheskaya sreda sborki — macOS 27.0 arm64, Xcode 27.0 beta; versiya 26 v ogranicheniyakh mpv otnositsya k yego bottle, a ne tekusjhemu khostu. Pervichnyij manifest sokhranyayet iskhodnyiye commit/blob/SHA/mode, konechnyij manifest — tochnyiye adaptirovannyiye bajtyi i otdeljnyij spisok novyikh fajlov.

Obsjhiye puti vyinesenyi v Foundation-modulj `ПутиИсполнения`, podklyuchyonnyij vo vse SwiftPM-produktyi i obe Xcode-celi. Runtime i pamyatj nakhodyatsya vne Git, parametryi obsjhiye dlya prilozheniya i pomosjhnikov. Runner sobirayet svoj paket iz lyubogo rabochego kataloga, obnovlyayet raneye sobrannyij helper i ispoljzuyet vneshnij scratch. Sistemnyij mpv podklyuchyon cherez pkg-config i lokaljnyij C-modulj bez kopirovaniya vneshnikh zagolovkov. OpenGL.framework ostayotsya yavnoj linkovkoj; dopolniteljnyij dlopen vozmozhen toljko po zadannomu parametru. Tri ustanovsjhika zavershayutsya do sistemnyikh operacij, tri launchd plist soderzhat neraskryityiye markeryi.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj      | Granicyi i sposob izmereniya |
| ------------------------------ | ----------------- | -------------------------- |
| Chteniye i soderzhateljnaya pravka  | ne izmereno       | Nachalo papki i instrumentyi ne dokazyivayut nepreryivnoye rabocheye vremya |
| Vosproizvedeniye migracii putej  | 0,006355417 s     | Podgotovka 0,004389500 s i zapisj 0,001965917 s; monotonnyij tajmer |
| Sinteticheskaya konfiguraciya      | 0,146–0,159 ms    | Odna konfiguraciya; pyatj obrazcov po 1000 iteracij posle resolver-pravki |
| Otkaz otnositeljnogo puti       | 0,0016–0,0018 ms  | Odna operaciya v tekh zhe pyati obrazcakh |
| Otsutstvuyusjhaya komanda v PATH    | 0,0110–0,0117 ms  | Odna proverka fajla, bez zapuska komandyi |
| C-adapter s podstavnyim zagruzchikom | 0,001794 s     | Dve serii po 100000 vyizovov, ne vremya realjnogo OpenGL |
| Obsjhaya priyomka i integraciya      | ne vyipolneno      | Otdeljnaya rabota kornya posle kontroljnoj tochki |

Granica profilya: instrumentaljnyiye izmereniya ogranichenyi ukazannyimi sinteticheskimi scenariyami i pryamyimi zapuskami nizhe. Ikh summa pokazyivayet stoimostj vyizovov i ne pribavlyayetsya k drugim stadiyam. FIFO, ocheredj, handoff i avtomaticheskoye prodolzheniye ne primenyalisj. Optimizacionnoye resheniye: dopolniteljnoye kyeshirovaniye i uslozhneniye ne trebuyutsya; konfiguraciya shtatno sozdayotsya odin raz, izmerennyiye zatratyi malyi. C-profilj proveryayet toljko nakladnyiye raskhodyi podstavnogo scenariya, ne videoproigryivaniye.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                             | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [compare_app] Pobajtnyij perenos 39 fajlov prilozheniya proverennyim importyorom                       | 2,065 s      | uspeshno   |
| [compare_app] RED: perenosimostj putej i runner prilozheniya na iskhodnom snimke                     | 0,133 s      | neuspeshno |
| [compare_app] RED: runner s yavno otsutstvuyusjhim ustanovlennyim helper i podstavnyim Swift            | 0,564 s      | neuspeshno |
| [compare_app] RED: migraciya obyazana otklonitj vyikhod manifesta iz oblasti                          | 0,078 s      | neuspeshno |
| [compare_app] GREEN: ogranichennaya oblastj migracii prilozheniya                                     | 0,13 s       | uspeshno   |
| [compare_app] Primenitj proverennuyu migraciyu putej s profilem dvukh stadij                         | 0,077 s      | neuspeshno |
| [compare_app] RED: vosproizvesti oshibku otchyota migracii pri otnositeljnom korne                   | 0,187 s      | neuspeshno |
| [compare_app] GREEN: migracionnyij otchyot pri otnositeljnom korne                                   | 0,182 s      | uspeshno   |
| [compare_app] Vosproizvesti migraciyu na iskhodnyikh Git-obyyektakh i sveritj 15 zapisannyikh rezuljtatov | 2,007 s      | uspeshno   |
| [compare_app] RED: runner obyazan proveritj aktualjnostj uzhe susjhestvuyusjhego helper                  | 0,516 s      | neuspeshno |
| [compare_app] GREEN: perenosimyiye puti i runner s podstavnyim Swift                                 | 1,056 s      | uspeshno   |
| [compare_app] Proveritj sintaksis Xcode i plist bez sborki i zapuska                              | 0,014 s      | uspeshno   |
| [compare_app] SwiftPM: proveritj sinteticheskuyu konfiguraciyu i kompilyaciyu prilozheniya, jobs 2       | 19,153 s     | uspeshno   |
| [compare_app] SwiftPM: Release vsekh chetyiryokh produktov, jobs 2                                     | 23,332 s     | uspeshno   |
| [compare_app] RED: konechnyij manifest obyazan pokryivatj 39 iskhodnyikh i vse novyiye fajlyi               | 0,078 s      | neuspeshno |
| [compare_app] Xcode: sobratj prilozheniye i helper bez podpisi i zapuska, jobs 2                    | 17,425 s     | uspeshno   |
| [compare_app] Obnovitj metadannyiye Markdown pered konechnyim manifestom                              | 1,328 s      | uspeshno   |
| [compare_app] Profilj konfiguracii putej: 5 obrazcov, po 1000 operacij kazhdoj stadii              | 2,308 s      | uspeshno   |
| [compare_app] RED: publichnyiye shablonyi i sistemnyiye komandyi trebuyut yavnoj konfiguracii               | 0,077 s      | neuspeshno |
| [compare_app] RED: razresheniye komandyi po yavnomu PATH bez zapuska komandyi                          | 2,368 s      | neuspeshno |
| [compare_app] Primenitj proveryayemoye preobrazovaniye toljko tryokh inertnyikh shablonov                  | 0,079 s      | uspeshno   |
| [compare_app] GREEN: publichnyiye shablonyi i shell-sintaksis                                          | 0,075 s      | uspeshno   |
| [compare_app] Shtatnyij skaner: opredelitj tochnyij ostatok publikacionnoj politiki                   | 22,555 s     | neuspeshno |
| [compare_app] GREEN: konfiguraciya i razresheniye komandyi po PATH, bez zapuska komandyi               | 8,6 s        | uspeshno   |
| [compare_app] RED: C-adapter ne dolzhen otkryivatj neukazannuyu biblioteku; zagruzchik podmenyon       | 5,034 s      | neuspeshno |
| [compare_app] Dovesti neprimenyonnyiye shablonyi i markeryi bez vneshnikh dejstvij                        | 0,078 s      | uspeshno   |
| [compare_app] GREEN i profilj: C-adapter s podstavnyim zagruzchikom, bez vyizovov mpv/OpenGL         | 0,619 s      | uspeshno   |
| [compare_app] Profilj obsjhej konfiguracii i resolver posle izmeneniya PATH                          | 2,15 s       | uspeshno   |
| [compare_app] Release posle adresnyikh izmenenij resolver i C-adaptera, jobs 2                      | 14,576 s     | uspeshno   |
| [compare_app] Skaner posle parametrizacii: sokhranitj tochnyiye opredeleniya i fiksturyi                | 22,093 s     | neuspeshno |
| [compare_app] Xcode: podtverditj posledniye izmeneniya obsjhikh putej, MCP i C-adaptera, jobs 2        | 6,691 s      | uspeshno   |
| [compare_app] Oformitj 25 tochnyikh opredelenij raspoznavatelya i synthetic-fikstur                   | 0,243 s      | uspeshno   |
| [compare_app] Obnovitj recency konechnyikh instrukcij i otchyota pered khyeshirovaniyem                    | 1,337 s      | uspeshno   |
| [compare_app] Sveritj iskhodnyiye Git blobs i sformirovatj konechnyij manifest 39 plyus novyiye fajlyi     | 0,719 s      | uspeshno   |
| [compare_app] GREEN: 12 Python-proverok konechnogo manifesta i perenosimogo povedeniya              | 1,27 s       | uspeshno   |
| [compare_app] Publikacionnyij skaner posle 25 tochnyikh deklaracij                                    | 22,488 s     | uspeshno   |
| [compare_app] Obnovitj recency pered kontroljnoj tochkoj                                           | 1,161 s      | uspeshno   |
| [compare_app] Obnovitj recency posle ustraneniya defektov metadannyikh svyaznosti                     | 1,143 s      | uspeshno   |
| [compare_app] Sveritj konechnyiye SHA posle ispravleniya toljko primera AX help                       | 0,078 s      | uspeshno   |
| [compare_app] Obnovitj recency podtverzhdyonnyikh granic kontroljnoj tochki                            | 1,158 s      | uspeshno   |
| [compare_app] Read-only: sveritj fakticheskiye Mach-O artefaktyi poslednej Xcode-sborki              | 0,827 s      | uspeshno   |
| [compare_app] Obnovitj recency otchyota posle read-only svideteljstva Xcode                         | 1,006 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 187,058 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Python RED/GREEN podtverdil ustraneniye putej, korrektnyij package/scratch iz chuzhogo cwd, obnovleniye starogo helper, neprikosnovennostj vneshnikh dejstvij ustanovsjhika, shell-sintaksis i migracionnyiye granicyi. Konechnyij nabor sveryayet takzhe vse iskhodnyiye i novyiye SHA/mode po manifestu.
- SwiftPM: pyatj sinteticheskikh testov konfiguracii, Git/symlink-granic i poiska komandyi po PATH proshli; komandyi iz PATH ne ispolnyalisj. Chetyire produkta sobranyi v Debug i Release. Posle poslednej pravki resolver/C-adaptera Release vyipolnen povtorno na izmenyonnom vkhode.
- C RED vosproizvyol popyitku otkryitj neukazannuyu biblioteku, GREEN podtverdil otsutstviye takoj popyitki i yavnyij fallback. dlsym/dlopen podmenenyi; funkcii mpv i OpenGL ne vyizyivalisj.
- Xcode sobral obe celi s otklyuchyonnoj podpisjyu, jobs 2 i katalogami mpv iz pkg-config. Pervoye postroyeniye yavno zavershilosj BUILD SUCCEEDED. Povtornaya sborka izmenyonnogo koda vernula 0, no quiet-vyivod Xcode 27 beta soderzhal dve stroki o komande s exit code 0 bez vyivoda i 46 preduprezhdenij. Eto ogranicheniye diagnostiki sokhraneno, a ne obyyavleno otsutstvuyusjhim.
- [Read-only-sverka artefaktov Xcode](materialyi/artefaktyi-Xcode.json) podtverzhdayet chetyire susjhestvuyusjhikh arm64 Mach-O: osnovnoj executable, Debug dylib, vstroyennyij helper i otdeljnyij produkt helper; SHA oboikh helper sovpadayut. Tochnaya argv poslednego zapuska peredana kornyu otdeljnyim soobsjheniyem, publichnyij material khranit otnositeljnyij sostav, SHA, razmeryi i mtime. Nalichiye fajlov samo po sebe ne otmenyayet sokhranyonnyiye ogranicheniya diagnostiki.
- Shtatnaya proverka plutil podtverdila project.pbxproj i plist. Publikacionnyij skaner vyiyavil rabochiye sistemnyiye privyazki: oni ustranenyi. Ostalisj toljko 25 tochnyikh opredelenij raspoznavatelya i sinteticheskikh fikstur, oformlennyikh shtatnyim obnovitelem politiki.

- Posle read-only-revjyu kornya ispravlen poslednij primer imeni AX-produkta v spravke; eta stroka ne menyayet ispolneniye, Swift-sborka iz-za neyo ne povtoryalasj. Konechnyij manifest obnovlyon.
- Itogovyij nabor iz 12 Python-testov i shtatnyij publikacionnyij skaner zavershilisj uspeshno.
- Pervichnaya kontroljnaya svyaznostj vyiyavila otsutstviye tochnogo imeni navyika vremeni, nepolnyij perechenj affected-links i lishnyuyu pustuyu stroku pered commit trailer. Metadannyiye dopolnenyi; otdeljnyij baseline-bloker otsutstvuyusjhego LICENSE zaregistrirovannogo submodule ustranyon razreshyonnoj lokaljnoj podgotovkoj toljko otsutstvovavshego fajla iz blob `0e259d42c996742e9e3cba14c677129b2c1b6311` kommita `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Gitlink, konfiguraciya i iskhodniki zavisimosti ne menyalisj; eto ne polnaya inicializaciya ili proverka zavisimosti, fajl ne vklyuchayetsya v commit FUM.

## Resheniya i ogranicheniya

- Nablyudyonnyij mpv — Homebrew 0.41.0_9, API 2.5, pkg-config 3.0.7; bottle arm64 s minimum macOS 26.0. Preduprezhdeniye linkovki o macOS 14/26 ozhidayemo i ne dokazyivayet sovmestimostj s macOS 14/15 ili Intel. Dinamicheskiye zavisimosti Homebrew ne upakovanyi v avtonomnyij bundle.
- Iskhodnaya sobstvennaya narabotka ne soderzhala LICENSE; ona sokhranyayetsya pod licenziyej FUM. Vneshnij mpv ne stanovitsya CC0: rezhim nablyudyonnoj sborki GPL, FFmpeg imeyet GPL/version3. Zagolovok client.h otdeljno ISC. Binarnaya publikaciya trebuyet otdeljnoj ocenki sostava zavisimostej.
- Xcode vyipolnil standartnuyu registraciyu vremennogo bundle v LaunchServices. Zhivoye prilozheniye, Accessibility-sensor, cikl vnimaniya, ustanovka, launchd, Keychain i zaprosyi razreshenij ne zapuskalisj. Eto ne ispyitaniye organov, razreshenij, UI i videoproigryivaniya.
- Pervyij RED runner imel oshibku izolyacii: pustoj override dopuskal vyibor susjhestvovavshego ustanovlennogo helper. Yemu dostalsya pustoj stdin, instrumentaljnyiye komandyi ne otpravlyalisj; zhivyikh zapisej/GUI ne nablyudalosj. Ispravlennaya fikstura zadayot yavno otsutstvuyusjhij helper, podstavnoj Swift i vremennyiye puti. Neuspeshnaya zapisj sokhranena, otdeljnyij nomer sboya ne vyiduman.
- Pervyij massovyij perenos putej izmenil 15 fajlov, zatem oshibsya pri formirovanii otchyota otnositeljno tochki. Regressiya vosproizvela defekt; korenj normalizovan do absolyutnogo i otchyot podgotovlen do zapisi. Novyij zapusk iz zakreplyonnyikh iskhodnikov v vremennom kataloge podtverdil vse 15 rezuljtatov. Iskhodnyij otkaz ne zamenyon uspeshnoj zapisjyu. Pozdnyaya parametrizaciya shablonov imeyet otdeljnyiye do/posle-khyeshi.
- Izolirovannoye derevo ispoljzuyet prezhneye pokoleniye bratislavskoj proyekcii bazyi 406c6ba1: SHA256 manifesta `cc02a0482eeddea16d44b9049b9f062dc9004f3c09f97b47c9b71c288b7dde98`, vkhodnoj inventarj `544a1e4a110118a3a9e8957b50a3c4a8330380136ef524186f0892861bf62ff2`. Ono otstayot ot novyikh fajlov; kontroljnaya tochka ne vyidayot yego za finaljnoye. Obsjhij smoke-check, aktualjnaya proyekciya, vosproizvedeniye iz chistogo klona, integraciya v vedusjhuyu vetku i resheniye po vsemu obyyomu FUM-STEP-0176 ostayutsya kornyu.
- Vo vremya vosstanovleniya odin vyizov spravki poluchil oshibku iz-za opechatki v imeni instrumenta; instrument ne zapuskalsya i zapisi ne byilo. Chteniye odnostrochnogo boljshogo manifesta proyekcii byilo obrezano vyivodom; zatem nuzhnyiye polya prochitanyi strukturno, bez dogadok po obrezannomu tekstu.

## Istochniki

- [Iskhodnyij zapros](zapros.md) i [pervichnyij chelovecheskij istochnik](../2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/zapros.md).
- [Iskhodnyij manifest](materialyi/iskhodnyij-manifest-prilozheniya.json), [konechnyij manifest](../../Prilozheniya/FUMA/macOS/manifest-perenosa.json), [bezopasnyij otchyot razlichij](materialyi/sverka-perenosa.json).
- [Vosproizvedeniye migracii](materialyi/vosproizvedeniye-migracii.json), [profilj putej i komand](materialyi/profilj-putej-i-komand.json), [profilj C-adaptera](materialyi/profilj-C-adaptera.json), [deklaracii politiki](materialyi/deklaracii-putej.json).
- [Copyright mpv 0.41.0](https://github.com/mpv-player/mpv/blob/v0.41.0/Copyright) i [sistemnyiye zavisimosti SwiftPM](https://github.com/swiftlang/swift-package-manager/blob/main/Sources/PackageManagerDocs/Documentation.docc/Dependencies/AddingSystemLibraryDependency.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:42:00 MSK -->
<!-- content-sha256: sha256:806d0849b58521904f29492d8d23033be8fc47c4bbf3895a025d2b9151c3d580 -->
<!-- FUM-MD-RECENCY:END -->
