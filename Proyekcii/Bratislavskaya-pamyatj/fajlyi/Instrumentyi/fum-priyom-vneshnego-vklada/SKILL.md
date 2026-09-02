---
name: fum-priyom-vneshnego-vklada
description: Prinimatj ot vneshnego agenta nedoverennyij paket predlozheniya iz arkhivirovannogo ChatGPT-share, proveryatj Git-bazu, manifest, khyesh, puti i konechnyiye obyyektyi i materializovyivatj kandidat bez izmeneniya checkout.
---

# Priyom vneshnego vklada

Kanonicheskoye russkoye imya avtomatizacii — `приём внешнего вклада`. Navyik svyazyivayet vneshnego agenta bez pishusjhego checkout s yedinstvennoj lokaljnoj kornevoj sessiyej FUM. Vneshnij agent proizvodit predlozheniye, no ne stanovitsya pisatelem `master`. Uspekh validatora ne oznachayet prinyatiye, kommit, push, prokhozhdeniye lokaljnyikh proverok ili razresheniye publikacii.

## Marshrut Web ChatGPT

1. Zafiksiruj publichnyij HTTPS-adres repozitoriya i polnyij OID opublikovannogo bazovogo kommita, kotoryij chitayet agent.
2. Peredaj [shablon zaprosa](shablon-zaprosa-vneshnemu-agentu.md). Finaljnoye tekstovoye soobsjheniye dolzhno soderzhatj rovno odnu ogradu `fum-внешний-вклад-v1` s polnyim paketom `fum.пакет-внешнего-вклада.v1`. Ssyilka `sandbox:/...`, perechenj fajlov, predpolagayemyij SHA i samootchyot o GitHub API ne zamenyayut paket.
3. V otdeljnoj lokaljnoj kornevoj zadache arkhiviruj share navyikom `fum-materialyi-zaprosov`, zatem proverj fajl soobsjhenij:

```bash
python3 Инструменты/fum-priyom-vneshnego-vklada/scripts/proveritj-paket-vneshnego-vklada.py \
  проверить-share \
  --корень-репозитория . \
  --запрос Журнал/<текущая-сессия>/запрос.md \
  --сообщения Источники/URL/https/chatgpt.com/share/<id>/chatgpt-share.messages.json \
  --выход-пакет Журнал/<текущая-сессия>/материалы/внешний-вклад/пакет.json \
  --выход-патч Журнал/<текущая-сессия>/материалы/внешний-вклад/предложение.patch \
  --выход-проверка Журнал/<текущая-сессия>/материалы/внешний-вклад/проверка.json
```

4. Prochitaj stdout i vse tri materiala. Toljko lokaljnaya kornevaya sessiya reshayet, kakiye stroki prinyatj, i sama formiruyet `Журнал/`, recency, indeksyi, `Proyekcii/**`, proverki i yedinstvennyij kommit. Push ostayotsya otdeljnyim yavnyim dejstviyem poljzovatelya.

Otdeljnyij JSON-paket proveryayetsya komandoj `проверить` s temi zhe `--корень-репозитория` i `--запрос`, obyazateljnyim `--пакет <пакет.json>` i neobyazateljnyim `--выход-патч` v tochnoye mesto tekusjhej sessii.

## Kontrakt versii 1

[Skhema JSON](skhemyi/paket-vneshnego-vklada-v1.schema.json) zadayot perenosimyij strukturnyij sloj. Validator ne ispolnyayet yeyo kak biblioteku: on sam zakryito proveryayet vse polya i dobavlyayet Git-invariantyi. Paket soderzhit UUID v4, `репозиторий`, utverzhdeniye, kriterii, ogranicheniya, otsortirovannyij manifest, chestnyiye statusyi proverok i patch razmerom ne boleye 256 KiB s Base64, iskhodnyim razmerom i SHA-256. Pered postroyeniyem patcha kazhdyij novyij nepustoj putj stavitsya v intent-to-add komandoj `git add -N -- <новые-пути>`; inache obyichnyij `git diff` yego ne uvidit. Zatem vyipolnyayetsya kanonicheskaya komanda `git -c core.quotePath=false diff --binary --full-index --no-renames --no-color --src-prefix=a/ --dst-prefix=b/ --no-ext-diff --no-textconv`; posle sokhraneniya tochnyikh bajtov intent-to-add mozhno ubratj komandoj `git reset -q -- <новые-пути>`. `Codex-Thread-ID` v paket ne vkhodit. Versiya 1 prinimayet toljko soderzhateljnyiye izmeneniya s obyichnyimi tekstovyimi hunks libo dvumya kanonicheskimi binary-fragments; pustoj fajl bez hunk i chistaya smena rezhima ostayutsya za yeyo predelami.

## Zakryitaya granica

Do lyuboj vyikhodnoj zapisi validator trebuyet:

