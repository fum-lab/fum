+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0015"
"статус" = "устранена"
+++
# Nedostupnostj sbrosa FIFO dlya vosstanovleniya avtozapuska

Kartochka istoricheski sokhranyayet nablyudyonnoye raskhozhdeniye mezhdu nalichiyem podrobno proverennogo shtatnogo reset-protokola i otsutstviyem dostupnogo cheloveku sposoba dejstviteljno nachatj lokaljnoye ispolneniye zanovo, kogda stale FIFO- i dispatcher-runtime blokiroval prezhnij avtozapusk. Chelovecheskij `./sbrositj.sh` ustranil nedostupnostj lokaljnogo vosstanovleniya, a snyatyij dispatcher-runtime boljshe ne yavlyayetsya konturom, kotoryij nuzhno vozobnovlyatj.

## Nablyudayemyij sboj

Shtatnyij sbros mozhno nachatj toljko iz tochnoj postoyannoj zadachi dispetchera posle polnogo host-inventarya i dokazateljstva neaktivnosti kazhdogo vozmozhnogo pisatelya. Dostupnyij host ne predostavlyayet ni polnogo checkout-scoped inventarya, ni proveryayemogo stop proizvoljnoj zhivoj zadachi, poetomu bezopasnyij marshrut zakryivayetsya do pervoj mutacii. V rezuljtate lokaljnyiye proverki reset-mashinyi prokhodyat, no poljzovatelj ne imeyet prakticheskoj tochki vkhoda dlya ochistki stale queue, reservation, claim i inyikh runtime-svideteljstv i vosstanovleniya sleduyusjhego kartochechnogo zapuska.

## Granica povtoreniya

Proyavleniye voznikayet, kogda tekusjhij lokaljnyij `HEAD` yavlyayetsya zhelayemoj novoj iskhodnoj tochkoj, a obsluzhivayemoye runtime-sostoyaniye etoj vetki soderzhit prezhniye FIFO- ili dispetcherskiye polnomochiya, kotoryiye neljzya shtatno terminalizirovatj cherez dostupnuyu host-poverkhnostj. Obsjhaya sistemnaya mera — otdeljnyij TTY-podtverzhdayemyij chelovecheskij `break-glass`, kotoryij atomarno arkhiviruyet i annuliruyet vsyu tochnuyu scoped runtime-oblastj, a ne pyitayetsya dokazatj ostanovku cherez otsutstvuyusjhij host-kontrakt.

Syuda ne otnositsya FUM-SBOJ-0013: tam dispatcher-only reset uzhe uspeshno zavershilsya, a novaya occurrence blokirovalasj prezhnej terminaljno neopredelyonnoj obsjhej rezervaciyej. Ne otnosyatsya takzhe `PAUSED` host-avtomatizaciya, nablyudayemaya zanyatostj posle lokaljnogo sbrosa i fizicheski prodolzhayusjhij rabotu process: lokaljnyij reset ne yavlyayetsya host-stop ili komandoj `Start`.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                      | Effekt                                                                                                       | Vosstanovleniye                                                                                               |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0015/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij zapros](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md) fiksiruyet prakticheskuyu nevozmozhnostj sbrositj proverennyij runtime radi avtozapuska. | Poljzovatelj ne mozhet vernutj FIFO i svyazannyiye runtime-pokoleniya k iskhodnomu sostoyaniyu tekusjhego `HEAD`.      | Realizovatj kornevoj `sbrositj.sh` s tochnyim TTY-planom, arkhivom, annulyaciyej, tombstone i svezhej ocheredjyu.    |

## Ozhidaniye i klassifikaciya

V istoricheskom konture FUM-REQ-0039 obesjhalo vosstanoviteljnyij sbros, no dostupnaya host-granica delala dispatcher-only marshrut neprigodnyim dlya realjnogo vosstanovleniya. Dejstvuyusjhij FUM-REQ-0039 ostavlyayet toljko otdeljnoye yavno poljzovateljskoye vosstanovleniye FIFO i rabochej kopii; ono ne oslablyayet obyichnyij FIFO i ne zapuskayet prodolzheniye avtomaticheski.

## Mekhanizm i sistemnoye ustraneniye

