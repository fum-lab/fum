# Iskhodnyij zapros 2026-07-24 08:19:09 MSK - Ispravitj skorostj novyikh zadach po umolchaniyu

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-24 07:49:44 MSK - Pereklyuchitj skorostj modeli na standartnuyu](../2026-07-24_07-49-44_MSK_pereklyuchitj-skorostj-modeli-na-standartnuyu/zapros.md)
- Sleduyusjhij zapros: [2026-07-24 08:42:34 MSK - Ispravitj poisk zakreplyonnogo heartbeat dispetchera](../2026-07-24_08-42-34_MSK_ispravitj-poisk-zakreplyonnogo-heartbeat-dispetchera/zapros.md)

## Tekst zaprosa

```text
Vsyo ravno zapuskayutsya chatyi s byistroj skorostjyu po umolchaniyu.
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f928a-f10a-7502-afe3-348b6d36d7a8

## Rezuljtat

Prichina najdena v boleye prioritetnom sloye Desktop, kotoryij ne byil proveren predyidusjhej sessiyej. Proyektnyij i poljzovateljskij `config.toml` uzhe soderzhali `service_tier = "default"`, odnako upravlyayemyij profilj macOS dlya `models.new_thread` zadaval `service_tier = "priority"`. Runtime-zhurnal tekusjhej zadachi podtverdil, chto Desktop peredal imenno etot yavnyij override, a vstroyennyij katalog `gpt-5.6-sol` sopostavlyayet `priority` s otobrazhayemyim rezhimom Fast.

V sistemnom profile novyikh zadach znacheniye `priority` zameneno na `default`. Modelj `gpt-5.6-sol` i rezhim rassuzhdeniya `ultra` sokhranenyi. Shtatnyij metod `configRequirements/read` novogo lokaljnogo app-server podtverdil itogovyij obyyekt `models.newThread` so znacheniyami `gpt-5.6-sol`, `ultra` i `default`.

Proyektnyij `.codex/config.toml` ne potreboval dopolniteljnoj pravki: on uzhe zaprashivayet standartnuyu skorostj. `features.fast_mode = true` po-prezhnemu ostavlyayet dostupnyim ruchnoj vyibor Fast, no boljshe ne yavlyayetsya istochnikom defolta. Uzhe otkryitaya zadacha sokhranyayet poluchennyij pri zapuske Fast-override; dlya garantirovannoj zagruzki izmenyonnogo sistemnogo profilya prilozheniyu nuzhen polnyij perezapusk, posle kotorogo novaya zadacha dolzhna sozdavatjsya so standartnoj skorostjyu.

## Resheniye po avtomatizacii

Otdeljnaya avtomatizaciya ne sozdana. Prichina nakhodilasj v ustojchivom sistemnom profile Desktop, a ne v vyichislyayemom proyektnom artefakte; znacheniye ispravleno napryamuyu i provereno cherez shtatnyij konfiguracionnyij API. Repozitorij sokhranyayet razlichiye mezhdu proyektnyim sloyem i sistemnyim defoltom v reyestre sredyi i zhurnale, ne pyitayasj perenositj mashinnuyu nastrojku macOS v publikacionnyij konfig proyekta.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya FIFO-dopuska, kanonicheskogo vremeni, proizvodnyikh fajlov i itogovoj priyomki.
- Poverkhnostj Codex Desktop `26.721.31836` (sborka `5828`) i vstroyennyij runtime `codex-cli 0.146.0-alpha.3.1` — versii proverenyi po lokaljnomu `Info.plist` i komande runtime; runtime-zhurnal, vstroyennyij modeljnyij katalog i `configRequirements/read` ispoljzovanyi dlya nablyudeniya fakticheskogo override, sootvetstviya `priority` rezhimu Fast i ispravlennogo defolta.
- macOS `defaults`, `base64` i SQLite `3` — ispoljzovanyi dlya chteniya i tochechnogo obnovleniya sistemnogo profilya `com.openai.codex`, dekodirovaniya yego TOML i chteniya odnoj diagnosticheskoj zapisi runtime bez publikacii mashinno-lokaljnyikh putej.
- Kontraktyi `functions.exec`, `exec_command`, `write_stdin`, `apply_patch` i `collaboration.*` — otdeljnyiye versii ne raskryivayutsya; ispoljzovanyi dlya lokaljnyikh komand, PTY-proverki app-server, pravok i paralleljnogo read-only-analiza.
- Python `3.14.6`, Git `2.54.0` (`Apple Git-157`), Zsh `5.9` i ripgrep `15.2.0` — ispoljzovanyi dlya lokaljnyikh avtomatizacij, Git-proverok i poiska.
- Tekusjhaya zadacha nablyudayemo poluchila ot Desktop servisnyij urovenj `priority`, to yestj Fast. Eto yavlyayetsya snimkom yeyo startovogo override, a ne dokazateljstvom nastrojki sleduyusjhej zadachi posle perezapuska prilozheniya.

## Povliyal na fajlyi

- [Teplovaya karta grafa Obsidian](../../../../../.obsidian/graph.json)
- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Indeks zhurnala](../README.md)
- [Predyidusjhij otchyot zhurnala](../2026-07-24_07-49-44_MSK_pereklyuchitj-skorostj-modeli-na-standartnuyu/otchyot.md)
- [Tekusjhij otchyot zhurnala](otchyot.md)
- [Predyidusjhij iskhodnyij zapros](../2026-07-24_07-49-44_MSK_pereklyuchitj-skorostj-modeli-na-standartnuyu/zapros.md)
- [Tekusjhij iskhodnyij zapros](zapros.md)

## Proverki

- Runtime-zhurnal tekusjhej zadachi soderzhit yavnyij `ThreadSettingsOverrides` s `service_tier = "priority"`, togda kak proyektnyij i poljzovateljskij konfigi soderzhat `default`; eto podtverzhdayet tochnuyu prichinu prezhnego Fast-defolta.
- Vstroyennyij modeljnyij katalog svyazyivayet servisnyij urovenj `priority` s nazvaniyem Fast i opisaniyem povyishennoj skorosti.
- Dekodirovannyij sistemnyij profilj i otvet `configRequirements/read` podtverzhdayut `models.newThread.serviceTier = "default"` pri sokhranyonnyikh `gpt-5.6-sol` i `ultra`.
- Recency-metki, teplovaya karta grafa Obsidian, svyaznostj rabochej sessii, `git diff --check` i polnyij smoke-check prokhodyat.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:11429921ff14669c5a6dafe0fbd7b3ff90a21cfcb854517fca5ba9d7d69bda13 -->
<!-- FUM-MD-RECENCY:END -->
