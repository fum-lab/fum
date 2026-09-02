# Vyibor sleduyusjhego shaga vetki iz kartochek shagov

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0016 -->

Ekspluatacionnyij status: otlozheno. Kartochka sokhranyayet vetochnyij selector i yego FIFO-dopusk kak arkhitekturnuyu narabotku; yeyo imperativnyij tekst ne dejstvuyet dlya ruchnoj posledovateljnoj zapisi i ne razreshayet avtomaticheskij vyibor rabotyi.

Yesli u razvivayemoj imenovannoj [vetki rabotyi](../Glossarij/vetka-rabotyi.md) ostayutsya vozmozhnyiye [sleduyusjhiye shagi](../Glossarij/sleduyusjhij-shag-vetki.md), yeyo vetochnaya zapisj dolzhna khranitj otkryityij versionnyij whitelist susjhestvuyusjhikh kanonicheskikh [kartochek shagov](../Glossarij/kartochka-shaga.md). Nabor ne materializuyet `ready` zaraneye: on attestuyet nezavisimo dopustimyiye kartochki kak `dispatch=automatic`, sokhranyayet tochnyiye ALL-of-zavisimosti ot zavershyonnyikh kartochek i otdeljno uderzhivayet yavnyiye `paused` ili `blocked` s usloviyami vozobnovleniya. Posle dopuska sessiya-prodolzheniye napryamuyu perechityivayet tochnyij `HEAD`, zanovo vyichislyayet gotovnostj vsego nabora i vyibirayet konkretnyij gotovyij shag. Korrektnyij negotovyij kandidat ne uchastvuyet v ranzhirovanii i ne ostanavlivayet ispolneniye nezavisimogo gotovogo.

Vetochnaya zapisj khranit polnyij ref vetki, verkhneurovnevoye sostoyaniye `open` ili `done`, proyekt i massiv kandidatov. Kazhdaya kandidatnaya zapisj khranit ustojchivyij `step_id` konkretnoj versii, `dispatch`, identifikator kartochki, khyesh yeyo soderzhaniya i massiv `requires_completed_card_ids`; dlya yavnyikh `paused` i `blocked` obyazateljno usloviye vozobnovleniya. Identifikator kartochki ne podmenyayet `step_id`: izmeneniye kartochki, yeyo puti, khyesha, `dispatch`, specifikacii zavisimostej ili usloviya vozobnovleniya dolzhno davatj novuyu versiyu kandidatnoj zapisi. Izmeneniye toljko nablyudayemogo statusa obyazateljnoj kartochki sokhranyayet `step_id`, no menyayet vyichislennyij status i `selection.id`. Zadacha, kriterii zaversheniya i istochniki chitayutsya iz runtime-gotovoj kartochki, a ne iz nezavisimoj kopii v vetochnoj zapisi.

## Semanticheskiye svyazi

- **zavisit ot:** [atomarnyikh kartochek planovyikh shagov](✅-atomarnyiye-kartochki-planovyikh-shagov.md) — vetochnyij vyibor mozhet ssyilatjsya toljko na indeksirovannuyu kanonicheskuyu kartochku s proveryayemoj identichnostjyu.
- **dopolnyayetsya:** [poljzovateljskim perenapravleniyem nepreryivnogo agentskogo cikla](🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) — diskretnaya smena prodolzheniya mezhdu zadachami stanovitsya prototipom dlya rabotayusjhego produktovogo cikla.
- **trebuyetsya dlya:** [kontekstno posiljnyikh ispolnyayemyikh shagov](🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md) — vyichislennyij runtime-pul `ready` yavlyayetsya tochkoj prinyatiya kontekstno ogranichennoj kartochki dopusjhennoj sessiyej-prodolzheniyem.
- **trebuyetsya dlya:** [izolirovannogo paralleljnogo ispolneniya i proveryayemoj integracii](✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md) — kazhdyij izolirovannyij zapusk dolzhen proiskhoditj iz tochnoj versii odnoj kanonicheskoj kartochki shaga.
- **usilivayetsya:** [vetochnyimi cepochkami shagov i zaversheniyem smoke-check kommitom](🚧-vetochnyiye-cepochki-shagov-i-zaversheniye-smoke-check-kommitom.md) — kandidat poluchayet proveryayemuyu prinadlezhnostj konechnoj cepochke i yeyo tochnoj vetke fiksacii.

