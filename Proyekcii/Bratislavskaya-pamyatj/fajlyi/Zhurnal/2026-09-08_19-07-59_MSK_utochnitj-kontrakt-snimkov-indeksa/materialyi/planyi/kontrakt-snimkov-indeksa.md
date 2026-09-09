# Proyekt kontrakta snimkov indeksa i granicyi komand

Status: proyektnaya detalizaciya [FUM-STEP-0155](../../../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0155-realizovatj-priyomku-snimkov-indeksa-v-odnoj-zadache.md). Kontrakt nizhe predlagayetsya dlya budusjhej realizacii. Ispolnyayemyij protokol, yego skhema i novyiye polnomochiya etim dokumentom ne vvodyatsya. Dejstvuyusjhiye run-v4 i report-v3 sokhranyayut sobstvennyiye ogranicheniya i priyomku zhivogo checkout.

Celj — prinimatj neizmenyayemyij snimok odnoj postoyannoj zadachi i sokhranyatj novyiye komandyi i soderzhateljnyiye otvetyi v yeyo rabochem dereve vo vremya proverki. Kommit otnositsya toljko k prinyatomu itogovomu derevu. Neokhvachennyij khvost ostayotsya yavnyim vkhodom sleduyusjhego raunda.

## Obyyektyi i predstavleniye

Sessiya, papka Zhurnala i raund imeyut raznyiye identichnosti. Kornevoj identifikator zadachi ostayotsya postoyannyim, papka ukazyivayet konkretnyij zapros i otchyot, novyij raund poluchayet otdeljnyij UUID. Rolj agenta yavlyayetsya atributom uchastnika i ne zamenyayet identifikator zadachi ili pravo zapisi.

Predlagayetsya versiya `приёмка-дерева.версия-1` s chetyirjmya vidami neizmenyayemyikh zapisej: `вход`, `результат`, `решение_о_коммите`, `квитанция`. Do realizacii nuzhno zakrepitj mashinnuyu skhemu s zakryityim naborom polej kazhdogo vida. Neizvestnoye pole, versiya ili vid zapisi oznachayut otkaz. Polya etogo proyekta nazyivayutsya po-russki; tekusjhiye formatyi ne pereimenovyivayutsya.

Dlya bajtovogo khyesha zapisj kodiruyetsya UTF-8, bez BOM, s LF v konce, bez neznachasjhikh probelov, s klyuchami obyyektov v poryadke kodovyikh tochek Unicode. Stroki sokhranyayutsya bez normalizacii Unicode; povtornyiye klyuchi, NaN, drobnyiye znacheniya schyotchikov i otricateljnyiye dlinyi zapresjhenyi. Chisla ogranichivayutsya celyimi 0…2^63−1. Sobstvennyij SHA-256 khranitsya v otdeljnom konverte, kotoryij ne vklyuchyon v khyeshiruyemyiye bajtyi. Proveryayusjhij sravnivayet fakticheskiye bajtyi s yedinstvennyim dopustimyim kodirovaniyem.

V strokakh kavyichka i obratnaya kosaya cherta ekraniruyutsya, upravlyayusjhiye U+0000…U+001F kodiruyutsya shestisimvoljnoj posledovateljnostjyu obratnaya kosaya cherta, `u` i chetyire strochnyiye shestnadcaterichnyiye cifryi. Ostaljnyiye skalyarnyiye znacheniya Unicode zapisyivayutsya neposredstvenno UTF-8; surrogatyi otvergayutsya. Aljternativnyiye korotkiye escape-posledovateljnosti i neobyazateljnoye ekranirovaniye ne vkhodyat v kanonicheskoye kodirovaniye. Poryadok massivov znachim; khyeshi imeyut strochnyiye shestnadcaterichnyiye cifryi.

Git OID zadayotsya paroj `алгоритм` i `значение`: polnyij shestnadcaterichnyij SHA-1 libo SHA-256 v sootvetstvii s formatom repozitoriya, s proverkoj ozhidayemogo tipa obyyekta. Sokrasjhyonnyij khyesh, imya vetki, vremya, PID, razmer fajla ili sovpadeniye recency ne yavlyayutsya identichnostjyu soderzhimogo. Obyichnyiye bajtovyiye khyeshi vsegda yavno ukazyivayut SHA-256 i dlinu iskhodnyikh bajtov.

