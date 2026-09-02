# Kontekstno posiljnyiye ispolnyayemyiye shagi

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0023 -->

Ekspluatacionnyij status: chastichno dejstvuyet toljko granica «odna sessiya — odin samostoyateljno proveryayemyij rezuljtat»; continuation, FIFO, selector i peredacha iz etoj kartochki otlozhenyi i ne dayut polnomochij dejstvuyusjhej ruchnoj skheme.

Kazhdyij ispolnyayemyij shag FUM dolzhen imetj s vyisokoj veroyatnostjyu zavershayemuyu v odnom svezhem kontekstnom okne granicu. V neyo vkhodyat odin samostoyateljno proveryayemyij rezuljtat, ogranichennyiye vkhodyi i izmeneniya, isklyucheniya, proverki, peredacha i obyazateljnyiye nakladnyiye raskhodyi polnoj [rabochej sessii](../Glossarij/rabochaya-sessiya.md), vklyuchaya sozdaniye prodolzheniya pered kommitom.

## Semanticheskiye svyazi

- **zavisit ot:** [atomarnyikh kartochek planovyikh shagov](✅-atomarnyiye-kartochki-planovyikh-shagov.md) — kontekstnaya granica utochnyayet smyislovuyu atomarnostj kartochki.
- **zavisit ot:** [vyibora sleduyusjhego shaga vetki iz kartochek shagov](✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md) — dopusjhennaya sessiya-prodolzheniye prinimayet toljko predvariteljno attestovannyij `automatic`, kotoryij pryamoj selektor vyichislil kak runtime-`ready` na novom `HEAD`.
- **trebuyetsya dlya:** [proveryayemogo mnogoagentnogo kontura FUM](🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md) — otdeljnyij vklad poluchayet ogranichennyij rabochij paket i dolgovremennuyu peredachu vmesto neyavnoj obsjhej istorii chatov.
- **trebuyetsya dlya:** [skvoznogo proveryayemogo odnoagentnogo epizoda FUM](✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md) — polnyij cikl dekompoziruyetsya na konechnyiye vozobnovlyayemyiye rabochiye paketyi.
- **trebuyetsya dlya:** [kommitiruyemyikh vkladov pishusjhikh poduzlov FUM](✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md) — pishusjhij poduzel dolzhen zavershitj sobstvennyij kandidatnyij commit i peredachu bez perepolneniya odnogo kontekstnogo okna.
- **trebuyetsya dlya:** [upravlyayemogo ispolneniya cepochek universaljnyimi fork-poduzlami](🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md) — dolgovechnoye naznacheniye mozhet okhvatyivatj cepochku, no kazhdyij yeyo pishusjhij perekhod ostayotsya otdeljnyim zavershayemyim rabochim paketom.

## Kriterii proverki

- kandidat `automatic` soderzhit odin samostoyateljno proveryayemyij rezuljtat, konechnyij nabor obyazateljnyikh vkhodov, yavnyiye granicyi izmenenij i isklyuchenij, konechnyiye proverki i formu peredachi;
- do attestacii `automatic` uchityivayutsya chteniye pravil, navyikov i istochnikov, fiksaciya zaprosa i zhurnala, celevyiye proverki, recency, polnyij smoke-check i atomarnyij `commit+handoff`, a runtime-`ready` zatem vyichislyayetsya toljko po tochnyim zavershyonnyim kartochechnyim zavisimostyam;
- shirokij zapros sokhranyayetsya kak istochnik, no do ispolneniya dekompoziruyetsya v zavisimuyu posledovateljnostj kartochek; neizvestnyiye vkhodyi, resheniya ili polnomochiya stanovyatsya predshestvennikami libo yavnyimi rezhimami `paused` ili `blocked`;
- kontekstnyij preflight do soderzhateljnoj rabotyi libo podtverzhdayet granicu, libo zavershayet sessiyu ustojchivoj dekompoziciyej bez lozhnogo statusa zavershyonnoj realizacii;
- telemetriya fakticheskikh sessij mozhet utochnyatj ocenku, no neizvestnyij razmer kontekstnogo okna ili chislo tokenov ne podmenyayutsya vyimyishlennyim chislom ili lozhnoj garantiyej.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: ruchnoj kontekstnyij preflight i granica vetochnoj sessii zakreplenyi, no versionnyij mashinno chitayemyij rabochij paket i yego fail-closed-validaciya yesjhyo ne realizovanyi. Vyisokaya veroyatnostj — konservativnaya inzhenernaya celj, a ne izmerennaya v etoj sessii chislovaya garantiya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-29 09:04:03 MSK — Rasshiritj dinamicheskij vyibor sleduyusjhego shaga](../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:db411a78b8730abc9327715e4c0c47c9dc669c228f35f79737a1ad2dce9e1413 -->
<!-- FUM-MD-RECENCY:END -->
