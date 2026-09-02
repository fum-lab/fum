# Otchyot 2026-08-06 20:56:43 MSK - Optimizirovatj rabotu testov

Polnyij smoke-check perevedyon na yavnyij fail-fast-poryadok. Posle obsjhej podgotovki on vyipolnyayet tri ispolnyayemyiye fazyi: stabiljnyij prefiks iz 13 repozitornyikh validatorov, analiticheski uporyadochennyiye Python- i Swift-testyi, zatem fiksirovannyij Swift-khvost iz sborok produktov i lint. Oshibka strukturyi zaprosa, otchyota, snimka obyyavlenij, recency, grafa ili svyaznosti teperj ostanavlivayet progon do dorogikh naborov.

Izmeneniye neposredstvenno otvechayet nablyudayemomu profilyu [predyidusjhej rabochej sessii](../2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/otchyot.md): tri smoke-zapuska proshli vse 37 analiticheskikh naborov i lishj zatem upali na snimke obyyavlenij, recency ili svyaznosti. Ikh testovyiye fazyi summarno zanyali `4558,346 с` — okolo 75 minut 58 sekund i `94,146%` polnoj dliteljnosti etikh tryokh neuspeshnyikh zapuskov. Pri novom poryadke te zhe tri prichinyi byili byi obnaruzhenyi do pervogo analiticheskogo testa.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                   |
| ------------------------ | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | okolo 3602 s | Ot registracii bileta v 19:55:29 MSK do dopuska i podtverzhdeniya novogo HEAD okolo 20:55:31 MSK                                               |
| Soderzhateljnaya rabota    | okolo 2437 s | Ot sozdaniya papki sessii v 20:56:43 MSK do nachala pervogo predfinaljnogo polnogo smoke-check okolo 21:37:20 MSK                              |
| Celevyiye proverki         | 141,004 s    | Agregirovannyij call-time 19 adresnyikh zapuskov iz mashinnogo bloka bez tryokh polnyikh smoke-check; paralleljnyiye vyizovyi mogli perekryivatjsya         |
| Polnyij smoke-check       | 1688,207 s   | Monotonnaya dliteljnostj poslednego okhvachennogo vyizova polnogo kontura; tri popyitki vmeste zanyali `1763,284 с` mashinnogo call-time             |
| Atomarnyij commit+handoff | ne izmereno  | Vyipolnyayetsya posle okonchateljnogo zakryitiya otchyota i podtverzhdayetsya otdeljnyim iskhodom ocheredi                                                  |

Granica profilya: ot atomarnoj registracii FIFO-bileta okolo 19:55:29 MSK cherez soderzhateljnuyu rabotu i predfinaljnyij smoke-check do zakryitiya otchyota; posleduyusjhij commit+handoff otmechayetsya kak terminaljnyij iskhod, no yego dliteljnostj v uzhe zakryityij otchyot ne podstavlyayetsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:cc3d9c9057c6bb3dada0b7da44ae77f8c34c75a59adf538ed3293d627639ea90 -->

