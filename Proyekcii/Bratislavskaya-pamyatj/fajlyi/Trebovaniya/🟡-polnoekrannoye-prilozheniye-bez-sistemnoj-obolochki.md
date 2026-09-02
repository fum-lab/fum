# Polnoekrannoye prilozheniye bez sistemnoj obolochki

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0001 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) na Mac Studio dolzhna predostavlyatj cheloveku polnoekrannoye prilozheniye bez ramki okna, vnutri kotorogo nakhoditsya vesj osnovnoj [interfejs FUM-uzla](../Glossarij/interfejs-FUM-uzla.md). Posle vkhoda v rabochuyu sessiyu chelovek ne dolzhen nuzhdatjsya v Finder ili standartnom rabochem stole dlya obyichnogo vzaimodejstviya s [FUM](../Glossarij/FUM.md).

## Semanticheskiye svyazi

- **sostoit iz:** [otrisovki interfejsa cherez Metal](🟡-otrisovka-interfejsa-cherez-Metal.md) — graficheskij sloj prilozheniya ispoljzuyet apparatnyij putj Metal.
- **sostoit iz:** [GUI kak proyekcii vnutrennej pamyati i ispolneniya](🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md) — soderzhimoye i dejstviya interfejsa dolzhnyi proiskhoditj iz kanonicheskoj pamyati FUM, a ne iz paralleljnoj domennoj modeli obolochki.
- **sostoit iz:** [skryitiya Dock i stroki menyu](🟡-skryitiye-Dock-i-stroki-menyu.md) — otsutstviye vidimoj sistemnoj obolochki vklyuchayet skryitiye sistemnyikh panelej.
- **dopolnyayetsya:** [maksimaljno syiroj zapisjyu sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — poljzovateljskij kontur poluchayet vosproizvodimyij potok dejstvij cheloveka do ikh smyislovoj interpretacii.
- **trebuyetsya dlya:** [avtozapuska interfejsa](🟡-avtozapusk-interfejsa.md) — yavlyayetsya prilozheniyem, kotoroye dolzhen otkryitj mekhanizm avtozapuska.
- **trebuyetsya dlya:** [fonovogo servisa vyichislenij i vosstanovleniya interfejsa](🟡-fonovyij-servis-vyichislenij-i-vosstanovleniya-interfejsa.md) — yavlyayetsya interfejsom, sostoyaniye kotorogo servis nablyudayet i vosstanavlivayet.
- **trebuyetsya dlya:** [upravlyayemogo zhyostkogo kiosk-rezhima](🟡-upravlyayemyij-zhyostkij-kiosk-rezhim.md) — yavlyayetsya prilozheniyem, v kotorom kiosk-rezhim uderzhivayet cheloveka.

## Kriterii proverki

- prilozheniye zanimayet dostupnuyu oblastj kazhdogo naznachennogo ekrana bez standartnoj ramki okna;
- osnovnoj rabochij scenarij vyipolnyayetsya vnutri prilozheniya;
- vyikhod k sistemnoj srede ostayotsya vozmozhen toljko cherez yavno predusmotrennyij administrativnyij putj.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano, proverennaya realizaciya yesjhyo ne podtverzhdena. Trebovaniye nachinayetsya posle zapuska poljzovateljskoj sessii i ne rasprostranyayetsya na zagruzochnyij ekran, Recovery i boot picker.

## Istochniki trebovanij

- [iskhodnyij zapros](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [razdel «Polnostjyu kastomnyij interfejs poverkh macOS»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md#полностью-кастомный-интерфейс-поверх-macos)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f9cbae61e7d0a342b0d970f2311238fbbe7106ba7487a8b26be452c3b22735e3 -->
<!-- FUM-MD-RECENCY:END -->
