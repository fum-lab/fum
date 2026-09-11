# Kompaktnyij rabochij kontekst zadachi

Rabochij kontekst — vosproizvodimyij srez dolgovechnoj pamyati dlya sleduyusjhego resheniya agenta. On pokazyivayet celj, dejstvuyusjhiye ogranicheniya, nezavershyonnyiye obyazateljstva, prinyatyiye resheniya, zavisimosti i blizhajshiye dejstviya. Podrobnyiye svideteljstva ostayutsya v pervichnyikh istochnikakh i raskryivayutsya po tochnyim ssyilkam.

Etot dokument planiruyet realizaciyu shaga 0165 i zadayot osnovu budusjhikh avtomaticheskikh proverok. Sborsjhik, izmeritelj kachestva i avtomaticheskoye podklyucheniye poka ne realizovanyi. Novyikh fonovyikh zapuskov, perekhvatov i polnomochij na chteniye zdesj ne poyavlyayetsya.

## Rezuljtat pervoj realizacii

Pervaya postavka — lokaljnaya komanda, kotoraya toljko chitayet yavno vyibrannyiye istochniki odnoj zadachi i formiruyet versionirovannyij srez, kartu proiskhozhdeniya i otchyot o granicakh. Ona rabotayet na otkryityikh sinteticheskikh primerakh i na otdeljno razreshyonnom istochnike; interfejs prilozheniya i chuzhiye dialogi avtomaticheski ne obsleduyet.

Obyazateljnoye yadro instrukcij i polnyiye tematicheskiye fajlyi, trebuyemyiye dejstvuyusjhim marshrutom, zagruzhayutsya po svoim pravilam. Srez khranit ukazateli na nikh i rezuljtatyi sverki versij; on ne zamenyayet obyazateljnyij tekst sokrasjhyonnyim pereskazom.

## Pervyij chitayusjhij srez nablyudayemosti

Pervyij ogranichennyij rezuljtat 0165 — lokaljnaya komanda dlya odnoj yavno vyibrannoj zadachi. Ona prinimayet manifest svideteljstv i moment ocenki, sokhranyayet posledneye podtverzhdyonnoye sostoyaniye kazhdogo kanala i yavno pokazyivayet neizvestnostj tekusjhego sostoyaniya. Snachala realizuyutsya susjhestvuyusjhij DETEKTOR-07 poteri nablyudayemosti i zavisimoye ustarevaniye DETEKTOR-02. Signal trebuyet nedostatochnogo okhvata neobkhodimoj oblasti: sam tajm-aut ili token_limit_reached yego ne zamenyayet.

Pyatj nablyudyonnyikh situacij stanovyatsya konkretnyimi variantami [susjhestvuyusjhikh scenariyev](scenarii-priyomki.json):

1. Dva epizoda szhatiya — KONTEKST-09. Pryamoj token_limit_reached=true, znacheniya auto_compact_scope_tokens 256258 i 249772, zadacha i vremya sokhranyayutsya kak faktyi runtime. Eto vnutrennij porog sootvetstvuyusjhego sobyitiya, ne kvota akkaunta, sobstvennaya kalibrovka detektora ili tekusjheye zapolneniye posle szhatiya. Posleduyusjhiye transportnyiye otkazyi sokhranyayutsya otdeljno; obsjhaya pervoprichina ne ustanovlena.
2. Chastichnyij otvet API — KONTEKST-02/03/04. Sostoyaniye active zadachi i staryij latestTurn: interrupted otnosyatsya k svoim oblastyam i ne obyazateljno protivorechat drug drugu. Ni otsutstviye otveta, ni boleye pozdneye polucheniye starogo znacheniya ne podtverzhdayut tekusjheye sostoyaniye processa.
3. Povtornaya dostavka — KONTEKST-05. Te zhe iskhodnyiye sobyitiya ne uvelichivayut chislo nablyudenij; dva tajm-auta s odinakovyim tekstom sokhranyayutsya razdeljno. Dopisj menyayet granicu snimka, sokhranyaya prezhniye identichnosti i ssyilki.
4. Chastichnoye vosstanovleniye — KONTEKST-04/13. Novaya aktivnostj podtverzhdayet toljko sobstvennuyu zadachu i kanal; vosstanovleniye kornya ne snimayet neizvestnosti rebyonka. Novyij snimok ne obyyavlyayet ustranyonnoj prichinu starogo otkaza.
5. Izobrazheniye raskhoditsya s istoriyej — KONTEKST-07/03. Vidimyiye repliki ostayutsya svideteljstvom izobrazheniya bez vyidumannyikh JSONL-pozicij, vremeni otpravki i otmetok obrabotki. Ikh boleye ranneye otsutstviye i pozdniye tajm-autyi prichinno ne svyazanyi imeyusjhimisya dannyimi. Aktualjnostj utochnyayetsya otdeljno.

