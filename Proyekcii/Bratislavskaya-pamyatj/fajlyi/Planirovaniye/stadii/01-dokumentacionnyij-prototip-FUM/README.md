# Stadiya: dokumentacionnyij prototip FUM

Na etoj stadii sam repozitorij yavlyayetsya [dokumentacionnyim prototipom FUM](../../../Glossarij/dokumentacionnyij-prototip-FUM.md). On yesjhyo ne yavlyayetsya gotovoj [korobochnoj realizaciyej FUM](../../../Glossarij/korobochnaya-realizaciya-FUM.md), no uzhe pokazyivayet obyazateljnyiye svojstva budusjhego uzla: vkhod sokhranyayetsya kak istochnik, resheniya poluchayut proiskhozhdeniye, proveryayemyiye dejstviya oformlyayutsya lokaljnyimi avtomatizaciyami, a rezuljtat vozvrasjhayetsya v dolgovremennuyu [pamyatj FUM](../../../Glossarij/pamyatj-FUM.md).

Ekspluatacionnyij status: tekusjhaya stadiya ispoljzuyet ruchnuyu posledovateljnuyu skhemu «odna poljzovateljski zapusjhennaya pishusjhaya sessiya — odin rezuljtat — ne boleye odnogo lokaljnogo kommita». Opisannyiye nizhe continuation, FIFO, selector i atomarnaya peredacha sokhranyayut istoriyu prezhnego povedencheskogo prototipa i ne yavlyayutsya dejstvuyusjhim marshrutom.

V soderzhateljnom priblizhenii osnovnoj smyislovoj nositelj etoj stadii - tekst, porozhdayemyij v sovmestnom konture cheloveka i LLM. Doslovnyiye [iskhodnyiye zaprosyi](../../../Glossarij/iskhodnyij-zapros.md) sokhranyayut formulirovki cheloveka, a LLM vo vneshnej agentskoj sessii Codex porozhdayet i pererabatyivayet proizvodnyiye tekstyi. Otdeljnaya sessiya Codex ne yavlyayetsya sobstvennyim runtime FUM, odnako polnyij kontur Git + Codex s obyazateljnyim prodolzheniyem vetki, pryamyim vyiborom sleduyusjhego shaga, strogoj FIFO-ocheredjyu i atomarnoj peredachej uzhe yavlyayetsya povedencheskim prototipom vozobnovlyayemogo [agentskogo cikla](../../../Glossarij/agentskij-cikl.md) na masshtabe diskretnyikh zadach i kommitov. Prezhnij periodicheskij heartbeat otnositsya toljko k istorii etogo prototipa.

Poljzovateljskaya zadacha v etom prototipe mozhet izmenitj pamyatj, trebovaniya i posleduyusjhuyu nablyudayemuyu trayektoriyu vetki. Granica tekusjhej formyi prokhodit vnutri dopusjhennoj zadachi: FIFO ne vyitesnyayet yeyo v realjnom vremeni, a chelovecheskij vvod stanovitsya dostupen preimusjhestvenno posle otpravki novogo soobsjheniya-zadachi, a ne kak razreshyonnyij potok sobyitij vo vremya rabotyi.

[Iskhodnyij zapros 2026-07-24 10:44:28 MSK](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) razreshil nachatj otdeljnyij inzhenernyij putj k korobochnomu FUM s minimaljnogo bezokonnogo Swift-kontura. Sozdannyij [prototip vosproizvodimogo popolneniya pamyati](../../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) yavlyayetsya ispolnyayemyim bootstrap ryadom s dokumentacionnoj stadiyej, no ne prevrasjhayet yeyo avtomaticheski v zavershyonnuyu i ne yavlyayetsya produktovyim relizom.

## Chto realizuyetsya zdesj

