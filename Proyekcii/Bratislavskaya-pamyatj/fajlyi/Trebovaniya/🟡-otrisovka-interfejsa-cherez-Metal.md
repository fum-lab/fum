# Otrisovka interfejsa cherez Metal

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0002 -->

[Graficheskij sloj polnoekrannogo interfejsa](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) na Apple silicon dolzhen ispoljzovatj Metal neposredstvenno ili cherez UI-stek s podtverzhdyonnyim Metal-byekendom, chtobyi zadejstvovatj GPU bez programmnoj otrisovki kak osnovnogo puti.

## Semanticheskiye svyazi

- **yavlyayetsya chastjyu:** [polnoekrannogo prilozheniya bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — zadayot sposob realizacii yego graficheskogo sloya.
- **dopolnyayetsya:** [GUI kak proyekciyej vnutrennej pamyati i ispolneniya](🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md) — Metal zadayot graficheskij byekend, a proyekciya zadayot proiskhozhdeniye otobrazhayemogo sostoyaniya i obratnyikh dejstvij.

## Kriterii proverki

- osnovnoj graficheskij putj ispoljzuyet `CAMetalLayer`, Metal ili dokumentirovannyij Metal-byekend vyibrannogo UI-steka;
- diagnosticheskij progon podtverzhdayet sozdaniye Metal-ustrojstva i komandnoj ocheredi;
- pri otsutstvii Metal interfejs soobsjhayet ob ogranichennom rezhime, a ne nezametno vyidayot yego za polnyij apparatnyij rezhim.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano, UI-stek i izmerimyiye porogi proizvoditeljnosti yesjhyo ne vyibranyi. Metal otnositsya k GPU; dostup k Neural Engine i Media Engine trebuyet otdeljnyikh specializirovannyikh API.

## Istochniki trebovanij

- [iskhodnyij zapros](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [razdel «Polnostjyu kastomnyij interfejs poverkh macOS»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md#полностью-кастомный-интерфейс-поверх-macos)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:97ecf0a9749f197fe7da522a882d290bfed5f9cf06816dddf70d27ee611e0c19 -->
<!-- FUM-MD-RECENCY:END -->
