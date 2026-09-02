# 02. Avtomatizacii i yazyik

## Naznacheniye

Eto napravleniye prevrasjhayet povtoryayemyiye rabochiye priyomyi [FUM](../../Glossarij/FUM.md) v vosproizvodimyiye [avtomatizacii FUM](../../Glossarij/avtomatizaciya-FUM.md). Ustojchivoye dejstviye dolzhno imetj istochnik, kontrakt, sposob zapuska, proverku, ogranicheniya i istoriyu izmenenij, a ne susjhestvovatj toljko kak privyichka konkretnoj rabochej sessii.

Daljnij rezuljtat napravleniya - [yazyik avtomatizacij FUM](../../Glossarij/yazyik-avtomatizacij-FUM.md), udobnyij dlya chteniya, generacii, proverki i tochechnoj pravki so storonyi LLM.

## Proyektnyiye voprosyi

- Gde prokhodit granica mezhdu odnorazovoj ruchnoj rabotoj i avtomatizaciyej, kotoruyu nuzhno zakreplyatj v pamyati?
- Kakiye chasti avtomatizacii mozhno sdelatj [chistyimi funkciyami](../../Glossarij/chistaya-funkciya.md), a kakiye ostayutsya obolochkami vvoda-vyivoda?
- Kak fiksirovatj nedeterminizm, vneshniye servisyi, versii modelej i nevosproizvodimyiye chasti bez raskryitiya sekretov?
- Kakaya minimaljnaya grammatika ili deklarativnaya forma nuzhna yazyiku avtomatizacij?

## Liniya razvitiya

Blizhajshiye avtomatizacii uzhe vidnyi v `Инструменты/`: `fum-glossarij`, `fum-materialyi-zaprosov`, `fum-sborka-svodnoj-dokumentacii` i `fum-svyaznostj-rabochej-sessii`. Napravleniye dolzhno postepenno vyidelyatj iz nikh obsjhiye kontraktyi: vkhodyi, vyikhodyi, effektyi, proverki, fiksturyi, otchyotyi, versii i ogranicheniya dostupa.

Ekspluatacionnaya ograda: sleduyusjhij abzac opisyivayet prezhnyuyu liniyu obyazateljnogo prodolzheniya vetki. Sejchas kazhduyu pishusjhuyu sessiyu zapuskayet poljzovatelj, i ona zavershayetsya bez continuation, FIFO, selector i handoff.

Otdeljnaya liniya zakreplyayet [obyazateljnoye prodolzheniye Git-vetki](../../Glossarij/obyazateljnoye-prodolzheniye-vetki.md). Kazhdaya zavershayusjhayasya kommitom kornevaya zadacha zaraneye sozdayot rovno odnu novuyu zadachu v tom zhe lokaljnom proyekte i checkout, dozhidayetsya yeyo tochnogo ozhidayusjhego FIFO-bileta, a zatem atomarno svyazyivayet kommit s peredachej ocheredi. Prodolzheniye perechityivayet novyij `HEAD` i neposredstvenno vyizyivayet vetochnyij selector; periodicheskij heartbeat i obsjhij dispetcher sokhranyayutsya toljko kak istoricheskaya realizaciya.

Kazhdaya novaya ustojchivaya avtomatizaciya razvivayetsya cherez [TDD](../../Glossarij/TDD.md): snachala fiksiruyetsya proveryayemoye ozhidaniye, zatem realizaciya dovoditsya do prokhozhdeniya proverki, posle chego utochnyayetsya bez poteri kontrakta.

Smyislovoye nazvaniye novoj ili pereimenovyivayemoj avtomatizacii zadayotsya po-russki kirillicej, a yego latinskoye predstavleniye vyichislyayetsya LinguisticKit po zakreplyonnomu russkomu kontraktu. Otdeljnyij reyestr khranit istochnik, tochnuyu transliteraciyu, tekhnicheskij slug i versiyu preobrazovatelya. Prezhnij tochnyij nabor uzhe migrirovan: sovmestimyiye s istoricheskim formatom polya `legacy` i `legacy_display` pustyi. Normalizaciya slug ostayotsya sobstvennyim sloyem FUM, a kolliziya imyon zakryivayet dobavleniye.

