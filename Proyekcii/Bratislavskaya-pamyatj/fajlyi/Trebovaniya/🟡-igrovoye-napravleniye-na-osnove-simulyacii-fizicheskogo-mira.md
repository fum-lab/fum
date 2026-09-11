# Igrovoye napravleniye na osnove simulyacii fizicheskogo mira

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0064 -->

V FUM/FUMA dolzhno razvivatjsya igrovoye napravleniye, v kotorom vzaimodejstviye igroka i nablyudayemyiye posledstviya opirayutsya na simulyaciyu fizicheskogo mira. Kazhdaya realizaciya zadayot konechnuyu modelj: prostranstvennyij i vremennoj masshtab, vyibrannyiye obyyektyi i processyi, iskhodnyiye usloviya, fizicheskiye predposyilki, chislennyiye priblizheniya i izmerimyiye granicyi primenimosti.

Polnaya simulyaciya fizicheskogo mira ne obesjhayetsya. Zhanr, dvizhok, graficheskij putj i stepenj detalizacii poka ne vyibranyi. Igrovyiye uslovnosti i sredstva otobrazheniya otlichimyi ot sostoyaniya fizicheskoj modeli; khudozhestvennaya ubediteljnostj ne dokazyivayet fizicheskuyu tochnostj.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Dlya pervogo igrovogo scenariya opredelenyi dejstviye igroka, nablyudayemyij rezuljtat i korotkij igrovoj cikl. Fizicheskaya modelj soderzhateljno vliyayet na etot cikl.
- Zafiksirovanyi masshtab, modeliruyemyiye obyyektyi i processyi, velichinyi i yedinicyi, nachaljnyiye i granichnyiye usloviya. Priblizheniya, igrovyiye uslovnosti i neokhvachennyiye processyi yavno opisanyi.
- Dlya vyibrannoj modeli zadan obosnovannyij etalon ili nezavisimyij sposob sravneniya i izmerimyij dopusk. Chislennaya oshibka, fizicheskaya primenimostj i kachestvo otobrazheniya ocenivayutsya razdeljno.
- Vosproizvodimyij scenarij sokhranyayet iskhodnoye sostoyaniye, posledovateljnostj dejstvij, parametryi simulyacii i sluchajnosti, yesli ona ispoljzuyetsya. Sravneniye rezuljtatov uchityivayet obyyavlennyij chislennyij dopusk.
- Pervyij ogranichennyij prototip dejstviteljno dopuskayet igrovoye vzaimodejstviye. Yego rezuljtat, granichnyiye sluchai i izvestnyiye raskhozhdeniya sokhranenyi; otdeljnyij raschyot bez igrovogo cikla ne obyyavlyayetsya gotovyim igrovyim prototipom.
- Na vyibrannom profile izmerenyi vremya shaga simulyacii i potrebleniye resursov; otobrazheniye izmeryayetsya otdeljno, yesli ono vkhodit v prototip. Granica masshtaba i tochnosti svyazana s nablyudyonnyimi zatratami.
- Sobstvennyiye iskhodniki, otkryityij scenarij i komandyi sborki, zapuska i proverki sokhranenyi v FUM. Testyi, profilj i resheniye ob optimizacii podtverzhdayut vyibrannuyu realizaciyu v yeyo konechnoj oblasti.
- Rezuljtat simulyacii ne vyidayotsya za nablyudeniye fizicheskogo obyyekta ili za dokazateljstvo istinnosti modeli vne proverennyikh uslovij.

## Status i granicyi

Status — `🟡`: napravleniye prinyato k planirovaniyu; [pervyij igrovoj prototip fizicheskoj simulyacii](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0200-podgotovitj-pervyij-igrovoj-prototip-fizicheskoj-simulyacii.md) yesjhyo ne podgotovlen. Sejchas sokhranyayetsya plan bez vyibora ili ustanovki SDK, licenzirovaniya dvizhka i realizacii.

Konkretnyij profilj pervogo prototipa vyibirayetsya v predelakh uzhe soglasovannyikh [celevyikh platform FUMA](🟡-zapusk-FUMA-na-celevyikh-platformakh.md). Nastoyasjheye trebovaniye ne rasshiryayet etot perechenj i ne priravnivayet graficheskuyu podderzhku FUMA k gotovomu igrovomu dvizhku.

Fizicheskoye issledovaniye, grafika, khudozhestvennyiye i muzyikaljnyiye materialyi mogut uchastvovatj v vyibrannom prototipe cherez konkretnyiye rezuljtatyi. Obsjhaya tema sama po sebe ne ustanavlivayet zavisimostj mezhdu napravleniyami.

## Istochniki trebovanij

- [Iskhodnaya komanda ob igrovom napravlenii](../Zhurnal/2026-09-11_02-03-39_MSK_zaplanirovatj-igrovoye-napravleniye/zapros.md).
- [Modeljnaya sreda FUM i razlicheniye modeli s vneshnim mirom](../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md).
- [Shablon scenariya modeljnoj sredyi](../Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md).
- [Celevyiye platformyi FUMA](🟡-zapusk-FUMA-na-celevyikh-platformakh.md).
- [Graficheskiye interfejsyi FUMA](🟡-graficheskiye-interfejsyi-FUMA.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:04:04 MSK -->
<!-- content-sha256: sha256:c61306aadd1bb82301716f02ac28089d6a0ebdd98b3373c2f0fdea7dfe16734f -->
<!-- FUM-MD-RECENCY:END -->
