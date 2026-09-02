# Iskhodnyij zapros 2026-07-23 16:11:30 MSK - Opisatj shablon kartochki eksperimenta FUM

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-23 15:26:35 MSK - Zapretitj vneshniye navyiki v repozitorii](../2026-07-23_15-26-35_MSK_zapretitj-vneshniye-navyiki-v-repozitorii/zapros.md)
- Sleduyusjhij zapros: [2026-07-23 17:37:10 MSK - Opisatj kartu ogranichitelej fizicheskogo dejstviya FUM](../2026-07-23_17-37-10_MSK_opisatj-kartu-ogranichitelej-fizicheskogo-dejstviya-FUM/zapros.md)

## Tekst zaprosa

```text
<codex_delegation>
  <source_thread_id>019f8070-6efb-77c1-b3c3-7be5439b851e</source_thread_id>
  <input>Это автоматически назначенная обычная корневая задача Codex в локальном проекте. Корнем всех файловых ссылок считай рабочий каталог проекта, выбранного через projectId. Не добавляй к переданным путям никакой корень и не преобразуй их в абсолютные пути.

Твоё первое видимое сообщение, до запуска любого инструмента, должно быть ровно:
Автозапуск назначил карточку FUM-STEP-0027 — Описать шаблон карточки эксперимента FUM; ожидаю допуск FIFO.
Это сообщение показывает назначение, но не подтверждает допуск FIFO и не означает начала содержательной работы.

Первым инструментальным действием получи из среды точный собственный корневой CODEX_THREAD_ID и зарегистрируй его как task_id командой join из Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md. Не создавай замену идентификатору. До join не запускай другие инструменты, процессы или субагентов и не меняй файлы, индекс, checkout, ветку, историю либо внешнее состояние. До состояния admitted только жди по контракту FIFO без изменений, без писателей и без промежуточных сообщений о неизменном ожидании.

Полностью прочитай:
- AGENTS.md
- Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md
- Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md

После допуска полностью прочитай без добавления корня переданные record_path, card_path и project_path. Рабочий набор, карточка шага и паспорт проекта являются обязательными входами. Соблюдай все границы действий, доступа, публикации и проверки из паспорта проекта.

Машинно проверенный payload успешного диспетчерского show ниже. Все значения точные: не нормализуй, не переименовывай и не выводи из них новые файловые пути.
{
  "branch_ref": "refs/heads/master",
  "step_id": "master-fum-step-0027-ready-v1",
  "status": "ready",
  "record_path": "Планирование/следующие-шаги-веток/master.md",
  "card_id": "FUM-STEP-0027",
  "card_path": "Планирование/карточки-шагов/🟡-FUM-STEP-0027-описать-шаблон-карточки-эксперимента-FUM.md",
  "card_content_sha256": "sha256:132d00eaabe3978a53c2004ad468d5367a8f38469492da4608261e0df388aad5",
  "project_path": "README.md",
  "title": "Описать шаблон карточки эксперимента FUM",
  "task": "Описать шаблон карточки [эксперимента FUM](../../Глоссарий/эксперимент-FUM.md): вопрос, гипотеза, метод, данные, среда, проверка, результат, ограничения, статус и следующий шаг.",
  "criteria": [
    "Результат, описанный в разделе «Задача», создан и сохранён в памяти FUM с явной границей применимости.",
    "Проверки, названные в задаче и опорных материалах, выполнены, а их результат зафиксирован в связанном запросе или журнале.",
    "Статус карточки обновлён по фактическому исходу; веточный выбор не дублирует содержание карточки."
  ]
}

После состояния admitted и до любых записей выполни документированный fenced show с ожидаемыми branch_ref="refs/heads/master" и step_id="master-fum-step-0027-ready-v1". Только если fenced show успешно повторно подтверждает эту пару и назначенные card_id/title, до содержательной работы ровно один раз выведи:
В работу взята карточка FUM-STEP-0027 — Описать шаблон карточки эксперимента FUM.

При mismatch не выводи формулировку о взятии карточки в работу. Вместо неё выведи ровно:
Назначение карточки FUM-STEP-0027 — Описать шаблон карточки эксперимента FUM не подтверждено; работа не начата.
Не оставляй владельца FIFO: дождись отсутствия всех способных позднее записать процессов и субагентов, выполни документированный finish-clean очереди с точными task_id и generation, а после успеха больше ничего не записывай и заверши задачу.

При подтверждённой паре проведи обычную рабочую сессию строго по AGENTS.md. Сохрани полный текст этого полученного диспетчерского prompt как исходный материал сессии. Выполни точные task и criteria из payload, опираясь на полностью прочитанные рабочий набор, карточку и паспорт.

Перед завершением:
- удали выполненного кандидата из рабочего набора;
- сохрани все ещё корректные paused- и blocked-кандидаты вместе с их resume_condition;
- выбери не более одной новой безопасно исполнимой карточки как ready и назначь ей свежий step_id;
- если кандидатов нет, установи state=done;
- не позволяй отложенной карточке скрывать другой готовый шаг;
- дождись всех способных позднее записать процессов и субагентов;
- выполни проверки;
- заверши сессию атомарным commit+handoff очереди по её документированному контракту, не используя обычный git commit.

Не освобождай claim этого успешно созданного запуска ни при каких обстоятельствах.</input>
</codex_delegation>
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f8f14-a012-7562-94f5-df4420d2acd5

## Rezuljtat

Sozdan [shablon kartochki eksperimenta FUM](../../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md) versii `1`. On fiksiruyet vopros, gipotezu, metod, dannyiye, sredu, zaraneye zadannuyu proverku, otdeljnyiye zapuski, nablyudayemyij rezuljtat, ogranicheniya, tri nezavisimyiye osi statusa i odin sleduyusjhij shag. Odna kartochka opisyivayet odnu versiyu protokola odnoj gipotezyi; planovyiye polya ne perepisyivayutsya pod iskhod, a otricateljnyij i neodnoznachnyij rezuljtatyi sokhranyayutsya.

Zapolnennyij primer proveryayet determinirovannuyu JSON-serializaciyu dvukh slovarej s raznyim poryadkom vstavki. Lokaljnaya komanda Python `3.14.6` bez seti, sekretov i zapisi dala odinakovyiye stroki i SHA-256, no rezuljtat ogranichen tochnyimi vkhodami, parametrami i sredoj i ne obyyavlen nezavisimyim vosproizvedeniyem ili otkryitiyem.

Vyipolnennaya kartochka `FUM-STEP-0027` perevedena v istoricheskij status. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0028` yedinstvennyim novyim `ready` s pokoleniyem `master-fum-step-0028-ready-v1`.

