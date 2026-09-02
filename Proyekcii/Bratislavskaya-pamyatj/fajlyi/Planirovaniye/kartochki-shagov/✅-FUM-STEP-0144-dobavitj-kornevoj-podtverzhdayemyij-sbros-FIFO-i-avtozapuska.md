+++
schema_version = 1
card_id = "FUM-STEP-0144"
status = "completed"
+++
# Dobavitj kornevoj podtverzhdayemyij sbros FIFO i avtozapuska

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj ispolnyayemyij kornevoj `sbrositj.sh` i TDD-realizaciyu chelovecheskogo `break-glass`-sbrosa k tochnomu `HEAD` tekusjhej imenovannoj vetki. Sbros dolzhen poluchitj podtverzhdeniye tochnogo plana pri TTY odnovremenno na stdin i stdout, bezopasno vosstanovitj rabocheye derevo, arkhivirovatj i annulirovatj aktivnyij scoped runtime, vyipustitj svezhiye ocheredj i reservation boundary, sozdatj checkout-scoped tombstone prezhnikh zadach, zapretitj povtornoye ispoljzovaniye prezhnikh polnomochij i otkryitj sleduyusjhij obyichnyij avtozapusk kartochki iz selector. Validnyiye official reset receipts pri etom ostayutsya na meste, a chelovecheskaya kvitanciya zhivyot v otdeljnom namespace i podderzhivayet terminal replay uzhe sostoyavshegosya rezuljtata bez novoj mutacii.

## Rezuljtat

Dobavlen ispolnyayemyij kornevoj `./sbrositj.sh`, zagruzhayusjhij realizaciyu iz tochnogo `HEAD` i trebuyusjhij bezargumentnyij interaktivnyij zapusk s TTY odnovremenno na stdin i stdout i dinamicheskoj frazoj polnogo plana. Protokol arkhiviruyet raw preimage, ochisjhayet toljko podtverzhdyonnyiye izmeneniya, sokhranyayet ignored-dannyiye, vlozhennyiye repozitorii, chuzhiye vetki i validnyiye oficialjnyiye kvitancii, vyipuskayet svezhiye FIFO i reservation boundary i sozdayot checkout-scoped tombstone prezhnikh zadach.

Terminaljnaya chelovecheskaya kvitanciya bezopasno vosproizvodit poteryannyij uspeshnyij otvet bez novoj mutacii. Obsjhaya rezervaciya posle boundary atomarno ograzhdayet novyij kartochnyij claim, validnyij perekhod vetki cepochki snachala idempotentno zavershayetsya, a skvoznaya vremennaya fikstura podtverzhdayet novyij selector, rezervaciyu, claim i FIFO generation iz togo zhe `HEAD`. FUM-REQ-0039 i FUM-STEP-0141 ne zakryityi i sokhranyayut sobstvennuyu host-stop-granicu.

## Istochniki

- [FUM-SBOJ-0015 — Nedostupnostj sbrosa FIFO dlya vosstanovleniya avtozapuska](../../Sboi/FUM-SBOJ-0015-nedostupnostj-sbrosa-FIFO-dlya-vosstanovleniya-avtozapuska.md)
- [FUM-REQ-0041 — Podtverzhdayemyij ruchnoj sbros FIFO i avtozapuska k tekusjhemu HEAD](../../Trebovaniya/✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md)
- [iskhodnyij zapros 2026-08-10 10:19:59 MSK — Dobavitj prostoj sbros FIFO k tekusjhemu HEAD](../../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [dispetcher avtomatizacij FUM](../../Instrumentyi/fum-dispetcher-avtomatizacij-fum/SKILL.md)
- [sleduyusjhij shag vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:8381c15d8b304b9d41182ec7e6bb8df6c278f888579e78773ec1592ac03c695d -->
<!-- FUM-MD-RECENCY:END -->
