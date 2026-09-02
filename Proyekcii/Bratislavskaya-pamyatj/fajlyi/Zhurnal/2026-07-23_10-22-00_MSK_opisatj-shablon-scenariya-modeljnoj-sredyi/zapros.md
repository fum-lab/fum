# Iskhodnyij zapros 2026-07-23 10:22:00 MSK - Opisatj shablon scenariya modeljnoj sredyi

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-23 09:36:31 MSK - Ispravitj avtozapusk i predotvratitj povtor oshibki](../2026-07-23_09-36-31_MSK_ispravitj-avtozapusk-i-predotvratitj-povtor-oshibki/zapros.md)
- Sleduyusjhij zapros: [2026-07-23 10:44:00 MSK - Avtomatizirovatj obnovleniye ssyilok pri smene statusa kartochki](../2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki/zapros.md)

## Tekst zaprosa

```text
<codex_delegation>
  <source_thread_id>019f8070-6efb-77c1-b3c3-7be5439b851e</source_thread_id>
  <input>Это автоматически созданная обычная корневая задача Codex для выполнения одного fenced-шага FUM.

Точный машинно проверенный payload рабочего шага:
{
  "branch_ref": "refs/heads/master",
  "step_id": "master-fum-step-0024-ready-v1",
  "status": "ready",
  "record_path": "Планирование/следующие-шаги-веток/master.md",
  "card_id": "FUM-STEP-0024",
  "card_path": "Планирование/карточки-шагов/🟡-FUM-STEP-0024-описать-шаблон-сценария-модельной-среды.md",
  "card_content_sha256": "sha256:9dd057eddcc214e9a853ed6279bf49c15f58b68500a7bd62de3dd3be173880f1",
  "project_path": "README.md",
  "title": "Описать шаблон сценария модельной среды",
  "task": "Описать шаблон сценария [модельной среды](../../Глоссарий/модельная-среда.md): временной режим, статус утверждений, уверенность, источники, ограничения доступа, вопросы и ожидаемый результат.",
  "criteria": [
    "Результат, описанный в разделе «Задача», создан и сохранён в памяти FUM с явной границей применимости.",
    "Проверки, названные в задаче и опорных материалах, выполнены, а их результат зафиксирован в связанном запросе или журнале.",
    "Статус карточки обновлён по фактическому исходу; веточный выбор не дублирует содержание карточки."
  ]
}

Считай корнем всех файловых ссылок рабочий каталог локального проекта, выбранного через projectId. Используй переданные record_path, card_path и project_path буквально, без добавления корня проекта и без построения производных путей.

Обязательный порядок и границы работы:
- Полностью прочитай AGENTS.md, Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md и Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md.
- Первым рабочим действием зарегистрируй точный собственный корневой CODEX_THREAD_ID в FIFO-очереди по документированному контракту. До состояния admitted только жди без изменений; не запускай писателей и субагентов.
- После допуска полностью прочитай переданные record_path, card_path и project_path. Рабочий набор, карточка шага и паспорт проекта являются обязательными входами. Соблюдай все границы действий, доступа, публикации и проверки из паспорта проекта.
- После допуска и до любых записей выполни fenced show с ожидаемыми branch_ref и step_id из payload.
- Если fenced show вернёт mismatch, не оставляй владельца очереди: дождись отсутствия всех способных позднее записать процессов и субагентов, выполни документированный finish-clean очереди с точными task_id и generation, а после успеха больше ничего не записывай и заверши задачу.
- Проведи обычную рабочую сессию по AGENTS.md и сохрани весь этот диспетчерский prompt как исходный материал сессии.
- Выполни точные task и criteria из payload, не подменяя и не сокращая их.
- Перед завершением удали выполненного кандидата из рабочего набора, сохрани все ещё корректные paused/blocked-кандидаты вместе с их resume_condition и выбери не более одной новой безопасно исполнимой карточки как ready со свежим step_id. Если кандидатов не осталось, установи state=done. Отложенная карточка не должна скрывать другой готовый шаг.
- Дождись завершения всех способных позднее записать процессов и субагентов, выполни требуемые проверки и заверши сессию атомарным commit+handoff FIFO-очереди. Обычный git commit не используй.
- Не освобождай fenced-claim этого успешно созданного запуска.</input>
</codex_delegation>
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f8dd7-a4ef-76d3-b7d5-17212bbddc1b

## Rezuljtat

Sozdan [shablon scenariya modeljnoj sredyi](../../Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md) dlya planovyikh materialov dokumentacionnogo prototipa FUM. Pasport i povtoryayemyij blok utverzhdeniya fiksiruyut vremennoj rezhim, status, kachestvennuyu uverennostj s osnovaniyem, istochniki, urovenj i ogranicheniya dostupa, proverku, svyazannyij vopros i ozhidayemyij modeljnyij rezuljtat.

Shablon zadayot tri vremennyikh rezhima i ne dopuskayet znacheniya `смешанный`: aktualjnoye opisaniye, rekonstrukciya proshlogo i planirovaniye budusjhego zapisyivayutsya razdeljno. Zapolnennyij primer sokhranyayet aktualjnyij fakt, rekonstruktivnyij vyivod i budusjheye scenarnoye dopusjheniye kak raznyiye utverzhdeniya i vedyot neproyasnyonnuyu razvilku k susjhestvuyusjhemu otkryitomu voprosu.

Vyipolnennaya kartochka `FUM-STEP-0024` perevedena v istoricheskij status. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0025` yedinstvennyim novyim `ready` s pokoleniyem `master-fum-step-0025-ready-v1`.

