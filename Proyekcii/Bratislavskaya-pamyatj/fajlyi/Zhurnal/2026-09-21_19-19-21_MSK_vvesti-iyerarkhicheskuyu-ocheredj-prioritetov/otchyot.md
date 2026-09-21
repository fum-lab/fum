# Otchyot 2026-09-21 19:19:21 MSK - Vvesti iyerarkhicheskuyu ocheredj prioritetov

Vvedyon read-only prototip iyerarkhicheskoj ocheredi s vosproizvodimyim zhurnalom
sobyitij. Obsuzhdeniye poluchayet dolgovechnuyu mashinnuyu formu: kazhdoye sobyitiye nesyot
nomer, vremya i istochnik zadachi s iskhodnyim soobsjheniyem, a povrezhdyonnyij ili
nepolnyij zhurnal otklonyayetsya do vyibora. Gotovyiye shagi ranzhiruyutsya obyyasnimyim
leksikograficheskim vektorom: klass, yavnyij prioritet, razblokirovaniye,
srochnostj, vozrast, obratnaya stoimostj i stabiljnyij identifikator.

Postoyannuyu vetku `trebovaniya` na etom etape ne sozdaval. Kanonicheskiye atomarnyiye
trebovaniya uzhe nakhodyatsya v `Требования/`, a dostavka i posledovateljnaya
fiksaciya prinadlezhat `planirovaniye`. Novaya vetka opravdana toljko pri
dokazannoj nezavisimoj granice pisatelya, priyomki i publikacii; poka ona
dobavila byi vtorogo vladeljca i risk raskhozhdeniya. Resheniye peredayotsya vladeljcu
planirovaniya kak otkryitoye arkhitekturnoye rassmotreniye, a ne kak prinyatoye
trebovaniye.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                           |
| ------------------------ | ------------ | -------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | 0 s          | Otdeljnyij FIFO ne zapuskalsya: `manual-sequential-v1`                 |
| Soderzhateljnaya rabota    | 3788 s       | 19:19:21–20:22:29 MSK, monotonnaya granica rabochej sessii             |
| Celevyiye proverki         | 2627,66 s    | Summa 13 pryamyikh obyornutyikh zapuskov; posledovateljnyiye vyizovyi          |
| Polnyij smoke-check       | 1756,700 s   | Finaljnyij zapusk, `26/26`, monotonnyij wall-clock                     |
| Atomarnyij commit+handoff | posle zakryitiya | Budet izmeren otdeljno posle snimka i proverki staged-sostava        |

Granica profilya: 2026-09-21 19:19:21–20:22:29 MSK; ozhidaniye FIFO otsutstvovalo,
finaljnaya peredacha yesjhyo ne vkhodila v etot interval.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:98eef847ce7a6eed260bdc49932d75c23e92ae3c9ac37593d6cba9f24a30b66d -->

| Vyizov                                                        | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------ | ------------ | --------- |
| [korenj] TDD testyi iyerarkhicheskoj ocheredi                     | 0,073 s      | uspeshno   |
| [korenj] Proverka imyon avtomatizacii                         | 2,882 s      | uspeshno   |
| [korenj] CLI vyibor i vosproizvedeniye ocheredi                 | 0,145 s      | uspeshno   |
| [korenj] Profilj vyibora 1000 kandidatov                      | 0,056 s      | uspeshno   |
| [korenj] Standartnyij smoke-check dokumentacionnogo prototipa | 17,025 s     | neuspeshno |
| [korenj] Povtornyij standartnyij smoke-check                   | 15,829 s     | neuspeshno |
| [korenj] Tretij standartnyij smoke-check                      | 16,269 s     | neuspeshno |
| [korenj] Finaljnyij standartnyij smoke-check                   | 15,754 s     | neuspeshno |
| [korenj] Finaljnyij smoke-check posle fiksacii okhvata         | 84,193 s     | neuspeshno |
| [korenj] Smoke-check posle obnovleniya metok                  | 92,145 s     | neuspeshno |
| [korenj] Finaljnyij smoke-check s ustojchivoj recency          | 626,51 s     | neuspeshno |
| [korenj] Smoke-check posle svyaznosti i trailer               | 1756,779 s   | uspeshno   |
| [korenj] Finaljnyij smoke-check okonchateljnogo otchyota         | 1914,231 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 4541,891 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Vosstanovleniye JSONL vyipolneno read-only: rezuljtat soderzhit `непроверенный_хвост=0`; iskhodnyij vyivod sokhranyon vne checkout.
- TDD-nabor novogo instrumenta soderzhit 8 testov: iyerarkhicheskij poryadok, isklyucheniye nepodgotovlennyikh kandidatov, zavisimosti, vozrast, nasledovaniye, stabiljnuyu razvyazku, otkaz povrezhdyonnogo vkhoda i vosproizvedeniye zhurnala s proiskhozhdeniyem.
- Dolgovremennaya pamyatj ne podmenyayetsya svodkoj: tochnyiye poljzovateljskiye soobsjheniya sokhranenyi v `запрос.md` i v privatnom JSONL-pakete etapa; sobyitiya ocheredi trebuyut `источник.задача` i `источник.сообщение`.
- Finaljnyij smoke-check `e1f050a7-bcd3-480f-87b3-45286652c668` proshyol `26/26`; bratislavskaya proyekciya ustanovlena dlya `11959` fajlov, plan `sha256:87eccf75fc500f8b8ecff95ebd2b158a2b70aea3203ecd057f0f475396027205`, nezavisimyij manifest dejstvitelen.
- Odinnadcatj predshestvuyusjhikh zapuskov sokhranenyi s iskhodami: ranniye otkazyi byili vyizvanyi nepolnyim okhvatom novyikh materialov, ustarevshej recency, otsutstvuyusjhej ssyilkoj na `Proyekcii/**` i trailer; kazhdyij otkaz ispravlen posleduyusjhim proveryayemyim progonom i ne skryit.

## Resheniya i ogranicheniya

- Iyerarkhiya ne yavlyayetsya skalyarnyim rejtingom: prioritetyi sravnivayutsya po fiksirovannomu vektoru i obyyasnyayutsya v rezuljtate.
- Priostanovlennyiye, zablokirovannyiye, ruchnyiye, zavershyonnyiye i zavisimyiye ot nezavershyonnyikh shagov kandidatyi ne vyibirayutsya.
- Vyibor ne sozdayot zadachi, vetki, lease ili pravo zapisi; pisatelj povtorno proveryayet svezhestj `HEAD`, vladeniye derevom i kartochku.
- Sleduyusjhij etap: svyazatj vyibrannyij vektor s kartochkami `Планирование/`, dolgovremenno dostavitj prinyatoye resheniye vladeljcu `planirovaniye` i otdeljno reshitj, nuzhna li vetka `trebovaniya`.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-21 20:23:03 MSK -->
<!-- content-sha256: sha256:41bac98ec2fb28257b1622293b5f9f5da030afca7d3a0c32ccfeed066f4d3440 -->
<!-- FUM-MD-RECENCY:END -->
