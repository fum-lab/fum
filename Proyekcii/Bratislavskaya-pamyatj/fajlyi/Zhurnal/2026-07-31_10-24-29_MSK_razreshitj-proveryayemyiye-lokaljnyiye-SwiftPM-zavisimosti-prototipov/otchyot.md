# Otchyot 2026-07-31 10:24:29 MSK - Razreshitj proveryayemyiye lokaljnyiye SwiftPM zavisimosti prototipov

Rabochaya sessiya zavershila FUM-STEP-0107: obsjhij smoke-check teperj razreshayet toljko yavno zaregistrirovannuyu offline-kompoziciyu sosednikh verkhneurovnevyikh SwiftPM-paketov i sokhranyayet prezhnij strogij zapret dlya paketov s pustyim allowlist. Kontrakt proveren na realjnom Swift 6.4 i na dejstvuyusjhem inventare prototipov.

## Rezuljtat

`swift-package-policy.json` perevedyon na skhemu `2`. Kazhdaya zapisj paketa soderzhit obyazateljnyij `localDependencies`; razreshyonnaya pryamaya svyazj fiksiruyet kanonicheskij repo-relative-putj provajdera, fakticheskuyu package identity i tochnyiye paryi `target`/`product`. Pustoj spisok oznachayet, chto fakticheskiye package- i product-zavisimosti dolzhnyi ostavatjsya pustyimi.

Podgotovka smoke-check snachala ogranichivayet iskhodnyij `Package.swift` deklarativnoj formoj `import PackageDescription` i yedinstvennyim `let package = Package(...)` bez predvariteljnogo ispolnyayemogo koda i posleduyusjhej mutacii. `dependencies:` dolzhen byitj literaljnyim massivom tochnyikh vyizovov `.package(path: "<канонический-относительный-путь>")`. Zatem fakticheskij `dump-package` sopostavlyayetsya s politikoj: absolyutnyij `fileSystem.path` raskryivayetsya cherez `realpath`, proveryayetsya vnutri repozitoriya i `Прототипы/` i normalizuyetsya obratno v repo-relative-putj.

Kontrakt otkazyivayet do testov i sborki pri propavshej, lishnej, nezaregistrirovannoj ili izmenivshejsya package-, identity- libo product-svyazi; pri absolyutnom, vyichislyayemom ili nekanonicheskom puti; pri vyikhode cherez simvolicheskuyu ssyilku; pri self-dependency, dublikate, neodnoznachnoj identity, cikle, vneshnej `byName`-svyazi i source-control-, registry-, binary- libo neizvestnoj zavisimosti. Yedinyiye offline-flagi otklyuchayut prefetch, avtomaticheskuyu rezolyuciyu, credential-khranilisjha, obsjhij dependency-kyesh i kyesh manifesta dlya `dump-package`, `swift test` i `swift build`.

Regressiya proshla polnyij polozhiteljnyij putj na vremennoj kompozicii `alpha -> beta`: podgotovku dvukh paketov, ikh testyi, sborki ispolnyayemyikh produktov i strogij lint. Dva nezavisimyikh kriticheskikh audita nashli i pomogli zakryitj obkhodyi cherez backtick/unused-marker, tranzitivnuyu collision identity i post-initializer mutation; okonchateljnyij kontrakt zapresjhayet vse tri formyi.

Publikacionnaya proverka otdeljno zakrepila tochnyimi fingerprint-isklyucheniyami otricateljnuyu fiksturu absolyutnogo puti i dve stroki opredeleniya zapreta domashnego sokrasjheniya v validatore. Kazhdoye isklyucheniye dejstvuyet toljko dlya odnoj stroki i ne rasshiryayet razresheniya rabochego koda ili sosednikh testovyikh dannyikh.

Zaklyuchiteljnyij obsjhij smoke-check proshyol vse 62 shaga za 333,965 sekundyi vnutrennego monotonnogo vremeni. V proverennyij kontur voshli testyi lokaljnyikh avtomatizacij, offline test/build/lint vsekh devyati SwiftPM-paketov, reyestryi, publikacionnaya chistota, recency, graf i svyaznostj rabochej sessii.

Rabochij nabor udalil vyipolnennoye pokoleniye FUM-STEP-0107 i sokhranil ostaljnyiye linii. FUM-STEP-0108 dobavlena svezhim pokoleniyem kak `paused`, potomu chto prezhneye poljzovateljskoye razresheniye zhivogo model-only-provajdera byilo ogranicheno FUM-STEP-0102 i ne dayot polnomochiya novomu shagu. Gotovyikh k avtozapusku kartochek posle peredachi net.

