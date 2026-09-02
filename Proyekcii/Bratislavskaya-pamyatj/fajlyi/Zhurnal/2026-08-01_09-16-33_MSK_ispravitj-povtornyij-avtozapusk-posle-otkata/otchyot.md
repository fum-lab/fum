# Otchyot 2026-08-01 09:16:33 MSK - Ispravitj povtornyij avtozapusk posle otkata

Rabochaya sessiya ustranyayet zavisaniye neizmenivshegosya shaga posle poruchennogo dochernej zadache polnogo otkata realizacii i vvodit proveryayemyij shtatnyij iskhod, kotoryij snova razreshayet avtozapusk toj zhe kartochki.

## Rezuljtat

Git- i host-forenzika razdelili dva sostoyaniya. Otkativshaya zadacha dejstviteljno ostanovila pisatelej, vernula rabochuyu kopiyu k iskhodnoj vershine i zavershila chistuyu peredachu FIFO. No otdeljnyij claim skhemyi `2` ostalsya na prezhnikh `selection.id`, `selection.head` i `step_id`: staryij dochernij prompt pryamo zapresjhal osvobozhdatj claim uspeshno sozdannogo zapuska i ne imel operacii perevzvedeniya. Poetomu novyij heartbeat videl tot zhe vyibor, poluchal `already_claimed` i bezopasno otkazyivalsya sozdavatj dublikat. Zavisaniye byilo zakonomernyim sledstviyem nepolnogo zhiznennogo cikla, a ne oshibkoj samogo otkata.

Claim teperj prokhodit nablyudayemyiye stadii `2 → 3 → 4`. Dispetcher sozdayot nesvyazannuyu rezervaciyu i peredayot lease toljko vnutri yavno nepublikuyemogo runtime-konverta. Posle kazhdogo FIFO-dopuska dochernyaya zadacha sama vyizyivayet `bind-run` s sobstvennyim kornevyim `task_id`; pervyij `verify-run` odnoj Git-tranzakciyej sveryayet tochnyiye queue ref, vladeljca, `generation`, `base_head`, branch ref, selection i claim, a zatem zakreplyayet pokoleniye. Svyazannaya zapisj ne pozvolyayet vtoromu heartbeat povtoritj `create_thread`, dazhe yesli on kakim-libo obrazom povtoril prezhnij lease.

Novaya operaciya `rearm` prednaznachena imenno dlya polnogo chistogo otkata zhivoj zadachi. Ona trebuyet claim skhemyi `4`, tochnyiye lease, `task_id`, `generation` i selection, proveryayet otsutstviye izmenenij vne razreshyonnoj kornevoj `.obsidian/`, pustoj indeks i atomarno sopostavlyayet queue ref, iskhodnuyu vershinu vetki i compare-and-delete claim. Posle uspekha razreshyon toljko `finish-clean`. Yesli process oborvyotsya v promezhutke, FIFO-vladelec ostanetsya i ostanovit povtornyij heartbeat do vozobnovleniya toj zhe zadachi: zhivostj vremenno teryayetsya, no vtoroj pisatelj ne poyavlyayetsya.

Smyislovoye revjyu utochnilo granicu avarijnogo vosstanovleniya. Uspeshno sozdannaya zhivaya zadacha nikogda ne vyizyivayet `release` i pri otkate ispoljzuyet toljko `rearm`. Privilegirovannyij vneshnij `release` lyuboj chitayemoj skhemyi sokhranyayetsya otdeljno: on dopustim lishj posle host-dokazateljstva, chto vozmozhnaya prezhnyaya zadacha okonchateljno ostanovlena i ne smozhet vozobnovitj zapisj, i trebuyet tochnyij nablyudyonnyij lease. Eto sokhranyayet vozmozhnostj vosstanovitj schema `3` ili `4` posle neobratimo ostanovlennogo ispolnitelya, ne prevrasjhaya `release` v shtatnyij obkhod run-fence.