## Vkhodnoj snimok

Vse sleduyusjhiye polya obyazateljnyi; otsutstviye dopustimogo predshestvennika oboznachayetsya yavnyim null toljko v pervom raunde.

Snachala fiksiruyetsya OID dereva vkhoda, zatem zapisj `вход` i yeyo khyeshiruyusjhij konvert dolgovechno ustanavlivayutsya vne etogo dereva i yego proverochnoj materializacii. Derevo vkhoda ne soderzhit samu zapisj, yeyo konvert ili obratnuyu zavisimostj ot ikh khyeshej; eksport soobsjhenij i vkhodnyiye manifestyi takzhe ne soderzhat takuyu zavisimostj. Posle zakrepleniya OID tochnyiye bajtyi zapisi i konverta mogut vojti v yavno razreshyonnuyu sluzhebnuyu deljtu dereva vyikhoda libo v sleduyusjheye derevo. Eto ne dopolnyayet i ne peresozdayot uzhe zakreplyonnoye derevo vkhoda.

- `версия`, `вид: вход`, `идентификатор_задачи`, `идентификатор_раунда`, `предыдущая_квитанция` — UUID zadachi i raunda, SHA-256 poslednej proverennoj kvitancii libo null. Povtor UUID s drugimi bajtami otvergayetsya.
- `запрос`, `отчёт` — tochnyiye otnositeljnyiye kanonicheskiye puti v prinimayemom dereve. Zapresjhenyi absolyutyi, vyikhodyi naruzhu, neodnoznachnyij registr i simvolicheskiye ssyilki v marshrute.
- `исходный_коммит`, `исходная_ветка`, `дерево_входа` — OID susjhestvuyusjhikh commit i tree i polnoye ozhidayemoye imya ref. Vetka ostayotsya usloviyem dopuska, a soderzhimoye zadayot OID dereva. Kommit obyazan byitj proverennyim predkom dopustimoj istorii; odin lishj pokhozhij spisok fajlov proiskhozhdeniye ne dokazyivayet.
- `граница_команд` — opisannyij nizhe nepustoj uporyadochennyij eksport soobsjhenij, yego dlina i SHA-256. Sam eksport nakhoditsya v dereve vkhoda i imeyet sobstvennyij blob OID. Granica zadayot posledneye polnostjyu prinyatoye soobsjheniye, a ne moment nachala dliteljnoj proverki.
- `основание_полномочий` — ssyilki na konkretnyiye eksportirovannyiye poljzovateljskiye soobsjheniya, razreshivshiye dejstviye, i predelyi dejstviya. Otdeljnyiye polnomochiya na publikaciyu neljzya vyivesti iz razresheniya lokaljnogo kommita.
- `зависимости` — dlya kazhdogo gitlink tochnyiye putj i OID kommita, dokazateljstvo dostupnosti i identichnosti materializovannyikh fajlov; dlya arkhiva — putj, dlina i SHA-256. Tree ne soderzhit bajtyi podmodulya avtomaticheski. Nedostupnostj ili gryaznaya podmena zavisimosti zakryivayet zapusk.
- `профиль_среды` — neizmenyayemyij manifest versij runtime, kompilyatora, znachimyikh parametrov sborki i ogranichenij sredyi. V nyom net sekretov, polnogo okruzheniya i lokaljnyikh absolyutnyikh putej. On fiksiruyet nablyudayemuyu sredu, no ne obesjhayet vosproizvodimostj neizvestnyikh faktorov.
- `план_проверок` — tochnyij uporyadochennyij spisok komand, klassov i svyazej diagnostiki, khyeshi pravil i instrumentov iz dereva vkhoda, politika razreshyonnyikh rezuljtatov. Dlya ispolneniya chitayutsya pravila i instrumentyi materializovannogo snimka; boleye pozdneye suzheniye polnomochij poljzovatelya vsyo ravno dejstvuyet.
- `политика_выхода` — versiya konechnogo perechnya dopustimyikh putej i preobrazovanij, vklyuchaya rezhim fajla, dopustimyij istochnik rezuljtata i obyazateljnyij sposob nezavisimoj proverki. Obsjhiye isklyucheniya dlya vsego Zhurnala, vsekh indeksov ili lyuboj proyekcii ne dopuskayutsya.

