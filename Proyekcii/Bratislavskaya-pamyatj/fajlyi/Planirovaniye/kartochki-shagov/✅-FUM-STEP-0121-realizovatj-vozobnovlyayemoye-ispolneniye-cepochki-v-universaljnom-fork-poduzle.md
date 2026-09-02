+++
schema_version = 1
card_id = "FUM-STEP-0121"
status = "completed"
+++
# Realizovatj vozobnovlyayemoye ispolneniye cepochki v universaljnom fork-poduzle

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj lokaljnyij runtime ot odnogo zaraneye podgotovlennogo pishusjhego paketa do linejnoj konechnoj cepochki v odnom universaljnom fork-poduzle. Vsya cepochka dolzhna ispoljzovatj odin fizicheskij zhivoj checkout i tochnyij polnyij rabochij ref: korenj sozdayot toljko nachaljnuyu host-zadachu, kazhdyij dopusjhennyij vladelec vyipolnyayet odin shag s sobstvennyimi proverkami i pered osmyislennyim commit sozdayot rovno odno prodolzheniye togo zhe checkout i ref, a `commit+handoff` atomarno prodvigayet vetku i stroguyu FIFO. Otdeljnyiye proveryayusjhaya i integracionnaya zadachi podklyuchayutsya toljko posle gotovnosti diapazona i ne vladeyut vetkoj mezhdu posledovateljnyimi shagami. Gotovyij diapazon materializuyet tochnyij lokaljnyij paket peredachi dlya zaraneye obyyavlennogo marshruta i toljko otmechayet marshrut obsjhego vklada fork — core bez sozdaniya pull request.

Sreda vyipolneniya etoj kartochki namerenno ostayotsya linejnoj vnutri odnogo [vetvevogo fork FUM](../../Glossarij/vetvevoj-fork-FUM.md). Porozhdeniye dvukh dochernikh fork i posleduyusjhaya moderaciya yavlyayutsya otdeljnyimi perekhodami, zaplanirovannyimi kartochkoj FUM-STEP-0145, i ne izmenyayut pravilo odnogo prodolzheniya na kommit.

## Rezuljtat

Dobavlenyi vozobnovlyayemyij runtime, zhivaya lokaljnaya fikstura i adresnyij nabor Swift-testov konechnoj cepochki. V odnom fizicheskom checkout na tochnom `refs/heads/роль/писатель`, otlichnom ot nepodvizhnogo `refs/heads/master`, tri raznyiye processnyiye sessii neposredstvenno poluchayut sostoyaniya selector `ready`, `ready`, `not_ready`; pervyiye dve vyipolnyayut dve zavisimyiye kartochki i sozdayut rovno dva neposredstvennyikh odnoroditeljskikh commit cherez svyazannyiye `commit+handoff`, a tretjya zavershayet tochnyij dopusk cherez `finish-clean` bez novogo prodolzheniya.

Kazhdyij kommityasjhij vladelec zaraneye sozdayot otdeljnyij process prodolzheniya i svyazyivayet yego PID, task ID, waiting-bilet, rabochuyu kopiyu, polnyij ref i podtverzhdyonnyij HEAD. Novyij process perechityivayet `AGENTS.md` i oba upravlyayusjhikh kontrakta iz fakticheskogo HEAD, podtverzhdayet vershinu i vosstanavlivayet kartochku, byudzhetyi i zavisimostj toljko iz Git, chastnyikh pasportov, FIFO i pryamogo selector. Shagi sokhranyayut otdeljnyiye kanonicheskiye paketyi, fakticheski ispolnennyiye proverki i doverennyij raskhod; prevyisheniye kazhdogo byudzheta, neuspeshnaya proverka, nezayavlennyij putj i obyyavlennyij putj vne oblasti otklonyayutsya do prodolzheniya ili kommita.

Zhivoj adapter zanovo svyazyivayet iskhodnyiye kartochki, rabochij nabor i kartochku cepochki s iskhodnyim Git-kommitom, chitayet admission-, waiting-, queue- i receipt-svideteljstva iz tochnyikh Git-obyyektov, proveryayet dva neposredstvennyikh roditelya, ispolnyayet obe zakryityiye skhemyi i semanticheskij validator FUM-STEP-0120. Posle finaljnogo `finish-clean` on materializuyet vosproizvodimyiye state- i handoff-refs s tochnyimi base, head, polnyim diapazonom, sovokupnyim diff, pasportami, ostatkom byudzheta, neizmennoj celjyu i budusjhim marshrutom obsjhego vklada bez pull request i bez obyyavleniya prinyatiya. Proveryayusjhaya i integracionnaya zadachi poyavlyayutsya toljko posle uspeshnoj semanticheskoj proverki i ne vkhodyat v FIFO vetki.

Ostanovka posle podtverzhdyonnogo prodolzheniya, podmena staged-tree, neodnoznachnyij otvet sozdaniya, poteryannyij otvet svyazannogo kommita i poteryannyij finaljnyij rezuljtat vosstanavlivayutsya ili blokiruyutsya bez vtorogo prodolzheniya i vtorogo kommita; izmenyonnyij povtor konfliktuyet. Semanticheskaya podmena vershinyi, byudzheta, oblasti ili prinyatiya otvergayetsya dazhe togda, kogda package-ref uzhe ukazyivayet na poddeljnyij blob.

## Granica rezuljtata

Dokazateljstvo avtonomno i ispoljzuyet vremennuyu local-bare topologiyu, realjnuyu lokaljnuyu ocheredj i selector, no determinirovannyij host-adapter vmesto Codex Desktop API, seti i zhivoj modeli. Mashinochitayemyiye zapisi sozdaniya ne yavlyayutsya avtoritetnyim readback realjnyikh imenovannyikh fork-zadach. Rezuljtat ne sozdayot postoyannuyu sborku dereva, pull request, nezavisimoye revjyu ili CAS-integraciyu i ne rasshiryayet polnomochiya do vneshnikh remotes; eti granicyi ostayutsya sleduyusjhim planovyim sloyem.

## Istochniki

- [iskhodnyij zapros 2026-08-12 12:40:10 MSK — Realizovatj vozobnovlyayemoye ispolneniye cepochki v universaljnom fork-poduzle](../../Zhurnal/2026-08-12_12-40-10_MSK_realizovatj-vozobnovlyayemoye-ispolneniye-cepochki-v-universaljnom-fork-poduzle/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0120 — pasport delegirovaniya cepochki](✅-FUM-STEP-0120-zakrepitj-pasport-delegirovaniya-konechnoj-cepochki-kartochek.md)
- [istoricheskaya FUM-STEP-0093 — adapter sleduyusjhego shaga snyatogo universaljnogo dispetchera](✅-FUM-STEP-0093-perenesti-avtozapusk-shagov-v-universaljnyij-dispetcher.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 15:29:50 MSK -->
<!-- content-sha256: sha256:55d8c5d66145c4d86d13fc11e6f1d2d8c488e38bf1684320424a4aa34d46dbfd -->
<!-- FUM-MD-RECENCY:END -->
