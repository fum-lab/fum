# Kompaktnyij rabochij kontekst zadachi

Sokhranyonnyij planovyij material zadachi «Planirovaniye FUMA» prinyat iz kommita `186b0360a31b97184773757634976257d0f86495`. Opisaniye dostupnosti 0177 i 0160 nizhe fiksiruyet sostoyaniye iskhodnoj vetki na baze `5c9806560fb9b52112ff8a7bc11888a1bb71f7aa`; eto istoricheskoye nablyudeniye, a ne inventarj nyineshnego checkout. Perenos sokhranyayet plan i yego proiskhozhdeniye. Pervoye otdeljnoye naznacheniye 0165 ogranicheno chitayusjhim sborsjhikom na sinteticheskikh vkhodakh; katalog vnimaniya i sluchai vspominaniya ostayutsya sokhranyonnoj planovoj oblastjyu i ne rasshiryayut ispolneniye README ili dvukh dejstvuyusjhikh detektorov vnimaniya.

Rabochij kontekst — vosproizvodimyij srez dolgovechnoj pamyati dlya sleduyusjhego resheniya agenta. On pokazyivayet celj, dejstvuyusjhiye ogranicheniya, nezavershyonnyiye obyazateljstva, prinyatyiye resheniya, zavisimosti i blizhajshiye dejstviya. Podrobnyiye svideteljstva ostayutsya v pervichnyikh istochnikakh i raskryivayutsya po tochnyim ssyilkam.

Etot dokument planiruyet realizaciyu shaga 0165 i zadayot osnovu budusjhikh avtomaticheskikh proverok. Sborsjhik, izmeritelj kachestva i avtomaticheskoye podklyucheniye poka ne realizovanyi. Novyikh fonovyikh zapuskov, perekhvatov i polnomochij na chteniye zdesj ne poyavlyayetsya.

## Rezuljtat pervoj realizacii

Pervaya postavka — lokaljnaya komanda, kotoraya toljko chitayet yavno vyibrannyiye istochniki odnoj zadachi i formiruyet versionirovannyij srez, kartu proiskhozhdeniya i otchyot o granicakh. Ona rabotayet na otkryityikh sinteticheskikh primerakh i na otdeljno razreshyonnom istochnike; interfejs prilozheniya i chuzhiye dialogi avtomaticheski ne obsleduyet.

Obyazateljnoye yadro instrukcij i polnyiye tematicheskiye fajlyi, trebuyemyiye dejstvuyusjhim marshrutom, zagruzhayutsya po svoim pravilam. Srez khranit ukazateli na nikh i rezuljtatyi sverki versij; on ne zamenyayet obyazateljnyij tekst sokrasjhyonnyim pereskazom.

## Vkhod i proiskhozhdeniye

Vkhod zadayotsya tochnyim identifikatorom zadachi, manifestom istochnikov i momentom ocenki. Dlya Git fiksiruyetsya polnyij commit i otnositeljnyij putj; dlya JSONL — zavershyonnaya bajtovaya granica, SHA prefiksa, nomera iskhodnyikh strok i otdeljnaya granica nezavershyonnogo khvosta. Dlya otveta API sokhranyayutsya identifikator nablyudeniya, vremya polucheniya i obyyavlennaya oblastj okhvata. Neizvestnaya versiya ili polnota ostayotsya neizvestnoj.

Kazhdaya vyibrannaya zapisj sokhranyayet:

- ustojchivyij identifikator i ssyilku na iskhodnyiye bajtyi;
- oblastj: zadacha, konkretnyij khod, rabocheye derevo, vetka ili operaciya;
- proiskhozhdeniye i sposob yego podtverzhdeniya do obyyedineniya chastej soobsjheniya;
- vremya samogo nablyudeniya i vremya polucheniya, yesli oni dostupnyi razdeljno;
- polnotu okhvata i ogranicheniya dostupnosti istochnika;
- versiyu primenyonnogo preobrazovaniya i svyazj s predshestvuyusjhej zapisjyu.