Materializaciya chitayet Git-obyyektyi ukazannogo dereva v otdeljnom proverochnom kataloge. Primenyonnyiye attributes, filjtryi, okonchaniya strok, ispolnyayemyiye bityi i simvolicheskiye ssyilki dolzhnyi sootvetstvovatj yavno proverennoj politike; obyichnyij checkout s neuchtyonnyimi poljzovateljskimi filjtrami nedostatochen. Dostup k zhivomu checkout ne stanovitsya zapasnyim istochnikom nedostayusjhikh fajlov.

Dlya vlozhennyikh ssyilok na manifestyi ispoljzuyetsya yedinaya zakryitaya struktura: `путь` — stroka, `объект` — Git OID, `длина` — celoye chislo bajtov, `хэш_байтов` — stroka iz 64 cifr. `профиль_среды`, `план_проверок` i `политика_выхода` yavlyayutsya takimi ssyilkami. Plan soderzhit massiv zapisej `номер`, `аргументы` (massiv strok bez shell-interpretacii), `класс`, `зависит_от` (nomera predyidusjhikh shagov), `ожидаемый_исход`, `ссылки_на_инструменты` i `ссылки_на_правила`; ciklyi i neizvestnyiye nomera otvergayutsya. Eto opisaniye polej budusjhej skhemyi, a ne novaya dopustimaya komanda dejstvuyusjhej obyortki.

## Granica komand i nemedlennaya otmena

Iskhodnyij dialog prodolzhayet chitatjsya iz fakticheskogo JSONL. Lokaljnaya kvitanciya chteniya soderzhit identichnostj istochnika, chislo zakonchennyikh bajtov, SHA-256 tochnogo prefiksa i pozicii vklyuchyonnyikh zapisej. Lokaljnyij putj i sluzhebnyiye polya etoj kvitancii ne kopiruyutsya v publikuyemoye derevo. Nezakonchennaya poslednyaya stroka ostayotsya khvostom do uspeshnogo chteniya celoj zapisi; razbor po vremeni ili po odnomu tekstovomu sovpadeniyu zapresjhyon.

Publikuyemyij eksport soderzhit toljko vyibrannyiye poljzovateljskiye komandyi i vidimyiye soderzhateljnyiye otvetyi osnovnoj zadachi. Kazhdoye soobsjheniye imeyet `номер` v obsjhej posledovateljnosti zadachi, `роль`, tochnyij `текст`, `байтовая_длина`, `хэш_байтов`; identichnyiye tekstyi v raznyikh poziciyakh — raznyiye soobsjheniya. Otdeljnaya zapisj proiskhozhdeniya svyazyivayet nomera s lokaljnoj kvitanciyej. Sistemnyiye soobsjheniya, skryityiye rassuzhdeniya, vnutrenniye soobsjheniya subagentov i neobrabotannyij sluzhebnyij vyivod ne yavlyayutsya poljzovateljskim dialogom. Yesli tekst soderzhit sekret, trebuyetsya otdeljnaya fiksiruyemaya granica publikacii; molchalivoye redaktirovaniye s sokhraneniyem prezhnego khyesha nedopustimo.

Obyichnaya novaya komanda poluchayet sleduyusjhij nomer i ostayotsya pozdnim khvostom. Otmena, zapret publikacii ili drugoye suzheniye polnomochij primenyayetsya srazu posle polucheniya, dazhe yesli nomer soobsjheniya nakhoditsya za granicej tekusjhego vkhoda. Proverka starogo snimka ne zamorazhivayet volyu poljzovatelya.

Pered dopuskom k kommitu kontroller obrabatyivayet vse uzhe dostavlennyiye upravlyayusjhiye soobsjheniya i svyazyivayet dopusk s posledovateljnyim nomerom nablyudeniya polnomochij. Poluchennaya do dopuska otmena zapresjhayet kommit; otmena vo vremya proverki ostanavlivayet okhvachennyiye processyi i sokhranyayet nablyudayemyij iskhod. Utrata kanala nablyudeniya oznachayet otsutstviye dokazannogo dopuska. Novaya komanda posle uzhe sostoyavshegosya atomarnogo izmeneniya ref otnositsya k sleduyusjhemu dejstviyu: istoricheskij kommit avtomaticheski ne perepisyivayetsya.