- Svyaznaya pamyatj: papki zaprosov v `Журнал/`, `Документация/`, `Глоссарий/`, `Вопросы/`, `Источники/`, `Планирование/` i Git-istoriya.
- Lokaljnyiye avtomatizacii: `fum-svezhestj-markdown`, `fum-svyaznostj-rabochej-sessii`, `fum-reyestr-planirovaniya`, `fum-materialyi-zaprosov`, `fum-kompleksnaya-proverka-repozitoriya` i drugiye proveryayemyiye instrumentyi.
- Chelovekochitayemoye planirovaniye: [dorozhnaya karta](../../dorozhnaya-karta.md), [svodnaya tablica](../../svodnaya-tablica-trebovanij-i-realizacij.md), [napravleniya](../../napravleniya-proyektirovaniya-i-razvitiya/README.md), [MVP-kandidatyi](../../MVP-kandidatyi/README.md), [predlozheniya o sleduyusjhikh shagakh](../../predlozheniya-o-sleduyusjhikh-shagakh.md).
- Proveryayemaya rabochaya sessiya: iskhodnyij zapros, zhurnal, spisok zatronutyikh fajlov, ispoljzovannyiye instrumentyi, recency-metki, proverka svyaznosti i kommit.
- Povedencheskij cikl diskretnyikh zadach: zavershayusjhayasya kommitom zadacha zaraneye sozdayot tochnoye prodolzheniye toj zhe vetki, FIFO serializuyet dopusk, atomarnaya peredacha svyazyivayet rezuljtat s uzhe susjhestvuyusjhej zadachej, a prodolzheniye posle perechityivaniya `HEAD` neposredstvenno vyibirayet sleduyusjhij shag.

## Granicyi stadii

Dokumentacionnyij prototip ne dolzhen vyidavatj planovuyu ili ruchnuyu proceduru za gotovyij produktovyij runtime. Yesli trebovaniye poka podderzhivayetsya Markdown-fajlom, skriptom, vneshnim Codex-konturom ili pravilom sessii, eto nuzhno pryamo otlichatj ot budusjhego vstroyennogo servisa korobochnoj FUM. Takoye razlichiye ne otmenyayet uzhe proveryayemoye povedeniye cikla, a tochno ogranichivayet yego tekusjhuyu granulyarnostj diskretnyimi zadachami i kommitami.

Na etoj stadii ne rasshiryayutsya avtonomnyiye vneshniye dejstviya, fizicheskoye dejstviye i dostup k neproverennyim servisam bez otdeljnogo trebovaniya, istochnika, proverki i yavnogo ogranicheniya. Daljniye vozmozhnosti ostayutsya v planirovanii, pasportakh, simulyatorakh, fiksturakh ili otkryityikh voprosakh.

## Blizhajshiye prakticheskiye rezuljtatyi

- Sokhranyatj [pasport pervogo vertikaljnogo korobochnogo URL-sreza](../../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) kak proverennuyu granicu mezhdu prinyatyim lokaljnyim arkhivatorom i yesjhyo ne realizovannyim produktovyim servisom istochnikov; zakryitiye zamechanij audita ne oznachayet, chto servis uzhe realizovan ili otdeljno razreshyon.
- Razvivatj [nachaljnyij korobochnyij prototip](../../../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md) otdeljnyimi Swift-srezami: ot uzhe proverennogo konechnogo replay k vosstanavlivayemyim pokoleniyam pamyati i inertnoj deklarativnoj GUI-proyekcii, ne vyidavaya etot putj za gotovyiye reyestr proiskhozhdeniya, agentskij runtime ili prilozheniye.
- Ukreplyatj rabochuyu sessiyu kak povtoryayemyij kontur proiskhozhdeniya: zapros -> izmeneniye -> proverka -> zhurnal -> kommit.
- Razvivatj lokaljnyiye avtomatizacii cherez [TDD](../../../Glossarij/TDD.md), chtobyi povtoryayemyiye ruchnyiye dejstviya postepenno stanovilisj proveryayemyimi.
- Ispoljzovatj [planovyij reyestr](../../reyestr-trebovanij-variantov-i-kandidatov.json) kak mashinno chitayemyij sloj tekusjhej planovoj svyaznosti.
- Uderzhivatj [poljzovateljskoye perenapravleniye cikla](../../../Trebovaniya/🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) i [nepreryivnoye sobyitijnoye nablyudeniye vvoda](../../../Trebovaniya/🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md) kak granicu budusjhego produktovogo runtime: [FUM-STEP-0072](../../kartochki-shagov/✅-FUM-STEP-0072-opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom.md) uzhe proverila staticheskij kontrakt i sinteticheskuyu read-only-fiksturu, no ne razreshila nachalo korobochnoj stadii i ne dokazala zhivoj kanal.

