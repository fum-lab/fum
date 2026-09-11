+++
schema_version = 1
card_id = "FUM-STEP-0179"
status = "active"
+++
# Avtomatizirovatj podgotovku repozitoriya na macOS

## Zadacha

Sozdatj avtomatizaciyu nastrojki repozitoriya i ustanovki vsekh instrumentov, neobkhodimyikh dlya vyibrannogo scenariya rabotyi s FUM na macOS. Obespechitj perekhod ot novoj libo chastichno podgotovlennoj mashinyi k proverennomu rabochemu okruzheniyu.

## Pochemu sejchas

Poljzovatelj poruchil zaplanirovatj nastrojku repozitoriya i ustanovku neobkhodimyikh instrumentov na macOS. Podgotovka rabochego dereva i zavisimostej dolzhna davatj proveryayemyij povtoryayemyij vkhod.

## Kriterii zaversheniya

- Yestj obsjheye deklarativnoye opisaniye obyazateljnyikh, uslovnyikh i neobyazateljnyikh instrumentov dlya chteniya, razrabotki, testirovaniya, proyekcii i komponentov FUMA. Trebovaniya svyazanyi s komandami i proverkami; perechenj ne podmenyon bezuslovnoj ustanovkoj vsego reyestra.
- Do izmenenij opredelyayutsya versiya macOS, arkhitektura, dostupnoye mesto, instrumentyi i ikh realjnyiye versii, SDK/toolchain, vyibrannyij repozitorij i yego sostoyaniye. Podderzhivayemyiye sochetaniya zakreplyayutsya po oficialjnyim istochnikam pri realizacii.
- Proveryayemyij plan obyyasnyayet, chto uzhe gotovo, chto ustanovitj ili nastroitj i kakoj komponent trebuyet dejstviya cheloveka. Ustanovka vyibirayet proverennyij istochnik, sokhranyayet rezuljtat i dopuskayet bezopasnoye prodolzheniye posle preryivaniya.
- Dlya FUM nastraivayutsya Git, nuzhnyiye Python i Swift/SDK, materializuyutsya tochnyiye submodule-zavisimosti. Tochnaya rabochaya kopiya, vetka i prava zapisi proveryayutsya; gryaznyij checkout, susjhestvuyusjhaya konfiguraciya i chuzhaya sessiya ne perezapisyivayutsya.
- Obsjhiye parametryi Git i ustanovki ogranichivayutsya yavno vyibrannoj oblastjyu. Susjhestvuyusjhiye poljzovateljskiye nastrojki, okruzheniya i prilozheniya sokhranyayutsya; povtor na podgotovlennoj mashine ne vnosit lishnikh izmenenij.
- Razlichenyi ustanovka instrumentov i poljzovateljskoye predostavleniye sistemnyikh razreshenij komponentam FUMA. Nuzhnyiye ruchnyiye shagi, licenzii ili perezapusk pokazyivayutsya kak nezavershyonnaya podgotovka, bez obkhoda mekhanizmov macOS.
- Proveren probnyij scenarij iz chistogo klona i v susjhestvuyusjhem rabochem dereve: dostupnostj komand, materializaciya zavisimostej i vyibrannyij smoke. Status gotovnosti privyazan k konkretnomu profilyu; macOS-prilozheniye proveryayetsya posle dostavki iskhodnikov v FUM-STEP-0176.
- Yestj adresnyiye RED/GREEN, scenarii sboya seti/mesta/versii i povtora, profilj vremeni i diska, resheniye ob optimizacii, zhurnal proiskhozhdeniya i statistika ruchnyikh i avtomaticheskikh vyizovov. Chelovek poluchayet ponyatnyij itog i komandu povtornoj proverki.

## Svyazannyiye rabotyi i poryadok

Planirovaniye vyipolneno po pryamomu porucheniyu; realizaciya etim dokumentom ne obyyavlyayetsya nachatoj. Obsjhij pervyij etap novyikh avtomatizacij — opisaniye profilej sredyi i trebovanij proverok; platformennyiye adapteryi mozhno realizovyivatj nezavisimo posle soglasovaniya obsjhej chasti.

- [Avtomatizirovatj nastrojku GitHub Actions](🟡-FUM-STEP-0178-avtomatizirovatj-nastrojku-GitHub-Actions.md).
- [Avtomatizirovatj podgotovku repozitoriya na Linux](🟡-FUM-STEP-0180-avtomatizirovatj-podgotovku-repozitoriya-na-Linux.md).
- [Avtomatizirovatj podgotovku repozitoriya na Windows](🟡-FUM-STEP-0181-avtomatizirovatj-podgotovku-repozitoriya-na-Windows.md).
- [Dostavka sobstvennoj realizacii v monorepozitorij](🟡-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

## Istochniki

- [Pryamoye porucheniye poljzovatelya i soderzhateljnyiye otvetyi](https://github.com/fum-lab/fum/blob/5c9806560fb9b52112ff8a7bc11888a1bb71f7aa/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_00-51-29_MSK_%D0%B7%D0%B0%D0%BF%D0%BB%D0%B0%D0%BD%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D1%83-macOS/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md).
- [Dejstvuyusjhij reyestr instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md).
- [Susjhestvuyusjhij kontrakt kompleksnoj proverki](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:58:13 MSK -->
<!-- content-sha256: sha256:712123d6e0381a7b2c3c75a8ac69188543a7e804c6e7348a330454828dc6a653 -->
<!-- FUM-MD-RECENCY:END -->
