# Iskhodnyij zapros 2026-07-22 10:31:30 MSK - Zapretitj absolyutnyiye puti v promptakh avtozadach

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-22 10:02:43 MSK - Dobavitj audit pokryitiya voprosov i otvetov](../2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/zapros.md)
- Sleduyusjhij zapros: [2026-07-22 10:59:50 MSK - Upravlyatj avtozapuskom shagov vetki cherez Stop Start](../2026-07-22_10-59-50_MSK_upravlyatj-avtozapuskom-shagov-vetki-cherez-Stop-Start/zapros.md)

## Tekst zaprosa

```text
Ne ispoljzuj absolyutnyiye puti v prompte dlya avtomaticheski sozdavayemyikh zadach. U nas vrode byil zapret na ispoljzovaniye absolyutnyikh putej fajlovoj sistemyi.
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f88a0-4f76-7430-9d14-10218684933a

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-sleduyusjhij-shag-vetki`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya ocheredi, kanonicheskogo vremeni, kontrakta dispetchera, sluzhebnyikh metok i itogovoj proverki.
- Codex Desktop `26.715.70719` build `5650`, vstroyennyij runtime i kontraktyi `codex_app.automation_update`, `codex_app.read_thread`, `functions.*` i `collaboration.*` — otdeljnyiye versii kontraktov sredoj ne raskryivayutsya; ispoljzovanyi dlya tochnogo chteniya iskhodnogo zaprosa, obnovleniya i proverki aktivnogo heartbeat, pravok, komand i paralleljnyikh read-only-auditov.
- Git `2.54.0 (Apple Git-157)`, Python `3.14.6`, ripgrep `15.2.0`, Zsh `5.9` i sistemnyiye utilityi macOS — versii proverenyi lokaljno; ispoljzovanyi dlya kontrolya istorii i diff, testov, poiska, chteniya konfiguracii i diagnostiki.

## Povliyal na fajlyi

- [Pravila povedeniya v repozitorii](../../AGENTS.md)
- [Predyidusjhij zapros](../2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/zapros.md)
- [Tekusjhij zapros](zapros.md)
- [Otchyot tekusjhej rabochej sessii](otchyot.md)
- [Indeks zhurnala](../README.md)
- [Kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [Shablon heartbeat-dispetchera](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [Testyi sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [Indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Nastrojka grafa Obsidian](../../../../../.obsidian/graph.json)

## Chto sdelano

Audit podtverdil, chto obsjhego pravila dlya promptov avtomaticheski sozdavayemyikh zadach ranjshe ne byilo. Uzkiye normyi zapresjhali mashinno-zavisimyiye absolyutnyiye puti v otdeljnyikh konfiguraciyakh, no sam heartbeat-dispetcher s momenta sozdaniya treboval podstavlyatj korenj klona i perenositj yego v dochernij prompt. Dvenadcatj istoricheskikh avtomaticheski sozdannyikh zaprosov doslovno sokhranyayut etot effekt; oni ne perepisyivalisj.

V `AGENTS.md`, kontrakte sleduyusjhego shaga vetki i shablone heartbeat zakreplena tochnaya granica: sokhranyonnyij absolyutnyij korenj dopustim toljko vnutri vneshnego dispetchera dlya vyibora lokaljnogo proyekta i rabochego kataloga. Dochernij prompt ispoljzuyet otnositeljnyiye `AGENTS.md`, puti navyikov i uzhe proverennyiye `record_path`, `card_path` i `project_path` bez dopisyivaniya kornya. Yesli zadacha, kriterii ili inoye dinamicheskoye znacheniye soderzhit absolyutnyij putj, dispetcher osvobozhdayet sobstvennyij claim do `create_thread` i ne sozdayot zadachu.

Aktivnyij pyatiminutnyij heartbeat obnovlyon cherez shtatnyij instrument Codex bez izmeneniya imeni, raspisaniya, statusa i roditeljskoj zadachi. Proverka sokhranyonnoj konfiguracii podtverdila tochnoye sovpadeniye vneshnego prompta s repozitornyim shablonom posle podstanovki kornya i otsutstviye etogo kornya v dochernem uchastke.

## Granica primenimosti

Zapret otnositsya k promptu avtomaticheski sozdavayemoj dochernej zadachi. Absolyutnyij korenj ostayotsya vnutrennim parametrom vneshnego heartbeat, potomu chto nuzhen dlya tochnogo sopostavleniya sokhranyonnogo proyekta i vyibora rabochego kataloga. Istoricheskiye fajlyi `Запросы/` sokhranyayut prezhniye promptyi doslovno i ne schitayutsya dejstvuyusjhej instrukciyej.

## Proverki

- Novyij regressionnyij test snachala ozhidayemo otkazal na starom `<КОРЕНЬ_КЛОНА>/...`, posle ispravleniya proshyol.
- Sokhranyonnaya konfiguraciya aktivnogo heartbeat sovpadayet s obnovlyonnyim shablonom; status `ACTIVE` i interval pyatj minut sokhranenyi, dochernij uchastok ispoljzuyet otnositeljnyiye puti.
- Polnyij avtonomnyij nabor `fum-sleduyusjhij-shag-vetki` proshyol: `42` testa. Nabor ocheredi proshyol: `31` test.
- Validaciya i chteniye sleduyusjhego shaga vetki, recency- i grafovaya proverki, proverka svyaznosti rabochej sessii, obsjhaya smoke-proverka repozitoriya i `git diff --check` proshli.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:51ced739e8eeeaf054c4876cfc7c08acb05b86f27f7001b312b9e52604446351 -->
<!-- FUM-MD-RECENCY:END -->