Otdeljnaya liniya dolzhna postroitj [bratislavskuyu versiyu pamyati](../../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md): khranimuyu proizvodnuyu proyekciyu kanonicheskogo kirillicheskogo dereva cherez tot zhe zakreplyonnyij LinguisticKit. Ona trebuyet samostoyateljnyikh TDD-kontraktov polnogo fajlovogo inventarya, pokomponentnogo preobrazovaniya putej, formatno osoznannogo soderzhimogo, lokaljnyikh ssyilok, manifesta proiskhozhdeniya, kollizij i atomarnoj peresborki; reyestr slug nazvanij avtomatizacij etot kontur ne zamenyayet.

## Blizhajshij proveryayemyij artefakt

Yedinaya lokaljnaya kompleksnaya proverka repozitoriya uzhe sobirayet testyi avtomatizacij i proverku svyaznosti vyibrannoj rabochej sessii. Vklyuchyonnyij v etot kontur reyestr nazvanij avtomatizacij ispoljzuyet materializovannyij LinguisticKit na zakreplyonnoj revizii: proveryayet strukturu, polnyij uchyot kanonicheskikh identifikatorov, otsutstviye dejstvuyusjhikh legacy-isklyuchenij, vyichislyayet transliteraciyu zhivyim adapterom i sveryayet yeyo s etalonami. Otdeljnaya avtomatizaciya v tom zhe konture proveryayet Git-topologiyu zavisimosti, roli forka i upstream, dostizhimostj revizii iz lokaljno poluchennyikh refs i tochnyij gitlink.

Proverka: komanda rabotayet bez setevyikh zavisimostej i sekretov, vyivodit perechenj realjno zapusjhennyikh proverok i zavershayetsya oshibkoj, yesli submodule ne materializovan, yego lokaljnaya Git-topologiya raskhoditsya s kontraktom, imya ne zaregistrirovano, ruchnaya transliteraciya otlichayetsya ot rezuljtata zakreplyonnogo adaptera libo obnaruzhena kolliziya. Posle svezhego klonirovaniya FUM submodule i yego otdeljnyij remote `upstream` dolzhnyi byitj yavno inicializirovanyi do polnogo smoke-check.

## Proveryayemyiye rezuljtatyi

- Lokaljnaya avtomatizaciya imeyet `SKILL.md`, skript ili deklarativnoye opisaniye, testyi i komandu zapuska.
- Obyichnyij testovyij nabor rabotayet bez seti, sekretov i privatnyikh dannyikh.
- Vneshnyaya zavisimostj opisana cherez kontrakt, fiksturu, simulyator ili otchyot o nevosproizvodimoj chasti.
- Razdel `## Использованные инструменты` v fajlakh zaprosov ssyilayetsya na reyestr i fiksiruyet fakticheskij snimok sredyi.

## Granicyi

Avtomatizaciya ne dolzhna rasshiryatj prava dejstviya toljko potomu, chto yeyo stalo udobno zapuskatj. Dlya servisnyikh, poljzovateljskikh i fizicheskikh dejstvij nuzhnyi yavnyiye [urovni dostupa](../../Glossarij/urovenj-dostupa.md), podtverzhdeniya i nablyudayemyiye trassyi. Yazyik avtomatizacij ne dolzhen skryivatj pobochnyiye effektyi za krasivyim sintaksisom.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [iskhodnyij zapros 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij](../../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-21 12:18:37 MSK - Zakrepitj transliteraciyu nazvanij avtomatizacij](../../Zhurnal/2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK - Aktualizirovatj fork i podklyuchitj LinguisticKit](../../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)

## Opornyiye materialyi

- [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [LLM-oriyentirovannyij yazyik avtomatizacij](../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [arkhivirovannyij istochnik Roman-Kerimov/LinguisticKit](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [arkhivirovannaya vyibrannaya reviziya LinguisticKit](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:51:31 MSK -->
<!-- content-sha256: sha256:77777c7e7da8ba299b2bc9a23cae62082f27083780fddddc0d73ac341df9ca7d -->
<!-- FUM-MD-RECENCY:END -->
