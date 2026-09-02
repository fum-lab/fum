# MVP-kandidat: adresnyiye opisaniya i pasporta auditorij

## Pasport

- Status: [MVP-kandidat](../../../Glossarij/MVP-kandidat.md).
- Gorizontyi dorozhnoj kartyi: [vosproizvodimyiye avtomatizacii](../../dorozhnaya-karta.md) i podgotovka k lichnomu agentu.
- Poljzovatelj: chelovek, kotoromu nuzhno obyyasnitj FUM raznyim auditoriyam bez poteri svyazej s istochnikami.
- Minimaljnyij rezuljtat: vosproizvodimaya sborka adresnogo opisaniya iz dokumentacii, glossariya, otkryityikh voprosov i pasporta auditorii.

## Produktovaya ideya dlya zapuska

Produkt: **Generator adresnyikh opisanij FUM** - vosproizvodimaya sborka versii proyekta dlya konkretnoj auditorii bez otryiva ot istochnikov.

Pervyij poljzovatelj - uchastnik proyekta, kotoromu nuzhno pokazatj FUM investoru, razrabotchiku, issledovatelyu ili drugomu adresatu i ne prevratitj opisaniye v otdeljnyij istochnik trebovanij ili reklamnoye obesjhaniye.

Pervyij scenarij zapuska: poljzovatelj vyibirayet auditoriyu i pasport ogranichenij. Generator beryot utverzhdennyiye materialyi iz `Документация/`, `Глоссарий/`, `Вопросы/` i papok zaprosov v `Журнал/`, peresobirayet polnyij Markdown-fajl opisaniya, dobavlyayet pasport auditorii, istochniki, ogranicheniya i obnovlyayet indeks `Описания/README.md`.

Sostav pervogo reliza:

- komanda ili yavnyij scenarij peresborki odnogo opisaniya cherez zakreplyonnuyu avtomatizaciyu;
- pasport auditorii s celjyu, adresatom, nedopustimyimi utverzhdeniyami i tonom;
- karta tezisov so statusami: trebovaniye, gipoteza, risk, otkryityij vopros;
- polnaya peresborka fajla opisaniya vmesto tochechnoj ruchnoj pravki;
- lokaljnaya proverka otnositeljnyikh ssyilok.

Kriterij gotovnosti k zapusku: odin adresnyij fajl mozhno peresobratj celikom tak, chtobyi klyuchevyiye utverzhdeniya imeli istochniki, ogranicheniya byili vidnyi v nachale, a proverka ssyilok prokhodila lokaljno.

## Pochemu eto mozhet byitj pervyim MVP

Adresnyiye opisaniya byistro pokazyivayut prakticheskuyu cennostj svyaznoj pamyati: odin i tot zhe istochnik trebovanij mozhet davatj raznyiye proizvodnyiye tekstyi dlya investora, inzhenera, issledovatelya ili poljzovatelya. Yesli avtomatizaciya rabotayet chestno, ona ne pridumyivayet status proyekta, a vyibirayet i uporyadochivayet uzhe zafiksirovannyiye tezisyi.

Etot kandidat osobenno demonstriruyem vneshnim lyudyam, potomu chto rezuljtat lyogko prochitatj. Yego risk v tom, chto opisaniye mozhet nachatj zvuchatj ubediteljneye, chem pozvolyayet tekusjhij status proyekta, poetomu svyazj s istochnikami i ogranicheniyami dolzhna byitj strogoj.

## Proveryayemyij MVP

Minimaljnyij variant dolzhen umetj:

- prinyatj pasport auditorii: adresat, celj, ogranicheniya, nedopustimyiye utverzhdeniya;
- vyibratj yavnyij nabor istochnikov iz `Документация/`, `Глоссарий/`, `Вопросы/` i papok zaprosov v `Журнал/`;
- sobratj kartu tezisov so statusami: trebovaniye, arkhitekturnaya gipoteza, risk, otkryityij vopros;
- sozdatj polnyij Markdown-fajl opisaniya, a ne tochechno pravitj staryij tekst;
- ukazatj primenennuyu [avtomatizaciyu FUM](../../../Glossarij/avtomatizaciya-FUM.md), istochniki i ogranicheniya;
- obnovitj indeks `Описания/README.md`.

## Kriterii priyomki

- V opisanii net kommercheskikh, tekhnicheskikh ili yuridicheskikh faktov, kotoryikh net v istochnikakh.
- Vse klyuchevyiye utverzhdeniya imeyut ssyilki na dokumentaciyu, glossarij ili otkryityiye voprosyi.
- Pasport auditorii nakhoditsya v nachale fajla.
- Yesli opisaniye obnovlyayet susjhestvuyusjhij fajl, rabochaya sessiya fiksiruyet polnuyu peresborku.
- Proverka otnositeljnyikh ssyilok prokhodit lokaljno.

## Ne vkhodit v pervyij variant

- Avtomaticheskaya generaciya reklamnyikh obesjhanij.
- Publikaciya, rassyilka ili vneshneye prodvizheniye opisanij.
- Sozdaniye novyikh trebovanij vnutri adresnogo teksta bez perenosa v dokumentaciyu.

## Zavisimosti

- Zakreplyonnaya avtomatizaciya [postroyeniya opisaniya FUM dlya adresata](../../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md).
- Tekusjhaya svyaznostj dokumentacii i glossariya.
- Pravilo, chto adresnyiye opisaniya ne pravyatsya tochechno vruchnuyu.

## Riski

- Siljnaya upakovka mozhet skryitj nezrelostj realizacii, yesli ne uderzhivatj status i ogranicheniya.
- Raznyiye auditorii mogut trebovatj konfliktuyusjhikh akcentov; takiye konfliktyi dolzhnyi vozvrasjhatjsya v dokumentaciyu ili voprosyi.
- Avtomatizaciya dolzhna ostavatjsya proveryayemoj, a ne prevrasjhatjsya v skryituyu ruchnuyu redakturu.

## Pervyij eksperiment

Pervyij eksperiment zavershyon polnoj peresborkoj [opisaniya FUM dlya razrabotchikov PO](../../../Opisaniya/dlya-razrabotchikov-PO.md) cherez zakreplyonnyij profilj s yavnyim naborom vkhodov. Rezuljtat razlichayet prinyatyij arkhivator, dva dejstvuyusjhikh issledovateljskikh Swift-prototipa, proyektiruyemuyu korobochnuyu formu i otkryityiye granicyi; kandidat pri etom ne stanovitsya aktivnyim MVP i ne vvodit samostoyateljnyikh trebovanij.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)

## Opornyiye materialyi

- [Opisaniya FUM dlya adresatov](../../../Dokumentaciya/18-opisaniya-FUM-dlya-adresatov.md)
- [Postroyeniye opisaniya FUM dlya adresata](../../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md)
- [Opisaniye FUM dlya investorov](../../../Opisaniya/dlya-investorov.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:b3a2f77f848bbccdb05536c00b881d7214602ab794f71aacf5d55402f58fdb0f -->
<!-- FUM-MD-RECENCY:END -->
