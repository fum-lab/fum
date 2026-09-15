# Otchyot 2026-09-15 19:50:16 MSK - Proveritj povtor bajtovogo operatora

Dobavleno skvoznoye pokryitiye povtornogo ispolneniya bajtovogo `Aё🙂` → UTF-32LE iz sokhranyonnyikh prinyatyikh dannyikh posle udaleniya vkhoda i opredeleniya. Proveryayutsya tochnyiye 12 bajtov, vsyo determinirovannoye nablyudeniye s tremya zapisyami trassyi, ravnyiye khyesh i razmer payload, novyij identifikator i sokhrannostj prezhnego prefiksa nakoplennoj istorii. Pered otricateljnyim testom UTF-8 vosstanovleno imenno bajtovoye opredeleniye, chtobyi ne podmenitj oshibku dannyikh otsutstviyem fajla.

V rukovodstve yavno opisan otkaz stdout posle uzhe podtverzhdyonnogo sokhraneniya: perekhvachennaya oshibka dayot kod 2, otvet mozhet otsutstvovatj ili byitj chastichnyim, zapisj ne otkatyivayetsya. Slepoj povtor mozhet dobavitj nablyudeniye; idempotentnaya dostavka kvitancii poka ne realizovana. Formulirovka podtverzhdena chteniyem susjhestvuyusjhego poryadka vyizovov, a ne inyyekcionnyim testom stdout.

Production Swift i skhemyi sborok ostayutsya bajtovo prezhnimi. Eto novoye pokryitiye i utochneniye dokumentacii; RED defekta realizacii ne zayavlen.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Podgotovka i read-only-obzor | ne izmereno | Ot proverki chistogo istochnika do rasshireniya Python i rukovodstva; otdeljnogo tajmera net |
| Skvoznyiye proverki | sm. nizhe | Dva pryamyikh vyizova otchyotnoj obyortki; binarniki ispoljzuyutsya bez perekompilyacii |
| Vnutrennij profilj | 5 obrazcov na binarnik | Prezhnij otkryityij scenarij normalizacii; process, vkhod, dekodirovaniye, ispolneniye i sokhraneniye izmeryayutsya monotonno |
| Novaya sborka, obsjhij smoke-check, proyekciya | ne zapuskalisj | Za predelami konkretnogo naznacheniya kornya |

Granica profilya: etap otkryit 2026-09-15 19:50:16 MSK. Vnutrenniye i vneshniye intervalyi ne summiruyutsya; dliteljnosti proverok ne yavlyayutsya kalendarnoj dliteljnostjyu etapa. Bajtovyij replay proveryayetsya otdeljno ot pyati izmeryayemyikh normalizacij. Sravneniye proizvoditeljnosti s proshlyim etapom ne zayavleno.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                             | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------- | ------------ | --------- |
| [Integrator FUMA] SwiftPM — bajtovyij povtor bez iskhodnyikh fajlov i polnyij scenarij | 1,781 s      | uspeshno   |
| [Integrator FUMA] Xcode — bajtovyij povtor bez iskhodnyikh fajlov i polnyij scenarij   | 1,458 s      | uspeshno   |
| [Integrator FUMA] Indeks dopolneniya — tochnyij diff                                 | 0,025 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3,264 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki i svideteljstva

Oba posledovateljnyikh zapuska rasshirennogo scenariya zavershilisj uspeshno s kodom 0. Proverenyi imenno osnovnyiye ispolnyayemyiye fajlyi SwiftPM i FUMA.app; novyikh sborok ne byilo.

- Pered ispoljzovaniyem sverenyi SHA-256 prezhnikh binarnikov: SwiftPM `aa3a53cf6fa809881321b7da1f09926e3b0bea65e0efd878bc2febc693f781e2`; Xcode `02b613f77ceb063ec8eb8b113d629625e5d5d84e6ccfd2a384fb956bfd00685c`. Privatnyiye puti peredayutsya toljko kornyu, v Git ne vklyuchayutsya.
- [Profilj SwiftPM](materialyi/profili/SwiftPM.json) i [profilj Xcode](materialyi/profili/Xcode.json) svyazyivayut binarnik, obnovlyonnyij Python, 22 fajla predmetnogo kontura i tri otkryityikh vkhoda SHA-256. Granica iskhodnikov sovpadayet s predyidusjhej postavkoj; eto ne polnyij graf SDK i vsekh prochikh fajlov prilozheniya.
- Proverka diff, svezhestj Markdown i read-only-dopusk kontroljnoj tochki vyipolnyayutsya posle zapolneniya otchyota. Kazhdyij pryamoj testovyij vyizov otrazhyon nizhe; predpisannyij zaklyuchiteljnyij dopusk ne zamyikayet izmereniye samogo sebya.

## Resheniya i ogranicheniya

- Blokiruyusjhij defekt production Swift ne obnaruzhen i ne ispravlyalsya. Povtor bajtovogo scenariya ranjshe ne imel sobstvennogo skvoznogo utverzhdeniya; teperj ono dobavleno i proveryayetsya na oboikh nastoyasjhikh binarnikakh.
- Otkaz stdout opisan po kodu; testyi yego ne inyyeciruyut. Metka uspeshnogo sokhraneniya ne yavlyayetsya podtverzhdeniyem polucheniya stdout vyizyivayusjhej storonoj.
- Sokhranyayetsya rezhim opublikovannoj kontroljnoj tochki s otkryityim terminaljnyim otchyotom. Prezhneye pokoleniye proyekcii iz bazovoj postavki ne peresobirayetsya i otstayot ot novyikh kanonicheskikh fajlov; yego iskhodnyij inventarj `sha256:651149712a44cbaefb8a7c90d7d2d48eb22bda9f4386dd4a089ecd220b33a724`, plan `sha256:a31fe342a679fd229086934e99ea600304dbd6b18e474eebb77719e3621d3024`. Obsjhaya priyomka, prezhniye dva srabatyivaniya publikacionnogo skanera v testakh bazyi i devyatj obsjhikh obyazateljstv ostayutsya u kornya.

## Istochniki

- [Iskhodnaya komanda i naznacheniye etapa](zapros.md).
- [Predyidusjhaya proverennaya postavka](../2026-09-15_19-04-26_MSK_integrirovatj-ispolneniye-operatora-FUMA/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:53:43 MSK -->
<!-- content-sha256: sha256:15b028992deff573657123d99940f62ec2601c3073554592877b1545c47dff1b -->
<!-- FUM-MD-RECENCY:END -->
