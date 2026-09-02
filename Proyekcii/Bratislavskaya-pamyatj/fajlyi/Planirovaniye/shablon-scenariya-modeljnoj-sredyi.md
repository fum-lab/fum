# Shablon scenariya modeljnoj sredyi

Shablon zadayot chelovekochitayemyij kontejner dlya planirovaniya v [modeljnoj srede](../Glossarij/modeljnaya-sreda.md). On pomogayet sravnivatj aktualjnoye opisaniye, rekonstrukciyu proshlogo i vozmozhnoye budusjheye, ne prevrasjhaya vyivod, gipotezu, prognoz ili zhelayemoye sostoyaniye v nablyudayemyij fakt.

Kontejner primenyayetsya k planovyim materialam tekusjhego [dokumentacionnogo prototipa FUM](../Glossarij/dokumentacionnyij-prototip-FUM.md). On ne yavlyayetsya ispolnyayemoj skhemoj, simulyatorom ili razresheniyem na vneshneye dejstviye; ne reshayet, dolzhnyi li tri vremennyikh rezhima byitj rezhimami odnoj sredyi ili raznyimi tipami sred; ne dayot polnogo dostupa k vnutrennemu sostoyaniyu modeliruyemogo uzla. Eta razvilka ostayotsya v [otkryitom voprose o statuse vnutrennikh FUM i modeljnyikh sred](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md).

## Osnovnoye pravilo

Polya vremennogo rezhima, statusa, uverennosti, istochnikov i dostupa zadayutsya dlya kazhdogo znachimogo utverzhdeniya, a ne toljko odin raz dlya vsego scenariya. Obsjhiye znacheniya pasporta yavlyayutsya znacheniyami po umolchaniyu, no ne mogut skryivatj razlichiya mezhdu strokami znaniya.

Scenarij ispoljzuyet rovno tri vremennyikh rezhima:

- `актуальное описание` — predstavleniye tekusjhego sostoyaniya po dostupnyim nablyudeniyam i istochnikam;
- `реконструкция прошлого` — vozmozhnoye obyyasneniye togo, kak vozniklo tekusjheye sostoyaniye;
- `планирование будущего` — vozmozhnyiye celi, dejstviya, razvilki, riski i posledstviya.

Znacheniye `смешанный` ne ispoljzuyetsya. Yesli odno rassuzhdeniye svyazyivayet proshloye, nastoyasjheye i budusjheye, ono razbivayetsya na otdeljnyiye utverzhdeniya s yavnyimi svyazyami mezhdu nimi.

## Statusyi utverzhdenij

Minimaljnyij lokaljnyij slovarj razlichayet:

- `наблюдаемый факт` — neposredstvenno nablyudyonnoye sostoyaniye s ukazannyim sposobom i vremenem nablyudeniya;
- `прямое сообщение источника` — soderzhaniye, pripisyivayemoye konkretnomu istochniku bez povyisheniya do nezavisimogo fakta;
- `вывод` — proizvodnoye utverzhdeniye s yavnyimi posyilkami;
- `гипотеза` — proveryayemoye predpolozheniye, kotoroye poka ne poluchilo dostatochnogo podtverzhdeniya;
- `прогноз` — utverzhdeniye o vozmozhnom budusjhem posledstvii;
- `сценарное допущение` — usloviye, prinyatoye dlya sravneniya variantov, no ne zayavlennoye kak istinnoye;
- `желаемое состояние` — celj ili kriterij predpochtiteljnogo iskhoda;
- `плановое действие` — kandidat na dejstviye vnutri scenariya, ne yavlyayusjhijsya razresheniyem na ispolneniye;
- `неизвестность` — otsutstviye dostatochnyikh dannyikh, konflikt istochnikov ili neproyasnyonnaya razvilka.

`Реконструкция прошлого` ostayotsya vremennyim rezhimom, a ne statusom istinnosti: otdeljnoye utverzhdeniye rekonstrukcii poluchayet status `вывод` ili `гипотеза`. Analogichno budusjhij rezhim ne smeshivayet prognoz, zhelayemoye sostoyaniye i planovoye dejstviye.

