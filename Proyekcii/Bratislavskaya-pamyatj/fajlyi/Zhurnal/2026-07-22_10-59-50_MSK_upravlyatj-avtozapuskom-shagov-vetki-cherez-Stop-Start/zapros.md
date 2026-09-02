# Iskhodnyij zapros 2026-07-22 10:59:50 MSK - Upravlyatj avtozapuskom shagov vetki cherez Stop Start

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-22 10:31:30 MSK - Zapretitj absolyutnyiye puti v promptakh avtozadach](../2026-07-22_10-31-30_MSK_zapretitj-absolyutnyiye-puti-v-promptakh-avtozadach/zapros.md)
- Sleduyusjhij zapros: [2026-07-22 11:17:21 MSK - Uvelichitj ozhidaniye ocheredi do pyati minut](../2026-07-22_11-17-21_MSK_uvelichitj-ozhidaniye-ocheredi-do-pyati-minut/zapros.md)

## Tekst zaprosa

```text
Sdelayem shatnuyu vozmozhnostj vyiklyuchatj i vozobnovlyatj avtozapusk shagov vetki cherez Stop/Start vnutri sessii s etoj avtomatizaciyej.
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f88aa-539c-7c30-ab33-b903e7f0fc9e

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Sistemnyij navyik `openai-docs` i oficialjnyij spravochnik zaplanirovannyikh zadach Codex — ispoljzovanyi dlya proverki aktualjnoj publichnoj modeli aktivnyikh i priostanovlennyikh zadach.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-sleduyusjhij-shag-vetki`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya ocheredi, kanonicheskogo vremeni, kontrakta dispetchera, sluzhebnyikh metok i itogovoj proverki.
- Kontraktyi Codex Desktop `codex_app.automation_update`, `codex_app.read_thread`, `functions.*` i `collaboration.*` — otdeljnyiye versii sredoj ne raskryivayutsya; ispoljzovanyi dlya prosmotra i shtatnogo pereklyucheniya zhivogo heartbeat, pravok, komand i paralleljnyikh read-only-auditov.
- Git, Python, ripgrep, Zsh i sistemnyiye utilityi macOS — versii proveryayutsya po [reyestru](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md); ispoljzovanyi dlya kontrolya sostoyaniya, testov, poiska i proverok.

## Povliyal na fajlyi

- [Pravila povedeniya v repozitorii](../../AGENTS.md)
- [Dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Predyidusjhij zapros](../2026-07-22_10-31-30_MSK_zapretitj-absolyutnyiye-puti-v-promptakh-avtozadach/zapros.md)
- [Tekusjhij zapros](zapros.md)
- [Otchyot tekusjhej rabochej sessii](otchyot.md)
- [Indeks zhurnala](../README.md)
- [Kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [Shablon heartbeat-dispetchera](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [Testyi sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Nastrojka grafa Obsidian](../../../../../.obsidian/graph.json)

## Chto sdelano

Shtatnaya kartochka susjhestvuyusjhego pyatiminutnogo heartbeat zakreplena kak yedinstvennaya operatorskaya poverkhnostj vnutri prikreplyonnoj dispetcherskoj zadachi. `Stop` perevodit etu zhe avtomatizaciyu v `PAUSED`, a `Start` vozvrasjhayet yeyo v `ACTIVE`, ne sozdavaya dublikat i sokhranyaya celevuyu zadachu, prompt, raspisaniye i ostaljnyiye polya.

V pravilakh repozitoriya, proizvodnoj dokumentacii, kontrakte sleduyusjhego shaga vetki i shablone heartbeat zafiksirovana granica upravleniya. Ostanovka zapresjhayet budusjhiye tiki, no ne otmenyayet uzhe nachavshijsya tik ili sozdannuyu zadachu, ne snimayet claim, ne osvobozhdayet FIFO-vladeljca i ne menyayet `ready` na `paused`. Vozobnovleniye ne forsiruyet nemedlennyij zapusk: sleduyusjhij planovyij tik zanovo prokhodit obe proverki prostoya, `show`, claim i FIFO.

Zhivoj heartbeat proveren shtatnyim perekhodom `ACTIVE → PAUSED → ACTIVE`. Posle oboikh perekhodov sokhranenyi ta zhe privyazannaya zadacha, tot zhe prompt i pyatiminutnyij ritm; itogovyij status ostalsya `ACTIVE`.

## Granica primenimosti

Stop/Start upravlyayut runtime-raspisaniyem dispetchera, a ne vetochnyim rabochim naborom. Susjhestvuyusjhij claim vosstanavlivayetsya toljko otdeljnoj fenced-operaciyej po tochnomu `lease_id` posle vneshnego podtverzhdeniya, chto prezhnyaya zadacha okonchateljno ostanovlena. Neodnoznachnyij rezuljtat pereklyucheniya trebuyet shtatnogo prosmotra i ne razreshayet ruchnoye redaktirovaniye lokaljnoj konfiguracii.

## Proverki

- Novyij regressionnyij test snachala ozhidayemo otkazal iz-za otsutstviya kontrakta Stop/Start, posle obnovleniya dokumentacii proshyol.
- Kontroliruyemyij perekhod zhivogo heartbeat podtverdil `PAUSED`, zatem `ACTIVE`, bez izmeneniya privyazki, prompta i raspisaniya.
- Polnyij avtonomnyij nabor `fum-sleduyusjhij-shag-vetki` proshyol: `43` testa. Nabor FIFO-ocheredi proshyol: `31` test.
- Validaciya i chteniye sleduyusjhego shaga sokhranili `FUM-STEP-0023` v `ready`, a obsjhij smoke-check repozitoriya proshyol vse `37` shagov, vklyuchaya oba SwiftPM-paketa, strogij lint, reyestryi, ssyilki, recency, graf i svyaznostj sessii.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3c72e6ce6266fd3e590316b3814c0b0b46626cfa2d62c7a40d662be5c4786a09 -->
<!-- FUM-MD-RECENCY:END -->