## Granica primenimosti

Shablon yavlyayetsya chelovekochitayemyim kontraktom dokumentacionnogo prototipa, a ne ispolnyayemoj skhemoj, laboratornyim runtime, avtomaticheskim dokazateljstvom, razresheniyem dostupa ili osnovaniyem dlya vneshnego dejstviya. Modeljnyij i lokaljnyij rezuljtat ne perenositsya na vneshnij mir bez otdeljnoj proverki. Setj, publikacionnoye i socialjnoye vozdejstviye, vneshniye cifrovyiye izmeneniya i fizicheskoye dejstviye ostayutsya zakryityi do otdeljnogo trebovaniya, razresheniya i proverki riska.

Slovari sostoyanij vyipolneniya i iskhodov proverki otnosyatsya k versii `1` shablona. Kanonicheskiye issledovateljskiye statusyi sokhranyayut otdeljnyiye kriterii; povtor vnutri proizvodyasjhego uzla ne schitayetsya nezavisimyim vosproizvedeniyem.

## Status avtomatizacii

Sozdan povtorno ispoljzuyemyij deklarativnyij shablon s pravilami zapolneniya i polnostjyu zapolnennyim lokaljnyim primerom. Otdeljnyij programmnyij validator ne dobavlyalsya: tekusjhij shag opredelyayet semantiku chelovekochitayemoj kartochki, a mashinnuyu skhemu razumno zakreplyatj posle nakopleniya realjnyikh kartochek i proverki ustojchivosti polej. Strukturu, ssyilki, planovyij sloj, recency i svyaznostj proveryayut susjhestvuyusjhiye lokaljnyiye avtomatizacii.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye navyiki `fum-ocheredj-zadach-git-vetki`, `fum-sleduyusjhij-shag-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-glossarij`, `fum-reyestr-planirovaniya`, `fum-obratnyiye-ssyilki-voprosov`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya FIFO-dopuska, fenced-sverki, kanonicheskogo vremeni, glossariya, planovogo reyestra, obratnyikh ssyilok voprosov, recency i itogovoj priyomki.
- Poverkhnostj Codex Desktop i kontraktyi `functions.*` i `collaboration.*` — otdeljnyiye versii tekusjhej sessiyej ne raskryivayutsya; ispoljzovanyi dlya lokaljnyikh komand, patch-pravok, plana i tryokh paralleljnyikh read-only-analizov.
- Git, Python `3.14.6`, ripgrep i Zsh — versii i sposobyi proverki zafiksirovanyi v reyestre; ispoljzovanyi dlya chteniya, poiska, lokaljnogo primera, pereimenovaniya kartochki, generatorov, proverok i atomarnoj podgotovki kommita.