Etot slovarj yavlyayetsya rabochim kontraktom shablona, a ne okonchateljnoj ontologiyej korobochnoj FUM. Issledovateljskiye statusyi vrode siljnogo predpolozheniya, vosproizvedyonnogo rezuljtata i otkryitiya primenyayutsya po svoim otdeljnyim kriteriyam i ne vyivodyatsya iz uverennogo tona scenariya.

## Uverennostj, istochniki i dostup

Uverennostj zapisyivayetsya kak `не оценена`, `низкая`, `средняя` ili `высокая` i vsegda soprovozhdayetsya kratkim osnovaniyem. Chislovaya veroyatnostj ne trebuyetsya: v pamyati FUM poka net obsjhej kalibrovki, kotoraya delala byi takoye chislo sopostavimyim mezhdu scenariyami. Dlya zhelayemogo sostoyaniya dopustimo `неприменимо`, yesli otdeljno ocenenyi yego dostizhimostj i posledstviya.

Kazhdoye utverzhdeniye soderzhit ssyilku na fajl pamyati, datirovannoye nablyudeniye, pryamoye soobsjheniye libo ssyilki na utverzhdeniya-posyilki. Otsutstviye istochnika ili sposoba nablyudeniya zapresjhayet status `наблюдаемый факт`. Novyiye dannyiye ne perepisyivayut proiskhozhdeniye prezhnej zapisi: oni sozdayut utochneniye, oproverzheniye ili novoye pokoleniye scenariya.

[Urovenj dostupa](../Glossarij/urovenj-dostupa.md) vyibirayetsya iz znachenij `публичный`, `ограниченный`, `приватный` i `закрытый`. Ryadom perechislyayutsya razreshyonnyiye chteniye, ispoljzovaniye, izmeneniye, publikaciya i peredacha. Proizvodnoye utverzhdeniye nasleduyet naiboleye strogoye ogranicheniye svoikh istochnikov, poka otdeljnoye osnovaniye ne dokazhet vozmozhnostj oslableniya. Pravo chitatj ili modelirovatj svedeniya ne oznachayet prava publikovatj ikh, dejstvovatj ot imeni istochnika ili raskryivatj predpolagayemoye vnutrenneye sostoyaniye drugogo uzla.

## Kopiruyemyij shablon

### Pasport scenariya

- **Identifikator i versiya:** `<устойчивый идентификатор>; <версия>`
- **Nazvaniye:** `<краткое название>`
- **Celj modelirovaniya:** `<какое решение, сравнение или неизвестность исследуется>`
- **Profilj nablyudatelya:** `<кто строит представление и какие сигналы ему доступны>`
- **Sreda, uchastniki i obyyektyi:** `<что моделируется и на каком уровне описания>`
- **Data sreza i vremennoj okhvat:** `<граница доступных данных; рассматриваемый интервал>`
- **Vkhodit v modelj:** `<явный перечень>`
- **Ne vkhodit v modelj:** `<исключения и неизвестные области>`
- **Urovenj i ogranicheniya dostupa po umolchaniyu:** `<уровень; разрешённые операции>`
- **Model-only-dopusk i byudzhet:** `<идентичность провайдера; локальный или удалённый режим; разрешённое раскрытие данных; конечные лимиты шагов, вариантов, вызовов, токенов, времени, вычислений, денег и обязательный резерв на проверку и передачу>`
- **Perekhod k realjnomu dejstviyu:** `не разрешён` libo `<ссылка на отдельное основание, проверку доступа и риска>`
- **Ozhidayusjhij podtverzhdeniya perekhod:** `<точный объект, версия, ожидаемый эффект и условие допуска>` libo `нет`

### Reyestr utverzhdenij

Dlya kazhdogo znachimogo utverzhdeniya povtoryayetsya blok:

#### `<ID утверждения>`

- **Utverzhdeniye:** `<самостоятельная проверяемая формулировка>`
- **Vremennoj rezhim:** `актуальное описание` | `реконструкция прошлого` | `планирование будущего`
- **Status:** `<одно значение локального словаря>`
- **Uverennostj:** `<уровень и основание>`
- **Istochniki ili posyilki:** `<ссылки, наблюдение или ID других утверждений>`
- **Urovenj i ogranicheniya dostupa:** `<уровень; допустимые операции>`
- **Proverka ili usloviye oproverzheniya:** `<наблюдаемый критерий>`
- **Svyazannyij vopros:** `<ссылка на Вопросы/... либо «нет»>`