Chelovecheskaya komanda, delegirovannoye porucheniye, otvet agenta, sluzhebnyij hook i rezuljtat instrumenta ostayutsya raznyimi vidami dannyikh. Odna rolj user ne dokazyivayet chelovecheskogo proiskhozhdeniya; output ne dokazyivayet uspeshnogo ispolneniya. Zhelayemaya modelj i nablyudyonnaya modelj khoda — raznyiye polya.

## Soderzhaniye rabochego sreza

Vyikhod vklyuchayet identichnostj zadachi i sborki sreza, vyibrannyiye istochniki, celj, ogranicheniya, obyazateljstva, resheniya, zavisimosti, sostoyaniya rabot i blizhajshiye dostupnyiye dejstviya. Dlya kazhdogo utverzhdeniya perechislyayutsya svideteljstva i granicyi yego primenimosti. Vyivod, sdelannyij preobrazovaniyem, otdelyayetsya ot pryamoj zapisi istochnika.

Podrobnosti raskryivayutsya po identifikatoru svideteljstva, a ne po pribliziteljnomu pereskazu ili sovpadeniyu imeni fajla. Skryityiye rassuzhdeniya i instrukcii drugikh urovnej ne eksportiruyutsya kak chelovecheskij dialog. Chastnyiye pervichnyiye zapisi i lokaljnyiye adresa ne popadayut v publichnuyu svodku.

Pri ogranichenii razmera v pervuyu ocheredj sokhranyayutsya dejstvuyusjhiye ogranicheniya, otmenyi, otkryityiye obyazateljstva, blokirovki i ssyilki na neobkhodimyiye dokazateljstva. Yesli obyazateljnaya chastj ne pomesjhayetsya, rezuljtat yavno soobsjhayet o nepolnote i trebuyet umenjshitj vyibrannyij obyyom rabotyi libo rasshiritj razreshyonnyij vkhod; molchalivoye usecheniye zapresjheno.

## Plan vspominaniya po kommitam

Vspominaniye — vyichislyayemyij povod vernutjsya k razboru zadachi. Preimusjhestvenno algoritmicheski formiruyemoye JSON-sostoyaniye organov chuvstv khranit nablyudeniya istorii, schyot, signalyi i ikh proiskhozhdeniye. Soderzhateljnyij otvet trebuyet rassmotreniya celi i obyazateljstv; chislo kommitov ne izmeryayet kachestvo ili progress samo po sebe. «Vsyo li idyot khorosho» — primer voprosa dlya vnimaniya, a 10 — primer nastraivayemogo intervala.

Budusjhij lokaljnyij srez poluchayet yavno vyibrannyiye identifikatoryi zadachi i repozitoriya, polnyij ref vetki, podtverzhdyonnyij bazovyij commit, nablyudyonnyij HEAD, zavershyonnyij manifest dostupnyikh istochnikov i versiyu konfiguracii. Vyibor ne vyivoditsya iz tekusjhego kataloga, poslednego otkryitogo okna, nazvaniya zadachi ili odnogo Git trailer. Podtverzhdeniye bazyi khranit istochnik, dejstvuyusjheye porucheniye i oblastj; neizvestnyiye baza libo privyazka zadachi k vetke zapresjhayut vyidavatj opredelyonnyij schyot. Rabocheye derevo i vremya polucheniya — nablyudeniya, a ne identichnostj komandyi.

### Pervyij eksperimentaljnyij rezhim

Dlya pervogo sinteticheskogo eksperimenta vyibran rezhim «pervyij roditelj posle bazyi». Yego osnovaniye — proveritj aktivnostj yavno vyibrannoj linii vetki i integracionnyiye sobyitiya bez povtornogo schyota bokovoj istorii. Eto proyektnyij vyibor dannogo plana, ne doslovnoye trebovaniye poljzovatelya i ne vklyuchyonnaya rabochaya politika.

