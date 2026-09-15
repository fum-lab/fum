# Svyazj napravlenij razvitiya s Git-vetkami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0068 -->

Git-vetka, ispoljzuyemaya dlya razvitiya FUM, predstavlyayet otdeljnuyu liniyu napravleniya razvitiya i sokhranyayet istoriyu yeyo izmenenij i rezuljtatov. Svyazj s zadachami, gipotezami i planovyimi shagami vosstanavlivayetsya po proiskhozhdeniyu. Tekhnicheskoye imya ref i otdeljnyij kommit ne zamenyayut predmetnoye soderzhaniye napravleniya.

Eto ne zadayot tozhdestvo napravleniya, zadachi, kartochki, fizicheskogo worktree i Git-snimka i ne trebuyet sozdavatj vetku dlya kazhdoj planovoj rubriki. Modelj utochnyayet uzhe opisannuyu rolj vetki kak linii rabotyi.

## Semanticheskiye svyazi

- **zavisit ot:** [atomarnyikh kartochek planovyikh shagov](✅-atomarnyiye-kartochki-planovyikh-shagov.md) — chastj trebovaniya ob otobrazhenii na planovyiye shagi ispoljzuyet ikh ustojchivyiye identichnosti i istochniki; eto ne usloviye susjhestvovaniya lyubogo napravleniya.

## Kriterii proverki

- Primer ne vyivodit iz iskhodnoj komandyi obyazateljnuyu vetku dlya kazhdogo napravleniya ili vzaimno odnoznachnoye sootvetstviye napravlenij, zadach i vetok.
- Opisanyi predmetnaya identichnostj napravleniya, iskhodnyiye osnovaniya i svyazj s planovyimi shagami; imya Git-vetki samo po sebe ne schitayetsya polnyim opisaniyem ili razresheniyem rabotyi.
- Primer svyazi ukazyivayet identichnostj repozitoriya, polnyij ref i versiyu Git-snimka. Odinakovyiye korotkiye imena v raznyikh repozitoriyakh ne skleivayutsya bez osnovaniya.
- Utochneniye naznacheniya, pereimenovaniye vetki, neskoljko posledovateljnyikh zadach i obyyedineniye rezuljtatov sokhranyayut istoriyu svyazi; novaya modelj ne trebuyet molcha sozdavatj novyij shag ili novoye napravleniye posle kazhdogo kommita.
- Prinyatiye rezuljtata i fakticheskaya integraciya razlichayutsya. Kommit, susjhestvuyusjhaya vetka ili zakryitiye zadachi ne dokazyivayut vyipolnennostj vsego predmetnogo napravleniya.
- Otdeljno opredelenyi blizhajshij dokumentacionnyij rezuljtat i ostavshiyesya resheniya po otobrazheniyu svyazi. Planovaya svyazj ne obyyavlyayetsya uzhe realizovannyim mashinnyim kontraktom, dispetcherom ili sobstvennyim runtime.

## Status i granicyi

Status trebovaniya — `🟡`: svyazj prinyata na planirovaniye. V kachestve osnovyi ispoljzuyetsya susjhestvuyusjheye opisaniye vetki rabotyi; format dolgovechnogo otobrazheniya i yego avtomatizaciya yesjhyo ne prinyatyi.

Trebovaniye ne sozdayot Git-vetki i rabochiye derevjya, ne pereimenovyivayet ikh, ne zapuskayet zadachi i ne vozvrasjhayet otlozhennyiye FIFO, pool, continuation, fork/CAS libo avtomaticheskuyu integraciyu. Ikh samostoyateljnyiye trebovaniya i istoricheskiye statusyi sokhranyayutsya. Infrastrukturnyij FUM-STEP-0201 prinimayet i svyazyivayet postanovku, no ne poglosjhayet predmetnuyu modelj napravleniya.

## Opornyiye materialyi

- [Paralleljnaya rabota i sliyaniye](../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md).
- [Evolyucionnyiye cepochki i otbor](../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/06-evolyucionnyiye-cepochki-i-otbor.md).
- [Karta sootvetstvij Git-infrastrukturyi evolyucionnyikh cepochek](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md#karta-sootvetstvij).
- [Vetka rabotyi](../Glossarij/vetka-rabotyi.md).

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_08-30-29_MSK_prinyatj-svyazj-napravleniya-i-vetki/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:37:36 MSK -->
<!-- content-sha256: sha256:f81af7897f43a554f7e324af3da76697158484a29280f25ebb936e052c387477 -->
<!-- FUM-MD-RECENCY:END -->
