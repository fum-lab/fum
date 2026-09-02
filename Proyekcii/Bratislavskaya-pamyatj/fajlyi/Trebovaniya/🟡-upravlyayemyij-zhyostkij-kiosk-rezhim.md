# Upravlyayemyij zhyostkij kiosk-rezhim

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0007 -->

Yesli ustanovka [FUM](../Glossarij/FUM.md) dolzhna isklyuchatj vyikhod cheloveka k obyichnoj poljzovateljskoj sessii, ona dolzhna podderzhivatj upravlyayemyij zhyostkij kiosk-rezhim cherez MDM i Autonomous Single App Mode, a ne imitirovatj blokirovku toljko [polnoekrannyim oknom](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md). [Skryitiye Dock i stroki menyu](🟡-skryitiye-Dock-i-stroki-menyu.md) ostayotsya vizualjnoj meroj i samo po sebe ne obespechivayet takoye ogranicheniye.

## Semanticheskiye svyazi

- **zavisit ot:** [polnoekrannogo prilozheniya bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — kiosk-rezhim uderzhivayet cheloveka vnutri naznachennogo prilozheniya.
- **usilivayet:** [skryitiye Dock i stroki menyu](🟡-skryitiye-Dock-i-stroki-menyu.md) — dobavlyayet sistemnoye ogranicheniye k vizualjnomu skryitiyu obolochki.

## Kriterii proverki

- rezhim vklyuchayetsya toljko na upravlyayemom i yavno naznachennom ustrojstve;
- posle vklyucheniya poljzovatelj ostayotsya vnutri razreshyonnogo prilozheniya;
- administrator mozhet udalyonno ili lokaljno zavershitj kiosk-rezhim po dokumentirovannoj procedure;
- poterya MDM-dostupa i sboj prilozheniya imeyut proverennyij putj vosstanovleniya.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: uslovnoye trebovaniye prinyato kak zaplanirovannaya vozmozhnostj, no neobkhodimostj zhyostkogo kiosk-rezhima dlya pervogo prototipa yesjhyo ne podtverzhdena. Ono ne rasprostranyayetsya na zagruzochnuyu cepochku, Recovery i boot picker Apple.

## Istochniki trebovanij

- [iskhodnyij zapros](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [razdel «Polnostjyu kastomnyij interfejs poverkh macOS»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md#полностью-кастомный-интерфейс-поверх-macos)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:22233ee157c74fdc9ce3509b9d9754f86b8f9ba83adda7484b8c8126145589df -->
<!-- FUM-MD-RECENCY:END -->
