# Plan nablyudeniya macOS cherez Swift

FUM dolzhen poluchatj proveryayemyiye nablyudeniya o srede macOS cherez sistemnyiye API i peredavatj ikh agentu v yedinoj forme. Tekusjhaya zadacha sostavlyayet plan. Pod FUMA predvariteljno ponimayetsya tekusjhij proyekt FUM: otdeljnogo sokhranyonnogo proyekta s imenem FUMA pri osmotre ne najdeno.

## Komanda poljzovatelya

````text
Nauchisj videtj cherez vse API, kotoryiye predostavlyayet macOS. Ispoljzuj Swift v proyekte FUMA.
````

## Soderzhateljnyij otvet

Planiruyetsya obsjhij sloj nablyudeniya macOS na Swift: dostupnyiye prilozheniya i okna, semanticheskoye derevo interfejsa, izobrazheniye ekrana i raspoznannyij tekst, fajlovyiye izmeneniya, ustrojstva vvoda, setj i sostoyaniye sistemyi. Osnovoj stanet uzhe susjhestvuyusjheye razdeleniye perenosimogo yadra i platformennyikh adapterov v klaviaturnom prototipe. Zatem sloj podklyuchayetsya k instrumentaljnomu interfejsu agenta, chtobyi poluchennyiye nablyudeniya byili dostupnyi v realjnoj rabochej sessii.

Zapros «vse API» prevrasjhayetsya v proveryayemyij reyestr okhvata SDK: dlya kazhdoj oblasti otmechayutsya realizovannyiye istochniki, dostupnyiye dannyiye, razresheniya, minimaljnaya versiya macOS, ogranicheniya i nepokryitaya chastj. Yedinogo razresheniya na vse dannyiye i universaljnogo API soderzhimogo vsekh prilozhenij plan ne predpolagayet. Swift ispoljzuyetsya dlya realizacii sistemnyikh adapterov i yadra; zapusk prototipa ne podmenyayet podklyucheniye etoj sposobnosti k agentu.

Drugaya pishusjhaya zadacha rabotayet v osnovnom checkout. Po posleduyusjhemu yavnomu ukazaniyu tekusjhaya zadacha poluchila otdeljnyij worktree i vetku: tam sokhranyayutsya komandyi, otvetyi i planyi i zakreplyayutsya pravila povedeniya. Realizaciya novogo Swift-nablyudatelya ostayotsya sleduyusjhim etapom planirovaniya.

## Susjhestvuyusjhaya osnova

V `Прототипы/физические-состояния-клавиш/` uzhe yestj biblioteki `FUMInputCore` i `FUMInputMac`, zhiznennyij cikl istochnika start/stop, otdeljnyiye kanalyi sobyitij i diagnostiki, normalizaciya vremennyikh metok i adapteryi IOHIDManager, GCKeyboard, CGEventTap i NSEvent. Eto klaviaturnyij srez; on yesjhyo ne yavlyayetsya obsjhim nablyudatelem macOS.

Klyuchevyiye tochki koda: `Sources/FUMInputMac/MacKeyboardObservationSource.swift:27`, `Sources/FUMInputMac/MacInputEnvironment.swift:21`, `Sources/FUMInputCore/FUMInputCore.swift:68`. V inventare HID sleduyet razlichitj pustoj spisok i oshibku otkryitiya: sejchas oba sluchaya mogut vozvrasjhatj pustoj massiv.

Prototip `агентное-чтение-сетевой-среды` modeliruyet dvizheniye agentov po arifmeticheskomu grafu. On ne chitayet realjnuyu setj ili sostoyaniye macOS i ne podkhodit v kachestve gotovogo sistemnogo adaptera.

## Pervaya ocheredj istochnikov

