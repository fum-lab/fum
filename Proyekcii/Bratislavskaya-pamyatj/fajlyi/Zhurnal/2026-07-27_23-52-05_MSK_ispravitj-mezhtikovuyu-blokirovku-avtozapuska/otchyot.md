# Otchyot 2026-07-27 23:52:05 MSK - Ispravitj mezhtikovuyu blokirovku avtozapuska

Kontrakt avtozapuska teperj yavno razlichayet nezavisimyiye tiki postoyannoj dispetcherskoj zadachi. Uspeshnoye sozdaniye odnogo shaga ostayotsya zasjhitoj toljko yego tochnogo pokoleniya, a ne prevrasjhayetsya v bessrochnyij zapret sleduyusjhikh pokolenij posle izmeneniya `HEAD`.

## Diagnoz

Lokaljnyiye `validate` i `show` podtverdili validnyij rabochij nabor s dvumya kandidatami `ready` i novyij vyibor FUM-STEP-0099 na tekusjhem `HEAD`. `claim-status` pri etom sokhranyal pokoleniye uzhe zavershyonnoj FUM-STEP-0098; avtonomnyiye testyi dokazali, chto novyij `selection.id` so svezhim lease sposoben atomarno zamenitj takoj claim.

Istoriya prikreplyonnogo heartbeat dala razlichayusjheye svideteljstvo. Odin tik uspeshno sozdal zadachu FUM-STEP-0098, ta zavershila rabotu i opublikovala novyij kommit. Posle etogo chetyire tika podryad ne vyizyivali novyij claim, a zavershalisj tochnyim smyislom: predyidusjhij zapusk uzhe sozdal zadachu, poetomu povtornaya rezervaciya zapresjhena. Ispolnyayemyij shag 10 dejstviteljno formuliroval zapret posle pervogo `create_thread` bez slov o tekusjhem tike. Postoyannaya zadacha sokhranyala istoriyu i perenosila etot flag v novyiye vkhodnyiye soobsjheniya `<heartbeat>`.

## Ispravleniye

Kazhdoye novoye vkhodnoye soobsjheniye `<heartbeat>` teperj yavno nachinayet otdeljnuyu logicheskuyu popyitku. Mezhdu tikami ne perenosyatsya `lease_id` i priznak uzhe vyizvannogo `create_thread`; zapret povtornogo claim ili sozdaniya dejstvuyet posle pervogo `create_thread` toljko v tekusjhem tike. Novyij `selection.id` sleduyusjhej vershinyi poluchayet svezhij lease i zamenyayet prezhnij claim, a tochnyij neizmenivshijsya vyibor po-prezhnemu ostanavlivayet shtatnyij `already_claimed`.

Granica zakreplena v `AGENTS.md`, proizvodnom opisanii avtomatizacij, lokaljnom navyike, ispolnyayemom heartbeat-shablone i opisanii rabochego nabora. Novyij TDD-test snachala vosproizvyol otsutstviye granicyi, zatem proshyol vmeste s polnyim naborom iz 76 testov. Zhivaya avtomatizaciya obnovlena na meste s prezhnimi celjyu, tipom heartbeat, pyatiminutnyim raspisaniyem i sostoyaniyem `ACTIVE`; novyij tik namerenno ne forsirovalsya.

## Proverki

Lokaljnyij selektor i fenced-zamena claim proverenyi nezavisimo ot vneshnego host. Skhema dostupnyikh `codex_app`-instrumentov sovmestima s shablonom; zavisshiye read-only-vyizovyi dvukh subagentov sokhranenyi kak otricateljnyiye rezuljtatyi i ne ostavili claim, potomu chto vse dolgiye host-proverki predshestvuyut mutacii. Pervyij polnyij smoke-check proshyol 60 shagov i na poslednej svyaznosti obnaruzhil netochnyij sintaksis statusov zhurnaljnogo profilya. Posle ispravleniya formata polnyij povtor proshyol 61/61 shag, vklyuchaya 76/76 testov sleduyusjhego shaga, SwiftPM-kontur, reyestryi, recency, graf i svyaznostj sessii.

## Profilj vremeni vyipolneniya

