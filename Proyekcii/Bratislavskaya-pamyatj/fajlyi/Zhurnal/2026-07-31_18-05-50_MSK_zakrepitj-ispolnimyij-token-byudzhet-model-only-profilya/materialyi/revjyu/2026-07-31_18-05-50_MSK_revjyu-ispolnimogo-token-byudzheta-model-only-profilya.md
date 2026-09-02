# Revjyu ispolnimogo token-byudzheta model-only-profilya

Vse pyatj materialjnyikh nakhodok ustranenyi; nezakryityikh P1/P2-zamechanij ne vyiyavleno.

## Granica revjyu

- Iskhodnyij zapros: [Zaprosyi/2026-07-31_18-05-50_MSK_zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya.md](../../zapros.md)
- Avtomatizaciya: [Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md](../../../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md)
- Konfiguraciya: [Revjyu/Avtomatizacii/2026-07-31_18-05-50_MSK_revjyu-ispolnimogo-token-byudzheta-model-only-profilya.json](2026-07-31_18-05-50_MSK_revjyu-ispolnimogo-token-byudzheta-model-only-profilya.json)
- Revjyuyer: Codex
- Vremya revjyu: 2026-07-31 18:05:50 MSK
- Baza: `ab83268d9c717c5e24fd6731f89a9e9b3cb29dc7`
- Golova: `HEAD`
- Diapazon Git: `ab83268d9c717c5e24fd6731f89a9e9b3cb29dc7..HEAD`
- Oblastj: Proveren rabochij diff FUM-STEP-0108: versionnyij byudzhetnyij profilj, atomarnyij process-memory ledger, tochnaya lokaljnaya attestaciya tokenizer/provider/runtime, zakryityij REST v0-transport, avtonomnyiye i opt-in live-proverki, dokumentaciya, zaversheniye kartochki i sleduyusjhij whitelist master. Vneshnyaya setj, zagruzka vesov, novyiye sekretyi, platnyij dostup, poljzovateljskiye dannyiye i publikaciya ne vkhodili v oblastj.

## Snimok Git

Kommityi v diapazone:

- Net kommitov v vyibrannom diapazone.

Izmenyonnyiye fajlyi:

Izmenyonnyiye fajlyi v vyibrannom diapazone ne najdenyi.

Statistika diff:

```text

```

Avtomaticheskij signal `git diff --check`: proshyol. Problem whitespace ne obnaruzheno.

Tekusjheye sostoyaniye rabochego dereva pri sborke otchyota:

```text
M  .obsidian/graph.json
M  README.md
M  Документация/41-контракт-чистого-модельного-шага.md
M  Журнал/2026-07-31_10-24-29_MSK_разрешить-проверяемые-локальные-SwiftPM-зависимости-прототипов.md
AM Журнал/2026-07-31_18-05-50_MSK_закрепить-исполнимый-токен-бюджет-model-only-профиля.md
M  Журнал/README.md
M  Запросы/2026-07-30_11-42-13_MSK_декомпозировать-реализацию-сквозного-одноагентного-эпизода.md
M  Запросы/2026-07-31_10-24-29_MSK_разрешить-проверяемые-локальные-SwiftPM-зависимости-прототипов.md
M  Запросы/2026-07-31_16-31-18_MSK_отключить-автоматическую-публикацию-master.md
AM Запросы/2026-07-31_18-05-50_MSK_закрепить-исполнимый-токен-бюджет-model-only-профиля.md
M  Индексы/markdown-файлы-по-времени-редактирования.md
M  Инструменты/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py
M  Инструменты/реестр-системных-приложений-и-инструментов.md
M  Планирование/карточки-шагов/README.md
A  Планирование/карточки-шагов/✅-FUM-STEP-0108-закрепить-исполнимый-токен-бюджет-model-only-профиля.md
D  Планирование/карточки-шагов/🟡-FUM-STEP-0108-закрепить-исполнимый-токен-бюджет-model-only-профиля.md
M  Планирование/карточки-шагов/✅-FUM-STEP-0109-ввести-схему-событий-живого-одноагентного-эпизода.md
M  Планирование/карточки-шагов/🧩-FUM-STEP-0103-реализовать-сквозной-одноагентный-эпизод-с-возобновлением.md
M  Планирование/реестр-требований-вариантов-и-кандидатов.json
M  Планирование/следующие-шаги-веток/master.md
M  Прототипы/README.md
M  Прототипы/чистый-модельный-шаг/README.md
A  Прототипы/чистый-модельный-шаг/Sources/FUMPureModelStep/LMStudioRESTV0BudgetTransport.swift
A  Прототипы/чистый-модельный-шаг/Sources/FUMPureModelStep/ModelOnlyBudget.swift
A  Прототипы/чистый-модельный-шаг/Tests/FUMPureModelStepTests/BudgetedModelOnlyAdapterTests.swift
M  Прототипы/чистый-модельный-шаг/Tests/FUMPureModelStepTests/LMStudioModelOnlyAdapterTests.swift
A  Прототипы/чистый-модельный-шаг/Tests/FUMPureModelStepTests/LMStudioRESTV0BudgetTransportTests.swift
M  Ревью/2026-07-31_16-31-18_MSK_ревью-ручной-публикации-master.md
A  Ревью/2026-07-31_18-05-50_MSK_ревью-исполнимого-токен-бюджета-model-only-профиля.md
M  Ревью/README.md
AM Ревью/Автоматизации/2026-07-31_18-05-50_MSK_ревью-исполнимого-токен-бюджета-model-only-профиля.json
```

