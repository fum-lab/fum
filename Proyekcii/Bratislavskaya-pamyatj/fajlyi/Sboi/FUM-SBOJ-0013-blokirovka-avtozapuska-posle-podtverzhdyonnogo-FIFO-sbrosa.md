+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0013"
"статус" = "снята"
+++
# Blokirovka avtozapuska posle podtverzhdyonnogo FIFO-sbrosa

Kartochka istoricheski sokhranyayet nablyudyonnuyu blokirovku sleduyusjhego zapuska posle shtatno zavershyonnogo FIFO-sbrosa. Obsjhaya rezervaciya prezhnego zapuska byila terminalizirovana kak neopredelyonnaya, kartochochnyij claim uzhe otsutstvoval, a novyij idle-vyibor imel druguyu vershinu, nastupleniye i klyuch zapuska, no obsjhij sloj vsyo ravno otvechal sostoyaniyem zanyatoj rezervacii. Periodicheskij heartbeat, dispetcherskaya rezervaciya i claim boljshe ne vkhodyat v dejstvuyusjhuyu arkhitekturu prodolzheniya, poetomu prezhneye ozhidaniye avtozapuska formaljno neprimenimo, a kartochka sokhranyayetsya kak proiskhozhdeniye i regressionnaya granica na sluchaj vozvrata snyatogo mekhanizma.

## Nablyudayemyij sboj

Shtatnyij sbros vyipustil samodostatochnuyu kvitanciyu, annuliroval prezhnego ispolnitelya, ochistil specializirovannyij claim i osvobodil FIFO. Posleduyusjhij heartbeat nashyol kvitanciyu i zavershil prezhnyuyu obsjhuyu rezervaciyu iskhodom `неопределённый`. Na sleduyusjhem dopustimom vyibore obsjhij compare-and-swap ne razlichil etu podtverzhdyonno vosstanovlennuyu terminalizaciyu i obyichnuyu neodnoznachnostj host-vyizova, poetomu ne sozdal novuyu obsjhuyu rezervaciyu i ne doshyol do kartochochnogo claim.

## Granica povtoreniya

Proyavleniye voznikayet pri odnovremennom vyipolnenii chetyiryokh uslovij: susjhestvuyet terminaljnaya obsjhaya rezervaciya `завершён/неопределённый` exact-adaptera `следующий_шаг_ветки`, neizmenyayemaya reset-kvitanciya tochno svyazyivayet yeyo predterminaljnyij reservation-ref/OID s annulirovannyim i neaktivnyim ispolnitelem, specializirovannyij claim posle sbrosa otsutstvuyet, a sleduyusjhij idle-vyibor predstavlyayet novuyu occurrence. Prezhnij kontrakt blokiroval zamenu po odnomu lishj terminaljnomu iskhodu, ne uchityivaya sovokupnoye dokazateljstvo reset-recovery.