Kanonicheskij prompt posle TDD-szhatiya zanimayet `14 930` simvolov pri zakreplyonnom limite `15 117`. Susjhestvuyusjhaya aktivnaya heartbeat-avtomatizaciya dvazhdyi obnovlyalasj na meste po mere ustraneniya zamechanij revjyu; kazhdyij post-view exact-diff razreshil izmeneniye toljko prompt i `updated_at`, sokhraniv status `ACTIVE`, identichnostj, celj i pyatiminutnoye raspisaniye. Staryij claim skhemyi `2` snyat toljko posle novoj polnoj host-inventarizacii: celevaya zadacha nakhodilasj v sostoyanii `notLoaded`, yeyo poslednij khod imel status `completed`, ne soderzhal oshibki i zavershalsya podtverzhdeniyem chistogo otkata. Post-release-proverka vernula `unclaimed`; opaque lease, pokoleniya i host-identifikatoryi ne opublikovanyi.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj   | Granicyi i sposob izmereniya                                                                 |
| ------------------------------ | -------------- | ------------------------------------------------------------------------------------------ |
| Registraciya i ozhidaniye FIFO    | meneye 1 s      | `join` srazu vernul `admitted`; dolgozhivusjhego ozhidaniya ne byilo.                            |
| Diagnostika, TDD i realizaciya  | okolo 89 min   | Ot prefiksa `09:16:33` do finaljnogo zelyonogo nabora i ustraneniya zamechaniya review.        |
| Live-vosstanovleniye            | 2,377 s        | Dva exact-diff-obnovleniya heartbeat i fenced-snyatiye starogo claim; vyizovyi shli razdeljno.    |
| Sokhranyonnoye revjyu              | 0,250 s        | Postroyeniye otchyota iz Git-sreza i pervaya polnaya validaciya sokhranyonnoj konfiguracii.          |
| Polnyij smoke-check             | 490,600 s      | Zaklyuchiteljnyij vneshnij progon proshyol vse `65` iz `65` shagov.                                |
| Atomarnaya peredacha FIFO        | vne profilya    | Isklyuchena iz rekursivnoj granicyi; posle `committed` zadacha boljshe nichego ne zapisyivayet.     |

### Pryamyiye zapuski proverok

U dvukh rannikh peresekayusjhikhsya diagnosticheskikh progonov — vosjmi release/stale-scenariyev (`7` zelyonyikh, odin krasnyij) i otdeljnogo povtora byivshego krasnogo scenariya — konechnyij izmeriteljnyij deskriptor ne sokhranilsya. Oba vyizova uchtenyi kak proiskhozhdeniye TDD, no ne poluchayut vyimyishlennuyu dliteljnostj i ne vkhodyat v chislovuyu tablicu ili summu.

