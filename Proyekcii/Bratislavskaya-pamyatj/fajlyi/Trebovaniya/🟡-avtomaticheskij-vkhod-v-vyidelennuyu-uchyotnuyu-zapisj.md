# Avtomaticheskij vkhod v vyidelennuyu uchyotnuyu zapisj

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0004 -->

Vyidelennaya ustanovka [FUM](../Glossarij/FUM.md) dolzhna umetj avtomaticheski vkhoditj v otdeljnuyu sistemnuyu uchyotnuyu zapisj, prednaznachennuyu dlya zapuska interfejsa i ne ispoljzuyemuyu kak povsednevnaya administrativnaya uchyotnaya zapisj.

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [avtozapuska interfejsa](🟡-avtozapusk-interfejsa.md) — predostavlyayet poljzovateljskuyu sessiyu, v kotoroj zapuskayetsya osnovnoye prilozheniye.

## Kriterii proverki

- posle shtatnoj zagruzki Mac otkryivayetsya naznachennaya rabochaya sessiya bez ruchnogo vyibora poljzovatelya;
- uchyotnaya zapisj imeyet toljko neobkhodimyiye prilozheniyu prava;
- administrativnyiye polnomochiya i dannyiye vladeljca ne vklyuchayutsya v rabochuyu uchyotnuyu zapisj;
- rezhim mozhno otklyuchitj cherez dokumentirovannyij administrativnyij putj.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano. Pered realizaciyej trebuyetsya otdeljnaya modelj ugroz, poskoljku avtomaticheskij vkhod oslablyayet zasjhitu lokaljnoj sessii pri fizicheskom dostupe.

## Istochniki trebovanij

- [iskhodnyij zapros](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [razdel «Polnostjyu kastomnyij interfejs poverkh macOS»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md#полностью-кастомный-интерфейс-поверх-macos)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:58db31f58deaac48e07409b36aa10adcfc8bcdbc3b238ba92dfcddfd96aa3fb9 -->
<!-- FUM-MD-RECENCY:END -->
