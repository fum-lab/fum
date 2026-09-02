# Proveryayemyij mnogoagentnyij kontur FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0022 -->

FUM dolzhen otlichatj [proveryayemyij mnogoagentnyij kontur](../Glossarij/proveryayemyij-mnogoagentnyij-kontur-FUM.md) ot paralleljnogo samodialoga neskoljkikh sessij odnoj modeli. Mnozhestvo chatov, povtoreniye odnogo vyivoda ili golosovaniye ne dokazyivayut nezavisimostj vkladov i ne povyishayut status svideteljstva.

## Semanticheskiye svyazi

- **zavisit ot:** [kontekstno posiljnyikh ispolnyayemyikh shagov](🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md) — kazhdyij razlichimyij vklad dolzhen zavershatjsya i peredavatjsya kak otdeljnyij ogranichennyij rabochij paket, a ne delitj skryityij kontekst s ostaljnyim epizodom.
- **usilivayetsya:** [kommitiruyemyimi vkladami pishusjhikh poduzlov FUM](✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md) — otdeljnyij Git-obyyekt delayet proiskhozhdeniye pishusjhego vklada adresuyemyim, ne vyidavaya tekhnicheskuyu izolyaciyu za nezavisimoye svideteljstvo.
- **usilivayetsya:** [upravlyayemyim ispolneniyem cepochek universaljnyimi fork-poduzlami](🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md) — docherniye repozitornyiye cepochki i kornevoye revjyu delayut rezuljtatyi vosstanavlivayemyimi, sokhranyaya nablyudayemuyu korrelyaciyu ispolnitelej.
- **usilivayet:** [avtonomnoye modeljnoye prodolzheniye pri ozhidanii podtverzhdeniya](🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md) — razlichimyiye gipotezyi i proverki delayut resursno ogranichennoye vetvleniye soderzhateljnyim, ne podmenyaya poljzovateljskogo dopuska golosovaniyem.
- **dopolnyayetsya:** [skvoznyim proveryayemyim odnoagentnyim epizodom FUM](✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md) — odinochnyij skvoznoj cikl dokazyivayet bazovuyu sposobnostj, kotoruyu pozdneye usilivayut razlichimyiye vkladyi i otdeljnaya proverka.

## Kriterii proverki