### Razvilki

Dlya kazhdoj razvilki fiksiruyutsya obsjhij tochnyij predok, dve ili boleye soderzhateljno razlichimyiye vetvi, otlichiye kazhdoj vetvi, yeyo modeljnoye dejstviye, otdeljnyij byudzhet, ozhidayemoye posledstviye, risk, sposob proverki, rezuljtat i status otbora. Yesli resursa khvatayet toljko na odnu vetvj, scenarij nazyivayet pravilo yeyo vyibora i sokhranyayet ostaljnyiye kak neproverennyiye, ne obyyavlyaya neodnoznachnostj ustranyonnoj sravneniyem.

Neproyasnyonnoye trebovaniye ne zamenyayetsya svobodnoj zametkoj vnutri scenariya: ono poluchayet ssyilku na susjhestvuyusjhij [otkryityij vopros](../Glossarij/otkryityij-vopros.md) libo oformlyayetsya kak novyij vopros po pravilam pamyati FUM. Ozhidaniye podtverzhdeniya vneshnego perekhoda ne yavlyayetsya samo po sebe usloviyem ostanovki modeljnoj rabotyi; scenarij prodolzhayet bezopasnyiye produktivnyiye vetvi do ischerpaniya obyyavlennogo byudzheta ili poleznyikh proveryayemyikh prodolzhenij.

### Ozhidayemyij rezuljtat i proverka

- **Ozhidayemyij modeljnyij rezuljtat:** `<сравнение вариантов, перечень рисков, выявленная нехватка данных или кандидат на следующий шаг>`
- **Kriterii gotovnosti:** `<что должно стать наблюдаемым в артефакте>`
- **Sposob proverki:** `<локальная проверка содержания, данных или связей>`
- **Kontroljnaya tochka ozhidaniya:** `<какое модельное состояние сохраняется при отсутствии ответа>`
- **Usloviye ostanovki modeljnoj rabotyi:** `<когда исчерпаны бюджет или безопасные продуктивные продолжения>`

### Granica realjnogo dejstviya

- **Dopustimyiye izmeneniya vnutri modeli:** `<что можно менять без внешнего эффекта>`
- **Predlagayemyiye vneshniye dejstviya:** `<перечень либо «нет»>`
- **Neobkhodimyiye osnovaniya:** `<доступ, оценка риска, подтверждение и наблюдаемая проверка>`
- **Fakticheskij status i svideteljstvo:** otdeljno ukazatj `selected_in_model` ili `recommended` iz modeljnogo kontura, `transition_user_confirmed` iz dejstviteljnogo poljzovateljskogo sobyitiya dlya tochnogo perekhoda i versii, `authorized` iz nezavisimoj politiki polnomochij, `preflight_passed` iz proverki tekusjhego sostoyaniya, `executed` iz sobyitiya ispolniteljnogo adaptera i `observed` iz svideteljstva rezuljtata.
- **Politika khraneniya i priyomki:** `<что разрешено записывать как append-only-трассу, кандидат и контрольную точку; какой отдельный протокол повышает результат до принятого канонического состояния>`

## Pravila zapolneniya

Scenarij schitayetsya zapolnennyim, kogda:

- kazhdyij znachimyij tezis imeyet vremennoj rezhim, status, uverennostj, istochnik i dostup;
- aktualjnyij fakt, rekonstrukciya i plan ne obyyedinenyi v odnu stroku;
- neizvestnostj i konflikt istochnikov sokhranenyi yavno;
- plan s neproyasnyonnoj razvilkoj ssyilayetsya na fajl v `Вопросы/`;
- vetvi imeyut obsjhij tochnyij predok, yavnyiye razlichiya, konechnyiye byudzhetyi, otdeljnyiye proverki i proiskhozhdeniye rezuljtata;
- ozhidayemyij rezuljtat opisyivayet rezuljtat modelirovaniya, a ne obesjhannyij vneshnij iskhod;
- ozhidaniye podtverzhdeniya zakryivayet toljko nazvannyij vneshnij perekhod, a ostanovka vsej modeljnoj rabotyi obosnovyivayetsya ischerpaniyem byudzheta ili otsutstviyem bezopasnogo produktivnogo prodolzheniya;
- perekhod k realjnomu, publikacionnomu, socialjnomu, servisnomu ili fizicheskomu dejstviyu ostayotsya zakryit do otdeljnogo osnovaniya.

