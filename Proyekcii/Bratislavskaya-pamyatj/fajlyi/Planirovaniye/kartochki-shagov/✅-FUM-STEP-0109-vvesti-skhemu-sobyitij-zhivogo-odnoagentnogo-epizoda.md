+++
schema_version = 1
card_id = "FUM-STEP-0109"
status = "completed"
+++
# Vvesti skhemu sobyitij zhivogo odnoagentnogo epizoda

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

V otdeljnom novom SwiftPM core-target bez fajlovogo, Git- ili provider-vvoda-vyivoda vvesti versionnyiye pasport, sobyitiya i chistyij reduktor odnogo zhivogo odnoagentnogo epizoda FUM. Skhema dolzhna cheredovatj modeljnyij shag, razbor namereniya, razreshyonnoye dejstviye, nablyudeniye, proverku i resheniye o prodolzhenii, sokhranyaya ozhidayusjhij podtverzhdeniya vneshnij perekhod nezavisimo ot prodolzhayusjhejsya konechnoj modeljnoj proverki variantov.

## Rezuljtat

Sozdan otdeljnyij SwiftPM-paket `FUMLiveSingleAgentEpisode` s chistyim target `FUMLiveEpisodeCore`. Versionnyij pasport zakreplyayet celj, kontekst, provider identity i rezhim, disclosure-politiku, shestimernyij byudzhet, allowlist dejstvij, kriterii proverki, kontroljnyiye tochki i terminaljnyiye iskhodyi. Live-sobyitiya imeyut sobstvennyiye identity `fum.live_single_agent_episode.event` i versiyu `1`, ne izmenyaya `fum.agent_cycle.trace` versij `1`–`3`.

Chistyij reduktor razlichayet modeljnyiye zapros i otvet, strogij razbor nedoverennogo namereniya, vnutrennij vyibor, poljzovateljskoye podtverzhdeniye, avtorizaciyu, preflight, ispolneniye, nablyudeniye, proverku, podtverzhdeniye pokoleniya i resheniye o prodolzhenii. Vse vneshniye rubezhi trebuyut otdeljnyikh sobyitij s tochnyimi koordinatami perekhoda. Zaversheniye modeljnoj osi zapresjhayet novyiye modeljnyiye sobyitiya, no ne meshayet pozdnemu podtverzhdeniyu uzhe obyyavlennogo perekhoda.

Avtonomnaya fikstura sokhranyayet dva varianta ot obsjhego predka, vse ikh model-only-otvetyi, namereniya i proverki, vyivodit `selected_in_model` iz tochnyikh sokhranyonnyikh istochnikov, sozdayot byudzhetnuyu kontroljnuyu tochku bez tretjyego vyizova i ostavlyayet vneshnij perekhod ozhidayusjhim. Planner proveryayet kazhdyij iz shesti ostatkov pokomponentno i dopuskayet nulevuyu denezhnuyu stoimostj toljko dlya dokazanno besplatnogo lokaljnogo profilya.

Nabor iz `14` XCTest-scenariyev podtverzhdayet polozhiteljnyij replay, idempotentnostj, neizmennostj osej, neizvestnuyu versiyu, narushennyij poryadok, podmenu identity, cross-transition-svideteljstva, neizvestnoye pole dejstviya, vyibor bez model-only-proiskhozhdeniya, lozhnyiye povyisheniya statusa i kazhdyij byudzhetnyij predel. Staticheskaya granica testa podtverzhdayet otsutstviye fajlovyikh, processnyikh, setevyikh, Git- i provider-vyizovov v core-target; otdeljnyiye SHA-256-baseline zakreplyayut neizmennyiye bajtyi prezhnikh trass versij `1`–`3`.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-07-31_21-37-26_MSK_vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda/zapros.md)
- [kontrakt zhivogo odnoagentnogo epizoda](../../Dokumentaciya/48-kontrakt-zhivogo-odnoagentnogo-epizoda.md)
- [SwiftPM-prototip zhivogo odnoagentnogo epizoda](../../Prototipyi/zhivoj-odnoagentnyij-epizod/README.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master i poetapnoye podtverzhdeniye](../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [FUM-STEP-0108 — ispolnimyij token-byudzhet](✅-FUM-STEP-0108-zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya.md)
- [FUM-STEP-0106 — neblokiruyusjheye modeljnoye vetvleniye](✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md)
- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3a1279d1dca6190cc328ec4c7d5af9500803aa421bf8eef99da9d1e610e11818 -->
<!-- FUM-MD-RECENCY:END -->
