+++
schema_version = 1
card_id = "FUM-STEP-0136"
status = "active"
+++
# Ograditj proverochnyij khod ot pustogo scenariya orkestracii

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj strukturirovannuyu host- ili orkestracionnuyu granicu obyyavlennogo dochernego effekta, kotoraya otdeljno zakreplyayet klass effekta, podgotovlennyij vkhod i tekusjhuyu sessiyu i ne mozhet vernutj uspekh bez fakticheskogo ozhidayemogo vlozhennogo zapuska i sootvetstvuyusjhego yemu proveryayemogo rezuljtata.

## Pochemu sejchas

Dva proyavleniya FUM-SBOJ-0008 pokazali obe storonyi odnoj granicyi. Svobodnyij scenarij proverki zavershilsya srazu posle chastichnogo postroyeniya massiva komandyi bez `tools.exec_command`, a heartbeat peresyok dolgovechnuyu pre-effect-granicu, no ne treboval `await` u nested `create_thread`. Ruchnaya pravka konkretnogo prompt ne otlichayet vyipolnennyij dochernij effekt ot pustogo libo otbroshennogo Promise sistemno.

## Kriterii zaversheniya

- Krasnaya poddeljnaya host-fikstura vosproizvodit tochnyij scenarij FUM-SBOJ-0008 s konstantami puti i nepolnyim massivom komandyi bez vlozhennogo vyizova i pokazyivayet nyineshnij pustoj uspekh.
- Otdeljnaya krasnaya host-fikstura vosproizvodit `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0002`: dolgovechnaya pre-effect-granica peresechena, nested host-Promise ne ozhidayetsya, isolate zavershayetsya bez nablyudayemoj zadachi.
- Novyij interfejs do ispolneniya prinimayet zakryityij konvert s klassom effekta «uchtyonnaya proverka», tochnoj identichnostjyu sessii, nazvaniyem, ispolnitelem, predelom i nepustyim massivom dochernej komandyi.
- Lyuboj khod, zaraneye obyyavlennyij host- ili orkestratoru kak uchtyonnaya proverka, marshrutiziruyetsya toljko cherez konvert. Syiroj `functions.exec` ne mozhet otmetitj takoye namereniye zavershyonnyim; obkhod interfejsa libo otsutstviye vkhoda ostavlyayet yego nezavershyonnyim i vozvrasjhayet yavnyij otkaz.
- Svobodnyij JavaScript ne yavlyayetsya istochnikom obyazateljnyikh polej konverta i ne mozhet molcha udalitj dochernij vyizov; neizvestnoye pole, pustaya komanda i nepodtverzhdyonnaya sessiya otklonyayutsya do zapuska.
- Uspekh trebuyet rovno odin fakticheskij zapusk i terminaljnuyu mashinnuyu zapisj, svyazannuyu s konvertom i tekusjhim zaprosom; otsutstviye zapisi, aktivnoye sostoyaniye ili nesovpadeniye identichnosti dayut yavnyij otkaz.
- Pustoj scenarij, zabyityij `await`, rannij vyikhod, zaversheniye izolyata i otsutstviye publikacii rezuljtata pokryityi otdeljnyimi otricateljnyimi fiksturami.
- Dlya host-effekta polnyij vkhod gotov do pre-effect-zapisi, a uspeshnaya granica i rovno odin nested-vyizov yavno ozhidayutsya v odnom orchestration-vyizove bez promezhutochnogo vyivoda, vozvrata ili perekhoda modeli.
- Poterya otveta posle sozdannoj zapisi vosstanavlivayet tot zhe zapusk po ustojchivomu identifikatoru i ne povtoryayet dochernij process.
- Namerennyiye chistyiye vyichisleniya i read-only-kompozicii ispoljzuyut otdeljnyij klass bez obesjhannogo effekta i ostayutsya dopustimyimi.
- Avtonomnyiye testyi host-konverta i uchyota proverok, regressiya FUM-SBOJ-0008 i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0008 — Pustoj scenarij orkestracii proverki bez dochernego vyizova](../../Sboi/FUM-SBOJ-0008-pustoj-scenarij-orkestracii-proverki-bez-dochernego-vyizova.md) — osnovaniya `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0001` i `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0002`
- [iskhodnyij zapros o pochinke avtozapuska](../../Zhurnal/2026-08-11_13-03-53_MSK_pochinitj-avtozapusk-FUM/zapros.md)
- [otchyot o pochinke avtozapuska](../../Zhurnal/2026-08-11_13-03-53_MSK_pochinitj-avtozapusk-FUM/otchyot.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya uchyota proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-11 14:05:39 MSK -->
<!-- content-sha256: sha256:0256d3fa70a728c7d67ddff3c1296b26e65321f1703849c63a5a3893889f931e -->
<!-- FUM-MD-RECENCY:END -->