- Baza isklyuchayetsya, HEAD vklyuchayetsya. Schyot raven chislu raznyikh kommitov na nepreryivnom puti pervyikh roditelej ot HEAD do bazyi. Baza dolzhna lezhatj imenno na etom puti; obsjhej dostizhimosti cherez drugogo roditelya nedostatochno.
- Merge-kommit schitayetsya odin raz; yego bokovyiye predki otdeljno ne pribavlyayutsya. Pri fast-forward schitayutsya novyiye kommityi nablyudyonnoj linii pervyikh roditelej. Avtor i trailer ne filjtruyut schyot: on pokazyivayet aktivnostj vyibrannoj vetki v oblasti zadachi, a ne lichnuyu produktivnostj ispolnitelya.
- Interval — yavno zadannoye polozhiteljnoye celoye chislo kommitov. Nolj, otricateljnoye, drobnoye, logicheskoye znacheniye i otsutstviye znacheniya neprigodnyi. Rabocheye znacheniye po umolchaniyu ne naznacheno.
- Pri schyote 0 signala net. Dlya kazhdogo dostignutogo polozhiteljnogo kratnogo intervala voznikayet odin ustojchivo identificiruyemyij povod; pri 9, 10, 11 i intervale 10 eto sootvetstvenno 0, 1, 1 povod. Pri skachke k 25 vidnyi granicyi 10 i 20. Kompaktnoye predstavleniye mozhet gruppirovatj ikh, sokhranyaya obe identichnosti i sostoyaniye rassmotreniya kazhdoj.
- Povtor chteniya tekh zhe vkhodov vosproizvodit te zhe povodyi. Novoye vremya polucheniya ne delayet dublikat novyim signalom. Schyot vosstanavlivayetsya po istorii, a rassmotreniye — po otdeljnyim svideteljstvam; odno ne zamenyayet drugoye.

Izmeneniye intervala v etom eksperimente nachinayet novuyu epokhu ot yavno podtverzhdyonnogo commit primeneniya novoj konfiguracii. V novoj epokhe baza isklyuchayetsya, schyot nachinayetsya s nulya; raneye voznikshiye nerassmotrennyiye signalyi sokhranyayutsya s prezhnej konfiguraciyej. Pozdno dostavlennoye izmeneniye ne ugadyivayet bazu po vremeni polucheniya: prezhnij zavisimyij srez stanovitsya istoricheskim do sverki commit primeneniya i granicyi dostavki. Vozvrat prezhnego chislennogo znacheniya s novoj epokhoj ne vozvrasjhayet staryiye identichnosti.

Smena polnogo ref, repozitoriya ili zadachi trebuyet novogo yavnogo vyibora. Ischeznoveniye bazyi, perepisannaya liniya, otkat HEAD otnositeljno poslednego podtverzhdyonnogo nablyudeniya, nedostupnyiye obyyektyi i nepolnaya istoriya dayut neizvestnyij tekusjhij schyot s prichinoj. Poslednij izvestnyij rezuljtat sokhranyayetsya kak istoricheskij; on ne stanovitsya nulyom ili svideteljstvom blagopoluchiya. Novaya podtverzhdyonnaya epokha — otdeljnoye resheniye, ne avtomaticheskij sposob skryitj razryiv.

### Granicyi i otkryityiye proyektnyiye resheniya

Pered rabochim podklyucheniyem nuzhno vyibratj i obosnovatj politiku schyota: pervyij roditelj libo inoj yavno opredelyonnyij okhvat. Schyot vsekh dostizhimyikh kommitov dal byi drugoye povedeniye pri sliyanii i trebuyet samostoyateljnyikh etalonov. Otkryityi rabocheye znacheniye intervala, polnomochiye vyibora novoj bazyi, politika izmeneniya intervala dlya realjnoj istorii, yomkostj i gruppirovka signalov, adresat vnimaniya i kriterii soderzhateljnogo obzora. Eti resheniya ne meshayut podgotovitj matricu zadannogo eksperimentaljnogo rezhima, no ne schitayutsya soglasovannyimi dlya proizvodstva.

[Modelj vnimaniya](modelj-vnimaniya.md) opredelyayet sostoyaniye i proiskhozhdeniye signala; [deklarativnyij katalog](detektoryi.json) khranit shablon JSON-sostoyaniya s neizvestnyimi znacheniyami. Eto opisaniye budusjhikh dannyikh, ne dejstvuyusjhij runtime API. Sborsjhik, khranilisjhe sostoyaniya, ispolnitelj scenariyev, izmeritelj i podklyucheniye k rabochemu ciklu ostayutsya posleduyusjhim obyyomom. Signal ne sozdayot raspisaniye, hook, heartbeat, fonovyij opros, vyizov modeli ili novyiye vneshniye polnomochiya.