## Kriterii proverki

- dlya kazhdoj avtomaticheski razvivayemoj imenovannoj vetki validator nakhodit rovno odnu vetochnuyu zapisj;
- verkhneurovnevaya zapisj skhemyi `5` i kazhdyij kandidat soderzhat toljko polya svoyej formyi; otkryitaya zapisj soderzhit khotya byi odnogo kandidata, a sostoyaniye `done` — obyazateljnyij yavnyij `candidates = []`;
- vse `card_id` i `step_id` vnutri nabora unikaljnyi, kazhdaya zapisj ssyilayetsya na aktualjnuyu kartochku po ustojchivomu identifikatoru, zakreplyayet tochnyij khyesh yeyo soderzhaniya, dopustimyij `dispatch` i massiv `requires_completed_card_ids`;
- kazhdyij `automatic` predvariteljno prokhodit proverki bezopasnosti, polnomochij i kontekstnoj posiljnosti; pustoj massiv zavisimostej vyichislyayetsya kak runtime-`ready`, a nepustoj — toljko kogda vse tochnyiye kartochki imeyut literal-status `completed`;
- `active`, `absorbed` i `withdrawn` ne udovletvoryayut zavisimosti `requires_completed_card_ids`; svobodnyij `resume_condition`, ssyilki, vremya, setj, sreda, sekretyi i modeljnyij vyivod ne interpretiruyutsya kak gotovnostj;
- neizvestnaya obyazateljnaya kartochka, povtor, samozavisimostj ili cikl zakryivayut nabor; yavnyiye `paused` i `blocked` trebuyut nepustogo usloviya vozobnovleniya, avtomaticheski ne otkryivayutsya i pri korrektnoj forme ne meshayut nezavisimomu runtime-`ready`;
- zadacha, kriterii zaversheniya i istochniki v mashinnom otvete i zadache Codex poluchayutsya iz vyibrannoj runtime-gotovoj kartochki, a ne iz nezavisimoj kopii;
- toljko posle FIFO-dopuska sessiya vyizyivayet selektor, kotoryij zanovo vyichislyayet gotovnostj na tochnom `HEAD` i po politike `dynamic-readiness-source-history-first-parent-v2` rassmatrivayet ne boleye 16 kommitov ot novogo k staromu po pervoj roditeljskoj linii;
- dlya sopostavleniya kazhdogo kandidata ispoljzuyutsya toljko deduplicirovannyiye normalizovannyiye lokaljnyiye ssyilki iz yego razdela `Источники`; sobstvennyij putj kandidatnoj kartochki, sluzhebnyiye i upravlyayusjhiye puti isklyuchayutsya;
- pervyim signalom svyazannosti sluzhit izmenyonnaya zavershyonnaya ili poglosjhyonnaya kartochka sredi istochnikov kandidata, sleduyusjhim — tochnoye izmeneniye inogo istochnika; vnutri klassa uchityivayutsya menjshaya distanciya, boljsheye chislo unikaljnyikh sovpavshikh putej i zatem para `card_id`, `step_id`, a pri otsutstvii razlichayusjhego signala primenyayetsya srazu eta ustojchivaya para;
- svyazannostj istorii yavlyayetsya myagkim pravilom poryadka toljko vnutri vyichislennogo mnozhestva dopustimyikh `ready` i ne otmenyayet zavisimosti, bezopasnostj, polnomochiya, yavnyij vyibor poljzovatelya ili kontekstnuyu posiljnostj;
- mashinnyij otvet zakreplyayet obyyekt `selection` s `id`, `policy`, tochnyim `head`, `ready_count` i svideteljstvom `reason`, `commit`, `distance`, `matched_paths`, a dopusjhennaya sessiya poluchayet te zhe znacheniya vmeste s vyibrannyimi kartochkoj i `step_id`;
- zapusk zakryivayetsya pri otsutstvuyusjhej, neindeksirovannoj, povrezhdyonnoj ili nedopustimoj po zhiznennomu statusu kartochke, nevernom khyeshe, povtore identifikatorov, nedopustimyikh polyakh libo nesovpadenii ozhidayemyikh `branch_ref`, `selection.id`, `selection.head` ili `step_id`;
- izmeneniye kartochki, yeyo puti, soderzhateljnogo khyesha, `dispatch`, massiva zavisimostej ili usloviya vozobnovleniya trebuyet novogo `step_id`; izmeneniye nablyudayemogo rezuljtata zavisimosti menyayet `selection.id` bez perevyipuska `step_id`; sessiya prinimayet vyibor toljko pri sovpadenii polnogo ref, tochnogo `selection.head`, `selection.id` i tekusjhego FIFO-dopuska;
- zhiznennyij status kartochki, obyyavlennyij `dispatch` i vyichislennyij runtime-status proveryayutsya razdeljno: `active` sama po sebe ne razreshayet ispolneniye;
- `selection.id` khyeshiruyet obyyavleniya i rezuljtatyi gotovnosti vsekh kandidatov, puti i khyeshi ikh sobstvennyikh kartochek, usloviya yavnogo vozobnovleniya, nezavershyonnyiye zavisimosti i tochnyiye `card_id`, puti, statusyi i khyeshi obyazateljnyikh kartochek vmeste s gotovyim pulom, pobeditelem i svideteljstvom ranzhirovaniya;
- zavershyonnaya sessiya udalyayet vyipolnennoye pokoleniye i obnovlyayet whitelist dopustimosti, no ne vyichislyayet i ne predvyibirayet pobeditelya sleduyusjhego zapuska; otkryityij nabor bez runtime-`ready` yavno oznachayet otsutstviye ispolnyayemogo shaga sejchas, a `done` ne podmenyayetsya ssyilkoj na vyipolnennuyu ili snyatuyu kartochku.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: trebovaniye realizovano v dokumentacionnom prototipe: vetochnaya zapisj skhemyi `5` khranit proveryayemyij whitelist kanonicheskikh kartochek i tochnyiye zavisimosti, a pryamoj selektor dopusjhennoj sessii vyichislyayet runtime-gotovnostj, proveryayet formu i individualjnuyu dopustimostj kandidatov, vyibirayet po ogranichennoj istorii istochnikov i zakreplyayet polnoye dokazateljstvo vyibora v `selection.id`.

