---
name: fum-audit-pokryitiya-voprosov-i-otvetov
description: Izvlekatj voprositeljnyiye predlozheniya iz doslovnyikh blokov iskhodnyikh zaprosov, sopostavlyatj ikh so ssyilkami kartochek Voprosyi i otvetyi/ i gotovitj spisok dlya ruchnoj smyislovoj proverki.
---

# Audit pokryitiya voprosov i otvetov

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) formiruyet vosproizvodimyij spisok voprositeljnyikh kandidatov dlya razdela [`Вопросы и ответы/`](../../Voprosyi%20i%20otvetyi/README.md). Ona otdelyayet mekhanicheski proveryayemuyu vyiborku i ssyilochnoye pokryitiye ot tryokh ruchnyikh reshenij: otnositsya li vopros neposredstvenno k susjhnosti FUM, dan li na nego soderzhateljnyij otvet i polezen li otvet kak samostoyateljnaya spravka.

Audit nichego ne ispravlyayet avtomaticheski. Nalichiye kandidatov yavlyayetsya shtatnyim rezuljtatom i vozvrasjhayet kod `0`; strukturno nedostovernyij vkhod zavershayet zapusk s kodom `1`.

## Komanda zapuska

Chelovekochitayemyij otchyot iz kornya repozitoriya:

```bash
python3 Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/scripts/audit-question-answer-coverage.py \
  --repo-root .
```

Mashinno chitayemyij otchyot skhemyi `fum.question-answer-coverage-audit.v1`:

```bash
python3 Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/scripts/audit-question-answer-coverage.py \
  --repo-root . \
  --json
```

Oba predstavleniya perechislyayut vse najdennyiye voprosyi, a ne toljko voprosyi bez kartochki. Dlya kazhdogo kandidata sokhranyayutsya tochnyiye putj i stroka iskhodnogo zaprosa, doslovnyij voprositeljnyij fragment, status ssyilochnogo pokryitiya, vse svyazannyiye kartochki i yavnyij perechenj ruchnyikh proverok.

## Proveryayemyij kontrakt

Scenarij [audit-question-answer-coverage.py](scripts/audit-question-answer-coverage.py):

1. chitayet kazhdyij tochnyij `Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название]>/запрос.md` i trebuyet rovno odin tochnyij razdel `## Текст запроса`;
2. yesli razdel soderzhit odin ili neskoljko fenced-blokov s yazyikom `text`, izvlekayet toljko ikh soderzhimoye; inache chitayet legacy-blockquote, a pri yego otsutstvii — syiroj tekst razdela;
3. ne prinimayet za granicu razdela H2-zagolovok, doslovno nakhodyasjhijsya vnutri fence;
4. nakhodit predlozheniya s konechnyim neekranirovannyim `?`, ne schitaya voprositeljnyiye znaki vnutri inline-code, HTML-kommentariyev, Markdown-adresov, bare URL i okonchaniya `?!`;
5. chitayet pryamyiye kartochki `Вопросы и ответы/*.md`, isklyuchaya `README.md`, i uchityivayet toljko vidimyiye lokaljnyiye ssyilki na tochnyiye fajlyi `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md` iz razdela `## Источники требований`;
6. razreshayet ssyilki po puti s dekodirovaniyem URL, udaleniyem query i fragment, proverkoj susjhestvovaniya i tochnogo registra;
7. determinirovanno sopostavlyayet kazhdyij vopros so vsemi kartochkami, kotoryiye ssyilayutsya na yego iskhodnyij zapros.

Yesli odin zapros soderzhit neskoljko voprosov, ssyilka kartochki otnositsya k zaprosu celikom i ne vyibirayet konkretnyij vopros. Poetomu i pokryityiye, i nepokryityiye stroki ostayutsya kandidatami ruchnoj proverki.

## Ruchnaya proverka rezuljtata

Dlya kazhdogo kandidata nuzhno nezavisimo reshitj:

- otnositsya li doslovnyij vopros neposredstvenno k prirode, ustrojstvu, svojstvam, principam, modeli, arkhitekture, povedeniyu ili granicam FUM;
- susjhestvuyet li soderzhateljnyij otvet, osnovannyij na pamyati FUM;
- polezna li otdeljnaya voprosno-otvetnaya kartochka kak povtorno chitayemaya spravka.

Sluzhebnyij vopros o repozitorii, rabochej sessii, dokumentacii, redaktore, instrumente ili versii sredyi ne stanovitsya voprosom o susjhnosti FUM iz-za formaljnogo `?`. Otsutstviye kartochki dlya takogo voprosa ne yavlyayetsya probelom pokryitiya celevogo razdela.

## Avtonomnyiye testyi

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/tests \
  -p 'test_*.py'
```

Fiksturyi pokryivayut tochnuyu granicu razdela, vnutrennij H2 v fence, fenced-, blockquote- i raw-formyi doslovnogo teksta, neskoljko poljzovateljskikh soobsjhenij, konechnuyu punktuaciyu, inline-code i URL, vidimostj i mesto source-ssyilki, isklyucheniye indeksnogo README, zapros s neskoljkimi voprosami, determinirovannyiye JSON- i chelovekochitayemyiye otchyotyi, a takzhe fail-closed otkaz pri otsutstvuyusjhem ili povtornom razdele.

## Granica avtomatizacii

Punktuacionnaya vyiborka ne yavlyayetsya lingvisticheskim dokazateljstvom voprositeljnoj semantiki. Ssyilochnoye pokryitiye takzhe ne dokazyivayet sootvetstviye konkretnogo voprosa konkretnomu otvetu, otnosheniye k susjhnosti FUM, soderzhateljnostj otveta ili samostoyateljnuyu poleznostj kartochki. Avtomatizaciya suzhayet korpus dlya proverki i sokhranyayet proveryayemoye proiskhozhdeniye, no okonchateljnoye resheniye ostayotsya ruchnyim smyislovyim dejstviyem cheloveka ili agenta.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/zapros.md)
- [iskhodnyij zapros 2026-07-10 06:46:29 MSK — Dopolnitj voprosyi i otvetyi po vsem zaprosam](../../Zhurnal/2026-07-10_06-46-29_MSK_dopolnitj-voprosyi-i-otvetyi-po-vsem-zaprosam/zapros.md)
- [iskhodnyij zapros 2026-07-13 15:20:42 MSK — Ogranichitj voprosyi i otvetyi susjhnostjyu FUM](../../Zhurnal/2026-07-13_15-20-42_MSK_ogranichitj-voprosyi-i-otvetyi-susjhnostjyu-FUM/zapros.md)
- [formaljnaya proverka voprosno-otvetnyikh materialov](../fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3ff39aa628660b3ab04747bc0e3a90b0e9944938c68a9a471c49a2ab74334f9b -->
<!-- FUM-MD-RECENCY:END -->
