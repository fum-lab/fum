+++
schema_version = 1
card_id = "FUM-STEP-0120"
status = "completed"
+++
# Zakrepitj pasport delegirovaniya konechnoj cepochki kartochek

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zakrepitj otdeljnyimi zakryityimi mashinochitayemyimi kontraktami naznacheniye konechnoj linejnoj cepochki kartochek i pasport yeyo sostoyaniya, svyazatj ikh s tochnyimi istochnikami, granicami, Git-vershinami, vetochnoj FIFO, obyazateljnyimi prodolzheniyami i marshrutom rezuljtata, a zatem avtonomno dokazatj dopustimyiye prefiksyi i adresnyiye otkazyi bez zhivyikh host-, Git-, setevyikh ili modeljnyikh effektov.

## Rezuljtat

V proveryayemyij SwiftPM-prototip dobavlenyi dve zakryityiye mashinochitayemyiye skhemyi pokoleniya `1`: [naznacheniye konechnoj linejnoj cepochki](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/DelegirovaniyeKonechnojCepochki/skhema-naznacheniya-konechnoj-linejnoj-cepochki-v1.json) i [pasport yeyo sostoyaniya](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/DelegirovaniyeKonechnojCepochki/skhema-sostoyaniya-konechnoj-linejnoj-cepochki-v1.json). Naznacheniye svyazyivayet tochnyij pasport universaljnogo ispolnitelya, kontekstnuyu rolj, kornevoye pokoleniye, iskhodnyij Git-obyyekt, kartochku cepochki, rabochij nabor i konechnyij uporyadochennyij spisok kartochek po identifikatoram, putyam i SHA-256 bez kopirovaniya ikh soderzhaniya. Odna neprozrachnaya identichnostj fizicheskoj rabochej kopii i polnyij rabochij ref zakreplenyi za vsej cepochkoj i otlichayutsya ot polnogo celevogo ref.

V kanonicheskij khyesh naznacheniya vkhodyat konechnyiye oblasti i isklyucheniya, instrumentyi, dostup, vneshniye effektyi, byudzhetyi, parallelizm, glubina rekursii, proverki, ostanovka, vozobnovleniye, terminaljnyiye iskhodyi, klass i marshrut rezuljtata, celevyiye repozitorij i ref. Zakryityiye paryi razlichayut sobstvennyij rezuljtat rebyonka, proyektnyij rezuljtat i obsjhij vklad fork — yadro; toljko obsjhij vklad trebuyet celj pull request i yavnyij priznak kandidata perenosimogo navyika. Effektivnyiye granicyi sostoyaniya mogut toljko suzhatj vyidannyiye mnozhestva i chislovyiye predelyi.

Pasport sostoyaniya svyazyivayet nachaljnuyu zadachu sredyi, tu zhe rabochuyu kopiyu i rabochij ref, uporyadochennyiye shagi, tochnyiye chastnyiye pasporta, raskhod i proverki kazhdogo shaga, sovokupnyij byudzhet, odnoroditeljskiye kommityi, podtverzhdyonnyiye vkhodnyiye vershinyi, strogij poryadok vetochnoj FIFO i rovno odno zaraneye sozdannoye prodolzheniye kazhdogo osmyislennogo kommita. Otdeljnyiye zapisi aktivnogo dopuska i zaversheniya bez kommita svyazyivayut tekusjhego vladeljca libo `finish-clean` s tochnoj kartochkoj, vershinoj, rabochej liniyej i snimkom ocheredi. Proveryayusjhaya i integracionnaya zadachi otdelenyi ot posledovateljnogo vladeniya, obyazanyi razlichatjsya i dopuskayutsya toljko posle gotovnosti diapazona; politika prinyatiya razreshayet vsyu cepochku libo yavno nazvannyij susjhestvuyusjhij tochnyij prefiks.

Lokaljnyij konechnyij interpretator snachala ispolnyayet obe opublikovannyiye zakryityiye skhemyi JSON Schema Draft 2020-12, a zatem semanticheskij validator sopostavlyayet dokumentyi s otdeljno predostavlennyim neizmenyayemyim doverennyim kontekstom: tochnyimi kartochkami i rabochim naborom, epokhoj i snimkom FIFO, dopuskami, svyazannyimi commit-kvitanciyami i svideteljstvom `finish-clean`. Avtonomnaya dvukhshagovaya fikstura i [43 adresnyikh TDD-scenariya](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Tests/FUMVerifiableMultiAgentContourTests/TestyiDelegirovaniyaKonechnojCepochki.swift) vosproizvodyat naznachennyij, aktivnyij, ostanovlennyij i gotovyij prefiksyi; zakryivayut podmenu istochnikov, kartochek, marshruta, vershinyi, chastnyikh pasportov i svideteljstv, rasshireniye granic, vyikhod za byudzhetyi, neodnoznachnyij JSON, ne-NFC stroki, nedopustimyiye puti i refs, obkhod libo pereprivyazku FIFO, povtor kvitancij, neavtoritetnuyu ostanovku, nepolnoye prinyatiye i prezhdevremennyiye vneshniye zadachi.

## Granica rezuljtata

Polozhiteljnaya fikstura dokazyivayet determinirovannoye ispolneniye skhem i sopostavleniye predstavlennyikh zapisej s doverennyim kontekstom, no ne vyidayotsya za zhivoye ispolneniye. Etot shag ne stroit kontekst iz Git i host, ne sozdayot host-zadachi, FIFO-biletyi, klonyi, refs, kommityi ili pull request, ne vyizyivayet setj i modelj i ne dvigayet celevoj ref. Adapter zhivogo kontura i fakticheskoye vozobnovlyayemoye ispolneniye dvukh i boleye shagov prinadlezhat FUM-STEP-0121, a dvoichnoye vetvleniye, soyedineniye i roditeljskaya moderaciya — otdeljnomu pasportu FUM-STEP-0145.

## Istochniki

- [tekusjhij zapros 2026-08-12 09:11:46 MSK — Zakrepitj pasport delegirovaniya konechnoj cepochki kartochek](../../Zhurnal/2026-08-12_09-11-46_MSK_zakrepitj-pasport-delegirovaniya-konechnoj-cepochki-kartochek/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0119 — topologiya universaljnogo fork-poduzla](✅-FUM-STEP-0119-zakrepitj-topologiyu-i-pasport-universaljnogo-fork-poduzla-ispolnitelya.md)
- [FUM-STEP-0075 — kontekstno posiljnyij rabochij paket](✅-FUM-STEP-0075-zakrepitj-kontrakt-kontekstno-posiljnogo-rabochego-paketa-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 11:28:35 MSK -->
<!-- content-sha256: sha256:3f529a0b99a05ac8e82aa63c7680cb66be176a0cafbf4ab18fd55bc913b4ee2c -->
<!-- FUM-MD-RECENCY:END -->