- odin epizod zadayot obsjhuyu zadachu i proveryayemyij artefakt, a kazhdyij vklad imeyet razlichimyiye rolj, gipotezu, oblastj, istochnik libo metod;
- kazhdyij vklad sokhranyayet identifikatoryi ispolnitelya, roli i rabochego paketa, nablyudayemyiye modelj i postavsjhika, a takzhe SHA-256 zadachi, lokaljnyikh vkhodov, roditeljskogo pokoleniya i rezuljtata; ispolnitelj tochno sovpadayet s avtorom sobyitiya, a rolj proveryayetsya po pasportu;
- obsjhiye modelj, postavsjhik, sistemnyij shablon i iskhodnyij material sokhranyayutsya kak gruppyi korrelyacii, a ispoljzovaniye roditeljskogo rezuljtata, kopirovaniye i proizvodnyij otvet — kak napravlennyiye ryobra; obsjhiye ispolnitelj ili tochno odin instrumentaljnyij vyizov takzhe svyazyivayut vkladyi; odin vklad mozhet imetj neskoljko peresekayusjhikhsya svyazej, a ikh svyaznyij komponent uchityivayetsya kak ne boleye odnogo ogranichennogo podtverzhdeniya;
- instrumentaljnoye nablyudeniye sokhranyayet vid polnomochiya istochnika, identichnostj vyizova, SHA-256 vkhoda i rezuljtata i vremya nablyudeniya otdeljno ot modeljnogo pereskaza, kotoryij ostayotsya proizvodnyim utverzhdeniyem;
- kazhdoye sobyitiye vklada ili proverki ssyilayetsya na tochnoye podtverzhdyonnoye pokoleniye, a novyij process vosstanavlivayet prinyatoye sostoyaniye, polnoye proiskhozhdeniye, korrelyacii, proverki i raznoglasiya iz kanonicheskogo zhurnala, artefaktov i pasporta bez prezhnego chata i novyikh modeljnyikh vyizovov;
- validator razlichayet nezavisimyij po nablyudayemyim priznakam vklad, korrelirovannyij vklad, kopiyu i vklad s nepodtverzhdyonnyim proiskhozhdeniyem, no ne obyyavlyayet dokazannoj semanticheskuyu nezavisimostj;
- otdeljnaya proverka sokhranyayet identifikatoryi proveryayusjhego i yego roli, zaraneye obyyavlennyiye kriterii, proveryayemyiye utverzhdeniya s tochnyimi khyeshami rezuljtatov, ssyilki na instrumentaljnyiye nablyudeniya i odin iskhod `passed`, `failed` ili `inconclusive`;
- status proveryayusjhego vyivoditsya otdeljno ot iskhoda i razlichayet vneshnij po nablyudayemyim priznakam sluchaj, samoproverku, korrelirovannuyu proverku i nepodtverzhdyonnoye proiskhozhdeniye; nedopustimaya rolj zakryivayetsya otkazom, a samoproverka i korrelirovannaya proverka sokhranyayutsya bez vneshnego vesa;
- proverka formyi ne vyidayotsya za instrumentaljno podtverzhdyonnyij fakt, a instrumentaljnoye nablyudeniye — za semanticheskuyu ocenku; ni iskhod proverki, ni nablyudayemoye razdeleniye proveryayusjhego ne obyyavlyayutsya dokazateljstvom istinyi ili absolyutnoj nezavisimosti;
- soglasiye korrelirovannyikh ispolnitelej odnoj modeli ili neskoljko odinakovyikh neproverennyikh otvetov ne prinimayutsya za vneshneye podtverzhdeniye, a nedostatochnoye dokazateljstvo dayot `inconclusive`;
- raznoglasiya, vozrazheniya, otkazyi, otricateljnyiye rezuljtatyi i prichinyi otkloneniya sokhranyayutsya kak tipizirovannyiye dopisyivayemyiye (`append-only`) zapisi, ne stirayutsya posleduyusjhim iskhodom i vosstanavlivayutsya v novom processe;
- versionirovannoye resheniye vyibora ssyilayetsya na zaraneye obyyavlennyiye kriterii, vse rassmotrennyiye vkladyi, proverki, dokazateljstva i sokhranyonnyiye raznoglasiya, yavno fiksiruyet vyibrannyiye i otklonyonnyiye rezuljtatyi i ne ispoljzuyet chislo sovpavshikh otvetov kak samostoyateljnoye osnovaniye; pozdneye razresheniye raznoglasiya prinimayet dokazateljstvo toljko iz zavershyonnoj zaraneye obyyavlennoj razlichayusjhej proverki pri tochnom sovpadenii utverzhdeniya, vklada i rezuljtata;
- pered kazhdyim sleduyusjhim dejstviyem proveryayutsya konechnyiye limityi ispolnitelej, raundov, modeljnyikh i instrumentaljnyikh vyizovov, vkhoda i vyikhoda, a takzhe zasjhisjhyonnyij rezerv na proverku i peredachu; uzhe zarezervirovannyij raskhod uchityivayetsya do vyidachi sleduyusjhego razresheniya;
- otsutstviye podtverzhdeniya parkuyet toljko tochnyij vneshnij perekhod: poka ostayutsya bezopasnaya produktivnaya model-only-rabota i yeyo byudzhet, vnutrenniye vetvi mogut prodolzhatjsya, no ikh vyibor ne poluchayet statusa poljzovateljskogo podtverzhdeniya ili avtorizacii;
- epizod zavershayetsya rovno odnim iskhodom `goal_met`, `budget_exhausted`, `needs_input`, `unresolved_conflict` ili `failed` s mashinochitayemoj prichinoj; `goal_met` trebuyet pustogo nabora neustranyonnyikh raznoglasij, `needs_input` dopustim toljko posle ischerpaniya bezopasnyikh produktivnyikh prodolzhenij libo ikh byudzheta, a `unresolved_conflict` — posle ischerpaniya razlichayusjhikh proverok libo kogda oni nebezopasnyi, neproduktivnyi ili vyikhodyat za byudzhet;
- posle terminaljnogo iskhoda tekusjheye pokoleniye ne prinimayet novyiye vkladyi ili upravlyayusjhiye sobyitiya; vozobnovleniye sozdayot novoye pokoleniye i novyij kontekstno posiljnyij rabochij paket s yavnoj svyazjyu s predshestvennikom;
- kanonicheskoye vosstanovleniye sokhranyayet resheniye, ostatki i rezervacii byudzhetov, ozhidayusjhij podtverzhdeniya perekhod, terminaljnyij iskhod i neustranyonnyiye raznoglasiya bez prezhnego chata i novyikh modeljnyikh vyizovov.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: normativnaya granica, mashinochitayemyij pasport epizoda, avtonomnyiye fiksturyi i [obsjhaya vosstanavlivayemaya pamyatj vkladov](../Dokumentaciya/49-kontrakt-vosstanavlivayemoj-obsjhej-pamyati-raspredelyonnogo-epizoda.md) zakreplenyi. Skhema zhurnala, sostoyaniya, pokoleniya i reducer versii 4 sokhranyayet proveryayemoye proiskhozhdeniye, peresekayusjhiyesya gruppyi korrelyacii, otdeljnyiye proverki, neizmenyayemyiye raznoglasiya, dokazateljnyij vyibor, ispolnyayemyiye byudzhetyi s rezervami, neblokiruyusjheye ozhidaniye podtverzhdeniya i odin terminaljnyij iskhod.

