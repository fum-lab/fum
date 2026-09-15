+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0106"
"статус" = "активна"
+++
# Poterya vvodnogo teksta pri obnovlenii navigacii

## Nablyudayemyij sboj

Pri sozdanii sleduyusjhego arkhivnogo etapa komanda start obnovila razdel navigacii predyidusjhego zaprosa i udalila vvodnyij abzac, oshibochno razmesjhyonnyij vnutri etogo upravlyayemogo razdela. Pervaya svyaznostj novogo etapa proshla; poterya obnaruzhena otdeljnoj sverkoj tochnogo diff do kommita. Istoricheskaya zapisj s poterej teksta ne opublikovana.

## Granica povtoreniya

Odin epizod perezapisi upravlyayemogo navigacionnogo bloka, vnutri kotorogo nakhoditsya dopolniteljnyij soderzhateljnyij tekst. Drejf H1 pri ruchnom zapolnenii otchyota — drugoj mekhanizm, uzhe opisannyij kartochkoj 0041; obsjhaya zadacha bezopasnogo zapolneniya shablonov mozhet obsluzhivatj oba nezavisimyikh scenariya.

## Proyavleniya

### FUM-SBOJ-0106/PROYAVLENIYE-0001

Iskhodnyij zapros etapa 01:02:01 vzyat iz kommita 57f291a72cca8b8b5624ebdc3f9e17eb6f2b62b3. Pri start etapa 01:55:13 novaya ssyilka sleduyusjhego zaprosa zamenila navigacionnyij razdel vmeste s vvodnyim abzacem. [Pervichnyiye fragmentyi do, posle i posle vosstanovleniya](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/materialyi/poterya-vvodnogo-abzaca.json) sokhranyayut tochnuyu granicu i SHA abzaca; [otchyot](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/otchyot.md) otdelyayet pervonachaljnyij uspeshnyij dopusk ot proverki ispravlennogo vkhoda.

### FUM-SBOJ-0106/PROYAVLENIYE-0002

Pri obyyedinenii arkhivnoj vetki s kornevoj rabotoj komanda repair povtorno udalila tot zhe vvodnyij abzac iz upravlyayemoj navigacii zaprosa 01:02:01. Avtomatizaciya zavershilasj kodom 0; nezavisimaya sverka s tochnyim vkhodyasjhim kommitom dfa04ed6c03ff3363d175e39f937f8aa118d993c obnaruzhila poteryu do kommita sliyaniya. Doslovnyiye poljzovateljskiye bloki i prochiye arkhivnyiye materialyi sokhranilisj. Abzac vosstanovlen iz etogo kommita i peremesjhyon posle H1 pered navigaciyej; [svideteljstvo s iskhodnyimi khyeshami i tochnyim tekstom](../Zhurnal/2026-09-12_05-27-53_MSK_obyyedinitj-arkhiv-fuma-s-kornevoj-rabotoj/materialyi/povtor-poteri-vvodnogo-abzaca.json) sokhranyayet razlichiye mezhdu uspekhom komandyi i sokhrannostjyu vsego dokumenta. Sistemnoye predotvrasjheniye poteri ostayotsya otkryityim.

## Ozhidaniye i klassifikaciya

Obnovleniye sosednikh navigacionnyikh ssyilok ne dolzhno molcha unichtozhatj soderzhateljnoye proiskhozhdeniye zaprosa. Nablyudayemaya nedorabotka vklyuchayet nevernoye razmesjheniye poyasneniya v upravlyayemom bloke i otsutstviye otkaza pri yego neodnoznachnom sostave. Doslovnyij poljzovateljskij tekst pod sobstvennyim zagolovkom ne izmenilsya.

## Vosstanovleniye i sistemnaya granica

Prezhnij abzac vosstanovlen doslovno iz HEAD; v novom zaprose poyasneniye pomesjheno posle H1 pered razdelom navigacii. Itogovyij diff predyidusjhego zaprosa ogranichen novoj ssyilkoj i shtatnoj svezhestjyu. Eto vosstanovleniye tekusjhikh dokumentov; avtomaticheskoye predotvrasjheniye analogichnoj poteri yesjhyo ne podtverzhdeno, poetomu kartochka ostayotsya aktivnoj.

## Proiskhozhdeniye identifikatora

Nomer 0106 vyidan obsjhim mekhanizmom rezervirovaniya s [tochnoj kvitanciyej](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/materialyi/rezerv-sboya.json). Predvariteljnoye imya sobstvennogo nekommichennogo chernovika soderzhalo zanyatyij nomer 0091; oshibka vyibora otnositsya k otdeljnomu mekhanizmu FUM-SBOJ-0050 i ne yavlyayetsya vtoryim proyavleniyem poteri abzaca.

## Svyazannyiye shagi

[Dejstvuyusjhij FUM-STEP-0168](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0168-sokhranyatj-mashinnyij-zagolovok-pri-zapolnenii-otchyota.md) dopolnen scenariyami `FUM-СБОЙ-0106/ПРОЯВЛЕНИЕ-0001` i `FUM-СБОЙ-0106/ПРОЯВЛЕНИЕ-0002` dlya sokhrannosti teksta pri obnovlenii karkasa. Novyij planovyij identifikator ne vyidelyalsya.

## Kriterii zakryitiya

Avtonomnyij RED/GREEN-scenarij vosproizvodit start s dopolniteljnyim abzacem vnutri navigacii i podtverzhdayet yego tochnoye sokhraneniye libo yavnyij otkaz do lyuboj zapisi. Obyichnaya para sosednikh ssyilok prodolzhayet obnovlyatjsya, doslovnyij zapros i chuzhiye razdelyi pobajtno sokhranyayutsya. Dokumentirovanyi upravlyayemaya granica i dopustimoye mesto vvodnogo teksta; sorazmernaya proverka i profilj otnosyatsya k prinyatomu izmeneniyu avtomatizacii.

## Istochniki

- [Zapros novogo arkhivnogo etapa](../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/zapros.md).
- [Kontrakt strukturyi papok zaprosov](../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 05:52:00 MSK -->
<!-- content-sha256: sha256:3372fec5ba913a504d1cf81b23b8d9efac3991c72edaf414648f2f22cbc8fe6c -->
<!-- FUM-MD-RECENCY:END -->