| Oblastj             | API                               | Planiruyemyij rezuljtat                                  |
| ------------------- | --------------------------------- | ------------------------------------------------------ |
| Prilozheniya          | NSWorkspace, NSRunningApplication  | Snimok prilozhenij, aktivnoye prilozheniye, izmeneniya.       |
| Semantika interfejsa | AXUIElement, AXObserver            | Dostupnyiye roli, atributyi, elementyi i sobyitiya interfejsa. |
| Ekran i okna        | ScreenCaptureKit, SCShareableContent | Vyibrannyiye okna i displei, kadryi s privyazkoj k istochniku. |
| Tekst izobrazheniya   | Vision                            | OCR s koordinatami i ocenkoj uverennosti.               |
| Fajlovyiye izmeneniya  | FSEvents                          | Izmeneniya vyibrannyikh derevjyev i osnovaniya pereskanirovaniya. |
| Setj                | NWPathMonitor                     | Izmeneniya dostupnogo setevogo puti.                     |
| Pitaniye             | IOPowerSources                    | Sostoyaniye istochnikov pitaniya i uvedomleniya ob izmenenii. |
| Fizicheskij vvod     | Susjhestvuyusjhiye chetyire adaptera       | Podklyucheniye klaviaturnogo sreza bez poteri proiskhozhdeniya. |

