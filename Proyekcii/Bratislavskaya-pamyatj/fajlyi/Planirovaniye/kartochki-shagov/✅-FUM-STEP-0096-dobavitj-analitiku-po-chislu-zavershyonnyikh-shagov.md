+++
schema_version = 1
card_id = "FUM-STEP-0096"
status = "completed"
+++
# Dobavitj analitiku po chislu zavershyonnyikh shagov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj adapter, sozdayusjhij odnu analiticheskuyu ispolniteljskuyu zadachu posle kazhdyikh nastraivayemyikh `N` podtverzhdyonno zavershyonnyikh zapuskov tochnyikh pokolenij, vyibrannyikh dispetcherom iz vyichislennogo runtime-pula `ready`. Vvesti ustojchivyij zhurnal sobyitij zaversheniya i kursor poroga, chtobyi propusjhennyij heartbeat, restart ili povtor upravlyayusjhego soobsjheniya ne teryali period i ne sozdavali dublikatyi. Schyotchik sluzhit toljko operacionnyim triggerom revizii; vyivod ob uluchshenii dopuskayetsya lishj po nablyudayemoj sposobnosti i vneshnim kriteriyam.

## Rezuljtat

Atomarnaya peredacha FIFO teperj dobavlyayet v ustojchivyij vetochno-lokaljnyij zhurnal rovno odno sobyitiye toljko dlya podtverzhdyonnogo commit+handoff tochnogo pokoleniya `master.next-step`, vyibrannogo iz vyichislennogo runtime-pula `ready`. Identichnostj sobyitiya svyazyivayet vetku, `step_id`, `card_id`, zavershayusjhij commit i rezuljtat; povtor toj zhe peredachi idempotenten. Tekusjhij `last_completion` ostayotsya byistryim putyom obsjhej terminalizacii, zhurnal i claim skhemyi `5` — dolgovechnyim success-proof, a ordinary `finish-clean` atomarno sozdayot skhemu `6` s exact `свидетельство_чистого_завершения = {"base_head": selection_head, "task_id": task_id, "generation": generation}`. Common-terminal prinimayet oba proof nezavisimo ot pozdnego handoff: success sokhranyayet claim dlya replay, clean-safe-failure yego udalyayet. Sleduyusjhaya rezervaciya togo zhe adaptera atomarno poglosjhayet terminal claim. Heartbeat, chat, proizvoljnyij commit, staroye claim bez `card_id` i sam nomer kartochki schyotchik ne izmenyayut.

Perekhodnyij handoff prezhnej HEAD-versii s claim skhemyi `4` ne stanovitsya schyotnyim sobyitiyem, no yego byistryij proof ne teryayetsya: do obsjhej terminalizacii sleduyusjhaya versiya ocheredi otklonyayet chuzhuyu zamenu `last_completion`, a reset sokhranyayet prezhneye zaversheniye v kvitancii. Posleduyusjhij commit skhemyi `4` pod novoj versiyej snachala istoricheski podtverzhdayet ready-vyibor i `card_id`, zatem atomarno migriruyet claim v skhemu `5` i pishet obyichnoye sobyitiye zhurnala.

V obsjhij reyestr dobavleno zadaniye analitiki s nachaljnyim porogom `N = 5`, yavnoj nachaljnoj granicej, oblastjyu analiza, sleduyusjhim porogom i kursorom poslednego podtverzhdyonnogo rezuljtata. Adapter zakreplyayet v claim starejshij nezakryityij porog i konechnyij diapazon proveryayemyikh sobyitij. Do host-granicyi `released` libo `unclaimed` dopuskayet obsjhij otkaz toljko posle povtornoj CAS-proverki otsutstviya claim. Obyichnyij FIFO `finished_clean` vmesto izmenyayemogo `last_completion` ostavlyayet dolgovechnuyu fazu `очищена` s tochnyimi zadachej, pokoleniyem i `base_head`, poetomu pozdnij handoff ne stirayet dokazateljstvo otsutstviya kommita.

Commit+handoff atomarno perevodit analiticheskij claim v fazu `передана` so svideteljstvom kommita; specializirovannoye zaversheniye sveryayet first-parent-cepochku i tochnyiye bajtyi otchyota i reyestra, a obsjheye podtverzhdeniye povtoryayet proverku, terminaliziruyet rezervaciyu i sokhranyayet exact claim `завершена` dlya polnogo replay. Sleduyusjhaya analiticheskaya rezervaciya atomarno poglosjhayet etot terminal claim vmeste s zamenoj terminal reservation i guards. Aktivnyij reset-marker blokiruyet eti mutacii; final shtatnogo reset sokhranyayet next-step claims skhem `4`/`5`/`6` i analiticheskij claim i ne vyizyivayet vneshnij `release`. Posle nego durable success i clean proof prodolzhayut terminalizaciyu po novomu obyichnomu OID nezavisimo ot `last_completion`, a safe failure trebuyet exact receipt/host/ledger/current queue/branch; perekhodnyij precommit-claim skhemyi `4` dopolniteljno prokhodit istoricheskuyu proverku ready-vyibora i udalyayetsya v toj zhe obsjhej CAS. Obsjhaya rezervaciya i management-fence vzaimno ograzhdenyi. Poetomu propusjhennyij tik, povtor ili restart ne teryayut period i ne sozdayut dublikat; za odin heartbeat dopustim ne boleye odnogo host-effekta, a nakopivshiyesya porogi obrabatyivayutsya posledovateljno.

Analiticheskij prompt trebuyet nazvatj nablyudayemuyu sposobnostj, terminaljnuyu priyomku, otricateljnyiye rezuljtatyi i stoimostj cepochki so ssyilkami na iskhodnyiye kartochki, kommityi i sobyitiya. Chislo shagov, kommitov ili dokumentov sluzhit toljko operacionnyim triggerom revizii i ne dokazyivayet uluchsheniye. Izmeneniye `N` idyot cherez novoye pokoleniye s yavnoj politikoj nakoplennogo ostatka i ne perepisyivayet zhurnal. Nachaljnaya granica osoznanno ne zakhvatyivayet tekusjhuyu kartochku: schyot nachinayetsya s posleduyusjhikh verificirovannyikh claim novoj skhemyi.

## Istochniki

- [iskhodnyij zapros 2026-08-10 14:30:08 MSK — Dobavitj analitiku po chislu zavershyonnyikh shagov](../../Zhurnal/2026-08-10_14-30-08_MSK_dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov/zapros.md)
- [iskhodnyij zapros o dinamicheskom vyichislenii gotovnosti](../../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [FUM-STEP-0094 — upravleniye dispetcherom soobsjheniyami](✅-FUM-STEP-0094-dobavitj-upravleniye-dispetcherom-cherez-soobsjheniya.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:9496adb0389e3e41576f942bfc942e6d59a6024ab49b015b997389bb0e90bc4b -->
<!-- FUM-MD-RECENCY:END -->
