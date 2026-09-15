# Granica dvukh normativnyikh profilej

Iskhodnyij M — `224dc6cf289e4cc88080b85ad7c99240284a7ced`. Celevoj L — `a728283474931eda71cd581ca5429121124ba3f6`. [Fikstura](../../../Instrumentyi/fum-dekompoziciya-pravil-agentov/tests/fiksturyi/profili-prodolzheniya.json) sokhranyayet polnyiye normativnyiye tekstyi iz Git i SHA-256 kornevyikh pravil kazhdogo istochnika.

## Nablyudayemyij otkaz

Koordinator soobsjhil, chto full `f81e52ff-c573-4b5a-9f59-240fba1dea25` ostanovilsya na shage dekompozicii s soobsjheniyem «granica prodolzheniya zadachi ne soglasovana». [Iskhodnaya mashinnaya zapisj](iskhodnyij-otkaz-C2.json) pobajtno izvlechena iz sokhranyonnogo neprinyatogo C2 `de9f81fec9e2bad840c6e37b049f5734f544d07b`, putj v Git: `Журнал/2026-09-11_21-58-48_MSK_принять-слияние-после-исправления-путей/материалы/запуски-проверок/5_f81e52ff-c573-4b5a-9f59-240fba1dea25.json`. Ona podtverzhdayet kod 1 i 433,800176334 s; teksta stderr v yeyo skheme net, tochnyij tekst oshibki podtverzhdyon koordinaciyej i adresnyim RED. Eto chuzhoj iskhodnyij zapusk, a ne zapisj tekusjhej granicyi proverok.

Staryij validator trebuyet rovno dva polya prodolzheniya. L/0177 dobavil dva obyazateljnyikh polya, i yego gotovyij validator trebuyet toljko novyij profilj. Pryamoye kopirovaniye lyuboj odnoj storonyi ne obespechivayet soglasovannoj sovmestimosti M/L. Sboj zaregistrirovan kak [FUM-SBOJ-0090](../../../Sboi/FUM-SBOJ-0090-nesovmestimostj-normativnyikh-profilej-prodolzheniya.md).

## Prinimayusjhij kontrakt

Iz polnogo kornevogo teksta izvlekayutsya tela dvukh pravil `FUM-ПРАВИЛО-000062` i `FUM-ПРАВИЛО-НОВОЕ-000017`, ot polnogo aktivnogo yakorya do sleduyusjhego polnogo yakorya s udaleniyem toljko zavershayusjhikh LF. Ikh SHA-256 obrazuyut odnu iz dvukh zaraneye izvestnyikh par. Zapisi inventarya obyazanyi ostavatjsya dejstvuyusjhimi P0 s tochnyimi kornevyimi naznacheniyami. Neizvestnaya ili smeshannaya para zakryivayet dopusk.

Staryij profilj trebuyet rovno `маркер` i `сценарий`. JSONL-profilj trebuyet dopolniteljno tochnyiye `обязательные_параметры` i `остаток_сообщений`: parametryi v kanonicheskom poryadke, komanda «ostatok», strogoye logicheskoye true i tochnyiye scenarii. Kazhdyij putj otdeljno proveryayetsya na susjhestvovaniye, registr, vyikhod i simvolicheskiye ssyilki. Nalichiye dejstvuyusjhikh norm samo vklyuchayet proverku: udaleniye deklaracii i markera ne otklyuchayet yeyo.

Povtornyiye JSON-klyuchi otklonyayutsya do poteri znacheniya parserom. V izvestnyikh kornevyikh karkasakh net ograd, vneshnikh HTML-oblastej i mnogostrochnyikh kommentariyev; neizvestnyij takoj karkas zakryivayet dopusk. Polnyiye normativnyiye tela ne mogut dejstvovatj vnutri etikh oblastej. Eto konservativnyij dopusk izvestnyikh karkasov, ne universaljnyij Markdown-parser.

## Proverki i profilj

