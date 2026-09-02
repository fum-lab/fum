# Audit absolyutnyikh putej v repozitorii FUM

Obnaruzhenyi odin P1, tri P2 i odin P3; repozitorij ne svoboden ot mashinno-zavisimyikh absolyutnyikh putej, khotya produktovaya dokumentaciya i first-party iskhodnyiye literalyi v osnovnom chistyi.

## Granica revjyu

- Iskhodnyij zapros: [Zaprosyi/2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej.md](../../zapros.md)
- Avtomatizaciya: [Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md](../../../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md)
- Konfiguraciya: [Revjyu/Avtomatizacii/2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.json](2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.json)
- Revjyuyer: Codex
- Vremya revjyu: 2026-07-22 12:35:05 MSK
- Baza: `44b9ea1a978f1cddf7b9ce3e019aefc6a6a57e2d`
- Golova: `44b9ea1a978f1cddf7b9ce3e019aefc6a6a57e2d`
- Diapazon Git: `44b9ea1a978f1cddf7b9ce3e019aefc6a6a57e2d..44b9ea1a978f1cddf7b9ce3e019aefc6a6a57e2d`
- Oblastj: Proveren kanonicheskij otslezhivayemyij snimok kornevogo repozitoriya, first-party tekst i kod, zakreplyonnyij Git-submodule, Git-puti i otdeljno ignoriruyemyiye sborochnyiye katalogi. Istoricheskiye zaprosyi, vneshniye arkhivyi, sistemnyiye runtime-puti, testovyiye fiksturyi i web-root marshrutyi klassificirovalisj otdeljno ot dejstvuyusjhikh defektov.

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
M Журнал/README.md
 M Запросы/2026-07-22_11-48-49_MSK_оформить-карточки-шагов-описательными-именами-и-эмодзи-статусами.md
 M Планирование/карточки-шагов/README.md
 M Планирование/предложения-о-следующих-шагах.md
 M Ревью/README.md
?? Журнал/2026-07-22_12-35-05_MSK_провести-аудит-абсолютных-путей.md
?? Запросы/2026-07-22_12-35-05_MSK_провести-аудит-абсолютных-путей.md
?? Планирование/карточки-шагов/🟡-FUM-STEP-0070-устранить-машинно-локальные-абсолютные-пути-и-добавить-их-автоматическую-проверку.md
?? Ревью/2026-07-22_12-35-05_MSK_аудит-абсолютных-путей.md
?? Ревью/Автоматизации/2026-07-22_12-35-05_MSK_аудит-абсолютных-путей.json
```

## Chto proveryalosj

- bukvaljnyiye POSIX, Windows, UNC, file URI, home-expansion i absolyutnyiye plejskholderyi
- vstraivayemyiye kompilyatorom puti i perenosimostj sobrannyikh artefaktov
- dejstvuyusjhiye kontraktyi navyikov, generatorov, Markdown-svyaznosti, sleduyusjhego shaga vetki i obsjhego smoke-check
- granica mezhdu defektom, doslovnyim proiskhozhdeniyem, sistemnyim runtime-putyom, testovoj fiksturoj i URL

## Kolichestvennyij srez

- Kornevoj Git-snimok soderzhit 1063 otslezhivayemyikh puti; 974 iz nikh proverenyi kak tekstovyiye i konfiguracionnyiye artefaktyi. Otdeljnyij kodovyij srez okhvatil 108 first-party iskhodnikov, konfiguracij i fikstur.
- Tochnyij `/Users/fum` vstrechayetsya 47 raz v 17 otslezhivayemyikh fajlakh: 42 vkhozhdeniya v 15 istoricheskikh zaprosakh i pyatj v dvukh dejstvuyusjhikh fajlakh. Tochnyij korenj checkout obrazuyet 43 vkhozhdeniya v 14 fajlakh.
- V `Запросы/` klassificirovano 149 nastoyasjhikh absolyutnyikh putej v 62 fajlakh: 42 `/Users/...`, 54 `/Applications/...`, 25 `/opt/...`, 13 `/usr/...`, 12 `/bin/...` i tri `/tmp...`. Ikh doslovnyiye bloki proiskhozhdeniya ne ispravlyayutsya zadnim chislom.
- V dejstvuyusjhej tekstovoj chasti vne `Запросы/` i `Источники/` vruchnuyu razobranyi 62 syiryikh path-like kandidata v 23 fajlakh: pyatj defektnyikh mashinno-zavisimyikh putej, 43 dopustimyikh sistemnyikh, protokoljnyikh ili istoricheskikh sluchaya, semj dopustimyikh libo neodnoznachnyikh shablonov i semj lozhnyikh sovpadenij.
- 47 strok s Windows drive i 20 UNC-strok nakhodyatsya toljko vo vneshnikh arkhivirovannyikh istochnikakh; dva `file://localhost/private/...` — testovyiye fiksturyi arkhivatora.
- V 97 proverennyikh iskhodnyikh i konfiguracionnyikh fajlakh zakreplyonnogo submodule net otslezhivayemyikh mashinno-lokaljnyikh literalov. Yego polnyij Git-snimok soderzhit 101 fajl.
- V tryokh first-party `.build` korenj checkout prisutstvuyet v 2476 fajlakh, a v `.build` submodule — yesjhyo v 671; eti produktyi ne otslezhivayutsya Git.