Trebovaniye zadayot toljko ogranichennyij istochnik-svyaznyij poryadok i ne realizuyet obsjhuyu optimizaciyu poleznosti, stoimosti ili riska. Ono ne sozdayot novuyu zadachu, ne dokazyivayet tranzakcionnostj Codex-host s Git i ne koordiniruyet otdeljnyiye klonyi. Sozdaniye prodolzheniya, FIFO i vosstanovleniye sokhranyayutsya otdeljnyimi kontraktami.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-29 09:04:03 MSK — Rasshiritj dinamicheskij vyibor sleduyusjhego shaga](../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [iskhodnyij zapros 2026-07-27 18:28:42 MSK — Vyibiratj sleduyusjhij shag pri zapuske s uchyotom istorii kommitov](../Zhurnal/2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK — Dekompozirovatj predlozheniya na kartochki shagov](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK — Zafiksirovatj poshagovyij otbor realizacii](../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK — Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-20 21:22:17 MSK — Vklyuchitj kartochki trebovanij v mashinnyij planovyij reyestr](../Zhurnal/2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)
- [iskhodnyij zapros 2026-07-22 03:38:35 MSK — Razreshitj vyipolneniye dostupnyikh kartochek shagov](../Zhurnal/2026-07-22_03-38-35_MSK_razreshitj-vyipolneniye-dostupnyikh-kartochek-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:c0fb6c2efb52b94b046419436dfff3d62eefa312e5172d875cc35008eda4fbbd -->
<!-- FUM-MD-RECENCY:END -->
