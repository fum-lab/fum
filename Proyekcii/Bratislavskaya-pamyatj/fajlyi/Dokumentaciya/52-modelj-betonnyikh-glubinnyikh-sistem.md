# 52 — Modelj betonnyikh glubinnyikh sooruzhenij i podvodnyikh gruzovyikh sistem

Modelj svyazyivayet krupnyiye zaglublyonnyiye sooruzheniya na osnove opusknyikh kolodcev i neobitayemyiye betonnyiye podvodnyiye kontejnernyiye i nalivnyiye apparatyi. Obsjhimi yavlyayutsya betonnyiye obolochki, predvariteljnoye napryazheniye, shvyi, datchiki i serijnoye proizvodstvo. Geotekhnika, gidrodinamika, avarijnyiye scenarii i normativnyiye osnovaniya kazhdoj vetvi rassmatrivayutsya otdeljno.

Eto predmetnyij scenarij [modeljnoj sredyi FUM](../Glossarij/modeljnaya-sreda.md), kotoryij sokhranyayet iskhodnyiye dannyiye, proveryayemyiye [gipotezyi](../Glossarij/gipoteza-FUM.md), raschyotnyiye dopusjheniya i kriterii [eksperimentov](../Glossarij/eksperiment-FUM.md). Razmeryi, glubinyi, materialyi i dopustimyiye vozdejstviya poka ne naznachenyi. Perekhod k stroiteljstvu ili ekspluatacii prokhodit otdeljnuyu [kartu ogranichitelej fizicheskogo dejstviya](40-karta-ogranichitelej-fizicheskogo-dejstviya-FUM.md).

## Centraljnaya gipoteza i stepenj podtverzhdeniya

Bazovyij element — okruglaya betonnaya yachejka s izmeryayemyim sostoyaniyem. V podzemnoj vetvi neskoljko stvolov nezavisimo pogruzhayutsya i soyedinyayutsya posle podtverzhdeniya ustojchivosti massiva. V morskoj vetvi gruzovyiye yachejki soyedinyayutsya s otdeljnyimi ballastnyimi, energeticheskimi i dvizhiteljnyimi modulyami. Predpolagayetsya, chto sekcionirovaniye pozvolyayet ogranichivatj posledstviya otkaza i ispyityivatj povtoryayemyij modulj. Eto nuzhno dokazatj dlya kazhdogo soyedineniya: dopolniteljnyiye styiki uvelichivayut chislo vozmozhnyikh protechek, a moduljnostj umenjshayet dolyu poleznogo obyyoma.

Stepenj podtverzhdeniya otnositsya k konkretnomu utverzhdeniyu i masshtabu:

- **Promyishlennaya tekhnologiya:** opusknyiye i pnevmaticheskiye kolodcyi, mekhanizirovannaya prokhodka stvolov; morskiye betonnyiye sooruzheniya v predelakh primenimyikh proyektov i standartov. Eto ne podtverzhdayet proizvoljnuyu glubinu ili geologiyu.
- **Issledovannyij princip:** rabota betonnyikh sfericheskikh i cilindricheskikh obolochek pod vneshnim gidrostaticheskim davleniyem. Issledovaniya ASCE i UHPC-korpusov ne dokazyivayut gotovnostj krupnogo gruzovogo apparata.
- **Inzhenernaya gipoteza:** vyirasjhivaniye gribovidnogo svoda snizu, revoljver konusnyikh meshalok, obyyedineniye betonnyikh gruzovyikh yacheyek v transportnyij apparat. V proverennyikh opornyikh istochnikakh podtverzhdeniye etikh kombinacij ne najdeno.
- **Neopredelyonnyij parametr:** glubina, poleznaya nagruzka, skorostj, resurs, sebestoimostj, sposob izvlecheniya i dopustimaya tyazhestj otkaza. Oni vyivodyatsya iz vyibrannogo scenariya i proverok.

## Formaljnaya modelj

```text
модель = {среда, ячейки, стыки, состояние, воздействия, измерения, переход, допуски}
следующее_состояние = переход(состояние, воздействия, среда, неопределённость)
измерения = наблюдение(состояние) + погрешность
```

