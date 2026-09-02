# Otchyot 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii

Arkhivator istochnikov FUM podtverzhdyon yedinstvennyim aktivnyim MVP. Dlya yego pervogo reliza zakreplyon odin skvoznoj scenarij priyomki, a dokumentacionnaya stadiya poluchila binarnyij kriterij vyikhoda i chestnyij status: posle uspeshnogo proverochnogo kontura tekusjhej sessii vyipolnenyi 2 iz 6 uslovij.

## Resheniye po MVP

Arkhivator ne priostanavlivayetsya. Dlya nego opredelyon produktovyij vkhod, a specializirovannyij rabochij skript, lokaljnyiye testyi i atomarnaya ustanovka povtornogo snimka uzhe susjhestvuyut. Ostavshijsya razryiv ogranichen obsjhej komandoj arkhivirovaniya ustojchivogo URL, avtonomnoj HTML/tekstovoj fiksturoj i skvoznoj proverkoj pervogo reliza. Tenevoj redaktor prodolzhenij i prototip fizicheskikh sostoyanij klavish ostayutsya poleznyimi komponentnyimi eksperimentami korobochnoj stadii, no ne zamenyayut vyibrannyij MVP.

Ostaljnyiye pyatj MVP-kandidatov sokhranyayutsya v planovoj pamyati bez aktivnogo statusa. Ikh razvitiye ne dolzhno vyitesnyatj pervyij priyomochnyij rubezh arkhivatora.

## Skvoznoj scenarij priyomki

Yedinstvennyij scenarij pervogo reliza — «obyichnyij HTML-URL prevrasjhayetsya v kanonicheskij istochnik i idempotentno perearkhiviruyetsya». Avtonomnyij test zapuskayet obsjhij vkhod `fum source archive` bez seti na ustojchivom fixture-URL i vremennom fajle zaprosa. Pervyij zapusk dolzhen sozdatj kanonicheskuyu URL-papku, ochisjhennyiye syirjyevyiye sloi, izvlechyonnyij tekst, `source-index.md`, `extraction-report.md`, tochnyij `snapshot-manifest.json` i odin nabor ssyilok iz zaprosa.

Povtornyij zapusk s obnovlyonnoj versiyej toj zhe fiksturyi ispoljzuyet tu zhe papku, ne dubliruyet ssyilki, udalyayet otsutstvuyusjhiye v novom manifeste upravlyayemyiye fajlyi i sokhranyayet publikacionnuyu chistotu. Etot kontrakt poka opisan, no yesjhyo ne realizovan obsjhim vkhodom i poetomu ne schitayetsya projdennyim.

## Kriterij vyikhoda stadii 01

Perekhod dopuskayetsya toljko posle odnovremennogo vyipolneniya vsekh shesti punktov: yedinstvennyij aktivnyij MVP, projdennyij skvoznoj acceptance, validnyij obsjhij proverochnyij kontur, aktualjnyiye vkhodnyiye opisaniya, pasport pervogo vertikaljnogo sreza korobochnoj stadii i otdeljnoye resheniye o nachale perekhoda. Tekusjhaya sessiya zakryivayet vyibor MVP i podtverzhdayet obsjhij proverochnyij kontur; chetyire ostaljnyikh punkta ostayutsya otkryityimi.

## Operativnaya ocheredj

1. Realizovatj obsjhij vkhod arkhivatora, avtonomnuyu HTML/tekstovuyu fiksturu i odin skvoznoj acceptance-scenarij pervogo reliza.
2. Obnovitj kornevoj README, avtomatizaciyu adresnyikh opisanij i opisaniye FUM dlya razrabotchikov, sokhraniv chestnyij publikacionnyij status.
3. Podgotovitj pasport dokumentacionnogo prototipa i pervogo perenosimogo vertikaljnogo sreza korobochnoj realizacii.

## Prodolzheniye

Zapisj `master` perevoditsya na zadachu ranga 1 so svezhim `step_id`. Claim uspeshnogo dispetcherskogo zapuska ne osvobozhdayetsya: pokoleniye smenyayetsya obnovleniyem zapisi shaga.

## Proverki

- Tochnaya para iskhodnogo shaga podtverzhdena fenced `show` do pervoj zapisi.
- Tri nezavisimyikh read-only audita podtverdili vyibor arkhivatora, checklist stadii i zavershayusjhuyu posledovateljnostj proverok; subagentyi zavershenyi bez zapisi.
- Planovyij JSON-reyestr peresobran i validen; tri operativnyikh ranga sleduyut v poryadke `1`, `2`, `3`.
- Projdenyi `23` avtonomnyikh testa `fum-branch-next-step` i `19` testov `fum-planning-registry`; novaya zapisj shaga validna, `git diff --check` ne vyiyavil oshibok.
- Pervyij polnyij smoke-check obnaruzhil ustarevshuyu proizvodnuyu teplovuyu kartu `.obsidian/graph.json`; ona peresobrana posle recency. Na okonchateljnom snimke svyaznostj sessii i vse `29` shagov polnogo smoke-check projdenyi.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [revjyu proyekta 2026-07-18](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)
- [MVP-kandidatyi FUM](../../Planirovaniye/MVP-kandidatyi/README.md)
- [stadiya 01](../../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:9f39732648a4c4b25d3daa189d28b667641bd7816143daef9cdac69734e00ee3 -->
<!-- FUM-MD-RECENCY:END -->
