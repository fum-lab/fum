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

- **FUM-SBOJ-0025/PROYAVLENIYE-0002.** V pervom etape 0176 planovyij generator zapusjhen napryamuyu posle podgotovki kartochki 0203 i vernul otkaz iz-za nevernogo znacheniya statusa indeksa. Obyazateljnaya obyortka ne sozdala zapisj iskhodnogo zapuska. [Adresnoye nablyudeniye](../Zhurnal/2026-09-11_02-13-44_MSK_integrirovatj-postavku-FUMA/materialyi/propusk-uchyota-0025.json) vosstanovleno chteniyem iskhodnogo vyizova i otveta JSONL; ono ne yavlyayetsya vruchnuyu izgotovlennoj kvitanciyej. [Pervyij otchyot](../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/otchyot.md) sokhranyayet ogranicheniye, uchtyonnyij povtor posle ispravleniya proshyol. Obsjheye sredstvo predotvrasjheniya i regressionnaya granica sovpadayut s pervyim proyavleniyem: proverochnyij generator dolzhen vkhoditj v obyortku do ispolneniya.

Povtor `FUM-СБОЙ-0025/ПРОЯВЛЕНИЕ-0002` aktualiziruyet shag 0153; rezuljtat povtornogo zapuska ne zakryivayet sistemnuyu prichinu.

## Vosstanovleniye i kriterij zakryitiya

Proverka povtoryayetsya cherez shtatnuyu obyortku. Povtor podtverzhdayet proveryayemoye sostoyaniye, no ne vosstanavlivayet propusjhennuyu zapisj zadnim chislom. Skhema zhurnala ne menyayetsya, mashinnoye svideteljstvo ne izgotavlivayetsya vruchnuyu. Do sistemnogo predotvrasjheniya obkhoda kartochka ostayotsya aktivnoj i svyazana s [FUM-STEP-0153](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0153-predotvrasjhatj-pryamyiye-proverki-vne-obyortki.md).

Kriterij zakryitiya — vosproizvodimaya mera, obnaruzhivayusjhaya ili predotvrasjhayusjhaya pryamoj proverochnyij vyizov do ispolneniya vne obyortki, s proverennoj granicej isklyuchenij dlya read-only-inventarya i zaklyuchiteljnogo zamyikaniya.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [Mashinnyij uchyot proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:47:10 MSK -->
<!-- content-sha256: sha256:4c52e2a194a6afe999dd5b14505e17beca820521e9a601af97c9dede926df8fa -->
<!-- FUM-MD-RECENCY:END -->