Sostoyaniye vklyuchayet polozheniye, kren, napryazheniya, tresjhinyi, pronicayemostj, temperaturu, massu i plavuchestj. Vozdejstviya vklyuchayut vyiyemku, usiliya domkratov, smazku, zasyipku, upravleniye ballastom i tyagoj. Dlya kazhdogo etapa zaraneye zadayutsya nablyudayemyiye velichinyi, neopredelyonnostj, predel raskhozhdeniya raschyota s izmereniyem i sposob ostanovki. Prevyisheniye predela blokiruyet sleduyusjhij etap; samo nalichiye datchikov ne dokazyivayet upravlyayemostj.

## Obsjhaya yachejka

Rassmatrivayutsya malopronicayemyij beton, obyichnoye i predvariteljno napryazhyonnoye armirovaniye, kontroliruyemyiye shvyi, smennyiye vvodyi i datchiki deformacii, davleniya, protechki i korrozii. Nesusjhij, vodonepronicayemyij, gruzovoj, zasjhitnyij, ballastnyij i servisnyij konturyi opisyivayutsya razdeljno. Dlya opasnogo libo kriogennogo gruza betonnaya obolochka sama po sebe ne podtverzhdayet prigodnostj gruzovogo barjyera.

Sfericheskaya i kruglaya cilindricheskaya formyi imeyut issledovateljskuyu bazu dlya vneshnego davleniya. Ovaljnyiye, arochnyiye i sostavnyiye formyi ostayutsya otdeljnyimi raschyotnyimi variantami: ikh neljzya obyyavlyatj predpochtiteljnyimi bez sravneniya ustojchivosti, nesovershenstv, styikov i dostupnogo obyyoma.

## Podzemnaya vetvj

Otkryityij opusknoj kolodec pogruzhayetsya pri razrabotke grunta vnutri rezhusjhego bashmaka. Pnevmaticheskij kesson sozdayot u osnovaniya rabochuyu kameru so szhatyim vozdukhom; Daiho opisyivayet sukhuyu vyiyemku s posledovateljnyim narasjhivaniyem zhelezobetonnogo tela. Mekhanizirovannaya VSM-prokhodka Herrenknecht — otdeljnaya tekhnologiya vyiyemki i upravlyayemogo opuskaniya stenki. Eti sposobyi neljzya schitatj vzaimozamenyayemyimi bez geologicheskikh dannyikh, skhemyi vodoponizheniya, raschyota ustojchivosti i organizacii rabot.

Priblizhyonnyij balans vertikaljnyikh sil dlya vyibrannogo sostoyaniya imeyet vid:

```text
движущая_сила = вес_колодца + вес_балласта + направленное_усилие_управления
сопротивление = выталкивающая_сила + сопротивление_под_башмаком + боковое_трение
избыток_силы = движущая_сила - сопротивление
```

Ves i silyi zadayutsya v soglasovannyikh yedinicakh; gidravlicheskiye vozdejstviya, porovoye davleniye i napravleniye upravlyayusjhego usiliya vkhodyat v konkretnuyu raschyotnuyu skhemu. Polozhiteljnyij izbyitok sam po sebe ne yavlyayetsya bezopasnyim zakonom upravleniya pogruzheniyem: soprotivleniye menyayetsya pri dvizhenii, vozmozhnyi zavisaniye i rezkoye prosedaniye. Issledovaniye monitoringa krupnogo kessona pokazyivayet skachkoobraznoye pogruzheniye i neobkhodimostj sopostavlyatj osadku, kren, kontaktnyiye napryazheniya, davleniye smazki i deformacii stenki.

Stvolyi vyipolnyayut transportnuyu, evakuacionnuyu, ventilyacionnuyu i energeticheskuyu funkcii. Soyedineniye stvolov dopustimo v modeli toljko posle podtverzhdeniya polozheniya i sostoyaniya massiva; perekhodyi dolzhnyi imetj obosnovannoye sekcionirovaniye ot vodyi i pozhara. Kriticheskiye scenarii: valunyi, naklonnyiye sloi, zazhatiye, kren, vnezapnoye pogruzheniye, proryiv vodyi i grunta, vsplyitiye posle osusheniya i osadki poverkhnosti.

### Rastusjhij stvol i gribovidnyij svod