| Vyizov                                                                           | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] TDD-red: rannij otkaz do dorogikh testovyikh naborov              | 21,485 s     | neuspeshno |
| [kornevoj agent] TDD-green: rannij otkaz do dorogikh testovyikh naborov            | 28,731 s     | uspeshno   |
| [kornevoj agent] TDD-green: fazovyij poryadok polnogo smoke-check                 | 22,82 s      | uspeshno   |
| [kornevoj agent] Kontrakt v2 rannego otkaza polnogo smoke-check                 | 7,731 s      | uspeshno   |
| [kornevoj agent] Svyaznostj aktivnoj v2-zapisi rannego smoke-check               | 2,049 s      | uspeshno   |
| [kornevoj agent] Obnovitj svezhestj Markdown pered polnyim smoke-check            | 0,634 s      | uspeshno   |
| [kornevoj agent] Obnovitj teplovuyu kartu grafa pered polnyim smoke-check         | 0,338 s      | uspeshno   |
| [kornevoj agent] Predfinaljnyij polnyij smoke-check s rannim prefiksom            | 37,331 s     | neuspeshno |
| [kornevoj agent] Lokalizovatj rannij otkaz proverki mashinno-lokaljnyikh putej     | 12,858 s     | neuspeshno |
| [kornevoj agent] Povtorno obnovitj svezhestj Markdown posle rannego otkaza       | 0,596 s      | uspeshno   |
| [kornevoj agent] Povtorno obnovitj teplovuyu kartu grafa posle rannego otkaza    | 0,351 s      | uspeshno   |
| [kornevoj agent] Povtornyij polnyij smoke-check posle ispravleniya rannej oshibki   | 37,746 s     | neuspeshno |
| [kornevoj agent] Inventarizirovatj ostatok obyyavlenij posle pozicionnyikh sdvigov | 4,647 s      | uspeshno   |
| [kornevoj agent] Sravnitj obyyavleniya izmenyonnyikh Python-fajlov s HEAD            | 0,271 s      | uspeshno   |
| [kornevoj agent] Povtorno inventarizirovatj ostatok posle russkikh imyon          | 4,634 s      | uspeshno   |
| [kornevoj agent] Obnovitj snimok ostatka posle proverennyikh pozicionnyikh sdvigov  | 4,441 s      | uspeshno   |
| [kornevoj agent] Proveritj obnovlyonnyij snimok ostatka obyyavlenij                | 4,395 s      | uspeshno   |
| [kornevoj agent] Povtoritj TDD fazovogo poryadka posle russkikh imyon              | 22,022 s     | uspeshno   |
| [kornevoj agent] Povtoritj svyaznostj posle russkogo imeni testa                 | 2,048 s      | uspeshno   |
| [kornevoj agent] Obnovitj svezhestj Markdown posle proverki snimka               | 0,597 s      | uspeshno   |
| [kornevoj agent] Obnovitj teplovuyu kartu grafa posle proverki snimka            | 0,355 s      | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle zamyikaniya rannego prefiksa   | 1688,207 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1904,287 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-red: 58 testov, dva ozhidayemyikh otkaza dokazali prezhnij poryadok «dorogiye naboryi → fiksirovannyiye validatoryi» i zapusk dorogikh naborov do pozdnego otkaza.
- Pervyij TDD-green: 59 testov smoke-check proshli posle vvedeniya priznaka rannej proverki i tryokhfaznogo razbiyeniya.
- Usilennyij TDD-green: 59 testov smoke-check podtverdili tochnyij realjnyij prefiks iz 13 shagov, zapret sovmesjhatj rannij i analiticheskij priznaki, otsutstviye zapuskov Python- i Swift-testov, sborki i lint posle rannego otkaza.
- 40 testov otchyotnoj avtomatizacii podtverdili sokhraneniye iskhodnogo nenulevogo koda, nepustogo analiticheskogo plana i pustyikh nablyudenij pri otkaze do pervogo testa, a takzhe uspeshnyiye `закрыть` i `проверить` dlya takoj zapisi.
- 72 testa svyaznosti podtverdili dopustimostj aktivnoj v2-zapisi toljko s `план: null`, pustyimi nablyudeniyami i terminaljnyimi polyami; aktivnyij nepustoj plan otklonyayetsya.
- Pervyij realjnyij polnyij smoke-check ostanovilsya na proverke mashinno-lokaljnyikh putej, shage 5 iz 76, za `37,260 с`: defis pered kosoj chertoj mezhdu slovami `Python` i `Swift` v dvukh zhurnaljnyikh strokakh byil raspoznan kak absolyutnyij POSIX-putj. Ni odin analiticheskij nabor ne zapuskalsya.
- Povtornyij polnyij smoke-check ostanovilsya na tochnom snimke obyyavlenij, shage 6 iz 76, za `37,669 с`. Inventarj vyiyavil chetyire novyiye latinskiye privyazki `step` i latinskuyu chastj `v2` v imeni testa; posle rusifikacii ostatok vernulsya k tochnyim znacheniyam `43328` obyyavlenij: `460` Mermaid, `16331` Python i `26537` Swift.
- Posle obnovleniya toljko pozicionnogo khyesha snimok proveren otdeljno; povtornyiye 59 testov smoke-poryadka i 72 testa svyaznosti proshli.
- Itogovyij polnyij smoke-check proshyol vse 76 shagov: 13 rannikh repozitornyikh validatorov, 37 analiticheskikh testovyikh naborov i fiksirovannyij khvost iz 26 sborok i lint. Vnutrenneye monotonnoye vremya sostavilo `1688,135 с`, a polnyij mashinnyij vyizov vmeste s otchyotnoj obyortkoj — `1688,207 с`.
- Posle etogo uspeshnogo vyizova mashinnyij sbor zakryit bez novyikh testovyikh zapuskov; otdeljnyiye read-only-proverki zamyikaniya podtverdili snimok otchyota, svyaznostj rabochej sessii, recency, graf i chistotu diff.

