# Otchyot 2026-07-31 14:59:59 MSK - Ispravitj podtverzhdeniye svobodnoj ocheredi avtozapuska

Rabochaya sessiya vosstanavlivayet tochnuyu prichinu otkaza heartbeat podtverditj svobodnuyu FIFO-ocheredj posle zaversheniya vruchnuyu sozdannyikh zadach i ustranyayet vosproizvodimyij razryiv kontrakta.

## Rezuljtat

Poslednyaya ruchnaya zadacha zavershilasj atomarnyim commit+handoff v 14:29:49 MSK: vladelec otsutstvoval, spisok ozhidaniya byil pust, a sleduyusjhij poryadkovyij nomer i istoricheskaya zapisj zaversheniya sokhranilisj shtatno. Problemnyij heartbeat srabotal v 14:53:31 MSK, kogda FIFO uzhe 23 minutyi 42 sekundyi byila svobodna; do registracii tekusjhej zadachi v 14:57:13 MSK eto sostoyaniye sokhranyalosj 27 minut 24 sekundyi. Novyikh obyyektov sostoyaniya ocheredi mezhdu zaversheniyem ruchnoj zadachi i tekusjhim `join` ne byilo. Sledovateljno, vruchnuyu sozdannyiye sessii ne ostavili vladeljca ili bilet i byili toljko predshestvuyusjhim kontekstom oshibki.

Tekusjhaya poljzovateljskaya zadacha uzhe nablyudalasj host kak aktivnaya pered problemnyim itogom heartbeat, poetomu korrektnyij sleduyusjhij barjyer vsyo ravno ostanovil byi avtozapusk po drugoj active-zadache. No dispetcher ostanovilsya ranjshe i oshibochno nazval prichinoj FIFO: prezhnij prompt zadaval vetvi dlya sobstvennogo i chuzhogo vladeljca i yavnoye prodolzheniye posle `finish-own-clean`, ne zadavaya stolj zhe yavnogo prodolzheniya dlya pervichnogo `state=idle` obsjhego diagnosticheskogo otveta.

Ocheredj poluchila otdeljnuyu read-only-proyekciyu `heartbeat-status`. Validnyij otvet soderzhit toljko `state`: `idle` pri odnovremennom otsutstvii owner i waiting, `own_owner` pri tochnom sobstvennom vladeljce dazhe s ozhidayusjhimi posledovatelyami i `busy` vo vsekh ostaljnyikh zanyatyikh sostoyaniyakh. Poetomu `last_completion`, vyirosshij `next_seq`, ref, object ID, pokoleniya i chuzhiye identifikatoryi boljshe ne uchastvuyut v modeljnoj interpretacii svobodyi. Prompt yavno prodolzhayet pervichnyij `idle`, razreshayet rovno odin `finish-own-clean` posle `own_owner`, povtoryayet proyekciyu i prodolzhayet toljko na `idle`; `busy`, povtornyij `own_owner`, oshibka ili inoj payload ostayutsya fail-closed.

Susjhestvuyusjhaya aktivnaya live-avtomatizaciya obnovlena kanonicheskim renderer bez sozdaniya dublikata. Exact-diff posle shtatnogo obnovleniya podtverdil neizmennostj identichnosti, celi, imeni, pyatiminutnogo raspisaniya, statusa, versii i vremeni sozdaniya; izmenilisj toljko prompt i sluzhebnyij `updated_at`. Integracionnoye revjyu obnaruzhilo odno protivorechivoye staroye predlozheniye dokumentacii s nedostatochnoj proverkoj waiting; zamechaniye P2 ustraneno do zaversheniya revjyu, nezakryityikh susjhestvennyikh zamechanij ne ostalosj.

## Profilj vremeni vyipolneniya

| Stadiya                      | Dliteljnostj | Granicyi i sposob izmereniya                                      |
| --------------------------- | ------------ | --------------------------------------------------------------- |
| Registraciya i ozhidaniye FIFO | meneye 1 s    | `join` srazu vernul `admitted`; dolgozhivusjhego ozhidaniya ne byilo. |
| Diagnostika                 | okolo 13 min | Ot host-snimka i Git-forenziki do dokazannoj prichinyi.           |
| TDD i realizaciya            | okolo 25 min | Perekryivayusjhiyesya krasnyiye i zelyonyiye progonyi dvukh konturov.        |
| Live-remont                 | meneye 1 s    | In-place-obnovleniye i mekhanicheskaya exact-diff-sverka.           |
| Polnyij smoke-check          | 686,800 s    | Pervaya popyitka vyiyavila format; povtor proshyol vse 62 shaga.        |
| Peredacha i publikaciya       | vne profilya  | Atomarnyij commit+handoff i tochnaya post-handoff-publikaciya.      |

