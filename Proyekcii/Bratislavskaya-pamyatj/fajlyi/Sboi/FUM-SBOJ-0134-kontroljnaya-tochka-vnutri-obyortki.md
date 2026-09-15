+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0134"
"статус" = "активна"
+++
# Proverka kontroljnoj tochki vnutri aktivnoj obyortki

## Nablyudayemyij sboj

Chastnyij vyizov `check-session-coherence.py --контрольная-точка` vyipolnen vnutri otchyotnoj obyortki. Sam rezhim kontroljnoj tochki zapresjhayet aktivnyiye zapisi, poetomu korrektno otklonil zapisj, sozdannuyu obyortkoj etogo vyizova. Proveryayusjhiye instrumentyi, kod postavki i snimki ne povrezhdenyi.

## Granica povtoreniya

Nesoglasovannyij vyibor rezhima proverki s zhiznennyim ciklom yeyo otchyotnoj obyortki. Eto ne osirotevshaya zapisj 0056, izmeneniye vkhoda 0043 ili propusk proverki indeksa 0044. Obyichnaya adresnaya proverka vnutri obyortki i otdeljnaya zaklyuchiteljnaya proverka kontroljnoj tochki imeyut raznyiye usloviya.

## Proyavleniya

### FUM-SBOJ-0134/PROYAVLENIYE-0001

[Otkaz 24](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/zapuski-proverok/24_786dbe93-045e-4893-b215-02dc07b4e78f.json) zavershilsya kodom 1 za 43.649792917 s s prichinoj «kontroljnaya tochka zapresjhena pri aktivnyikh zapisyakh». [Uspekh 25](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/zapuski-proverok/25_39fe58ff-9410-431a-88dd-4179f336c42f.json) podtverdil tot zhe otpechatok shtatnyim rezhimom za 43.969157125 s. [Nablyudeniye](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/nablyudeniye-rezhima-svyaznosti.json) svyazyivayet zapisi, SHA zhurnalov i neizmennostj proveryayusjhikh iskhodnikov otnositeljno HEAD. Oba iskhoda sokhranenyi.

## Ozhidaniye i klassifikaciya

Vnutri aktivnoj obyortki ispoljzuyetsya obyichnyij rezhim svyaznosti. `--контрольная-точка` primenyayetsya k otdeljnoj zaklyuchiteljnoj proverke razreshyonnogo checkpoint posle terminalizacii zapisej i obnovleniya predprosmotra. Nomer vyidelen koordinatorom po sobyitiyu `context-checkpoint-coherence-inside-wrapper-01a0930d-run24`.

## Mekhanizm i sistemnoye ustraneniye

Iz chastnogo vyizova ubran nepodkhodyasjhij flag. Povtor proshyol na tom zhe kanonicheskom snimke; biblioteka ne izmenyalasj. Eto vosstanovleniye tekusjhego vyizova. Nuzhen proverennyij sposob vyibora dvukh rezhimov po sostoyaniyu otchyota do zapuska dliteljnoj svyaznosti, bez oslableniya zapreta aktivnoj zapisi dlya kontroljnoj tochki.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — osnovaniye `FUM-СБОЙ-0134/ПРОЯВЛЕНИЕ-0001`.

## Kriterii zakryitiya

Opisaniye i proveryayemyij primer vyibora rezhima razlichayut obyichnyij vyizov vnutri obyortki i otdeljnuyu zaklyuchiteljnuyu checkpoint-proverku. Nesovmestimyij vyibor vyiyavlyayetsya do dorogogo obkhoda; iskhodnyiye pravila aktivnogo i zakryitogo otchyota sokhranyayutsya. Odin uspeshnyij ispravlennyij vyizov ne obyyavlyayetsya obsjhej profilaktikoj.

## Istochniki

- [Komanda raspredeleniya i zapros](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/zapros.md).
- [Otchyot i sokhranyonnyiye iskhodyi](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 03:22:57 MSK -->
<!-- content-sha256: sha256:fbecc3351fc0f18df8a0d2f99a48e9f63ddfdd66785b12950057b31cdc0f9db0 -->
<!-- FUM-MD-RECENCY:END -->
