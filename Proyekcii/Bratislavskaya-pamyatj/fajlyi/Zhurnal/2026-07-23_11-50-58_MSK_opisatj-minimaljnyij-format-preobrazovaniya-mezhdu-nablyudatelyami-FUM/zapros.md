# Iskhodnyij zapros 2026-07-23 11:50:58 MSK - Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-23 10:44:00 MSK - Avtomatizirovatj obnovleniye ssyilok pri smene statusa kartochki](../2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki/zapros.md)
- Sleduyusjhij zapros: [2026-07-23 12:53:46 MSK - Opisatj minimaljnyij pasport peredavayemogo rezuljtata FUM](../2026-07-23_12-53-46_MSK_opisatj-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/zapros.md)

## Tekst zaprosa

```text
<codex_delegation>
  <source_thread_id>019f8070-6efb-77c1-b3c3-7be5439b851e</source_thread_id>
  <input>Это автоматически созданная обычная корневая задача Codex для выполнения одного fenced-шага FUM.

Точный машинно проверенный payload рабочего шага:
{
  "branch_ref": "refs/heads/master",
  "step_id": "master-fum-step-0025-ready-v1",
  "status": "ready",
  "record_path": "Планирование/следующие-шаги-веток/master.md",
  "card_id": "FUM-STEP-0025",
  "card_path": "Планирование/карточки-шагов/🟡-FUM-STEP-0025-описать-минимальный-формат-преобразования-между-наблюдателями-FUM.md",
  "card_content_sha256": "sha256:951b62e3cd4e1c95d6057a775a54e0817ddeb9987900da11b2efe1d03af4d73c",
  "project_path": "README.md",
  "title": "Описать минимальный формат преобразования между наблюдателями FUM",
  "task": "Описать минимальный формат преобразования между [наблюдателями FUM](../../Глоссарий/наблюдатель-FUM.md): исходный слой, профиль наблюдателя, наблюдаемые сигналы, сохраняемые инварианты, потери информации, проверку обратимости или необратимости перехода, а также маршрут к источнику полной информации или явную отметку невозможности такого перехода.",
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

Codex-Thread-ID: 019f8e18-236c-70c0-9ed9-6621288f8438

## Rezuljtat

Sozdan [minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md) versii `1`. Odna napravlennaya JSON-zapisj svyazyivayet tochnyiye iskhodnuyu i celevuyu storonyi, profili nablyudatelej, proverennyiye ischerpyivayusjhiye inventari signalov, kartu preobrazovaniya, invariantyi, yavnyiye poteri, vyivod ob obratimosti i nezavisimo proveryayemyij marshrut k iskhodnomu sloyu.

[JSON Schema](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json) zapresjhayet neizvestnyiye polya i zadayot strukturnyiye uslovnyiye kontraktyi obratimosti i marshruta. [Semanticheskij validator](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py) proveryayet mezhpolevyiye ssyilki, pokryitiye i granicyi publikacii. Dve lokaljnyiye fiksturyi s materializovannyimi kontekstami postavki pokazyivayut tochnyij UTF-8 round-trip i neobratimoye izvlecheniye pervogo Markdown-zagolovka s dokazannoj kolliziyej; vo vtorom sluchaye sokhranyonnyij istochnik ostayotsya dostupnyim, khotya celevaya podpisj ne soderzhit dostatochnoj informacii dlya obratnogo preobrazovaniya.

V glossarij dobavleno [preobrazovaniye mezhdu nablyudatelyami FUM](../../Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md), a arkhitektura, interfejs, nablyudateljskaya otnositeljnostj, reyestr kartochek sootvetstviya i profiljnoye napravleniye planirovaniya svyazanyi s novyim kontraktom bez podmenyi konceptualjnoj analogii napravlennyim preobrazovaniyem.

Vyipolnennaya kartochka `FUM-STEP-0025` perevedena v istoricheskij status. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0026` yedinstvennyim novyim `ready` s pokoleniyem `master-fum-step-0026-ready-v1`.

## Granica primenimosti

Versiya `1` opisyivayet odin perekhod mezhdu dvumya obyyavlennyimi predstavleniyami dokumentacionnogo prototipa. Ona ne yavlyayetsya runtime, kompilyatorom, transportom, universaljnoj ontologiyej nablyudatelej, chislovoj metrikoj informacionnoj poteri, razresheniyem na dostup ili dokazateljstvom polnogo vnutrennego sostoyaniya sistemyi. Kompoziciya cepochek ne schitayetsya avtomaticheski tranzitivnoj, a konechnaya fikstura podtverzhdayet toljko svoyu oblastj.

«Polnaya informaciya» oznachayet polnyij zakreplyonnyij istochnik v yavno nazvannoj proyekcii vnutri `scope`, a ne absolyutnoye sostoyaniye mira; ischerpyivayusjhij inventarj signalov etoj proyekcii proveryayetsya otdeljno. Marshrut k sokhranyonnomu istochniku i obratimostj samogo preobrazovaniya takzhe proveryayutsya nezavisimo.

## Status avtomatizacii