Budusjhaya realizaciya obyazana opredelitj odnu ocheredj dostavki i tochku linearizacii mezhdu polucheniyem otmenyi i atomarnyim izmeneniyem ref. Proverka ocheredi, za kotoroj sleduyet nezasjhisjhyonnyij promezhutok do kommita, etogo trebovaniya ne vyipolnyayet. Vremya otpravki, yesjhyo ne nablyudavsheyesya kontrollerom, ne podmenyayet vremya polucheniya.

## Rezuljtat, itogovoye derevo i kvitanciya

Zapisj `результат` soderzhit `версия`, `вид`, `идентификатор_задачи`, `идентификатор_раунда`, `хэш_входа`, `дерево_входа`, `запуски`, `вердикт`, `причина`, `результаты_путей` i `граница_полномочий`.

`запуски` — uporyadochennyiye identifikatoryi i SHA-256 tochnyikh terminaljnyikh zapisej, ikh klassyi, kodyi iskhoda i izmerennyiye dliteljnosti. Ne zavershivshijsya process ne poluchayet pridumannoye vremya ili uspeshnyij iskhod. Verdikt prinimayet znacheniya `принят`, `отклонён`, `отменён`, `не_установлен`; prichina opisyivayet nablyudayemoye osnovaniye otdeljno ot rezuljtata testa. Otkaz sredyi ne prevrasjhayetsya v dokazannyij defekt agenta.

`результаты_путей` perechislyayut toljko razreshyonnyiye rezuljtatyi proverki i generacii. Dlya kazhdogo puti ukazanyi operaciya, blob OID i rezhim do/posle, dlina i SHA-256 fakticheskikh novyikh bajtov, identifikator porodivshego shaga i proveryayusjhego svideteljstva; otsutstviye storonyi zadayotsya null. Zamena tipa, udaleniye ili izmeneniye drugogo puti zapresjhenyi. Soglasovannostj kanonicheskogo sloya, recency, indeksa i proyekcii proveryayetsya po ukazannoj politike, a ne po zayavleniyu generatora.

Zakryityiye polya zapisi deljtyi: `путь`, `операция` (`добавление`, `изменение` ili `удаление`), `до`, `после`, `шаг`, `хэш_проверки`. Nenulevaya storona soderzhit toljko `объект`, `режим`, `длина`, `хэш_байтов`; rezhim — tochnaya Git-stroka, a obyyekt imeyet sootvetstvuyusjhij yemu tip. Gitlink ne vyidayotsya za blob. Puti unikaljnyi i uporyadochenyi po bajtam UTF-8. Dlya sluzhebnyikh zapisej polnogo perechnya deljtyi shag ssyilayetsya na konkretnoye pravilo zamyikaniya toj zhe versii politiki.

Itogovoye derevo stroitsya iz dereva vkhoda i etogo perechnya, zatem dopolnyayetsya zaraneye opredelyonnyim sluzhebnyim naborom. Yego puti i sposobyi obrazovaniya zakreplyayet konechnaya versiya politiki. Nabor vklyuchayet zapisj `результат` i vse artefaktyi, chji bajtyi tranzitivno zavisyat ot neyo: naprimer, proyekciyu otchyota, indeks s yego khyeshem i proizvodnyiye ot takogo indeksa. Yesli khotya byi odin zavisimyij artefakt ostalsya za predelami nabora, politika zamyikaniya ne prinimayetsya.

Zapisj `результат` ne soderzhit OID, bajtovyiye khyeshi ili drugiye vyichislyayemyiye iz soderzhimogo identifikatoryi samoj sebya i lyubogo tranzitivno zavisimogo ot neyo artefakta. Eti artefaktyi ne vkhodyat v yeyo `результаты_путей`. Poetomu petlya «rezuljtat → OID proyekcii ili indeksa → tekst libo khyesh rezuljtata» ne stanovitsya dopustimoj posle isklyucheniya toljko sobstvennogo blob. Tochnyiye Git OID zavisimogo sluzhebnogo nabora i finaljnyij perechenj absolyutno vsekh razlichij fiksiruyutsya toljko v posleduyusjhej kvitancii. Khyeshi raneye zakreplyonnogo vkhoda i nezavisimyikh rezuljtatov proverki po-prezhnemu mogut vkhoditj v `результат`.