## Granica dopustimyikh sluchayev

- `/bin/sh`, `#!/usr/bin/env python3`, `/usr/bin/...`, standartnyiye macOS-puti Ollama i snimok sistemnyikh instrumentov yavlyayutsya ispolnimyimi sistemnyimi putyami, a ne poljzovateljskim hardcode.
- `/repo`, `/tmp`, `/bin/cat`, `/usr/bin/printf`, `/usr/bin/false` i `file://localhost/private/...` ispoljzuyutsya toljko kak testovyiye fiksturyi libo dlya proverki otkaza.
- Vedusjhij `/` v `.gitignore:10` zakreplyayet shablon u kornya repozitoriya i ne yavlyayetsya absolyutnyim putyom fajlovoj sistemyi. `/hooks` — komanda interfejsa Codex, a web-root marshrutyi arkhivirovannyikh stranic — URL.
- Absolyutnyij `<КОРЕНЬ_КЛОНА>` vneshnego heartbeat yavlyayetsya dokumentirovannyim isklyucheniyem toljko dlya vyibora lokaljnogo proyekta i rabochego kataloga; tekusjhij dochernij prompt yego ne soderzhit.
- V `Документация/`, `Глоссарий/`, `Планирование/`, `Описания/`, `Оценки/`, `Требования/`, `Вопросы/`, `Вопросы и ответы/`, `Проекты/` i `Индексы/` ne najdeno absolyutnyikh putej, `file://`, Windows drive/UNC, home-expansion ili absolyutnyikh root-plejskholderov.

## Nakhodki

| Prioritet | Status | Fajl | Stroka | Zagolovok |
| --- | --- | --- | --- | --- |
| P1 | podtverzhdeno | `Инструменты/fum-glossarij/SKILL.md` | 16 | Lokaljnyij navyik glossariya zhyostko privyazan k odnomu checkout |
| P2 | podtverzhdeno | `Инструменты/реестр-системных-приложений-и-инструментов.md` | 24 | Reyestr publikuyet dva poljzovateljskikh mashinnyikh puti |
| P2 | podtverzhdeno | `Прототипы/физические-состояния-клавиш/Sources/FUMInputMac/RepositoryLocation.swift` | 3 | Swift-prototip vstraivayet putj mashinyi cherez #filePath |
| P2 | podtverzhdeno kak probel kontrolya | `Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py` | 654 | Obsjhij proverochnyij kontur ne obespechivayet fail-closed-kontrolj putej |
| P3 | podtverzhdeno kak neodnoznachnyij primer | `Инструменты/fum-sborka-svodnoj-dokumentacii/SKILL.md` | 64 | Primer absolyutnogo config path protivorechit otnositeljnomu kontraktu |

### P1: Lokaljnyij navyik glossariya zhyostko privyazan k odnomu checkout

Stroki 16, 17 i 22 napravlyayut chteniye i rabochij katalog v /Users/fum/Projects/FUM. V drugom klone navyik mozhet obratitjsya k nesusjhestvuyusjhemu libo chuzhomu checkout vmesto tekusjhego repozitoriya.

Rekomendaciya: Ispoljzovatj puti otnositeljno kornya tekusjhego Git checkout i ne khranitj poljzovateljskij domashnij katalog v ispolnyayemoj instrukcii navyika.

### P2: Reyestr publikuyet dva poljzovateljskikh mashinnyikh puti

Stroka 24 soderzhit /Users/fum/Projects/FUM, a stroka 75 — /Users/fum/.lmstudio/bin/lms. Poslednyaya stroka odnovremenno zayavlyayet, chto konkretnyiye mashinnyiye puti ne publikuyutsya.

Rekomendaciya: Opisyivatj checkout otnositeljno kornya, a poljzovateljskij CLI — cherez komandu obnaruzheniya, PATH ili obezlichennoye home-expansion bez publikacii imeni poljzovatelya.

### P2: Swift-prototip vstraivayet putj mashinyi cherez #filePath

Stroki 3 i 35–41 sokhranyayut polnyij putj iskhodnika, a CaptureViewModel.swift:55–59 ispoljzuyet yego pri zapuske. Tekusjhij ignoriruyemyij Debug-binarnik realjno soderzhit /Users/fum/Projects/FUM i posle perenosa zakryivayet zapisj, yesli prezhnij checkout ischez.

Rekomendaciya: Peredavatj perenosimuyu runtime-konfiguraciyu ili opredelyatj razreshyonnyij katalog otnositeljno prilozheniya; dobavitj test perenosa sobrannogo artefakta i proverku otsutstviya build-root v publikuyemom binarnike.