Gipoteza: centraljnyij stvol sluzhit transportnyim i proizvodstvennyim kanalom, a arochnaya gribovidnaya obolochka razvivayetsya iz nego snizu sektorami. Grunt nad zavershyonnyimi uchastkami podayotsya cherez centraljnyij stvol. Vozmozhnoye umenjsheniye nadzemnoj vyisotyi i povyisheniye soprotivleniya vsplyitiyu rassmatrivayutsya vmeste s dopolniteljnyimi nagruzkami zasyipki.

Kandidat dlya issledovaniya: pogruzheniye stvola; zakrepleniye gorizonta; sozdaniye rabochej kameryi; posledovateljnoye ustrojstvo sektorov svoda s vremennoj podderzhkoj; vyiderzhivaniye betona; izmereniye deformacij i porovogo davleniya; kontroliruyemaya zasyipka. Eta posledovateljnostj yavlyayetsya gipotezoj, a ne tekhnologicheskim reglamentom. Sposob sozdaniya svobodnogo obyyoma pod svod, rabota nezamknutogo sektora, peredacha nagruzki na stvol i massiv, izvlecheniye vremennyikh opor i sokhraneniye transportnogo prokhoda ostayutsya neizvestnyimi.

Shirokaya «shlyapka» ne schitayetsya pogruzhayemyim telom po analogii s kolodcem. Kritichnyi sopryazheniye stvola i svoda, nesimmetrichnaya zasyipka, ustojchivostj obolochki na kazhdoj stadii, osadki poverkhnosti i remont vneshnej storonyi. Do raschyota promezhutochnyikh sostoyanij i ispyitanij perekhod k stroiteljstvu ne zadan.

### Revoljver konusnyikh meshalok

Gipoteza proizvodstvennogo uzla: vrasjhayusjhijsya nositelj konusnyikh meshalok prokhodit nepodvizhnyiye pozicii podachi materialov, kontrolya i razgruzki. Sleduyet razlichatj oborot nositelya i sobstvennoye vrasjheniye kazhdoj meshalki, sozdayusjheye peremeshivaniye. Odin polnyij oborot nositelya sootvetstvuyet ciklu odnogo zamesa v kazhdoj ispravnoj meshalke:

```text
производительность = число_мешалок * объём_замеса * коэффициент_готовности / время_оборота_носителя
время_оборота_носителя >= время_загрузки + время_смешивания + время_контроля + время_разгрузки + резерв_времени
```

Eto ocenka srednej proizvoditeljnosti pri odnom zamese na cikl. Ona ne dokazyivayet ravnomernostj potoka i ne uchityivayet vse ogranicheniya obsjhej podachi, mojki i vyigruzki. Otdeljno proveryayutsya odnorodnostj, dozirovaniye, vremya smeshivaniya, otbrakovka odnogo zamesa, ochistka, disbalans, izvlecheniye zaklinivshej meshalki i soglasovaniye s armirovaniyem i ukladkoj. Sravnivayutsya poverkhnostnyij zavod, modulj v stvole i nizhnij mobiljnyij modulj.

## Podvodnaya vetvj

V rassmatrivayemoj kontejnernoj konfiguracii ISO-kontejner ostayotsya logisticheskoj yedinicej v sukhom otseke s davleniyem, blizkim k atmosfernomu. On ne schitayetsya prochnyim korpusom protiv vneshnego gidrostaticheskogo davleniya. Sravnivayutsya yedinyij samokhodnyij apparat, gruzovyiye kapsulyi s otdeljnyim tyagachom i pogruzhayemaya barzha. Vozmozhnyij rannij demonstrator — izvlekayemaya barzha dlya korotkogo zasjhisjhyonnogo marshruta; yeyo vyibor trebuyet podtverzhdeniya vozmozhnosti podyyoma, obsluzhivaniya i sravneniya s nadvodnyim variantom.

V nalivnoj konfiguracii sravnivayutsya nezavisimyij metallicheskij ili kompozitnyij tank, uravnoveshennyij po davleniyu tank s mezhbarjyernyim obyyomom i smennaya kapsula. Dlya rannego eksperimenta rassmatrivayetsya inertnaya zhidkostj s zadannyimi plotnostjyu i sovmestimostjyu materialov. Neftj, khimikatyi, szhizhennyiye gazyi i zhidkij uglekislyij gaz trebuyut otdeljnyikh dokazateljstv germetichnosti, sovmestimosti, temperaturnogo rezhima i posledstvij utechki.