Nezavisimyij validator vyivodit polnyij konechnyij nabor putej iz versii politiki, proveryayet graf soderzhateljnyikh zavisimostej i otsutstviye ciklov, zatem vosproizvodit sluzhebnyiye bajtyi v dopustimom poryadke. Politika ne mozhet razreshatj proizvoljnyiye katalogi libo molcha obryivatj tranzitivnoye zamyikaniye na proyekcii ili indeksakh. Yesli sam sposob generacii obrazuyet cikl, versiya politiki otvergayetsya do formirovaniya prinimayemogo vyikhoda. Sluzhebnyij nabor mozhet dopolniteljno vklyuchatj nezavisimyiye zapisj vkhoda i konvert po predyidusjhemu razdelu; eto ne razreshayet obratnyiye ssyilki v derevo vkhoda.

Kvitanciya soderzhit `версия`, `вид: квитанция`, UUID zadachi i raunda, `предыдущая_квитанция`, `хэш_входа`, `хэш_результата`, `дерево_входа`, `дерево_выхода`, `полная_дельта`, `итоговый_коммит`, `родитель_коммита`, `ветка`, `граница_полномочий`, `хэш_решения_о_коммите` i `свидетельство_замыкания`. Posledneye svyazyivayet proverku polnogo dereva vyikhoda, deljtyi, soobsjheniya i kommita s versiyami validatorov i khyeshami ikh terminaljnyikh zapisej.

Kvitanciya sozdayotsya posle proverki fakticheskikh tree, parent i tochnyikh bajtov polnogo soobsjheniya itogovogo kommita i dolgovechno dobavlyayetsya v khvost Zhurnala. Ona vkhodit v sleduyusjhij snimok ili otdeljnoye yavno prinyatoye khranilisjhe svideteljstv. Tekusjheye derevo ne soderzhit sobstvennogo OID, sobstvennogo commit OID ili khyesh kvitancii o sebe: inache voznikayet cikl. Otsutstviye kvitancii posle avarii oznachayet nezavershyonnoye podtverzhdeniye, a ne pravo perepisatj prinyatyij kommit.

## Soobsjheniye i podgotovlennoye resheniye o kommite

Posle zakrepleniya dereva vyikhoda, do Git-kommita, vne etogo dereva dolgovechno ustanavlivayetsya zapisj `решение_о_коммите`. Yeyo zakryityiye polya: `версия`, `вид: решение_о_коммите`, UUID zadachi i raunda, `хэш_входа`, `хэш_результата`, `дерево_выхода`, `родитель_коммита`, `ветка`, `сообщение_коммита`, `длина_сообщения`, `хэш_сообщения`, `граница_команд` i `граница_полномочий`. Pole soobsjheniya soderzhit tochnyij UTF-8 tekst vsego soobsjheniya, vklyuchaya zagolovok, pustyiye stroki, doslovnyij blok komand i trailer; dlina otnositsya k yego UTF-8 bajtam, a khyesh ispoljzuyet SHA-256 etikh zhe bajtov. Normalizaciya strok pri sravnenii zapresjhena.

Soobsjheniye stroitsya po zakreplyonnomu eksportu komand dereva vkhoda. Versiya shablona otdelyayet sluzhebnyij tekst ot doslovnogo uporyadochennogo bloka komand; proveryayusjhij izvlekayet etot blok i pobajtovo sravnivayet s polnyim vklyuchyonnyim perechnem eksportirovannyikh poljzovateljskikh komand, sokhranyaya povtornyiye soobsjheniya. Proverka podstrok vmesto sravneniya strukturyi, chisla, poryadka i bajtov nedostatochna. Pozdnyaya komanda v zhivom `запрос.md` ne vklyuchayetsya v soobsjheniye tekusjhego raunda i ne propuskayetsya v sleduyusjhem.