### P2: Obsjhij proverochnyij kontur ne obespechivayet fail-closed-kontrolj putej

Smoke-check ne skaniruyet soderzhimoye; Markdown-svyaznostj propuskayet susjhestvuyusjhuyu absolyutnuyu ssyilku vne repozitoriya; generatoryi prinimayut i mestami pechatayut absolyutnyiye path-polya; branch-next-step.py proveryayet project_path, no ne title, task i criteria. Tekusjhiye kartochki i JSON-konfiguracii bezopasnyi, poetomu eto latentnaya, a ne tekusjhaya utechka.

Rekomendaciya: Dobavitj samostoyateljnyij tipizirovannyij skaner v smoke-check i otdeljnyiye otricateljnyiye testyi dlya Markdown, generatorov i vsekh dinamicheskikh polej dochernego prompta.

### P3: Primer absolyutnogo config path protivorechit otnositeljnomu kontraktu

Stroki 64 i 74 ispoljzuyut /path/to/config.json srazu posle trebovaniya zadavatj puti otnositeljno kornya. Drugiye navyiki takzhe soderzhat yavnyiye /putj/k/... plejskholderyi; eto ne utechka, no oslozhnyayet odnoznachnuyu mashinnuyu politiku.

Rekomendaciya: Ispoljzovatj repozitorno-otnositeljnyij primer libo yavno markirovatj poljzovateljskij vneshnij putj kak razreshyonnoye isklyucheniye.

## Proverki

| Proverka | Komanda | Rezuljtat | Detali |
| --- | --- | --- | --- |
| Inventarj otslezhivayemogo dereva | `git ls-files` | proshlo, 1063 puti | Snimok vklyuchayet odin gitlink; otslezhivayemyikh simvolicheskikh ssyilok net, puti .gitmodules otnositeljnyi. |
| Personaljnyij korenj poljzovatelya | `git grep -n -I -F '/Users/fum' -- .` | 47 vkhozhdenij v 17 fajlakh | 42 vkhozhdeniya nakhodyatsya v 15 istoricheskikh zaprosakh, pyatj — v dvukh dejstvuyusjhikh fajlakh. |
| Kod i konfiguracii | `rg -n '#filePath' Прототипы Инструменты Зависимости` | 108 first-party fajlov proverenyi | Personaljnyikh hardcode-literalov v ispolnyayemyikh iskhodnikakh i tekusjhikh JSON path-polyakh net; #filePath podtverzhdyon kak vstraivayemyij putj. |
| Zakreplyonnyij submodule | `git -C Зависимости/LinguisticKit grep -n -I -F '/Users/' -- .` | sovpadenij mashinno-lokaljnyikh literalov net | Proveren pinned commit 837e2ce107b97ee7b9d3344c9fe99142281fe393; dev-tool ispoljzuyet #filePath, a yego binarnik nakhoditsya toljko v ignoriruyemom .build. |
| Ignoriruyemyiye sborochnyiye produktyi | `rg -a --hidden --no-ignore -l -F '/Users/fum/Projects/FUM' -g '**/.build/**' .` | 2476 first-party i 671 submodule-fajl | Absolyutnyiye build-root ozhidayemyi v lokaljnyikh SwiftPM/Xcode-artefaktakh; .gitignore isklyuchayet .build. |

## Ostatochnyiye riski

- Soderzhateljnaya klassifikaciya poka ruchnaya; bez otdeljnogo skanera novyij putj mozhet projti obsjhij smoke-check.
- Istoricheskiye zaprosyi i vneshniye arkhivyi namerenno sokhranyayut absolyutnyiye primeryi proiskhozhdeniya i trebuyut kontekstnoj, a ne globaljnoj filjtracii.
- Ignoriruyemyiye sborochnyiye katalogi soderzhat tyisyachi mashinnyikh putej i ostayutsya bezopasnyimi toljko poka ne publikuyutsya prinuditeljno.
- Sam otchyot citiruyet obnaruzhennyiye puti kak dokazateljstvo, poetomu posleduyusjhiye syiryiye schyotchiki dolzhnyi isklyuchatj libo tipizirovatj auditorskiye artefaktyi.

## Sokhraneniye rezuljtata

Otchyot postroyen lokaljnoj avtomatizaciyej `fum-revjyu-prodelannoj-rabotyi` iz sokhranyonnoj konfiguracii, tekusjhego Git-sreza i smyislovogo revjyu agenta. Skript avtomatiziruyet sbor nablyudayemogo konteksta, strukturu otchyota i proverku obyazateljnyikh razdelov, no ne podmenyayet soderzhateljnuyu otvetstvennostj revjyuyera za vyivodyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:824bd6bd0e98f6d26a67fc7ff0bb5a38b2fb6b5bf963c880fb330d53ad604336 -->
<!-- FUM-MD-RECENCY:END -->