- pervichnyij checkout na `refs/heads/master` i tochnoye sovpadeniye `HEAD`, lokaljno nablyudayemogo `origin/master` i bazyi paketa;
- tochnyij obyichnyij `Источники/URL/https/chatgpt.com/share/<id>/chatgpt-share.messages.json` bez simvolicheskikh ssyilok, sovpadeniye `<id>` s `source_url` arkhiva i otsutstviye izvestnyikh sekretov kak v syiryikh JSON-bajtakh, tak i posle dekodirovaniya JSON;
- HTTPS-adres `origin`, Base64, razmer, SHA-256, full-index OID i polnoye sovpadeniye manifesta s diff;
- UTF-8 i NFC, bezopasnyiye puti i obyichnyiye rezhimyi, bez path traversal, rename/copy, symlink, gitlink, upravlyayusjhikh Unicode-simvolov i NFC/casefold-kollizij mezhdu prefiksami predlozheniya libo s prefiksami bazovogo dereva;
- otsutstviye izvestnyikh signatur sekretov v metadannyikh, patche i konechnyikh raspakovannyikh obyyektakh;
- sobstvennoye ogranichennoye dekodirovaniye Git Base85 i zlib oboikh binary-fragments do zapuska Git: dlya `literal` proveryayetsya tochnyij rezuljtat, dlya `delta` — razmer programmyi, razmeryi istochnika i rezuljtata i vesj potok copy/insert-komand; summarnaya raspakovka i rezuljtatyi kazhdogo napravleniya ogranichivayutsya nemedlenno;
- privyazku delta-istochnikov i reverse-rezuljtatov k fakticheskim razmeram bazovyikh blobs, a forward-rezuljtatov — k vyichislennyim Git razmeram novyikh blobs; do primeneniya proveryayutsya takzhe uzhe susjhestvuyusjhiye obyyektyi zayavlennyikh novyikh OID i konservativnaya verkhnyaya granica tekstovyikh rezuljtatov;
- ogranicheniye razmera fajlov, processornogo i wall-clock-vremeni dochernego Git i `cat-file --batch-check` do chteniya soderzhimogo;
- primenimostj patcha toljko vo vremennom `GIT_INDEX_FILE` i otdeljnom `GIT_OBJECT_DIRECTORY`, gde realjnaya baza obyyektov dostupna toljko dlya chteniya;
- tochnoye sovpadeniye kazhdogo binarnogo razdela s lokaljno regenerirovannyim kanonicheskim diff i vozvrat polnogo bazovogo dereva pri obratnom primenenii;
- ne boleye 8 MiB na kazhdyij bazovyij ili konechnyij obyyekt i 32 MiB summarno po putyam, raspakovannyim fragmentam i rezuljtatam kazhdogo napravleniya;
- vyikhodyi toljko po tochnyim imenam v `Журнал/<текущая-сессия>/материалы/внешний-вклад/`, privyazannyiye k tochnomu `запрос.md`.

Lyuboj komponent `.git*`, `.codex`, `.github`, `.obsidian`, lyuboj vlozhennyij `AGENTS.md`, a takzhe kornevyiye `Правила/агентов/**`, `Инструменты/**`, `Журнал/**`, `Источники/**`, `Proyekcii/**` i `Зависимости/**` zapresjhenyi. Validator vyizyivayet pryamoj i obratnyij `git apply --cached` toljko v izolirovannyikh vremennyikh indekse i baze obyyektov; realjnyiye checkout, index, refs, remote i `.git/objects` ne menyayutsya. Vyikhodnyiye fajlyi sozdayutsya bez perezapisi toljko posle polnoj proverki.

`проверка.json` svyazyivayet kandidat s SHA-256 arkhiva soobsjhenij, indeksom finaljnogo soobsjheniya, adresom share i khyeshami syirogo i kanonicheskogo paketa i patcha. Statusyi `применено`, `закоммичено` i `опубликовано` v nyom zavedomo lozhnyi: eto svideteljstvo proiskhozhdeniya, no ne kvitanciya prinyatiya.

## Boljshoj vklad i granica podtverzhdeniya

Patch boljshe 256 KiB peredayotsya cherez otdeljnyij fork/vetku i zakreplyonnyij neizmenyayemyij chernovik pull request, sozdannyij sredoj s write-dostupom, naprimer Codex web/cloud. Takoj PR ostayotsya nedoverennyim predlozheniyem i ne razreshayet avtomaticheskij merge.

Avtonomnyij nabor testov sinteziruyet strukturnyij share-arkhiv i proveryayet marshrut bez seti. Eto ne zhivoj canary Web ChatGPT. Iskhodnyij dialog sozdan do vvedeniya protokola i ne soderzhit paketa v1; yego predmetnyiye izmeneniya eta sessiya ne importiruyet.

## Proverki

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-priyom-vneshnego-vklada/tests \
  -p 'test_*.py'
```

## Istochniki trebovanij

- [iskhodnyij zapros](../../Zhurnal/2026-09-02_07-51-07_MSK_organizovatj-priyom-vneshnego-vklada/zapros.md)
- [arkhivirovannyij dialog «Modelj stroiteljstva sooruzhenij»](../../Istochniki/URL/https/chatgpt.com/share/6a97050e-9da8-83ed-b92c-a3850dd6486d/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 10:28:38 MSK -->
<!-- content-sha256: sha256:0c7d0aaed5e0d75b998a9efec04d5092b0250f31d15bd6a88f652293c21fa23b -->
<!-- FUM-MD-RECENCY:END -->