Do dopuska proveryayetsya sootvetstviye podgotovlennogo soobsjheniya granice komand i dejstvuyusjhim pravilam, posle fiksacii — tochnoye sovpadeniye yego dlinyi, SHA-256 i bajtov s soobsjheniyem fakticheskogo commit-obyyekta. Sovpadeniye toljko tree i parent nedostatochno. Versiya proceduryi obyazana yavno uchityivatj ochistku soobsjheniya i hooks; ikh neozhidannoye izmeneniye soobsjheniya zapresjhayet prinyatiye i vyipusk kvitancii. Takoj obnaruzhennyij iskhod sokhranyayetsya kak narusheniye s fakticheskim obyyektom, bez avtomaticheskogo perepisyivaniya istorii. Kvitanciya svyazyivayet tochnyij khyesh podgotovlennogo resheniya s rezuljtatom etoj sverki.

## Perekhodyi i sokhraneniye khvosta

1. `подготовлен`: zakreplenyi vkhod i polnomochiya, obyyektyi proverenyi; zapisj vkhoda i yeyo konvert ustanovlenyi dolgovechno vne dereva vkhoda do zapuska.
2. `проверяется`: ispolnyayutsya predusmotrennyiye proverki v materializacii. Zhivoj Zhurnal dopolnyayetsya, derevo vkhoda ne menyayetsya.
3. `проверен`: vse obyazateljnyiye zapisi terminaljnyi, ikh fakticheskiye vkhodyi sovpadayut; pri otkaze perekhod k `отклонён`, pri otmene k `отменён`. Diagnostika svyazana s tochnyim otkazom.
4. `выход_закреплён`: sformirovanyi rezuljtat, sluzhebnyij nabor i derevo vyikhoda; nezavisimaya proverka dokazyivayet konechnuyu deljtu i soglasovannostj. Posle etogo novyij blob trebuyet novogo vkhoda, yesli izmeneniye ne byilo zaraneye chastjyu proveryayemogo zamyikaniya.
5. `допущен`: pod obsjhej dlya pisatelej granicej serializacii povtorno sverenyi polnomochiya, ozhidayemyiye HEAD/ref, indeks i dolgovechno podgotovlennoye resheniye s tochnyim soobsjheniyem. Chuzhoye izmeneniye lyubogo iz nikh dayot `устарел`, ne zatirayetsya i ne prikryivayetsya smenoj vetki.
6. `зафиксирован`: obyichnyij lokaljnyij kommit soderzhit tochnoye derevo vyikhoda, ozhidayemogo roditelya i zakreplyonnyiye bajtyi soobsjheniya; fakticheskij obyyekt proveren. Zatem ustanavlivayetsya kvitanciya i nachinayetsya sleduyusjhij poleznyij etap.
7. `не_установлен`: posle avarii nedostatochno svideteljstv dlya odnogo iz perekhodov. Vosstanovleniye chitayet neizmenyayemyiye zapisi i Git-obyyektyi; uspeshnyij iskhod ne ugadyivayetsya.

Do postanovki rezuljtata v indeks sokhranyayetsya tochnoye nablyudeniye tekusjhego khvosta: puti, blob/bajtovyiye khyeshi i rezhimyi, vklyuchaya novyiye i udalyonnyiye fajlyi. Dlya kommita indeks poluchayet toljko prinyatyiye blob OID i rezhimyi. Komanda, dobavlyayusjhaya celikom boleye svezhij fajl Zhurnala, nedopustima. Rabochiye bajtyi ne zamenyayutsya prinyatoj versiyej; yesli nuzhen soglasovannyij vid otnositeljno novogo HEAD, ispoljzuyetsya proveryayemoye tryokhstoronneye sovmesjheniye s sokhranyonnoj kopiyej khvosta. Konflikt pokazyivayetsya yavno, a obe versii ostayutsya vosstanovimyimi.

Lock yavlyayetsya chastjyu budusjhego protokola vsekh uchastvuyusjhikh pisatelej. Otdeljnyiye proverki HEAD i posleduyusjhij obyichnyij `git commit` sami po sebe ne obrazuyut atomarnuyu uslovnuyu zamenu ref. Obkhodyasjhij obsjhij protokol pisatelj dolzhen privoditj k obnaruzheniyu nesovpadeniya i ostanovke; obesjhatj zasjhitu ot lyubogo vneshnego processa neljzya.