| Vyizov                                                          | Dliteljnostj | Rezuljtat                                                                                       |
| --------------------------------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------- |
| pervyij `py_compile` realizacii                                  | 0,060 s      | uspeshno — sintaksis iskhodnogo karkasa podtverzhdyon                                               |
| povtornyij `py_compile` posle pravok                             | 0,060 s      | uspeshno — sintaksis posle vvedeniya run-fence podtverzhdyon                                        |
| tretij sintaksicheskij preflight s poiskom                       | 0,200 s      | uspeshno — modulj kompiliruyetsya, ostatochnyiye opechatki najdenyi otdeljno                            |
| TDD-red do poyavleniya API                                        | 9,220 s      | neuspeshno ozhidayemo — 11 scenariyev dali 23 failure-zapisi i odnu oshibku                           |
| pervyij shirokij checkpoint 24 novyikh scenariyev                   | 70,900 s     | neuspeshno ozhidayemo — 14 proshli, 10 vyiyavili semanticheskiye probelyi                                 |
| pivot-povtor pyati klyuchevyikh scenariyev                            | 18,640 s     | uspeshno — 5 iz 5                                                                                |
| race/opaque target                                              | 6,060 s      | uspeshno — 3 iz 3                                                                                |
| rasshirennyij stabilizirovannyij checkpoint                       | 79,590 s     | uspeshno — 29 iz 29                                                                              |
| rannij polnyij nabor                                             | 125,690 s    | uspeshno — 141 test                                                                              |
| TDD-red runtime-konverta i child bind                           | 0,204 s      | neuspeshno ozhidayemo — dve regressii zafiksirovali tri otsutstvuyusjhikh obyazateljstva                 |
| targeted-green runtime-konverta                                 | 0,206 s      | uspeshno — 2 iz 2                                                                                |
| nabor exact-lease i chistotyi verify                              | 13,310 s     | uspeshno — 8 iz 8                                                                                |
| rasshirennyij verify/rearm subset                                 | 61,910 s     | uspeshno — 26 iz 26                                                                              |
| pervyij polnyij nabor posle smenyi signatur                        | 124,926 s    | neuspeshno — 5 staticheskikh proverok obnaruzhili poteryannyiye obyazateljstva prompt                    |
| lokaljnyij polnyij povtor so skryityim stderr                       | 61,003 s     | neuspeshno — ostanovilsya na tryokh yesjhyo ne sinkhronizirovannyikh static assertions                      |
| polnyij nabor FIFO                                               | 66,879 s     | uspeshno — 58 testov                                                                             |
| odinochnaya static-regressiya posle szhatiya                         | 0,122 s      | neuspeshno ozhidayemo — obnaruzhena ustarevshaya i poteryannaya formulirovka                             |
| rasshirennaya static-sverka semi pravil                           | 0,750 s      | neuspeshno — 4 proshli, 3 assertions trebovali grammaticheskoj sinkhronizacii                        |
| finaljnaya static-sverka pyati pravil                             | 0,700 s      | uspeshno — 5 iz 5                                                                                |
| heartbeat-gruppa osnovnogo fajla                                | 2,190 s      | uspeshno — 19 testov                                                                             |
| heartbeat discovery dvukh modulej                                | 2,525 s      | uspeshno — 38 testov                                                                             |
| polnyij nabor pered smyislovyim review                             | 137,370 s    | uspeshno — 148 testov                                                                            |
| TDD-red gipotezyi schema-only release                            | 1,400 s      | neuspeshno ozhidayemo — tri subtest zafiksirovali konflikt s neobkhodimyim vneshnim recovery           |
| external-recovery posle liveness-review                         | 2,700 s      | uspeshno — exact lease osvobozhdayet skhemyi 1–4, nevernyij lease sokhranyayet ref                        |
| TDD-red polnomochiya dochernego release                            | 0,270 s      | neuspeshno ozhidayemo — dva subtest podtverdili otsutstviye yavnoj child-zapretiteljnoj frazyi         |
| child release/budget targeted-green                             | 0,380 s      | uspeshno — 2 iz 2; renderer zanimayet 14 930 iz 15 117 simvolov                                    |
| zaklyuchiteljnyij polnyij nabor sleduyusjhego shaga                     | 130,910 s    | uspeshno — 149 testov                                                                            |
| pervyij AST-audit direct API                                     | 0,200 s      | uspeshno — sintaksis i formyi vyizovov razobranyi                                                    |
| vtoroj AST-audit exact lease                                    | 0,200 s      | uspeshno — vse shestj direct API-vyizovov imeyut novuyu semiargumentnuyu signaturu                     |
| pervichnaya proverka razmera renderer                              | 0,100 s      | neuspeshno — 15 191 simvol prevyisil limit 15 117                                                  |
| finaljnaya proverka razmera renderer                              | 0,200 s      | uspeshno — 14 930 simvolov                                                                       |
| pervyij `git diff --check`                                       | 0,100 s      | uspeshno — probeljnyikh oshibok net                                                                 |
| povtornyij `git diff --check`                                    | 0,100 s      | uspeshno — probeljnyikh oshibok net                                                                 |
| safety-review `git diff --check HEAD`                            | 0,000 s      | uspeshno — komanda zavershilasj bez vyivoda                                                        |
| pervyij live post-view exact-diff                                | 0,461 s      | uspeshno — izmenilisj toljko prompt i `updated_at`                                                |
| host-proof i fenced-release starogo claim                       | 1,447 s      | uspeshno — zavershyonnyij chistyij otkat dokazan, itogovoye sostoyaniye `unclaimed`                       |
| finaljnyij live post-view exact-diff                              | 0,469 s      | uspeshno — izmenilisj toljko prompt i `updated_at`, status ostalsya `ACTIVE`                       |
| postroyeniye sokhranyonnogo revjyu                                   | 0,180 s      | uspeshno — otchyot materializovan iz konfiguracii i tekusjhego Git-sreza                              |
| pervaya validaciya sokhranyonnogo revjyu                             | 0,070 s      | uspeshno — obyazateljnyiye razdelyi i ustranyonnaya P2-nakhodka soglasovanyi                              |
| pervaya proverka svyaznosti sessii                                | 16,250 s     | uspeshno — navigaciya, kornevoj ID, profilj, ssyilki, recency i soobsjheniye kommita soglasovanyi        |
| zaklyuchiteljnyij polnyij smoke-check                               | 490,600 s    | uspeshno — projdenyi vse 65 iz 65 shagov                                                            |

