+++
schema_version = 1
card_id = "FUM-STEP-0180"
status = "active"
+++
# Avtomatizirovatj podgotovku repozitoriya na Linux

## Zadacha

Sozdatj avtomatizaciyu nastrojki repozitoriya i ustanovki vsekh instrumentov, neobkhodimyikh dlya vyibrannogo podderzhivayemogo scenariya FUM na Linux, na novoj libo chastichno podgotovlennoj sisteme.

## Pochemu sejchas

Poljzovatelj otdeljno poruchil zaplanirovatj podgotovku Linux. Nuzhna obsjhaya s macOS i Windows modelj zavisimostej s yavnoj platformennoj realizaciyej, chtobyi gotovnostj sredyi ne opredelyalasj predpolozheniyami agenta.

## Kriterii zaversheniya

- Opredelena podderzhivayemaya matrica distributivov, vyipuskov i arkhitektur, vklyuchaya pervyij vosproizvodimyij scenarij. Avtomatizaciya obnaruzhivayet sistemu i dostupnyij sposob ustanovki, a nepodderzhivayemoye sochetaniye soobsjhayet do izmenenij.
- Ispoljzuyetsya obsjheye opisaniye instrumentov i profilej FUM s macOS i Windows. Dlya kazhdoj zavisimosti zafiksirovanyi naznacheniye, sovmestimyiye versii, proveryayemyij istochnik i sposob podtverzhdeniya ustanovki; paketyi i komandyi ne dubliruyutsya v nezavisimyikh spiskakh.
- Predvariteljnaya proverka ocenivayet mesto, prava, setj, ustanovlennyiye instrumentyi i sostoyaniye repozitoriya. Plan otdelyayet gotovoye okruzheniye ot nuzhnoj ustanovki; povyishennyiye prava ispoljzuyutsya toljko dlya konkretnyikh neobkhodimyikh operacij.
- Nastraivayutsya Git, nuzhnyij Python, dostupnyij podderzhivayemyij Swift i zavisimosti vyibrannyikh proverok; materializuyetsya tochnyij LinguisticKit. Uchtenyi osobennosti fajlovoj sistemyi, registr imyon, kirillica, lokalj i okonchaniya strok.
- Susjhestvuyusjhiye poljzovateljskiye nastrojki, okruzheniya i nezakommichennyiye izmeneniya sokhranyayutsya. Povtor idempotenten, izmeneniye vkhodov trebuyet obnovitj plan; proverenyi preryivaniye, chastichnaya ustanovka i vosstanovleniye.
- Dostupnyij profilj Linux otdelyon ot komponentov, trebuyusjhikh API macOS. Otsutstviye vozmozhnosti sobratj macOS-prilozheniye ne skryivayetsya uspeshnyim rezuljtatom perenosimoj chasti. Sobstvennyiye komponentyi vklyuchayutsya po realjnoj postavke FUM-STEP-0176.
- Iz chistogo klona vosproizvodyatsya proverka instrumentov i vyibrannyij smoke; tot zhe scenarij prigoden dlya soglasovannogo Linux-okruzheniya GitHub Actions. Gotovnostj privyazana k versii opisaniya sredyi i tochnomu naboru proverok.
- Yestj RED/GREEN, otkryityiye fiksturyi i podtverzhdeniye na podderzhivayemoj sisteme, profilj pervichnogo/povtornogo zapuska, analiz optimizacii i statistika s proiskhozhdeniyem. Rukovodstvo pomogayet cheloveku ponyatj sostoyaniye, ustranitj prichinu otkaza i bezopasno povtoritj podgotovku.

## Svyazannyiye rabotyi i poryadok

[Konkretnaya postanovka Linux VM na macOS](../Linux-na-macOS.md) utochnyayet otdeljnyij scenarij: podgotovka vyibrannogo Linux-gostya po obsjhej modeli instrumentov i profilej FUM. Uspekh etogo scenariya ne zakryivayet shirokij shag; status active i prezhniye kriterii sokhranyayutsya.

Planirovaniye vyipolneno po pryamomu porucheniyu; realizaciya etim dokumentom ne obyyavlyayetsya nachatoj. Obsjhij pervyij etap novyikh avtomatizacij — opisaniye profilej sredyi i trebovanij proverok; platformennyiye adapteryi mozhno realizovyivatj nezavisimo posle soglasovaniya obsjhej chasti.

- [Avtomatizirovatj nastrojku GitHub Actions](🟡-FUM-STEP-0178-avtomatizirovatj-nastrojku-GitHub-Actions.md).
- [Avtomatizirovatj podgotovku repozitoriya na macOS](🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md).
- [Avtomatizirovatj podgotovku repozitoriya na Windows](🟡-FUM-STEP-0181-avtomatizirovatj-podgotovku-repozitoriya-na-Windows.md).
- [Dostavka sobstvennoj realizacii v monorepozitorij](✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

## Istochniki

- [Pryamoye porucheniye poljzovatelya i soderzhateljnyiye otvetyi](../../Zhurnal/2026-09-11_00-53-41_MSK_zaplanirovatj-podgotovku-Linux/zapros.md).
- [Dejstvuyusjhij reyestr instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md).
- [Susjhestvuyusjhij kontrakt kompleksnoj proverki](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:46:43 MSK -->
<!-- content-sha256: sha256:eaf1fe178634407910f1696e14e98ce77cbc783bb1ce9a292db51fb399794de8 -->
<!-- FUM-MD-RECENCY:END -->
