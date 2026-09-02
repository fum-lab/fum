+++
schema_version = 1
card_id = "FUM-STEP-0119"
status = "completed"
+++
# Zakrepitj topologiyu i pasport universaljnogo fork-poduzla-ispolnitelya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj lokaljnyij kontrakt repozitornoj kompozicii otdeljnyim vidom dolgovechnogo universaljnogo ispolnitelya. Pasport dolzhen otlichatj obsjhij profilj sposobnostej, kontekstnuyu rolj i polnomochiya konkretnogo naznacheniya, zakreplyatj ustojchivyiye identichnosti yadra, assembly, rebyonka i repozitoriya, raznyiye `origin` i `upstream`, zerkaljnyij `master`, rolevyiye linii, putj submodule, prinyatyij gitlink, polnyij zhivoj ref, sobstvennyiye branch-scoped FIFO i obyazateljnoye prodolzheniye vetki s pryamyim selector, a takzhe marshrutyi pull request; validator dolzhen dokazyivatj otdeljnostj detached-snimka i zhivogo klona i zakryivatjsya otkazom pri samorekursii.

## Rezuljtat

Proveryayemyij mnogoagentnyij kontur rasshiren dvumya otdeljnyimi zakryityimi JSON-skhemami s kirillicheskimi smyislovyimi polyami: roditeljskoj registraciyej universaljnogo fork-poduzla i sobstvennyim pasportom rebyonka. ASCII-sovmestimyiye identifikatoryi skhem i ssyilki na opredeleniya ostayutsya strogimi URI-reference. Registraciya razlichayet logicheskuyu identichnostj kompozicii i identichnostj yeyo repozitoriya, svyazyivayet ustojchivyiye identichnosti yadra, assembly, rebyonka i repozitoriya s tochnyim prinyatyim gitlink, a pasport otdelyayet obsjhij profilj sposobnostej ot versionirovannoj kontekstnoj roli i ogranichennyikh polnomochij konkretnogo naznacheniya. Smena roli sokhranyayet identichnostj ispolnitelya i ne mozhet neyavno rasshiritj dostup.

Pasport zakreplyayet proveryayemuyu Git-topologiyu: tochnyij kornevoj `upstream`, otlichnyij ot nego sobstvennyij `origin`, zerkaljnyij `master` na opublikovannom pokolenii upstream, otdeljnyiye rolevyiye refs, razreshyonnyiye celi pull request, polnyij zhivoj ref, putj submodule i sinkhronizirovannuyu osnovu gitlink. Roditeljskaya registraciya khranit etot polnyij ref kak adres, no ne kopiruyet v assembly zhivoye sostoyaniye sobstvennyikh FIFO, kvitancij obyazateljnogo prodolzheniya, rabochego nabora selector ili vetki rebyonka; fork nasleduyet svobodnoye ot ekzemplyarov yadro, a ne roditeljskuyu assembly.

Materializovannyij submodule proveryayetsya kak chistyij detached-snimok tochnogo prinyatogo commit, prinadlezhasjhij zaregistrirovannyim puti i checkout assembly; sekciya `.gitmodules`, URL, rezhim `160000` i gitlink obyazanyi sovpadatj. Pishusjhij klon imeyet otdeljnyij Git common-dir, sobstvennyij prikreplyonnyij polnyij ref i tochnyij prinyatyij HEAD. Vnutri rebyonka avtonomnaya branch-specific oblastj planirovaniya soderzhit kartochku s khyesh-ograzhdeniyem, a skopirovannyij pryamoj selector fakticheski vyipolnyayet `show` i vyibirayet yeyo v rolevoj vetke.

Dvadcatj odna otricateljnaya fikstura zakryivayetsya otkazom pri sovpavshikh `origin` i `upstream`, nevernom kornevom upstream, lokaljnom commit ili raskhozhdenii zerkaljnogo `master`, ustarevshem pokolenii naznacheniya, otsutstvuyusjhem libo nesovpadayusjhem pasporte, podmene kompozicionnoj identichnosti, nedostizhimom gitlink, nevernom checkout ili `.gitmodules`, neizvestnom URL, zapisi cherez submodule i lyubom obnaruzhennom cikle materializovannogo grafa, vklyuchaya povtornyij vkhod v raneye obojdyonnoye podderevo iz novogo aktivnogo puti. Istoricheskaya skhema repozitornoj kompozicii versii `1` i vid `specialized_subnode` sokhranenyi bez pereinterpretacii kak sovmestimyij istoricheskij kontrakt prezhnego prototipa.

Postavka ostayotsya polnostjyu lokaljnoj: ona ne sozdayot vneshnij fork, remote, submodule ili zadachu Codex, ne vyipolnyayet setevuyu publikaciyu i ne zayavlyayet zhivuyu orkestraciyu. Kontrakt i avtonomnyiye fiksturyi podgotavlivayut proveryayemuyu osnovu dlya otdeljnoj konechnoj delegacii bez rasshireniya vneshnikh polnomochij.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0090 — avtonomnaya skvoznaya priyomka repozitornoj kompozicii](✅-FUM-STEP-0090-provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 08:15:36 MSK -->
<!-- content-sha256: sha256:ad11d04d21781b60669271f468c753da0333554f2d35602bd204409853edad54 -->
<!-- FUM-MD-RECENCY:END -->
