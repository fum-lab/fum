# Otchyot 2026-09-09 20:29:51 MSK - Zavershitj priyomku ignorirovaniya fajlov macos

`.DS_Store` uzhe isklyuchyon susjhestvuyusjhim `.gitignore`. Realjnaya blokirovka proiskhodila v strogoj proverke proyekcii; yeyo obrabotka ispravlena s sokhraneniyem obyichnyikh ignoriruyemyikh metadannyikh. Ssyilki, katalogi, specialjnyiye i otslezhivayemyiye obyyektyi ostayutsya pod prezhnej strogoj proverkoj.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| ------ | ------------ | ------------------------- |
| Razbor pozdnego otkaza i podgotovka | ne izmereno | Ot otkaza indeksa do neizmennogo kanonicheskogo snimka |
| Adresnyiye proverki | sm. nizhe | Shtatnaya obyortka, otdeljnyiye nablyudayemyiye vyizovyi |
| Standartnyij smoke-check (dokumentacionnyij) | sm. nizhe | Yedinstvennyij finaljnyij sostavnoj zapusk novoj granicyi |

Granica profilya: novyij cikl ot 2026-09-09 20:29:51 MSK do zakryitiya tekusjhego otchyota. Prezhnij cikl 18:43 i yego proverki zamyikaniya ne pribavlyayutsya k etoj summe. Posle zakryitiya vyipolnyayutsya toljko shtatnyiye finaljnyiye primeneniye i proverka proyekcii, proverka snimka, svyaznostj, recency i oba Git diff-check. Kalendarnoye vremya vsej zadachi i budusjhego kommita ne oceneno zadnim chislom.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:524baed251d78d36a622d82dfcdf88bca6643151bbf9a945cb351b5b54417efc -->

| Vyizov                                                                                                          | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj — zamyikaniye priyomki] RED: obnaruzhitj lishnij LF v indeksirovannom izmeritele                            | 0,017 s      | neuspeshno |
| [Korenj — zamyikaniye priyomki] GREEN: proveritj indeksirovannyij izmeritelj posle udaleniya odnogo LF              | 0,017 s      | uspeshno   |
| [Korenj — zamyikaniye priyomki] Sinkhronizirovatj reyestr so sboyem propusjhennoj proverki indeksa                     | 0,353 s      | uspeshno   |
| [Korenj — zamyikaniye priyomki] Podtverditj neizmennostj starogo svideteljstva i chistotu kanonicheskogo indeksa    | 0,109 s      | uspeshno   |
| [Korenj — zamyikaniye priyomki] Proveritj svyaznostj novoj zhurnaljnoj granicyi i obsjhego kommita                     | 38,316 s     | neuspeshno |
| [Korenj — zamyikaniye priyomki] Podtverditj svyaznostj posle dobavleniya obyazateljnoj ssyilki na reyestr instrumentov | 36,51 s      | uspeshno   |
| [Korenj — zamyikaniye priyomki] Proveritj vesj kanonicheskij indeks pered obsjhej priyomkoj                           | 0,029 s      | uspeshno   |
| [Korenj — zamyikaniye priyomki] Standartnaya finaljnaya priyomka obsjhego izmeneniya posle ispravleniya indeksa          | 538,91 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 614,261 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- V [pervom cikle](../2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md) proshli 24 shaga za 649,248 s po vneshnej obyortke; posleduyusjhiye finaljnyiye primeneniye i proverka zanyali 201,36 i 100,22 s. Etot uspekh sokhranyon kak istoricheskoye svideteljstvo prezhnego snimka.
- Pozdnij `git diff --cached --check` zavershilsya kodom 2: lishnyaya pustaya stroka v izmeritele i yego vyivodimoj kopii. Otkaz povtoryon cherez novuyu obyortku do ispravleniya; posle udaleniya odnogo LF adresnaya proverka kanonicheskogo indeksirovannogo fajla proshla.
- [Tochnoye izmeneniye izmeritelya](materialyi/ispravleniye-konca-izmeritelya.json) sokhranyayet dlinyi, SHA i ravenstvo AST. Prezhnij profilj ne perepisan: iskhodnaya versiya vosstanavlivayetsya dobavleniyem odnogo LF.
- Polnaya aktualjnostj obsjhego izmeneniya podtverzhdayetsya toljko finaljnyim standartnyim zapuskom etoj granicyi i posleduyusjhimi proverkami zamyikaniya.

## Resheniya i ogranicheniya

[FUM-SBOJ-0044](../../Sboi/FUM-SBOJ-0044-proverka-indeksa-propusjhena-do-zakryitiya-otchyota.md) ostayotsya aktivnyim: avtomaticheskoj proverki indeksa pered zakryitiyem poka net. [FUM-STEP-0171](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0171-proveryatj-indeks-do-zakryitiya-otchyota.md) sokhranyayet otdeljnuyu sistemnuyu meru. V etoj zadache primenyayetsya yavnaya proverka oboikh diff do zakryitiya i posle finaljnoj proyekcii.

Predmetnyij algoritm posle predyidusjhego uspeshnogo smoke ne menyalsya. Dvojnoj cikl vyizvan propusjhennoj proverkoj indeksirovannogo oformleniya, a ne neobkhodimostjyu povtoritj benchmark. Priyomka arkhiva, ogranichennostj profilya Debug/Release i otkryityiye napravleniya FUMA sokhranyayut granicyi predyidusjhego otchyota. Oba zhurnala vkhodyat v odin lokaljnyij kommit; publikaciya ne vyipolnyayetsya.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Predyidusjhaya priyomka](../2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 20:34:49 MSK -->
<!-- content-sha256: sha256:2a059ee29625b318b140c45134dae928b25790d48098d838599ca6ad48b6806d -->
<!-- FUM-MD-RECENCY:END -->
