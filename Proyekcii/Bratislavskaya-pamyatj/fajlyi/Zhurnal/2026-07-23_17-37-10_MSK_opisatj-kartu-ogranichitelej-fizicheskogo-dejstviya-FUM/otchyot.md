# Otchyot 2026-07-23 17:37:10 MSK - Opisatj kartu ogranichitelej fizicheskogo dejstviya FUM

Pamyatj FUM poluchila konservativnuyu kartu perekhoda ot cifrovogo zamyisla k materialjnomu effektu. Ona ne prevrasjhayet daljnij fizicheskij gorizont v razresheniye: risk, dostup, polnomochiya, otvetstvennostj, nablyudayemostj, simulyator i kontrakt teperj dolzhnyi byitj svyazanyi s odnim tochnyim dejstviyem, a neizvestnoye usloviye zakryivayet perekhod.

## Rezuljtat

[Karta ogranichitelej fizicheskogo dejstviya FUM](../../Dokumentaciya/40-karta-ogranichitelej-fizicheskogo-dejstviya-FUM.md) versii `1` vvodit rabochiye klassyi `R0–R4`. Oni razlichayut modeljnyij sloj, apparatnoye nablyudeniye bez ispolniteljnogo effekta, izolirovannyij stend, obsjhestvenno znachimoye proizvodstvo i ekologicheski libo avtonomno rasshiryayusjhijsya kontur. Klass vyibirayet boleye strogij barjyer, no ne vyidayot polnomochiye.

Karta raznosit po dvum osyam informacionnyij dostup i operacionnyiye prava proyektirovatj, simulirovatj, podtverzhdatj, ispolnyatj, ostanavlivatj, vosstanavlivatj i proveryatj. Dlya budusjhego fizicheskogo perekhoda nazvanyi vladeljcyi trebovaniya i obyyekta, ocensjhik riska, avtorizuyusjhij subyyekt, operator, nezavisimyij nablyudatelj, vladelec avarijnogo svorachivaniya i predstavitelj zatronutyikh storon.

## Karta ogranichitelej

Posledovateljnostj barjyerov nachinayetsya s otdeljnogo trebovaniya i tochnoj oblasti, zatem trebuyet klassifikacii riska, modeli, simulyatora i kontrakta, razdeleniya rolej, nablyudayemoj trassyi, bezopasnogo sostoyaniya i vosstanovleniya. Toljko posle proverki etikh uslovij vozmozhno otdeljnoye ogranichennoye podtverzhdeniye, a neposredstvenno pered dejstviyem dolzhna sovpastj predstartovaya proverka versij, sostoyaniya i polnomochij.

Dlya syirogo nositelya karta trebuyet programmnuyu fiksturu otkazov, kontrakt blochnogo interfejsa, rezervnuyu kopiyu i vosproizvedyonnoye vosstanovleniye. Dlya robota ili stanka nuzhnyi modelj dinamiki i otkazov, interloki, fizicheskaya ostanovka i telemetriya. Proizvodstvo dobavlyayet roli, priyomku, sertifikaciyu i proiskhozhdeniye; zemnoj poligon — pravo, ekologiyu, soobsjhestva i svorachivaniye; kosmicheskij kontur — zaderzhku svyazi, lokaljnuyu ostanovku i predel rasshireniya materialjnoj bazyi.

## Granica primenimosti

Versiya `1` yavlyayetsya dokumentacionnyim kontraktom, a ne programmnyim validatorom, razreshiteljnyim servisom, inzhenernyim standartom ili pravovyim zaklyucheniyem. Ona ne podklyuchayet ispolniteljnyij vyikhod i ne razreshayet `R1–R4`. V tekusjhem prototipe fakticheskaya rabota ostayotsya v `R0`; primeneniye kartyi k realjnomu ustrojstvu potrebuyet novogo doslovnogo istochnika, predmetnyikh proverok i kompetentnyikh dlya oblasti subyyektov.

Karta ne reshayet, kto vprave podtverzhdatj kazhdyij klass, kakiye roli mozhno sovmesjhatj, kogda simulyator dostatochno tochen i kakiye dejstviya zapresjhenyi nezavisimo ot proverki. Eti granicyi sokhranenyi v shesti svyazannyikh voprosakh ob apparatnoj, issledovateljskoj, vlastnoj, potrebiteljskoj, territorialjnoj i kosmicheskoj avtonomii.

