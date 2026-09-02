# Otchyot 2026-07-31 18:05:50 MSK - Zakrepitj ispolnimyij token byudzhet model only profilya

Rabochaya sessiya zamenila neispolnyayemoye znacheniye `max_output_tokens = unknown` otdeljnyim byudzhetnyim LM Studio REST v0-profilem, ne menyaya smyisl sovmestimogo CLI-kontura versii `1`.

## Rezuljtat

Profilj versii `2` nezavisimo zakreplyayet rezhim, provider/interface/endpoint, model/runtime/tokenizer identity, disclosure i shestimernyiye ceiling/reservation. Do JSON/SHA absolyutnyiye UTF-8-predelyi ogranichivayut profile identity, disclosure-spiski, `invocation_id`, purpose i input; rannij otkaz ne sozdayot reservation ili terminal ledger entry i vozvrasjhayet `request_sha256 = nil`. Actor-ledger atomarno proveryayet affordability, sokhranyayet reservation do inference, soglasuyet doverennyiye token counters i lokaljno izmerennoye vremya, a dlya neodnoznachnyikh provider-iskhodov uderzhivayet konservativnyij raskhod bez avtomaticheskogo povtora. Dolgovechnostj yavno ogranichena zhiznjyu process; mezhprocessnoye vosstanovleniye ne zayavleno.

Lokaljnyij REST v0-transport dopuskayet toljko tochnyij loopback endpoint, peredayot `max_tokens` iz profilya i otdelyayet model/runtime/usage ot nedoverennogo teksta. Izolirovannaya ephemeral-sessiya ne nasleduyet cookie, credentials, cache ili proxy, ne sleduyet redirect, povtorno sveryayet konechnyij URL i ogranichivayet absolyutnyiye deadline i razmer tela. SHA-256 tela sokhranyayetsya toljko dlya uspeshno soglasovannoj completed-popyitki; post-provider-otkazyi imeyut otdeljnyiye tipizirovannyiye iskhodyi bez digest.

Avtonomnyiye fiksturyi proveryayut byudzhet, konkurentnostj odinakovogo `invocation_id`, terminal outcomes, replay i HTTP-granicyi bez modeli. Povtornyiye opt-in-vyizovyi uzhe sokhranyonnoj modeli podtverdili tochnyiye `qwen/qwen3-0.6b`, runtime `llama.cpp-mac-arm64-apple-metal-advsimd 2.27.1`, `max_tokens = 1`, `prompt_tokens = 14` i `completion_tokens = 1`. Posle finaljnoj proverki server LM Studio ostanovlen, spisok zagruzhennyikh modelej pust.

Kartochka FUM-STEP-0108 zavershena i udalena iz vetochnogo whitelist. Vse ostaljnyiye korrektnyiye kandidatyi sokhranenyi: rabochij nabor soderzhit `26` kartochek, iz kotoryikh yedinstvennoj vyichislennoj `ready` yavlyayetsya FUM-STEP-0109, `24` ostayutsya `paused`, odna — `blocked`.

## Profilj vremeni vyipolneniya

| Stadiya                            | Dliteljnostj  | Granicyi i sposob izmereniya                                                                                              |
| --------------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Registraciya i FIFO                | meneye 1 s     | `join` srazu vernul `admitted`; fenced `show` podtverdil tochnoye naznacheniye.                                             |
| Kontekst i proyektirovaniye         | okolo 25 min  | Obyazateljnyiye vkhodyi, lokaljnyiye navyiki, capability-probyi i tri razlichimyikh read-only subagentskikh vklada.                 |
| TDD, realizaciya i usileniye granic | okolo 2 ch     | Krasno-zelyonyiye ciklyi profile/ledger/transport, povtornyiye audityi, avtonomnyiye i opt-in live-proverki.                     |
| Dokumentaciya, plan i revjyu        | okolo 1 ch     | Kartochka, whitelist, dokumentaciya, pasporta, zapros, zhurnal, reyestryi i sokhranyonnoye revjyu.                               |
| Polnyij smoke-check                | 356,217 s     | Yedinyij itogovyij zapusk proshyol `62` etapa; znacheniye vzyato iz tochnogo `smoke-timing total`.                              |
| Peredacha                          | vne profilya   | Lokaljnyij atomarnyij commit+handoff bez avtomaticheskogo push ili publish.                                                |