Eto utochneniye prioriteta susjhestvuyusjhej kartochki, ne novyij nabor detektorov ili skhem. Pervyij srez ne zakryivayet vse kriterii 0165. Posle RED/GREEN nuzhen neboljshoj profilj na odinakovyikh vkhodakh s uchyotom stoimosti samogo sborsjhika i sokhrannosti obyazateljstv; porog poleznosti zaraneye ne naznachayetsya.

[Staticheski proverennaya karta interfejsov](../../Zhurnal/2026-09-11_04-16-49_MSK_sokhranitj-nablyudeniya-i-utochnitj-plan-konteksta/materialyi/karta-interfejsov.md) ogranichivayet povtornoye ispoljzovaniye. Python-reader 0177 predostavlyayet chelovecheskoye proiskhozhdeniye i konechnyij snimok; API/runtime trebuyut otdeljnyikh svideteljstv. Swift-reduktor prigoden dlya podderzhannyikh polej v pamyati novoj epokhi, s sokhraneniyem prezhnej istorii, no yego logicheskiye taktyi ne podmenyayut realjnyiye vremena. Statistika boljshogo iskhodnogo JSONL poka nepolna iz-za predela 268435456 bajt; vyirezaniye i perenumeraciya khvosta ne snimayut etot predel korrektno. Minimaljnoye soyedineniye etikh interfejsov yesjhyo trebuyet proverki koda adaptera i sovmestnogo ispolneniya; zdesj ono ne realizovano.

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

## Poryadok rabot

1. Soglasovatj podderzhannyij vkhod i formaljnyij vyikhod, sokhraniv otkryityiye resheniya o srokakh godnosti, limite sreza i dostupnyikh schyotchikakh.
2. Prevratitj deklarativnyiye sluchai v povedencheskiye RED, realizovatj chitayusjhij sborsjhik i poluchitj GREEN.
3. Dobavitj adresnoye raskryitiye svideteljstv, vosproizvodimyij povtor i proverki podmenyi istochnika.
4. Realizovatj izmeritelj po pasportu, provesti profilj na odinakovyikh vkhodakh i prinyatj obosnovannoye resheniye ob optimizacii.
   Podklyuchitj toljko dostupnyiye resursnyiye pokazaniya s dokazannoj oblastjyu; proveritj ustarevshiye signalyi i lozhnuyu ekonomiyu otdeljnyimi scenariyami 09–10.
5. Projti nezavisimuyu smyislovuyu proverku i otdeljnuyu integracionnuyu priyomku. Toljko posle neyo obsuzhdatj podklyucheniye k rabochemu ciklu.

## Istochniki

- [Nablyudeniya i adresnoye utochneniye pervogo sreza](../../Zhurnal/2026-09-11_04-16-49_MSK_sokhranitj-nablyudeniya-i-utochnitj-plan-konteksta/zapros.md).

- [Zadacha 0165](../kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md).
- [Pryamoye porucheniye zaplanirovatj zadachu i osnovu budusjhikh proverok](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).
- [Nablyudeniya o zatratakh i ispoljzovanii konteksta](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/otchyot.md).
- [Statistika vyizovov](../kartochki-shagov/🟡-FUM-STEP-0160-nakaplivatj-statistiku-vyizovov.md).
- [Snimok sostoyaniya](../kartochki-shagov/🟡-FUM-STEP-0159-sobratj-snimok-agentskogo-runtime-i-interfejsa.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 04:25:12 MSK -->
<!-- content-sha256: sha256:4c0ce51300ed778b7584c59cd7f31b33e6ed5484de2150073519d6c251c178bd -->
<!-- FUM-MD-RECENCY:END -->