[Avtonomnaya skvoznaya priyomka](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0081-provesti-avtonomnuyu-priyomku-raspredelyonnogo-myisliteljnogo-epizoda.md) zavershena na zapisannyikh fiksturakh. Odin lokaljnyij rezhim `./Прототипы/проверяемый-многоагентный-контур/запустить.sh acceptance all` vyidayot determinirovannyij kanonicheskij JSON-otchyot dlya chetyiryokh scenariyev. Polozhiteljnyij scenarij provodit dva raznyikh rabochikh paketa i dvukh proizvoditelej cherez instrumentaljnoye nablyudeniye, otdeljnuyu proverku, vyibor i `goal_met`; mezhdu vkladami novyij process vosstanavlivayet podtverzhdyonnyij `CURRENT`, a itog nepreryivnogo i vozobnovlyonnogo progonov sovpadayet pobajtovo. Ostaljnyiye scenarii otdeljno proveryayut lozhnyij konsensus bez prinyatiya, ischerpaniye byudzheta do publikacii sleduyusjhego dejstviya i ozhidaniye podtverzhdeniya cherez lokaljnuyu trassu versii `3` s dvumya ogranichennyimi vetvyami ot obsjhego predka i vnutrennim otborom bez poljzovateljskogo dopuska.

Trebovaniye ostayotsya `🚧`, potomu chto zapisannyiye proizvoditeli, proveryayusjhij i instrumentaljnyiye otvetyi ne yavlyayutsya zhivyimi ispolnitelyami. Priyomka ne ispoljzuyet setj, sekretyi, zhivuyu modelj ili zhivoj instrument i ne dokazyivayet zhivoj raspredelyonnyij mnogomodeljnyij progon, kriptograficheskuyu podlinnostj libo semanticheskuyu nezavisimostj vkladov.

Trebovaniye ne prisvaivayet tekusjhim subagentam Codex status vnutrennikh FUM, soznaniye ili fakticheskuyu nezavisimostj.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-02 13:26:18 MSK — Provesti avtonomnuyu priyomku raspredelyonnogo myisliteljnogo epizoda](../Zhurnal/2026-08-02_13-26-18_MSK_provesti-avtonomnuyu-priyomku-raspredelyonnogo-myisliteljnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-02 09:36:50 MSK — Dobavitj vyibor, byudzhetyi i usloviye ostanovki epizoda](../Zhurnal/2026-08-02_09-36-50_MSK_dobavitj-vyibor-byudzhetyi-i-usloviye-ostanovki-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-01 23:00:38 MSK — Dobavitj vosstanavlivayemuyu obsjhuyu pamyatj raspredelyonnogo epizoda](../Zhurnal/2026-08-01_23-00-38_MSK_dobavitj-vosstanavlivayemuyu-obsjhuyu-pamyatj-raspredelyonnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-02 01:12:32 MSK — Zafiksirovatj proiskhozhdeniye i ogranichennuyu nezavisimostj vkladov poduzlov](../Zhurnal/2026-08-02_01-12-32_MSK_zafiksirovatj-proiskhozhdeniye-i-ogranichennuyu-nezavisimostj-vkladov-poduzlov/zapros.md)
- [minimaljnyij pasport peredavayemogo rezuljtata FUM](../Dokumentaciya/39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 16:49:34 MSK -->
<!-- content-sha256: sha256:5d8a3eec4c5ac129914ec8d6bb54daa396f67b9039892dcedbb103b7d4ca78e9 -->
<!-- FUM-MD-RECENCY:END -->
