# Otchyot 2026-07-10 05:59:58 MSK - Utochnitj uchyot versij ChatGPT i Codex

Rabochaya sessiya ispravila slishkom shirokuyu formulirovku «versiya Codex ne raskryivayetsya sredoj». Ona voznikla pri sozdanii reyestra instrumentov kak bezopasnyij fallback, no zatem bez dopolniteljnoj proverki povtorilasj vo vsekh 102 fajlakh zaprosov, gde prisutstvuyet razdel ispoljzovannyikh instrumentov.

Lokaljnaya proverka pokazala, chto nablyudayemyi neskoljko raznyikh versij: ChatGPT desktop app `26.707.31428` so sborkoj `5059`, vstroyennyij `codex-cli 0.144.0-alpha.4` i samostoyateljnyij `codex-cli 0.144.1`. Otdeljno nablyudayetsya skonfigurirovannaya modelj po umolchaniyu, no ona ne prinyata za dokazannyij snimok aktivnoj modeli sessii.

V `AGENTS.md` i reyestre zakrepleno poslojnoye pravilo. Poverkhnostj ili prilozheniye, vstroyennyij runtime, samostoyateljnyij CLI, aktivnaya modelj i kontraktyi instrumentov teperj fiksiruyutsya razdeljno. Versiya odnogo sloya ne podmenyayet drugoj, a zapisj «ne raskryivayetsya» trebuyet nazvatj konkretnuyu nenablyudayemuyu granicu.

Gotovyij otvet sokhranyon v `Вопросы и ответы/`. Istoricheskiye zaprosyi ne perepisyivalisj: novaya tochnostj primenyayetsya k tekusjhej i budusjhim sessiyam.

Povtoryayemaya proverka zasjhisjhena susjhestvuyusjhej avtomatizaciyej `fum-session-coherence`: novyij TDD-test vosproizvodit prezhnyuyu obsjhuyu zapisj, a realizaciya otklonyayet yeyo dlya novyikh zaprosov, sokhranyaya istoricheskuyu obratnuyu sovmestimostj. Vremennaya registraciya publichnogo MCP-servera oficialjnoj dokumentacii byila otmenena do zaversheniya sessii, poetomu postoyannogo izmeneniya globaljnoj konfiguracii ne ostalosj.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- Udalyonnaya posle utochneniya oblasti razdela kartochka: `Вопросы и ответы/2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex.md`
- [AGENTS.md](../../AGENTS.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Predlozheniya o sleduyusjhikh shagakh FUM](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo: 15 testov.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex.md` - proshlo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3cb7ec5bf425b61ca10d87cdb6c6c565867efd780eac41a868bcbddc0a538ecf -->
<!-- FUM-MD-RECENCY:END -->