## Ustarevaniye, protivorechiya i neizvestnostj

Vozrast zapisi sam po sebe ne delayet vse yeyo polya lozhnyimi. Dejstviye znacheniya opredelyayetsya oblastjyu i proveryayemyim usloviyem:

- Modelj otnositsya k konkretnomu khodu; nachalo drugogo khoda ne nasleduyet yeyo bez novogo svideteljstva.
- Sostoyaniye dereva otnositsya k nablyudyonnyim root/ref/HEAD; smena odnogo iz nikh trebuyet novoj sverki.
- Chastichnyij spisok zadach ne dokazyivayet otsutstviye neupomyanutoj zadachi.
- Pozdnyaya chelovecheskaya otmena isklyuchayet prezhneye razresheniye na sleduyusjheye dejstviye, sokhranyaya istoriyu pervonachaljnoj komandyi.
- Nedostupnyij istochnik sokhranyayet posledneye izvestnoye nablyudeniye kak istoricheskoye; tekusjhij status ostayotsya neizvestnyim.
- Nesoglasovannyiye svedeniya sokhranyayutsya razdeljno. Boleye pozdneye polucheniye odnogo otveta ne dayot yemu avtomaticheski boljshego avtoriteta.
- EOF, final, kommit i otsutstviye output ne zakryivayut obyazateljstva bez otdeljnogo dokazateljstva ikh vyipolneniya.

Yesli primenyayetsya vremennoj srok godnosti, v sreze sokhranyayutsya identifikator politiki, yeyo oblastj i osnovaniye poroga. Proizvoljnyij obsjhij srok dlya vsekh polej ne naznachayetsya. Sroki i prichinnoye ustarevaniye proveryayutsya otdeljno.

## Osnova avtomaticheskikh proverok

[Scenarii priyomki](scenarii-priyomki.json) zadayut ustojchivyiye identifikatoryi sluchayev, izmeneniya vkhoda, obyazateljnyiye nablyudayemyiye svojstva i zapresjhyonnyiye vyivodyi. Eto deklarativnaya matrica dlya budusjhego testovogo ispolnitelya, a ne uzhe ispolnyayemyij nabor testov.

Ispolnitelj snachala proveryayet strukturu vkhodov i vyikhodov, zatem sokhrannostj obyazateljnyikh identifikatorov i ogranichenij, korrektnostj proiskhozhdeniya, oblastj znachenij i priznaki nepolnotyi. Dlya kazhdogo otkaza on sokhranyayet konkretnyij sluchaj i ssyilku na proveryayemyiye bajtyi. Nepodderzhannaya forma privodit k yavnomu otkazu ili nepolnote po kontraktu, a ne k zelyonomu rezuljtatu.

Formaljnyiye proverki pokryivayut zadannyiye invariantyi, no ne dokazyivayut smyislovuyu polnotu proizvoljnogo chelovecheskogo teksta. Na etape priyomki nuzhen nezavisimyij razbor iskhodnoj komandyi i poluchennogo sreza. Novyiye realjnyiye oshibki dobavlyayutsya otdeljnyimi regressionnyimi sluchayami s proiskhozhdeniyem.

## Izmereniye poleznosti

[Pasport eksperimenta](pasport-eksperimenta.json) fiksiruyet sopostavimyij vkhod, versii instrumentov, usloviya, povtoreniya, metriki i ogranicheniya nablyudayemosti. Nezapolnennyiye polya oboznachayut budusjhij eksperiment; oni ne yavlyayutsya nulevyimi zatratami ili uspeshnoj proverkoj.

Snachala ustanavlivayetsya iskhodnyij zamer tekusjhego sposoba vosstanovleniya na zakreplyonnom nabore zadach. Zatem tot zhe nabor vyipolnyayetsya s novyim sborsjhikom. Dlya oboikh sposobov sokhranyayutsya tochnyiye vkhodyi, odinakovyiye kriterii rezuljtata i stoimostj samogo sbora.

