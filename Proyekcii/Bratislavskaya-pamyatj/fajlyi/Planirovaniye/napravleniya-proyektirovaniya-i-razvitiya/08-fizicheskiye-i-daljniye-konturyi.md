# 08. Fizicheskiye i daljniye konturyi

## Naznacheniye

Eto napravleniye uderzhivayet daljnij fizicheskij gorizont [FUM](../../Glossarij/FUM.md): [fizicheskoye dejstviye FUM](../../Glossarij/fizicheskoye-dejstviye-FUM.md), [apparatnyiye FUM-uzlyi](../../Glossarij/apparatnyij-FUM-uzel.md), [robotizirovannyiye sistemyi FUM](../../Glossarij/robotizirovannaya-sistema-FUM.md), [proizvodstvennyiye cepochki FUM](../../Glossarij/proizvodstvennaya-cepochka-FUM.md), [zemnyiye resursnyiye poligonyi FUM](../../Glossarij/zemnoj-resursnyij-poligon-FUM.md), [kosmicheskaya avtonomiya FUM](../../Glossarij/kosmicheskaya-avtonomiya-FUM.md) i mezhzvyozdnaya dolgovechnostj.

Smyisl napravleniya - ne toropitj fizicheskuyu avtonomiyu, a zaraneye proyektirovatj tak, chtobyi blizhniye programmnyiye resheniya ne zakryivali putj k bezopasnyim, proveryayemyim i decentralizovannyim fizicheskim konturam.

## Proyektnyiye voprosyi

- Kakiye proverki dolzhnyi predshestvovatj perekhodu ot modeljnogo ili programmnogo dejstviya k fizicheskomu dejstviyu?
- Kak simulyator, otchyot o nevosproizvodimoj chasti i apparatnyij kontur svyazyivayutsya s odnim istochnikom trebovaniya?
- Gde prokhodyat granicyi riska, dostupa, otvetstvennosti i vlasti dlya fizicheskogo uzla?
- Kak opisyivatj trudnodostupnyij zemnoj poligon, modulj razvyortyivaniya i sposob dostavki tak, chtobyi proyekt ne podmenyal proverku prava, ekologii i bezopasnosti?
- Kakiye blizhniye arkhitekturnyiye resheniya vazhnyi dlya daljnego masshtaba kosmicheskoj avtonomii, no ne trebuyut prezhdevremennogo materialjnogo dejstviya?

## Liniya razvitiya

Blizhajsheye razvitiye dolzhno ostavatjsya modeljnyim i dokumentacionnyim: simulyatoryi, kontraktyi ustrojstv, kartyi riskov, otkryityiye voprosyi i otchyotyi o granicakh vosproizvodimosti. Lyuboj perekhod k realjnomu apparatnomu dejstviyu trebuyet otdeljnogo trebovaniya, proverki, ogranichenij dostupa i nablyudayemoj trassyi rezuljtata.

Fizicheskoye napravleniye dolzhno postoyanno sveryatjsya s decentralizaciyej: sostavnoj uzel ili proizvodstvennaya cepochka ne poluchayut avtomaticheskogo prava totaljnogo kontrolya nad poduzlami, sredoj ili poljzovatelyami.

## Proveryayemyij artefakt

[Karta ogranichitelej fizicheskogo dejstviya FUM](../../Dokumentaciya/40-karta-ogranichitelej-fizicheskogo-dejstviya-FUM.md) versii `1` opisyivayet risk, dve nezavisimyiye osi dostupa, roli otvetstvennosti, nablyudayemuyu trassu, trebuyemyiye simulyator i kontrakt, a takzhe svyazannyiye otkryityiye voprosyi. [Zemnyiye resursnyiye poligonyi FUM](../../Glossarij/zemnoj-resursnyij-poligon-FUM.md) vkhodyat v neyo otdeljnyim perekhodnyim sluchayem mezhdu obyichnyim zemnyim proizvodstvom i kosmicheskoj avtonomiyej.

Proverka: karta ssyilayetsya na voprosyi o granicakh apparatnoj, issledovateljskoj, vlastnoj, potrebiteljskoj, zemnoj resursnoj i kosmicheskoj avtonomii i yavno fiksiruyet, chto perekhod k realjnomu fizicheskomu dejstviyu trebuyet otdeljnogo trebovaniya, proverki i podtverzhdyonnoj trassyi.

[Modelj betonnyikh glubinnyikh sistem](../../Dokumentaciya/52-modelj-betonnyikh-glubinnyikh-sistem.md) dobavlyayet predmetnyij scenarij sravneniya podzemnogo obyyekta i podvodnogo gruzovogo marshruta. [Vyibor opornoj paryi](../kartochki-shagov/🟡-FUM-STEP-0149-vyibratj-opornyiye-scenarii-betonnyikh-glubinnyikh-sistem.md) ostayotsya dokumentacionnoj zadachej.

## Stroiteljstvo i glubinnyiye sooruzheniya

FUM-REQ-0054 otkryivayet planirovaniye stroiteljnogo napravleniya s prioritetom glubinnyikh sooruzhenij; FUM-STEP-0188 zadayot programmu i pervoye issledovaniye kartyi proverennosti tekhnologij, svyazyivaya dokument 52, fizicheskoye napravleniye 08 i susjhestvuyusjhij shag 0149.

