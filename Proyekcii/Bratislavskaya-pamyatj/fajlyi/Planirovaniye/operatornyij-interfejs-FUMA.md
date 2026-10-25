# Operatornyij interfejs FUMA

Pervyij diagnosticheskij scenarij FUMA na Swift dolzhen zapuskatj Codex CLI, sokhranyatj yego dostupnyij potok sobyitij v pamyati i pokazyivatj nablyudayemoye sostoyaniye graficheski. Strukturiruyusjhiye operatoryi preobrazuyut eto sostoyaniye v komandyi otrisovki Metal. GUI ispoljzuyet tu zhe pamyatj i opredeleniya operatorov, chto i ostaljnaya FUMA.

Eto postanovka daljnejshej rabotyi. Ona utochnyayet susjhestvuyusjhiye trebovaniya i shagi; dannyij dokument ne podtverzhdayet sozdaniye yazyika, zapusk CLI iz prilozheniya, polnotu zapisi API ili rabotayusjhij ekran.

## Prioritet i susjhestvuyusjheye pokryitiye

Prioritet realizacii — obrabotka konteksta: [FUM-STEP-0165](kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md), [FUM-STEP-0177](kartochki-shagov/✅-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md) i [FUM-STEP-0160](kartochki-shagov/🟡-FUM-STEP-0160-nakaplivatj-statistiku-vyizovov.md). Nezavisimyiye ogranichennyiye rezuljtatyi mogut razrabatyivatjsya paralleljno; otdeljnyij rezuljtat dolzhen imetj sobstvennyiye vkhodyi, kriterii i granicu posleduyusjhego obyyedineniya.

GUI utochnyayet [FUM-REQ-0021 — proyekciyu vnutrennej pamyati](../Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md), a Metal — [FUM-REQ-0002](../Trebovaniya/🟡-otrisovka-interfejsa-cherez-Metal.md). Obsjhaya platformennaya oblastj [FUM-REQ-0047](../Trebovaniya/🟡-graficheskiye-interfejsyi-FUMA.md) sokhranyayetsya. Pervyij scenarij macOS vkhodit v [FUM-STEP-0182](kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md); khraneniye nablyudenij svyazano s [FUM-STEP-0156](kartochki-shagov/🟡-FUM-STEP-0156-realizovatj-kontejner-nablyudenij-s-binarnyimi-blokami.md).

