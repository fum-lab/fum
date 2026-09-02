# Dekompoziciya pravil agentov

Avtomatizaciya uderzhivayet `AGENTS.md` v predelakh vsegda peredavayemogo konteksta i dokazyivayet, chto tematicheskaya zagruzka ne teryayet iskhodnyiye pravila. Codex avtomaticheski obnaruzhivayet toljko fajlyi semejstva `AGENTS.md` po iyerarkhii katalogov; obyichnyiye Markdown-ssyilki ne stanovyatsya instrukciyami, poetomu obyazateljnostj polnogo chteniya tematicheskikh fajlov zakreplena polozhiteljnyim kornevyim marshrutizatorom.

Mashinnyij inventarj svyazyivayet iskhodnyij Git-snimok, pobajtovyiye iskhodnyiye yedinicyi, stabiljnyiye identifikatoryi pravil, ikh oblasti, prioritetyi, triggeryi i yedinstvennyiye celevyiye yakorya. Sam iskhodnyij tekst povtorno ne khranitsya: on vosproizvoditsya iz tochnyikh `commit` i `blob`.

Komanda `маршрут` snachala provodit polnuyu strukturnuyu proverku, a zatem vozvrasjhayet bezopasnoye obyyedineniye putej dlya vsekh peredannyikh triggerov. Komanda `проверить` proveryayet strukturu celikom. Obe komandyi read-only.

## Sostav

- `SKILL.md` — obyazateljnyij poryadok izmeneniya strukturyi;
- `scripts/проверить-декомпозицию-правил.py` — validator i vyichislitelj marshruta;
- `tests/test_декомпозиция_правил_агентов.py` — polozhiteljnyiye i otricateljnyiye TDD-fiksturyi;
- `Правила/агентов/инвентарь-правил.json` — kanonicheskij mashinnyij inventarj.

## Istochnik trebovanij

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:13:37 MSK -->
<!-- content-sha256: sha256:7109b0a03ff875d301b83950cf38fea46c74b2e7ab1dc732f4e3c207e0290bfc -->
<!-- FUM-MD-RECENCY:END -->