## Proiskhozhdeniye vkladov

- `smoke_design` sproyektiroval skhemu allowlist, proveril sopostavleniye i provyol dva kriticheskikh read-only-audita obkhodov deklarativnogo parser.
- `swift_shapes` zafiksiroval realjnyiye formyi `dump-package` Swift 6.4, vyipolnil nezavisimuyu vremennuyu kompoziciyu i proveril oflajn-komandyi i simvolicheskuyu ssyilku.
- `session_planning` proveril zhiznennyij cikl kartochki, rabochij nabor i granicu polnomochij sleduyusjhego shaga.
- Kornevoj ispolnitelj provyol TDD, integriroval realizaciyu i dokumentaciyu, zakryil najdennyiye obkhodyi, oformil sessiyu, planovuyu peredachu i polnyij proverochnyij kontur.

## Profilj vremeni vyipolneniya

| Stadiya                                  | Dliteljnostj   | Granicyi i sposob izmereniya                                                                      |
| --------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------- |
| FIFO i kontekstnyij preflight            | meneye 2 min    | `join` srazu vernul `admitted`; zatem polnostjyu prochitanyi pravila, navyiki i obyazateljnyiye vkhodyi. |
| TDD, realizaciya i kriticheskiye audityi    | okolo 70 min   | Ot krasnoj skhemyi `1` do zakryitiya leksicheskikh, grafovyikh i identity-obkhodov.                      |
| Dokumentaciya i planovaya peredacha        | okolo 25 min   | Politika, navyik, kartochka, zapros, zhurnal i rabochij nabor vetki.                                |
| Pryamyiye proverki do granicyi profilya      | 32 min 0,994 s | Summa vsekh perechislennyikh zapuskov; paralleljnyiye proverki schitayutsya otdeljno.                    |
| Zakryivayusjhiye proverki, FIFO i publikaciya | vne profilya    | Vyipolnyayutsya posle fiksacii rezuljtata bez rekursivnogo rasshireniya tablicyi.                      |

Granica profilya: zakanchivayetsya uspeshnyim zaklyuchiteljnyim polnyim smoke-check, kotoryij vklyuchyon v tablicu pryamyikh zapuskov. Posleduyusjheye vneseniye samogo rezuljtata v zhurnal neizbezhno trebuyet zamyikayusjhikh recency-, graph-, coherence- i diff-proverok; oni, atomarnyij queue `commit` i yedinstvennyij post-handoff `publish` vyipolnyayutsya posle granicyi i ne dobavlyayutsya v profilj rekursivno.

### Pryamyiye zapuski proverok