Sozdanyi povtorno ispoljzuyemyiye deklarativnaya JSON Schema, semanticheskij validator na standartnoj biblioteke Python, dve lokaljnyiye proverochnyiye fiksturyi i dva materializovannyikh konteksta postavki. Validator vosproizvodit ssyilochnuyu celostnostj, pokryitiye signalov, soglasovannostj poterj s obratimostjyu, zapret mashinno-lokaljnyikh putej, proveryayemuyu svyazj s sidecar-zapisjyu, round-trip, kolliziyu, SHA-256 i marshrutyi. Ispolnitelj proizvoljnyikh metodov preobrazovaniya i proverka kompozicii ostayutsya posleduyusjhimi sloyami.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-sleduyusjhij-shag-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-glossarij`, `fum-reyestr-planirovaniya`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya dopuska, fenced-sverki, kanonicheskogo vremeni, glossariya, planovogo sloya, recency i itogovoj priyomki.
- Navyik `fum-glossary` i prioritetnyij lokaljnyij kontrakt `fum-glossarij` — ispoljzovanyi dlya odnoj novoj terminologicheskoj statji s kirillicheskim imenem i indeksom.
- Poverkhnostj Codex Desktop i kontraktyi `functions.*` i `collaboration.*` — otdeljnyiye versii tekusjhej sessiyej ne raskryivayutsya; ispoljzovanyi dlya lokaljnyikh komand, patch-pravok, plana i tryokh paralleljnyikh read-only-auditov.
- Git, Python, ripgrep, Node.js i Zsh — versii i sposobyi proverki zafiksirovanyi v reyestre; ispoljzovanyi dlya chteniya, poiska, proverki dostupnosti JSON Schema-validatora, proverki fikstur, pereimenovaniya kartochki, generatorov i atomarnoj podgotovki kommita.

## Povliyal na fajlyi

Kazhdyij putj itogovogo Git-sostoyaniya perechislen yavno dlya predkommitnoj proverki svyaznosti.

- [.obsidian/graph.json](<../../../../../.obsidian/graph.json>)
- [README.md](../../README.md)
- [Dokumentaciya/22-arkhitektura-FUM.md](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [Dokumentaciya/25-interfejs-FUM-uzla.md](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md](../../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Dokumentaciya/28-reyestr-kartochek-sootvetstviya-FUM/README.md](../../Dokumentaciya/28-reyestr-kartochek-sootvetstviya-FUM/README.md)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-neobratimoj-fiksturyi.json](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-neobratimoj-fiksturyi.json)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-obratimoj-fiksturyi.json](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-obratimoj-fiksturyi.json)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-neobratimogo-preobrazovaniya.json](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-neobratimogo-preobrazovaniya.json)
- [Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-obratimogo-preobrazovaniya.json](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-obratimogo-preobrazovaniya.json)
- [Glossarij/README.md](../../Glossarij/README.md)
- [Glossarij/nablyudatelj-FUM.md](../../Glossarij/nablyudatelj-FUM.md)
- [Glossarij/nablyudateljskaya-otnositeljnostj-FUM.md](../../Glossarij/nablyudateljskaya-otnositeljnostj-FUM.md)
- [Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md](../../Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md)
- [Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Zaprosyi/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov.md](../2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [Zaprosyi/2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami.md](../2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami/zapros.md)
- [Zaprosyi/2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki.md](../2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki/zapros.md)
- [Zaprosyi/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md](zapros.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Planirovaniye/kartochki-shagov/README.md](../../Planirovaniye/kartochki-shagov/README.md)
- [Planirovaniye/kartochki-shagov/✅-FUM-STEP-0025-opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0025-opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Planirovaniye/sleduyusjhiye-shagi-vetok/master.md](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Proverki

- JSON Schema i obe fiksturyi prokhodyat Draft 2020-12 i sokhranyayemyij semanticheskij validator; obyazateljnyiye polya, unikaljnostj identifikatorov, razresheniye ssyilok na signalyi, ischerpyivayusjhiye inventari i sploshnoye pokryitiye iskhodnyikh signalov proverenyi.
- Pyatnadcatj otricateljnyikh mutacij ozhidayemo otklonenyi: visyachiye i povtornyiye ID, otvyazannyij marshrut, protivorechivyiye poteri i obratimostj, nepodtverzhdyonnyij `preserved`, nepodderzhivayemyij discovery-metod, lishniye statusnyiye polya, absolyutnyij `file:` URI, privatnyiye adresa i pokhozhiye na sekret parametryi URL.
- Obratimaya fikstura podtverzhdayet tochnyij UTF-8 round-trip bez poterj; neobratimaya podtverzhdayet sokhraneniye zagolovka i yavnuyu kolliziyu dvukh raznyikh Markdown-tel pri odinakovom celevom znachenii.
- V obeikh fiksturakh materializovannyij kontekst postavki obnaruzhivayet sidecar-zapisj, otnositeljnyij marshrut razreshayetsya k `Глоссарий/FUM.md`, a SHA-256 sovpadayet s zakreplyonnyim snimkom; absolyutnyiye mashinno-lokaljnyiye puti otsutstvuyut.
- Planovyij reyestr peresobran i validen; kartochnyij indeks i vetochnyij rabochij nabor proshli shtatnyiye proverki, a fenced `show` podtverdil novoye pokoleniye `master-fum-step-0026-ready-v1`.
- Polnota kornevogo tematicheskogo indeksa, recency Markdown, graf Obsidian, obratnyiye ssyilki voprosov, svyaznostj rabochej sessii, `git diff --check` i polnyij smoke-check podtverzhdenyi pered atomarnoj peredachej ocheredi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2b83415f88fb2390a1670157865e4f81043ad0a74d882e4cfa8417a2cf13e4c6 -->
<!-- FUM-MD-RECENCY:END -->