| Stadiya                                      |  Dliteljnostj | Granicyi i sposob izmereniya                                                                                                            |
| ------------------------------------------- | ------------: | ------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i ozhidaniye FIFO                 |        0,40 s | Wall time yedinstvennogo `join`; sostoyaniye `admitted` polucheno srazu, perioda `waiting` ne byilo.                                       |
| Diagnostika, TDD i sinkhronizaciya heartbeat  |   ne izmereno | Ot FIFO-dopuska do podgotovki sluzhebnyikh materialov; host-audityi shli paralleljno i ikh dliteljnosti neljzya skladyivatj kak wall time.    |
| Celevyiye proverki do polnogo smoke-check     |   ne izmereno | Ot krasnogo regressionnogo testa do uspeshnogo polnogo nabora; pryamyiye processyi perechislenyi nizhe i chastichno vyipolnyalisj paralleljno.    |
| Pervyij polnyij smoke-check                   |  3 min 49,2 s | Vneshnij `/usr/bin/time`; vnutrennyaya monotonnaya dliteljnostj ispolnitelya — `229,175` s; oshibka na shage 61 sokhranena.                   |
| Ispravleniye formata zhurnaljnogo profilya     |   ne izmereno | Mezhdu dvumya polnyimi zapuskami ispravlen toljko mashinno proveryayemyij format statusov, zatem obnovlenyi recency i graf.                   |
| Povtornyij polnyij smoke-check                |  3 min 46,1 s | Vneshnij `/usr/bin/time`; vnutrennyaya monotonnaya dliteljnostj ispolnitelya — `226,044` s; projden 61/61 shag.                             |

### Pryamyiye zapuski proverok

