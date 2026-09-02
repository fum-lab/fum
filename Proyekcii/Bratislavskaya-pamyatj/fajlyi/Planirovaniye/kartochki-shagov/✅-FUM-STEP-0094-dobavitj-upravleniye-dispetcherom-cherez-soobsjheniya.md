+++
schema_version = 1
card_id = "FUM-STEP-0094"
status = "completed"
+++
# Dobavitj upravleniye dispetcherom cherez soobsjheniya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sdelatj poljzovateljskiye soobsjheniya v susjhestvuyusjhuyu prikreplyonnuyu zadachu proveryayemoj poverkhnostjyu prosmotra i nastrojki dispetchera. Opredelitj chelovekochitayemyiye namereniya spiska, sostoyaniya, pauzyi, vozobnovleniya, izmeneniya triggera i uslovij, dobavleniya i blokirovki zadaniya; kazhdoye izmeneniye dolzhno preobrazovyivatjsya v zakryitoye strukturnoye predlozheniye s ozhidayemyim pokoleniyem i yavnyimi effektami.

## Rezuljtat

Prikreplyonnaya zadacha poluchila proveryayemuyu poverkhnostj upravleniya soobsjheniyami. Read-only-namereniye stroit kanonicheskij obezlichennyij snimok obsjhego reyestra: dlya kazhdogo zadaniya vidnyi pokoleniye, trigger, usloviya dopuska, sostoyaniye, effekt, poslednij podtverzhdyonnyij kursor i sostoyaniye rezervacii, no ne lokaljnyiye puti, project-, task-, generation-, attempt- ili run-identifikatoryi.

Izmenyayusjhiye namereniya preobrazuyutsya v zakryitoye predlozheniye skhemyi `fum.dispatcher-control-proposal.v1`. Predlozheniye svyazyivayet identifikator i khyesh soobsjheniya s iskhodnyimi khyeshem i pokoleniyem reyestra, pokoleniyem zadaniya, tochnyim diff, klassom effekta, posledstviyami i perechnem podtverzhdenij; iskhodnyij svobodnyij tekst ostayotsya toljko v rabochej sessii. Primeneniye povtorno vosproizvodit predlozheniye iz osnovaniya, proveryayet `HEAD`, pokoleniya, khyeshi, FIFO-vladeljca i upravlyayusjheye ograzhdeniye. Izmeneniye vneshnego effekta, lyubogo uzhe podtverzhdyonnogo kursora i snyatiye safety-blokirovki trebuyut otdeljnyikh podtverzhdenij, svyazannyikh s tochnyim identifikatorom predlozheniya; skhema `1` ne dopuskayet smenu remote ili ref voobsjhe.

Repozitornyiye izmeneniya vyipolnyayutsya toljko dopusjhennoj obyichnoj kornevoj zadachej i zavershayutsya lokaljnyim atomarnyim commit+handoff. Host-pauza i vozobnovleniye takzhe prokhodyat FIFO, svyazyivayut predlozheniye s nablyudyonnyim iskhodnyim statusom `ACTIVE` ili `PAUSED`, proveryayut yego pered host-obnovleniyem i pri otsutstvii repozitornogo diff zavershayutsya chistoj peredachej. Obsjhij upravlyayusjhij fence i rezervacii zapuska vzaimno proveryayutsya odnoj Git-CAS-sistemoj; vnutrennij snimok management-ref dopolniteljno vkhodit v tranzakciyu `finish-own-clean`, poetomu heartbeat ne mozhet samoisklyuchitj perenastrojku, vyiigravshuyu vstrechnyij CAS.

Avtonomnyiye scenarii pokryivayut tochnyij publichnyij prosmotr, individualjnyiye i obsjhiye pauzu i vozobnovleniye, dobavleniye i blokirovku zadaniya, CAS-konfliktyi pokoleniya i khyesha, obyazateljnyiye podtverzhdeniya, otmenu bez otkata, neizvestnoye namereniye, povtor soobsjheniya bez dvojnogo izmeneniya, CLI-kontrakt i vstrechnyiye gonki upravleniya s host-granicej. Publikaciya ne vkhodit v rezuljtat: nakoplennyij proverennyij prefiks `refs/heads/master` mozhet opublikovatj toljko otdeljnyij ruchnoj push poljzovatelya, kotoryij ne yavlyayetsya podtverzhdeniyem kazhdoj kartochki ili poshagovyim dopuskom.

## Istochniki

- [iskhodnyij zapros 2026-08-06 06:59:01 MSK — Dobavitj upravleniye dispetcherom cherez soobsjheniya](../../Zhurnal/2026-08-06_06-59-01_MSK_dobavitj-upravleniye-dispetcherom-cherez-soobsjheniya/zapros.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master](../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [FUM-STEP-0093 — migraciya avtozapuska shagov](✅-FUM-STEP-0093-perenesti-avtozapusk-shagov-v-universaljnyij-dispetcher.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:217e49350175226b3cc56d6dc0a9f77b4fa5f223b5a2872d8a20fd71e8566ef2 -->
<!-- FUM-MD-RECENCY:END -->
