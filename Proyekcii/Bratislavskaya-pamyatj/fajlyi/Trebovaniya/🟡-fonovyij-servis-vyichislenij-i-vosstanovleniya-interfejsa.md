# Fonovyij servis vyichislenij i vosstanovleniya interfejsa

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0006 -->

Vyichisleniya, monitoring sostoyaniya i vosstanovleniye [polnoekrannogo poljzovateljskogo interfejsa](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) dolzhnyi vyipolnyatjsya otdeljnyim fonovyim servisom, chtobyi sboj graficheskogo processa ne ostanavlival vesj lokaljnyij [FUM](../Glossarij/FUM.md).

## Semanticheskiye svyazi

- **zavisit ot:** [polnoekrannogo prilozheniya bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — nablyudayet i vosstanavlivayet yego graficheskij process.
- **dopolnyayet:** [avtozapusk interfejsa](🟡-avtozapusk-interfejsa.md) — prodolzhayet obespechivatj dostupnostj interfejsa posle pervogo zapuska.

## Kriterii proverki

- vyichisliteljnyij servis prodolzhayet kontroliruyemuyu rabotu pri perezapuske UI;
- watchdog obnaruzhivayet zavisaniye ili avarijnoye zaversheniye interfejsa i perezapuskayet yego s ogranicheniyem chastotyi povtorov;
- obmen mezhdu UI i servisom imeyet yavnyij lokaljnyij kontrakt i minimaljnyiye prava;
- posle serii neudachnyikh perezapuskov sistema perekhodit v diagnostiruyemoye bezopasnoye sostoyaniye.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano. [Avtozapusk interfejsa](🟡-avtozapusk-interfejsa.md) otvechayet za pervyij zapusk posle vkhoda, a fonovyij servis — za posleduyusjheye nablyudeniye i vosstanovleniye. Granica processov, format IPC i politika sokhraneniya nezavershyonnoj rabotyi yesjhyo ne vyibranyi.

## Istochniki trebovanij

- [iskhodnyij zapros](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [razdel «Polnostjyu kastomnyij interfejs poverkh macOS»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md#полностью-кастомный-интерфейс-поверх-macos)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:127f0d3547359dce295327b280e233ab997f6afbe6b7bfcb1cbb388e5225b13e -->
<!-- FUM-MD-RECENCY:END -->