Prichina — obyyedineniye dvukh nesovmestimyikh celej v yedinstvennom marshrute: obyichnyij reset obyazan dokazatj ostanovku vozmozhnyikh pisatelej i sokhranitj recovery, togda kak avarijnoye nachalo zanovo dolzhno pozvolitj cheloveku soznateljno annulirovatj prezhniye lokaljnyiye polnomochiya dazhe bez takogo dokazateljstva.

Sistemnoye ustraneniye vvodit otdeljnyij kornevoj launcher. On podtverzhdayet polnyij tochnyij plan pri TTY odnovremenno na stdin i stdout, sokhranyayet raw OID v neispolnyayemom arkhive, ograzhdayet perekhod, bezopasno vosstanavlivayet worktree k `HEAD`, ochisjhayet aktivnuyu runtime-oblastj, sozdayot novyiye queue epoch/boundary i checkout-scoped tombstone prezhnikh ispolnitelej. Validnyiye official reset receipts sokhranyayutsya, povrezhdyonnyiye arkhiviruyutsya i udalyayutsya, a human receipt pomesjhayetsya v otdeljnoye namespace i pozvolyayet vosstanovitj tochnyij terminaljnyij iskhod bez povtornoj mutacii. Etot break-glass ne vosstanavlivayet snyatyij heartbeat i ne sozdayot zadachu-prodolzheniye.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                        | Svyazj                                                                                          | Osnovaniye                       |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0144 — Dobavitj kornevoj podtverzhdayemyij sbros FIFO i avtozapuska](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0144-dobavitj-kornevoj-podtverzhdayemyij-sbros-FIFO-i-avtozapuska.md)             | Realizuyet otdeljnyij chelovecheskij marshrut i yego regressionnuyu granicu.                          | `FUM-СБОЙ-0015/ПРОЯВЛЕНИЕ-0001` |

## Kriterii zakryitiya

- Kornevoj launcher i avtonomnyiye fiksturyi dokazyivayut obyazateljnostj TTY odnovremenno na stdin i stdout i nevozmozhnostj sluchajnogo libo neinteraktivnogo primeneniya.
- Tochnyij plan, arkhiv, reset-fence, cleanup i terminaljnaya CAS proverenyi na drift, crash-retry, neizvestnyikh runtime refs, SHA-1 i SHA-256.
- Validnyiye official reset receipts sokhranyayutsya kak istoricheskiye dokazateljstva; povrezhdyonnyiye ne blokiruyut novuyu granicu, a kvitanciya ruchnogo sbrosa ne podmenyayet obyazateljnoye prodolzheniye vetki i idempotentno vosproizvodit uzhe sostoyavshijsya terminaljnyij iskhod.
- Staryiye queue/claim/reservation/repair-pokoleniya i povtornyij `join` annulirovannoj zadachi otklonyayutsya, a novyij ispolnitelj poluchayet svezhij dopusk.
- Posle sbrosa nikakoj avtomaticheskij selector ne zapuskayetsya; daljnejshuyu rabotu nachinayet otdeljnyij yavnyij poljzovateljskij zapros.
- Dokumentaciya ne smeshivayet lokaljnuyu annulyaciyu s host-stop i sokhranyayet FUM-REQ-0039 i FUM-STEP-0141 kak otdeljnuyu nezavershyonnuyu zhivuyu priyomku poljzovateljskogo vosstanovleniya.

## Rezuljtat ustraneniya

Kornevoj `./sbrositj.sh` i yego TDD-kontur realizovali otdeljnyij dostupnyij cheloveku marshrut bez host-stop-predusloviya. Polnyiye profiljnyiye naboryi podtverdili TTY i exact-plan, crash-safe cleanup, raw archive, checkout-scoped tombstone, terminal replay, atomarnyij symbolic `HEAD` i svezhuyu ocheredj. Prezhnij dispatcher-only reset sokhranyayetsya toljko kak istoricheskaya realizaciya i ne poluchayet novyikh polnomochij.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/otchyot.md)
- [FUM-REQ-0041 — Podtverzhdayemyij ruchnoj sbros FIFO i avtozapuska k tekusjhemu HEAD](../Trebovaniya/✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md)
- [FUM-REQ-0039 — Shtatnyij sbros FIFO-ocheredi i rabochej kopii](../Trebovaniya/🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:739731be888f0b30c150208af010d2574e422e3f2ef31a3f3fd67e29097aa103 -->
<!-- FUM-MD-RECENCY:END -->
