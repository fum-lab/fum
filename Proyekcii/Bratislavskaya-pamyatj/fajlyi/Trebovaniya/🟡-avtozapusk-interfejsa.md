# Avtozapusk interfejsa

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0005 -->

Osnovnoye prilozheniye [FUM](../Glossarij/FUM.md) dolzhno avtomaticheski zapuskatjsya posle [vkhoda v vyidelennuyu uchyotnuyu zapisj](🟡-avtomaticheskij-vkhod-v-vyidelennuyu-uchyotnuyu-zapisj.md) cherez podderzhivayemyij mekhanizm login item ili `launchd`, ne trebuya ruchnogo otkryitiya Finder ili Terminal.

## Semanticheskiye svyazi

- **zavisit ot:** [avtomaticheskogo vkhoda v vyidelennuyu uchyotnuyu zapisj](🟡-avtomaticheskij-vkhod-v-vyidelennuyu-uchyotnuyu-zapisj.md) — zapusk nachinayetsya vnutri otkryitoj poljzovateljskoj sessii.
- **zavisit ot:** [polnoekrannogo prilozheniya bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — imenno eto prilozheniye yavlyayetsya celjyu avtomaticheskogo zapuska.
- **dopolnyayetsya:** [fonovyim servisom vyichislenij i vosstanovleniya interfejsa](🟡-fonovyij-servis-vyichislenij-i-vosstanovleniya-interfejsa.md) — avtozapusk otvechayet za pervoye otkryitiye, a servis za posleduyusjheye vosstanovleniye.

## Kriterii proverki

- chistaya zagruzka i vkhod privodyat k zapusku [polnoekrannogo interfejsa](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) bez dejstvij cheloveka;
- konfiguraciya avtozapuska khranitsya vosproizvodimo i ne soderzhit sekretov ili mashinno-zavisimyikh absolyutnyikh putej;
- obnovleniye prilozheniya ne sozdayot dubliruyusjhiyesya zadaniya;
- administrativnyij rezhim pozvolyayet vremenno otklyuchitj avtozapusk.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano; konkretnyij mekhanizm budet vyibran vmeste s modeljyu ustanovki i obnovleniya [korobochnoj realizacii FUM](../Glossarij/korobochnaya-realizaciya-FUM.md).

## Istochniki trebovanij

- [iskhodnyij zapros](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [razdel «Polnostjyu kastomnyij interfejs poverkh macOS»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md#полностью-кастомный-интерфейс-поверх-macos)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e7d9a754e9406bd8c9d918bef436f7c4e10a62416c46acc0805832baf235e869 -->
<!-- FUM-MD-RECENCY:END -->