| Vyizov                                                                | Dliteljnostj | Rezuljtat                                                               |
| -------------------------------------------------------------------- | ------------ | ----------------------------------------------------------------------- |
| iskhodnyij unittest avtomatizacii smoke-check                          | 0,60 s       | uspeshno — 38 testov                                                     |
| TDD-red dopustimoj lokaljnoj SwiftPM-kompozicii                      | 0,20 s       | neuspeshno — ozhidayemo otklonena skhema policy `2` staryim parser skhemyi `1` |
| Swift 6.4 version i dump-package chistogo modeljnogo shaga             | 2,50 s       | uspeshno — zafiksirovana iskhodnaya forma manifest JSON                    |
| spravka `swift test` i `swift build` po offline-flagam               | 0,30 s       | uspeshno                                                                 |
| otdeljnaya spravka po `--disable-prefetching`                         | 0,20 s       | uspeshno                                                                 |
| spravka `swift package` po offline-flagam                            | 0,20 s       | uspeshno                                                                 |
| dump-package vremennoj dvukhpaketnoj diagnostiki                      | 0,70 s       | uspeshno — poluchena fakticheskaya forma `fileSystem` i product-svyazi       |
| audit dump-package paketa avtomatizacii                              | 1,00 s       | uspeshno                                                                 |
| audit dump-package chistogo modeljnogo shaga                           | 0,90 s       | uspeshno                                                                 |
| `swiftc -frontend -dump-parse` dejstvuyusjhego Package.swift            | 1,40 s       | uspeshno                                                                 |
| audit spravki Swift offline-flagov                                   | 0,40 s       | uspeshno                                                                 |
| nezavisimyiye version i polnyij dump-package Swift 6.4                  | 1,40 s       | uspeshno                                                                 |
| odin wrapper devyati tochnyikh dump-package dejstvuyusjhego inventarya       | 8,60 s       | uspeshno                                                                 |
| lokaljnyij dump-package LinguisticKit                                 | 3,80 s       | uspeshno                                                                 |
| read-only `git ls-remote` publichnyikh refs SwiftPM                     | 1,50 s       | uspeshno — issledovateljskaya setevaya sverka, ne runtime-zavisimostj      |
| paralleljnyij planovyij baseline validate/show/registry                | 0,70 s       | uspeshno                                                                 |
| povtornyij validate rabochego nabora do izmenenij                      | 0,62 s       | uspeshno                                                                 |
| povtornyij show rabochego nabora do izmenenij                          | 0,65 s       | uspeshno                                                                 |
| povtornaya proverka planovogo reyestra do izmenenij                    | 0,31 s       | uspeshno                                                                 |
| vyichisleniye ozhidayemogo khyesha kartochki FUM-STEP-0108                    | 0,10 s       | uspeshno                                                                 |
| pervyij polnyij test_run_smoke_check posle migracii                    | 2,62 s       | neuspeshno — 3 otkaza i 1 oshibka ustarevshikh fikstur                      |
| povtornyij test_run_smoke_check posle fikstur                         | 2,12 s       | neuspeshno — ostalosj staroye ozhidaniye teksta oshibki                      |
| test_run_smoke_check s pervyimi pogranichnyimi testami                  | 2,65 s       | uspeshno — 30 testov                                                     |
| pervyij ispolnyayemyij test lokaljnoj kompozicii                         | 6,18 s       | neuspeshno — u vremennyikh paketov ne byilo test target                     |
| povtor lokaljnoj kompozicii s polnoj diagnostikoj                    | 8,91 s       | neuspeshno — podtverzhdeno otsutstviye testov                              |
| lokaljnaya kompoziciya posle dobavleniya testov                         | 18,28 s      | neuspeshno — strict lint nashyol trailing comma                            |
| povtor lokaljnoj kompozicii posle pervoj lint-pravki                 | 14,52 s      | neuspeshno — ostavalasj odna trailing comma                              |
| lokaljnaya kompoziciya: test/build/lint oboikh paketov                  | 23,18 s      | uspeshno — shestj shagov                                                   |
| test_run_smoke_check posle privyazki parser k Package initializer     | 22,60 s      | neuspeshno — odna legacy-fikstura ne soderzhala Package declaration       |
| celevoj test rezhima `--list` posle ispravleniya fiksturyi              | 0,12 s       | uspeshno                                                                 |
| smoke-check `--list` na devyati dejstvuyusjhikh paketakh                   | 12,27 s      | uspeshno — podgotovka i offline-komandyi vsego inventarya                  |
| audit dump-package s novyim naborom offline-flagov                    | 3,80 s       | uspeshno                                                                 |
| realjnyij backtick/unused-marker vosproizvoditelj do ispravleniya      | 0,80 s       | neuspeshno — absolyutnyij putj oshibochno prinyat                             |
| in-memory tranzitivnaya identity collision do ispravleniya             | 0,10 s       | neuspeshno — konflikt oshibochno prinyat                                    |
| paralleljnyij unittest audita na promezhutochnoj fiksture               | 17,255 s     | neuspeshno — audit popal v nezavershyonnuyu trailing-comma pravku           |
| nezavisimoye build_swift_steps realjnoj kompozicii                    | 2,291 s      | uspeshno — sformirovano 6 shagov                                          |
| nezavisimyij `swift test` potrebitelya alpha                           | 7,300 s      | uspeshno — 1 test                                                        |
| nezavisimyij `swift build` produkta AlphaCLI                          | 2,578 s      | uspeshno                                                                 |
| nezavisimyij `swift test` provajdera beta                             | 8,672 s      | uspeshno — 1 test                                                        |
| nezavisimyij `swift build` produkta BetaCLI                           | 2,135 s      | uspeshno                                                                 |
| realjnyij vyichislyayemyij putj vo vremennom manifest                      | 0,905 s      | uspeshno — otklonyon do test/build                                        |
| syiroj dump-package puti cherez vnutrennyuyu simvolicheskuyu ssyilku        | 3,650 s      | uspeshno — Swift vernul leksicheskij symlink path                         |
| kontraktnaya proverka simvolicheskoj ssyilki                            | 0,651 s      | uspeshno — putj otklonyon kak nekanonicheskij                              |
| povtor backtick/unused-marker posle ispravleniya                      | 1,015 s      | uspeshno — obkhod otklonyon                                                |
| povtor tranzitivnoj identity collision posle ispravleniya             | 0,10 s       | uspeshno — collision otklonena                                           |
| povtornyij polnyij unittest kriticheskogo audita                        | 19,457 s     | uspeshno — 30 testov                                                     |
| realjnyij post-initializer mutation do ispravleniya                    | 0,836 s      | neuspeshno — absolyutnaya final dependency oshibochno prinyata                |
| pervyij celevoj manifest-source unittest posle zapreta mutacii        | 0,13 s       | neuspeshno — dva testovyikh regex ozhidali prezhnij sloj otkaza              |
| vtoroj celevoj manifest-source unittest                              | 0,13 s       | neuspeshno — dva ozhidaniya byili perestavlenyi neverno                      |
| tretij celevoj manifest-source unittest                              | 0,13 s       | uspeshno                                                                 |
| pervaya popyitka specializirovannogo zaversheniya kartochki               | 0,27 s       | neuspeshno — zhivaya ssyilka vetochnogo nabora yesjhyo ukazyivala na active-putj  |
| povtornoye specializirovannoye zaversheniye kartochki                     | 0,36 s       | uspeshno — status, imya, ssyilki i indeksyi sinkhronizirovanyi                |
| pervyij branch-next-step validate posle zaversheniya                    | 0,38 s       | neuspeshno — zhurnal-istochnik kartochki yesjhyo ne susjhestvoval                 |
| pervyij branch-next-step show posle zaversheniya                        | 0,44 s       | neuspeshno — ta zhe otsutstvuyusjhaya ssyilka zhurnala                          |
| zaklyuchiteljnyij branch-next-step validate                             | 0,62 s       | uspeshno — 24 kandidata, 0 ready, 22 paused, 2 blocked                   |
| zaklyuchiteljnyij branch-next-step show                                 | 0,61 s       | uspeshno — ozhidayemyij `not_ready`, kod 3                                  |
| polnyij unittest avtomatizacii smoke-check posle vsekh pravok          | 22,93 s      | uspeshno — 44 testa                                                      |
| pobajtovoye sravneniye dispatcher prompt v zaprose i soobsjhenii kommita | 0,00 s       | uspeshno                                                                 |
| finaljnyiye realjnyiye mutation i custom-Package vosproizvoditeli        | 4,225 s      | uspeshno — oba obkhoda otklonenyi                                          |
| finaljnyij test_run_smoke_check kriticheskogo audita                   | 24,284 s     | uspeshno — 30 testov                                                     |
| promezhutochnyij `git diff --check`                                     | 0,10 s       | uspeshno                                                                 |
| povtornoye vyichisleniye khyesha FUM-STEP-0108 posle rename                 | 0,10 s       | uspeshno — sovpalo s vetochnyim pokoleniyem                                 |
| sborka planovogo reyestra posle zaversheniya kartochki                   | 0,25 s       | uspeshno                                                                 |
| proverka planovogo reyestra posle zaversheniya kartochki                 | 0,33 s       | uspeshno                                                                 |
| pervoye obnovleniye Markdown-recency                                   | 0,50 s       | neuspeshno — obnaruzhena nezavershyonnaya zapisj pending                     |
| povtornoye obnovleniye Markdown-recency                                | 0,48 s       | uspeshno                                                                 |
| obnovleniye teplovoj kartyi grafa                                      | 0,28 s       | uspeshno                                                                 |
| proverka Markdown-recency                                            | 0,44 s       | uspeshno                                                                 |
| proverka svezhesti grafa                                              | 0,28 s       | uspeshno                                                                 |
| pervaya proverka svyaznosti rabochej sessii                             | 12,82 s      | neuspeshno — ispravlenyi zagolovki i navigaciya                            |
| obnovleniye recency posle ispravleniya zagolovkov                      | 0,47 s       | uspeshno                                                                 |
| obnovleniye grafa posle ispravleniya zagolovkov                        | 0,27 s       | uspeshno                                                                 |
| povtornaya proverka svyaznosti rabochej sessii                          | 12,95 s      | uspeshno                                                                 |
| pervyij polnyij smoke-check rabochego sostoyaniya                         | 235,87 s     | neuspeshno — ustarevshij snapshot sleduyusjhego shaga                         |
| celevoj snapshot-test rabochego nabora                                | 1,28 s       | uspeshno                                                                 |
| zaklyuchiteljnoye obnovleniye recency pered polnyim progonom              | 0,47 s       | uspeshno                                                                 |
| zaklyuchiteljnoye obnovleniye grafa pered polnyim progonom                | 0,27 s       | uspeshno                                                                 |
| zaklyuchiteljnaya proverka svyaznosti pered polnyim progonom              | 13,07 s      | uspeshno                                                                 |
| vtoroj polnyij smoke-check rabochego sostoyaniya                         | 331,69 s     | neuspeshno — netipizirovannaya absolyutnaya testovaya fikstura               |
| proverka mashinno-lokaljnyikh putej posle tochnogo isklyucheniya            | 10,47 s      | uspeshno                                                                 |
| obnovleniye recency pered tretjim polnyim progonom                     | 0,49 s       | uspeshno                                                                 |
| obnovleniye grafa pered tretjim polnyim progonom                       | 0,30 s       | uspeshno                                                                 |
| tretij polnyij smoke-check rabochego sostoyaniya                         | 325,44 s     | neuspeshno — dva netipizirovannyikh opredeleniya validatora                 |
| diagnosticheskaya proverka novyikh mashinno-lokaljnyikh kategorij           | 10,60 s      | neuspeshno — lokalizovanyi dva opredeleniya validatora                     |
| proverka putej posle tipizacii opredelenij validatora                | 10,65 s      | uspeshno                                                                 |
| chetvyortyij polnyij smoke-check rabochego sostoyaniya                      | 338,29 s     | neuspeshno — sluzhebnyij prefiks summyi zhurnala                             |
| obnovleniye recency pered zaklyuchiteljnyim smoke-check                  | 0,46 s       | uspeshno                                                                 |
| obnovleniye grafa pered zaklyuchiteljnyim smoke-check                    | 0,26 s       | uspeshno                                                                 |
| proverka svyaznosti pered zaklyuchiteljnyim smoke-check                  | 12,51 s      | uspeshno                                                                 |
| zaklyuchiteljnyij polnyij smoke-check                                    | 334,02 s     | uspeshno — 62 iz 62 shagov                                                |

