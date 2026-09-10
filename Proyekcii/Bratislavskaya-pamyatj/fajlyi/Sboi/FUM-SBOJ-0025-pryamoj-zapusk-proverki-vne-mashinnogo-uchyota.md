+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0025"
"статус" = "активна"
+++
# Pryamoj zapusk proverki vne mashinnogo uchyota

## Nablyudayemyij sboj

Odna adresnaya proverka oformleniya diff vyizvana cherez `exec_command` napryamuyu posle podgotovki komandyi s tochnyimi isklyucheniyami syiryikh HTML. Ona zavershilasj uspeshno, no obyazateljnaya obyortka ne sozdala zapisj etogo konkretnogo zapuska.

## Granica povtoreniya

Granica — ruchnaya sborka komandyi proverki, pozvolyayusjhaya zabyitj obyazateljnyij putj mashinnogo uchyota. Rezuljtat proverochnogo processa ne utrachen, odnako zakryityij snimok ne mozhet podtverditj polnotu vsekh pryamyikh vyizovov sessii.

## Proyavleniya

- **FUM-SBOJ-0025/PROYAVLENIYE-0001.** V [tekusjhej sessii](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md) instrumentaljnyij otvet pryamogo `git diff HEAD --check` s shestjyu tochnyimi isklyucheniyami pokazal kod 0 i wall-clock `0.234003917` s. Eti svedeniya perenesenyi v otdeljnoye nablyudeniye [otchyota](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/otchyot.md); oni ne vyidanyi za sozdannuyu obyortkoj zapisj.

## Vosstanovleniye i kriterij zakryitiya

Proverka povtoryayetsya cherez shtatnuyu obyortku. Povtor podtverzhdayet proveryayemoye sostoyaniye, no ne vosstanavlivayet propusjhennuyu zapisj zadnim chislom. Skhema zhurnala ne menyayetsya, mashinnoye svideteljstvo ne izgotavlivayetsya vruchnuyu. Do sistemnogo predotvrasjheniya obkhoda kartochka ostayotsya aktivnoj i svyazana s [FUM-STEP-0153](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0153-predotvrasjhatj-pryamyiye-proverki-vne-obyortki.md).

Kriterij zakryitiya — vosproizvodimaya mera, obnaruzhivayusjhaya ili predotvrasjhayusjhaya pryamoj proverochnyij vyizov do ispolneniya vne obyortki, s proverennoj granicej isklyuchenij dlya read-only-inventarya i zaklyuchiteljnogo zamyikaniya.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [Mashinnyij uchyot proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 20:27:55 MSK -->
<!-- content-sha256: sha256:1968c1f9928a11b55e8a625a23d31ff2ebcca8c700f7a9158703ef89dbec6c64 -->
<!-- FUM-MD-RECENCY:END -->