Dlya odnorodnoj zhidkosti pri kvazistaticheskom rassmotrenii:

```text
наружное_давление = давление_на_поверхности + плотность_воды * ускорение_тяжести * глубина
перепад_давления = наружное_давление - внутреннее_давление
выталкивающая_сила = плотность_воды * ускорение_тяжести * вытесняемый_объём
резерв_подъёмной_силы = выталкивающая_сила - суммарный_вес
```

Summarnyij ves vklyuchayet korpus, oborudovaniye, gruz i ballast. Vyitesnyayemyij obyyom i ves dolzhnyi sootvetstvovatj odnomu sostoyaniyu zatopleniya; polozhiteljnyij rezerv ne dokazyivayet ostojchivostj, upravlyayemyij podyyom ili prochnostj. Dlya obolochki rasschityivayetsya perepad davleniya, vklyuchaya vnutrenneye davleniye i rezhim pogruzheniya.

Proveryayutsya neravnomernoye zapolneniye, svobodnyiye poverkhnosti zhidkosti, otkaz klapana, poterya energii i svyazi, stolknoveniye, posadka na grunt i zatopleniye odnoj sekcii. Odin iz rannikh kriteriyev — vozmozhnostj kontroliruyemogo izvlecheniya posle izolyacii povrezhdyonnoj yachejki. Konflikt avarijnoj plavuchesti s massoj betona proveryayetsya do detalizacii transportnoj sistemyi.

Nuzhnyi nelinejnyij raschyot ustojchivosti s geometricheskimi nesovershenstvami, razbrosom tolsjhinyi i prochnosti, realjnyimi shvami, poteryami predvariteljnogo napryazheniya, ciklicheskim vozdejstviyem i degradaciyej. Ispyitaniye povyishennyim davleniyem i razrushiteljnoye ispyitaniye predstaviteljnogo obrazca reshayut raznyiye zadachi; rezuljtatyi odnogo obrazca ne dayut dopustimoj glubinyi dlya proizvoljnogo korpusa.

Rabota o Subsea Shuttle Tanker yavlyayetsya raschyotnyim issledovaniyem transportnoj koncepcii so **staljnyimi** korpusami. Ona polezna kak primer sravneniya scenariyev perevozki uglekislogo gaza i ne podtverzhdayet gotovnostj betonnogo gruzovogo apparata. DNV-ST-C502 okhvatyivayet morskiye betonnyiye sooruzheniya; primenimostj k konkretnomu apparatu ustanavlivayetsya otdeljno. Publikaciya IMO o MASS Code otnositsya k avtonomnyim **nadvodnyim** sudam i ne zadayot avtomaticheski normativnyij rezhim podvodnoj sistemyi.

## Ekonomika, pasport i proverki

Sravneniye provoditsya po odinakovyim granicam zhiznennogo cikla:

```text
полная_стоимость = капитальные_затраты + приведённые_эксплуатационные_затраты
                 + ожидаемые_затраты_риска + затраты_простоя
```

Ekspluatacionnyiye zatratyi vklyuchayut energiyu, portovyij cikl, osmotryi, remont i izvlecheniye bez povtornogo schyota odnikh raskhodov. Podzemnaya vetvj sravnivayetsya s tonnelyami, shakhtami, stenoj v grunte i otkryitoj vyiyemkoj. Morskaya — s nadvodnyim sudnom, truboprovodom i staljnyim podvodnyim apparatom. Dopusjheniya o masshtabe, marshrute, cene energii i resurse sokhranyayutsya vmeste s rezuljtatom.

Pasport yachejki khranit proiskhozhdeniye materialov, fakticheskuyu geometriyu, natyazheniye, temperaturnuyu istoriyu tverdeniya, kartu shvov i remontov, ispyitaniya i istoriyu davleniya, tresjhin, protechek i udarov.

