# Vnutrenneye nablyudeniye i vnimaniye

Eto sokhranyonnaya deklarativnaya modelj iz planovoj postavki `186b0360a31b97184773757634976257d0f86495`. Yeyo perenos ne vklyuchayet detektoryi v rabochij runtime. Pervyij otdeljnyij srez 0165 — chitayusjhij sborsjhik sinteticheskogo konteksta s proiskhozhdeniyem, nepolnotoj i ustarevaniyem; realizaciya README i dejstvuyusjhikh detektorov vnimaniya ostayotsya vne etogo naznacheniya.

Chelovecheskaya modelj ispoljzuyetsya kak funkcionaljnaya osnova: vnutrenniye signalyi postupayut na predvariteljnuyu ocenku, znachimyiye situacii poluchayut vnimaniye, zatem vyibirayetsya dejstviye i proveryayetsya yego rezuljtat. Eto proyekt organizacii rabochego cikla FUMA; sootvetstviye konkretnyim biologicheskim mekhanizmam zdesj ne utverzhdayetsya.

## Urovni cikla

1. Nablyudeniye poluchayet dostupnyiye pokazaniya konteksta, resursov, vyipolneniya i sostoyaniya obyazateljstv. Ono sokhranyayet istochnik, yedinicu, oblastj i vremya; otsutstvuyusjheye pokazaniye ostayotsya neizvestnyim.
2. Predvariteljnaya obrabotka proveryayet sopostavimostj pokazanij, ustranyayet povtornuyu dostavku odnogo sobyitiya i vyidelyayet izmeneniye otnositeljno izvestnogo sostoyaniya.
3. Detektoryi raspoznayut yavno zadannyiye situacii. Ikh rezuljtat — signal s dokazateljstvom, znachimostjyu i usloviyem snyatiya.
4. Vnimaniye sobirayet signalyi v ogranichennuyu ocheredj, pokazyivayet protivorechiya, vazhnyiye izmeneniya i otlozhennyiye voprosyi. Prichina prioriteta vidima.
5. Razbor svyazyivayet signal s celjyu, obyazateljstvami i polnomochiyami. Agent libo chelovek vyibirayet sleduyusjhij shag; fakt vyibora sokhranyayetsya otdeljno ot ispolneniya.
6. Dejstviye vyipolnyayetsya toljko v razreshyonnoj oblasti. Obratnaya svyazj pokazyivayet nablyudyonnyij effekt, otsutstviye podtverzhdeniya ili ukhudsheniye.
7. Obucheniye sravnivayet rezuljtat s ozhidaniyem. Udachnyij sposob reakcii stanovitsya kandidatom dlya vosproizvodimoj avtomatizacii posle proverki na sopostavimyikh sluchayakh.

Urovni svyazanyi proiskhozhdeniyem sobyitij, a ne vyidumannoj chislennoj uverennostjyu. Vremya polucheniya, prichinnoye izmeneniye i oblastj istochnika vliyayut na aktualjnostj razdeljno.

## Detektoryi

[Nachaljnyij katalog](detektoryi.json) opisyivayet situacii i dannyiye, neobkhodimyiye dlya ikh obnaruzheniya. Usloviya poka deklarativnyi; rabochij dvizhok detektorov ne realizovan. Katalog ne oznachayet vklyuchyonnyij monitoring.

Signal soderzhit identifikator detektora i yego versiyu, zadachu i oblastj, iskhodnyiye svideteljstva, usloviye srabatyivaniya, vremya nablyudeniya, znachimostj, sostoyaniye razbora i usloviye snyatiya. Dlya kolichestvennogo poroga sokhranyayutsya yego znacheniye, yedinica, metod vyibora i sopostavimyij iskhodnyij zamer. Otsutstviye etikh dannyikh ne zamenyayetsya proizvoljnyim porogom.

Razlichayutsya informacionnyij signal, trebuyusjhij vnimaniya i kriticheskij. Znachimostj opredelyayetsya posledstviyem dlya celi ili ogranicheniya, a ne toljko boljshim chislom. Signal o nedostupnom izmeritele otlichayetsya ot signala o podtverzhdyonnom ischerpanii resursa.

## JSON-sostoyaniye vspominaniya

[Shablon sostoyaniya v kataloge detektorov](detektoryi.json) — deklaraciya budusjhego formata. Polya konfiguracii, schyot i vremena poka imeyut znacheniye null; pustoj perechenj signalov v shablone oznachayet otsutstviye nablyudeniya, a ne podtverzhdyonnoye otsutstviye povodov. Struktura dopolnyayet planovyij katalog versii 1 i ne obyyavlyayet sovmestimostj s otsutstvuyusjhim ispolnyayemyim API.