## Proverochnyij primer

### Pasport scenariya

- **Identifikator i versiya:** `model-environment-inner-fum-form; 1`
- **Nazvaniye:** `Сравнить формы первого внутреннего FUM`
- **Celj modelirovaniya:** sravnitj dve formyi opisaniya vnutrennikh FUM, ne vyibiraya ispolnyayemuyu arkhitekturu.
- **Profilj nablyudatelya:** dokumentacionnyij prototip FUM; dostupnyi toljko publikacionnyiye materialyi tekusjhej pamyati.
- **Sreda, uchastniki i obyyektyi:** modeljnaya sreda, vnutrennij FUM i tri vremennyikh rezhima na urovne dokumentacionnogo opisaniya.
- **Data sreza i vremennoj okhvat:** tekusjhij snimok pamyati; proshloye trebovanij, aktualjnoye sostoyaniye dokumentacii i blizhajsheye planovoye prodolzheniye.
- **Vkhodit v modelj:** uzhe zapisannyiye trebovaniya, otkryityij vopros i sravneniye dvukh dokumentaljnyikh variantov.
- **Ne vkhodit v modelj:** runtime, nezavisimoye ispolneniye vnutrennikh FUM, vneshniye servisyi, privatnyiye sostoyaniya i fizicheskiye dejstviya.
- **Urovenj i ogranicheniya dostupa po umolchaniyu:** `публичный`; chteniye, ispoljzovaniye, izmeneniye i publikaciya razreshenyi v predelakh CC0-repozitoriya.
- **Model-only-dopusk i byudzhet:** toljko lokaljnaya dokumentaljnaya obrabotka; dve vetvi, po odnoj proverke polej kazhdoj vetvi i odin obsjhij sintez; udalyonnyij provajder, raskryitiye dannyikh, vneshniye vyizovyi i raskhodyi ne razreshenyi.
- **Perekhod k realjnomu dejstviyu:** `не разрешён`.
- **Ozhidayusjhij podtverzhdeniya perekhod:** vyibor ispolnyayemoj runtime-arkhitekturyi posle otveta na otkryityij vopros; tochnaya realizaciya yesjhyo ne opredelena i ne avtorizovana.

#### `A-001`

- **Utverzhdeniye:** dokumentaciya FUM uzhe razlichayet aktualjnoye opisaniye, rekonstrukciyu proshlogo i planirovaniye budusjhego kak tri rodstvennyiye zadachi modeljnoj sredyi.
- **Vremennoj rezhim:** `актуальное описание`.
- **Status:** `наблюдаемый факт`.
- **Uverennostj:** `высокая`; formulirovka neposredstvenno prisutstvuyet v kanonicheskom dokumente.
- **Istochniki ili posyilki:** [sreda dlya vnutrennikh FUM](../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md), razdel «Vremennyiye rezhimyi».
- **Urovenj i ogranicheniya dostupa:** `публичный`; dopustimyi chteniye, ispoljzovaniye i publikacionnaya ssyilka.
- **Proverka ili usloviye oproverzheniya:** sveritj nalichiye tryokh otdeljnyikh punktov v istochnike.
- **Svyazannyij vopros:** [status vnutrennikh FUM i modeljnyikh sred](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md).

#### `P-001`

