---
name: fum-dekompoziciya-pravil-agentov
description: Proveryayet kompaktnoye yadro AGENTS.md, obyazateljnyiye tematicheskiye marshrutyi i polnoye odnoznachnoye pokryitiye iskhodnogo inventarya pravil.
---

# Dekompoziciya pravil agentov

Ispoljzuj etot navyik pri izmenenii `AGENTS.md`, fajlov `Правила/агентов/`, mashinnogo inventarya ili samogo validatora dekompozicii. Navyik ne dayot polnomochij na zapisj: pravo zapisi opredelyayetsya vsegda zagruzhennyim kornevyim yadrom i dejstvuyusjhej rabochej sessiyej.

## Obyazateljnyij poryadok

1. Do pervoj zapisi vyiberi trigger `правила` po kornevomu marshrutizatoru i polnostjyu prochitaj vse vozvrasjhyonnyiye tematicheskiye Markdown-fajlyi, `Правила/агентов/инвентарь-правил.json` i etot `SKILL.md`.
2. Sokhrani stabiljnyiye identifikatoryi susjhestvuyusjhikh pravil. Novomu pravilu naznachj novyij identifikator, oblastj, prioritet, triggeryi, semanticheskij klyuch, yedinstvennoye naznacheniye i proveryayemoye osnovaniye.
3. Ne menyaj istoricheskij snimok zadnim chislom. Iskhodnyij `AGENTS.md` vosproizvoditsya iz tochnyikh `commit` i `blob`; `исходные_единицы` dolzhnyi bez razryivov i perekryitij pokryivatj kazhdyij yego bajt.
4. Pri izmenenii tematicheskogo fajla pereschitaj yego `sha256_содержания` bez sluzhebnogo bloka `FUM-MD-RECENCY`. Ne kopiruj odnu aktivnuyu normu v neskoljko fajlov.
5. Razvivaj validator cherez TDD: snachala dobavj otricateljnuyu libo polozhiteljnuyu fiksturu i nablyudaj RED, zatem realizuj povedeniye i nablyudaj GREEN.
6. Kazhdyij pryamoj zapusk testa ili validatora v pishusjhej sessii provodi cherez lokaljnuyu avtomatizaciyu otchyotov o zapuskakh proverok s putyom tekusjhego `запрос.md`.

## Komandyi

Marshrut dlya odnogo ili neskoljkikh triggerov vyichislyayetsya bez izmeneniya fajlov:

```sh
python3 Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py \
  --корень-репозитория . маршрут \
  --триггер изменение \
  --триггер документация
```

Polnaya strukturnaya proverka vyipolnyayetsya tak:

```sh
python3 Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py \
  --корень-репозитория . проверить
```

Avtonomnyiye testyi:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-dekompoziciya-pravil-agentov/tests \
  -p 'test_*.py'
```

Validator toljko chitayet strukturu. On zakryito otklonyayet otsutstvuyusjhij putj, nevernyij registr, lyuboj symlink-komponent, vyikhod za checkout, podmenu soderzhaniya, povtor identifikatora ili aktivnoj semantiki, nepolnoye iskhodnoye pokryitiye, nekompaktnyij korenj, nesoglasovannyij marshrut i vklyucheniye istoricheskikh polnomochij v obyichnyij marshrut.

## Istochnik trebovanij

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:13:37 MSK -->
<!-- content-sha256: sha256:8dda70e09ea481dc709a2e334b9eea9adee1cb52d132f7179acaeb63c932bfee -->
<!-- FUM-MD-RECENCY:END -->
