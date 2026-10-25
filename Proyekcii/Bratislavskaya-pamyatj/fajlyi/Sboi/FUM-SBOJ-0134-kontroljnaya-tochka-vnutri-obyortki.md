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

### FUM-SBOJ-0134/PROYAVLENIYE-0002

V finansovom J6 [zapisj5](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/iskhodnaya-zapisj-5_d25cc923-4e6c-44cd-8a0f-8abb77351c17.json) zavershilasj kodom1 za34,729466209s: vnutri aktivnoj otchyotnoj obyortki oshibochno vyibran rezhim `--контрольная-точка`. [Zakhvachennyij otkaz](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/nablyudeniye-otkaza-5.json) sokhranyayet tochnuyu prichinu. Posle udaleniya flaga [obyichnaya svyaznostj](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/iskhodnaya-zapisj-6_8d50184a-97d3-469d-936b-ad976687905a.json) proshla na tom zhe otpechatke za34,370809459s. Eto vosstanovleniye vyizova, a ne finaljnaya priyomka finansovogo sreza ili sistemnaya profilaktika.

Nomer0002 [naznachen koordinatorom](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/naznacheniye-0134-0002.json); okonchateljnaya sverka207 refs vyipolnena po polnyim OID posle preduprezhdenij neodnoznachnyikh imyon. U0134 prochitanyi odna Git-versiya i17 rabochikh fajlov s0001. Setj i chastnyiye nezaregistrirovannyiye rezervyi vne proverki.

## Ozhidaniye i klassifikaciya

Vnutri aktivnoj obyortki ispoljzuyetsya obyichnyij rezhim svyaznosti. `--контрольная-точка` primenyayetsya k otdeljnoj zaklyuchiteljnoj proverke razreshyonnogo checkpoint posle terminalizacii zapisej i obnovleniya predprosmotra. Nomer vyidelen koordinatorom po sobyitiyu `context-checkpoint-coherence-inside-wrapper-01a0930d-run24`.

## Mekhanizm i sistemnoye ustraneniye

Iz chastnogo vyizova ubran nepodkhodyasjhij flag. Povtor proshyol na tom zhe kanonicheskom snimke; biblioteka ne izmenyalasj. Eto vosstanovleniye tekusjhego vyizova. Nuzhen proverennyij sposob vyibora dvukh rezhimov po sostoyaniyu otchyota do zapuska dliteljnoj svyaznosti, bez oslableniya zapreta aktivnoj zapisi dlya kontroljnoj tochki.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — osnovaniye `FUM-СБОЙ-0134/ПРОЯВЛЕНИЕ-0001`.

Osnovaniye aktualizacii STEP0174 — `FUM-СБОЙ-0134/ПРОЯВЛЕНИЕ-0002`: povtor podtverzhdayet neobkhodimostj rannego vyibora rezhima do dliteljnoj svyaznosti.

## Kriterii zakryitiya

Opisaniye i proveryayemyij primer vyibora rezhima razlichayut obyichnyij vyizov vnutri obyortki i otdeljnuyu zaklyuchiteljnuyu checkpoint-proverku. Nesovmestimyij vyibor vyiyavlyayetsya do dorogogo obkhoda; iskhodnyiye pravila aktivnogo i zakryitogo otchyota sokhranyayutsya. Odin uspeshnyij ispravlennyij vyizov ne obyyavlyayetsya obsjhej profilaktikoj.

## Istochniki

- [Komanda raspredeleniya i zapros](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/zapros.md).
- [Otchyot i sokhranyonnyiye iskhodyi](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/otchyot.md).

- [Registraciya povtoreniya0002](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 17:48:33 MSK -->
<!-- content-sha256: sha256:feee172c8804775f73d3ab22f72e5d51953a3d52b1bd9f46ce212a9e13efbcac -->
<!-- FUM-MD-RECENCY:END -->
