+++
schema_version = 1
card_id = "FUM-STEP-0127"
status = "completed"
+++
# Dobavitj resursno-konfliktnoye raspredeleniye cepochek

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj k proverennomu kornevomu reyestru planirovsjhik izmenyayemyikh resursov i peredachu uzhe strukturirovannyikh naznachenij v sobstvennyiye ocheredi dochernikh checkout. On dolzhen uchityivatj zakreplyonnuyu kornem rolj bez samostoyateljnogo smyislovogo vyivoda, paralleljno dopuskatj toljko sovmestimyiye rabochiye refs i oblasti v predelakh yomkosti naznacheniya, rebyonka, host i modeli, serializovatj konfliktuyusjhiye resursyi i ne uderzhivatj FIFO-pokoleniye roditeljskoj rabochej kopii na vremya dochernej cepochki.

## Rezuljtat

Kornevoj reyestr rasshiren zakryityim resursnyim sloyem skhemyi `3`. On prinimayet toljko uzhe strukturirovannoye naznacheniye, stroit otdeljnyiye kanonicheskiye konfliktnyiye indeksyi polnogo rabochego ref, live-checkout/common-dir, normalizovannyikh oblastej zapisi i prochikh izmenyayemyikh resursov, fail-closed proveryayet sovmestimostj i vse predelyi i ograzhdyonno sokhranyayet allocation do tochnoj terminalizacii. Raznyiye refs s neperesekayusjhimisya oblastyami dopuskayutsya paralleljno, sovpavshij ref ili oblastj serializuyutsya, a obsjhij target stanovitsya konfliktom toljko na integracionnoj stadii.

Fenced-schyotchiki pereschityivayutsya iz kanonicheskikh sessij dlya fork, naznacheniya, rebyonka, Desktop-host i modeljnogo profilya. Writer i moderator odnogo zhivogo fork delyat odin predel `1`; waiting continuation, inactive child i vneshnij read-only reviewer ne vladeyut fork i izmenyayemyimi resursami, no uderzhivayut slotyi naznacheniya, rebyonka, Desktop-host i modeli. Poteryannyij, ostanovlennyij ili otmenyonnyij vneshnij iskhod sokhranyayet tochnuyu prezhnyuyu masku i ne osvobozhdayet resurs bez avtoritetnogo terminal-svideteljstva. Barjyer ocheredi svyazyivayet tochnyiye identifikator naznacheniya i khyesh dopuska s fork, pokoleniyem, bazoj i rabochim ref, a kazhdyij rebyonok i yego prodolzheniye povtorno proveryayut ikh toljko v FIFO sobstvennogo fizicheskogo checkout.

Vetvj s resursnyimi polnomochiyami ne mozhet vyizvatj host cherez legacy-konvert bez polnogo exact resource tuple. Posle nachatogo host-vyizova terminalizaciya trebuyet oba nepustyikh `threadId` i `hostId`, a vtoraya production-popyitka toj zhe kornevoj vetvi zakryivayetsya do zapisi i host-effekta. Polnomochiye prodolzhenij opirayetsya na durable-svideteljstvo fakticheskogo exact-dopuska, a ne na `next_seq` ili udalyonnyij waiting-bilet.

Avtonomnaya sinkhronizirovannaya fake-host fikstura bez vremennyikh zaderzhek dokazyivayet `max_active = 2` dlya sovmestimyikh naznachenij i stroguyu posledovateljnostj konfliktuyusjhikh. Adresnyiye testyi takzhe zakryivayut sovpavshij ref pri raznyikh oblastyakh, peresekayusjhiyesya oblasti pri raznyikh refs, podgotovku i integraciyu v obsjhuyu celj, obsjhij writer+moderator, neizvestnyiye limityi i stale-pokoleniye, poteryannyij otvet, perezapusk, tochnoye terminal-osvobozhdeniye i svyazj s dochernej FIFO.

## Kriterii zaversheniya