Sravnivayutsya obyyom peredannyikh dannyikh i, pri nalichii dostovernogo schyotchika, vkhodnyiye tokenyi modeli; chislo povtornyikh chtenij; pryamyiye vyizovyi modeli i vlozhennyiye vyizovyi avtomatizacij; zaderzhka vosstanovleniya; dolya vyivodov s proveryayemyim proiskhozhdeniyem; chislo poteryannyikh ogranichenij, obyazateljstv i oshibochnyikh sostoyanij. Diskovyij razmer JSONL ne schitayetsya razmerom kontekstnogo okna. Kyeshirovannyiye tokenyi, vremya ozhidaniya i vlozhennyiye intervalyi uchityivayutsya razdeljno.

Granica kachestva pervichna: dlya zadannogo etalonnogo nabora ne dopuskayutsya poterya obyazateljnogo ogranicheniya ili obyazateljstva, pripisyivaniye cheloveku sluzhebnoj komandyi i lozhnoye podtverzhdeniye dejstviya. Snizheniye chisla vyizovov pri ukhudshenii etikh svojstv ne yavlyayetsya uluchsheniyem. Velichina poleznogo snizheniya zatrat opredelyayetsya posle iskhodnogo zamera; zaraneye vyidumannyij procent ne naznachayetsya.

## Obratnaya svyazj po resursam

[Modelj vnutrennego nablyudeniya i vnimaniya](modelj-vnimaniya.md) zadayot funkcionaljnuyu posledovateljnostj po chelovecheskomu obrazcu: signal, znachimostj, vnimaniye, razbor, dejstviye i obucheniye. [Katalog detektorov](detektoryi.json) vyidelyayet situacii, trebuyusjhiye vnimaniya; ikh porogi i avtomaticheskiye reakcii ne schitayutsya nastroyennyimi do otdeljnoj proverki.

Rabochij srez vklyuchayet dostupnyiye pokazaniya vnutrennego nablyudeniya: obyyom konteksta, raskhod limitov, CPU, pamyatj, diskovyiye operacii, dliteljnostj proverok i ozhidanij. Kazhdoye pokazaniye imeyet znacheniye s yedinicej, istochnik i yego versiyu, vremya nablyudeniya i polucheniya, oblastj, polnotu i pravilo ustarevaniya. Neizvestnoye znacheniye ne zamenyayetsya nulyom.

Razlichayutsya chetyire oblasti: otdeljnyij vyizov, process ili proverka, zadacha i obsjhij akkaunt libo khost. Dostupnyij API limitov Codex soobsjhayet okna akkaunta; eti dannyiye neljzya ispoljzovatj kak schyotchik zapolneniya konteksta ili zatrat dannoj zadachi. Monotonnoye proshedsheye vremya ne zamenyayet CPU. Summa roditeljskogo i vlozhennyikh intervalov ne schitayetsya obsjhej stoimostjyu bez dokazannogo neperesecheniya.

Petlya imeyet chetyire shaga: poluchitj pokazaniya, sopostavitj ikh s rezuljtatom i ogranicheniyami, predlozhitj libo vyipolnitj uzhe razreshyonnuyu korrekciyu, proveritj yeyo effekt na sopostavimom vkhode. Korrekciyami mogut byitj adresnoye raskryitiye dannyikh, ustraneniye povtornogo vyichisleniya ili peredacha nezavisimoj rabotyi v uzhe razreshyonnom obyyome. Resursnyij signal ne vyidayot prava menyatj modelj, uvelichivatj raskhodyi, sbrasyivatj limityi, podklyuchatj novyij istochnik ili ignorirovatj obyazateljnuyu proverku.

Osnova sleduyusjhej avtomatizacii — vosproizvodimaya zapisj «pokazaniye → resheniye → dejstviye → rezuljtat» s neizvestnyimi polyami tam, gde svyazj ne dokazana. Poleznostj ocenivayetsya s uchyotom stoimosti nablyudatelya i kachestva resheniya. Tochnyij porog reakcii vyibirayetsya posle iskhodnogo izmereniya; avtomaticheskaya reakciya po odnomu sluchajnomu pokazaniyu ne schitayetsya realizovannoj politikoj.