Syuda ne otnositsya obyichnaya host-neopredelyonnostj bez tochnoj reset-kvitancii, kvitanciya bez udalyayemogo ograzhdeniya specializirovannogo claim, vernuvshijsya posle otkata staryij claim, povtor toj zhe occurrence ili rezervaciya inogo adaptera. Do obsjhego `bind-run` tochnyim ispolnitelem mozhet byitj toljko soglasovannyij `threadId` iz paryi `threadId`/`hostId`; predvariteljnyij `clientThreadId` ne yavlyayetsya dokazateljstvom. Eti sostoyaniya dolzhnyi i posle ustraneniya ostavatjsya zakryityimi.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                           | Effekt                                                                                                       | Vosstanovleniye                                                                                                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0013/ПРОЯВЛЕНИЕ-0001` | [Diagnostika tekusjhej rabochej sessii](../Zhurnal/2026-08-08_07-56-16_MSK_pochinitj-avtozapusk-FUM/otchyot.md#diagnostika-po-sloyam) fiksiruyet soglasovannyiye sostoyaniya obsjhej rezervacii, claim, kvitancii i novogo vyibora. | Avtozapusk ne proshyol obsjhuyu rezervaciyu posle sbrosa, khotya specializirovannaya ocheredj uzhe byila svobodna.       | Dobavlena uzkaya zamena dlya novoj occurrence po exact-kvitancii i atomarnomu otsutstviyu claim; zhivaya polnaya idle-priyomka ostavlena posleduyusjhemu upravlyayusjhemu nablyudeniyu. |

## Ozhidaniye i klassifikaciya

V snyatom konture eto byil defekt soglasovaniya obsjhego dispetcherskogo fence s kartochochnyim recovery posle sbrosa, a ne oshibka raspisaniya, renderer, zhivogo prompt ili specializirovannogo selector. Dejstvuyusjhij kontur obyazateljnogo prodolzheniya vetki ne sozdayot obsjhuyu rezervaciyu, heartbeat ili kartochochnyij claim i potomu ne nasleduyet etu klassifikaciyu.

## Mekhanizm i sistemnoye ustraneniye

Prezhnij predikat zamenyi obsjhej rezervacii prinimal toljko bezopasnyij otkaz do effekta libo uspeshnuyu zavershyonnuyu druguyu occurrence. Reset-recovery namerenno zavershal prezhnij zapusk kak neopredelyonnyij, poetomu yego bezopasnoye sostoyaniye ne imelo puti k novomu zapusku.

Ustraneniye vosproizvodit obe dopustimyiye predterminaljnyiye formyi prezhnej rezervacii, nakhodit tochnyij OID v proverennoj kvitancii, trebuyet prinadlezhnostj ispolnitelya annulirovannomu i neaktivnomu mnozhestvam i rovno odno udalyayemoye ograzhdeniye ozhidayemogo specializirovannogo claim. Otsutstviye etoj claim-ssyilki proveryayetsya v toj zhe Git-tranzakcii, kotoraya zamenyayet obsjhuyu rezervaciyu. Lyuboye nepolnoye dokazateljstvo vozvrasjhayet prezhnyuyu blokirovku.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                       | Svyazj                                                                                                     | Osnovaniye                       |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0141 — Realizovatj shtatnyij sbros FIFO-ocheredi i rabochej kopii](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0141-realizovatj-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)  | Istoricheskoye osnovaniye; shag ostavlyayet toljko yavnoye poljzovateljskoye vosstanovleniye bez postoyannoj zadachi. | `FUM-СБОЙ-0013/ПРОЯВЛЕНИЕ-0001` |

## Osnovaniye snyatiya

- Dejstvuyusjhij putj prodolzheniya ne soderzhit heartbeat, dispatcher-reservation, idle-vyibor ili kartochochnyij claim: vladelec do kommita sozdayot tochnuyu zadachu-prodolzheniye, podtverzhdayet yeyo ozhidayusjhij bilet i peredayot yej branch-scoped FIFO.
- Prodolzheniye posle handoff perechityivayet novyij `HEAD`, podtverzhdayet vershinu i neposredstvenno vyizyivayet vetochnyij selector; avtomaticheskij reset-recovery prezhnej rezervacii yemu ne trebuyetsya.
- `./sbrositj.sh` ostayotsya otdeljnyim chelovecheskim break-glass, a FUM-STEP-0141 — yavnyim poljzovateljskim vosstanovleniyem; ni odin iz etikh putej ne vozobnovlyayet snyatyij heartbeat.
- Kartochka povtorno aktiviruyetsya toljko pri yavnom vozvrasjhenii prezhnego dispetcherskogo kontura i vosproizvedenii yego blokirovki.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-08_07-56-16_MSK_pochinitj-avtozapusk-FUM/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-08_07-56-16_MSK_pochinitj-avtozapusk-FUM/otchyot.md)
- [FUM-REQ-0028 — Universaljnaya dispetcherizaciya periodicheskikh avtomatizacij](../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [FUM-REQ-0039 — Shtatnyij sbros FIFO-ocheredi i rabochej kopii](../Trebovaniya/🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:45cbdef2539ac5c9e8cc6f88a0bffaf1758bc5d19ece4f9ed7f6f0cfd9884f2e -->
<!-- FUM-MD-RECENCY:END -->
