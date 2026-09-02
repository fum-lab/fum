# Otchyot 2026-07-27 18:28:42 MSK - Vyibiratj sleduyusjhij shag pri zapuske s uchyotom istorii kommitov

Rabochij nabor vetki boljshe ne predvyibirayet odnu kartochku. On khranit pul vsekh individualjno dopustimyikh `ready`, a konkretnyij shag vyibirayetsya po tochnomu `HEAD` toljko posle povtornoj proverki prostoya host. Tak svyazannyiye kommityi mogut okazatjsya ryadom, no istoricheskaya svyaznostj ne otmenyayet bezopasnostj, zavisimosti, polnomochiya i kontekstnuyu posiljnostj.

## Rezuljtat

Selektor rabochego nabora perevedyon na skhemu `4`. Komanda `validate` strukturno proveryayet vesj nabor bez chteniya istorii. Pozdnij `show` rassmatrivayet do 16 first-parent-kommitov i toljko deduplicirovannyiye normalizovannyiye lokaljnyiye Markdown-ssyilki iz razdela `Источники` kartochki. Siljneye vsego svyazj s izmenyonnoj zavershyonnoj ili poglosjhyonnoj kartochkoj-istochnikom, zatem tochno izmenyonnyij inoj istochnik; vnutri klassa uchityivayutsya menjshaya distanciya, boljsheye chislo unikaljnyikh sovpavshikh putej i para `card_id`, `step_id`. Bez signala rezuljtat ostayotsya ustojchivyim.

Otvet `show` poluchil kanonicheskij obyyekt `selection` s identichnostjyu vsekh vliyayusjhikh vkhodov, tochnoj vershinoj, prichinoj i svideteljstvom. `claim` teperj trebuyet `--expected-selection-id`, v odnoj Git-tranzakcii proveryayet vershinu vetki i compare-and-swap claim, a zapisj skhemyi `2` khranit ploskiye `selection_id` i `selection_head`. Chteniye legacy-zapisi skhemyi `1` sokhraneno. Lokaljnaya ssyilka-istochnik teperj fail-closed proveryayetsya na susjhestvovaniye i tochnyij registr do `is_file`, poetomu rezuljtat ne zavisit ot chuvstviteljnosti fajlovoj sistemyi k registru.

Zhivoj pyatiminutnyij heartbeat obnovlyon na meste bez smenyi celevoj zadachi, statusa ili raspisaniya. Yego prompt tochno sovpadayet s versioniruyemyim shablonom. V aktivnom nabore ostalisj dva `ready`: FUM-STEP-0077 i FUM-STEP-0008. Na iskhodnoj vershine realjnyij `show` vyibral FUM-STEP-0077 s prichinoj `completed_step_source`, potomu chto poslednij kommit izmenil yego zavershyonnuyu kartochku-istochnik FUM-STEP-0076.

Politika mashinno-lokaljnyikh putej ne rasshirena: dlya izmenyonnyikh strok opredeleniya zapresjhyonnyikh form obnovlenyi toljko tochnyiye SHA-256, a dve novyiye otricateljnyiye fiksturyi razreshenyi po tochnoj stroke, pozicii i kontroljnoj summe. Puti, vidyi form, schyotchiki i bazovyiye kategorii ostalisj prezhnimi.

## Granicyi rezuljtata

Signal istorii ne yavlyayetsya obsjhim planirovsjhikom poleznosti, ne chitayet tekstyi kommitov, ne stroit embeddings i ne nakaplivayet vesa. On toljko myagko uporyadochivayet uzhe bezopasnyiye `ready` po tochnyim putyam istochnikov. Sobstvennaya kartochka, `.obsidian/`, indeksyi, planovyij reyestrovyij JSON i rabochiye naboryi isklyuchenyi iz konteksta.

Dva recent-snimka Codex i khranimyij proyekt ostayutsya netranzakcionnyimi host-vkhodami. Claim atomaren toljko v predelakh Git-ssyilok lokaljnogo klona; zapusk otdeljnoj zadachi Codex ne vkhodit v tu zhe tranzakciyu. Skhema claim `1` toljko chitayetsya dlya sovmestimosti; novyiye zapisi sozdayutsya toljko po skheme `2`.

## Proverki

TDD nachalsya s ozhidayemogo krasnogo progona: 74 testa dali 51 otkaz i odnu oshibku na prezhnej realizacii. Posle osnovnoj realizacii vse 74 testa proshli. Itogovyij audit nashyol platformenno zavisimyij fail-open dlya ssyilki s nevernyim registrom. Otdeljnyij krasnyij test vosproizvyol yego, a posle ispravleniya zelyonyij nabor vyiros do 75/75.