| Vyizov                                                                                    | Dliteljnostj | Rezuljtat                                                                                                  |
| ---------------------------------------------------------------------------------------- | -----------: | ---------------------------------------------------------------------------------------------------------- |
| `[root]` rannij `branch-next-step validate`                                              |       0,54 s | uspeshno (`state=valid`, dva kandidata `ready`)                                                             |
| `[root]` rannij `branch-next-step show`                                                  |       0,83 s | uspeshno (vyibrana FUM-STEP-0099 na tekusjhem `HEAD`)                                                          |
| `[root]` rannij `branch-next-step claim-status`                                          |       0,18 s | uspeshno (nablyudayetsya staroye zavershyonnoye pokoleniye)                                                         |
| `[root]` zhivoj snimok `list_threads(limit=50)`                                           |       2,20 s | uspeshno (heartbeat zakreplyon; tekusjhaya poljzovateljskaya zadacha aktivna)                                     |
| `[root]` pervyij `read_thread` s chrezmernyim limitom                                       |       0,00 s | neuspeshno (host otklonil `turnLimit=40`, maksimum raven 10)                                                |
| `[root]` chteniye poslednikh heartbeat-tikov                                                |       0,50 s | uspeshno (poluchenyi posledniye resheniya dispetchera)                                                            |
| `[root]` chteniye predyidusjhej stranicyi heartbeat-tikov                                      |       0,40 s | uspeshno (najden predshestvuyusjhij uspeshnyij `NOTIFY`)                                                          |
| `[root]` povtornoye chteniye istorii dlya mashinnogo razbora                                  |       0,50 s | uspeshno (pryamoj vyivod okazalsya usechyon i ne ispoljzovan kak itogovoye svideteljstvo)                         |
| `[root]` proverka tipa otveta `read_thread`                                              |       0,40 s | uspeshno (otvet podtverzhdyon kak JSON-stroka)                                                                |
| `[root]` tochechnyij razbor odnogo heartbeat-tika                                           |       0,40 s | uspeshno (izvlecheno resheniye bez povtoreniya polnogo prompta)                                                 |
| `[root]` kompaktnoye chteniye serii heartbeat-reshenij                                       |       3,80 s | uspeshno (dokazanyi chetyire mezhtikovyikh otkaza posle novogo `HEAD`)                                            |
| `[root]` chteniye zavershyonnoj avtomaticheski sozdannoj zadachi                               |       0,10 s | uspeshno (podtverzhdenyi zaversheniye i publikaciya FUM-STEP-0098)                                               |
| `[root]` proverka sokhranyonnogo proyekta cherez `list_projects`                             |       0,10 s | uspeshno (tochnyij lokaljnyij Git-proyekt susjhestvuyet)                                                           |
| `[root]` iskhodnaya sverka zhivogo heartbeat s repozitornyim shablonom                        |       0,03 s | uspeshno (do ispravleniya registraciya sovpadala s shablonom)                                                  |
| `[root]` iskhodnyij shtatnyij prosmotr kartochki avtomatizacii                                |       0,10 s | uspeshno (kartochka otrisovana)                                                                              |
| `[root]` krasnyij test mezhtikovoj granicyi                                                 |       0,22 s | neuspeshno (ozhidayemo; granica novogo `<heartbeat>` otsutstvovala)                                           |
| `[root]` zelyonyij tochechnyij test mezhtikovoj granicyi                                        |       0,21 s | uspeshno                                                                                                    |
| `[root]` povtor tochechnogo testa posle usileniya obeimi storonami claim-invarianta         |       0,19 s | uspeshno (1/1)                                                                                              |
| `[root]` shtatnyij prosmotr obnovlyonnogo heartbeat                                         |       0,10 s | uspeshno (kartochka otrisovana posle obnovleniya)                                                             |
| `[root]` sverka obnovlyonnoj registracii s shablonom                                       |       0,03 s | uspeshno (tip, celj, raspisaniye, status i prompt soglasovanyi)                                               |
| `[root]` itogovyij shtatnyij prosmotr obnovlyonnogo heartbeat                                |       0,07 s | uspeshno (kartochka otrisovana posle okonchateljnoj sinkhronizacii prompt)                                     |
| `[root]` itogovaya pobajtovaya sverka zhivoj registracii s shablonom                         |       0,09 s | uspeshno (tip, celj, raspisaniye, status i prompt tochno soglasovanyi)                                         |
| `[root]` proverka Git-sostoyaniya, statistiki diff i `git diff --check`                    |       0,10 s | uspeshno (oshibok probelov ne najdeno; klassificirovanyi toljko fajlyi tekusjhej sessii)                         |
| `[root]` pervyij polnyij nabor `fum-sleduyusjhij-shag-vetki` posle pravki                  |      34,02 s | neuspeshno (76 testov; sokhranyonnaya proverka potrebovala prezhnyuyu tochnuyu podstroku yavnogo podtverzhdeniya)      |
| `[root]` povtornyij polnyij nabor `fum-sleduyusjhij-shag-vetki`                            |      34,01 s | uspeshno (76/76)                                                                                            |
| `[audit_selector]` nezavisimyij `validate`                                                |       0,49 s | uspeshno                                                                                                    |
| `[audit_selector]` nezavisimyij `show`                                                    |       0,77 s | uspeshno                                                                                                    |
| `[audit_selector]` fenced `show` tekusjhego pokoleniya                                      |       0,75 s | uspeshno                                                                                                    |
| `[audit_selector]` nezavisimyij `claim-status`                                            |       0,19 s | uspeshno                                                                                                    |
| `[audit_selector]` pervaya tekhnicheskaya popyitka polnogo nabora                             |      30,00 s | prervano (PTY-granica posle 64 uspeshnyikh tochek; itogovyij kod ne ispoljzovan)                                |
| `[audit_selector]` polnyij nabor selektora                                                |      34,05 s | uspeshno (75/75 do dobavleniya novogo testa)                                                                 |
| `[audit_selector]` dva testa mezhpokolennoj zamenyi claim                                  |       3,30 s | uspeshno (2/2)                                                                                              |
| `[audit_selector]` shestj celevyikh testov same-selection i mezhpokolennoj zamenyi claim      |       4,19 s | uspeshno (6/6); najdena i zatem ustranena neodnoznachnostj opisaniya `Start`                                  |
| `[audit_heartbeat_contract]` nezavisimyij krasnyij test mezhtikovoj granicyi                 |       0,21 s | neuspeshno (ozhidayemo; vosproizvedena ta zhe otsutstvuyusjhaya formulirovka)                                      |
| `[audit_heartbeat_contract]` itogovyij uzkij test mezhtikovoj granicyi                      |       0,20 s | uspeshno (1/1)                                                                                              |
| `[audit_heartbeat_contract]` chetyire celevyikh scenariya claim-fence                         |       2,44 s | uspeshno (4/4: poteryannyij otvet, konkurenciya lease, povtor i zamena novyim vyiborom)                          |
| `[audit_heartbeat_contract]` polnyij heartbeat-podnabor                                   |       0,85 s | uspeshno (9/9)                                                                                              |
| `[audit_heartbeat_contract]` celevoj `git diff --check`                                  |       0,01 s | uspeshno                                                                                                    |
| `[audit_heartbeat_contract]` itogovaya proverka Git-sostoyaniya                             |       0,03 s | uspeshno (testovyikh artefaktov net)                                                                          |
| `[audit_heartbeat_contract]` `list_threads(limit=50)`                                    |     125,00 s | prervano (ostanovlen bez otveta; vneshneye sostoyaniye ne izmeneno)                                            |
| `[audit_heartbeat_contract]` `list_projects`                                             |      53,00 s | prervano (ostanovlen bez otveta; vneshneye sostoyaniye ne izmeneno)                                            |
| `[audit_heartbeat_contract]` inventarizaciya dostupnyikh skhem host-instrumentov             |       0,00 s | uspeshno (nesovmestimosti argumentov ne najdeno)                                                            |
| `[audit_runtime_history]` `list_threads(limit=50)`                                       |     190,00 s | prervano (ostanovlen posle nablyudeniya ne meneye 190 s bez otveta)                                           |
| `[audit_runtime_history]` shtatnyij prosmotr kartochki avtomatizacii                        |     100,00 s | prervano (ostanovlen posle nablyudeniya ne meneye 100 s bez otveta)                                           |
| `[audit_runtime_history]` chteniye istorii dispetchera                                      |     100,00 s | prervano (ostanovleno posle nablyudeniya ne meneye 100 s bez otveta)                                          |
| `[audit_runtime_history]` itogovyij `git diff --check HEAD --`                            |       0,00 s | uspeshno                                                                                                    |
| `[audit_runtime_history]` proverka mashinno-lokaljnyikh putej                               |       9,91 s | uspeshno                                                                                                    |
| `[audit_runtime_history]` proverka navigacii zaprosov i zhurnaljnogo indeksa              |       0,00 s | uspeshno                                                                                                    |
| `[audit_runtime_history]` sopostavleniye zatronutyikh fajlov s Git-sostoyaniyem               |       0,00 s | uspeshno (13/13)                                                                                            |
| `[audit_runtime_history]` skan dobavlennogo soderzhimogo na privatnyiye ID i lokaljnyiye puti |       0,00 s | uspeshno                                                                                                    |
| `[audit_runtime_history]` proverka arifmetiki profilya vremeni                            |       0,00 s | uspeshno (45 strok, 724,60 s do proverok etogo audita)                                                      |
| `[root]` pervyij polnyij smoke-check repozitoriya                                           |     229,22 s | neuspeshno (60/61; svyaznostj otklonila netochnyij sintaksis statusov zhurnaljnogo profilya)                     |
| `[root]` povtornyij polnyij smoke-check repozitoriya                                        |     226,09 s | uspeshno (61/61; vnutrennyaya monotonnaya dliteljnostj `226,044` s)                                            |

Obsjheye vremya pryamyikh zapuskov proverok: 1189,82 s.

Granica profilya: ot yedinstvennogo FIFO-`join` do zaversheniya uspeshnogo povtornogo smoke-check; pervyij zapusk nachat v `2026-07-27T21:24:14Z`, povtornyij — v `2026-07-27T21:29:32Z`. Vlozhennyiye shagi yedinogo runner ne dubliruyutsya kak pryamyiye vyizovyi, a dliteljnosti paralleljnyikh auditov ne skladyivayutsya s kalendarnyim vremenem. Posle etoj granicyi generatoryi recency i grafa uchityivayut itogovuyu zapisj otchyota, a `git diff --check` i svyaznostj povtoryayutsya s tem zhe tochnyim soobsjheniyem kommita. Eti zamyikayusjhiye vyizovyi, staging, atomarnaya peredacha i publikaciya sleduyut posle granicyi i ne obrazuyut rekursivnyij novyij smoke-check.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [shablon heartbeat-dispetchera](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [opisaniye vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1a1e5512481d0a5997fa54b3584f9c022fc36c1bb1b5199bb8768212f287d673 -->
<!-- FUM-MD-RECENCY:END -->