## Chto proveryalosj

- nezavisimaya fiksaciya identity, disclosure i vsekh shesti izmerenij ceiling/reservation
- atomarnaya affordability-proverka, idempotentnyij replay i konservativnyiye terminaljnyiye iskhodyi bez povtornogo raskhoda
- ispolnimyij provider max_tokens, tochnaya tokenizer-attestaciya i otdeleniye trusted usage ot modeljnogo teksta
- fail-closed-granicyi public API, loopback HTTP, redirect, ambient state, absolyutnyij deadline i predel tela
- strogiye prehash-predelyi vsekh khyeshiruyemyikh vkhodov i otsutstviye neogranichennoj rabotyi do otkaza
- avtonomnoye pokryitiye oshibok i odin razreshyonnyij zhivoj lokaljnyij progon bez ostatochnogo sostoyaniya LM Studio
- soglasovannostj dokumentacii, zavershyonnoj kartochki i yedinstvennogo sleduyusjhego ready-pokoleniya FUM-STEP-0109

## Nakhodki

| Prioritet | Status | Fajl | Stroka | Zagolovok |
| --- | --- | --- | --- | --- |
| P1 | ustraneno do zaversheniya revjyu | `Прототипы/чистый-модельный-шаг/Sources/FUMPureModelStep/ModelOnlyBudget.swift` | 1320 | Prehash-putj dopuskal neogranichennuyu obrabotku vkhoda i metadannyikh |
| P1 | ustraneno do zaversheniya revjyu | `Прототипы/чистый-модельный-шаг/Sources/FUMPureModelStep/ModelOnlyBudget.swift` | 492 | Syiraya transport-poverkhnostj pozvolyala obojti byudzhetnyij adapter |
| P1 | ustraneno do zaversheniya revjyu | `Прототипы/чистый-модельный-шаг/Sources/FUMPureModelStep/LMStudioRESTV0BudgetTransport.swift` | 37 | HTTP-kliyent nasledoval ambient-sostoyaniye i ne zamyikal absolyutnyiye granicyi otveta |
| P1 | ustraneno do zaversheniya revjyu | `Прототипы/чистый-модельный-шаг/Sources/FUMPureModelStep/ModelOnlyBudget.swift` | 726 | Replay i odinakovyiye invocation_id ne byili obsjhej atomarnoj granicej |
| P2 | ustraneno do zaversheniya revjyu | `Документация/41-контракт-чистого-модельного-шага.md` | 108 | Dokumentaciya smeshivala CLI v1, REST v2 i granicu sokhraneniya digest |

### P1: Prehash-putj dopuskal neogranichennuyu obrabotku vkhoda i metadannyikh

Pervonachaljnyij variant mog polnostjyu kodirovatj ili khyeshirovatj slishkom dlinnyiye profile identity, purpose, invocation_id i input do tipizirovannogo otkaza, poetomu deklarativnyij disclosure-predel ne byil absolyutnoj vyichisliteljnoj granicej.

Rekomendaciya: Proveryatj tochnyiye absolyutnyiye UTF-8-predelyi do JSON/SHA, obryivatj exact-input na pervom lishnem bajte i vozvrasjhatj otkaz bez request_sha256, reservation i terminal ledger entry.

### P1: Syiraya transport-poverkhnostj pozvolyala obojti byudzhetnyij adapter

Promezhutochnyiye protocol-tipyi i vnedryayemyiye initializer mogli byi datj vneshnemu kliyentu pryamoj provider/HTTP-vyizov bez profile validation, reservation i settlement.

Rekomendaciya: Ostavitj publichnyimi toljko vstroyennuyu tochnuyu attestaciyu, konkretnyij REST transport i byudzhetnyij adapter, a pryamyiye generate, provider- i HTTP-kontraktyi sdelatj package-internal.

### P1: HTTP-kliyent nasledoval ambient-sostoyaniye i ne zamyikal absolyutnyiye granicyi otveta

Pervonachaljnyij transport ne dokazyival zapret redirect, cookie, credentials, cache i proxy, ne sveryal konechnyij URL i ne ogranichival obsjhij deadline i razmer tela nezavisimo ot skorosti potoka.

Rekomendaciya: Sozdavatj izolirovannuyu ephemeral-sessiyu na vyizov, zapresjhatj redirect, povtorno sveryatj loopback URL, ogranichivatj yedinyij resource timeout i prekrasjhatj chteniye posle absolyutnogo limita bajtov.

### P1: Replay i odinakovyiye invocation_id ne byili obsjhej atomarnoj granicej