Realjnyiye `validate` i `show` podtverdili dva `ready`, tochnuyu vershinu i vyibor FUM-STEP-0077 po zavershyonnomu istochniku na distancii `0`. Planovyij reyestr peresobran i proveren. Shtatnyiye `update` i `view` zhivogo heartbeat podtverdili neizmennuyu registraciyu i tochnyij novyij prompt. Pervyij polnyij smoke-check proshyol 53 shaga i ostanovilsya na politike mashinno-lokaljnyikh putej: posle soderzhateljnyikh pravok ustareli uzkiye kontroljnyiye summyi dopustimyikh strok opredeleniya i otricateljnyikh testovyikh fikstur. Politika perezakreplena bez rasshireniya oblasti, yeyo otdeljnaya proverka snova proshla, a povtornyij polnyij smoke-check uspeshno zavershil vse 61 etap.

## Profilj vremeni vyipolneniya

| Stadiya                       | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                            |
| ---------------------------- | -----------: | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya FIFO             |  ne izmereno | Sobstvennyij bilet zaregistrirovan pervyim mutiruyusjhim dejstviyem; otdeljnaya wall-clock-granica ne sokhranilasj.                                           |
| Ozhidaniye FIFO                |   3 403,24 s | Po metkam ocheredi: ot registracii 14:24:13.321Z do dopuska 15:20:56.557Z; ozhidaniye otdeleno ot aktivnoj rabotyi.                                       |
| Soderzhateljnaya rabota        |  ne izmereno | Perechityivaniye posle predshestvennika, proyektirovaniye, TDD, realizaciya, dokumentaciya i tri razlichimyikh subagentskikh vklada; yedinyij tajmer ne sokhranyalsya. |
| Predfinaljnyiye proverki       |      12,97 s | Chetyire posledovateljnyikh vyizova: diff, recency, graf i svyaznostj sessii s tochnyim soobsjheniyem kommita.                                                   |
| Pryamyiye zapuski proverok      |    771,912 s | Summa vsekh strok nizhe; paralleljnyiye vyizovyi schitayutsya po wall-clock kazhdogo instrumentaljnogo vyizova.                                                  |
| Pervyij polnyij smoke-check    |     241,92 s | Neuspeshno: shagi 1–53 proshli, shag 54 obnaruzhil ustarevshiye uzkiye fiksacii politiki mashinno-lokaljnyikh putej.                                             |
| Zamyikaniye politiki putej     |      41,40 s | Chetyire posledovateljnyikh diagnosticheskikh i itogovyikh vyizova; poslednij polnyij vyizov uspeshen.                                                            |
| Povtornyij polnyij smoke-check |     231,85 s | Uspeshno: projden 61 etap; vnutrennyaya monotonnaya dliteljnostj — 231,801 s.                                                                             |

### Pryamyiye zapuski proverok