Obsjhij pervyij etap — postanovka zadachi i svyazannyij massovo-obyyomnyij i stoimostnoj balans. Zatem issleduyutsya materialyi i defektnyiye shvyi. Podzemnaya vetvj otdeljno prokhodit proverku gruntovogo vzaimodejstviya, upravlyayemosti pogruzheniya i promezhutochnyikh sostoyanij svoda. Morskaya vetvj otdeljno prokhodit ispyitaniya obolochki, avarijnoj plavuchesti i izvlecheniya, posle chego mozhet rassmatrivatj nablyudayemyij korotkij marshrut. Uspekh odnoj vetvi ne zamenyayet dokazateljstva drugoj.

Variant snimayetsya libo peresmatrivayetsya, yesli massa isklyuchayet poleznuyu nagruzku, povrezhdeniye ne pozvolyayet izvlechj apparat, dopuski ne dayut zapasa ustojchivosti, otkaz styika ne lokalizuyetsya, kriticheskiye zonyi nedostupnyi dlya remonta, pogruzheniye kolodca neljzya upravlyayemo ostanovitj, osadki nepriyemlemyi ili zhiznennyij cikl proigryivayet obyichnoj aljternative.

Sleduyusjhij [planovyij shag](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0149-vyibratj-opornyiye-scenarii-betonnyikh-glubinnyikh-sistem.md) — vyibratj odin podzemnyij obyyekt s glubinoj i geologiyej i odin korotkij morskoj marshrut s gruzom i portovyim ciklom. Neopredelyonnyiye parametryi sokhranyayutsya v pasportakh etikh scenariyev; universaljnyiye razmeryi do etogo ne naznachayutsya.

## Istochniki i granicyi proverki

- [Iskhodnyij zapros o priyome i lokaljnoj peresborke](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [Arkhiv dialoga «Modelj stroiteljstva sooruzhenij»](../Istochniki/URL/https/chatgpt.com/share/6a97050e-9da8-83ed-b92c-a3850dd6486d/source-index.md) — proiskhozhdeniye inzhenernyikh gipotez; yego utverzhdeniya ne zamenyayut nezavisimyiye istochniki.
- [Proverka istochnikov i redakcionnyiye resheniya](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/materialyi/proverka-istochnikov.md).
- [Herrenknecht — VSM](https://www.herrenknecht.com/ru/produkte/productdetail/schachtabsenkanlage-vsm/) — mekhanizirovannaya prokhodka stvolov.
- [Daiho — Outline of Pneumatic Caisson](https://www.daiho.co.jp/en/tech/civil_eng/nk/) — opisaniye pnevmaticheskogo kessona proizvoditelem.
- [Monitoring the construction of a large-diameter caisson in sand](https://www.sciencedirect.com/org/science/article/pii/S1353261821000223) — nablyudayemoye vzaimodejstviye grunta i opusknogo sooruzheniya; dostupnyij izdateljskij indeks.
- [DNV-ST-C502](https://www.dnv.com/energy/standards-guidelines/dnv-st-c502-offshore-concrete-structures/) — proverena otkryitaya kartochka standarta; polnyij normativnyij tekst ne proveren.
- [Concrete Hulls for Undersea Applications](https://ascelibrary.org/doi/10.1061/JSDEAG.0002883) — proverena dostupnaya annotaciya izdatelya, polnyij tekst zakryit.
- [UHPC underwater housings](https://onlinelibrary.wiley.com/doi/full/10.1002/suco.201600018) — proverena dostupnaya annotaciya izdatelya, polnyij tekst zakryit.
- [Technical–Economic Feasibility Analysis of Subsea Shuttle Tanker](https://www.mdpi.com/2077-1312/10/1/20) — raschyotnaya koncepciya so staljnyimi korpusami.
- [IMO — MASS Code](https://www.imo.org/en/mediacentre/pressbriefings/pages/imo-adopts-mass-code.aspx) — kontekst avtonomnogo nadvodnogo sudokhodstva.

## Svyazannyiye materialyi FUM

- [Sreda dlya vnutrennikh FUM](11-sreda-dlya-vnutrennikh-FUM.md) i [nauchnyiye issledovaniya](16-nauchnyiye-issledovaniya-i-otkryitiya.md).
- [Shablon scenariya modeljnoj sredyi](../Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md) i [shablon kartochki eksperimenta](../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 18:43:58 MSK -->
<!-- content-sha256: sha256:2ac2fc00cb62a68763b19d950a32a43602cb827bdc3096c888030bc06c60d86e -->
<!-- FUM-MD-RECENCY:END -->
