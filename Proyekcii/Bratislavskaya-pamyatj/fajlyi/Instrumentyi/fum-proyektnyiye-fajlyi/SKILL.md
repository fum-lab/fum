---
name: fum-proyektnyiye-fajlyi
description: Otbiratj proyektnyiye Markdown-fajlyi FUM dlya lokaljnyikh avtomatizacij po obsjhej Git-sovmestimoj politike isklyuchenij i bezopasno proveryatj vyikhodnyiye puti.
---

# FUM Project Files

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) zadayot yedinyij vosproizvodimyij inventarj proyektnyikh Markdown-fajlov. Yeyo modulj [project_files.py](scripts/project_files.py) ispoljzuyetsya sluzhebnyimi generatorami i proverkami, chtobyi odin Git-snimok daval odin i tot zhe nabor vkhodov nezavisimo ot soderzhimogo lokaljnyikh sborochnyikh katalogov i kyeshej.

## Kontrakt vkhodov

V Git-repozitorii inventarj obyyedinyayet vse otslezhivayemyiye Markdown-fajlyi s novyimi neignoriruyemyimi Markdown-fajlami. Otslezhivayemyiye fajlyi zaprashivayutsya otdeljno ot neotslezhivayemyikh, poetomu lokaljnyij `.git/info/exclude` ne mozhet skryitj uzhe otslezhivayemyij proyektnyij dokument.

Iz lyubogo obkhoda bezuslovno isklyuchayutsya `.git`, `.build`, `.swiftpm`, `.cache`, `cache`, `caches`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`, katalogi s okonchaniyami `-cache`, `_cache` i `.cache`, a takzhe `.obsidian/plugins` i `.obsidian/themes`. Eta strukturnaya granica dejstvuyet dazhe dlya prinuditeljno otslezhivayemogo fajla i pri fajlovom obkhode bez Git.

Vkhod dolzhen byitj obyichnyim fajlom vnutri repozitoriya. Simvolicheskiye ssyilki v komponentakh puti, razresheniye puti za predelyi repozitoriya ili vnutrj isklyuchyonnogo kataloga, oshibka fajlovogo obkhoda i skryito otsutstvuyusjhij otslezhivayemyij Markdown-fajl schitayutsya oshibkami. Tak avtomatizaciya ostanavlivayetsya, yesli ne mozhet dokazatj polnotu i bezopasnostj inventarya.

## Ispoljzovaniye

Modulj predostavlyayet:

- `project_markdown_paths(repo_root)` — otsortirovannyij inventarj proyektnyikh Markdown-fajlov;
- `is_structurally_excluded_path(path, repo_root)` — proverku strukturnogo isklyucheniya dlya proizvoljnogo puti;
- `normalized_project_relative_path(value, repo_root, field_name=..., must_exist=...)` — stroguyu normalizaciyu path-polya: toljko POSIX-putj ot kornya repozitoriya bez URI, home-form, Windows/UNC-putej, `.`/`..`, simvolicheskikh ssyilok i strukturnyikh isklyuchenij;
- `safe_project_output_path(path, repo_root)` — proverku kanonicheskogo vyikhodnogo fajla pered chteniyem ili zapisjyu.

Fajlovyij fallback primenyayetsya toljko tam, gde Git-kontekst dejstviteljno otsutstvuyet ili yavno otklyuchyon vyizyivayusjhim kodom. On ispoljzuyet tu zhe strukturnuyu politiku i ne sleduyet po simvolicheskim ssyilkam.

## Proverki

Avtonomnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proyektnyiye-fajlyi/tests -p 'test_*.py'
```

Fiksturyi proveryayut obsjhij Git-inventarj, `.build/checkouts/vendor/README.md`, `.swiftpm`, kyeshi, lokaljnyij exclude otslezhivayemogo fajla, filesystem fallback, zapresjhyonnyiye formyi path-polej, simvolicheskuyu ssyilku v isklyuchyonnoye khranilisjhe, oshibku obkhoda i skryito otsutstvuyusjhij `skip-worktree`-fajl.

## Granica avtomatizacii

Inventarj opredelyayet toljko tekhnicheskoye mnozhestvo Markdown-vkhodov i bezopasnostj vyikhodnyikh putej. On ne reshayet, yavlyayetsya li fajl soderzhateljno umestnyim, publikacionno chistyim ili praviljno oformlennyim.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)
- [revjyu proyekta 2026-07-18](../../Zhurnal/2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)
- [iskhodnyij zapros 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../../Zhurnal/2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:9e7c6a8f1e12de651933b0bf619af60ae70f133e4ba61046459ff29af4299612 -->
<!-- FUM-MD-RECENCY:END -->
