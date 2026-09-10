# Plan ogranichennoj statistiki vyizovov

Novyij paket chitayet toljko yavno zadannyij JSONL na publichnyikh fiksturakh. Odin atomarnyij paket kontejnera sokhranyayet novyiye normalizovannyiye sobyitiya i granicu vsego zavershyonnogo prefiksa; otdeljnogo cursor-fajla net. Do append potokovyij SHA na prezhnej granice dolzhen sovpastj. Argumentyi, polnyij vyivod, sistemnyiye soobsjheniya i skryityiye rassuzhdeniya ne sokhranyayutsya.

1. Zaversheno: RED/GREEN potokovogo chteniya, identichnosti, par call/output, neizvestnosti i timestamp.
2. Zaversheno: atomarnaya gruppa khraneniya, povtor, restart, konfliktyi, chastichnyij khvost i otkazyi zapisi; itogovyiye 35 GREEN.
3. Zaversheno: CLI JSON/Markdown, malyij/boljshoj/rabochij profilj, izmerennyiye gruppirovka i osvobozhdeniye vremennyikh obyyektov. Rabochij import 1,127 s, polnyij povtor 0,118 s, pik processa 66,391 MiB.
4. Zavershenyi read-only-revjyu, RED/GREEN poslednego zamechaniya k oracle i Swift checkpoint `85dccce282821a890e5e65539b4f22b895b52887`; OID/tree i granica publichnogo API peredanyi kornyu. FUM-manifest, otchyot i kontroljnyij diff podgotovlenyi. Posle kommita etogo materiala vyipolnyayutsya toljko proverka rezuljtata, razreshyonnyij push tochnoj FUM-vetki i peredacha yeyo OID.

Prezhniye paketyi kontejnera i snimka neizmennyi. Pravila, trebovaniya, kartochka FUM-STEP-0160 i kornevoj realjnyij import ostayutsya roditelyu. Polnyij smoke-check i obsjhaya proyekciya zdesj ne zayavlyayutsya. Mashinnyij perechenj: [prodolzheniye.json](prodolzheniye.json).

Osnovaniye: [shestj doslovnyikh upravlyayusjhikh soobsjhenij](../../zapros.md). Pervichnyij tekst peredan kornem s ukazaniyem zavershyonnoj stroki 15699 i commit `670a1fda352b34668d87000602e76e246aefa22f`; privatnyij JSONL zdesj ne chitalsya. Otdeljnyiye vetki i pobajtovyij perenos zafiksirovanyi v [svideteljstve](../perenos-napravleniya.md). Razmeryi i soobsjhyonnyiye 3771 stroka call/output pokryivayutsya chislovyimi byudzhetami, no realjnaya semanticheskaya proverka ostayotsya kornyu. Universaljnyij reader dlya arkhivnogo snimka ne dobavlyalsya: imeyusjhijsya publichnyij chitatelj read-only, no otbirayet toljko statisticheskiye sobyitiya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 16:25:24 MSK -->
<!-- content-sha256: sha256:27c6a2414a69433ea5f62f5b1de4e5a30f62ed542d68a953f90801f43f854712 -->
<!-- FUM-MD-RECENCY:END -->