### Pryamyiye zapuski proverok

| Vyizov                                                        | Dliteljnostj | Rezuljtat                                                                                                     |
| ------------------------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------- |
| fenced `branch-next-step show`                               | 0,60 s       | uspeshno — naznacheniye FUM-STEP-0108 podtverzhdeno                                                               |
| capability-proba Native API v1                               | 12,59 s      | uspeshno — najden ispolnimyij `max_output_tokens` i structured stats, no bez runtime identity                   |
| capability-proba REST API v0                                 | 0,09 s       | uspeshno — podtverzhdenyi `max_tokens`, usage, model, runtime i `finish_reason = length`                          |
| otricateljnaya proba `max_tokens = 0`                         | 0,02 s       | neuspeshno ozhidayemo — provider otklonil nepodderzhivayemoye znacheniye do inference                                  |
| TDD-red budget adapter                                       | 3,15 s       | neuspeshno ozhidayemo — otsutstvovali profile, ledger i transport-kontraktyi                                       |
| pervyij TDD-green budget adapter                              | 5,00 s       | uspeshno — `12` testov                                                                                         |
| TDD-red REST v0 transport                                    | 1,89 s       | neuspeshno ozhidayemo — otsutstvovali HTTP- i REST v0-tipyi                                                        |
| TDD-green REST v0 transport                                  | 3,90 s       | uspeshno — `4` testa                                                                                           |
| pervyij polnyij SwiftPM test                                   | 4,46 s       | uspeshno — `37` testov, odin live-test shtatno propusjhen                                                         |
| pervyij opt-in live LM Studio REST v0                         | 4,72 s       | uspeshno — tochnyiye model/runtime, `max_tokens = 1`, `finish_reason = length` i provider usage                    |
| pervoye vosstanovleniye sostoyaniya LM Studio                    | 0,90 s       | uspeshno — modelj vyigruzhena, server ostanovlen, spisok zagruzhennyikh modelej pust                                 |
| budget suite posle usileniya replay/preflight                 | 4,66 s       | uspeshno — `16` testov                                                                                         |
| smena statusa kartochki FUM-STEP-0108                          | 0,50 s       | uspeshno — specializirovannyij perenos obnovil status, indeks i ssyilki                                           |
| pervyij selector posle zaversheniya kartochki                    | 0,54 s       | neuspeshno ozhidayemo — najden izmenivshijsya khyesh FUM-STEP-0109                                                     |
| pervoye formatirovaniye Swift                                  | 0,23 s       | neuspeshno ozhidayemo — obnaruzhenyi yesjhyo ne otformatirovannyiye novyiye fajlyi                                           |
| pervyij strogij Swift lint                                    | 0,24 s       | uspeshno — format posle ispravleniya prinyat                                                                     |
| polnyij SwiftPM test posle replay-usileniya                     | 4,67 s       | uspeshno — vesj tekusjhij nabor testov                                                                            |
| sborka `FUMModelStepProbe` posle replay-usileniya              | 1,47 s       | uspeshno — ispolnyayemyij produkt sobran                                                                           |
| promezhutochnaya validaciya rabochego nabora                      | 0,55 s       | uspeshno — vetochnyij whitelist strukturno soglasovan                                                            |
| promezhutochnyij `branch-next-step show`                         | 0,57 s       | uspeshno — yedinstvennyim ready opredelyon FUM-STEP-0109                                                          |
| sverka tochnogo prompt/tokenizer-vektora                       | 0,10 s       | uspeshno — bajtyi, SHA-256 i `14` input tokens sovpali                                                           |
| promezhutochnyij `git diff --check`                              | 0,04 s       | uspeshno — probeljnyikh oshibok ne obnaruzheno                                                                      |
| sborka posle zakryitiya SHA API                                | 2,92 s       | neuspeshno ozhidayemo — test yesjhyo obrasjhalsya k stavshemu private SHA-helper                                          |
| povtornaya sborka posle perenosa testovogo SHA                 | 2,75 s       | uspeshno — zakryitaya API-granica sobirayetsya                                                                      |
| polnyij SwiftPM test posle zakryitiya SHA API                    | 3,70 s       | uspeshno — vesj tekusjhij nabor testov                                                                            |
| budget suite posle obsjhej ledger-granicyi                       | 4,12 s       | uspeshno — replay i odinakovyiye `invocation_id` prokhodyat                                                        |
| polnyij SwiftPM test posle obsjhej ledger-granicyi                | 5,66 s       | uspeshno — vesj tekusjhij nabor testov                                                                            |
| povtornyij opt-in live LM Studio REST v0                       | 2,79 s       | uspeshno — identity, limit i structured usage podtverzhdenyi                                                     |
| polnyij SwiftPM test posle HTTP-usileniya                       | 6,18 s       | uspeshno — vesj tekusjhij nabor testov                                                                            |
| transport suite posle dobavleniya HTTP-granic                  | 6,00 s       | neuspeshno ozhidayemo — pervaya novaya fikstura vyiyavila nezamknutyij sluchaj                                          |
| povtornyij transport suite                                    | 4,00 s       | neuspeshno ozhidayemo — ostavalasj odna regressiya absolute deadline                                              |
| polnyij SwiftPM test posle ispravleniya transport               | 8,36 s       | uspeshno — HTTP-granicyi i vesj paket proshli                                                                     |
| sborka probe posle ispravleniya transport                      | 1,16 s       | uspeshno — ispolnyayemyij produkt sobran                                                                           |
| formatirovaniye posle HTTP-usileniya                            | 0,33 s       | uspeshno — Swift-iskhodniki pereformatirovanyi                                                                    |
| strogij lint posle HTTP-usileniya                              | 0,30 s       | neuspeshno ozhidayemo — obnaruzheno odno nesoglasovannoye imya                                                       |
| diagnosticheskij status i strogij lint                         | 0,25 s       | uspeshno — ispravlennoye imya prinyato                                                                             |
| povtornoye formatirovaniye                                     | 0,32 s       | uspeshno — format prinyat                                                                                        |
| povtornyij strogij lint                                       | 0,30 s       | uspeshno — strogij lint proshyol                                                                                  |
| polnyij SwiftPM test posle HTTP-audita                         | 6,22 s       | uspeshno — vesj tekusjhij nabor testov                                                                            |
| sborka probe posle HTTP-audita                               | 1,26 s       | uspeshno — ispolnyayemyij produkt sobran                                                                           |
| tretij opt-in live LM Studio REST v0                          | 3,01 s       | uspeshno — tochnyiye identity, limit i usage podtverzhdenyi                                                         |
| tretjye vosstanovleniye sostoyaniya LM Studio                     | 0,21 s       | uspeshno — server ostanovlen, spisok modelej pust                                                               |
| format/lint/budget suite posle ogranicheniya input              | 6,63 s       | uspeshno — rannij bounded-input-otkaz proshyol                                                                    |
| lint posle suzheniya public API                                 | 0,54 s       | neuspeshno ozhidayemo — dva test-only initializer trebovali yavnogo access                                        |
| format/lint i dve suite posle bounded metadata/API            | 8,51 s       | uspeshno — absolyutnyiye predelyi i package-internal vnedreniye proshli                                              |
| formatirovaniye posle access-audita                            | 0,41 s       | uspeshno — Swift-iskhodniki pereformatirovanyi                                                                    |
| lint posle access-audita                                     | 0,36 s       | neuspeshno ozhidayemo — clock-initializer treboval yavnogo access                                                 |
| itogovoye formatirovaniye Swift                                | 0,38 s       | uspeshno — itogovyiye Swift-fajlyi otformatirovanyi                                                                 |
| itogovyij strogij Swift lint                                  | 0,37 s       | uspeshno — isklyuchenij i narushenij net                                                                           |
| itogovyij polnyij SwiftPM test                                 | 7,89 s       | uspeshno — `71` test, odin opt-in live-test shtatno propusjhen                                                    |
| itogovaya sborka `FUMModelStepProbe`                           | 1,32 s       | uspeshno — ispolnyayemyij produkt sobran                                                                           |
| itogovyij opt-in live LM Studio REST v0                        | 3,40 s       | uspeshno — model/runtime, `max_tokens = 1`, `14` input i `1` output token podtverzhdenyi                          |
| itogovoye vosstanovleniye sostoyaniya LM Studio                  | 0,27 s       | uspeshno — server ostanovlen, `lms ps --json` vernul pustoj massiv                                              |
| validaciya konechnogo whitelist                                | 0,62 s       | uspeshno — `26` kandidatov, odin ready, `24` paused i odin blocked                                             |
| sborka sokhranyonnogo revjyu                                    | 0,17 s       | uspeshno — Markdown-otchyot materializovan iz mashinnoj konfiguracii                                             |
| sborka planovogo reyestra                                     | 0,29 s       | uspeshno — mashinnyij reyestr peresobran po tekusjhim kartochkam i trebovaniyam                                       |
| validaciya planovogo reyestra                                  | 0,30 s       | uspeshno — peresobrannyij reyestr soglasovan                                                                     |
| obnovleniye Markdown recency                                  | 0,58 s       | uspeshno — obnovlyon `21` soderzhateljno izmenyonnyij Markdown-fajl                                                |
| peresborka teplovoj kartyi Obsidian                            | 0,31 s       | uspeshno — graf otrazhayet svezhij recency-srez                                                                   |
| povtornaya validaciya konechnogo whitelist                      | 0,62 s       | uspeshno — podtverzhdenyi `26/1/24/1`                                                                            |
| finaljnyij `branch-next-step show` do smoke-check              | 0,64 s       | uspeshno — vyibran FUM-STEP-0109, `reason = only_ready`, zavisimosti vyipolnenyi                                  |
| polnaya validaciya sokhranyonnogo revjyu                          | 0,06 s       | uspeshno — obyazateljnyiye razdelyi zapolnenyi, nezavershyonnyikh markerov net                                          |
| pervaya polnaya proverka sessionnoj svyaznosti                  | 15,42 s      | neuspeshno — obnaruzhenyi tri nesoglasovannyikh zagolovka navigacii i sessionnyikh fajlov                             |
| povtornaya polnaya proverka sessionnoj svyaznosti               | 15,37 s      | uspeshno — zagolovki, navigaciya, provenance i fakticheskij Git-inventarj soglasovanyi                             |
| pervyij polnyij smoke-check                                    | 238,764 s    | neuspeshno — etap 18 obnaruzhil ustarevshij baseline `27/1/25/1` i FUM-STEP-0108 v repozitornoj fiksture          |
| celevaya repozitornaya fikstura sleduyusjhego shaga                | 1,41 s       | uspeshno — novyij baseline `26/1/24/1` i FUM-STEP-0109 prinyat                                                   |
| vtoroj polnyij smoke-check                                    | 339,118 s    | neuspeshno — etap 55 raspoznal tri normativnyikh HTTP path-literala kak mashinno-lokaljnyiye fajlovyiye puti           |
| formatirovaniye posle ustraneniya path-lozhnopolozhenij           | 0,10 s       | uspeshno — dva Swift-fajla otformatirovanyi                                                                      |
| strogij lint posle ustraneniya path-lozhnopolozhenij             | 0,36 s       | uspeshno — celevoj paket sootvetstvuyet centraljnoj konfiguracii                                                |
| transport suite posle ustraneniya path-lozhnopolozhenij          | 4,94 s       | uspeshno — `13` REST v0-testov proshli                                                                           |
| celevaya proverka mashinno-lokaljnyikh putej                      | 12,17 s      | uspeshno — normativnyiye URL/path-komponentyi boljshe ne klassificiruyutsya kak fajlovyiye puti                         |
| tretij itogovyij polnyij smoke-check                           | 356,217 s    | uspeshno — proshli vse `62` etapa, vklyuchaya SwiftPM, lint, reyestryi, recency, graf i sessionnuyu svyaznostj          |
| itogovaya peresborka sokhranyonnogo revjyu                       | 0,16 s       | uspeshno — v otchyot dobavlen proshedshij polnyij smoke-check                                                       |
| itogovaya validaciya sokhranyonnogo revjyu                        | 0,06 s       | uspeshno — otchyot soglasovan s mashinnoj konfiguraciyej                                                           |
| post-smoke-validaciya konechnogo whitelist                     | 0,61 s       | uspeshno — sokhranenyi tochnyiye `26/1/24/1`                                                                        |
| post-smoke `branch-next-step show`                            | 0,62 s       | uspeshno — FUM-STEP-0109 ostayotsya yedinstvennoj ready-kartochkoj                                                 |
| post-smoke-validaciya sokhranyonnogo revjyu                      | 0,06 s       | uspeshno — konfiguraciya i otchyot soglasovanyi                                                                    |
| post-smoke-proverka Markdown recency                         | 0,49 s       | uspeshno — recency-metki aktualjnyi                                                                             |
| post-smoke-proverka grafa Obsidian                           | 0,29 s       | uspeshno — teplovaya karta aktualjna                                                                            |
| post-smoke `git diff --cached --check`                        | 0,02 s       | uspeshno — probeljnyikh oshibok v staged-sreze net                                                                |
| post-smoke-proverka sessionnoj svyaznosti                     | 14,89 s      | uspeshno — provenance, zhurnal, soobsjheniye i staged Git-inventarj soglasovanyi                                   |

