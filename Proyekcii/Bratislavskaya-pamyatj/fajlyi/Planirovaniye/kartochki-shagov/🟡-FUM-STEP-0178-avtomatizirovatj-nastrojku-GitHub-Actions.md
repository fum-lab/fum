+++
schema_version = 1
card_id = "FUM-STEP-0178"
status = "active"
+++
# Avtomatizirovatj nastrojku GitHub Actions

## Zadacha

Sozdatj avtomatizaciyu, kotoraya analiziruyet repozitorij, gotovit proveryayemyij plan nastrojki GitHub Actions, primenyayet soglasovannuyu konfiguraciyu i proveryayet fakticheskij rezuljtat CI. Pervyij scenarij — monorepozitorij FUM.

## Pochemu sejchas

Poljzovatelj poruchil zaplanirovatj avtomatizaciyu nastrojki GitHub Actions. V tekusjhem dereve net kataloga `.github` i podkhodyasjhej kartochki: nastrojka dolzhna statj vosproizvodimoj proceduroj, prigodnoj dlya sleduyusjhikh repozitoriyev.

## Kriterii zaversheniya

- Opredelenyi vkhodyi: tochnyij repozitorij i reviziya, trebuyemyiye proverki, platformyi i sobyitiya zapuska. Otchyot o tekusjhem sostoyanii otlichayet otsutstvuyusjhuyu nastrojku, prigodnuyu susjhestvuyusjhuyu i konflikt.
- Sukhoj plan pokazyivayet fajlyi i udalyonnyiye nastrojki s prichinami izmenenij. Primeneniye sveryayet iskhodnoye sostoyaniye; povtor ne sozdayot lishnego diff, a poljzovateljskiye workflows i nastrojki sokhranyayutsya. Proverenyi preryivaniye i bezopasnoye vozobnovleniye.
- Ispoljzuyetsya obsjheye opisaniye instrumentov i proverok s zadachami macOS, Linux i Windows. Podderzhivayemyiye versii i proiskhozhdeniye Actions fiksiruyutsya po proverennyim oficialjnyim istochnikam; obnovleniye menyayet ikh yavno.
- Dlya FUM vosproizvoditsya proverka tochnogo kommita iz chistogo checkout s zakreplyonnyim LinguisticKit i nuzhnyimi Swift/Python. Sostav dokumentacionnogo i polnogo profilej oboznachen otdeljno; sobstvennyiye paketyi FUMA podklyuchayutsya po faktu postavki FUM-STEP-0176.
- Oformlen proveryayemyij kontrakt CI bez vyimyishlennogo Codex-UUID i bez izmeneniya zakryitogo otchyota zadachi. Propusk svyaznosti sessii ne nazyivayetsya polnoj priyomkoj; sgenerirovannyiye rezuljtatyi sravnivayutsya s proveryayemyim kommitom, a otstayusjhaya proyekciya obnaruzhivayetsya.
- Polnomochiya workflow minimaljnyi i yavnyi; proverochnyij scenarij rabotayet bez sekretov. Razdelenyi doverennyiye i vneshniye PR, prava kyeshej i artefaktov. Izmeneniya udalyonnyikh politik, zasjhisjhyonnyikh vetok i sekretov predstavlenyi otdeljnyimi yavnyimi dejstviyami.
- Lokaljnaya validaciya otlichayetsya ot zhivogo zapuska. Dlya uspeshnogo, otkazavshego i nezavershyonnogo zapuska sokhranyayutsya commit, workflow, run/attempt, sobyitiye, ispolniteli, obyazateljnyiye jobs i ssyilki na rezuljtatyi.
- Yestj RED/GREEN, otkryityiye fiksturyi, profilj podgotovki i vyipolneniya, analiz optimizacii i statistika vyizovov s proiskhozhdeniyem. Rukovodstvo obyyasnyayet cheloveku zapusk, rezuljtat i ispravleniye oshibok bez chteniya realizacii.

## Svyazannyiye rabotyi i poryadok

Planirovaniye vyipolneno po pryamomu porucheniyu; realizaciya etim dokumentom ne obyyavlyayetsya nachatoj. Obsjhij pervyij etap novyikh avtomatizacij — opisaniye profilej sredyi i trebovanij proverok; platformennyiye adapteryi mozhno realizovyivatj nezavisimo posle soglasovaniya obsjhej chasti.

- [Avtomatizirovatj podgotovku repozitoriya na macOS](🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md).
- [Avtomatizirovatj podgotovku repozitoriya na Linux](🟡-FUM-STEP-0180-avtomatizirovatj-podgotovku-repozitoriya-na-Linux.md).
- [Avtomatizirovatj podgotovku repozitoriya na Windows](🟡-FUM-STEP-0181-avtomatizirovatj-podgotovku-repozitoriya-na-Windows.md).
- [Dostavka sobstvennoj realizacii v monorepozitorij](🟡-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

## Istochniki

- [Pryamoye porucheniye poljzovatelya i soderzhateljnyiye otvetyi](https://github.com/fum-lab/fum/blob/5c9806560fb9b52112ff8a7bc11888a1bb71f7aa/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_00-37-07_MSK_%D0%B7%D0%B0%D0%BF%D0%BB%D0%B0%D0%BD%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D1%83-GitHub-Actions/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md).
- [Dejstvuyusjhij reyestr instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md).
- [Susjhestvuyusjhij kontrakt kompleksnoj proverki](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:58:13 MSK -->
<!-- content-sha256: sha256:484ee73158231a4be2860b8ad33ec51e878c26e4fd24cc712cc82035d1a550c5 -->
<!-- FUM-MD-RECENCY:END -->