NSWorkspace dayot svedeniya o prilozheniyakh, no otdeljnyiye uvedomleniya zapuska ne pokryivayut fonovyiye prilozheniya; dlya takogo okhvata Apple ukazyivayet nablyudeniye za runningApplications. Eto dolzhno byitj otrazheno v testakh polnotyi. [Dokumentaciya Apple](https://developer.apple.com/documentation/appkit/nsworkspace/didlaunchapplicationnotification).

AXUIElement pozvolyayet zaprashivatj spisok dostupnyikh atributov i ikh znacheniya, a takzhe proveryatj doveriye k processu. Nepodderzhannyij atribut sokhranyayetsya kak otdeljnyij iskhod, a ne pustoye znacheniye. [AXUIElement.h](https://developer.apple.com/documentation/applicationservices/axuielement_h), [polucheniye neskoljkikh atributov](https://developer.apple.com/documentation/applicationservices/1462051-axuielementcopymultipleattribute).

ScreenCaptureKit predostavlyayet vyibor i zakhvat ekrannogo soderzhimogo; SCShareableContent perechislyayet dostupnyiye displei, prilozheniya i okna. Dostup k izobrazheniyu i dostup k derevu Accessibility uchityivayutsya nezavisimo. [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit), [SCShareableContent](https://developer.apple.com/documentation/screencapturekit/scshareablecontent).

Vision raspoznayot tekst izobrazheniya; OCR sokhranyayetsya kak rezuljtat raspoznavaniya s istochnikom kadra, a ne vyidayotsya za tochnoye znacheniye elementa Accessibility. [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest).

FSEvents soobsjhayet ob izmeneniyakh nablyudayemogo dereva. Perechenj fajlov utochnyayetsya po snimku; podpiska nachinayetsya do pervonachaljnogo obkhoda, a izmeneniya vo vremya nego privodyat k povtornomu chteniyu zatronutyikh mest. Ispoljzovan arkhivnyij oficialjnyij obzor; konkretnyiye flagi i dostupnostj nuzhno sveritj s vyibrannyim SDK pri realizacii. [Rukovodstvo Apple](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html).

NWPathMonitor nablyudayet setevoj putj i yego izmeneniya; eto ne soderzhimoye trafika vsekh processov. IOPowerSources dayot sostoyaniye batarej i IBP i uvedomleniya ob izmeneniyakh. [NWPathMonitor](https://developer.apple.com/documentation/network/nwpathmonitor), [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h).

## Posledovateljnostj realizacii

1. **Inventarj okhvata.** Zafiksirovatj ustanovlennuyu macOS, vyibrannyij SDK, arkhitekturu i Swift toolchain. Sostavitj konechnyij reyestr publichnyikh semejstv API nablyudeniya i ikh dostupnosti. Dopolniteljno obsledovatj processnyiye i resursnyiye dannyiye Darwin/Foundation, displei, toma, audio i video, ustrojstva IOKit, Bluetooth i prikladnyiye interfejsyi. Dlya kazhdoj oblasti yavno otmetitj, kakiye dannyiye dejstviteljno nablyudayutsya. Pravila dostupa i trebovaniya entitlement proveryatj po oficialjnoj dokumentacii i fakticheskomu SDK; nedostupnyij istochnik ostayotsya vidimyim v reyestre.
2. **Perenosimoye yadro na Swift.** Sozdatj otdeljnyij prototip `Прототипы/наблюдение-macOS/` s yadrom, macOS-adapterami i CLI. Novyiye sobstvennyiye smyislovyiye imena pisatj kirillicej. Obsjheye nablyudeniye khranit istochnik i versiyu, identichnostj obyyekta, vremya polucheniya i predostavlennoye API vremya sobyitiya, poleznyiye dannyiye, oblastj okhvata, svezhestj i diagnostiku. Ne rasshiryatj tip fizicheskogo nazhatiya do universaljnogo sobyitiya.
3. **Pervyij skvoznoj scenarij.** Perechislitj istochniki i tekusjhij dostup; poluchitj aktivnoye prilozheniye, dostupnoye derevo yego interfejsa i vyibrannyij kadr okna; svyazatj rezuljtatyi po prilozheniyu, oknu, geometrii i vremeni. Ne schitatj neskoljko posledovateljnyikh API-vyizovov atomarnyim snimkom: fiksirovatj raskhozhdeniya i povtoryatj toljko neobkhodimyiye chteniya.
4. **Zhiznennyij cikl i razresheniya.** Dlya kazhdogo adaptera realizovatj snimok, podpisku, ostanovku, tajm-aut i diagnosticheskiye iskhodyi «dostupno», «net razresheniya», «ne podderzhivayetsya», «istochnik ischez», «oshibka». Sostoyaniye dostupa proveryatj bez avtomaticheskogo pokaza dialogov; zapros razresheniya — otdeljnoye yavnoye dejstviye interfejsa. Dlya stabiljnoj povtornoj rabotyi podgotovitj .app-obolochku s ustojchivoj identichnostjyu. Poljzovateljskiye sobyitiya i izobrazheniya po umolchaniyu ne stanovyatsya otslezhivayemyimi fajlami repozitoriya.
5. **Sobyitiya i stoimostj.** Ispoljzovatj uvedomleniya vmesto postoyannogo polnogo oprosa tam, gde API ikh predostavlyayet. Ogranichitj ocheredi, chastotu kadrov i obyyom dereva Accessibility. Uchityivatj poteryu sobyitij, perepolneniye, zavissheye prilozheniye, otklyucheniye ustrojstva, son i probuzhdeniye. Dlya fajlovyikh izmenenij vesti proveryayemyij snimok, a ne schitatj potok uvedomlenij polnyim zhurnalom soderzhimogo.
6. **Instrumentaljnyij dostup agenta.** Dobavitj stabiljnyij Swift CLI s operaciyami «vozmozhnosti», «dostup», «snimok», «podpiska», «ostanovka» i versionirovannyim mashinnyim vyivodom. Zatem podklyuchitj lokaljnyij instrumentaljnyij most k rabochej srede agenta i zaregistrirovatj yego v reyestre instrumentov. Priyomka vklyuchayet realjnyij vyizov iz agentskoj sessii; ispolnyayemyij primer sam po sebe ne oznachayet, chto agent uzhe poluchil novuyu sposobnostj.
7. **Rasshireniye okhvata.** Posle pervogo skvoznogo scenariya posledovateljno podklyuchatj ostaljnyiye semejstva iz reyestra. Kazhdyij novyij istochnik poluchayet sobstvennyij kontrakt dostupnosti i regressionnyiye scenarii. Sostoyaniye «vesj macOS podderzhan» ne ispoljzovatj; polnotu ocenivatj otnositeljno konkretnoj versii reyestra i SDK.

## Kriterii priyomki

- Bez razresheniya istochnik soobsjhayet tochnuyu prichinu; otkaz ili pustoj spisok ne vyidayutsya za otsutstviye nablyudayemyikh obyyektov.
- Izmeneniya razreshenij, ischeznoveniye prilozheniya i sobyitiya sna ne zavisayut i ne podmenyayutsya ustarevshimi dannyimi.
- Semanticheskij tekst i OCR sokhranyayut raznoye proiskhozhdeniye; raskhozhdeniye ostayotsya nablyudayemyim.
- Ogranichenyi vremya zaprosa, pamyatj i ocheredj sobyitij; ostanovka prekrasjhayet podpiski.
- Avtonomnyiye testyi vosproizvodyat zapisannyiye i sinteticheskiye otvetyi bez zhivogo zakhvata. Otdeljnaya razreshyonnaya priyomka proveryayet nastoyasjhij macOS-istochnik i dostup cherez instrument agenta.
- Dlya kazhdogo semejstva API mozhno pokazatj realizovannyij scenarij, trebuyemoye razresheniye, podderzhannyiye versii i nepokryituyu chastj.
- Kod i sistemnyiye adapteryi napisanyi na Swift; iskhodniki, pasport, tochka zapuska i ogranicheniya sokhranenyi v FUM posle dopuska k pishusjhej sessii.

## Dolgovremennyij zhurnal nablyudenij

### Dopolneniye poljzovatelya

````text
Vsyo eto nablyudeniye myi dolzhnyi byitj sposobnyi sokhranyatj v zhurnal v postoyannom zapominayusjhem ustrojstve.
````

### Prinyatyij rezuljtat

Kazhdyij podklyuchyonnyij vid nablyudeniya dolzhen imetj sokhranyayemoye predstavleniye na postoyannom nositele: sobyitiya, snimki, kadryi, iskhodnyiye otvetyi API v dopustimoj oblasti, rezuljtatyi OCR, svedeniya ob istochnike, razresheniyakh, oshibkakh i razryivakh. Chelovekochitayemaya zapisj zadachi v repozitorii svyazyivayetsya s etim zhurnalom proiskhozhdeniyem. Massivyi poljzovateljskikh ekrannyikh i apparatnyikh dannyikh khranyatsya v vyibrannom rabochem khranilisjhe, chjya yomkostj i dostupnostj nablyudayemyi.

### Format i podtverzhdeniye zapisi

- Neizmenyayemyiye segmentyi uporyadochennogo zhurnala soderzhat posledovateljnostj, identifikator seansa i istochnika, versiyu skhemyi, vremya polucheniya i sobyitiya, tip dannyikh, khyesh i ssyilku na boljshiye dannyiye.
- Kadryi i drugiye krupnyiye obyyektyi zapisyivayutsya otdeljno s adresaciyej po khyeshu. Podtverzhdyonnaya zapisj sobyitiya ne dolzhna ssyilatjsya na nezafiksirovannyij obyyekt.
- Poleznyiye dannyiye snachala polnostjyu zapisyivayutsya i sinkhroniziruyutsya; zatem fiksiruyetsya segment i podtverzhdyonnyij ukazatelj zhurnala. Otvet «sokhraneno» vyidayotsya toljko posle uspeshnoj granicyi fiksacii. Paketnaya fiksaciya dopustima s yavnyim razlichiyem prinyatogo v bufer i podtverzhdyonnogo.
- Pri povtore ispoljzuyutsya ustojchivyiye identifikatoryi zapisi. Sboj posle publikacii ukazatelya trebuyet perechitatj yego: oshibka otveta sama po sebe ne dokazyivayet otkat.
- Posle perezapuska proveryayutsya granica podtverzhdyonnogo prefiksa, khyeshi, ssyilki i versiya; nepodtverzhdyonnyij khvost i vremennyiye fajlyi ne stanovyatsya prinyatoj istoriyej avtomaticheski.
- Indeks po vremeni, istochniku, prilozheniyu i tipu vosstanavlivayetsya iz zhurnala. SQLite mozhno ocenitj kak proizvodnyij indeks; yesli on uchastvuyet v podtverzhdenii dannyikh, rezhimyi sinkhronizacii vyibirayutsya yavno, poskoljku WAL s NORMAL i FULL dayot raznyiye garantii pri sboye. [Dokumentaciya SQLite](https://www.sqlite.org/wal.html).

### Pereispoljzovaniye Swift-koda FUM

`ContentAddressedGenerationStore` v `Прототипы/воспроизводимое-пополнение-памяти/Sources/FUMReproducibleMemoryPopulation/ContentAddressedGenerationStore.swift` uzhe obespechivayet adresnoye pokoleniye, staging, polnuyu zapisj, fsync, publikaciyu bez zamesjheniya i CURRENT s blokirovkoj. Metod fiksacii nachinayetsya na stroke 232; vozvrat posle publikacii i sinkhronizacii — na stroke 394. Etot skhemonezavisimyij mekhanizm sleduyet proveritj kak osnovu publikacii manifestov segmentov.

Neljzya perenositj susjhestvuyusjhuyu domennuyu modelj pamyati bez izmenenij: ona rasschitana na remember/compose i ogranichennoye chislo sobyitij, a nepreryivnomu nablyudeniyu nuzhnyi segmentyi i otdeljnyiye krupnyiye obyyektyi. Proverennaya garantiya susjhestvuyusjhego prototipa otnositsya k avarii processa; ustojchivostj k potere pitaniya yego pasport ne zayavlyayet. V novom zhurnale otdeljno zadayutsya i proveryayutsya granicyi avarii processa, perezapuska OS i poteri pitaniya dlya vyibrannogo nositelya.

Klaviaturnyij `GuidedCaptureRecorder` prigoden kak primer formata JSONL, no ne gotov kak postoyannyij nadyozhnyij zhurnal: sinkhronizaciya vyipolnyayetsya pri zakryitii kartochki ili seansa. Reduktor menyayetsya do append, a GUI pri oshibke zapisi toljko pokazyivayet soobsjheniye. Do integracii neobkhodimyi podtverzhdeniye fiksacii i ostanovka libo diagnosticheskij razryiv pri otkaze.

### Yomkostj i proverka vosstanovleniya

- Pri nekhvatke mesta ili I/O-oshibke zapisj ne podtverzhdayetsya; potok ostanavlivayetsya ili yavno fiksiruyetsya nedostupnyij interval. Yesli nositelj uzhe ne prinimayet dazhe soobsjheniye ob oshibke, oshibka vozvrasjhayetsya vyizyivayusjhemu kodu, a neopredelyonnyij razryiv otmechayetsya pri vosstanovlenii. Neljzya obesjhatj zapisj markera na zapolnennyij disk.
- Proverka svobodnogo mesta polezna, no ne zamenyayet obrabotku oshibok fakticheskogo write/fsync. Bufer ogranichen; molchalivoye udaleniye raneye podtverzhdyonnyikh nablyudenij ne primenyayetsya.
- Rotaciya razdelyayet segmentyi; udaleniye, szhatiye s poteryami i sokrasjheniye sroka khraneniya trebuyut yavno vyibrannoj politiki. Rezervnaya kopiya dolzhna vklyuchatj zhurnal i vse dostizhimyiye obyyektyi soglasovannogo snimka.
- Adresnyiye scenarii okhvatyivayut chastichnyij write, ENOSPC, oshibku fsync, preryivaniye do i posle publikacii ukazatelya, povrezhdeniye segmenta, otsutstvuyusjhij obyyekt, povtor podachi i povtornoye otkryitiye. Poslednij podtverzhdyonnyij prefiks obyazan vosstanavlivatjsya bez izmeneniya smyisla.
- Priyomka vklyuchayet zapisj na vyibrannyij postoyannyij nositelj, zakryitiye i povtornoye otkryitiye drugim processom, chteniye iskhodnyikh dannyikh i vosproizvedeniye nablyudenij. Do takoj proverki sposobnostj dolgovremennogo khraneniya ne obyyavlyayetsya realizovannoj.

## Vosstanovleniye dialoga iz JSONL

### Komandyi poljzovatelya

````text
Soderzhimoye nashego tekusjhego dialoga chitaj iz jsonl.
````

````text
Chtobyi szhatiye konteksta nichego ne bylo.
````

### Rabochij kontrakt

Iskhodnyij lokaljnyij JSONL tekusjhej zadachi Codex stanovitsya proveryayemyim istochnikom dlya vosstanovleniya perepiski. Tochnyij seans opredelyayetsya iz CODEX_THREAD_ID i metadannyikh fajla, a ne po pokhozhemu zagolovku. V etoj zadache fajl uzhe najden i prochitan; pri pervonachaljnom chtenii vosstanovlenyi devyatj poljzovateljskikh soobsjhenij. Posleduyusjhiye komandyi dobavlyalisj po mere postupleniya; tekusjhij Zhurnal soderzhit 19 komand v iskhodnoj posledovateljnosti.

Chteniye fiksiruyet polnyij zavershyonnyij prefiks fajla. Nezavershyonnaya poslednyaya stroka ostayotsya dlya sleduyusjhego chteniya. Dlya poljzovateljskogo dialoga izvlekayutsya toljko poljzovateljskiye soobsjheniya i vidimyiye otvetyi kornevogo assistenta; sluzhebnyiye instrukcii sredyi, vnutrenniye rassuzhdeniya, otvetyi instrumentov i soobsjheniya subagentov ne perepisyivayutsya v publikuyemyij zhurnal. U otveta cherez voprosnik sokhranyayutsya tochnyiye tekst voprosa i vyibrannyij otvet bez tekhnicheskikh identifikatorov interfejsa.

Posle szhatiya konteksta i pered prodolzheniyem resheniya perechityivayutsya pervichnyiye komandyi, ikh utochneniya, prinyatyiye ogranicheniya i nezavershyonnyiye dejstviya. Kursor soderzhit poziciyu, chislo zavershyonnyikh strok i khyesh prochitannogo prefiksa; on zapisyivayetsya toljko posle sokhraneniya sootvetstvuyusjhej vyigruzki dialoga. Pri usechenii ili izmenenii starogo prefiksa trebuyetsya povtornaya sverka; odinakovyiye tekstyi otdeljnyikh soobsjhenij ne dedupliciruyutsya po tekstu.

Svodka mozhet uskoryatj poisk, no yeyo utverzhdeniya proveryayutsya po iskhodnyim zapisyam. Eto vosstanavlivayemostj konteksta, a ne otklyucheniye mekhanizma szhatiya Codex i ne obesjhaniye beskonechnogo kontekstnogo okna. Nedostupnyij ili povrezhdyonnyij JSONL dolzhen davatj yavnuyu granicu chteniya. Postoyannoye zakrepleniye etogo poryadka vkhodit v uzhe soglasovannyij punkt izmeneniya kanonicheskikh pravil.

## Granica tekusjhego rezuljtata

Dlya napravleniya nablyudeniya vyipolnenyi staticheskij analiz imeyusjhegosya Swift-koda i chteniye oficialjnoj dokumentacii Apple. Novyij prototip nablyudeniya ne sozdan i ne sobiralsya; zakhvat ekrana i poljzovateljskogo vvoda ne zapuskalsya. Sborka Swift-preobrazovatelya v proverke proyekcii otnositsya k drugomu napravleniyu. Rabota po uskoreniyu proyekcii i postoyannomu zakrepleniyu pravil sokhranyayetsya.

## Svyazannyiye materialyi

- [Iskhodnyiye komandyi tekusjhej zadachi](../../zapros.md).
- [Istoriya soderzhateljnyikh otvetov](../../otchyot.md).
- [Plan uskoreniya proyekcii i zakrepleniya povedeniya](plan.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 23:48:47 MSK -->
<!-- content-sha256: sha256:debb573cb6539dfed878b88ad3bf6a725e1e1aa3a8380475f17040a513096bf2 -->
<!-- FUM-MD-RECENCY:END -->
