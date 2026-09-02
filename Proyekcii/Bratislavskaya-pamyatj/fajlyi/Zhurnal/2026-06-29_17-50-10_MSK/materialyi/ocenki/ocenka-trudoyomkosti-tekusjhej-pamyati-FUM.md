# Ocenka trudoyomkosti tekusjhej pamyati FUM

Na moment ocenki naiboleye veroyatnaya trudoyomkostj rabotyi, uzhe prodelannoj v tekusjhej [pamyati FUM](../../../../Glossarij/pamyatj-FUM.md), sostavlyayet okolo **160 cheloveko-chasov**. Rabochij diapazon ocenki: **120-220 cheloveko-chasov**.

Eta ocenka ne yavlyayetsya fakticheskim tajm-trekingom. Ona otvechayet na vopros, skoljko vremeni, veroyatno, potrebovalosj byi siljnomu cheloveku ili neboljshoj komande, chtobyi vruchnuyu vyipolnitj sopostavimuyu rabotu pri nalichii tekusjhego urovnya instrumentov, yasnoj celi i vozmozhnosti poljzovatjsya agentnoj pomosjhjyu.

## Snimok repozitoriya

Ocenka opirayetsya na snimok repozitoriya ot 2026-06-29.

| Pokazatelj | Znacheniye |
| --- | --- |
| Period Git-istorii | 2026-06-21 - 2026-06-29 |
| Kolichestvo kommitov | 102 |
| Otslezhivayemyiye fajlyi | 332 |
| Markdown-fajlyi | 305 |
| Obsjhij obyyom strok v otslezhivayemyikh fajlakh | 36 088 |
| Obsjhij obyyom slov v Markdown-fajlakh | 116 763 |

Primechaniya k snimku:
- Snimok zafiksirovan v rabochej sessii po iskhodnomu zaprosu 2026-06-29 17:50:10 MSK.
- Osnovnoj obyyom rabotyi sosredotochen v `Запросы/`, `Глоссарий/`, `Журнал/`, `Документация/`, `Планирование/`, `Источники/` i `Инструменты/`.
- Ocenka vklyuchayet ne toljko napisaniye teksta, no i proyektirovaniye strukturyi pamyati FUM, vedeniye proiskhozhdeniya trebovanij, podderzhku navigacii, lokaljnyiye avtomatizacii, proverki i Git-disciplinu.

## Metodika raschyota

Vopros ocenki: Skoljko cheloveko-chasov potrebovalosj byi siljnomu cheloveku ili neboljshoj komande, chtobyi vruchnuyu vyipolnitj sopostavimuyu rabotu po sozdaniyu tekusjhej pamyati FUM?

- Snimok artefaktov - Ocenka opirayetsya na razmer i strukturu tekusjhego Git-repozitoriya: istoriyu kommitov, kolichestvo fajlov, Markdown-obyyom, stroki i raspredeleniye materialov po oblastyam pamyati.
- Razlozheniye po vidam rabotyi - Itogovaya trudoyomkostj sobirayetsya iz diapazonov po konceptualjnoj prorabotke, dokumentacii, proiskhozhdeniyu reshenij, avtomatizaciyam i Git-gigiyene.
- Soglasovaniye diapazonov - Summa komponentnyikh diapazonov dayot grubyij koridor okolo 125-230 cheloveko-chasov; itogovyij diapazon okruglyon do 120-220 cheloveko-chasov s uchyotom peresecheniya vidov rabotyi i povtornogo ispoljzovaniya pravil.

## Diapazonyi

| Komponent | Nizhnyaya granica | Verkhnyaya granica | Kommentarij |
| --- | ---: | ---: | --- |
| Konceptualjnaya prorabotka FUM, arkhitekturyi, granic i klyuchevyikh obrazov | 35 | 60 | Proyektirovaniye obsjhej ramki, terminov, arkhitekturnyikh gorizontov i granic trebovanij. |
| Napisaniye, svyazyivaniye i redaktirovaniye dokumentacii, glossariya i planirovaniya | 40 | 75 | Osnovnyiye Markdown-materialyi, navigaciya, ssyilki i soglasovaniye russkoyazyichnoj strukturyi. |
| Oformleniye iskhodnyikh zaprosov, zhurnala, istochnikov, navigacii i proiskhozhdeniya reshenij | 20 | 35 | Sokhraneniye cepochki zapros -> proizvodnaya dokumentaciya -> proverka -> kommit. |
| Sozdaniye i dovedeniye lokaljnyikh avtomatizacij, testov, recency-metok i proverok svyaznosti | 20 | 40 | Instrumentyi v `Инструменты/`, testovyiye naboryi i povtoryayemyiye proverki rabochej sessii. |
| Git-gigiyena, proverki, kommityi, ispravleniya strukturyi i publikacionnaya chistota | 10 | 20 | Proverka diff, staging, kommityi, otsutstviye musora i publikacionno chistoye sostoyaniye pamyati. |

