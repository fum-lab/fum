# Obyazateljnoye prodolzheniye Git-vetki posle kommita

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0042 -->

Ekspluatacionnyij status: otlozheno. Kartochka sokhranyayet prezhnij continuation/FIFO-kontrakt kak istoricheskuyu narabotku; yeyo imperativnyij tekst ne dejstvuyet dlya ruchnoj posledovateljnoj zapisi `refs/heads/master` i ne razreshayet sozdavatj sleduyusjhuyu zadachu.

Kazhdaya kornevaya zadacha Codex, zavershayusjhaya osmyislennuyu rabotu podtverzhdyonnyim Git-kommitom, dolzhna pered kommitom sozdatj rovno odnu novuyu zadachu-prodolzheniye v tom zhe sokhranyonnom lokaljnom proyekte i svyazatj yeyo s polnyim ref tekusjhej imenovannoj vetki. Atomarnyij `commit+handoff` dopuskayetsya toljko posle togo, kak novaya zadacha poluchila tochnyiye `threadId` i `hostId`, pervyim instrumentaljnyim dejstviyem voshla v FIFO obsjhej rabochej kopii i nablyudayetsya ozhidayusjhim biletom na iskhodnoj vershine etoj vetki.

Prodolzheniye ne nasleduyet zaraneye vyibrannuyu kartochku kak polnomochiye. Posle dvizheniya vetki ono perechityivayet novyij `HEAD`, podtverzhdayet vetku i dopusk, zanovo zapuskayet kanonicheskij vetochnyij selektor i vyipolnyayet odin dopustimyij shag. Yesli nabor zavershyon, gotovogo shaga net ili zakonnaya rabota ne trebuyet izmeneniya, zadacha delayet `finish-clean`; otsutstviye kommita prekrasjhayet cepochku.

## Semanticheskiye svyazi

- **dopolnyayet:** [snyatuyu universaljnuyu dispetcherizaciyu periodicheskikh avtomatizacij](🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md) — zadayot dejstvuyusjhij prichinnyij marshrut prodolzheniya vetki vmesto sokhranyonnoj toljko dlya proiskhozhdeniya periodicheskoj arkhitekturyi.
- **trebuyetsya dlya:** [dereva vetvevyikh fork i roditeljskoj moderacii](🟡-derevo-vetvevyikh-fork-i-roditeljskaya-moderaciya.md) — kazhdyij aktivirovannyij rebyonok razvivayet svoj yedinstvennyij rabochij ref posledovateljnyimi sessiyami bez vtorogo pisatelya.

## Kriterii proverki

- prodolzheniye sozdayotsya cherez `create_thread` v tochnom sokhranyonnom proyekte s lokaljnoj sredoj, bez otdeljnogo worktree, yavnogo pereopredeleniya modeli ili skryitogo periodicheskogo triggera;
- prompt soderzhit polnyij `refs/heads/...`, identichnostj roditeljskoj zadachi i obyazannostj pervyim instrumentaljnyim dejstviyem vyipolnitj `join`, no ne soderzhit absolyutnyikh putej, prezhnej kartochki, lease, dispetcherskoj rezervacii ili host-identifikatorov;
- yedinstvennyij otvet sozdaniya prinimayetsya toljko s nepustyimi `threadId` i `hostId`; oshibka, tajm-aut, poteryannyij otvet ili odin `clientThreadId` zapresjhayut kommit i avtomaticheskij povtor;
- roditelj do kommita mashinno podtverzhdayet exact ozhidayusjhij bilet rebyonka v toj zhe branch-scoped FIFO, otlichiye yego task ID ot vladeljca i `acknowledged_head`, ravnyij `base_head` vladeljca; uzhe susjhestvuyusjhiye boleye ranniye biletyi sokhranyayut poryadok, a rebyonok ne poluchayet prioriteta;
- komanda ocheredi poluchayet `--идентификатор-продолжения`, povtorno proveryayet svyazj do sozdaniya kommita i atomarno sokhranyayet yeyo v rezuljtate, `last_completion` i neizmenyayemoj Git-kvitancii; tochnyij replay vosstanavlivayetsya posle pozdnej peredachi FIFO, a drugoj ili otsutstvuyusjhij identifikator otklonyayetsya;
- nalichiye kanonicheskogo markera v novom `HEAD` mashinno trebuyet prodolzheniye, pervyij svyazannyij kommit zakreplyayet neobratimuyu aktivaciyu v ocheredi, a snyatyiye dispatcher-, reservation-, claim-, ledger- i analytics-perekhodyi dlya takogo kommita ne ispolnyayutsya;
- atomarnaya Git-tranzakciya odnovremenno dvigayet polnyij ref vetki i peredayot FIFO, poetomu rebyonok do kommita toljko zhdyot, a pri dostizhenii golovyi ocheredi poluchayet `reload_required`, perechityivayet fakticheskij tekusjhij `HEAD`, vyipolnyayet `ack-head` i dopuskayetsya v obyichnom poryadke;
- kazhdyij sobstvennyij kommit prodolzheniya povtoryayet tot zhe protokol, a `finish-clean`, oshibka i neizvestnyij iskhod kommita novogo rebyonka ne porozhdayut;
- periodicheskij heartbeat i universaljnyij dispetcher ostanovlenyi i ne uchastvuyut v vyibore, rezervirovanii, vosstanovlenii ili sozdanii zadach;
- avtonomnyiye testyi pokryivayut dopustimoye prodolzheniye, otsutstviye bileta, sovpadeniye rebyonka s vladeljcem, ustarevshuyu iskhodnuyu vershinu, exact replay, mismatch replay, Unicode-ref i otsutstviye absolyutnyikh putej v prompte;
- pervaya uzhe dopusjhennaya migracionnaya sessiya mozhet odin raz zakrepitj ekvivalentnyij prompt sama i zavershitjsya prezhnej HEAD-bootstrap-komandoj bez novogo flaga toljko posle podtverzhdyonnyikh sozdaniya i waiting-bileta; daljnejshikh isklyuchenij net.

## Granica garantii

Poryadok `create → waiting → commit+handoff` garantiruyet bezopasnostj: kazhdyij podtverzhdyonnyij kommit uzhe imeyet susjhestvuyusjheye prodolzheniye, kotoroye ne moglo pisatj do peredachi vetki. Bez idempotentnogo klyucha i avtoritetnogo poiska rezuljtata na storone Codex-host protokol ne mozhet odnovremenno garantirovatj bezuslovnyij progress posle padeniya i otsutstviye dublya. Neodnoznachnostj do kommita poetomu namerenno ostanavlivayet vetku do yavnogo chelovecheskogo vosstanovleniya.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: kontrakt zakreplyon v pravilakh rabochej sessii, ocheredi i yeyo avtonomnyikh testakh; prezhnij heartbeat ostanovlen, a migracionnaya sessiya pered sobstvennyim kommitom sozdayot i registriruyet pervoye prodolzheniye vetki.

Trebovaniye otnositsya k kommitam, sozdavayemyim kornevyimi zadachami cherez ocheredj FUM. Ono ne delayet proizvoljnyij vneshnij `git commit` bezopasnyim, ne publikuyet vetku i ne rasshiryayet polnomochiya sleduyusjhego shaga.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:7b20abbffc1c59ab30fe045e242bfd06d28e81c0e80c1e3ecc28feff9cac8e7f -->
<!-- FUM-MD-RECENCY:END -->