## Dolgovechnostj i sovmestimostj

Vkhod, podgotovlennoye resheniye o kommite i nablyudayemyij rezuljtat perekhoda sokhranyayutsya s vremennyim fajlom, sinkhronizaciyej soderzhimogo, atomarnoj ustanovkoj i sinkhronizaciyej kataloga v opredelyonnom poryadke. Toljko posle podtverzhdyonnoj dolgovechnosti predyidusjhego shaga razreshayetsya sleduyusjhij vneshnij effekt. Obryiv khvosta zhurnala sobyitij obnaruzhivayetsya po dline i khyeshu; prigoden toljko poslednij celyij podtverzhdyonnyij prefiks.

Posle avarii mezhdu kommitom i kvitanciyej vosstanovleniye sveryayet zaraneye zakreplyonnyiye roditelya, derevo, identichnostj raunda, tochnyiye bajtyi i khyesh soobsjheniya iz podgotovlennogo resheniya i fakticheskij kommit. Yedinstvennoye dokazannoye sovpadeniye pozvolyayet dopisatj kvitanciyu bez novogo kommita; otsutstviye ili neodnoznachnostj ostavlyayet otkaz. Udaleniye sledov ne yavlyayetsya vosstanovleniyem.

Snimki report-v3, syiryiye zapisi run-v3/run-v4 i ikh prezhniye zakryitiya ostayutsya neizmennyimi. Novyiye polya ne dopisyivayutsya v istoricheskiye JSON. Novyij protokol potrebuyet otdeljnogo versionirovannogo perekhoda i obnovleniya pravil, inventarya, skhem i validatorov do pervogo realjnogo zapuska.

Prinyatoye raneye ogranicheniye run-v4 sokhranyayetsya: uzhe zaregistrirovannaya polnaya popyitka na tom zhe soderzhimom ne povtoryayetsya cherez HEAD, staging ili vozvrat B→C→B. Identifikator novogo raunda sam po sebe ne dayot prava povtoritj yeyo. Do realizacii nuzhno opredelitj sovmestimyij otpechatok snimka i perekhod staroj istorii; do etogo tekusjhij pisatelj ostayotsya yedinstvennyim dejstvuyusjhim mekhanizmom.

## Budusjhaya TDD-proverka i profilj

Snachala kazhdyij scenarij dolzhen vosproizvodimo otvergatj prezhdevremennyij dopusk, poteryu dannyikh ili lozhnoye svideteljstvo; zatem minimaljnaya realizaciya perevodit ozhidayemoye povedeniye v GREEN. Eto plan proverok, perechislennyiye scenarii sejchas ne ispolnyalisj.

