# Otchyot 2026-09-16 16:25:45 MSK - Svyazatj prinyatiye delegacii s rabotoj

Realizovan [yavnyij priyom](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/prinyatiye-delegacii.md) odnogo nezavisimo vyibrannogo porucheniya i proverka yego pokryitiya susjhestvuyusjhej rabotoj v1. Nulevoj ostatok chelovecheskikh soobsjhenij boljshe ne skryivayet sokhranyonnoye prinyatiye bez rabotyi. Novaya zapisj ne khranit status vyipolneniya; kornevoye chelovecheskoye osnovaniye proveryayetsya otdeljno ot sobstvennogo osnovaniya ispolnitelya.

Osnovnoj RED na starom guard vosproizvyol `0 / завершить` vmesto ozhidayemogo 2: prezhnij razovyij plan zavershyon, chelovecheskij ostatok raven nulyu, otdeljnoye prinyatiye susjhestvuyet, rabotyi net. Pervyij otkaz — semanticheskij `0 != 2`, a ne neizvestnyij flag ili oshibka importa. Posle ispravleniya prinyatiye bez pokryitiya vozvrasjhayet 2, dostupnaya rabota — 3 i tochnyij identifikator.

Realjnyij vyibrannyij R proveren prezhnim chitatelem v3 po zakreplyonnomu genezisu. [Akt ispolnitelya](../../Planirovaniye/zadachi/01a08d6a-4df0-7cb3-9bc4-ebd730a44882/prinyatiye-delegacii.json) sokhranyon otdeljnyim yavnyim vyizovom, zatem zaregistrirovana rabota `принятый-объём-координатора`. Realjnyiye vyizovyi podtverdili 2 do registracii i 3 posle neyo. Zaversheniye etoj podgotovki ne zakryivayet kornevuyu rabotu koordinatora.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Proverka vyibrannogo R | 2,391 s | Odin monotonnyij zamer polnogo DAG, reyestra i istochnika |
| Realjnyij guard do optimizacii | 5,260 s | Odin process, susjhestvuyusjhij plan, JSONL i dva obkhoda R |
| Realjnyij guard posle optimizacii | 3,318 s | Odin process, odin obkhod R i povtornaya sverka vyibrannogo blob, lokaljnyikh vkhodov i HEAD |
| Adresnyiye zapuski | po tablice nizhe | Monotonnoye vremya obyazateljnoj obyortki |
| Polnyij smoke i nativnyij Stop | ne vyipolnyalisj | Kontroljnaya tochka; otdeljnaya priyomka ostayotsya koordinatoru |

Granica profilya: eto otdeljnyiye nablyudeniya na realjnom sobstvennom dereve i istochnike, bez ochistki fajlovogo kyesha OS i bez statisticheskogo vyivoda. Povtornyij obkhod neizmenyayemogo R okazalsya izbyitochnyim; on zamenyon chteniyem i proverkoj vyibrannogo istochnika, pri sokhranenii polnoj pervonachaljnoj proverki DAG i zaklyuchiteljnoj sverki lokaljnyikh vkhodov. Tryokhsekundnyij byudzhet ne podtverzhdyon.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                             | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------- | ------------ | --------- |
| [Korenj 0154] RED prinyatiye bez rabotyi                             | 1,525 s      | neuspeshno |
| [Korenj 0154] GREEN prinyatiye bez rabotyi                           | 2,058 s      | neuspeshno |
| [Korenj 0154] Svyazj prinyatiya i otricateljnyiye granicyi              | 14,231 s     | neuspeshno |
| [Korenj 0154] RED sostav perenosimogo komplekta                   | 24,86 s      | neuspeshno |
| [Korenj 0154] GREEN svyazi i otkazov                               | 14,918 s     | uspeshno   |
| [Korenj 0154] GREEN zamyikaniye komplekta                           | 25,152 s     | uspeshno   |
| [Korenj 0154] Profilj mosta i rasshirennyiye granicyi                 | 3,461 s      | uspeshno   |
| [Korenj 0154] Vyibrannyij istochnik R i profilj realjnogo DAG        | 2,505 s      | uspeshno   |
| [Korenj 0154] Granicyi vyibrannoj revizii i pozdnej mutacii         | 22,31 s      | uspeshno   |
| [Korenj 0154] Realjnoye prinyatiye bez pokryitiya: ozhidayetsya kod 2     | 2,672 s      | uspeshno   |
| [Korenj 0154] Realjnaya rabota i profilj dopuska do optimizacii    | 5,369 s      | uspeshno   |
| [Korenj 0154] Profilj dopuska posle isklyucheniya povtornogo DAG     | 3,471 s      | uspeshno   |
| [Korenj 0154] Regressiya mosta, dopuska i zakreplyonnogo reyestra    | 64,246 s     | uspeshno   |
| [Korenj 0154] Polnyij DAG: prezhniye granicyi vyibrannogo chteniya       | 15,961 s     | neuspeshno |
| [Korenj 0154] Finaljnaya adresnaya sverka izmenyonnogo DAG i mosta   | 39,83 s      | uspeshno   |
| [Korenj 0154] Russkiye obyyavleniya novogo mosta                     | 0,091 s      | neuspeshno |
| [Korenj 0154] Publikacionnaya chistota mosta                        | 22,466 s     | uspeshno   |
| [Korenj 0154] Russkiye obyyavleniya: isklyuchyon vneshnij unittest setUp | 0,088 s      | uspeshno   |
| [Korenj 0154] RED utrata prinyatiya do pervogo kommita              | 1,856 s      | neuspeshno |
| [Korenj 0154] GREEN utrata do kommita i regressiya prinyatij        | 22,186 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 289,256 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Osnovnyiye 11 testov pokryivayut nezavisimyij vkhod, UUID/SHA, chuzhoye osnovaniye, udaleniye i vosstanovleniye prinyatiya, idempotentnostj, pozdnyuyu mutaciyu i vyibrannyij R vne predkov HEAD. Adresnaya regressiya mosta, guard i v3: 42 testa, uspeshno. Zamyikaniye komplekta: RED obnaruzhil otsutstviye novogo iskhodnika, GREEN podtverdil 22 testa. Komplekt teperj soderzhit 12 iskhodnikov; prezhniye sokhranyonnyiye komplektyi ne perepisyivayutsya.