## Fakticheskaya dostupnostj zavisimostej

V iskhodnoj vetke etogo utochneniya, commit `5c9806560fb9b52112ff8a7bc11888a1bb71f7aa`, kartochki 0160 i 0177 aktivnyi; ikh otdeljnyiye realizacii syuda ne integrirovanyi. Nablyudeniya nizhe poluchenyi chteniyem dostupnyikh lokaljnyikh Git-obyyektov i materialov postavok, bez zapuska chuzhikh proverok i bez svezhego podtverzhdeniya servernyikh refs.

**0177.** Otdeljnaya realizaciya chitatelya i istorii obrabotki sokhranena v FUM-kommite `6b1860591deb1d669f5f5ae1bd03336170fb8fce`; pozdnyaya kvalifikaciya — `9fcdde84938762aebb1df773c41b98f8c1833734`, vetka `refs/heads/codex/необработанные-сообщения-01a07d3d`. Dokumentyi postavki: `Инструменты/fum-svyaznostj-rabochej-sessii/сообщения-задачи.md` i `обработка-сообщений.md`. Eto dostupnyij otdeljno kontrakt, a ne uzhe dejstvuyusjhij adapter 0165.

Budusjhij adapter dolzhen sokhranyatj identichnostj zadachi i istochnika, zavershyonnuyu granicu i khyesh konteksta, ekzemplyaryi soobsjhenij i ikh bajtovyiye pozicii, proiskhozhdeniye, khyesh istorii obrabotki, ostatok, polnotu istochnika, neproverennyij khvost i granicu zaklyuchiteljnoj sverki. Izmenivshijsya prefiks libo nedostupnyij ekzemplyar delayet zavisimyij vyivod neproveryayemyim. Indeks 0177 okhvatyivayet poljzovateljskiye soobsjheniya; otvetyi assistenta i smyisl obyazateljstv raskryivayutsya otdeljno cherez Zhurnal i svideteljstva. Pustoj ostatok sam po sebe ne dokazyivayet ispolneniye obyazateljstv; obrabotka ne podtverzhdayetsya chteniyem, signalom ili yego rassmotreniyem. Kyesh i otdeljnyiye izmereniya 0177 ne dokazyivayut stoimostj kholodnogo, dopisyivayemogo libo boleye krupnogo vkhoda 0165.

**0160.** Iskhodniki uzhe dostavlenyi obyichnyimi otslezhivayemyimi fajlami monorepozitoriya v otdeljnoj postavke 0176: commit `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95`, vetka `refs/heads/codex/перенести-исходники-FUMA-0176`. Proverenyi `Приложения/FUMA/Packages/СтатистикаВызовов/Package.swift`, README, Sources i Tests; ryadom opublikovan paket `СнимокАгентскойЗадачи`. Postavka soderzhit komandyi vosproizvedeniya iz chistogo klona; yeyo priyomku podtverdil koordinator. Dlya planovogo utochneniya sborki ne povtoryalisj. Eti paketyi yesjhyo ne integrirovanyi v tekusjhiye master/planirovaniye i ne podklyuchenyi k srezu 0165; novyij perenos iskhodnikov ne trebuyetsya.

Predyidusjhiye FUM-manifest `37ef3e5121169ec75a29f2dc3b34eab0594933d2` i otdeljnaya Swift-narabotka `85dccce282821a890e5e65539b4f22b895b52887` sokhranyayut proiskhozhdeniye, no ne opisyivayut nyineshnyuyu granicu dostavki. V aktualjnom Package.swift ukazanyi macOS 14+, Swift 6 i sosednij `КонтейнерНаблюдений`. Polnyij 0160 i podklyucheniye metrik k konkretnoj zadache ne zakryivayutsya odnim perenosom.

Kontrakt `fum.codex-jsonl-вызовы.1` sokhranyayet identichnostj zadachi, prefiks i pozicii s khyeshami, identichnostj i semejstvo vyizova, kachestvo vremeni. On ne yavlyayetsya istochnikom komand, polnyikh argumentov, otvetov ili reshenij. Mezhzapisnaya zaderzhka ne schitayetsya vremenem ispolneniya, a vseobsjhaya vlozhennostj vyizovov ne dokazana. Izvestnyi ogranicheniya narabotki: 256 MiB vkhoda, 4 MiB stroki, 100000 strok i 8192 sobyitij vyizova/otveta vmeste s dublyami. Prevyisheniye limita i otsutstviye adaptera oznachayut yavnuyu nedostupnostj, a ne nulevoj raskhod.

