# Proyektyi

Katalog yavlyayetsya indeksom roditeljskikh registracij samostoyateljnyikh proyektov v [repozitornoj kompozicii FUM](../Glossarij/repozitornaya-kompoziciya-FUM.md). Kazhdyij novyij proyekt imeyet otdeljnyij Git-repozitorij i podklyuchayetsya po puti `Проекты/<краткое-имя>` kak submodule na tochnyij proverennyij commit. Obyichnyij vlozhennyij katalog bez zapisi dereva rezhima `160000` ne yavlyayetsya proyektom kompozicii.

Kornevoj FUM ostayotsya opisan v [glavnom README](../README.md) i ne poluchayet otdeljnyij proyektnyij pasport. V tekusjhej pamyati yesjhyo net realjnogo proyektnogo submodule: avtonomnaya lokaljnaya fikstura proveryayet kontrakt na vremennyikh bare-repozitoriyakh, no ne yavlyayetsya registraciyej vneshnego proyekta i ne dobavlyayetsya v etot indeks.

## Roditeljskaya registraciya

Mashinnyiye registracii razmesjhayutsya v `Проекты/регистрации/<устойчивый-идентификатор>.json`. Kazhdaya registraciya khranit vid `project`, ustojchivyiye identichnosti proyekta i repozitoriya, publikacionno dopustimyij adres repozitoriya, polnyij zhivoj ref, putj submodule, tochnyij gitlink, urovenj dostupa, publikacionnuyu granicu, obyazateljnyiye proverki i marshrut peredachi rezuljtata. Vremennyij putj lokaljnogo klona ostayotsya vneshnim runtime-kontekstom i ne popadayet v registraciyu.

Registraciya ne kopiruyet celj, soderzhateljnuyu zadachu, pravila, ocheredj, sostoyaniye prodolzheniya, kartochku ili rabochij nabor proyekta. Tochnyij prinyatyij OID prisutstvuyet v roditeljskoj registracii i v gitlink roditeljskogo dereva; dochernij repozitorij ne zapisyivayet sobstvennyij OID vnutrj pasporta togo zhe kommita.

## Pasporta i upravlyayusjhij sloj proyekta

V korne dochernego repozitoriya nakhodyatsya dva svyazannyikh predstavleniya pasporta:

- `README.md` dayot cheloveku celj proyekta, granicyi i ssyilki na upravlyayusjhiye materialyi;
- `Паспорт-проекта.json` yavlyayetsya zakryityim mashinnyim kontraktom i khranit identichnosti proyekta i repozitoriya, ustojchivyij adres, celj, polnyij osnovnoj ref, dostup i publikacionnuyu granicu, puti pravil, ocheredi, vetochnogo selektora, rabochego nabora i kartochki, khyesh rabochego nabora, istochniki, proverki i usloviye zaversheniya.

Mashinnyij pasport ne soderzhit OID sobstvennogo vklyuchayusjhego kommita i ne soderzhit gitlink na proyekt. `README.md` svyazyivayet mashinnyij pasport, sobstvennyij `AGENTS.md` i [rabochij nabor sleduyusjhego shaga vetki](../Glossarij/sleduyusjhij-shag-vetki.md). Pasport ne zamenyayet iskhodnyiye zaprosyi, proizvodnuyu dokumentaciyu, trebovaniya ili zhurnal; sekretyi, uchyotnyiye dannyiye i nepublikuyemoye mashinnoye sostoyaniye v publichnoj pamyati ne sokhranyayutsya.

Ocheredj zapisi i [obyazateljnoye prodolzheniye vetki](../Glossarij/obyazateljnoye-prodolzheniye-vetki.md) proyekta privyazanyi k fizicheskomu checkout i tochnomu polnomu ref; sluzhebnyiye refs i kvitancii vyichislyayutsya iz yego Git common-dir. Roditeljskij checkout imeyet otdeljnuyu ocheredj i sobstvennuyu cepochku prodolzhenij; yego dopusk ili zanyatostj nichego ne dokazyivayut o proyekte. Sluzhebnyiye refs ne publikuyutsya v bare-repozitorij proyekta i ne perenosyatsya v svezhij zhivoj klon.

## Ispolneniye i obnovleniye gitlink