Promezhutochnyiye oshibki realizacii (tuple vmesto bajtov i neperekhvachennyij tip oshibki) ustranenyi. Popyitka zapuska testov cherez cProfile obnaruzhila oshibku fiksturyi, no sam cProfile vernul 0; zelyonaya mashinnaya stroka etogo vyizova ne dokazyivayet uspekh testov. Fikstura ispravlena, obyichnyij unittest zatem podtverdil 11 testov. Syiroj profilj etogo nepolnogo zapuska ne ispoljzuyetsya kak dokazateljstvo proizvoditeljnosti.

Regressiya polnogo DAG i smeshannoj istorii snachala obnaruzhila nepolnyij spisok iskhodnikov v izolirovannoj fiksture. Posle yego ispravleniya adresnaya sverka DAG, smeshannoj istorii i mosta proshla 34 testa. Proverka russkikh obyyavlenij ispravila dva novyikh imeni testov; vneshnij metod unittest `setUp` sokhranyon.

Koordinator obnaruzhil okno udaleniya prinyatiya do pervogo Git-kommita. Otdeljnyij RED posle uspeshnogo priyoma bez kommita podtverdil lozhnyij 0. Ispravleniye trebuyet susjhestvuyusjhego prinyatiya pri nezavisimo vyibrannom poruchenii: utrata fajla zakryivayet dopusk. Povtornyij adresnyij nabor iz 12 testov proshyol. Do pervogo kommita odnovremennoye udaleniye fajla i vneshnego vyibrannogo vkhoda ostayotsya nerazlichimyim s otsutstviyem delegacii; fsync ne vyidayotsya za zakrepleniye istorii.

Nezavisimyij obzor obnaruzhil nepolnoye zamyikaniye komplekta i otsutstviye fsync roditeljskoj cepochki; oba ispravlenyi. Obzor ne yavlyayetsya kornevoj priyomkoj. Pered checkpoint vyipolnyayutsya publikacionnaya chistota, aktualizaciya recency, exact diff i svyaznostj s otkryityim mashinnyim zhurnalom.

## Resheniya i ogranicheniya

Polnota toljko otnositeljno sokhranyonnogo proveryayemogo prinyatiya. Nesokhranyonnyiye razgovornyiye prinyatiya ne obnaruzhivayutsya; XML i proizvoljnyij tool-output polnomochij ne dayut. Polnyij DAG proveryayet vse roditeljskiye ryobra. Dlya ispolneniya ostayotsya prezhnij v1: svobodnoye svideteljstvo zaversheniya ne podmenyayet stroguyu kornevuyu priyomku. Novaya skhema obyazateljstv i vtoroj reyestr statusov ne sozdayutsya.

Podgotovitelj i adapter poka ne zakreplyayut vyibrannyij tuple v native-konfiguracii; ochisjhennoye okruzheniye komplekta yego ne perenosit. Pri susjhestvuyusjhem prinyatii otsutstviye vkhoda zakryivayet dopusk. Hooks/Trust i fakticheskij zapusk Stop ne proverenyi. Proyekciya ostayotsya pokoleniyem bazyi 25e77b49e78e6ba326af566c84ae3a85290a7474 i otstayot ot etogo kanonicheskogo izmeneniya; kontroljnaya tochka ne zayavlyayet finaljnuyu gotovnostj.

## Istochniki

- [Zapros i sluzhebnyiye utochneniya](zapros.md).
- [Nezavisimo vyibrannyij vkhod](materialyi/vyibrannyij-vkhod.json).
- [Plan ispolneniya](materialyi/prodolzheniye.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 16:55:43 MSK -->
<!-- content-sha256: sha256:d923d1e29472ab491c2230f1420671efccdab183e1cc869c1005837d50a1fb62 -->
<!-- FUM-MD-RECENCY:END -->