## MVP-kandidatyi na etoj stadii

Na stadii dokumentacionnogo prototipa MVP-kandidatyi yavlyayutsya ne gotovyimi produktami, a proveryayemyimi rabochimi konturami pamyati. Ikh zadacha - umenjshitj ruchnuyu stoimostj tekusjhej praktiki i podgotovitj perenosimyiye kontraktyi dlya sleduyusjhej stadii.

| MVP-kandidat                                                                                                      | Chto proveryayetsya sejchas                                                                                                                                 | Chto gotovit dlya sleduyusjhej stadii                                                                      |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| [Arkhivirovaniye prikreplyayemyikh materialov](../../MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) | Lokaljnaya papka istochnika, indeks, izvlechyonnyij tekst, otchyot i ssyilka iz fajla zaprosa.                                                                 | Kontrakt servisa priyoma istochnikov i API proiskhozhdeniya.                                               |
| [Pamyatj rabochej sessii](../../MVP-kandidatyi/01-pamyatj-rabochej-sessii/README.md)                                   | Povtoryayemoye oformleniye zaprosa, zhurnala, instrumentov, proverok i sostava kommita.                                                                     | Format pasporta rabochej sessii i vstroyennogo kontura proiskhozhdeniya rezuljtata.                        |
| [Glossarno-dokumentacionnyij kontur](../../MVP-kandidatyi/03-glossarno-dokumentacionnyij-kontur/README.md)           | Otchyot po terminam, ssyilkam, novyim ponyatiyam i strukture glossariya.                                                                                      | Kontrakt redaktora svyaznoj pamyati i pravil publikacionnoj chistotyi.                                    |
| [Adresnyiye opisaniya i pasporta auditorij](../../MVP-kandidatyi/05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md) | Polnaya peresborka opisaniya iz istochnikov s pasportom auditorii i ogranicheniyami.                                                                        | Format generatora adresnyikh obyyasnenij s istochnikami i statusami tezisov.                              |
| [Ispolnyayemyij agentskij cikl](../../MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)                         | Format trassyi, povedencheskij Git + Codex-cikl i bezokonnyij Swift-putj vosproizvodimogo izmeneniya pamyati; sobstvennyij agentskij runtime yesjhyo ne dokazan. | Sobstvennyij runtime s bezopasnyim perenapravleniyem po razreshyonnyim sobyitiyam vvoda vo vremya rabotyi.      |
| [Yedinaya tochka lokaljnoj rabotyi](../../MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)                   | Pasport tekusjhego kontura i diagnostika markerov predposyilok budusjhej GUI-proyekcii; okna i poljzovateljskogo prilozheniya net.                             | Yedinoye prilozheniye, chjya modelj predstavleniya i dejstviya prokhodyat cherez vnutrenniye pamyatj i ispolneniye. |

## Proverka gotovnosti rezuljtata

Rezuljtat na etoj stadii schitayetsya ustojchivyim, yesli on:

- svyazan s iskhodnyim zaprosom i proizvodnyimi materialami;
- ne narushayet publikacionnuyu chistotu pamyati;
- prokhodit lokaljnyiye proverki, primenimyiye k zatronutyim avtomatizaciyam i planovyim materialam;
- obnovlyayet recency-metki, indeks Markdown-fajlov i zhurnal rabochej sessii;
- fiksiruyetsya Git-kommitom, yesli poljzovatelj yavno ne poprosil ne kommititj.

## Kriterij vyikhoda stadii

Vyikhod iz stadii binarnyij: on razreshyon toljko togda, kogda odnovremenno otmechenyi vse shestj punktov. Zaversheniye otdeljnoj rabochej sessii po predyidusjhemu razdelu ne podmenyayet vyikhod stadii, a chastichnoye vyipolneniye checklist ne okruglyayetsya do gotovnosti.