Sostoyaniye razdelyayet vyibrannuyu oblastj, podtverzhdyonnuyu epokhu, konfiguraciyu, nablyudyonnuyu istoriyu, vyichislennyij schyot i signalyi. U kazhdogo vyichislennogo polya sokhranyayutsya iskhodnyiye svideteljstva, versiya algoritma, granica vkhoda, status dostupnosti i prichina ustarevaniya. Schyot i peresecheniye intervala preimusjhestvenno algoritmichnyi; ocenka vyipolneniya celi trebuyet samostoyateljnogo soderzhateljnogo razbora.

Identichnostj povoda zadayot kortezh: repozitorij, zadacha, polnyij ref, identichnostj epokhi, bazovyij commit, versiya konfiguracii i poryadkovaya granica intervala. Kommit peresecheniya, nablyudyonnyij HEAD i identifikator detektora vkhodyat v dokazateljstvo. Versiya konfiguracii fiksiruyet takzhe rezhim schyota i versiyu algoritma; ikh izmeneniye trebuyet yavnoj novoj versii i podtverzhdyonnoj epokhi. Sposob kodirovaniya kortezha i khraneniya vyibrannyikh sobyitij utochnyayetsya budusjhej realizaciyej; ravenstvo teksta voprosa ne dokazyivayet ravenstva signalov.

Dlya kazhdogo povoda sokhranyayutsya prichina, yedinica i znacheniye schyota, interval s istochnikom, dostignutaya granica, otnosyasjhiyesya k nej OID, polnota istorii, vremya sobyitiya pri nalichii i otdeljnoye vremya polucheniya. Git-vremya avtora ne dokazyivayet vremya dostavki ili sozdaniya signala. Vopros i rekomenduyemaya oblastj obzora — predstavleniye povoda, a ne rezuljtat proverki kachestva.

## Chteniye, signal, rassmotreniye i ispolneniye

1. Chteniye podtverzhdayet dostup k opredelyonnomu prefiksu ili snimku. Ono ne podtverzhdayet rassmotreniye vsekh soderzhasjhikhsya komand.
2. Signal fiksiruyet vyipolnennoye usloviye detektora i granicu dannyikh. On ne dayot otveta «vsyo khorosho».
3. Rassmotreniye sokhranyayet otdeljnoye svideteljstvo razbora: kto rassmotrel, kakiye celi i obyazateljstva proverenyi, na kakikh dannyikh osnovan vyivod, chto ostalosj neizvestnyim. Prosmotr, pokaz voprosa i otmetka polucheniya etogo ne zamenyayut.
4. Ispolneniye sokhranyayet razreshyonnoye dejstviye i podtverzhdyonnyij rezuljtat protiv konkretnogo kriteriya. Vyibor dejstviya, yego otpravka i uspekh razlichayutsya.

Nablyudayemaya aktualjnostj signala i stadiya reakcii — nezavisimyiye izmereniya. Signal mozhet byitj rassmotren, no yego prichina sokhranyatjsya; mozhet ustaretj do rassmotreniya; rezuljtat dejstviya mozhet ostatjsya neizvestnyim. Vosstanovleniye ne pridumyivayet propusjhennyiye perekhodyi i ne prevrasjhayet otsutstviye zapisi v dokazateljstvo zaversheniya.

Pozdnyaya otmena libo izmeneniye oblasti imeyut sobstvennoye podtverzhdyonnoye proiskhozhdeniye i prioritet nad staroj rekomendaciyej. Istoricheskij povod sokhranyayetsya, no proizvodnaya rekomendaciya pomechayetsya neprimenimoj; prava peresmatrivayutsya do lyubogo dejstviya. Otmena konkretnogo dejstviya ne oznachayet avtomaticheski otmenu vsej politiki vspominaniya. Pri nedostupnom istochnike otmenyi ili neizvestnoj granice dostavki aktualjnostj razresheniya ne podtverzhdayetsya po odnomu staromu srezu.

Sostavleniye sreza i vyivod signala ne sozdayut kvitanciyu obrabotki 0177. Kontrakt 0177 trebuyet otdeljnyikh svideteljstv iskhodnoj komandyi, soderzhateljnogo otveta i osnovaniya s proveryayemyimi bajtovyimi granicami i khyeshami; dopuskayutsya resheniya «otvet», «rabota», «utochneniye» i «otkaz». Zhurnal rassmotreniya signala ne sozdayot eti svideteljstva avtomaticheski. Uchyot obrabotki soobsjheniya otdeljno ot ispolneniya iskhodnogo obyazateljstva: posledneye podtverzhdayetsya svoim rezuljtatom.

