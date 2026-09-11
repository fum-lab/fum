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

Validator toljko chitayet strukturu. Pole inventarya `продолжение_задачи` soglasuyet yedinstvennyij marker `explicit-worklist-v1` v korne s susjhestvuyusjhim tochnyim lokaljnyim scenariyem proverki resheniya; otsutstviye, dublirovaniye, neizvestnaya versiya i nebezopasnyij putj zakryivayut dopusk. On sveryayet registraciyu kazhdogo fakticheskogo yakorya v obe storonyi, zapresjhayet dejstvuyusjhuyu normu v teme bez polnomochij i pri politike izolirovannyikh worktree trebuyet yedinstvennyij sovmestimyij marker zapreta starogo avtokonvejyera. On zakryito otklonyayet otsutstvuyusjhij putj, nevernyij registr, lyuboj symlink-komponent, vyikhod za checkout, podmenu soderzhaniya, povtor identifikatora, JSON-klyucha ili aktivnoj semantiki, nepolnoye iskhodnoye pokryitiye, nekompaktnyij korenj, nesoglasovannyij marshrut i vklyucheniye istoricheskikh polnomochij v obyichnyij marshrut.

Dlya sovmestimosti iskhodnogo master i rezuljtata FUM-STEP-0177 podderzhanyi rovno dve paryi tel dejstvuyusjhikh kornevyikh pravil 000062 i NOVOYE-000017. Ikh tochnyiye tekstyi, proiskhozhdeniye i deklaracii sokhranenyi v [otkryitoj fiksture profilej](tests/fiksturyi/profili-prodolzheniya.json). Para iz master trebuyet rovno `маркер` i `сценарий`; para JSONL dopolniteljno trebuyet tochnyij spisok `обязательные_параметры: ["--перед-завершением", "--исходник"]` i tryokhpolevoj `остаток_сообщений` s komandoj `остаток`, `без_записи: true` i kanonicheskim obrabotchikom. Oba puti proveryayutsya kak tochnyiye obyichnyiye lokaljnyiye fajlyi. Profilj vyibirayetsya po polnyim telam pravil proveryayemogo dereva i ikh dejstvuyusjhemu naznacheniyu P0 v `AGENTS.md`, zatem sveryayetsya deklaraciya. Udaleniye novyikh polej ne perevodit pravila JSONL v staryij profilj.

Neizvestnyiye i smeshannyiye redakcii, skryitiye norm, inyiye polya i znacheniya otklonyayutsya. Dva podderzhannyikh kornevyikh karkasa ne soderzhat ograd, vneshnikh HTML-oblastej ili mnogostrochnyikh HTML-kommentariyev; pri prodolzhenii zadachi takiye formyi zakryivayut dopusk. Khyesh tela isklyuchayet toljko konechnyiye perevodyi stroki LF. Yesli pravilo izmeneno, snachala soglasujte novyij profilj i yego regressii, zatem povtorite `проверить`; redaktirovaniye inventarya samo po sebe ne rasshiryayet spisok profilej. Polnyij soglasovannyij vozvrat obeikh norm i deklaracii k staromu profilyu razlichayetsya vneshnim kontrolem proiskhozhdeniya sliyaniya, a ne etim staticheskim validatorom.

## Istochnik trebovanij

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:16:44 MSK -->
<!-- content-sha256: sha256:2e213914a7eb08f733ae2505af1b8b208a4e903328722c651a89fb1c15da7d92 -->
<!-- FUM-MD-RECENCY:END -->