Dlya pervogo budusjhego opyita dostatochno otkryityikh sinteticheskikh vkhodov s obyyavlennyimi kontraktami. Podklyucheniye realjnyikh istochnikov trebuyet prinyatoj versii adaptera i dopustimogo nositelya. V [pasporte](pasport-eksperimenta.json) versii, dostupnostj, ogranicheniya i privyazka metrik k zadache ostayutsya nezapolnennyimi do konkretnogo opyita.

## Gotovnostj planovogo utochneniya

Planovyij rezuljtat prinimayetsya po soglasovannosti pyati materialov i kartochki 0165: yestj vyibrannaya oblastj budusjhego vkhoda, opredelyonnyij eksperimentaljnyij schyot, modelj JSON, proiskhozhdeniye reshenij, deklarativnyiye granichnyiye sluchai, nezavisimyij etalon i pasport budusjhego profilya. Strukturnaya proverka JSON i ssyilok podtverzhdayet toljko eti artefaktyi. Ona ne ispolnyayet opisannyiye scenarii i ne zakryivayet 0165.

## Poryadok rabot

1. Soglasovatj podderzhannyij vkhod i formaljnyij vyikhod, sokhraniv otkryityiye resheniya o srokakh godnosti, limite sreza i dostupnyikh schyotchikakh.
2. Prevratitj deklarativnyiye sluchai v povedencheskiye RED, realizovatj chitayusjhij sborsjhik i poluchitj GREEN.
3. Dobavitj adresnoye raskryitiye svideteljstv, vosproizvodimyij povtor i proverki podmenyi istochnika.
4. Realizovatj izmeritelj po pasportu, provesti profilj na odinakovyikh vkhodakh i prinyatj obosnovannoye resheniye ob optimizacii.
   Podklyuchitj toljko dostupnyiye resursnyiye pokazaniya s dokazannoj oblastjyu; proveritj ustarevshiye signalyi i lozhnuyu ekonomiyu otdeljnyimi scenariyami 09–10.
5. Projti nezavisimuyu smyislovuyu proverku i otdeljnuyu integracionnuyu priyomku. Toljko posle neyo obsuzhdatj podklyucheniye k rabochemu ciklu.

## Istochniki

- [Pozdneye utochneniye o dostavke 0160](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-11_08-14-52_MSK_уточнить-план-вспоминания-рабочего-контекста/материалы/уточнение-поставки-0160.json) i [proverennyiye Git-obyyektyi paketov](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-11_08-14-52_MSK_уточнить-план-вспоминания-рабочего-контекста/материалы/поставка-пакетов-0176.json).

- [Pervichnyiye komandyi, otvetyi i prinyataya postanovka utochneniya](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-11_08-14-52_MSK_уточнить-план-вспоминания-рабочего-контекста/запрос.md).

- [Zadacha 0165](../kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md).
- [Pryamoye porucheniye zaplanirovatj zadachu i osnovu budusjhikh proverok](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-09_14-35-59_MSK_подготовить-нативное-продолжение-задачи/запрос.md).
- [Nablyudeniya o zatratakh i ispoljzovanii konteksta](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-09_14-35-59_MSK_подготовить-нативное-продолжение-задачи/отчёт.md).
- [Statistika vyizovov](../kartochki-shagov/🟡-FUM-STEP-0160-nakaplivatj-statistiku-vyizovov.md).
- [Snimok sostoyaniya](../kartochki-shagov/🟡-FUM-STEP-0159-sobratj-snimok-agentskogo-runtime-i-interfejsa.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 01:09:27 MSK -->
<!-- content-sha256: sha256:badf532088db370f98aa0f2e0b10fc9966f697e854b83cbfd19eecf2f4c0aa19 -->
<!-- FUM-MD-RECENCY:END -->
