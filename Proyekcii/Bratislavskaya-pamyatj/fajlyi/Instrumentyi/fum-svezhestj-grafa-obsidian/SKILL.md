---
name: fum-svezhestj-grafa-obsidian
description: Vruchnuyu stroitj neobyazateljnuyu lokaljnuyu teplovuyu kartu Obsidian; graph.json yavlyayetsya ignored poljzovateljskim sostoyaniyem i ne vkhodit v predkommitnyij kontur.
---

# FUM Obsidian Graph Recency

## Dejstvuyusjhij status

`.obsidian/graph.json` yavlyayetsya lokaljnyim ignored-sostoyaniyem Obsidian i ne vkhodit v Git-kommityi. Eta avtomatizaciya sokhranena kak yavnaya poljzovateljskaya utilita: yeyo zapuskayut toljko po otdeljnomu zaprosu na peresborku lokaljnoj teplovoj kartyi. Obyichnaya pishusjhaya sessiya ne vyizyivayet yeyo posle Markdown-recency, ne schitayet raskhozhdeniye blocker i ne menyayet `.obsidian/fum-recency-reference-date` toljko iz-za lokaljnogo grafa.

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoraya peresobirayet cvetovyiye gruppyi grafa Obsidian v `.obsidian/graph.json` kak teplovuyu kartu Markdown-uzlov po sluzhebnyim metkam `FUM-MD-RECENCY`.

Avtomatizaciya ne menyayet soderzhateljnyiye dokumentyi i ne vyichislyayet novoye vremya redaktirovaniya. Ona chitayet uzhe sokhranyonnyiye recency-metki, gruppiruyet `.md`-fajlyi po vozrastu i zapisyivayet v `colorGroups` poiskovyiye zaprosyi Obsidian vida `path:"..."`, chtobyi cvet primenyalsya k konkretnyim uzlam, a ne k sluchajnyim upominaniyam dat v tekste.

Mnozhestvo vkhodov zadayot obsjhaya avtomatizaciya [fum-proyektnyiye-fajlyi](../fum-proyektnyiye-fajlyi/SKILL.md). `.build`, `.swiftpm`, katalogi kyeshej, `.obsidian/plugins` i `.obsidian/themes` ne uchastvuyut v teplovoj karte, dazhe yesli soderzhat Markdown-fajlyi ili prinuditeljno otslezhivayutsya.

## Kogda ispoljzovatj

Istoricheski avtomatizaciya zapuskalasj posle `fum-svezhestj-markdown`, yesli rabochaya sessiya dolzhna byila sokhranitj ili proveritj cvetovuyu kartu grafa Obsidian. Etot predkommitnyij marshrut boljshe ne dejstvuyet; komandyi nizhe ostayutsya dlya otdeljnogo ruchnogo ispoljzovaniya i testov.

## Komanda zapuska

```bash
python3 Инструменты/fum-svezhestj-grafa-obsidian/scripts/build-obsidian-graph-recency.py
```

Komanda obnovlyayet:

- `collapse-color-groups` v `.obsidian/graph.json`, chtobyi blok grupp cveta byil raskryit;
- `colorGroups` v `.obsidian/graph.json`, zamenyaya prezhniye gruppyi na korzinyi teplovoj kartyi;
- `.obsidian/fum-recency-reference-date` s opornoj datoj kalendarnogo predstavleniya.

Dlya proverki bez zapisi ispoljzuyetsya:

```bash
python3 Инструменты/fum-svezhestj-grafa-obsidian/scripts/build-obsidian-graph-recency.py --check
```

Obnovleniye prinimayet yavnuyu opornuyu datu cherez `--today YYYY-MM-DD` libo ispoljzuyet tekusjhuyu datu MSK i sokhranyayet yeyo v proyektnom sidecar-fajle `.obsidian/fum-recency-reference-date`. Proverka bez `--today` povtorno ispoljzuyet sokhranyonnuyu datu, poetomu neizmennyij Git-snimok ne stanovitsya ustarevshim toljko iz-za nastupleniya sleduyusjhego dnya. Yavnyij `--today` pereopredelyayet sokhranyonnuyu datu i pozvolyayet proveritj ili peresobratj predstavleniye dlya drugogo kalendarnogo sreza.

Opornaya data khranitsya otdeljno ot `graph.json`, potomu chto Obsidian udalyayet neznakomyiye polya pri sokhranenii sobstvennogo sostoyaniya. Obyichnaya perezapisj nastroyek prilozheniyem ne unichtozhayet kalendarnyij yakorj avtomatizacii.

## Cvetovyiye korzinyi

Teplovaya karta stroitsya ot goryachikh svezhikh uzlov k kholodnyim staryim:

- `0 days` - fajlyi, izmenyonnyiye segodnya;
- `1 day` - fajlyi, izmenyonnyiye vchera;
- `2 days` - fajlyi, izmenyonnyiye dva dnya nazad;
- `3-4 days` - fajlyi, izmenyonnyiye tri-chetyire dnya nazad;
- `5 days` - fajlyi, izmenyonnyiye pyatj dnej nazad;
- `6 days` - fajlyi, izmenyonnyiye shestj dnej nazad;
- `7 days` - fajlyi, izmenyonnyiye semj dnej nazad;
- `8 days` - fajlyi, izmenyonnyiye vosemj dnej nazad;
- `9 days` - fajlyi, izmenyonnyiye devyatj dnej nazad;
- `10+ days` - boleye staryiye fajlyi.

Palitra idyot desyatjyu yavnyimi stupenyami ot krasnogo cherez oranzhevyij, zhyoltyij, zelyono-biryuzovyij i sine-biryuzovyij k sinemu, chtobyi perekhodyi mezhdu svezhimi i staryimi uzlami byili vizualjno plavneye. Dnevnaya detalizaciya pervogo desyatidnevnogo okna vyibrana potomu, chto tekusjhaya pamyatj FUM obnovlyayetsya chasto i dolzhna pokazyivatj razlichiya mezhdu sosednimi rabochimi sessiyami.

## Proverki

Lokaljnyiye testyi avtomatizacii zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svezhestj-grafa-obsidian/tests -p 'test_*.py'
```

Obsjhij smoke-check repozitoriya proveryayet testyi etoj istoricheskoj utilityi, no ne zapuskayet yeyo rezhim `--check` nad lokaljnyim `graph.json`. Sostoyaniye teplovoj kartyi proveryayetsya toljko pri otdeljnom ruchnom zaprose na etu utilitu.

## Granica avtomatizacii

Skript opirayetsya na poiskovyij sintaksis Obsidian i tekusjhij JSON-format `.obsidian/graph.json`. On sokhranyayet ostaljnyiye nastrojki grafa bez izmeneniya, no namerenno zamenyayet vesj spisok `colorGroups`, potomu chto teplovaya karta yavlyayetsya celjnyim rezhimom okrashivaniya.

Oba kanonicheskikh vyikhodnyikh fajla proveryayutsya do chteniya i zapisi: simvolicheskaya ssyilka, vyikhod za predelyi repozitoriya ili razresheniye v strukturno isklyuchyonnoye khranilisjhe ostanavlivayut avtomatizaciyu.

Yesli Obsidian izmenit format `graph.json` ili povedeniye poiskovyikh grupp, nuzhno obnovitj testyi i etot kontrakt pered izmeneniyem skripta.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../../Zhurnal/2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:3616f887abd45337c30c1062b36b980fceacc71cc347a91604047ff151cd051d -->
<!-- FUM-MD-RECENCY:END -->