### Pryamyiye zapuski proverok

| Vyizov                                                                 | Dliteljnostj | Rezuljtat                                                        |
| --------------------------------------------------------------------- | ------------ | ---------------------------------------------------------------- |
| FIFO TDD-red: 4 regressii `heartbeat-status`                          | 2,713 s      | neuspeshno ozhidayemo: podkomanda yesjhyo otsutstvovala                 |
| FIFO targeted-green: 4 regressii                                     | 3,164 s      | uspeshno — 4 iz 4                                                 |
| FIFO polnyij promezhutochnyij nabor                                      | 57,895 s     | uspeshno — 57 iz 57                                               |
| FIFO finaljnyij targeted-progon                                       | 3,260 s      | uspeshno — 4 iz 4                                                 |
| FIFO `diff --check` i statistika                                     | 0,100 s      | uspeshno — probeljnyikh oshibok net                                  |
| Renderer TDD-red                                                     | 0,060 s      | neuspeshno ozhidayemo: polozhiteljnaya vetvj yesjhyo otsutstvovala        |
| Vetochnyij prompt TDD-red                                              | 0,190 s      | neuspeshno ozhidayemo: pervichnyij `idle` ne prodolzhal tik            |
| Renderer targeted-green                                              | 0,060 s      | uspeshno — 1 iz 1                                                 |
| Vetochnyij gate i limit targeted-green                                 | 0,260 s      | uspeshno — 2 iz 2                                                 |
| Renderer polnyij nabor                                                | 0,450 s      | uspeshno — 19 iz 19                                               |
| Sleduyusjhij shag vetki polnyij promezhutochnyij nabor                        | 36,360 s     | uspeshno — 93 iz 93                                               |
| Razmer prompt i `git diff --check`                                   | 0,100 s      | uspeshno — 14 689 iz 14 722 simvolov, diff chist                   |
| Dopolniteljnaya regressiya zavershyonnoj ruchnoj sessii                   | 3,967 s      | uspeshno — 5 iz 5                                                 |
| Live post-view exact-diff                                            | 0,400 s      | uspeshno — izmenilisj toljko prompt i `updated_at`                |
| Kornevoj `git diff --check`                                          | 0,000 s      | uspeshno — probeljnyikh oshibok net                                  |
| FIFO polnyij itogovyij nabor                                           | 69,440 s     | uspeshno — 58 iz 58                                               |
| Sleduyusjhij shag vetki polnyij itogovyij nabor                             | 43,300 s     | uspeshno — 112 iz 112                                             |
| Validaciya sokhranyonnogo revjyu                                         | 0,060 s      | uspeshno — polnyij otchyot sootvetstvuyet konfiguracii                |
| Integracionnoye revjyu: polnyij FIFO                                    | 62,056 s     | uspeshno — 58 iz 58                                               |
| Integracionnoye revjyu: polnyij sleduyusjhij shag                           | 43,135 s     | uspeshno — 112 iz 112                                             |
| Integracionnoye revjyu: diff, sostoyaniye i smyislovoj prosmotr           | 0,100 s      | uspeshno — diff chist; odno smyislovoye zamechaniye P2 zatem ustraneno |
| Povtornaya validaciya sokhranyonnogo revjyu                               | 0,060 s      | uspeshno — ustranyonnaya P2-nakhodka i itog soglasovanyi              |
| Polnyij smoke-check, pervaya popyitka                                   | 348,290 s    | neuspeshno — svyaznostj otklonila slitnyij status `успешно:`        |
| Kontroljnaya proverka svyaznosti posle ispravleniya                     | 13,190 s     | uspeshno — struktura sessii i arifmetika profilya soglasovanyi      |
| Polnyij smoke-check, povtor                                           | 338,510 s    | uspeshno — projdenyi vse 62 shaga                                   |

Obsjheye vremya pryamyikh zapuskov proverok: 1027,120 s.

Granica profilya: ot `join` do metki posle uspeshnogo polnogo smoke-check. Zakryivayusjhiye recency, svyaznostj, diff, FIFO i publikaciya ne rasshiryayut profilj rekursivno.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:477d788c8df95ec841545cd121775966440b77e35aa25490409df8ffb27e7fc6 -->
<!-- FUM-MD-RECENCY:END -->