- Izmeneniye zhivogo indeksa i fajla posle zakrepleniya vkhoda ne menyayet materializaciyu; nevernyij tip Git-obyyekta, nedostayusjhij blob ili gitlink, filjtr s drugimi bajtami i podmena instrumenta zakryivayut zapusk.
- Pozdnij otvet v tom zhe fajle, povtor odinakovogo teksta v dvukh soobsjheniyakh i nezakonchennaya stroka JSONL sokhranyayutsya bez propuskov i dublej. Posle kommita vse pozdniye bajtyi vosstanavlivayutsya; konflikt ne teryayet ni odnu storonu.
- Otmena do starta, vo vremya testa i mezhdu dopuskom i izmeneniyem ref imeyet zadannyij iskhod. Barjyeryi testa vosproizvodyat obe storonyi granicyi dostavki, bez predpolozheniya o poryadke po zaderzhkam. Poteryannyij kanal ne razreshayet kommit.
- Chuzhoye izmeneniye HEAD, ref ili indeksa, novyij nerazreshyonnyij putj, izmeneniye rezhima i podmena razreshyonnogo rezuljtata otvergayutsya do fiksacii. Proveryayetsya tochnoye tree/parent fakticheskogo kommita.
- RED dlya vkhoda: zapisj `вход` ili yeyo konvert pomesjhenyi v derevo, OID kotorogo oni soderzhat, libo vkhodnoj manifest ssyilayetsya na ikh budusjhij khyesh. Dopusk obyazan otkazatj. GREEN: snachala fiksiruyetsya nezavisimoye derevo, zapisj i konvert sokhranyayutsya vne yego, pozdneye ikh tochnyiye bajtyi dobavlyayutsya toljko razreshyonnoj deljtoj; prezhnij vkhodnoj OID ne menyayetsya.
- RED dlya rezuljtata: zapisj soderzhit OID ili khyesh proyekcii/indeksa, kotoryij pryamo libo cherez cepochku proizvodnyikh soderzhit tekst ili khyesh etoj zapisi. Variant, isklyuchayusjhij toljko sobstvennyij blob, takzhe otvergayetsya. GREEN: vesj konechnyij tranzitivno zavisimyij nabor vklyuchyon v sluzhebnoye zamyikaniye, rezuljtat ne soderzhit obratnyikh zavisimostej, fakticheskiye OID nabora nakhodyatsya v posleduyusjhej kvitancii. Dopolniteljnyij zavisimyij artefakt za predelami politiki i cikl mezhdu generatorami snova dayut otkaz.
- RED dlya soobsjheniya: posle zakrepleniya granicyi v tot zhe zhivoj `запрос.md` dobavlena komanda, i postroitelj vzyal yeyo v soobsjheniye starogo raunda; takzhe otvergayutsya propusk, lishnyaya komanda, perestanovka i poterya povtornogo teksta. GREEN: soobsjheniye ispoljzuyet rovno eksport vkhodnogo snimka, a pozdnyaya komanda ostayotsya khvostom sleduyusjhego. Podmena bajtov soobsjheniya fakticheskogo commit-obyyekta pri tekh zhe tree i parent ne poluchayet kvitanciyu.
- Sobstvennaya ssyilka na yesjhyo ne opredelyonnyij tree/commit, neizvestnaya skhema, povtor klyucha, perepisannaya kvitanciya, khyesh nepraviljnyikh bajtov i soglasovannyiye toljko po recency fajlyi otvergayutsya.
- Avariya na kazhdoj granice zapisi, fsync, ustanovki, kommita i kvitancii vosstanavlivayet toljko dokazannyij perekhod. Otdeljno proveryayutsya nezavershyonnyij process, neopredelyonnaya prichina i nepolnyij khvost sobyitij.
- Prezhniye istoricheskiye fiksturyi vosproizvodyatsya pobajtovo. Povtor polnoj popyitki cherez novyij raund, inoj HEAD/staging i B→C→B otvergayetsya do zapuska processa.
- Metki profilya okhvatyivayut chteniye JSONL, fiksaciyu granicyi, materializaciyu, nezavisimyiye vyichisleniya, postroyeniye i proverku deljtyi, sinkhronizaciyu, postanovku blob i vosstanovleniye khvosta. Malyij, realjnyij i uvelichennyij vkhodyi sravnivayutsya po tochnyim bajtam; izmeryayutsya vremya, obyyom i povtornoye ispoljzovaniye. Optimizaciya prinimayetsya toljko posle sokhraneniya etikh invariantov.

Blizhajshaya realizaciya nachinayetsya s skhemyi vkhoda i chistogo chteniya Git-obyyektov na vremennyikh fiksturakh. Zatem otdeljno vvodyatsya eksport komand s otmenoj, materializaciya, konechnaya deljta, dolgovechnoye zamyikaniye i tochnyij kommit s sokhraneniyem khvosta. Ni odin promezhutochnyij etap ne obyyavlyayet vesj FUM-STEP-0155 vyipolnennyim.

## Istochniki

- [Iskhodnyiye komandyi vyidelennoj zadachi](../../zapros.md).
- [Otvetyi i granica etoj detalizacii](../../otchyot.md).
- [Plan konvejyera odnoj postoyannoj zadachi](../../../2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/materialyi/planyi/plan-konvejyera-odnoj-zadachi.md).
- [Kartochka FUM-STEP-0155](../../../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0155-realizovatj-priyomku-snimkov-indeksa-v-odnoj-zadache.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 20:00:22 MSK -->
<!-- content-sha256: sha256:55f6be83f26aa6f0155b74c607a846b1599b52c18c098939806aa40a08c7b83d -->
<!-- FUM-MD-RECENCY:END -->