Obsjheye vremya pryamyikh zapuskov proverok: 1920,994 s.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov.
- Codex Desktop, vstroyennyij Codex runtime i modelj na osnove GPT-5 — host, ispolneniye kornevoj sessii i read-only-auditov; tochnyiye sborki otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch`, `update_plan` i `collaboration.*` — processyi, pravki, plan i koordinaciya razlichimyikh vkladov.
- [obsjhij smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — skhema, realizaciya, testyi, dokumentaciya i polnyij progon.
- [proverka mashinno-lokaljnyikh putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md) — tochnaya tipizaciya otricateljnoj fiksturyi bez shirokogo isklyucheniya.
- [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md) i [sleduyusjhij shag vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md) — FIFO, fenced-podtverzhdeniye, rabochij nabor, atomarnaya peredacha i publikaciya.
- [moskovskoye vremya rabochej sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [reyestr planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [svezhestj Markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [svezhestj grafa Obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md) i [svyaznostj rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) — vremya, kartochka, reyestryi, recency, graf i svyaznostj.
- Python 3, Swift 6.4, Git, Zsh i ripgrep — lokaljnaya realizaciya i diagnostika. Odin issledovateljskij `git ls-remote` subagenta prochital publichnyiye refs SwiftPM; proizvodstvennyij i proverochnyij kontrakt FUM seti ne ispoljzuyet.
- Tri read-only-subagenta — razlichimyiye skhemnyij, SwiftPM-runtime i sessionno-planovyij vkladyi bez zapisi v checkout.

## Zatronutyiye fajlyi

- [kontrakt obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [ispolnitelj obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py)
- [politika SwiftPM-paketov](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json)
- [regressionnyiye testyi smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/tests/test_run_smoke_check.py)
- [politika mashinno-lokaljnyikh putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/policy.json)
- [snapshot-test rabochego nabora vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [zavershyonnaya kartochka FUM-STEP-0107](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0107-razreshitj-proveryayemyiye-lokaljnyiye-SwiftPM-zavisimosti-prototipov.md)
- [sleduyusjhaya kartochka FUM-STEP-0108](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0108-zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [iskhodnyij zapros sessii](zapros.md)
- [indeks zhurnala rabot](../README.md)
- [indeks Markdown po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [teplovaya karta grafa Obsidian](../../../../../.obsidian/graph.json)
- [opornaya data teplovoj kartyi](../../.obsidian/fum-recency-reference-date)

## Istochniki

- [iskhodnyij dispetcherskij zapros](zapros.md)
- [zavershyonnaya kartochka FUM-STEP-0107](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0107-razreshitj-proveryayemyiye-lokaljnyiye-SwiftPM-zavisimosti-prototipov.md)
- [kontrakt obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c652bc102cff2acdf33e94921365640eea8ecc7f5cd0ee522d8ae5338628f37e -->
<!-- FUM-MD-RECENCY:END -->
