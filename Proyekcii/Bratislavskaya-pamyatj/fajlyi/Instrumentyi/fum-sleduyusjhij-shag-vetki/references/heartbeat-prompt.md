# Istoricheskaya spravka o heartbeat-dispetchere

Eta stranica sokhranyayet proiskhozhdeniye snyatogo pyatiminutnogo heartbeat-dispetchera FUM. Ona boljshe ne yavlyayetsya shablonom prompt, instrukciyej rabochej sessii, istochnikom registracii host-avtomatizacii ili osnovaniyem dlya kakogo-libo effekta. Nalichiye prezhnego renderer, sovmestimyikh komand i testovyikh fikstur ne vozvrasjhayet etomu tekstu ekspluatacionnyij status.

## Snyatyij kontur

Prezhnij kontur rabotal cherez odnu prikreplyonnuyu zadachu Codex i pyatiminutnyij tik. Dispetcher nablyudal host-prostoj, sveryal obsjhij reyestr, FIFO, rezervacii i specializirovannyiye claims, posle chego mog sozdatj odnu zadachu sleduyusjhego shaga libo analitiki. Otdeljnyiye ograzhdeniya opisyivali poteryannyij host-otvet, vozobnovleniye posle razryiva svyazi, `Stop`/`Start`, vosstanovleniye rezervacij i migraciyu prompt susjhestvuyusjhej avtomatizacii na meste.

Etot mekhanizm snyat celikom. Periodicheskij heartbeat, postoyannaya zadacha dispetchera, obsjhij reyestr avtomaticheskikh zadanij, dispetcherskiye rezervacii, vosstanoviteljnyiye soobsjheniya i marshrutyi `Stop`/`Start` sokhranyayutsya toljko v istorii i sovmestimyikh fiksturakh. Oni ne dayut zadache polnomochij, ne opredelyayut gotovnostj vetki i ne razreshayut sozdaniye novoj sessii. Susjhestvuyusjhaya host-avtomatizaciya etogo kontura ostayotsya ostanovlennoj.

## Predyidusjhij kontur obyazateljnogo prodolzheniya

Posle heartbeat i do `manual-sequential-v1` prodolzheniye svyazyivalosj s tochnoj imenovannoj Git-vetkoj. Kornevaya zadacha zaraneye sozdavala odnu zadachu-prodolzheniye, podtverzhdala yeyo FIFO-bilet i vyipolnyala atomarnyij `commit+handoff`; prodolzheniye perechityivalo novyij `HEAD` i vyizyivalo vetochnyij selector. Sejchas etot kontur otlozhen: obyichnuyu pishusjhuyu zadachu zapuskayet poljzovatelj, a ona posle odnogo soderzhateljnogo zaprosa i ne boleye odnogo lokaljnogo kommita zavershayetsya bez rebyonka.

Neodnoznachnyij otvet sredyi pri sozdanii prodolzheniya zakryivayet kommit i avtomaticheskij povtor. Istoricheskiye heartbeat-artefaktyi ne ispoljzuyutsya kak obkhod etoj granicyi.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-10 14:30:08 MSK — Dobavitj analitiku po chislu zavershyonnyikh shagov](../../../Zhurnal/2026-08-10_14-30-08_MSK_dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov/zapros.md)
- [FUM-REQ-0039 — shtatnyij sbros FIFO-ocheredi i rabochej kopii](../../../Trebovaniya/🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)
- [iskhodnyij zapros 2026-08-07 20:34:22 MSK — Dobavitj shtatnyij sbros ocheredi](../../../Zhurnal/2026-08-07_20-34-22_MSK_dobavitj-shtatnyij-sbros-ocheredi/zapros.md)
- [iskhodnyij zapros 2026-08-06 06:59:01 MSK — Dobavitj upravleniye dispetcherom cherez soobsjheniya](../../../Zhurnal/2026-08-06_06-59-01_MSK_dobavitj-upravleniye-dispetcherom-cherez-soobsjheniya/zapros.md)
- [iskhodnyij zapros ob ispravlenii avtozapuska posle drejfa host-skhemyi](../../../Zhurnal/2026-08-05_21-02-54_MSK_ispravitj-avtozapusk/zapros.md)
- [iskhodnyij zapros o dispetchere avtomatizacij](../../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [iskhodnyij zapros o vyibore shaga po istorii](../../../Zhurnal/2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)
- [iskhodnyij zapros ob otklyuchenii avtomaticheskoj publikacii](../../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [istoricheskoye trebovaniye universaljnoj dispetcherizacii](../../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:41:30 MSK -->
<!-- content-sha256: sha256:2155e0443b33e63c720e75c6c083d77b7ef1033a20a3e8e3c2af0aa79dc22f9e -->
<!-- FUM-MD-RECENCY:END -->
