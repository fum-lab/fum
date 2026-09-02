---
name: fum-obratnyiye-ssyilki-voprosov
description: Proveryatj dvunapravlennostj lokaljnyikh ssyilok mezhdu otkryityimi ili chastichno proyasnyonnyimi voprosami FUM i zayavlennoj zatronutoj dokumentaciyej.
---

# FUM Question Backlinks

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) sokhranyayet vidimostj nereshyonnyikh smyislovyikh zavisimostej. Kazhdaya lokaljnaya celj, zayavlennaya aktivnyim voprosom v razdele `## Затронутая документация`, dolzhna susjhestvovatj s tochnyim registrom puti i soderzhatj obratnuyu Markdown-ssyilku na etot vopros.

Proverka avtonomna: yej ne nuzhnyi setj, sekretyi i vneshniye servisyi. Istochnikom sostava aktivnyikh voprosov sluzhit [indeks voprosov](../../Voprosyi/README.md), a ne data, imya fajla ili svobodnyij tekst statusa vnutri voprosa.

## Kogda ispoljzovatj

Ispoljzuj avtomatizaciyu:

- posle dobavleniya, chastichnogo proyasneniya, perenosa ili zakryitiya voprosa;
- posle izmeneniya razdela `## Затронутая документация`;
- posle pravki proizvodnogo dokumenta, kotoryij zavisit ot otkryitoj neopredelyonnosti;
- pered kommitom kak chastj polnogo [smoke-check](../fum-kompleksnaya-proverka-repozitoriya/SKILL.md).

Pered dobavleniyem obratnoj ssyilki nuzhno proveritj fakticheskuyu smyislovuyu zavisimostj celevogo dokumenta. Validator podtverzhdayet strukturnuyu dvunapravlennostj, no ne opredelyayet, verno li vopros obyyavil celj i umestno li konkretnoye utverzhdeniye svyazano s neopredelyonnostjyu.

## Komanda proverki

Iz kornya repozitoriya:

```bash
python3 Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py
```

Dlya yavnogo kornya:

```bash
python3 Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py \
  --repo-root /путь/к/FUM
```

Uspeshnyij zapusk vozvrasjhayet kod `0` i pechatayet chislo aktivnyikh voprosov i zayavlennyikh celej. Lyubaya strukturnaya oshibka vozvrasjhayet kod `1` i vyivoditsya v `stderr`.

## Proveryayemyij kontrakt

Scenarij [check-question-backlinks.py](scripts/check-question-backlinks.py):

1. chitayet razdelyi `## Открытые вопросы` i `## Частично прояснённые вопросы` iz `Вопросы/README.md`, vklyuchaya zagolovki, oformlennyiye Markdown-ssyilkoj;
2. trebuyet, chtobyi kazhdaya indeksnaya ssyilka oboznachala yedinstvennyij Markdown-fajl neposredstvenno v `Вопросы/`;
3. trebuyet u kazhdogo aktivnogo voprosa rovno odin nepustoj razdel `## Затронутая документация`;
4. dlya kazhdoj lokaljnoj celi proveryayet susjhestvovaniye Markdown-fajla, otsutstviye symlink-komponentov i dublya, a takzhe tochnoye sovpadeniye registra vsekh komponentov puti;
5. trebuyet v celevom fajle khotya byi odnu lokaljnuyu Markdown-ssyilku obratno na vopros i takzhe proveryayet registr obratnogo puti;
6. ne primenyayet etot kontrakt k proyasnyonnyim voprosam.

Fragmentyi posle `#`, query-komponentyi i podpisi Markdown-ssyilok ne vliyayut na sopostavleniye fajlov. Ssyilki vnutri fenced-blokov koda, inline-code i HTML-kommentariyev, izobrazheniya i ekranirovannyij tekst ne schitayutsya svyazyami dokumentacii. Vneshniye URL i puti cherez symbolic link ne yavlyayutsya celyami dvunapravlennosti.

## Avtonomnyiye testyi

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-obratnyiye-ssyilki-voprosov/tests \
  -p 'test_*.py'
```

Fiksturyi pokryivayut otkryityij i chastichno proyasnyonnyij statusyi, otsutstvuyusjhuyu obratnuyu ssyilku, nesusjhestvuyusjhuyu celj, nesovpadayusjhij registr pryamogo i obratnogo puti, otsutstviye ili pustotu razdela celej, fenced-primeryi, ne-Markdown-fajlyi, symlink-celi, ignorirovaniye proyasnyonnogo voprosa i kodyi zaversheniya CLI.

## Granica avtomatizacii

Avtomatizaciya ne trebuyet, chtobyi lyubaya kontekstnaya ssyilka na vopros iz zaprosa, zhurnala, opisaniya ili drugogo materiala byila obyyavlena yego celjyu. Obyazateljnaya obratnaya svyazj voznikayet toljko iz yavno zayavlennoj lokaljnoj celi aktivnogo voprosa.

Proverka takzhe ne zamenyayet soderzhateljnyij audit. Yesli zayavlennaya celj fakticheski ne zavisit ot voprosa, nuzhno ispravitj sam vopros s sokhraneniyem proiskhozhdeniya resheniya, a ne dobavlyatj formaljnuyu ssyilku radi zelyonogo rezuljtata.

Tekusjhij proveryayemyij sintaksis svyazi — vstroyennaya Markdown-ssyilka s podpisjyu i otnositeljnyim putyom k `.md`-fajlu. Reference-style ssyilki i puti s neobyazateljnyimi sbalansirovannyimi skobkami ne vkhodyat v etot uprosjhyonnyij parser-kontrakt; obyazateljnyiye svyazi sleduyet zapisyivatj vstroyennoj ssyilkoj.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-20 23:08:44 MSK — Vosstanovitj obratnyiye ssyilki voprosov](../../Zhurnal/2026-07-20_23-08-44_MSK_vosstanovitj-obratnyiye-ssyilki-voprosov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:742dc338693642bca91b104b538aa898c8196cc9d1050ba2cddfd4a45c2a29c5 -->
<!-- FUM-MD-RECENCY:END -->