## Granica primenimosti

Shablon opisyivayet chelovekochitayemyiye planovyiye scenarii tekusjhego dokumentacionnogo prototipa. On ne yavlyayetsya runtime-skhemoj, simulyatorom, virtualizovannoj ili apparatnoj sredoj; ne reshayet, yavlyayutsya li tri vremennyikh rezhima odnoj sredoj ili raznyimi tipami; ne raskryivayet vnutrenneye sostoyaniye modeliruyemogo uzla; ne prevrasjhayet vyivod, prognoz ili celj v fakt i ne razreshayet realjnoye dejstviye.

Lokaljnyiye slovari statusov i kachestvennoj uverennosti yavlyayutsya kontraktom etogo shablona, a ne okonchateljnoj ontologiyej korobochnoj FUM. Chislovaya veroyatnostj ne vvoditsya bez obsjhej kalibrovki.

## Status avtomatizacii

Sozdan povtorno ispoljzuyemyij deklarativnyij shablon s pravilami zapolneniya i lokaljnyim proverochnyim primerom. Otdeljnyij programmnyij validator ne dobavlyalsya: tekusjhij shag opredelyayet chelovekochitayemyij dokumentaljnyij kontrakt, a susjhestvuyusjhiye proverki podtverzhdayut ssyilki, planovyij sloj, strukturu kartochki, recency i svyaznostj rabochej sessii. Mashinnaya skhema ostayotsya vozmozhnyim posleduyusjhim sloyem posle nakopleniya realjnyikh scenariyev i proyasneniya otkryityikh razvilok.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-sleduyusjhij-shag-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-glossarij`, `fum-reyestr-planirovaniya`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya dopuska, fenced-sverki, kanonicheskogo vremeni, lokaljnogo glossariya, planovogo reyestra, recency i itogovoj priyomki.
- Poverkhnostj Codex Desktop i kontraktyi `functions.*` i `collaboration.*` — otdeljnyiye versii tekusjhej sessiyej ne raskryivayutsya; ispoljzovanyi dlya lokaljnyikh komand, patch-pravok, plana i tryokh paralleljnyikh read-only-auditov.
- Git, Python, ripgrep i Zsh — versii i sposobyi proverki zafiksirovanyi v reyestre; ispoljzovanyi dlya chteniya, poiska, pereimenovaniya kartochki, generatorov, proverok i atomarnoj podgotovki kommita.

## Povliyal na fajlyi

Kazhdyij putj itogovogo Git-sostoyaniya perechislen yavno dlya predkommitnoj proverki svyaznosti.

- [.obsidian/graph.json](<../../../../../.obsidian/graph.json>)
- [Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md](../../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md)
- [Glossarij/modeljnaya-sreda.md](../../Glossarij/modeljnaya-sreda.md)
- [Zhurnal/2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Zaprosyi/2026-07-23_09-36-31_MSK_ispravitj-avtozapusk-i-predotvratitj-povtor-oshibki.md](../2026-07-23_09-36-31_MSK_ispravitj-avtozapusk-i-predotvratitj-povtor-oshibki/zapros.md)
- [Zaprosyi/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov.md](../2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [Zaprosyi/2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami.md](../2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami/zapros.md)
- [Zaprosyi/2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi.md](zapros.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md](../../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md)
- [Planirovaniye/README.md](../../Planirovaniye/README.md)
- [Planirovaniye/dorozhnaya-karta.md](../../Planirovaniye/dorozhnaya-karta.md)
- [Planirovaniye/kartochki-shagov/README.md](../../Planirovaniye/kartochki-shagov/README.md)
- [Planirovaniye/kartochki-shagov/✅-FUM-STEP-0024-opisatj-shablon-scenariya-modeljnoj-sredyi.md](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0024-opisatj-shablon-scenariya-modeljnoj-sredyi.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Planirovaniye/sleduyusjhiye-shagi-vetok/master.md](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md](../../Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md)

## Proverki

- Smyislovaya proverka shablona podtverzhdayet obyazateljnyiye vremennoj rezhim, status, uverennostj, istochniki, ogranicheniya dostupa, voprosyi i ozhidayemyij rezuljtat na urovne kazhdogo znachimogo utverzhdeniya.
- Proverochnyij primer razdeljno sokhranyayet aktualjnyij fakt, rekonstrukciyu proshlogo i plan budusjhego, ssyilayetsya na susjhestvuyusjhij otkryityij vopros i ostanavlivayetsya do vyibora runtime ili realjnogo dejstviya.
- Planovyij reyestr peresobran i validen; kartochnyij indeks i vetochnyij rabochij nabor proshli shtatnyiye proverki, a fenced `show` podtverdil novoye pokoleniye `master-fum-step-0025-ready-v1`.
- Recency Markdown, graf Obsidian, obratnyiye ssyilki voprosov, svyaznostj rabochej sessii, `git diff --check` i polnyij smoke-check podtverzhdenyi pered atomarnoj peredachej ocheredi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:5b84f1a821a38e3fef7e37608494b8b9ec695122decc98d9c88e3fd3ab89b759 -->
<!-- FUM-MD-RECENCY:END -->