Obsjheye vremya pryamyikh zapuskov proverok: 1428,552 s.

Granica profilya: ot pervogo uspeshnogo FIFO-dopuska do rezuljtata zaklyuchiteljnogo polnogo smoke-check. Dliteljnosti paralleljnyikh i peresekayusjhikhsya vyizovov skladyivayutsya kak aggregate call-time, a ne kalendarnoye vremya; vlozhennyiye shagi smoke-check povtorno ne pribavlyayutsya. Posleduyusjhiye materializaciya recency posle zapisi itogovoj dliteljnosti, finaljnyiye read-only-sverki, staging i atomarnyij queue `commit` nakhodyatsya za rekursivnoj granicej i ne sozdayut novyiye stroki profilya.

## Vklad ispolnitelej

- Kornevoj ispolnitelj vosstanovil host- i Git-trassu sboya, vyibral protokol, realizoval run-fence i `rearm`, obnovil live-avtomatizaciyu, vyipolnil vneshneye vosstanovleniye claim i otvechayet za itogovuyu integraciyu.
- Subagent regressij razrabotal razlichimyiye red/green-scenarii bind, verify, rearm, gonok refs, chistotyi, exact lease, runtime-konverta i vneshnego recovery; peresecheniya testov ispoljzovalisj kak diagnosticheskiye povtoryi, a ne nezavisimoye golosovaniye.
- Subagent proizvodnoj dokumentacii nezavisimo soglasoval skhemyi `2 → 3 → 4`, liveness-gap, vneshneye recovery i nepublikuyemyij runtime-konvert v pyati vyidelennyikh dokumentakh.
- Safety-revjyuyer prognal polnyiye naboryi, proveril queue/claim CAS i obnaruzhil poteryannuyu granicu polnomochij `release`; pervonachaljnaya schema-only-gipoteza byila otvergnuta posle proverki liveness-case i zamenena soglasovannyim razdeleniyem zhivogo `rearm` i vneshnego recovery.

## Resheniya i ogranicheniya

- Dispatcher-side bind ne ispoljzuyetsya: korrektnostj odinakova dlya gotovogo `threadId` i asinkhronnogo `clientThreadId`, potomu chto bind vsegda vyipolnyayet sama dopusjhennaya zadacha.
- `verify-run` i `rearm` trebuyut exact lease, no ne publikuyut fakticheskoye znacheniye pri mismatch.
- Queue blob proveryayetsya zakryitoj skhemoj, vklyuchaya unikaljnostj i poryadok uchastnikov, tochnogo vladeljca i konechnyiye chislovyiye znacheniya; neizvestnoye pole ili raskhozhdeniye zakryivayet run-fence.
- Chistota checkout ostayotsya procedurno zasjhisjhyonnoj ot TOCTOU obyazateljnoj ostanovkoj pisatelej; Git refs pri etom proveryayutsya odnoj atomarnoj tranzakciyej.
- Vneshnij `release` ne mozhet sam prochitatj host-sostoyaniye, poetomu okonchateljnaya ostanovka prezhnej zadachi ostayotsya obyazateljnyim vneshnim dokazateljstvom, a ne vyivodom iz odnogo lease.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [sokhranyonnoye revjyu](materialyi/revjyu/2026-08-01_10-45-59_MSK_revjyu-povtornogo-avtozapuska-posle-otkata.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2dba3dd6911f0e01fbf8988679f8da79d2a1abfdb2a62857dd842535dae1c442 -->
<!-- FUM-MD-RECENCY:END -->
