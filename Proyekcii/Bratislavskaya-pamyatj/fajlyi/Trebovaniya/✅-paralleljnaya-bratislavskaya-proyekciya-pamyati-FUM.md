# Paralleljnaya bratislavskaya proyekciya pamyati FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0037 -->

Repozitornaya [pamyatj FUM](../Glossarij/pamyatj-FUM.md) dolzhna khranitj kanonicheskuyu rabochuyu kirillicheskuyu oblastj i polnostjyu peresobirayemuyu paralleljnuyu oblastj na [bratislavskom yazyike](../Glossarij/bratislavskij-yazyik.md). Russkoye soderzhimoye i kazhdyij kirillicheskij komponent polnogo otnositeljnogo puti preobrazuyutsya zakreplyonnyim LinguisticKit, a proizvodnyij rezuljtat ostayotsya odnostoronnej proyekciyej, a ne vtoryim istochnikom istinyi.

## Semanticheskiye svyazi

- **dopolnyayet:** [vosproizvodimoye shtatnoye popolneniye pamyati](🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md) — dobavlyayet khranimuyu i vosproizvodimo peresobirayemuyu yazyikovuyu proyekciyu repozitornoj pamyati, ne izmenyaya kanonicheskiye produktovyiye sobyitiya i snimki.

## Kriterii proverki