## Povliyal na fajlyi

Kazhdyij putj itogovogo Git-sostoyaniya perechislen yavno dlya predkommitnoj proverki svyaznosti.

- [Nastrojka grafa Obsidian](<../../../../../.obsidian/graph.json>)
- [Otkryityij vopros o granicakh issledovateljskoj avtonomii FUM](../../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md)
- [Eksperiment FUM](../../Glossarij/eksperiment-FUM.md)
- [Nauchnyiye issledovaniya FUM i otkryitiya](../../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md)
- [Indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Indeks zhurnala](../README.md)
- [Tekusjhij otchyot zhurnala](otchyot.md)
- [Predyidusjhij iskhodnyij zapros](../2026-07-23_15-26-35_MSK_zapretitj-vneshniye-navyiki-v-repozitorii/zapros.md)
- [Iskhodnyij zapros o dekompozicii predlozhenij na kartochki](../2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [Iskhodnyij zapros o pereimenovanii kartochek shagov](../2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami/zapros.md)
- [Tekusjhij iskhodnyij zapros](zapros.md)
- [Indeks planirovaniya](../../Planirovaniye/README.md)
- [Dorozhnaya karta FUM](../../Planirovaniye/dorozhnaya-karta.md)
- [Indeks kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md)
- [Zavershyonnaya kartochka FUM-STEP-0027](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0027-opisatj-shablon-kartochki-eksperimenta-FUM.md)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0027-описать-шаблон-карточки-эксперимента-FUM.md`
- [Napravleniye issledovanij i otkryitij](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md)
- [Planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [Shablon kartochki eksperimenta FUM](../../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md)

## Proverki

- Lokaljnyij proverochnyij primer vyipolnen v Python `3.14.6`: dve serializacii ravnyi `{"a":1,"b":2}`, dva SHA-256 ravnyi `43258cff783fe7036d8a43033f830adfc60ec037382473548ac742b888292777`, kod vyikhoda `0`.
- Planovyij reyestr dlya `71` kartochki, novoye pokoleniye rabochego nabora s `FUM-STEP-0028` kak yedinstvennyim `ready`, recency, graf Obsidian, obratnyiye ssyilki `14` aktivnyikh voprosov na `87` zayavlennyikh celej, svyaznostj rabochej sessii i `git diff --check` proverenyi uspeshno.
- Posle ispravlenij finaljnogo soderzhateljnogo revjyu svezhij polnyij smoke-check proshyol `39/39` shagov za `197,1` sekundyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0fc0ebe079549250b238c14f41d05a66c5c94ae500d504f49a28c83f7ab1cac0 -->
<!-- FUM-MD-RECENCY:END -->
