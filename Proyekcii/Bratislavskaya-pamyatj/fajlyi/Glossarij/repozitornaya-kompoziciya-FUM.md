# Repozitornaya kompoziciya FUM

Repozitornaya kompoziciya FUM — aciklichnaya sistema samostoyateljnyikh Git-repozitoriyev [poduzlov FUM](poduzel-FUM.md) i proyektov, svyazannyikh proveryayemyimi Git-ssyilkami, pasportami peredachi i zakreplyonnyimi versiyami. Kazhdyij dochernij repozitorij sokhranyayet sobstvennuyu istoriyu, granicu dostupa, publikaciyu i pravo peredavatj rezuljtat vverkh.

Git submodule v takoj kompozicii — proyekciya prinyatogo snimka, a ne rabocheye mesto [pishusjhego poduzla FUM](pishusjhij-poduzel-FUM.md). Gitlink zakreplyayet tochnyij OID, no ne vetku, ne importiruyet docherniye kommityi v Git-DAG nadsistemyi i ne dokazyivayet ikh dostizhimostj iz remote. Dochernij commit zakreplyayetsya pod razreshyonnyim polnyim ref i proveryayetsya do togo, kak roditelj obnovit gitlink; kandidatnyij rezuljtat mozhet dopolniteljno imetj dolgovechnyij `result_ref`.

[Universaljnyij ispolniteljnyij poduzel FUM](universaljnyij-ispolniteljnyij-poduzel-FUM.md) podklyuchayetsya imenno kak dolgovechnyij dochernij repozitorij, a ne kak efemernyij klon popyitki. Yego prinyatyij snimok nakhoditsya v assembly-submodule, togda kak zhivaya cepochka shagov razvivayetsya cherez otdeljnyiye klonyi popyitok i yedinyij rabochij ref; celevoj ref rebyonka ne menyayetsya do prinyatiya, a yego obnovleniye samo po sebe ne dvigayet gitlink roditelya.

U samostoyateljnogo proyekta razdelenyi dochernij pasport i roditeljskaya registraciya. Docherniye `README.md` i `Паспорт-проекта.json` opisyivayut celj, ustojchivyiye identichnosti, rabochij ref, granicyi, istochniki, proverki i puti sobstvennyikh pravil, ocheredi, vetochnogo selektora i sleduyusjhego shaga, no ne soderzhat OID vklyuchayusjhego ikh kommita ili gitlink na sebya. Roditeljskaya registraciya khranit toljko kompozicionnyiye polya i tochnyij gitlink i ne kopiruyet zadachu libo upravlyayusjheye sostoyaniye proyekta.

Ocheredj i [obyazateljnoye prodolzheniye vetki](obyazateljnoye-prodolzheniye-vetki.md) prinadlezhat fizicheskomu checkout dochernego repozitoriya i tochnomu polnomu ref. Ikh sluzhebnyiye refs i kvitancii ne perenosyatsya cherez bare-repozitorij i ne vyivodyatsya iz sostoyaniya roditeljskogo checkout. Roditelj sposoben proveritj registracionnuyu zapisj i tochnyij gitlink do materializacii submodule; otdeljnyij zhivoj klon sozdayot dochernij commit, a roditelj zatem obnovlyayet registraciyu i gitlink otdeljnyim compare-and-swap-kommitom.

Repozitornaya kompoziciya zapresjhayet pryamyiye i kosvennyiye ciklyi po kanonicheskim identichnostyam repozitoriyev. Repozitorij specializacii poduzla otdelyayetsya ot celevogo repozitoriya yego rabotyi, a proyektnyij repozitorij ne ssyilayetsya submodule-ssyilkoj obratno na roditeljskuyu kompoziciyu. Takoye razdeleniye ne pozvolyayet polnomu fork FUM, vlozhennomu obratno v FUM, porozhdatj samossyilochnuyu iyerarkhiyu pri sinkhronizacii.

## Svyazannyiye dokumentyi

- [Indeks i kontrakt samostoyateljnyikh proyektov](../Proyektyi/README.md)
- [Repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [Trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [Paralleljnaya rabota i sliyaniye](../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [iskhodnyij zapros 2026-08-04 17:51:27 MSK — Perevesti proyektyi na repozitorii-submodule s sobstvennyimi ocheredyami](../Zhurnal/2026-08-04_17-51-27_MSK_perevesti-proyektyi-na-repozitorii-submodule-s-sobstvennyimi-ocheredyami/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:044d74030de4978d06b3adf2230c86a319206daf8bbbbdfc3e73a25bb5d973cb -->
<!-- FUM-MD-RECENCY:END -->