- toljko kirillicheskaya oblastj redaktiruyetsya i yavlyayetsya istochnikom trebovanij, proverok i sleduyusjhego pokoleniya; ruchnaya pravka bratislavskogo rezuljtata obnaruzhivayetsya i otklonyayetsya;
- preobrazovaniye ispoljzuyet LinguisticKit `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)` na revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`, a smena tablicyi ili revizii vyipolnyayetsya kak yavnaya migraciya;
- polnyij repozitorno-otnositeljnyij putj kazhdogo vklyuchyonnogo fajla otobrazhayetsya pokomponentno: kirillicheskiye chasti vsekh imyon katalogov i fajlov transliteriruyutsya, neizmenivshiyesya tekhnicheskiye chasti sokhranyayutsya i tozhe uchityivayutsya v manifeste;
- proizvodnoye prostranstvo imyon ne peresekayetsya s istochnikom i ne vkhodit obratno v iskhodnyij inventarj; tochnyij layout razreshayet uzhe latinskiye imena, vlozhennyiye katalogi i udaleniye libo pereimenovaniye istochnikov bez rekursii i ustarevshego ostatka;
- do pervoj zapisi proveryayutsya exact-, NFC-, registronezavisimyiye, fajlovo-katalozhnyiye, prefiksnyiye, dlinovyiye i platformennyiye kollizii; neodnoznachnostj ne skryivayetsya avtomaticheskim suffiksom;
- versionirovannaya politika opredelyayet polnyij iskhodnyij inventarj i povedeniye dlya Markdown-ssyilok i anchors, doslovnyikh zaprosov, vneshnikh istochnikov i URL, koda, JSON i drugikh mashinnyikh formatov, khyeshej, `FUM-MD-RECENCY`, binarnyikh dannyikh, simvolicheskikh ssyilok, gitlink, rezhimov fajlov i pustyikh katalogov;
- manifest pokoleniya svyazyivayet tochnyij iskhodnyij snimok, oblastj i isklyucheniya, versiyu skhemyi, LinguisticKit-kontrakt, kazhduyu paru iskhodnogo i celevogo puti, khyeshi soderzhimogo i polnyij itogovyij nabor fajlov;
- novoye pokoleniye sobirayetsya i proveryayetsya vne celi, a tokenizirovannyiye chastichnyiye zapisi stanovyatsya polnyimi vyikhodami toljko posle sinkhronizacii bajtov i okonchateljnogo rezhima; ustanovka primenyayet atomarnoye `NO_REPLACE`, pri mezhkatalozhnom perenose zakreplyayet naznacheniye ranjshe udaleniya istochnika, svorachivayet toljko dokazannyij avarijnyij dublikat, povtorno sveryayet konfliktnuyu Git-granicu i sokhranyayet prezhneye podtverzhdyonnoye pokoleniye pri oshibke; opublikovannaya do pervoj mutacii vneshnyaya kvitanciya svyazyivayet tochnyiye snimki pokolenij i odna dayot vosstanovleniyu pravo na perenos libo udaleniye, a uspeshnaya polnaya peresborka udalyayet toljko dokazanno ustarevshiye upravlyayemyiye vyikhodyi;
- preobrazovannyiye lokaljnyiye ssyilki razreshayutsya v sootvetstvuyusjhem pokolenii libo po yavnoj politike vedut k kanonicheskoj celi, a vneshniye i neprozrachnyiye kontraktyi ne menyayutsya neosoznannoj strokovoj transliteraciyej;
- TDD-nabor i avtonomnaya priyomka podtverzhdayut povtoryayemostj bajtov i putej, polnyij okhvat, otsutstviye rekursivnogo vkhoda, obnaruzheniye ruchnogo drejfa i bezopasnoye vosstanovleniye posle sboya; obsjhaya kompleksnaya proverka vyipolnyayetsya uzhe na soglasovannyikh kanonicheskom i proizvodnom sloyakh.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: mashinnyij kontrakt i lokaljnaya TDD-avtomatizaciya polnoj proyekcii realizovanyi. Generator stroit i atomarno ustanavlivayet tochnoye pokoleniye `Proyekcii/Bratislavskaya-pamyatj`; vosstanovleniye prinimayet toljko vneshnyuyu kvitanciyu i tochnyiye snimki, publichnyiye plan i validator zakryivayutsya pri nezavershyonnoj tranzakcii, a nezavisimyij validator zanovo poluchayet ozhidayemyiye puti i bajtyi iz kanonicheskogo sloya, proveryayet kanonicheskij manifest, proiskhozhdeniye, rezhimyi, ssyilki, ruchnoj drejf i otsutstviye rekursivnogo vkhoda. Tranzakcionnaya granica rasschitana na odnu dobrosovestnuyu pishusjhuyu sessiyu i doverennyij lokaljnyij Git-dir; zasjhita ot namerennoj poddelki sostoyaniya drugim processom togo zhe poljzovatelya potrebovala byi vneshnego kornya doveriya i v trebovaniye ne vkhodit.

Trebovaniye otnositsya k chelovekochitayemoj repozitornoj pamyati i ne menyayet yazyikonejtraljnyiye kanonicheskiye bajtyi `fum.memory.canonical-json.v1`. Tochnoye fizicheskoye razmesjheniye, formatnyiye politiki, zakreplyonnaya reviziya LinguisticKit i polnyij manifest pokoleniya zadanyi kontraktom versii 2. Eto yavnaya migraciya politiki, plana i manifesta ot versii 1; opublikovannyiye fajlyi versii 1 ostayutsya pobajtovo neizmennyimi. Proizvodnaya oblastj khranitsya v Git, no isklyuchena iz kanonicheskikh avtodiskaveri-konturov i nikogda ne stanovitsya istochnikom instrukcij libo rabochim katalogom agenta.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros 2026-09-01 11:19:59 MSK — Realizovatj bratislavskuyu proyekciyu pamyati](../Zhurnal/2026-09-01_11-19-59_MSK_realizovatj-bratislavskuyu-proyekciyu-pamyati/zapros.md)
- [opisaniye bratislavskoj versii pamyati FUM](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)
- [avtomatizaciya bratislavskoj proyekcii pamyati](../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 17:52:20 MSK -->
<!-- content-sha256: sha256:a161900fe9f6c0e60c898af8c1271de14f1aa9263ab957b06d455c03cee24ec2 -->
<!-- FUM-MD-RECENCY:END -->