## Proverki

- Soderzhaniye kartyi svereno s dokumentami fizicheskogo dejstviya, decentralizacii, minimaljnoj trassyi, pasporta rezuljtata i napravleniyem fizicheskikh i daljnikh konturov.
- Dvunapravlennaya proverka podtverdila `14` aktivnyikh voprosov i `93` obyyavlennyiye celi; shestj svyazannyikh voprosov ukazyivayut na kartu, a karta sokhranyayet obratnyiye ssyilki na nikh.
- Planovyij reyestr peresobran i validen; fenced-proverka rabochego nabora podtverdila yedinstvennyij `ready` `master-fum-step-0005-ready-v1` i sokhranyonnyij `blocked`.
- Recency, graf Obsidian, svyaznostj rabochej sessii i `git diff --check` proshli; polnyij smoke-check zavershilsya uspeshno: `39` shagov, kod vozvrata `0`.

## Prodolzheniye

`FUM-STEP-0028` zavershena po fakticheskomu rezuljtatu. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0005` yedinstvennyim novyim `ready`. Etot shag mozhet byitj proveren lokaljnoj determinirovannoj zaglushkoj bez seti, sekretov, vneshnego ili fizicheskogo dejstviya i bez nachala korobochnoj stadii.

## Profilj vremeni vyipolneniya

| Stadiya                                    | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                                        |
| ----------------------------------------- | -----------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i dopusk FIFO                 |        0,7 s | Summa nablyudayemogo wall-clock tryokh posledovateljnyikh vyizovov: dva oshibochnyikh bootstrap-vyizova i uspeshnyij `join`; dolgogo ozhidaniya ne byilo.                          |
| Soderzhateljnaya rabota i read-only-analizyi | 19 min 6,8 s | Ot mashinnogo `admitted_at` do okonchateljnogo progona celevyikh proverok; paralleljnyiye analizyi, finaljnoye revjyu i predvariteljnyiye proverki otdeljno ne skladyivayutsya. |
| Finaljnyiye celevyiye proverki                |       13,9 s | Monotonnyij interval `153798,472–153812,336`: reyestr, recency, graf, voprosyi, rabochij nabor, svyaznostj i proverka diff.                                            |
| Predfinaljnyij polnyij smoke-check          | 3 min 12,3 s | Monotonnyij interval `154048,628–154240,894`: povtornyij svezhij progon sokhranil itog `39` shagov i kod vozvrata `0`.                                                 |

Granica profilya: ot uspeshnogo FIFO-dopuska do zaversheniya predfinaljnogo polnogo smoke-check — `26 мин 29,2 с` wall-clock. Ozhidaniye FIFO pokazano otdeljno; pervyij identichnyij polnyij progon ne prinyat kak svideteljstvo iz-za otsoyedineniya terminaljnogo kanala do vyidachi itogovogo koda i poetomu byil povtoryon. Finaljnaya zapisj rezuljtatov, staging i atomarnyij commit+handoff nakhodyatsya posle etoj granicyi.

## Zatronutyiye materialyi

- [karta ogranichitelej fizicheskogo dejstviya FUM](../../Dokumentaciya/40-karta-ogranichitelej-fizicheskogo-dejstviya-FUM.md)
- [fizicheskoye dejstviye FUM i apparatnyiye uzlyi](../../Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [napravleniye fizicheskikh i daljnikh konturov](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/08-fizicheskiye-i-daljniye-konturyi.md)
- [fizicheskoye dejstviye FUM](../../Glossarij/fizicheskoye-dejstviye-FUM.md)
- [vopros o granicakh apparatnoj avtonomii FUM](../../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md)
- [zavershyonnaya kartochka FUM-STEP-0028](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0028-opisatj-kartu-ogranichitelej-fizicheskogo-dejstviya-FUM.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [napravleniye fizicheskikh i daljnikh konturov](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/08-fizicheskiye-i-daljniye-konturyi.md)
- [fizicheskoye dejstviye FUM i apparatnyiye uzlyi](../../Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:fa3764044fb94504e7c01f0f755134e12c0490a6a601c0d44e1b7c50ef8811b3 -->
<!-- FUM-MD-RECENCY:END -->
