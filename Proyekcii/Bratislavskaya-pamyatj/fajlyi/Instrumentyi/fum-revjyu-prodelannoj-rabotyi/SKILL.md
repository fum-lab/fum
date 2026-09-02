---
name: fum-revjyu-prodelannoj-rabotyi
description: Sozdavatj i proveryatj sokhranyonnyiye revjyu prodelannoj rabotyi FUM: Git-srez, oblastj proverki, nakhodki, proverki, ostatochnyiye riski i vyivod.
---

# FUM Work Review

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) sozdayot i proveryayet sokhranyonnyiye revjyu prodelannoj rabotyi. Ona nuzhna, kogda rabochij srez uzhe soderzhit neskoljko kommitov ili zametnoye izmeneniye [pamyati FUM](../../Glossarij/pamyatj-FUM.md), a rezuljtat revjyu dolzhen ostatjsya ne toljko v otvete agenta, no i v repozitorii.

Avtomatizaciya sobirayet nablyudayemyij Git-kontekst, primenyayet ustojchivuyu strukturu otchyota i validiruyet sokhranyonnyij Markdown-fajl. Smyislovaya chastj revjyu ostayotsya otvetstvennostjyu agenta-revjyuyera: skript ne zamenyayet chteniye diff, proverku svyaznosti trebovanij i inzhenernoye suzhdeniye.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu, kogda nuzhno:

- provesti revjyu prodelannoj rabotyi otnositeljno vyibrannoj bazyi, naprimer `origin/master..HEAD`;
- sokhranitj nakhodki, otsutstviye nakhodok, proverki i ostatochnyiye riski v `Ревью/`;
- sdelatj revjyu povtoryayemyim i sravnimyim mezhdu rabochimi sessiyami;
- podtverditj, chto otchyot revjyu soderzhit ssyilku na iskhodnyij zapros, avtomatizaciyu, Git-srez i proverochnyij kontur.

## Vkhodyi

Avtomatizaciya prinimayet JSON-konfiguraciyu:

```json
{
  "title": "Ревью проделанной работы",
  "request_file": "Журнал/2026-07-01_17-03-14_MSK_проверить-работу/запрос.md",
  "automation_file": "Инструменты/fum-revjyu-prodelannoj-rabotyi/SKILL.md",
  "base_ref": "origin/master",
  "head_ref": "HEAD",
  "reviewed_at": "2026-07-01 17:03:14 MSK",
  "reviewer": "Codex",
  "scope": "Проверяется свежая работа относительно origin/master.",
  "review_focus": [
    "связь изменений с исходными запросами",
    "структурная связность рабочей сессии"
  ],
  "findings": [],
  "checks": [
    {
      "name": "fum-kompleksnaya-proverka-repozitoriya",
      "command": "python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py --request Журнал/<имя-запроса>/запрос.md",
      "result": "прошло",
      "details": "Все локальные проверки прошли."
    }
  ],
  "residual_risks": [
    "Смысловая оценка физических аналогий остаётся исследовательской гипотезой."
  ],
  "decision": "Существенных замечаний не выявлено."
}
```

`request_file`, `automation_file`, neobyazateljnoye `config_file` i kazhdoye `findings[].file` ukazyivayutsya normalizovannyimi POSIX-putyami ot kornya repozitoriya. Absolyutnyiye, vyikhodyasjhiye iz repozitoriya, URI-, home-, Windows/UNC- i simvolicheskiye formyi otklonyayutsya do zapisi otchyota. Pole `findings` mozhet byitj pustyim, yesli susjhestvennyikh zamechanij net; v etom sluchaye `decision` dolzhen pryamo fiksirovatj otsutstviye susjhestvennyikh zamechanij. Dlya zamechanij ispoljzuyutsya polya `priority`, `status`, `file`, `line`, `title`, `details` i `recommendation`.

## Komandyi zapuska

Sborka otchyota:

```bash
python3 Инструменты/fum-revjyu-prodelannoj-rabotyi/scripts/build-work-review.py build \
  --config Ревью/Автоматизации/<имя-конфигурации>.json \
  --output Ревью/<имя-отчёта>.md
```

Proverka gotovogo otchyota:

```bash
python3 Инструменты/fum-revjyu-prodelannoj-rabotyi/scripts/build-work-review.py validate \
  --config Ревью/Автоматизации/<имя-конфигурации>.json \
  --document Ревью/<имя-отчёта>.md \
  --complete
```

## Chto proveryayetsya

Validator proveryayet:

- zagolovok otchyota;
- obyazateljnyiye razdelyi `Граница ревью`, `Снимок Git`, `Что проверялось`, `Находки`, `Проверки`, `Остаточные риски` i `Сохранение результата`;
- ssyilki na fajl [iskhodnogo zaprosa](../../Glossarij/iskhodnyij-zapros.md) i etu avtomatizaciyu;
- upominaniye vyibrannyikh `base_ref`, `head_ref` i itogovogo resheniya;
- nalichiye komandyi kazhdoj zayavlennoj proverki;
- yavnuyu frazu `Существенных замечаний не выявлено.`, yesli spisok nakhodok pust;
- otsutstviye markera `WORK_REVIEW_TODO` pri proverke s `--complete`.

## Proverki avtomatizacii

Lokaljnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-revjyu-prodelannoj-rabotyi/tests -p 'test_*.py'
```

Testyi fiksiruyut bazovyij kontrakt: avtomatizaciya stroit otchyot iz Git-diapazona i konfiguracii, validiruyet polnyij rezuljtat i soobsjhayet ob otsutstvuyusjhem obyazateljnom razdele.

## Granica avtomatizacii

`fum-revjyu-prodelannoj-rabotyi` avtomatiziruyet sokhraneniye i strukturnuyu proverku revjyu, no ne delayet skryitogo LLM-analiza diff. Agent dolzhen sam prochitatj izmeneniya, ocenitj riski, sformulirovatj nakhodki ili chestno zafiksirovatj ikh otsutstviye, a zatem peredatj etot smyislovoj rezuljtat v konfiguraciyu.

Skript chitayet toljko lokaljnyij Git-srez, `git diff --check` i `git status --short --untracked-files=all`. On ne trebuyet setevyikh zaprosov, sekretov i vneshnikh servisov. Yesli revjyu zavisit ot vneshnego CI, GitHub, privatnoj perepiski ili aktualjnyikh vneshnikh faktov, eto nuzhno yavno vnesti v `checks` ili `residual_risks`.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6066d448019daf714f7dc1eb83b7a709db9c3cad798fbda11c0082665888cc0f -->
<!-- FUM-MD-RECENCY:END -->
