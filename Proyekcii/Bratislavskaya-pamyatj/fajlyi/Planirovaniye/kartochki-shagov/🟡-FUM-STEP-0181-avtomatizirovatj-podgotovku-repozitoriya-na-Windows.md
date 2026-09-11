+++
schema_version = 1
card_id = "FUM-STEP-0181"
status = "active"
+++
# Avtomatizirovatj podgotovku repozitoriya na Windows

## Zadacha

Sozdatj avtomatizaciyu nastrojki repozitoriya i ustanovki vsekh instrumentov, neobkhodimyikh dlya vyibrannogo scenariya rabotyi s FUM na Windows, s yavnyim razlicheniyem nativnogo okruzheniya i WSL.

## Pochemu sejchas

Poljzovatelj poruchil zaplanirovatj podgotovku Windows. Susjhestvuyusjhiye lokaljnyiye avtomatizacii soderzhat platformennyiye predposyilki; gotovnostj Windows nuzhno podtverditj, a ne vyivoditj iz rabotosposobnosti macOS ili Linux.

## Kriterii zaversheniya

- Opredelena matrica vyipuskov i arkhitektur Windows i podderzhivayemyikh rezhimov rabotyi. Nativnyij Windows i WSL opisanyi kak otdeljnyiye profili s ponyatnyim vyiborom; ikh puti, repozitorii i instrumentyi ne smeshivayutsya neyavno.
- Ispoljzuyetsya obsjheye opisaniye instrumentov i proverok s macOS/Linux, a platformennyiye adapteryi opredelyayut proverennyiye istochniki i sposobyi ustanovki. Uzhe podkhodyasjhiye versii obnaruzhivayutsya; nepodderzhivayemyij instrument ili rezhim oboznachayetsya do izmenenij.
- Plan podgotovki pokazyivayet sostoyaniye Git, interpretatorov, SDK/toolchain i zavisimostej vyibrannogo profilya, mesto na diske i neobkhodimyiye dejstviya. Povyisheniye prav, vklyucheniye komponentov sistemyi i perezapusk imeyut otdeljnyiye yavnyiye etapyi; nezavershyonnyij etap ne vyidayot gotovnostj.
- Proverenyi puti s probelami i kirillicej, ogranicheniya dlinyi, registr, kodirovki, okonchaniya strok, vyipolneniye komand i platformennyiye blokirovki/atomarnaya zapisj. POSIX-zavisimyiye avtomatizacii otdeljno adaptirovanyi libo yavno ogranichenyi podderzhivayemyim profilem WSL.
- Nastrojka repozitoriya sokhranyayet poljzovateljskiye Git-parametryi, susjhestvuyusjhiye okruzheniya, nezakommichennyiye izmeneniya i chuzhiye rabochiye sessii. Materializuyutsya tochnyiye vneshniye zavisimosti; povtor i vosstanovleniye posle preryivaniya ne dubliruyut ustanovki i ne zatirayut dannyiye.
- Gotovnostj razlichayet perenosimyiye proverki FUM, podderzhivayemyiye paketyi i komponentyi, kotoryim trebuyetsya macOS. Sobstvennyiye iskhodniki i komandyi berutsya iz monorepozitoriya posle postavki FUM-STEP-0176; nedostupnostj platformennogo komponenta ne skryivayetsya.
- Proveren scenarij novoj sistemyi ili izolirovannoj virtualjnoj mashinyi i povtor v uzhe nastroyennom okruzhenii. Proverki iz chistogo klona soglasovanyi s vyibrannyim Windows- libo Linux-profilem GitHub Actions.
- Yestj RED/GREEN, scenarii otkaza i povtora, otkryityiye fiksturyi, profilj vremeni i resursov, resheniye ob optimizacii i statistika s proiskhozhdeniyem. Chelovek poluchayet ponyatnyij itog, spisok ostavshikhsya dejstvij i sposob povtornoj proverki.

## Svyazannyiye rabotyi i poryadok

Planirovaniye vyipolneno po pryamomu porucheniyu; realizaciya etim dokumentom ne obyyavlyayetsya nachatoj. Obsjhij pervyij etap novyikh avtomatizacij — opisaniye profilej sredyi i trebovanij proverok; platformennyiye adapteryi mozhno realizovyivatj nezavisimo posle soglasovaniya obsjhej chasti.

- [Avtomatizirovatj nastrojku GitHub Actions](🟡-FUM-STEP-0178-avtomatizirovatj-nastrojku-GitHub-Actions.md).
- [Avtomatizirovatj podgotovku repozitoriya na macOS](🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md).
- [Avtomatizirovatj podgotovku repozitoriya na Linux](🟡-FUM-STEP-0180-avtomatizirovatj-podgotovku-repozitoriya-na-Linux.md).
- [Dostavka sobstvennoj realizacii v monorepozitorij](✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

## Istochniki

- [Pryamoye porucheniye poljzovatelya i soderzhateljnyiye otvetyi](../../Zhurnal/2026-09-11_00-58-07_MSK_zaplanirovatj-podgotovku-Windows/zapros.md).
- [Dejstvuyusjhij reyestr instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md).
- [Susjhestvuyusjhij kontrakt kompleksnoj proverki](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:47:30 MSK -->
<!-- content-sha256: sha256:05a533f550428bbf47a03715ef93419e3c0becc17815571c02774b95920da5a7 -->
<!-- FUM-MD-RECENCY:END -->
