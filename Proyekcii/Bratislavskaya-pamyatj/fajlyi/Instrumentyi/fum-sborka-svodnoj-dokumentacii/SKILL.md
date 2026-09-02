---
name: fum-sborka-svodnoj-dokumentacii
description: Sozdavatj svodnyiye statji dokumentacii FUM iz neskoljkikh opornyikh statej na obsjhuyu temu, naprimer arkhitekturnuyu kartu iz raznesyonnyikh dokumentov.
---

# FUM Doc Aggregation

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md) dlya sozdaniya svodnoj statji: odnogo Markdown-dokumenta, kotoryij sobirayet neskoljko opornyikh statej [proizvodnoj dokumentacii](../../Glossarij/proizvodnaya-dokumentaciya.md) v obsjhuyu kartu temyi.

Svodnaya statjya ne zamenyayet opornyiye dokumentyi. Ona pokazyivayet obsjhuyu strukturu, granicyi temyi, kartu istochnikov i marshrut podderzhki, a detaljnyiye trebovaniya ostayutsya v iskhodnyikh materialakh.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu, kogda nuzhno:

- sobratj razroznennyiye statji `Документация/` v odnu obzornuyu ili arkhitekturnuyu statjyu;
- sozdatj novyij vkhodnoj dokument po obsjhej teme, kotoraya uzhe raskryita v neskoljkikh mestakh;
- obnovitj susjhestvuyusjhuyu svodnuyu statjyu posle izmeneniya nabora istochnikov;
- proveritj, chto svodnaya statjya soderzhit ssyilku na iskhodnyij zapros, vse opornyiye dokumentyi i obyazateljnuyu strukturu.

Ne ispoljzuj etu avtomatizaciyu dlya [opisanij FUM dlya adresatov](../../Glossarij/opisaniye-FUM-dlya-adresata.md): dlya nikh zakreplena otdeljnaya skhema `Описания/Автоматизации/построение-описания-FUM-для-адресата.md`.

## Vkhodyi

Avtomatizaciya prinimayet JSON-konfiguraciyu:

```json
{
  "title": "Архитектура FUM",
  "topic": "архитектура FUM",
  "purpose": "Собрать разнесённые архитектурные требования в одну карту.",
  "request_file": "Журнал/2026-06-24_15-45-41_MSK_собрать-архитектуру/запрос.md",
  "automation_file": "Инструменты/fum-sborka-svodnoj-dokumentacii/SKILL.md",
  "source_documents": [
    {
      "path": "Документация/00-обзор-проекта.md",
      "role": "обзорный вход"
    },
    {
      "path": "Документация/05-модульная-архитектура-FUM.md",
      "role": "детальный слой темы"
    }
  ],
  "sections": [
    {
      "title": "Карта слоёв",
      "focus": "Показать, какие слои образуют общую тему."
    }
  ]
}
```

Minimaljnyij nabor istochnikov - dve opornyiye statji. `request_file`, `automation_file` i kazhdyij `source_documents[].path` zadayutsya normalizovannyimi POSIX-putyami ot kornya repozitoriya. Absolyutnyiye, vyikhodyasjhiye iz repozitoriya, URI-, home-, Windows/UNC- i simvolicheskiye formyi otklonyayutsya do zapisi karkasa.

## Procedura

1. Sokhrani iskhodnyij poljzovateljskij zapros v `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md` po pravilam `AGENTS.md`.
2. Vyiberi obsjhuyu temu, celj svodnoj statji i spisok opornyikh dokumentov.
3. Sozdaj JSON-konfiguraciyu dlya tekusjhej sborki. Yesli svodnaya statjya budet regulyarno peresobiratjsya, sokhrani konfiguraciyu v [pamyati FUM](../../Glossarij/pamyatj-FUM.md) ryadom s avtomatizaciyej ili v drugom yavno svyazannom meste.
4. Postroj kanonicheskij karkas:

```bash
python3 Инструменты/fum-sborka-svodnoj-dokumentacii/scripts/build-doc-aggregation.py build \
  --config Документация/Автоматизации/сводная-статья.json \
  --output Документация/<номер>-<тема>.md
```

5. Zapolni smyislovyiye razdelyi na russkom yazyike kirillicej. Vse susjhestvennyiye utverzhdeniya dolzhnyi vyivoditjsya iz opornyikh dokumentov ili byitj yavno pomechenyi kak interpretaciya.
6. Udali vse markeryi `DOC_AGGREGATION_TODO`.
7. Proverj zavershyonnuyu statjyu:

```bash
python3 Инструменты/fum-sborka-svodnoj-dokumentacii/scripts/build-doc-aggregation.py validate \
  --config Документация/Автоматизации/сводная-статья.json \
  --document Документация/<номер>-<тема>.md \
  --complete
```

8. Zafiksiruj vyizov avtomatizacii i rezuljtat proverki v fajle iskhodnogo zaprosa rabochej sessii.

## Proverki

Lokaljnyiye testyi avtomatizacii zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-sborka-svodnoj-dokumentacii/tests -p 'test_*.py'
```

Validator proveryayet:

- zagolovok svodnoj statji;
- ssyilku na iskhodnyij zapros;
- ssyilki na vse opornyiye dokumentyi;
- obyazateljnyiye razdelyi pasporta, naznacheniya, kartyi istochnikov i podderzhki;
- razdelyi, perechislennyiye v konfiguracii;
- princip, chto svodnaya statjya ne zamenyayet opornyiye dokumentyi;
- otsutstviye `DOC_AGGREGATION_TODO` pri proverke s `--complete`.

## Granica avtomatizacii

Skript stroit proveryayemyij karkas i kontroliruyet strukturu, no ne podmenyayet smyislovoj sintez. Agent otvechayet za chteniye istochnikov, vyibor tezisov, ustraneniye protivorechij, ssyilki na glossarij i fiksaciyu otkryityikh voprosov, yesli iz istochnikov sleduyet neodnoznachnostj.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:546e473db536b4cbb0a47000147fcfb146545faa86ce3ca3965d474b36cb4ac6 -->
<!-- FUM-MD-RECENCY:END -->
