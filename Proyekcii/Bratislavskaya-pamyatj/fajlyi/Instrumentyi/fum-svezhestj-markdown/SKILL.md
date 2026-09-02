---
name: fum-svezhestj-markdown
description: Obnovlyatj sluzhebnyiye metki poslednego soderzhateljnogo redaktirovaniya vo vsekh Markdown-fajlakh FUM i sobiratj indeks fajlov ot svezhikh k staryim.
---

# FUM MD Recency

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoraya podderzhivayet v kazhdom proyektnom Markdown-fajle [pamyati FUM](../../Glossarij/pamyatj-FUM.md) skryituyu sluzhebnuyu metku poslednego soderzhateljnogo redaktirovaniya i sobirayet obsjhij indeks etikh `.md`-fajlov ot svezhikh k boleye staryim.

Soderzhateljnyim schitayetsya izmeneniye teksta fajla bez uchyota samoj sluzhebnoj metki `FUM-MD-RECENCY`. V kanonicheskom `Журнал/<сессия>/отчёт.md` yedinstvennaya sintaksicheski tochnaya para `FUM-CHECK-RUNS` tozhe schitayetsya sluzhebnoj: izmeneniye tablicyi ili perekhod iz otkryitogo marker v zakryityij ne sdvigayet datu i indeks. Povrezhdyonnaya, nepolnaya ili povtornaya para otklonyayetsya. Dlya novogo ili ustarevshego otchyota avtomatizaciya zapisyivayet stabiljnyij khyesh bez etoj paryi, no prodolzhayet prinimatj neizmenyonnyij istoricheskij polnyij khyesh. Yesli khyesh ne izmenilsya, povtornyij zapusk ne obnovlyayet datu fajla.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu v kazhdoj [rabochej sessii](../../Glossarij/rabochaya-sessiya.md), vliyayusjhej na proyekt, posle vneseniya fajlovyikh pravok i pered proverkoj svyaznosti sessii.

Avtomatizaciya osobenno vazhna, kogda sessiya sozdayot ili redaktiruyet Markdown-fajlyi: `Документация/`, `Глоссарий/`, `Журнал/`, `Планирование/`, `Описания/`, `Источники/`, `Инструменты/` i kornevyiye `.md`-fajlyi.

## Komanda zapuska

```bash
python3 Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py
```

Komanda obnovlyayet:

- sluzhebnyij blok `FUM-MD-RECENCY` v konce kazhdogo Markdown-fajla;
- indeks [Markdown-fajlov po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md) s Markdown-tablicej v osnovnom Obsidian-stile: kolonki vyirovnenyi probelami v iskhodnike.

Mnozhestvo vkhodov zadayot obsjhaya avtomatizaciya [fum-proyektnyiye-fajlyi](../fum-proyektnyiye-fajlyi/SKILL.md): otslezhivayemyiye i novyiye neignoriruyemyiye proyektnyiye Markdown-fajlyi vklyuchayutsya, a `.build`, `.swiftpm`, katalogi kyeshej, `.obsidian/plugins` i `.obsidian/themes` ne chitayutsya, ne indeksiruyutsya i nikogda ne perepisyivayutsya. Strukturnyiye isklyucheniya dejstvuyut i pri `--no-git`; etot flag otklyuchayet toljko ispoljzovaniye Git-istorii dlya vyichisleniya vremeni.

Dlya proverki bez zapisi ispoljzuyetsya:

```bash
python3 Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py --check
```

## Pravilo vremeni

Yesli fajl uzhe soderzhit aktualjnuyu metku i yego soderzhateljnyij khyesh ne izmenilsya, data sokhranyayetsya.

Yesli fajl izmenyon soderzhateljno, sozdan zanovo ili yesjhyo ne soderzhit metki, data vyibirayetsya tak:

- dlya fajlov, izmenyonnyikh v tekusjhem rabochem dereve Git, ispoljzuyetsya vremya zapuska avtomatizacii;
- dlya chistyikh otslezhivayemyikh fajlov pri pervoj inicializacii ispoljzuyetsya data poslednego Git-kommita, kotoryij menyal fajl;
- yesli Git-istoriya nedostupna, ispoljzuyetsya vremya zapuska avtomatizacii.

## Proverki

Lokaljnyiye testyi avtomatizacii zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svezhestj-markdown/tests -p 'test_*.py'
```

Testyi fiksiruyut bazovyij kontrakt: avtomatizaciya dobavlyayet metki, sokhranyayet datu neizmenyonnyikh fajlov, stroit indeks v poryadke ot svezhikh fajlov k staryim, oformlyayet tablicu indeksa s vyirovnennyimi kolonkami, zamechayet ustarevshuyu metku v rezhime `--check` i pri pervoj inicializacii umeyet bratj datu chistogo otslezhivayemogo fajla iz Git-istorii. Otdeljnyiye fiksturyi podtverzhdayut stabiljnuyu svezhestj otchyota pri zamene toljko kanonicheskogo `FUM-CHECK-RUNS`, chteniye istoricheskogo polnogo khyesha, otkaz pri povrezhdyonnoj ili povtornoj pare marker-strok, uspeshnuyu proverku neizmennogo snimka na sleduyusjhij kalendarnyij denj i to, chto `.build/checkouts/vendor/README.md`, `.swiftpm` i kyeshi ne stanovyatsya vkhodami i ne izmenyayutsya.

## Granica avtomatizacii

Skript ne opredelyayet smyislovuyu cennostj izmeneniya. On toljko podderzhivayet mashinno proveryayemoye vremya poslednego soderzhateljnogo redaktirovaniya i indeks Markdown-fajlov. Agent po-prezhnemu otvechayet za korrektnostj soderzhaniya, publikacionnuyu chistotu, ssyilki na istochniki trebovanij i polnotu fajla iskhodnogo zaprosa.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../../Zhurnal/2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-15 00:47:22 MSK -->
<!-- content-sha256: sha256:aaed99e1769b57dc6083f2b4d43e79bdaf86b1cf958e90d2b2deb40d3acdb1f3 -->
<!-- FUM-MD-RECENCY:END -->
