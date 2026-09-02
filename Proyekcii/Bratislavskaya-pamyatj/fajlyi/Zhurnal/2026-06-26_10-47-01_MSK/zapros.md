# Iskhodnyij zapros 2026-06-26 10:47:01 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-06-26 10:34:02 MSK](../2026-06-26_10-34-02_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-06-26 11:05:03 MSK](../2026-06-26_11-05-03_MSK/zapros.md)

## Tekst zaprosa

> Opishi raznicu mezhdu interfejsom FUM i MCP.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.exec_command`, `functions.apply_patch`, `multi_tool_use.parallel`.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, poiska po repozitoriyu, prosmotra versij instrumentov i zapuska proverok.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-glossary` - versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-glossarij/SKILL.md); ispoljzovan dlya obnovleniya glossarnyikh statej.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); ispoljzovan dlya proverki svyaznosti tekusjhej rabochej sessii.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya zapuska proverki svyaznosti.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj v etoj sessii; ispoljzovanyi `sed`, `ls`, `sort`, `tail` i `date`.

## Povliyal na fajlyi

- [Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Dokumentaciya/25-interfejs-FUM-uzla.md](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Glossarij/README.md](../../Glossarij/README.md)
- [Glossarij/MCP-server.md](../../Glossarij/MCP-server.md)
- [Glossarij/interfejs-FUM-uzla.md](../../Glossarij/interfejs-FUM-uzla.md)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Zhurnal/README.md](../README.md)
- [Zhurnal/2026-06-26_10-47-01_MSK.md](otchyot.md)
- [Zaprosyi/2026-06-26_10-34-02_MSK.md](../2026-06-26_10-34-02_MSK/zapros.md)
- [Zaprosyi/2026-06-26_10-47-01_MSK.md](zapros.md)

## Proverki

- `git diff --check` - proshlo bez zamechanij.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-26_10-47-01_MSK.md` - proshlo.

## Opisaniye sdelannogo

Razlichiye mezhdu [interfejsom FUM-uzla](../../Glossarij/interfejs-FUM-uzla.md) i [MCP-serverom](../../Glossarij/MCP-server.md) zakrepleno v proizvodnoj dokumentacii i glossarii.

Interfejs FUM-uzla opisan kak shirokaya arkhitekturnaya granica vnutrennej i vneshnej dostupnosti uzla: pamyatj, sostoyaniya, nablyudatelej, namereniya, podtverzhdeniya, prava, trassyi, proiskhozhdeniye i peredachu rezuljtata. MCP-server utochnyon kak boleye uzkij servisnyij adapter vnutri vneshnego interfejsa, kotoryij predostavlyayet mashinnyij dostup k konkretnomu servisu ili srede, no ne zamenyayet interfejs FUM celikom.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:bb28c44566d129f649cb2294a618352d3e93807c78694196666237d1520d9080 -->
<!-- FUM-MD-RECENCY:END -->