Do materializacii submodule roditelj proveryayet registraciyu, `.gitmodules`, rezhim `160000`, tochnyij gitlink i dostizhimostj commit iz obyyavlennogo repozitoriya. Otsutstviye materialized checkout ne razreshayet vyibiratj vershinu `live_ref`, vyipolnyatj `update --remote` ili inache ugadyivatj sostoyaniye proyekta. Yavnaya materializaciya dolzhna vosstanovitj chistyij detached-snimok rovno na zakreplyonnom OID.

Pishusjhij shag vyipolnyayetsya toljko v otdeljnom zhivom klone proyektnogo repozitoriya. Proyektnyij commit snachala zakreplyayetsya v polnom ref proyekta i proveryayetsya, ne menyaya roditelj. Zatem otdeljnyij integracionnyij klon roditelya pri sovpavshikh ozhidayemyikh vershine roditelya, prezhnem gitlink i novoj proyektnoj vershine sozdayot odnoroditeljskij commit, kotoryij menyayet toljko proyektnyij gitlink i soglasovannuyu roditeljskuyu registraciyu, i peredayot yego tochnyim compare-and-swap. Proverochnaya fikstura posle etogo yesjhyo raz prodvigayet zhivoj ref proyekta neprinyatyim dochernim commit: parent-only-proverka i yavnaya materializaciya vsyo ravno vosstanavlivayut prezhnij prinyatyij gitlink, a ne novuyu vershinu vetki.

Ustarevshaya roditeljskaya vershina, izmenivshijsya prezhnij gitlink, proigrannyij CAS, konflikt ili neizvestnyij klass ne razreshayutsya vyiborom odnoj storonyi. Integraciya zakryivayetsya bez dvizheniya celevogo ref; dejstvuyusjhij ogranichennyij resolver ne ustranyayet gitlink-konfliktyi.

## Zakryityiye otricateljnyiye granicyi

Avtonomnaya proverka proyekta obyazana zakryivatjsya otkazom bez neozhidannogo dvizheniya refs v semi sluchayakh:

- obyichnyij katalog nakhoditsya na meste gitlink;
- otsutstvuyet mashinnyij pasport proyekta;
- otsutstvuyet rabochij nabor sleduyusjhego shaga;
- proyekt ispoljzuyet obsjhij checkout s roditelem;
- registraciya i fakticheskij gitlink ne sovpadayut;
- proyekt obrazuyet pryamoj ili tranzitivnyij cikl repozitornoj kompozicii;
- urovenj dostupa ili publikacionnaya granica delayut dochernij commit nedostupnyim roditelyu.

## Granicyi dostupa i tekusjhego dokazateljstva

Publichnaya kompozicionnaya sborka mozhet podklyuchatj toljko publikacionno dopustimyiye i vosproizvodimo dostupnyiye repozitorii i ne dolzhna raskryivatj URL ili imena privatnyikh proyektov. Proyektyi s zakryityimi materialami podklyuchayutsya v privatnoj sborke; naruzhu iz nikh peredayotsya toljko yavno razreshyonnyij obezlichennyij rezuljtat.

Proverennyij proyektnyij scenarij sozdayot toljko vremennyiye lokaljnyiye bare-repozitorii proyekta i roditelya. On ne obrasjhayetsya k seti, ne sozdayot vneshnij proyekt ili remote, ne publikuyet lokaljnyiye puti kak ustojchivyiye adresa i ne dokazyivayet polnuyu skvoznuyu kompoziciyu neskoljkikh pishusjhikh poduzlov.

## Svyazannyiye materialyi

- [Trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [Repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [Sleduyusjhiye shagi vetok](../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)
- [Publichnyij upstream i forki pamyati FUM](../Dokumentaciya/27-publichnyij-upstream-i-forki-pamyati.md)
- [Paralleljnaya rabota i sliyaniye](../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-04 17:51:27 MSK — Perevesti proyektyi na repozitorii-submodule s sobstvennyimi ocheredyami](../Zhurnal/2026-08-04_17-51-27_MSK_perevesti-proyektyi-na-repozitorii-submodule-s-sobstvennyimi-ocheredyami/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK - Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-21 18:31:35 MSK — Vvesti posledovateljnuyu ocheredj sessij bez hooks](../Zhurnal/2026-07-21_18-31-35_MSK_vvesti-posledovateljnuyu-ocheredj-sessij-bez-hooks/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:63722d0ffebeac287ed22d41ff2ef320d0ab32501a2f9037f303ac169cf4d680 -->
<!-- FUM-MD-RECENCY:END -->
