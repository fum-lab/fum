+++
schema_version = 1
card_id = "FUM-STEP-0112"
status = "completed"
+++
# Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zamknutj odin uzkij skvoznoj odnoagentnyij scenarij v sobstvennom runtime FUM: vneshnyaya zadacha, realjnyij model-only-vyizov, razreshyonnoye lokaljnoye dejstviye, izolirovannyij kandidatnyij kommit, otdeljnaya priyomka, dva prinuditeljnyikh mezhprocessnyikh vozobnovleniya i terminaljnyij iskhod. Podtverditj avtonomnoj fiksturoj i odnim opt-in zhivyim progonom, ne rasshiryaya vyivod za etot scenarij.

## Pochemu sejchas

Predyidusjhiye docherniye shagi otdeljno zakreplyayut kompoziciyu paketov, ispolnimyiye byudzhetyi, sobyitijnyij reduktor, podtverzhdyonnoye khranilisjhe i kandidatnyij Git-effekt. Toljko posle etikh granic mozhno integrirovatj iskhodnyiye kriterii FUM-STEP-0103 bez skryitogo vneshnego agentskogo cikla i bez smesheniya vnutrennego vyibora s dopuskom. Paketnoye razresheniye tekusjhego zaprosa okhvatyivayet zhivoj progon toljko s uzhe dostupnyim lokaljnyim provider i ne perenositsya na druguyu identity, zagruzku modeli, novyiye sekretyi, platnyij dostup, poljzovateljskiye dannyiye ili vneshnyuyu setj; ruchnoj `push` ne yavlyayetsya istochnikom etikh polnomochij.

## Kriterii zaversheniya

- Odin versionnyij pasport perechislyayet celj, kontekst, provider identity, byudzhetyi, raskryitiye dannyikh, allowlist dejstvij, proverki i dopustimyiye terminaljnyiye iskhodyi; odna sokhranyonnaya trassa zavershayetsya rovno odnim iskhodom, a avtonomnyiye testyi pokryivayut ostaljnyiye.
- Sobstvennyij runtime, a ne vneshnij agentskij cikl, chereduyet modeljnyij shag, razbor namereniya, dejstviye, nablyudeniye, proverku i resheniye o prodolzhenii cherez versionnyiye headless-interfejsyi.
- Poka vneshnij perekhod ozhidayet podtverzhdeniya, fikstura proveryayet ne meneye dvukh variantov ot obsjhego predka v konechnom byudzhete; vnutrennij vyibor ne povyishayet statusyi dopuska bez nezavisimogo svideteljstva.
- Posle nablyudayemogo podtverzhdeniya dvukh zaraneye zaregistrirovannyikh checkpoint — posle vnutrennego vyibora i posle nablyudeniya kandidatnogo kommita — vneshnij harness posyilayet runtime `SIGKILL` ili ekvivalentnoye negracioznoye zaversheniye. Prodolzheniye vyipolnyayut processyi s novyimi PID toljko iz podtverzhdyonnogo `CURRENT`, bez prezhnego chata, stdin i skryityikh peremennyikh processa.
- Kandidatnyij kommit ostayotsya v izolirovannoj vetke, ne integriruyetsya avtomaticheski i poluchayet otdeljnyij proverochnyij i priyomochnyij iskhod.
- Avtonomnaya fikstura vosproizvodit prinyatyij epizod pobajtovo ili po zakreplyonnoj kanonicheskoj proyekcii, proveryayet nedostupnyij byudzhet bez novogo vyizova i no-call replay bez model-, tool-, Git- i workspace-effektov; osnovnoj progon prokhodit bez seti i zhivoj modeli.
- Odin opt-in zhivoj lokaljnyij progon prokhodit tem zhe sobstvennyim runtime bez recorded model transport: vyipolnyayet realjnyiye model-only-shagi, oba fakticheskikh ubijstva i vozobnovleniya, sozdaniye, nezavisimuyu proverku i priyomku kandidata i terminaljnyij iskhod. On ispoljzuyet uzhe dostupnyij provider bez skachivaniya vesov, novyikh sekretov, platnogo dostupa ili poljzovateljskikh dannyikh; otchyot zakreplyayet identity, usage, PID, kontroljnyiye tochki, candidate object i priyomku.
- README i otchyot chestno nazyivayut rezuljtat odnim proverennyim scenariyem, a ne gotovyim universaljnyim agentom, raspredelyonnyim FUM, produktovoj versiyej ili dokazannyim preimusjhestvom nad kontroljnyim agentom.

## Rezuljtat

Odin uzkij scenarij zamknut v sobstvennom runtime FUM: polnyij versionnyij execution-passport svyazyivayetsya s podtverzhdyonnyim `CURRENT`; dva model-only-varianta ot obsjhego predka prokhodyat strogij razbor i proverku; tretij proposal ostanavlivayetsya konechnyim byudzhetom bez vyizova; otdeljnoye vneshneye podtverzhdeniye razreshayet toljko tochnyij vyibrannyij Git-perekhod. Harness dvazhdyi nezavisimo sveryayet checkpoint s `CURRENT`, posyilayet fakticheskij `SIGKILL`, a novyiye worker-processyi prodolzhayut bez prezhnego stdin, chata i skryityikh peremennyikh.

Razreshyonnoye dejstviye sozdayot determinirovannyij commit toljko v izolirovannom clone i otdeljnoj vetke, posle chego otdeljnyij process priyomki zanovo proveryayet tochnyij parent/tree/diff/checker i sokhranyayet `accepted`. Epizod zavershayetsya yedinstvennyim `completed`; iskhodnyij checkout ne izmenyayetsya i avtomaticheskaya integraciya otsutstvuyet. Avtonomnyij recorded harness vosproizvodit zakreplyonnuyu kanonicheskuyu proyekciyu, dokazyivayet budget no-call i no-effect replay. Odin opt-in zhivoj progon tem zhe runtime vyipolnil dva realjnyikh lokaljnyikh LM Studio model-only-vyizova i oba ubijstva; provider zatem vozvrasjhyon v iskhodnoye vyiklyuchennoye sostoyaniye.

Eto priyomka odnogo sinteticheskogo scenariya, a ne gotovyij universaljnyij ili raspredelyonnyij FUM, produktovyij runtime, dokazateljstvo power-loss durability libo preimusjhestvo nad kontroljnyim agentom.

Atomarnoye FUM-REQ-0029 o kak minimum odnom skvoznom proveryayemom odnoagentnom epizode podtverzhdeno etim rezuljtatom i perevedeno v `✅`. FUM-REQ-0035 ostayotsya `🟡`, poskoljku vneshneye mashinnoye svideteljstvo harness ne yavlyayetsya zhivyim poljzovateljskim podtverzhdeniyem.

## Istochniki

- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [otchyot zhivogo progona](../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master i poetapnoye podtverzhdeniye](../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [FUM-STEP-0111 — kandidatnyij kommit i otdeljnaya priyomka](✅-FUM-STEP-0111-realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku.md)
- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)
- [trebovaniye o skvoznom odnoagentnom epizode](../../Trebovaniya/✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:aefcb265b3f5e5137cda2a169ea371361545afb4638725b861bcb247b4d2fd31 -->
<!-- FUM-MD-RECENCY:END -->