| Vyizov                                                                                    | Dliteljnostj | Rezuljtat                                                                   |
| ---------------------------------------------------------------------------------------- | -----------: | --------------------------------------------------------------------------- |
| `[history_ranking_tests]` polnyij TDD-red, 74 testa                                       |      18,86 s | neuspeshno (51 otkaz, 1 oshibka na prezhnej realizacii)                        |
| `[selector_architecture]` dubliruyusjhij polnyij red, 74 testa                               |     18,362 s | neuspeshno (51 otkaz, 1 oshibka; baseline ispolnitelya)                        |
| `[selector_architecture]` yedinichnyij test `only_ready`                                    |       0,45 s | uspeshno (1/1)                                                               |
| `[selector_architecture]` promezhutochnyij polnyij progon, poteryana svodka                   |      25,60 s | ne zaversheno (nizhnyaya granica tool wall; nablyudalisj 57 markerov i 2 otkaza) |
| `[selector_architecture]` verbose fail-fast                                              |      18,58 s | neuspeshno (31 test, 1 ustarevsheye exact-ozhidaniye dokumenta)                  |
| `[selector_architecture]` verbose-progon do nachala 58-go testa                           |      12,20 s | ne zaversheno (nizhnyaya granica tool wall; finaljnaya svodka ne sokhranilasj)    |
| `[selector_architecture]` test normalizacii tochnogo istochnika                            |       0,62 s | uspeshno (1/1)                                                               |
| `[selector_architecture]` vyiborka tryokh selection-testov                                  |       2,86 s | uspeshno (3/3)                                                               |
| `[selector_architecture]` promezhutochnyij polnyij green bez svodki                          |      25,90 s | ne zaversheno (nizhnyaya granica tool wall; nablyudalisj 57 uspeshnyikh markerov)   |
| `[selector_architecture]` polnyij progon s sokhranyonnoj svodkoj, 74 testa                  |      37,46 s | uspeshno (74/74)                                                             |
| `[contract_consistency_audit]` obsjhij poisk schema, multi-ready, selection i claim        |       0,10 s | ne zaversheno (vyivod chastichno usechyon)                                        |
| `[contract_consistency_audit]` poisk formulirovok pro yedinstvennyij `ready`               |       0,10 s | uspeshno (najdena ustarevshaya svodnaya tablica)                                |
| `[contract_consistency_audit]` obzor pokryitiya selection/history-testami                  |       0,10 s | uspeshno                                                                     |
| `[contract_consistency_audit]` sverka testovogo kontrakta `validate`                     |       0,10 s | uspeshno (najdeno smesheniye exit-kodov v navyike)                              |
| `[contract_consistency_audit]` obzor testov normalizacii istochnikov                      |       0,10 s | uspeshno                                                                     |
| `[contract_consistency_audit]` pervichnaya Python-proverka khyeshej                           |       0,10 s | neuspeshno (netochnaya normalizaciya; nakhodka otozvana)                         |
| `[contract_consistency_audit]` proverka ssyilok pervogo celevogo nabora                   |       0,30 s | uspeshno (celi susjhestvuyut i registr sovpadayet)                               |
| `[contract_consistency_audit]` pervichnyij poisk narushenij `ё`                             |       0,10 s | uspeshno (yavnyikh narushenij net)                                               |
| `[contract_consistency_audit]` poisk zhivyikh upominanij schema `3`, pervaya popyitka         |       0,10 s | neuspeshno (shell quoting)                                                   |
| `[contract_consistency_audit]` povtornyij poisk schema `3`                                |       0,10 s | uspeshno (protivorechij net)                                                  |
| `[contract_consistency_audit]` poisk ustarevshego fence, pervaya popyitka                   |       0,10 s | neuspeshno (backticks chastichno interpretirovanyi shell)                       |
| `[contract_consistency_audit]` ispravlennyij poisk ustarevshego fence                      |       0,10 s | uspeshno (najdenyi ustarevshiye zapisi reyestra)                                 |
| `[contract_consistency_audit]` tochnaya Python-proverka `content_without_recency`          |       0,10 s | uspeshno (23/23 khyesha)                                                        |
| `[contract_consistency_audit]` sverka tie-break po chislu unikaljnyikh putej                |       0,10 s | uspeshno                                                                     |
| `[contract_consistency_audit]` proverka ssyilok vsego itogovogo nabora                    |       0,20 s | uspeshno (celi susjhestvuyut i registr sovpadayet)                               |
| `[contract_consistency_audit]` sverka heartbeat `state=valid` i `ready_count`            |       0,10 s | uspeshno                                                                     |
| `[contract_consistency_audit]` finaljnyij poisk zapreta neskoljkikh `ready`                |       0,10 s | uspeshno (najdenyi svodnaya tablica i proizvodnyij reyestr)                      |
| `[contract_consistency_audit]` finaljnyij poisk tipichnyikh zamen `ё`                        |       0,10 s | uspeshno (yavnyikh novyikh narushenij net)                                         |
| `[requirements_trace]` proverka kornya i iskhodnogo Git-sostoyaniya                          |       0,00 s | uspeshno (dliteljnostj ne sokhranilasj; zapisana nizhnyaya granica)              |
| `[requirements_trace]` iskhodnyij diff desyati naznachennyikh fajlov                           |       0,00 s | uspeshno (pusto; dliteljnostj ne sokhranilasj)                                |
| `[requirements_trace]` paralleljnaya `git diff --numstat`-sverka desyati fajlov            |       0,10 s | uspeshno (vse desyatj naznachennyikh fajlov yestj v diff)                         |
| `[requirements_trace]` paralleljnyij `rg` po staroj semantike schema `3` i odnogo `ready` |       0,10 s | uspeshno (ustarevshej semantiki khraneniya net)                                 |
| `[requirements_trace]` paralleljnyij `rg` po policy, selection i novomu istochniku         |       0,10 s | uspeshno (obyazateljnyiye elementyi najdenyi)                                     |
| `[requirements_trace]` paralleljnyij diff-kontrolj neizmennoj recency                     |       0,10 s | uspeshno (recency-bloki ne zatronutyi)                                        |
| `[requirements_trace]` kontrolj obsjhej rabochej kopii                                      |       0,10 s | uspeshno (izmeneniya ogranichenyi naznachennoj oblastjyu)                         |
| `[requirements_trace]` sverka tochnoj formyi vlozhennogo `selection`                        |       0,10 s | uspeshno                                                                     |
| `[requirements_trace]` sverka CLI `--expected-selection-id`                              |       0,10 s | uspeshno                                                                     |
| `[requirements_trace]` sverka claim schema `2`                                           |       0,10 s | uspeshno                                                                     |
| `[requirements_trace]` finaljnyij poisk ustarevshikh formulirovok                           |       0,10 s | uspeshno (ostalosj toljko korrektnoye «vyibirayet ne boleye odnogo»)             |
| `[requirements_trace]` sverka ssyilki novogo zaprosa                                      |       0,10 s | uspeshno (istochnik yestj vo vsekh desyati fajlakh)                               |
| `[requirements_trace]` finaljnyij diff desyati fajlov                                      |       0,10 s | uspeshno (otklonenij net)                                                    |
| `[root]` iskhodnyiye Git-sostoyaniye, statistika diff i `git diff --check`                    |       0,20 s | uspeshno                                                                     |
| `[root]` pervyij polnyij progon posle osnovnoj realizacii, 74 testa                        |      37,50 s | uspeshno (74/74)                                                             |
| `[root]` realjnyij `branch-next-step validate`                                            |       0,51 s | uspeshno (`state=valid`, `ready_count=2`)                                    |
| `[root]` realjnyij `branch-next-step show`                                                |       0,85 s | uspeshno (FUM-STEP-0077, `completed_step_source`, distanciya 0)               |
| `[root]` regressionnyij TDD-red nevernogo registra ssyilki                                 |       0,25 s | neuspeshno (ozhidayemo vosproizvedyon fail-open)                                |
| `[root]` povtor regressionnogo testa posle ispravleniya                                   |       0,25 s | uspeshno (1/1)                                                               |
| `[root]` shtatnyiye update/view i lokaljnaya sverka heartbeat                                |       0,40 s | uspeshno (ta zhe aktivnaya pyatiminutnaya registraciya, tochnyij prompt)            |
| `[root]` polnyij progon posle fail-closed-ispravleniya, 75 testov                          |      37,65 s | uspeshno (75/75)                                                             |
| `[root]` sborka planovogo reyestra                                                        |       0,26 s | uspeshno                                                                     |
| `[root]` proverka planovogo reyestra                                                      |       0,26 s | uspeshno                                                                     |
| `[root]` poisk ustarevshikh ogranichenij `ready` posle audita                               |       0,02 s | uspeshno (ostalisj toljko korrektnyiye formulirovki vyibora odnogo pobeditelya)  |
| `[root]` generator Markdown-recency                                                      |       0,49 s | uspeshno (obnovleno 26 fajlov)                                               |
| `[root]` generator teplovoj kartyi Obsidian                                               |       0,29 s | uspeshno (teplovaya karta obnovlena)                                          |
| `[root]` povtornyij generator Markdown-recency                                            |       0,46 s | uspeshno (obnovleno 3 fajla)                                                 |
| `[root]` povtornyij generator teplovoj kartyi Obsidian                                     |       0,29 s | uspeshno (karta uzhe aktualjna)                                               |
| `[root]` `git diff --check` pered svyaznostjyu                                             |       0,04 s | uspeshno                                                                     |
| `[root]` proverka Markdown-recency pered svyaznostjyu                                      |       0,43 s | uspeshno                                                                     |
| `[root]` proverka teplovoj kartyi pered svyaznostjyu                                        |       0,27 s | uspeshno                                                                     |
| `[root]` svyaznostj sessii s tochnyim soobsjheniyem kommita                                    |      12,23 s | uspeshno                                                                     |
| `[root]` pervyij polnyij smoke-check                                                       |     241,92 s | neuspeshno (shagi 1–53 proshli; shag 54 otklonil ustarevshiye tochnyiye SHA-256)     |
| `[root]` diagnostika politiki putej s filjtrom pervogo nesootvetstviya                    |      10,38 s | uspeshno (lokalizovana ustarevshaya fiksaciya heartbeat-prompta)                |
| `[root]` polnyij audit putej posle pervoj uzkoj fiksacii                                  |      10,34 s | neuspeshno (ostalisj dve stroki navyika i dve testovyiye fiksturyi)              |
| `[root]` diagnosticheskij audit ostavshikhsya nesootvetstvij politiki putej                  |      10,34 s | uspeshno (tochno opredelenyi chetyire ostavshiyesya fiksacii)                       |
| `[root]` itogovyij polnyij audit mashinno-lokaljnyikh putej                                   |      10,34 s | uspeshno                                                                     |
| `[root]` povtornyij polnyij smoke-check                                                    |     231,85 s | uspeshno (61/61; vnutrennyaya monotonnaya dliteljnostj 231,801 s)               |

Obsjheye vremya pryamyikh zapuskov proverok: 771,912 s.

Granica profilya: ot pervogo FIFO-`join` do zaversheniya povtornogo polnogo smoke-check. Finaljnaya recency-zapisj, zamyikayusjhiye proverki, staging, commit+handoff i publikaciya tochnogo kommita sleduyut posle granicyi i v summu pryamyikh zapuskov ne vkhodyat.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [trebovaniye FUM-REQ-0016](../../Trebovaniya/✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c10004a5e6f5ad8cc6669ced9c062a023f35657624a4019f4bf4d6297c93b842 -->
<!-- FUM-MD-RECENCY:END -->