Obsjheye vremya pryamyikh zapuskov proverok: 1145,469 s.

Granica profilya: ot nemedlennogo FIFO-dopuska do zaversheniya itogovogo polnogo smoke-check. Stadijnyiye dliteljnosti ne skladyivayutsya s call-time pryamyikh zapuskov, a paralleljnyiye subagentskiye intervalyi ne summiruyutsya mezhdu soboj. Vlozhennyiye stadii polnogo smoke-check ne pribavlyayutsya k yego vneshnemu vremeni. Posle smoke-check recency, graf, svyaznostj i `git diff --check` povtorno zamyikayut izmenivshijsya otchyot; staging i atomarnyij lokaljnyij commit+handoff vyipolnyayutsya posle nikh bez avtomaticheskogo push.

## Granicyi

Byudzhetnyij ledger ne yavlyayetsya crash-durable: `process_memory` oznachayet toljko atomarnostj i idempotentnostj vnutri konkretnogo actor/process. Ispolnima rovno odna exact-tokenizer-fikstura dlya zaraneye zakreplyonnogo prompt; proizvoljnyiye vkhodyi, remote transport i nenulevaya tarifikaciya zakryivayutsya otkazom. Fakticheskiye model/runtime identity podtverzhdayutsya toljko strukturirovannyim provider-otvetom. Profilj ne razreshayet vneshnyuyu setj, novyiye modeli, sekretyi, platnyij dostup, poljzovateljskiye dannyiye, instrumentyi modeli ili ispolneniye yeyo teksta. Sovmestimyij CLI-profilj sokhranyayetsya, no ne vyidayotsya za obladatelya ispolnimogo token limit.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [vyipolnennaya kartochka FUM-STEP-0108](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0108-zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya.md)
- [kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md)
- [Swift-prototip chistogo modeljnogo shaga](../../Prototipyi/chistyij-modeljnyij-shag/README.md)
- [sokhranyonnoye revjyu ispolnimogo byudzheta](materialyi/revjyu/2026-07-31_18-05-50_MSK_revjyu-ispolnimogo-token-byudzheta-model-only-profilya.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1dcc346144f5a6d5e0a1e5d2461fc79b4af33fc1c811e26198ea6485404091ea -->
<!-- FUM-MD-RECENCY:END -->