- Kanonicheskij klyuch resursa vklyuchayet identichnosti vetvevogo fork, pokoleniya i repozitoriya, polnyij rabochij ref, zhivoj checkout, oblastj zapisi i ostaljnyiye yavno izmenyayemyiye resursyi; neizvestnaya sovmestimostj zakryivayet paralleljnyij dopusk.
- Planirovsjhik prinimayet toljko uzhe zakreplyonnyiye kornem rolj, klass rezuljtata, effektyi i resursyi; svobodnuyu prozu on ne klassificiruyet i dostup agenta ne rasshiryayet.
- Raznyiye rabochiye refs i neperesekayusjhiyesya oblasti mogut ispolnyatjsya paralleljno, a odin rabochij ref poluchayet ne boleye odnogo vladeljca; obsjhij celevoj ref ne blokiruyet podgotovku, no yego integraciya ostayotsya otdeljnoj serializovannoj stadiyej.
- Reyestr vedyot ograzhdyonnyiye schyotchiki aktivnyikh sessij i potrebleniya dlya fork, naznacheniya, rebyonka, Desktop-host i modeljnogo profilya; obsjhaya yomkostj vzaimoisklyuchayusjhikh pishusjhej i moderiruyusjhej sessij odnogo zhivogo fork tochno ravna `1`. Ozhidayusjheye prodolzheniye, neaktivnaya dochernyaya zadacha i vneshnyaya proveryayusjhaya zadacha bez prava zapisi uchityivayutsya otdeljnyimi sostoyaniyami, a neizvestnyij predel, prevyisheniye lyubogo limita ili nesovpavsheye pokoleniye zakryivayut dopusk. Poteryannyij otvet ne osvobozhdayet yomkostj bez avtoritetnoj terminalizacii.
- Svyazannaya dochernyaya zadacha vkhodit v FIFO sobstvennogo fizicheskogo checkout i posle dopuska povtorno proveryayet tochnyiye naznacheniye, bazu, rabochij ref i pokoleniye; ocheredj roditelya ne vyidayotsya za docherneye vladeniye.
- Ostanovka, otmena i poteryannyij otvet osvobozhdayut resurs toljko posle kanonicheskogo terminaljnogo sostoyaniya; novyij process vosstanavlivayet resheniye iz reyestra bez skryitogo chata.
- Avtonomnyij poddeljnyij host dokazyivayet perekryitiye sovmestimyikh zapuskov i posledovateljnostj konfliktuyusjhikh zapuskov bez seti, modeli ili vneshnikh repozitoriyev.

## Granica rezuljtata

Realizaciya yavlyayetsya uzkim determinirovannyim raspredelitelem yavno nazvannyikh resursov poverkh lokaljnogo kornevogo reyestra. Ona ne klassificiruyet svobodnuyu prozu, ne sozdayot realjnyij Codex Desktop-seans, ne vyizyivayet modelj ili setj, ne materializuyet vneshniye fork-repozitorii, ne vyipolnyayet nezavisimoye smyislovoye revjyu i ne dvigayet celevoj ref fakticheskoj CAS-integraciyej. Eti granicyi ostayutsya u sleduyusjhikh kartochek linii.

## Istochniki

- [tekusjhij zapros 2026-08-13 07:41:51 MSK — Dobavitj resursno-konfliktnoye raspredeleniye cepochek](../../Zhurnal/2026-08-13_07-41-51_MSK_dobavitj-resursno-konfliktnoye-raspredeleniye-cepochek/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0122 — kornevoj reyestr zapuskov](✅-FUM-STEP-0122-dobavitj-kornevoj-reyestr-zapuskov-i-vosstanovleniye-host-privyazok.md)
- [FUM-STEP-0097 — skvoznaya priyomka universaljnogo dispetchera](🗑️-FUM-STEP-0097-provesti-skvoznuyu-priyomku-universaljnogo-dispetchera.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-13 11:35:05 MSK -->
<!-- content-sha256: sha256:e25bbade65c10945644b6a7f76042e344b52875a991ba111a3a87c06cc7b7923 -->
<!-- FUM-MD-RECENCY:END -->