Pyatj grupp strogikh regressij vzyatyi iz `6b1860591deb1d669f5f5ae1bd03336170fb8fce`; fikstura dopolnena dejstviteljnyimi tekstami pravil. Dopolniteljnyiye otricateljnyiye scenarii proveryayut staryij profilj, smeshannyiye i neizvestnyiye redakcii, aktivnostj norm, povtornyiye JSON-klyuchi, null, tochnyij bool, puti i udaleniye vsekh libo chasti novyikh polej. RED, GREEN37, zamechaniye nezavisimogo auditora, RED vneshnej HTML-oblasti i GREEN38 sokhranenyi v [otchyote](../otchyot.md).

Itogovyij kod chitayet realjnyiye derevjya M i L: 221 i 222 pravila, po 11 tem. [Profilj](profilj-dopuska.json) soderzhit tochnyij khyesh validatora, pravila i inventarj vkhodov, identifikatoryi pryamyikh zapuskov. Nakoplennoye vremya funkcii vyibora profilya: 0,000851792 s dlya M i 0,000708792 s dlya L; polnaya struktura sootvetstvenno 0,060778958 i 0,062140292 s. Eto po odnomu izmereniyu pod cProfile; uluchsheniye proizvoditeljnosti ne zayavlyayetsya, dopolniteljnaya optimizaciya ne obosnovana.

## Ogranicheniye istoricheskogo otkata

Udaleniye JSONL-polej pri sokhranyonnyikh normakh L zapresjheno. Odnovremennaya polnaya zamena dvukh tekstov pravil i deklaracii tochnyim staryim profilem yavlyayetsya podderzhannyim M. Istoricheskuyu dopustimostj takogo otkata dolzhen proveryatj vneshnij istochnik pravil pri sliyanii. Neizmenyayemyiye tekstyi profilya ne podmenyayut vneshniye polnomochiya i obsjhuyu priyomku.

## Dopolniteljnaya predposyilka poryadka voprosov

Do full koordinator poruchil perenesti prinyatuyu v L perestanovku proverki voprosov pered proyekciyej. Tochnyij diff M→L soderzhit yedinstvennyij perenos odnogo production-bloka i tri strogikh sravneniya poryadka v dvukh testakh. Perenesenyi rovno eti bajtyi production i testov; opisaniye poryadka vzyato iz togo zhe L. Chislo proverok, spisok dopustimyikh naborov i strogiye sravneniya sokhranenyi. RED dvukh testov dal dva otkaza na prezhnem poryadke M; GREEN s cProfile proshyol dva testa. [Profilj poryadka](profilj-poryadka-voprosov.json) sokhranyayet khyeshi i granicyi. Eto ne novyij zapusk C2: koordinator otdeljno proverit novyij kandidat prinimayusjhimi testami M1 do proyekcii.

## Nezavisimyiye zamechaniya i okonchateljnaya redakciya

Koordinator peredal zamechaniye o nakopiteljnom udalenii polej v odnom teste. Ispravlennaya fikstura nachinayet kazhdyij iz tryokh variantov s iskhodnogo inventarya; chislo testov ostalosj 38, okonchateljnyij GREEN zanyal 5,779 s. Ekvivalentnoye shestnadcaterichnoye oboznacheniye tiljdyi v regex ustranyayet konflikt s raspoznavatelem domashnikh sokrasjhenij bez isklyucheniya puti ili oslableniya skanera. Predyidusjhiye pokazateli otnosyatsya k redakcii posle HTML-revjyu; okonchateljnyij khyesh i novyij profilj yavno vyidelenyi v [izmereniyakh](profilj-dopuska.json). Polnoye skanirovaniye s pervyim limitom 20 s zavershilosj tajm-autom124, a ne dokazannyim RED soderzhimogo; povtor nuzhen dlya fakticheskogo dopuska itogovogo snimka.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:16:44 MSK -->
<!-- content-sha256: sha256:baaed113a6ddc688103034f14ffbba96a303b39c4f286bf5fb357da42ef424f6 -->
<!-- FUM-MD-RECENCY:END -->
