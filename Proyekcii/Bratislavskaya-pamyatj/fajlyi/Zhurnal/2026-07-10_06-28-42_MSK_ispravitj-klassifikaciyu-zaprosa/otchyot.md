# Otchyot 2026-07-10 06:28:42 MSK - Ispravitj klassifikaciyu zaprosa

Iz razdela `Вопросы и ответы/` udalyon fajl, kotoryij vosproizvodil prosjbu `Davaj sozdadim...`, a ne vopros. Kanonicheskaya zapisj etoj prosjbyi uzhe susjhestvuyet v `Запросы/`, poetomu dopolniteljnyij proizvodnyij material dubliroval istochnik i pripisyival yemu otsutstvuyusjhuyu voprositeljnuyu formu.

Granica razdela teperj sformulirovana bukvaljno: voprositeljnoye predlozheniye v iskhodnom tekste poljzovatelya dolzhno okanchivatjsya znakom `?`. Prosjbyi, komandyi i predlozheniya vyipolnitj dejstviye ne pereformuliruyutsya zadnim chislom v voprosyi i ostayutsya iskhodnyimi zaprosami. Otvet o versiyakh ChatGPT i Codex, chej iskhodnyij tekst dejstviteljno okanchivayetsya `?`, stal pervyim korrektnyim materialom razdela.

Povtoreniye oshibki predotvrasjhayet rasshirennaya avtomatizaciya `fum-session-coherence`. TDD-test snachala vosproizvyol nevernuyu kartochku, posle chego proverka stala obkhoditj vesj katalog `Вопросы и ответы/`, propuskatj toljko README i otklonyatj fajl bez nepustogo razdela `## Вопрос`, zakanchivayusjhegosya znakom `?`. Dopolniteljnyiye testyi zakrepili zapisj udalyonnogo puti v razdele `## Повлиял на файлы`, chtobyi sessii s udaleniyami prokhodili proverku Git-sostoyaniya bez bityikh Markdown-ssyilok, no susjhestvuyusjhij fajl neljzya byilo lozhno obyyavitj udalyonnyim vmesto obyazateljnoj ssyilki.

## Zatronutyiye materialyi

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [iskhodnyij zapros o sozdanii razdela](../2026-07-10_05-51-44_MSK_sozdatj-papku-voprosov-i-otvetov/zapros.md)
- [pravila repozitoriya](../../AGENTS.md)
- [README razdela voprosov i otvetov](../../Voprosyi%20i%20otvetyi/README.md)
- [avtomatizaciya proverki svyaznosti](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [Predlozheniya o sleduyusjhikh shagakh FUM](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Regressionnyij test voprosno-otvetnogo materiala do realizacii - ozhidayemo zavershilsya oshibkoj; posle realizacii proshyol.
- Regressionnyij test markera udalyonnogo fajla do realizacii - ozhidayemo zavershilsya oshibkoj; posle realizacii proshyol.
- Otricateljnyij test markera dlya susjhestvuyusjhego fajla do zasjhityi - ozhidayemo zavershilsya oshibkoj; posle realizacii proshyol.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo: 19 testov.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-10_06-28-42_MSK_исправить-классификацию-запроса.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-10_06-28-42_MSK_исправить-классификацию-запроса.md` - proshlo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0c2ceaf5170a1fcf01951c2e12a3ba046f97e4accaa2b2823190d3d744da4e22 -->
<!-- FUM-MD-RECENCY:END -->