- **Utverzhdeniye:** nyineshnyaya neodnoznachnostj, veroyatno, voznikla potomu, chto tri rodstvennyiye zadachi byili obyyedinenyi obsjhim trebovaniyem do vyibora mezhdu odnoj sredoj s rezhimami i neskoljkimi tipami sred.
- **Vremennoj rezhim:** `реконструкция прошлого`.
- **Status:** `вывод`.
- **Uverennostj:** `средняя`; vyivod soglasuyetsya s formulirovkami dokumentov, no ne yavlyayetsya pryamoj istoricheskoj zapisjyu resheniya.
- **Istochniki ili posyilki:** `A-001`, [otkryityij vopros](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md), [napravleniye modeljnoj sredyi](napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md).
- **Urovenj i ogranicheniya dostupa:** `публичный`; dopustimyi chteniye, ispoljzovaniye i publikaciya s sokhraneniyem statusa vyivoda.
- **Proverka ili usloviye oproverzheniya:** najti pryamoj istochnik, kotoryij otdeljno fiksiruyet prichinu obyyedineniya ili razdeleniya rezhimov.
- **Svyazannyij vopros:** [status vnutrennikh FUM i modeljnyikh sred](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md).

#### `F-001`

- **Utverzhdeniye:** v blizhajshem dokumentaljnom sravnenii rassmatrivayutsya dva scenarnyikh dopusjheniya: odna sreda s tremya rezhimami i tri razlichimyikh tipa sred s obsjhim kontraktom utverzhdenij.
- **Vremennoj rezhim:** `планирование будущего`.
- **Status:** `сценарное допущение`.
- **Uverennostj:** `не оценена`; eto prostranstvo sravneniya, a ne prognoz istinnosti variantov.
- **Istochniki ili posyilki:** `A-001`, `P-001`.
- **Urovenj i ogranicheniya dostupa:** `публичный`; dopustimo toljko dokumentaljnoye modelirovaniye.
- **Proverka ili usloviye oproverzheniya:** oba varianta dolzhnyi sokhranyatj proiskhozhdeniye, uverennostj, vremennoj rezhim i dostup kazhdogo utverzhdeniya.
- **Svyazannyij vopros:** [status vnutrennikh FUM i modeljnyikh sred](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md).

### Razvilka primera

Obe vetvi nasleduyut sostoyaniye `A-001`, `P-001` i `F-001`. Pervaya vetvj modeliruyet yedinuyu sredu i proveryayet pravila pereklyucheniya rezhimov i zasjhitu ot smesheniya statusov; vtoraya modeliruyet raznyiye tipyi sred i proveryayet obsjhij kontrakt i pravila perenosa utverzhdenij. Poka otveta net, scenarij prorabatyivayet i sravnivayet obe dokumentaljnyiye vetvi v zadannom byudzhete, sokhranyayet vozmozhnuyu rekomendaciyu kak `selected_in_model` i toljko zatem sozdayot kontroljnuyu tochku ozhidaniya; runtime-arkhitektura ne schitayetsya podtverzhdyonnoj ili razreshyonnoj.

### Ozhidayemyij rezuljtat i proverka primera

Ozhidayemyij rezuljtat — tablica razlichij dvukh variantov, perechenj sokhranyayemyikh polej i spisok dannyikh, kotoryikh ne khvatayet dlya vyibora. Proverka podtverzhdayet, chto `A-001` ostayotsya aktualjnyim faktom, `P-001` — rekonstruktivnyim vyivodom, `F-001` — budusjhim scenarnyim dopusjheniyem, a razvilka vedyot k susjhestvuyusjhemu fajlu v `Вопросы/`.

Granica primera prokhodit do realizacii: on ne sozdayot vnutrennij FUM, ne zapuskayet simulyaciyu, ne poluchayet novyiye prava dostupa i ne razreshayet dejstviye vo vneshnem mire.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-23 10:22:00 MSK — Opisatj shablon scenariya modeljnoj sredyi](../Zhurnal/2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi/zapros.md)
- [napravleniye modeljnoj sredyi i planirovaniya](napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md)
- [sreda dlya vnutrennikh FUM](../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md)
- [vnutrenniye modeli drugikh uzlov](../Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md)

## Opornyiye materialyi

- [dorozhnaya karta FUM](dorozhnaya-karta.md)
- [urovenj dostupa](../Glossarij/urovenj-dostupa.md)
- [otkryityij vopros o statuse vnutrennikh FUM i modeljnyikh sred](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:913622c9872dec469f5bc5550a6ace8d3f045ad7710439d39b68fc992f801c31 -->
<!-- FUM-MD-RECENCY:END -->
