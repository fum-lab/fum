# Iskhodnyij zapros 2026-07-28 08:47:18 MSK - Zakrepitj yazyikonejtraljnyij kanonicheskij protokol pamyati

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-28 07:49:45 MSK - Dobavitj avarijnuyu soglasovannostj khranilisjha pamyati](../2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- Sleduyusjhij zapros: [2026-07-28 10:56:30 MSK - Napolnitj poljzovateljskiye istorii FUM](../2026-07-28_10-56-30_MSK_napolnitj-poljzovateljskiye-istorii-FUM/zapros.md)

## Tekst zaprosa

```text
<codex_delegation>
  <source_thread_id>019f8070-6efb-77c1-b3c3-7be5439b851e</source_thread_id>
  <input>Автозапуск назначил карточку FUM-STEP-0101 — Закрепить языконейтральный канонический протокол памяти; ожидаю допуск FIFO.

Точные входы: branch_ref=refs/heads/master; step_id=master-fum-step-0101-ready-v2; status=ready; record_path=Планирование/следующие-шаги-веток/master.md; card_id=FUM-STEP-0101; card_path=Планирование/карточки-шагов/🟡-FUM-STEP-0101-закрепить-языконейтральный-канонический-протокол-памяти.md; card_content_sha256=sha256:4affbc4290cd4b572bf77e89b9bc0549d62b7b679b0ebb9bf3f120f2f2cc5f19; project_path=README.md; title=Закрепить языконейтральный канонический протокол памяти; task=Определить версионный языконейтральный байтовый профиль канонических событий и поколений памяти, создать граничные golden vectors и подтвердить их не менее чем двумя реализациями. Swift остаётся основным runtime; вторая узкая реализация проверяет переносимость протокола, а не заменяет продуктовый стек.
Критерии: (1) профиль задаёт UTF-8, порядок ключей, числа, строки, Unicode, экранирование, пробелы, переводы строк и запрет значений; (2) стандарт/профиль обоснован первичными техническими источниками и совместим с доменом памяти; (3) golden vectors покрывают обычные/граничные события, поколения, хэши и отказы; (4) Swift и узкая независимая реализация дают побайтовое совпадение и одинаково отклоняют неканонические входы; (5) хэши/идентификаторы вычисляются только из байтов профиля без скрытых Foundation-зависимостей; (6) автономные тесты, сборка, конкурентность и форматирование проходят без сети/секретов.
selection: id=sha256:a7a8a868fff239e4ac4bc8162d2f495874147605fec40e1a6c64e5ad4f5a5ebf; policy=source-history-first-parent-v1; head=93cf00d5fd471fe22005dce68c3e6a69476104c4; ready_count=2; reason=completed_step_source; commit=93cf00d5fd471fe22005dce68c3e6a69476104c4; distance=0; matched_paths=Планирование/карточки-шагов/✅-FUM-STEP-0100-добавить-аварийную-согласованность-хранилища-памяти.md

Сначала полностью прочитай AGENTS.md, Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md, Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md и переданные record_path, card_path, project_path. Первым инструментальным действием зарегистрируй корневой CODEX_THREAD_ID через FIFO join; до admitted только жди без изменений и промежуточных сообщений. После допуска до записей выполни fenced show с ожидаемыми branch_ref, step_id, selection_id. После успеха ровно выведи: «В работу взята карточка FUM-STEP-0101 — Закрепить языконейтральный канонический протокол памяти.»; при mismatch выведи сообщение о неподтверждённом назначении, не оставляй владельца и выполни finish-clean. Сохрани этот диспетчерский prompt как исходный материал. Выполни preflight, учти обязательные накладные расходы, тесты, recency, smoke-check, атомарный commit+handoff и точный publish new_head; не освобождай успешно созданный claim.</input>
</codex_delegation>
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019fa73a-9e78-79e3-aa08-3f118b646e62

## Rezuljtat

Zakreplyon profilj `fum.memory.canonical-json.v1` — prikladnoye podmnozhestvo JCS i I-JSON s yedinstvennyimi UTF-8-bajtami, ASCII-poryadkom polej, bezopasnyimi celyimi, tochnyimi pravilami Unicode i ekranirovaniya, glubinoj do `128`, otsutstviyem probelov i konechnogo perevoda stroki i yavnyimi zapresjhyonnyimi znacheniyami. Pokoleniye perevedeno na skhemu `3`, a `CURRENT` — na skhemu `2`; oba nositelya soderzhat identifikator profilya, a prezhniye skhemyi otklonyayutsya bez molchalivoj migracii.

Swift-runtime poluchil sobstvennyiye parser i writer bez Foundation-serializacii kanonicheskikh bajtov. `input_sha256` i ostaljnyiye identifikatoryi vyichislyayutsya neposredstvenno iz bajtov profilya; tipizirovannaya granica obyazana pobajtovo vernutj tot zhe rezuljtat. Obsjhij corpus soderzhit 52 proverki: obyichnyiye i granichnyiye sobyitiya, nachaljnoye i prodolzhennoye pokoleniya, `CURRENT`, izvestnyiye SHA-256, Unicode, chisla, glubinu i klassyi otkazov. Swift i uzkij nezavisimyij Python-verifier chitayut odin manifest i sovpadayut po polnomu naboru `id`, verdict, bytes i SHA-256.

Kartochka FUM-STEP-0101 zavershena. V rabochem nabore sokhranena nezavisimaya FUM-STEP-0008, a FUM-STEP-0102 ostayotsya `paused` do poyavleniya zakonno nastroyennogo modeljnogo provajdera.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex desktop app i agentskij runtime — versii ne raskryivayutsya sredoj; ispoljzovanyi dlya kornevoj sessii i koordinacii razlichimyikh rolej normativnogo audita, audita Swift-kontura i proyektirovaniya golden vectors.
- Instrumentyi ispolneniya, patchej, veb-dostupa i mnogoagentnoj koordinacii Codex — versii ne raskryivayutsya sredoj; ispoljzovanyi dlya chteniya, tochechnyikh pravok, lokaljnyikh processov, proverki pervichnyikh tekhnicheskikh istochnikov i nezavisimyikh auditov.
- `fum-ocheredj-zadach-git-vetki` — versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md); ispoljzovan dlya FIFO-dopuska, atomarnogo commit+handoff i tochnoj publikacii.
- `fum-sleduyusjhij-shag-vetki` — versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md); ispoljzovan dlya fenced-proverki naznacheniya i obnovleniya rabochego nabora vetki.
- `fum-moskovskoye-vremya-rabochej-sessii` — versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md); ispoljzovan dlya yedinoj vremennoj metki zaprosa i zhurnala.
- `fum-reyestr-planirovaniya` — versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); ispoljzovan dlya zaversheniya kartochki, kaskada zhivyikh ssyilok i peresborki mashinnogo reyestra.
- `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej lokaljnyikh navyikov; ispoljzuyutsya dlya sluzhebnyikh indeksov, grafa, svyaznosti i polnogo smoke-check.
- Swift, SwiftPM, XCTest, Swift Format, CryptoKit, `zsh`, `git`, `ripgrep`, `jq` i `python3` — versii proveryayutsya lokaljnyim reyestrom; ispoljzovanyi dlya realizacii, avtonomnogo conformance, testov, sborki, formatirovaniya, poiska i generatorov.

## Proverki

Krasnyiye progonyi podtverdili otsutstviye yazyikonejtraljnogo API v prezhnej realizacii. Posle realizacii celevyiye proverki podtverdili strogij profilj, tochnuyu skhemu posle tipizirovannogo dekodirovaniya, odinakovuyu granicu glubinyi writer/parser, razlichiye NFC/NFD i nemutiruyusjhij otkaz prezhnikh skhem. Finaljnyij obsjhij corpus soderzhit 52 soglasovannyiye Swift↔Python-proverki, a polnyij Swift-nabor vyipolnyayet 41 test bez otkazov. Strogaya sborka s `strict-concurrency=complete` i preduprezhdeniyami kak oshibkami, Swift Format lint, vetochnyij nabor i planovyij reyestr proshli. Polnyij repozitornyij smoke-check zavershil 61/61 shag avtonomno bez seti i sekretov. Polnyij perechenj pryamyikh zapuskov i dliteljnostej sokhranyon v [otchyote rabochej sessii](otchyot.md).

## Povliyal na fajlyi

- [.obsidian/graph.json](../../../../../.obsidian/graph.json)
- [README.md](../../README.md)
- [Proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)
- [Yazyikonejtraljnyij kanonicheskij protokol pamyati](../../Dokumentaciya/47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- [Zhurnal/README.md](../README.md)
- [Zhurnal tekusjhej rabochej sessii](otchyot.md)
- [Iskhodnyij zapros o kriticheskom analize i prioritetakh](../2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [Tekusjhij iskhodnyij zapros](zapros.md)
- [Predyidusjhij iskhodnyij zapros](../2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- [Indeks Markdown-fajlov po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Indeks kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md)
- [Vyipolnennaya kartochka FUM-STEP-0101](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0101-zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0101-закрепить-языконейтральный-канонический-протокол-памяти.md`
- [Kartochka FUM-STEP-0102](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0102-podklyuchitj-proveryayemyij-realjnyij-model-only-adapter.md)
- [Planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Rabochij nabor sleduyusjhego shaga vetki](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [Pasport Swift-prototipa](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)
- [CanonicalMemoryJSON.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Sources/FUMReproducibleMemoryPopulation/CanonicalMemoryJSON.swift)
- [Domain.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Sources/FUMReproducibleMemoryPopulation/Domain.swift)
- [Engine.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Sources/FUMReproducibleMemoryPopulation/Engine.swift)
- [Generation.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Sources/FUMReproducibleMemoryPopulation/Generation.swift)
- [GenerationValidation.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Sources/FUMReproducibleMemoryPopulation/GenerationValidation.swift)
- [MemoryGenerationStore.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Sources/FUMReproducibleMemoryPopulation/MemoryGenerationStore.swift)
- [CanonicalMemoryJSONTests.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/CanonicalMemoryJSONTests.swift)
- [CanonicalMemoryProtocolConformanceTests.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/CanonicalMemoryProtocolConformanceTests.swift)
- [MemoryPopulationTests.swift](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/MemoryPopulationTests.swift)
- [Nezavisimyij Python-verifier](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/Fiksturyi/KanonicheskijProtokol-v1/canonical_memory_json_v1.py)
- [Golden bytes nachaljnogo pokoleniya](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/Fiksturyi/KanonicheskijProtokol-v1/generation-initial-v3.base64)
- [Golden bytes prodolzhennogo pokoleniya](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/Fiksturyi/KanonicheskijProtokol-v1/generation-continuation-v3.base64)
- [Manifest obsjhego corpus](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/Fiksturyi/KanonicheskijProtokol-v1/manifest.json)
- [Granichnoye sobyitiye `remember`](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/Tests/FUMReproducibleMemoryPopulationTests/Fiksturyi/KanonicheskijProtokol-v1/remember-event-value-boundary.base64)
- [Trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:1a7ac83edda39e16179478855ec5d4752ceb674e9e61a9fc780cd8446dc23481 -->
<!-- FUM-MD-RECENCY:END -->
