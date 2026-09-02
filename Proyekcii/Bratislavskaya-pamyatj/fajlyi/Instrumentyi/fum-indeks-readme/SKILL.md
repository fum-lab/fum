---
name: fum-indeks-readme
description: Proveryatj kompaktnostj kornevoj instrukcii tekusjhego ispoljzovaniya FUM i polnotu otdeljnogo tematicheskogo indeksa nomernoj dokumentacii.
---

# Kornevaya instrukciya i indeks dokumentacii FUM

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) uderzhivayet raznyiye poljzovateljskiye zadachi dvukh vkhodnyikh fajlov. Kornevoj `README.md` ostayotsya kratkoj aktualjnoj instrukciyej, a `Документация/README.md` khranit polnyij tematicheskij indeks nomernoj proizvodnoj dokumentacii.

Takoye razdeleniye zasjhisjhayet glavnyij vkhod v [pamyatj FUM](../../Glossarij/pamyatj-FUM.md) srazu ot dvukh vidov drejfa: instrukciya ne razduvayetsya vmeste s rostom dokumentacii, a novyij nomernoj dokument ne ischezayet iz polnoj tematicheskoj kartyi.

## Kontrakt kornevoj instrukcii

Kornevoj `README.md` obyazan:

- soderzhatj rovno odin vidimyij razdel vtorogo urovnya `## Как использовать FUM сейчас`;
- soderzhatj vidimuyu lokaljnuyu ssyilku s tochnyim registrom na `Документация/README.md`;
- ne soderzhatj vidimogo razdela `## Документация по темам`;
- zanimatj ne boleye `12 000` Unicode-simvolov vmeste so sluzhebnyim blokom `FUM-MD-RECENCY`.

Kommentarij, fenced- ili indented-blok i inline-kod ne delayut zagolovok ili ssyilku vidimyimi. Predel otnositsya k simvolam prochitannogo UTF-8-teksta, a ne k bajtam fajla; celevoj tekst ostavlyayet zapas dlya sluzhebnyikh metok svezhesti.

## Kontrakt polnogo indeksa

Obsjhij inventarj zadayot [fum-proyektnyiye-fajlyi](../fum-proyektnyiye-fajlyi/SKILL.md). Iz nego vyibirayutsya toljko dva vida vkhodov:

- verkhneurovnevyiye `Документация/NN-*.md`;
- kanonicheskiye `Документация/NN-*/README.md`.

`Документация/README.md` soderzhit rovno odin vidimyij razdel `## Документация по темам` i vnutri nego napryamuyu ssyilayetsya na kazhdyij obyazateljnyij vkhod. Celi razreshayutsya otnositeljno kataloga `Документация/`, poetomu obyichnaya ssyilka imeyet vid `00-обзор-проекта.md`, a papochnaya — `31-пользовательские-истории-FUM/README.md`.

Nenomernyiye dokumentyi i vlozhennyiye fajlyi nomernyikh papok, krome ikh `README.md`, v obyazateljnyij inventarj ne vkhodyat. Ssyilka v drugom razdele, kommentarii, bloke koda ili inline-kode propusk ne maskiruyet. Puti sravnivayutsya posle bezopasnoj URL-dekodirovki i leksicheskoj normalizacii, no s tochnyim registrom. Otsutstvuyusjhij ili povtoryonnyij tematicheskij razdel, oshibka obsjhego inventarya i lyuboj propusjhennyij putj ostanavlivayut proverku.

## Komanda

Iz kornya repozitoriya:

```bash
python3 Инструменты/fum-indeks-readme/scripts/check-readme-index.py \
  --repo-root .
```

Uspekh vozvrasjhayet kod `0` i chislo obyazateljnyikh i proindeksirovannyikh vkhodov. Narusheniye vozvrasjhayet kod `1`, diagnostiku kornevoj instrukcii i ustojchivyij otsortirovannyij spisok otsutstvuyusjhikh putej polnogo indeksa. Proverka nichego ne zapisyivayet, ne obrasjhayetsya k seti, ne ispoljzuyet sekretyi i ne zavisit ot tekusjhej datyi.

## TDD-proverki

Avtonomnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-indeks-readme/tests -p 'test_*.py'
```

Fiksturyi podtverzhdayut kompaktnuyu kornevuyu instrukciyu, yedinstvennostj tekusjhego scenariya, zapret polnogo indeksa v korne, vidimuyu ssyilku na otdeljnyij indeks, predeljnyij razmer i polnyij okhvat nomernyikh vkhodov. Otdeljno proveryayutsya otnositeljnaya baza ssyilok, URL-dekodirovaniye, leksicheskaya normalizaciya, tochnyij registr, nevidimyiye oblasti Markdown, novyiye dokumentyi i papochnyiye tochki vkhoda, stabiljnyij CLI-vyivod i tekusjhij repozitorij.

Proverka vkhodit yavnyim shagom v obsjhij [smoke-check](../fum-kompleksnaya-proverka-repozitoriya/SKILL.md), poetomu pered kommitom proveryayutsya i testyi validatora, i fakticheskoye razdeleniye dvukh README.

## Granica avtomatizacii

Avtomatizaciya proveryayet strukturu, vidimostj, razmer i nalichiye pryamyikh ssyilok. Ona ne ocenivayet ponyatnostj instrukcii, kachestvo tematicheskoj gruppirovki, nazvaniya ssyilok ili polnotu soderzhaniya dokumentov. Kornevoj README ostayotsya chelovekochitayemoj instrukciyej, a `Документация/` — istochnikom proizvodnoj dokumentacii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-06 15:14:50 MSK — Sdelatj README instrukciyej ispoljzovaniya FUM](../../Zhurnal/2026-08-06_15-14-50_MSK_sdelatj-README-instrukciyej-ispoljzovaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK — Aktualizirovatj vkhodnyiye opisaniya FUM](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 15:59:35 MSK -->
<!-- content-sha256: sha256:010320cbd4624a422d82d2444d17ac92fe3d7455e19ac56f1bca6c4ba3d650e5 -->
<!-- FUM-MD-RECENCY:END -->