## Resheniya i ogranicheniya

- Rannimi sdelanyi toljko uzhe susjhestvuyusjhiye samostoyateljnyiye repozitornyiye validatoryi. Ikh vzaimnyij poryadok sokhranyayet zavisimosti `сборка планового реестра → его проверка`, `машинно-локальные пути → снимок объявлений` i `recency → граф → связность`.
- Analiticheskij plan po-prezhnemu soderzhit toljko naboryi `unittest` i `swift test`; statisticheskaya sortirovka ne smeshivayetsya s fiksirovannyimi fazami.
- Swift-sborki i lint ne obyyavlenyi rannimi: oni sokhranyayut prezhnij poryadok posle analiticheskikh testov, poskoljku eto otdeljnyij priyomochnyij khvost, a nablyudavshiyesya poteri vyizvanyi repozitornyimi validatorami.
- Plan nablyudenij publikuyetsya do pervogo rannego shaga. Poetomu rannij otkaz dokazuyemo otlichim ot oshibki podgotovki: u pervogo yestj nepustoj plan i pustoj prefiks, u vtoroj plan ostayotsya `null`.
- Tochnyij snimok obyyavlenij obnovlyon toljko posle sravneniya s `HEAD`: pyatj novyikh latinskikh obyyavlenij byili ustranenyi, a chislo i yazyikovaya svodka ostatka polnostjyu sovpali s prezhnim snimkom.
- Proverki, susjhestvuyusjhiye toljko vnutri domennogo testovogo nabora, rannimi avtomaticheski ne stanovyatsya. Ikh uskoreniye trebuyet otdeljnogo ustojchivogo samostoyateljnogo validatora, chtobyi smoke-check ne dubliroval vnutrennyuyu realizaciyu testa.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [otchyot predyidusjhej sessii](../2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/otchyot.md)
- [mashinnaya zapisj predyidusjhego smoke №12](../2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/materialyi/zapuski-proverok/12_10ffc076-2000-42a8-8895-2356ccd8b97f.json)
- [mashinnaya zapisj predyidusjhego smoke №18](../2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/materialyi/zapuski-proverok/18_9214641a-d190-49a3-9061-acf8d4fb5ae3.json)
- [mashinnaya zapisj predyidusjhego smoke №21](../2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/materialyi/zapuski-proverok/21_1d271972-cf9d-4d44-8e98-d673e99b35ce.json)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 22:18:41 MSK -->
<!-- content-sha256: sha256:dc918dcac80aea5154012e4e2fb03d5394fcc6d59cb29d171c5d7702380e9c63 -->
<!-- FUM-MD-RECENCY:END -->
