---
name: fum-pochinka-avtozapuska
description: Istoricheskij kontrakt snyatogo instrumenta pochinki avtozapuska; sokhranyayetsya dlya chteniya prezhnikh sostoyanij i lokaljnyikh regressionnyikh testov, no ne razreshayet sozdaniye zadach ili izmeneniye host-avtomatizacij.
---

# Pochinka avtozapuska

Instrument vyiveden iz ekspluatacii vmeste s periodicheskim heartbeat, postoyannoj zadachej dispetchera i marshrutami `Stop`/`Start`. On sokhranyayetsya kak istoricheskij kontrakt prezhnego repair-fence, host-snimkov i regressionnyikh fikstur. Etot navyik ne razreshayet vyizyivatj `create_thread`, menyatj ili zapuskatj host-avtomatizaciyu, sozdavatj remontnuyu rezervaciyu, privyazyivatj ispolnitelya libo vyipolnyatj inoj zhivoj effekt.

Dejstvuyusjhij marshrut ne chinit avtozapusk, potomu chto avtozapusk boljshe ne yavlyayetsya chastjyu rabochego kontura. V ruchnoj skheme `manual-sequential-v1` poljzovatelj sam zapuskayet odnu pishusjhuyu kornevuyu zadachu v pervichnom checkout; ona sozdayot ne boleye odnogo lokaljnogo kommita `master` i zavershayetsya bez continuation, FIFO-handoff i vetochnogo selector. Predshestvuyusjhij marshrut s exact [zadachej-prodolzheniyem vetki](../../Glossarij/obyazateljnoye-prodolzheniye-vetki.md) sokhranyayetsya toljko kak istoriya perekhoda.

Kanonicheskoye istoricheskoye nazvaniye — `починка автозапуска`, tekhnicheskij slug — `fum-pochinka-avtozapuska`. Sokhraneniye imeni obespechivayet ssyilki iz prezhnikh kommitov i ne oznachayet ekspluatacionnyij status.

## Sokhranyonnaya istoricheskaya sovmestimostj

Realizaciya, istoricheskaya spravka, izolirovannaya testovaya fikstura i testyi ostayutsya v kataloge `Инструменты/fum-pochinka-avtozapuska/`. Prezhnij protokol ispoljzoval checkout- i branch-scoped repair-ssyilku, odnorazovuyu host-granicu, kanonicheskij runtime-konvert i fazyi ot `зарезервирован` do `завершён`. Eti dannyiye sokhranyayut proiskhozhdeniye prezhnikh reshenij, no ne yavlyayutsya waiting-biletom prodolzheniya i ne dayut polnomochij na Git- ili host-effekt.

V dejstvuyusjhej rabochej sessii zapresjheno:

- vyizyivatj komandyi `зарезервировать`, `начать-вызов-среды`, `подтвердить-создание`, `bind-run`, `verify-run` ili `подтвердить-завершение-исполнителя` istoricheskogo instrumenta;
- ispoljzovatj yego renderer ili runtime-konvert dlya sozdaniya novoj zadachi;
- chitatj host-prostoj kak usloviye zapuska;
- obnovlyatj prompt prezhnej avtomatizacii, vyipolnyatj `Start`, sozdavatj zamenyayusjhij heartbeat ili otpravlyatj vosstanoviteljnoye soobsjheniye;
- vruchnuyu udalyatj otdeljnuyu repair-ssyilku kak sposob vosstanovleniya.

Susjhestvuyusjhaya host-avtomatizaciya prezhnego kontura dolzhna ostavatjsya ostanovlennoj. Yeyo snyatiye podtverzhdayet perekhod, no ne yavlyayetsya operaciyej etogo navyika. Neodnoznachnyij prezhnij host-rezuljtat issleduyetsya otdeljno i ne razreshayet povtor effekta.

Istoricheskiye repair-ssyilki ne udalyayutsya ad hoc. Ikh poglosjheniye ili arkhivirovaniye trebuyet otdeljnogo iskhodnogo zaprosa, polnogo inventarya, TDD-proverok i ograzhdyonnoj migracii. Chelovecheskij `./sbrositj.sh` ostayotsya otdeljnyim break-glass vsego lokaljnogo runtime-kontura i ne vozobnovlyayet avtozapusk.

## Proverka sovmestimosti

Avtonomnyiye testyi istoricheskoj realizacii ne trebuyut seti i mogut ispoljzovatjsya toljko kak lokaljnaya regressiya formatov. V rabochej sessii oni zapuskayutsya cherez [obyortku otchyotov o proverkakh](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) s tochnyim tekusjhim iskhodnyim zaprosom Zhurnala. Zelyonyij rezuljtat ne oznachayet, chto pochinka ili sam avtozapusk vnovj vvedenyi v ekspluataciyu.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [FUM-REQ-0041 — podtverzhdayemyij ruchnoj sbros FIFO k tekusjhemu HEAD](../../Trebovaniya/✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md)
- [iskhodnyij zapros o sozdanii instrumenta pochinki](../../Zhurnal/2026-08-05_22-56-33_MSK_proanalizirovatj-opyit-pochinki-i-sozdatj-instrument-pochinki-avtozapuska/zapros.md)
- [posledneye ispravleniye tochnoj skhemyi avtozapuska](../../Zhurnal/2026-08-05_21-02-54_MSK_ispravitj-avtozapusk/otchyot.md)
- [kontrakt FIFO-ocheredi](../fum-ocheredj-zadach-git-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:dec3b4af945aadfcd2a97bd7632c4035adc6ca5644fa894755b2108c011cdfd6 -->
<!-- FUM-MD-RECENCY:END -->
