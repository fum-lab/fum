# Vnutrenneye nablyudeniye i vnimaniye

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

- [Plan kompaktnogo rabochego konteksta](README.md).
- [Shag 0165](../kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md).
- [Ukazaniya o vnutrennej obratnoj svyazi, avtomaticheskikh detektorakh i chelovecheskoj modeli](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 17:38:45 MSK -->
<!-- content-sha256: sha256:9b6f10bffd30510c66301e7c13a7f2c371f8dfb3c2fee12ffe5af128edb40d62 -->
<!-- FUM-MD-RECENCY:END -->