- [Sostavitj programmu stroiteljnogo napravleniya](../kartochki-shagov/🟡-FUM-STEP-0188-sostavitj-programmu-stroiteljnogo-napravleniya.md)
- [Stroiteljnoye napravleniye s prioritetom glubinnyikh sooruzhenij](../../Trebovaniya/🟡-stroiteljnoye-napravleniye-s-prioritetom-glubinnyikh-sooruzhenij.md)

## Seljskoye khozyajstvo i proizvodstvo yedyi

Podgotovleno trebovaniye FUM-REQ-0055 i budusjhij shag FUM-STEP-0189: vyibratj kuljturu, modeljnoye mesto i masshtab, sravnitj obyichnyij process s kandidatom avtomatizacii i podgotovitj vosproizvodimyij plan do syyedobnogo sbora i khraneniya. Posadki i proizvodstvo ne vyipolnyalisj.

- [Vyibratj pervyij scenarij proizvodstva yedyi](../kartochki-shagov/🟡-FUM-STEP-0189-vyibratj-pervyij-scenarij-proizvodstva-yedyi.md)
- [Seljskoye khozyajstvo i proizvodstvo yedyi](../../Trebovaniya/🟡-seljskoye-khozyajstvo-i-proizvodstvo-yedyi.md)

## Robototekhnika

Podgotovleno trebovaniye FUM-REQ-0056 i budusjhij shag FUM-STEP-0190: vyibratj i sproyektirovatj pervyij modeljnyij robototekhnicheskij scenarij s datchikami, ocenkoj sostoyaniya, planom, privodami, rezuljtatom, otkazami i ostanovkoj. Virtualjnaya platforma s inertnyim kontejnerom oboznachena kak issledovateljskoye predlozheniye; realjnyiye ustrojstva ne zapuskalisj.

- [Sproyektirovatj pervyij modeljnyij robototekhnicheskij scenarij](../kartochki-shagov/🟡-FUM-STEP-0190-sproyektirovatj-pervyij-modeljnyij-robototekhnicheskij-scenarij.md)
- [Robototekhnicheskoye napravleniye FUMA](../../Trebovaniya/🟡-robototekhnicheskoye-napravleniye-FUMA.md)

## Proveryayemyiye rezuljtatyi

- Dlya fizicheskogo kontura snachala susjhestvuyet modelj, simulyator ili publikacionno chistyij kontrakt.
- Risk, urovenj dostupa, otvetstvennostj i nablyudayemostj opisanyi do realjnogo dejstviya.
- Otkryityiye voprosyi o granicakh avtonomii yavno svyazanyi s planovyimi materialami.
- Zemnoj resursnyij poligon opisan kak modeljnyij ili strogo podtverzhdyonnyij kontur, a ne kak avtomaticheskoye razresheniye na dobyichu, posadku, stroiteljstvo ili izmeneniye sredyi.
- Daljniye kosmicheskiye trebovaniya ispoljzuyutsya kak arkhitekturnyiye kriterii sovmestimosti, a ne kak povod k prezhdevremennoj realizacii.

## Granicyi

Eto napravleniye ne razreshayet fizicheskoye dejstviye samo po sebe. Ono sokhranyayet daljnij gorizont v pamyati proyekta i zadayot ogranicheniya dlya budusjhego. Poka granicyi apparatnoj, issledovateljskoj, socialjnoj i kosmicheskoj avtonomii ostayutsya otkryityimi, prakticheskaya rabota dolzhna ostavatjsya v proveryayemyikh programmnyikh, modeljnyikh i dokumentacionnyikh sloyakh.

## Istochniki trebovanij

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-36-54_MSK_zaplanirovatj-robototekhnicheskoye-napravleniye/zapros.md)

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-34-46_MSK_zaplanirovatj-seljskoye-khozyajstvo-i-yedu/zapros.md)

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-27-07_MSK_zaplanirovatj-stroiteljnoye-napravleniye/zapros.md)

- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 20:08:37 MSK](../../Zhurnal/2026-07-02_20-08-37_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-23 17:37:10 MSK](../../Zhurnal/2026-07-23_17-37-10_MSK_opisatj-kartu-ogranichitelej-fizicheskogo-dejstviya-FUM/zapros.md)

## Opornyiye materialyi

- [Fizicheskoye dejstviye FUM i apparatnyiye uzlyi](../../Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [Kosmicheskaya avtonomiya FUM i mezhzvyozdnoye rasseleniye](../../Dokumentaciya/14-kosmicheskaya-avtonomiya-i-rasseleniye.md)
- [Decentralizaciya FUM i granicyi vlasti](../../Dokumentaciya/15-decentralizaciya-i-granicyi-vlasti.md)
- [otkryityij vopros o granicakh apparatnoj avtonomii](../../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md)
- [otkryityij vopros o granicakh zemnyikh resursnyikh poligonov FUM](../../Voprosyi/2026-07-02_20-08-37_MSK_granicyi-zemnyikh-resursnyikh-poligonov-FUM.md)
- [otkryityij vopros o granicakh kosmicheskoj avtonomii](../../Voprosyi/2026-06-22_07-40-59_MSK_granicyi-kosmicheskoj-avtonomii-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:37:18 MSK -->
<!-- content-sha256: sha256:342c45ebf7bb73789f029976973842cbaf30a33ebdec6897ecc767f0b8043d1b -->
<!-- FUM-MD-RECENCY:END -->