Pervonachaljnaya lokaljnaya proverka adapter ne isklyuchala gonku dvukh ekzemplyarov na odnom ledger i ne garantirovala yedinyij terminal replay posle neopredelyonnogo provider-iskhoda.

Rekomendaciya: Linearizovatj lookup, affordability i reservation vnutri odnogo actor-ledger, khranitj active i terminal zapisi po request hash i zakryivatj konflikt odinakovogo invocation_id tipizirovannyim otkazom.

### P2: Dokumentaciya smeshivala CLI v1, REST v2 i granicu sokhraneniya digest

Promezhutochnyiye formulirovki pripisyivali v1-probe byudzhetnuyu REST-semantiku, nazyivali publichnyij invocation vnutrennim i obesjhali digest shire uspeshno soglasovannogo terminal completed-iskhoda.

Rekomendaciya: Razvesti dva profilya, tochno nazvatj public/package-internal poverkhnosti i sokhranyatj response body SHA toljko posle uspeshnoj sverki provider usage i identity.

## Proverki

| Proverka | Komanda | Rezuljtat | Detali |
| --- | --- | --- | --- |
| Formatirovaniye i strogij Swift lint | `swift format lint --strict --recursive Sources Tests` | proshlo | Itogovyiye Swift-fajlyi sootvetstvuyut centraljnomu strogomu stilyu bez isklyuchenij. |
| Polnyij avtonomnyij SwiftPM-nabor | `swift test` | proshlo: 71 test, odin opt-in live-test shtatno propusjhen | Proverenyi profilj, disclosure, affordability, reservation, settlement, replay, concurrency, REST-granicyi, perepolneniye, malformed, timeout, partial i konservativnyiye terminal outcomes. |
| Sborka ispolnyayemogo produkta | `swift build --product FUMModelStepProbe` | proshlo | Sovmestimyij determinirovannyij CLI-profilj versii 1 prodolzhayet sobiratjsya otdeljno ot REST-profilya versii 2. |
| Opt-in live LM Studio REST v0 | `FUM_RUN_LM_STUDIO_LIVE_TESTS=1 swift test --filter LMStudioRESTV0BudgetTransportTests/live` | proshlo: odin lokaljnyij test | Podtverzhdenyi qwen/qwen3-0.6b, runtime llama.cpp-mac-arm64-apple-metal-advsimd 2.27.1, max_tokens=1, prompt_tokens=14 i completion_tokens=1; zatem server ostanovlen i spisok zagruzhennyikh modelej pust. |
| Validaciya rabochego nabora | `python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py validate --repo-root . --json` | proshlo: candidate_count=26, ready_count=1, paused_count=24, blocked_count=1 | Vyipolnennoye pokoleniye FUM-STEP-0108 udaleno; show determinirovanno vyibirayet FUM-STEP-0109 s reason=only_ready. |
| Polnyij smoke-check repozitoriya | `python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py --request Запросы/2026-07-31_18-05-50_MSK_закрепить-исполнимый-токен-бюджет-model-only-профиля.md --commit-message-file <временный-файл> --codex-thread-id <корневой-сеанс>` | proshlo: 62 etapa za 356,217 s | Posle ispravleniya ustarevshej fixture sleduyusjhego shaga i tryokh lozhnyikh path-literalov proshli vse avtomatizacii, SwiftPM-paketyi, sborki, lint, reyestryi, lokaljnyiye puti, recency, graf i sessionnaya svyaznostj. |
| Publikacionnaya chistota diff | `git diff --check` | proshlo | Probeljnyiye oshibki v tekusjhem rabochem diff ne obnaruzhenyi. |

## Ostatochnyiye riski

- Ledger imeyet zayavlennuyu durability process_memory i ne perezhivayet padeniye processa; crash-durable vosstanovleniye ostayotsya otdeljnyim shagom.
- Ispolnima rovno odna zakreplyonnaya exact-tokenizer-fikstura; universaljnaya sovmestimostj tokenizer s proizvoljnyimi vkhodami ili modelyami ne zayavlena.
- Fakticheskiye model i runtime identity stanovyatsya doverennyim svideteljstvom toljko posle otveta provider; ikh nesovpadeniye zavershayetsya konservativnyim otkazom.
- Remote transport i nenulevaya tarifikaciya ne realizovanyi: takiye profili serializuyutsya, no ispolneniye zakryivayetsya otkazom.

## Sokhraneniye rezuljtata

Otchyot postroyen lokaljnoj avtomatizaciyej `fum-revjyu-prodelannoj-rabotyi` iz sokhranyonnoj konfiguracii, tekusjhego Git-sreza i smyislovogo revjyu agenta. Skript avtomatiziruyet sbor nablyudayemogo konteksta, strukturu otchyota i proverku obyazateljnyikh razdelov, no ne podmenyayet soderzhateljnuyu otvetstvennostj revjyuyera za vyivodyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:66816f0b0ace1acf54148ee834ac95aa3b70f9d20d8e7d345c69777b3940b0b1 -->
<!-- FUM-MD-RECENCY:END -->