- [x] Rovno odin aktivnyij MVP soglasovan v [indekse kandidatov](../../MVP-kandidatyi/README.md), [dorozhnoj karte](../../dorozhnaya-karta.md), [svodnom planirovanii](../../svodnaya-tablica-trebovanij-i-realizacij.md) i [matrice otbora](../../MVP-kandidatyi/matrica-otbora.md): eto arkhivator istochnikov.
- [x] Pervyij reliz aktivnogo MVP proshyol [yedinstvennyij avtonomnyij skvoznoj scenarij](../../MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) cherez obsjhij CLI: fixture-URL i vremennyij zapros sozdali kanonicheskij istochnik, a povtor obnovil tot zhe snimok bez ustarevshikh fajlov i dublikatov ssyilok.
- [x] [Mashinnyij planovyij reyestr](../../reyestr-trebovanij-variantov-i-kandidatov.json) peresobran i validen, a polnyij avtonomnyij [smoke-check](../../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) tekusjhej sessii zafiksirovan v [zhurnale](../../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/otchyot.md).
- [x] Kornevoj [README](../../../README.md), zakreplyonnaya [avtomatizaciya adresnogo opisaniya](../../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md) i [opisaniye FUM dlya razrabotchikov](../../../Opisaniya/dlya-razrabotchikov-PO.md) polnostjyu peresobranyi i chestno otrazhayut fakticheskij status aktivnogo MVP i nezavershyonnyij perekhod.
- [x] Po [usloviyam perekhoda stadii 02](../02-korobochnaya-realizaciya-FUM/README.md) podgotovlen [pasport pervogo vertikaljnogo korobochnogo sreza](../../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) s poljzovateljskim scenariyem, vkhodami, vyikhodami, trassami, oshibkami, pravami i avtonomnoj proverkoj.
- [ ] Pasport produktovogo URL-sreza dorabotan po zamechaniyam i povtorno proveren, no [iskhodnyij zapros 2026-07-24 10:44:28 MSK](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) razreshayet toljko ogranichennyij bezokonnyij inzhenernyij prototip. Dlya polnogo vyipolneniya punkta nuzhen otdeljnyij yavnyij zapros, razreshayusjhij produktovuyu realizaciyu po [FUM-STEP-0105](../../kartochki-shagov/🟡-FUM-STEP-0105-realizovatj-avtonomnoye-yadro-pervogo-produktovogo-URL-sreza.md), posle chego realizaciya dolzhna projti zakreplyonnuyu priyomku; zhivoj setevoj dostup ostayotsya otdeljnyim polnomochiyem.

Tekusjhij status: **stadiya ne projdena — vyipolnenyi 5 iz 6 punktov**. Pervyij reliz arkhivatora prinyat, razreshyonnyij inzhenernyij Swift-prototip sozdan, a zamechaniya audita produktovogo pasporta zakryityi povtornoj proverkoj. Nezavershyonnyim ostayotsya odin produktovyij perekhod: realizaciya URL-servisa ne poluchila otdeljnogo razresheniya i ne proshla priyomku, a polnomochiye zhivoj seti iz inzhenernogo zaprosa ne vyivoditsya.

## Opornyiye istochniki

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-21 15:51:32 MSK - Podgotovitj pasport pervogo korobochnogo sreza FUM](../../../Zhurnal/2026-07-21_15-51-32_MSK_podgotovitj-pasport-pervogo-korobochnogo-sreza-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii](../../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-14 00:36:30 MSK - Utochnitj tekstovyij sostav pamyati dokumentacionnogo prototipa FUM](../../../Zhurnal/2026-07-14_00-36-30_MSK_utochnitj-tekstovyij-sostav-pamyati-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../../../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-01 15:08:04 MSK](../../../Zhurnal/2026-07-01_15-08-04_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-01 14:58:32 MSK](../../../Zhurnal/2026-07-01_14-58-32_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-29 10:59:18 MSK](../../../Zhurnal/2026-06-29_10-59-18_MSK/zapros.md)
- [Obzor proyekta FUM](../../../Dokumentaciya/00-obzor-proyekta.md)
- [Dorozhnaya karta FUM](../../dorozhnaya-karta.md)
- [Svodnaya tablica trebovanij i realizacij FUM](../../svodnaya-tablica-trebovanij-i-realizacij.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:87a2c800e23bf67c6de69d7435d55f72e7faaf5915e508e81d692dad9f61ebd1 -->
<!-- FUM-MD-RECENCY:END -->