## Ogranichennaya yomkostj vnimaniya

Sistema obyyedinyayet povtornyiye dostavki odnoj i toj zhe situacii, sokhranyaya schyotchik, vremya pervogo i poslednego nablyudeniya i ssyilki na iskhodnyiye sobyitiya. Odinakovyiye tekstyi raznyikh sobyitij ne skhlopyivayutsya bez dokazannoj obsjhej identichnosti.

Povtornoye uvedomleniye zavisit ot susjhestvennogo izmeneniya, sroka povtornogo rassmotreniya i podtverzhdeniya razbora. Dlya shumnyikh chislennyikh pokazanij mozhno primenyatj ustojchivostj vo vremeni i raznyiye porogi vkhoda i vyikhoda, yesli ikh parametryi obosnovanyi izmereniyem. Fiksirovannogo obsjhego vremeni podavleniya dlya vsekh signalov net.

Privyikaniye k bezopasnomu fonu ne skryivayet novoye narusheniye ogranicheniya, otzyiv razresheniya ili protivorechiye. Perepolneniye ocheredi yavno pokazyivayet nepolnotu; nerazobrannyiye znachimyiye situacii ostayutsya dostupnyi. Podtverzhdeniye polucheniya ne oznachayet ustraneniye prichinyi. Sostoyaniye nablyudayemoj situacii i sostoyaniye yeyo razbora uchityivayutsya otdeljno: resheniye prinyato, no prichina mozhet ostavatjsya aktivnoj.

## Prostyiye reakcii i razbor

Prostaya reakciya zaraneye zadayotsya proveryayemyim pravilom: naprimer, pokazatj izmeneniye, ne nachinatj dejstviye posle podtverzhdyonnoj otmenyi libo raskryitj uzhe razreshyonnyij istochnik. Dlya kazhdoj reakcii sokhranyayutsya vkhod, ozhidayemyij effekt i granica polnomochij.

Neobyichnaya situaciya, konflikt celej, otsutstvuyusjheye razresheniye i nedokazannaya svyazj peredayutsya na razbor. Resursnoye davleniye samo po sebe ne razreshayet menyatj modelj, raskhodovatj dopolniteljnyiye sredstva, sbrasyivatj limityi ili snizhatj obyazateljnuyu proverku.

Rabochij agent razlichayet nablyudeniye, signal, svoyo resheniye, otpravlennoye dejstviye i podtverzhdyonnyij rezuljtat. Neudacha ili otsutstvuyusjhaya obratnaya svyazj ne prevrasjhayutsya v uspekh posle vosstanovleniya konteksta.

## Proverka i posleduyusjheye obucheniye

Do podklyucheniya proveryayutsya poleznyiye srabatyivaniya, lozhnyiye srabatyivaniya, propuski, povtornaya dostavka, ustarevshiye pokazaniya, protivorechasjhiye istochniki i peregruzka vnimaniya. Stoimostj detektorov uchityivayetsya vmeste so stoimostjyu uvedomlenij i raskryitiya dokazateljstv.

[Matrica priyomki](scenarii-priyomki.json) i [pasport eksperimenta](pasport-eksperimenta.json) svyazyivayut korrektnostj s izmereniyami. Dlya ocenki detektora sokhranyayutsya etalonnyiye situacii, znamenatelj, usloviya nagruzki i rezuljtat reakcii. Umenjsheniye chisla uvedomlenij pri potere vazhnyikh signalov ne schitayetsya uluchsheniyem.

Pravilo, vyivedennoye iz udachnoj reakcii, sokhranyayet oblastj primeneniya, svideteljstvo poleznosti, versiyu i kriterij otmenyi pri regressii. Avtomatizaciya sleduyusjhego urovnya ne poluchayet polnomochiya toljko iz sobstvennoj ocenki effektivnosti.

## Istochniki

- [Utochneniye o vspominanii i vyichislyayemom JSON-sostoyanii](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-11_08-14-52_MSK_уточнить-план-вспоминания-рабочего-контекста/запрос.md).

- [Plan kompaktnogo rabochego konteksta](README.md).
- [Shag 0165](../kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md).
- [Ukazaniya o vnutrennej obratnoj svyazi, avtomaticheskikh detektorakh i chelovecheskoj modeli](https://github.com/fum-lab/fum/blob/186b0360a31b97184773757634976257d0f86495/Журнал/2026-09-09_14-35-59_MSK_подготовить-нативное-продолжение-задачи/запрос.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 01:09:27 MSK -->
<!-- content-sha256: sha256:bc399e829501eea17c3eb0b14c18c8aee0828730160d32e2931c1fd20ad5f665 -->
<!-- FUM-MD-RECENCY:END -->