Itogovyij rabochij diapazon: **120-220 cheloveko-chasov**.
Tochechnaya ocenka: **160 cheloveko-chasov**.

## Dopusjheniya

- Ocenivayetsya stoimostj sozdaniya sopostavimogo rezuljtata, a ne fakticheskaya dliteljnostj proshedshikh agentskikh sessij.
- Ispolnitelj yavlyayetsya siljnyim chelovekom ili neboljshoj komandoj, sposobnoj byistro ponyatj tekusjhuyu celj proyekta i poljzovatjsya agentnoj pomosjhjyu.
- Tekusjhij urovenj instrumentov i lokaljnyikh avtomatizacij dostupen ispolnitelyu, no skryitaya istoriya razmyishlenij i interaktivnyiye promezhutochnyiye sostoyaniya ne schitayutsya gotovyim iskhodnyim materialom.
- Raznyiye vidyi rabotyi chastichno peresekayutsya: napisaniye dokumentacii odnovremenno utochnyayet arkhitekturu, glossarij i pravila rabochej sessii.
- Ocenka izmeryayet cheloveko-chasyi sozdaniya sopostavimoj pamyati FUM, a ne ryinochnuyu stoimostj, ne kalendarnuyu dliteljnostj i ne budusjhuyu stoimostj soprovozhdeniya.

## Ogranicheniya tochnosti

- V repozitorii net nezavisimogo tajm-trekera, poetomu ocenka rekonstruiruyet trudoyomkostj po artefaktam, istorii Git i strukture rabot.
- Ocenka ne otdelyayet polnostjyu vklad cheloveka, agenta i instrumentov: tekusjhaya [pamyatj FUM](../../../../Glossarij/pamyatj-FUM.md) sozdavalasj kak gibridnaya rabota.
- Obyyom slov i fajlov sam po sebe ne raven trudoyomkosti; znachiteljnaya chastj cennosti nakhoditsya v soglasovannosti strukturyi, ssyilok, pravil i proverok.
- Diapazon opisyivayet stoimostj sozdaniya sopostavimogo rezuljtata, a ne garantirovannuyu stoimostj daljnejshego soprovozhdeniya.
- Verkhnyaya granica byistro rastyot, yesli ubratj agentnuyu pomosjhj, avtomatizaciyu povtoryayusjhikhsya dejstvij i uzhe slozhivshuyusya konceptualjnuyu ramku.

## Oformleniye rezuljtata

- Klyuchevoj vyivod i rabochij diapazon nakhodyatsya v pervyikh abzacakh fajla.
- Snimok repozitoriya oformlen otdeljnoj tablicej s datoj, istoriyej Git, kolichestvom fajlov, strok i slov.
- Metodika raschyota vyinesena v otdeljnyij razdel, chtobyi byilo vidno, kak ocenka poluchena.
- Diapazonyi po vidam rabotyi predstavlenyi tablicej s nizhnej i verkhnej granicej.
- Dopusjheniya i ogranicheniya tochnosti otdelenyi ot itogovoj interpretacii, chtobyi ne smeshivatj vyivod i usloviya primenimosti.

## Itogovaya interpretaciya

Yesli byi sopostavimuyu rabotu vyipolnyal odin siljnyij chelovek s khoroshimi instrumentami i uzhe sformirovannyim videniyem proyekta, razumnaya kalendarnaya interpretaciya ocenki - primerno **3-5 nedelj plotnoj rabotyi**.

Yesli ubratj agentnuyu pomosjhj, avtomatizaciyu povtoryayusjhikhsya dejstvij i uzhe slozhivshuyusya konceptualjnuyu ramku, sopostavimyij rezuljtat mog byi potrebovatj **250+ cheloveko-chasov**. Verkhnyaya granica rastyot osobenno byistro tam, gde nuzhno odnovremenno uderzhivatj terminologiyu, vnutrennyuyu svyaznostj, proiskhozhdeniye trebovanij, pravila rabochej sessii i proveryayemostj lokaljnyikh avtomatizacij.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-29 17:50:10 MSK](../../zapros.md)
- [fum-ocenki](../../../../Instrumentyi/fum-ocenki/SKILL.md) - lokaljnaya avtomatizaciya sborki i proverki ocenochnyikh materialov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:15ca3ca12e8b079271915bba504fce3d09e20aa31bd5e51bad6ec0b6b03a14d9 -->
<!-- FUM-MD-RECENCY:END -->
