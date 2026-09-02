---
name: fum-ocenki
description: Sozdavatj i proveryatj ocenochnyiye materialyi FUM v `Оценки/`: snimok repozitoriya, metodika raschyota, diapazonyi, dopusjheniya, ogranicheniya tochnosti i oformleniye rezuljtata.
---

# FUM Estimates

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoraya sozdayot i proveryayet ocenochnyiye materialyi v `Оценки/`. Ocenka zdesj ponimayetsya kak vosproizvodimyij analiticheskij snimok: ona ne zamenyayet fakticheskij tajm-treking, finansovuyu smetu ili trebovaniya, no fiksiruyet vopros ocenki, sostoyaniye repozitoriya, metodiku, diapazonyi, dopusjheniya, ogranicheniya tochnosti i oformleniye rezuljtata.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu, kogda nuzhno sozdatj, obnovitj ili proveritj tipovoj fajl v `Оценки/`: trudoyomkostj, masshtab rabot, oriyentirovochnuyu stoimostj, slozhnostj soprovozhdeniya ili druguyu ocenku, gde vazhnyi povtoryayemaya metodika i sravnimostj rezuljtatov.

Ne ispoljzuj yeyo kak zamenu smyislovoj otvetstvennosti agenta. Skript proveryayet strukturu, proiskhozhdeniye i nalichiye zayavlennyikh elementov, no chislennyiye diapazonyi, dopusjheniya i vyivodyi vsyo ravno dolzhnyi byitj obyyasnimyi po istochnikam i kontekstu zadachi.

## Vkhodyi

Avtomatizaciya prinimayet JSON-konfiguraciyu:

```json
{
  "title": "Оценка трудоёмкости текущей памяти FUM",
  "request_file": "Журнал/2026-06-29_17-50-10_MSK_оценить-трудоёмкость/запрос.md",
  "automation_file": "Инструменты/fum-ocenki/SKILL.md",
  "question": "Сколько человеко-часов потребовалось бы для сопоставимой работы?",
  "unit": "человеко-часов",
  "point_estimate": 160,
  "range": {"low": 120, "high": 220},
  "summary": "Краткий вывод оценки.",
  "scope": "Граница оцениваемого результата.",
  "snapshot": {
    "date": "2026-06-29",
    "metrics": [
      {"name": "Отслеживаемые файлы", "value": "332"}
    ],
    "notes": [
      "Снимок зафиксирован при создании оценки."
    ]
  },
  "methodology": [
    {
      "name": "Разложение по видам работы",
      "description": "Итоговая оценка собирается из диапазонов по компонентам."
    }
  ],
  "breakdown": [
    {
      "name": "Написание и связывание документации",
      "low": 40,
      "high": 75,
      "comment": "Документация, глоссарий и планирование."
    }
  ],
  "assumptions": [
    "Оценивается сопоставимое создание результата, а не фактическое время сессий."
  ],
  "precision_limits": [
    "Оценка не является фактическим тайм-трекингом."
  ],
  "result_format": [
    "Ключевой вывод стоит в первых абзацах."
  ],
  "interpretation": [
    "Краткая человекочитаемая интерпретация результата."
  ]
}
```

`request_file` i `automation_file` ukazyivayutsya normalizovannyimi POSIX-putyami ot kornya repozitoriya. Absolyutnyiye, vyikhodyasjhiye iz repozitoriya, URI-, home-, Windows/UNC- i simvolicheskiye formyi otklonyayutsya do zapisi dokumenta. Dlya vosproizvodimyikh ocenok predpochtiteljno khranitj konfiguraciyu v `Оценки/Автоматизации/`.

## Procedura

1. Sokhrani iskhodnyij poljzovateljskij zapros v `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md` po pravilam `AGENTS.md`.
2. Yesli nuzhen novyij snimok tekusjhego sostoyaniya repozitoriya, vyipolni:

```bash
python3 Инструменты/fum-ocenki/scripts/build-estimate.py snapshot \
  --output Оценки/Автоматизации/<имя-снимка>.json
```

3. Podgotovj JSON-konfiguraciyu ocenki: vopros, yedinicyi izmereniya, tochechnuyu ocenku, diapazon, snimok repozitoriya, metodiku, razlozheniye, dopusjheniya, ogranicheniya i pravila oformleniya rezuljtata.
4. Soberi Markdown-fajl:

```bash
python3 Инструменты/fum-ocenki/scripts/build-estimate.py build \
  --config Оценки/Автоматизации/<имя-конфигурации>.json \
  --output Оценки/<имя-оценки>.md
```

5. Proverj gotovyij fajl:

```bash
python3 Инструменты/fum-ocenki/scripts/build-estimate.py validate \
  --config Оценки/Автоматизации/<имя-конфигурации>.json \
  --document Оценки/<имя-оценки>.md \
  --complete
```

6. Zafiksiruj vyizov avtomatizacii, konfiguraciyu, rezuljtat proverki i ogranicheniya tochnosti v fajle iskhodnogo zaprosa rabochej sessii.

## Chto proveryayetsya

Validator proveryayet:

- zagolovok ocenki;
- ssyilku na iskhodnyij zapros;
- ssyilku na avtomatizaciyu;
- obyazateljnyiye razdelyi `Снимок репозитория`, `Методика расчёта`, `Диапазоны`, `Допущения`, `Ограничения точности` i `Оформление результата`;
- nalichiye itogovogo diapazona i tochechnoj ocenki;
- nalichiye zayavlennyikh v konfiguracii metrik snimka, metodicheskikh shagov, komponent razlozheniya, dopusjhenij, ogranichenij i pravil oformleniya;
- otsutstviye markerov `ESTIMATE_TODO` pri proverke s `--complete`.

## Proverki avtomatizacii

Lokaljnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocenki/tests -p 'test_*.py'
```

Testyi fiksiruyut bazovyij kontrakt: avtomatizaciya sozdayot ocenochnyij Markdown-fajl s obyazateljnyimi razdelami, prinimayet polnyij rezuljtat, soobsjhayet ob otsutstvuyusjhem obyazateljnom razdele i zamechayet poteryannyij itogovyij diapazon.

## Granica avtomatizacii

Skript podderzhivayet proveryayemuyu formu ocenki, no ne vyichislyayet smyislovyiye koefficiyentyi avtomaticheski i ne garantiruyet istinnostj chisel. Agent otvechayet za vyibor metodiki, korrektnostj diapazonov, chestnostj dopusjhenij, publikacionnuyu chistotu snimka, svyazj s istochnikami trebovanij i fiksaciyu otkryityikh voprosov, yesli ocenka vyiyavlyayet neodnoznachnostj ili protivorechiye.

Komanda `snapshot` sobirayet toljko lokaljno nablyudayemuyu statistiku Git-repozitoriya: kommit, vetku, sostoyaniye rabochego dereva, chislo otslezhivayemyikh fajlov, Markdown-fajlov, strok i slov. Yesli ocenke nuzhnyi vneshniye dannyiye, stoimostj servisov, trudozatratyi lyudej ili privatnaya istoriya rabotyi, oni dolzhnyi fiksirovatjsya otdeljnyim publikacionno chistyim istochnikom ili yavno oboznachatjsya kak nedostupnaya chastj.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:448ad06e1c00a52acc06a1f4b47a7b8a768d841f8af556331aed4508ad9c892b -->
<!-- FUM-MD-RECENCY:END -->
