# Istoriya: vesti svyaznuyu pamyatj FUM

Uchastniku razvitiya [FUM](../../Glossarij/FUM.md) nuzhna pamyatj, v kotoroj iskhodnoye namereniye, ispoljzovannyiye materialyi, proizvodnyiye resheniya, proverki i prodolzheniya ne raspadayutsya na nesvyazannyiye soobsjheniya i fajlyi. Poljzovatelj dolzhen imetj vozmozhnostj vernutjsya k rezuljtatu spustya neskoljko rabochikh sessij, ponyatj yego proiskhozhdeniye i prodolzhitj rabotu bez skryitoj zavisimosti ot prezhnego kontekstnogo okna modeli.

Cennostj istorii sostoit ne v nakoplenii maksimaljnogo obyyoma dannyikh, a v sokhranenii proveryayemoj prichinnoj cepochki. [Pamyatj FUM](../../Glossarij/pamyatj-FUM.md) dolzhna razlichatj pervichnyij golos cheloveka, proizvodnyij tekst agenta, podtverzhdyonnyiye rezuljtatyi, otkryityiye voprosyi, proverki i Git-srez, iz kotorogo vyiroslo sleduyusjheye pokoleniye rabotyi.

## Poljzovateljskaya istoriya

Kak uchastnik proyekta FUM, ya khochu peredatj namereniye ili material odin raz i poluchitj svyaznoye obnovleniye pamyati s proiskhozhdeniyem, proverkami i navigaciyej, chtobyi pozdneye ya ili drugoj dopusjhennyij uzel mogli vosstanovitj smyisl izmeneniya i bezopasno prodolzhitj yego.

## Osnovnoj scenarij

1. Poljzovatelj peredayot namereniye, vopros ili material i zadayot dostupnyiye ogranicheniya publikacii i ispoljzovaniya.
2. FUM sokhranyayet iskhodnyij zapros doslovno, a prikreplyayemyij material — v razreshyonnoj ustojchivoj forme s proiskhozhdeniyem.
3. FUM chitayet otnosyasjhiyesya k zadache dokumentyi i otdelyayet pervichnyij istochnik ot sobstvennoj interpretacii i proizvodnyikh utverzhdenij.
4. FUM obnovlyayet dokumentaciyu, glossarij, voprosyi, planirovaniye ili drugiye sloi pamyati toljko po smyislu zadachi i svyazyivayet rezuljtat s istochnikami.
5. FUM zapuskayet primenimyiye lokaljnyiye proverki, sokhranyayet nablyudayemyiye rezuljtatyi i ne obyyavlyayet rabotu zavershyonnoj pri neproverennom ili neuspeshnom iskhode.
6. Rabochaya sessiya poluchayet chelovekochitayemyij zhurnal i publikacionno chistyij Git-srez; indeksyi i ssyilki pozvolyayut perejti ot rezuljtata k zaprosu, ogranicheniyam i proverkam.
7. Sleduyusjhaya sessiya nachinayet s prinyatoj pamyati i yavnogo prodolzheniya, ne polagayasj na nedostupnyij prezhnij chat ili skryityiye rassuzhdeniya modeli.

## Aljternativyi i otkazyi

- Yesli material privaten ili ogranichen, FUM ne perenosit yego v publichnuyu pamyatj; sokhranyayetsya toljko razreshyonnaya forma, metadannyiye ogranicheniya ili yavno podgotovlennoye obezlichennoye proizvodnoye predstavleniye.
- Yesli istochniki protivorechat drug drugu ili ne pozvolyayut odnoznachno izmenitj dokumentaciyu, FUM sokhranyayet raskhozhdeniye kak [otkryityij vopros](../../Glossarij/otkryityij-vopros.md), a ne vyibirayet skryito udobnuyu traktovku.
- Yesli vneshnij servis, modelj ili sostoyaniye neljzya vosproizvesti lokaljno, FUM fiksiruyet kontrakt, versiyu, vkhodyi, dostupnyij rezuljtat i granicu nevosproizvodimosti.
- Yesli proverka ne prokhodit, izmeneniye ostayotsya nezavershyonnyim: oshibka i prigodnaya dlya vozobnovleniya tochka sokhranyayutsya bez vyidachi chastichnogo rezuljtata za prinyatyij.

## Kriterii priyomki

- Doslovnyij zapros otdelyon ot proizvodnoj dokumentacii i svyazan s nej lokaljnyimi ssyilkami.
- Dlya kazhdogo prinyatogo soderzhateljnogo izmeneniya mozhno najti istochnik, zatronutyij material, proverku i rabochij Git-srez.
- Zhurnal obyyasnyayet rezuljtat i ogranicheniya bez neobkhodimosti chitatj vesj diff, no ne zamenyayet pervichnyiye materialyi i proverki.
- Proizvodnyiye indeksyi, grafyi i kyeshi vosstanavlivayutsya iz prinyatoj pamyati i ne stanovyatsya skryityim istochnikom istinyi.
- Otkazyi, raskhozhdeniya i ogranicheniya dostupa ostayutsya nablyudayemyimi i ne ischezayut za itogovyim rezyume.
- Prodolzheniye vozmozhno iz sokhranyonnyikh fajlov i istorii bez obyazateljnogo dostupa k prezhnemu kontekstnomu oknu.

## Granica primenimosti

Istoriya opisyivayet uzhe chastichno nablyudayemyij kontur dokumentacionnogo prototipa Git + Markdown + vneshnyaya agentskaya sessiya. Ona ne utverzhdayet, chto tekusjhij repozitorij yavlyayetsya polnoj pamyatjyu cheloveka ili gotovyim sobstvennyim runtime FUM, ne trebuyet sokhranyatj skryityiye rassuzhdeniya i ne dayot prava publikovatj lichnyiye libo ogranichennyiye materialyi. Istinnostj soderzhateljnyikh utverzhdenij ne sleduyet toljko iz celostnosti i proiskhozhdeniya zapisi.

## Status

Tekusjhij status: disciplina Git + Markdown + vneshnyaya sessiya Codex chastichno proveryayet svyaznostj, proiskhozhdeniye i vozobnovleniye pamyati na masshtabe rabochikh zadach.

Celevoj status: sobstvennyij runtime korobochnoj FUM sokhranyayet te zhe invariantyi proiskhozhdeniya, vosstanovleniya, dostupa i nablyudayemogo otkaza bez obyazateljnoj vneshnej agentskoj sessii.

## Istochniki trebovanij

- [iskhodnyij zapros o napolnenii poljzovateljskikh istorij FUM](../../Zhurnal/2026-07-28_10-56-30_MSK_napolnitj-poljzovateljskiye-istorii-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-03 08:43:45 MSK — Sozdatj razdel poljzovateljskikh istorij](../../Zhurnal/2026-07-03_08-43-45_MSK_sozdatj-razdel-poljzovateljskikh-istorij/zapros.md)

## Opornyiye dokumentyi

- [Modelj pamyati FUM](../01-modelj-pamyati-FUM.md)
- [Obzor proyekta FUM](../00-obzor-proyekta.md)
- [Arkhitektura FUM](../22-arkhitektura-FUM.md)
- [Interfejs FUM-uzla](../25-interfejs-FUM-uzla.md)
- [Proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)
- [Yazyikonejtraljnyij kanonicheskij protokol pamyati](../47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1b2a1436d9a409686f3e2183e408e0ae19f1f384cc624ff1ed1e3c0ab0d28686 -->
<!-- FUM-MD-RECENCY:END -->