Dlya yazyika sokhranyayetsya svyazj s raneye oformlennyimi FUM-REQ-0067 i FUM-STEP-0208: [postanovka chistogo ispolneniya i UTF-32 v kommite b08b969c](https://github.com/fum-lab/fum/blob/b08b969c9c40bda90e53e8effee904f181dce7d6/Требования/🟡-чистое-исполнение-операторов-и-UTF-32.md). Pri sliyanii prinyatoj FUMA trebovaniye i [zavershyonnyij ogranichennyij interpretator FUM-STEP-0208](kartochki-shagov/✅-FUM-STEP-0208-realizovatj-interpretator-i-UTF-32.md) vklyuchenyi v tekusjheye derevo. Prezhnyaya ssyilka sokhranyayet proiskhozhdeniye postanovki. Dostavka etogo prototipa ne zakryivayet universaljnyij yazyik ili integraciyu osnovnogo runtime. Novyiye dubliruyusjhiye identifikatoryi ne naznachenyi.

## Yazyik opisaniya strukturiruyusjhikh operatorov

Predstoit opredelitj sposob opisaniya operatorov, ikh vkhodov, vyikhodov, kompozicii i nablyudayemogo ispolneniya. Chistoye vyichisleniye otdelyayetsya ot dostupa k macOS: operator poluchayet yavno sokhranyonnyij vkhod, a vneshneye dejstviye prokhodit cherez nablyudayemuyu Swift-proslojku.

Kriterii budusjhego rezuljtata:

- Versionirovannoye opredeleniye odnoznachno zadayot znacheniya i poryadok vyichisleniya; neodnoznachnaya konstrukciya, neizvestnaya versiya i prevyisheniye resursov dayut yavnyij iskhod.
- Odni i te zhe opredeleniye i vkhod vosproizvodyat rezuljtat; proiskhozhdeniye svyazyivayet versiyu operatora, tochnyiye vkhodnyiye dannyiye i nablyudeniye ispolneniya.
- Proverochnyiye ozhidaniya nezavisimyi ot vyichisleniya. Otkryityiye polozhiteljnyiye i otricateljnyiye primeryi pokryivayut kompoziciyu, oshibku i vosstanovleniye.
- Vyibor tekstovogo ili strukturirovannogo predstavleniya, tipov i predelov obosnovan otdeljnyim proyektnyim resheniyem; gotovaya universaljnaya grammatika sejchas ne zayavlyayetsya.

## Swift, macOS i pamyatj nablyudenij

Swift-proslojka svyazyivayet API macOS, vnutrennij API interpretatora operatorov i nablyudayemyij signal. Kazhdyij vyizov ili nablyudeniye cherez API macOS, vyipolnyayemyij FUMA, dolzhen ostavlyatj zapisj v yeyo pamyati. Eta oblastj ne oznachayet perekhvata vsekh vyizovov vsekh storonnikh processov operacionnoj sistemyi.

Budusjhaya priyomka dolzhna podtverditj:

- vyizov, vkhod, iskhod, oshibka ili otmena razlichimyi i svyazanyi s porodivshej ikh operaciyej; nedostupnostj API i otsutstviye razresheniya ne vyidayutsya za pustoye uspeshnoye nablyudeniye;
- iskhodnyiye dostupnyiye bajtyi i interpretirovannoye predstavleniye svyazanyi proiskhozhdeniyem; poterya, usecheniye, razryiv i neizvestnyij format vidimyi;
- podtverzhdyonnaya zapisj vosstanavlivayetsya drugim processom po kontraktu kontejnera FUM-STEP-0156;
- perechislenyi granicyi nablyudayemogo Swift-adaptera i fakticheskoye pokryitiye API; polnota ne vyivoditsya iz odnogo uspeshnogo primera;
- opredelyon sposob uchityivatj sluzhebnyiye operacii samogo zhurnala bez beskonechnogo samoopisaniya i skryityikh isklyuchenij;
- privatnaya rabochaya pamyatj otdelena ot publikacionno dopustimyikh fikstur; polnyij rabochij potok ne publikuyetsya v Git avtomaticheski.

## Codex CLI i diagnosticheskij GUI

Swift-prilozheniye upravlyayet processom Codex CLI i sokhranyayet polnyij dostupnyij yemu potok sobyitij. Otdeljno uchityivayutsya vyikhod processa, diagnosticheskij potok, oshibka zapuska, otmena i konec vvoda. Poryadok vnutri kazhdogo potoka i fakticheski nablyudyonnoye vzaimnoye raspolozheniye sobyitij razlichayutsya: nedokazannyij globaljnyij poryadok ne pridumyivayetsya.

Dlya sistemyi strukturiruyusjhikh operatorov nuzhen adapter API Codex CLI: tipizirovannyiye komandyi i parametryi, otvetyi, sobyitiya i oshibki. Kazhdoye obrasjheniye svyazyivayetsya s zadachej, vyizovom, versiyej protokola i sokhranyonnyim nablyudeniyem. Fakticheski podderzhivayemyiye operacii opredelyayutsya po konkretnoj postavke CLI; nalichiye processa ne dokazyivayet dostupnosti proizvoljnogo API. Vosproizvedeniye chitayet sokhranyonnyiye rezuljtatyi i ne povtoryayet vneshniye dejstviya. Priyomka otdeljno proveryayet nepodderzhannuyu operaciyu, oshibku protokola i otlichiye vosproizvedeniya ot novogo ispolneniya.

Operatoryi stroyat sostoyaniye diagnosticheskogo interfejsa iz sokhranyonnyikh sobyitij. Sleduyusjheye preobrazovaniye formiruyet komandyi Metal. Obratnoye poljzovateljskoye dejstviye vozvrasjhayetsya v tot zhe sobyitijnyij kontur; ruchnoye sostoyaniye renderer ne stanovitsya otdeljnoj domennoj istinoj.

Kriterii pervogo vertikaljnogo scenariya:

- izvestnyij potok vosproizvoditsya iz pamyati bez povtornogo zapuska CLI; ekrannoye sostoyaniye svyazano s yego sobyitiyami i versiyami operatorov;
- zhivoj zapusk podtverzhdayet fakticheskiye versiyu CLI i podderzhannyij format sobyitij; neizvestnyiye sobyitiya sokhranyayutsya, a nepodderzhannaya interpretaciya oboznachayetsya;
- proverenyi chastichnyij vvod, boljshoj potok, medlennyij potrebitelj, oshibka, otmena i vosstanovleniye; interfejs ne skryivayet propuski za sokrasjhyonnyim predstavleniyem;
- diagnosticheskij ekran pokazyivayet nablyudayemyiye sostoyaniya, ne vyidavaya ikh za dostup k skryitomu vnutrennemu sostoyaniyu modeli;
- proiskhozhdeniye khotya byi odnogo elementa i obratnogo dejstviya proveryayetsya skvoznyim scenariyem; Metal-diagnostika i proverka otobrazheniya imeyut sobstvennyiye svideteljstva;
- iskhodniki, otkryityiye fiksturyi i vosproizvodimyiye komandyi khranyatsya v FUM; RED/GREEN, profilj i resheniye ob optimizacii otnosyatsya k tochnomu prinyatomu snimku.

## Nablyudayemostj i nastrojka dlya LLM

LLM dolzhna videtj, chto vyipolnyayetsya avtomaticheski i kakim sposobom: fakticheski vyibrannoye pravilo, vkhodyi, tekusjheye sostoyaniye, rezuljtat i proiskhozhdeniye. Dlya nastrojki ispoljzuyetsya yazyik opisaniya strukturiruyusjhikh operatorov. Predstavleniye otdelyayet nablyudayemoye ispolneniye ot zhelayemoj konfiguracii.

Kompaktnyij srez soderzhit tochnyiye ukazateli na polnuyu trassu; detalizaciya raskryivayetsya adresno, chtobyi nablyudayemostj sama ne perepolnyala kontekst. Predlozheniye nastrojki, yeyo prinyatiye i fakticheskoye primeneniye sokhranyayutsya kak raznyiye sostoyaniya. Otobrazheniye predlozheniya ne podtverzhdayet, chto ono uzhe vliyayet na ispolneniye. Priyomka dolzhna proveritj etu cepochku na uspeshnom, otklonyonnom i yesjhyo ne primenyonnom izmenenii, sokhraniv proiskhozhdeniye i pozdniye utochneniya.

## Obolochka iskhodyasjhikh API Codex CLI

Utochneniye «Oba potoka» okhvatyivayet zaprosyi CLI k API modeli i iniciirovannyiye CLI vyizovyi instrumentov i OS. Eti obrasjheniya dolzhnyi prokhoditj vnutri upravlyayemoj obolochki FUMA na Swift s zapisjyu vkhoda, rezuljtata, oshibki i otmenyi v pamyatj. Odin zapusk dochernego processa i chteniye yego vyivoda yesjhyo ne dokazyivayut okhvat iskhodyasjhikh obrasjhenij.

Pered realizaciyej trebuyetsya inventarj tochek obrasjheniya dlya zakreplyonnoj versii CLI: transport modeli, vstroyennyiye instrumentyi, fajlovyiye i processnyiye operacii, podklyuchayemyiye instrumentyi i vneshniye servisyi. Dlya kazhdoj tochki ukazyivayutsya sposob vklyucheniya v obolochku, kontroliruyemaya granica, proveryayemoye svideteljstvo i nepokryityiye obkhodnyiye puti. Neizvestnoye pokryitiye ostayotsya neizvestnyim; otdeljnyij uspeshnyij adapter ne dokazyivayet polnotu vsekh potokov.

Priyomka svyazyivayet zapros k modeli, porozhdyonnyij vyizov instrumenta, yego iskhod i sleduyusjhij zapros yedinoj trassoj s versiyami protokola i operatorov. Otdeljno proveryayutsya oshibka transporta, nepodderzhannyij instrument, otmena, razryiv zapisi i popyitka obkhoda obolochki. Vosproizvedeniye ispoljzuyet sokhranyonnyiye rezuljtatyi bez povtoreniya setevogo zaprosa ili dejstviya OS. Konkretnyij sposob vstraivaniya i predelyi vmeshateljstva vyibirayutsya posle proverki CLI; postanovka ne utverzhdayet, chto dejstvuyusjhij CLI uzhe predostavlyayet vse nuzhnyiye tochki podklyucheniya.

## Yedinyij runtime i stoimostj IPC

Celevaya postavka — yedinyij ispolnyayemyij binarnik FUMA, obyyedinyayusjhij prigodnyiye dlya vstraivaniya zavisimosti runtime; yeyo naznacheniye — minimizirovatj stoimostj mezhprocessnogo obmena. Predpochtiteljnyij goryachij putj Codex → operatoryi → GUI sleduyet issledovatj kak ispolneniye v odnom processe cherez pryamyiye funkcii i obsjhiye buferyi. Biblioteka, zagruzhennaya v etot process, takzhe ne trebuyet IPC dlya lokaljnogo vyizova; yedinstvennyij fajl postavki sam po sebe ne garantiruyet yedinstvennyij process.

[Sborka sobstvennoj realizacii v FUM, FUM-STEP-0176](kartochki-shagov/✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md) zadayot dostavku iskhodnikov i vosproizvodimostj. Ona ne podtverzhdayet obyyedineniye runtime v odin process. Eto dopolniteljnaya celj vyibora sostava ispolnyayemoj sistemyi, svyazannaya s pervyim scenariyem FUM-STEP-0182; susjhestvuyusjhiye kartochki dannyim utochneniyem ne zakryivayutsya.

Kriterii budusjhego resheniya:

- Dlya zakreplyonnogo scenariya sostavlenyi skhema fakticheskikh processov i perechenj perekhodov mezhdu nimi; izmerenyi chislo perekhodov, obyyom serializacii i kopirovaniya, zaderzhki p50/p95 i pikovaya pamyatj s ukazannyimi granicami izmereniya.
- Na odinakovyikh vkhodakh sravnenyi iskhodnyij variant i dostupnyij variant pryamyikh vyizovov; porogi priyemlemogo uluchsheniya i dopustimoj pamyati zadanyi do sravneniya, a otsutstviye vyiigryisha ne skryivayetsya.
- Dlya kazhdogo komponenta ukazanyi vozmozhnostj vstraivaniya, interfejs pryamogo vyizova, vladeniye buferami, oshibki, otmena i neobkhodimostj izolyacii; vyibor podtverzhdyon sborkoj i profilem tochnogo snimka.
- Sistemnyiye frameworks i SDK ne obesjhanyi chastjyu sobstvennogo binarnika. Sokhranyayemyiye otdeljnyiye processyi perechislenyi s prichinoj i izmerennoj cenoj obmena. Vyinuzhdennoye otkloneniye ot yedinogo binarnika ostayotsya yavno nezavershyonnoj chastjyu etoj celi, poka otdeljno ne prinyato izmeneniye trebovaniya; vyiigryish IPC sam po sebe yeyo ne zakryivayet.
- Poljzovateljskij scenarij, nablyudayemostj oboikh potokov API i vosstanovleniye pamyati sokhranyayutsya posle izmeneniya razmesjheniya komponentov; upakovka sama ne schitayetsya dokazateljstvom rezuljtata.

Tekusjhaya postavka sokhranyayet celj i kriterii, ne vyipolnyayet vstraivaniye Codex ili obyyedineniye runtime.

## Pervyij srez osnovnogo rantajma

Pervyij soglasovannyij rezuljtat — podklyuchitj susjhestvuyusjhij Swift-interpretator iz `Прототипы/память-структурирующих-операторов` k `Приложения/FUMA/macOS` bez kopirovaniya ispolnyayusjhej logiki. Skvoznoj putj prokhodit ot vkhoda FUMA cherez tipizirovannoye vyipolneniye operatora v osnovnom processe k rezuljtatu i dolgovechnomu nablyudeniyu v gotovom kontejnere.

Priyomka podtverzhdayet sokhraneniye oshibok, predelov i proiskhozhdeniya, vosproizvedeniye podtverzhdyonnogo nablyudeniya, sborki SwiftPM i prilozheniya, adresnyiye RED/GREEN i profilj tochnogo snimka. Dobavleniye odnoj zavisimosti ne zakryivayet srez. Obolochka oboikh potokov API Codex CLI, GUI, Metal i celj yedinogo binarnika sokhranyayut sobstvennyiye kriterii.

Susjhestvuyusjheye naznacheniye privedeno v [postoyannom plane](README.md#blizhajshiye-soglasovannyiye-postavki). Osnovaniye — [prinyataya postanovka rantajma](../Zhurnal/2026-09-15_18-29-25_MSK_zakrepitj-vosemj-reshenij-obrabotki/zapros.md); eta zapisj ne zamenyayet posleduyusjhuyu priyomku.

## Poryadok realizacii i granica postavki

Snachala prinimayutsya proveryayemyiye kontraktyi konteksta i nablyudenij. Na obsjhej versii dannyikh mozhno nezavisimo gotovitj yazyik operatorov, Swift-adapter processov i macOS, a takzhe GUI-proyekciyu s Metal-ispolnitelem. Ikh obyyedineniye proveryayetsya odnim skvoznyim scenariyem; otdeljnyij uspekh kazhdogo komponenta yego ne zamenyayet.

Tochnyiye versii CLI i SDK, format obmena, ogranicheniya resursov i porogi profilya predstoit zakrepitj pered realizaciyej. Staryiye prototipyi i chuzhoj nezakommichennyij kontrakt ne obyyavlyayutsya prinyatoj postavkoj. Tekusjhij rezuljtat ogranichen dokumentacionnyim checkpoint v postoyannoj vetke `planirovaniye`; realizaciya, polnaya priyomka i integraciya vyipolnyayutsya otdeljno.

## Istochniki

- [Pozdniye utochneniya ob oboikh potokakh API i stoimosti IPC](../Zhurnal/2026-09-15_16-09-02_MSK_utochnitj-obolochku-API-i-stoimostj-IPC/zapros.md).
- [Iskhodnyiye komandyi i proiskhozhdeniye tekusjhikh utochnenij](../Zhurnal/2026-09-15_15-40-41_MSK_utochnitj-operatornyij-interfejs-FUMA/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 20:02:40 MSK -->
<!-- content-sha256: sha256:9bf4ea808305cff12cd7ecf255bcc020e87dacb55afd54834d9b7888079860f2 -->
<!-- FUM-MD-RECENCY:END -->
