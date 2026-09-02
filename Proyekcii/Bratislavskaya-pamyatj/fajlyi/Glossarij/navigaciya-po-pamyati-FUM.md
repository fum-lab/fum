# Navigaciya po pamyati FUM

Navigaciya po pamyati FUM - peremesjheniye cheloveka, agenta ili drugogo uzla po [pamyati FUM](pamyatj-FUM.md): otkryitiye dokumentov, perekhodyi po yavno zadannyim i operatorno predlozhennyim semanticheskim svyazyam, poisk, prokrutka, vyibor fragmentov, vozvrat k predyidusjhim mestam i drugiye dejstviya, kotoryiye menyayut vidimyij ili rabochij kontekst.

V arkhitekture [FUM](FUM.md) navigaciya po pamyati FUM dolzhna schitatjsya [nablyudayemyim vkhodnyim signalom](nablyudayemyij-vkhodnoj-signal.md) naravne s [iskhodnyim zaprosom](iskhodnyij-zapros.md). Vazhen ne toljko itogovyij otkryityij fragment [pamyati](pamyatj-FUM.md), no i sam putj: istochnik perekhoda, celevoj obyyekt, sposob vvoda, posledovateljnostj sobyitij i svyazj s posleduyusjhimi dejstviyami.

Ispolniteljnyij sloj, primenyaya [sistemu strukturiruyusjhikh operatorov FUM](sistema-strukturiruyusjhikh-operatorov-FUM.md), mozhet predlozhitj perekhod bez bukvaljnoj ssyilki v iskhodnom tekste. Takoj perekhod sokhranyayet iniciatora vyivoda, ispolniteljnyij kontur, primenyonnyij operator, iskhodnyiye fragmentyi i ikh proiskhozhdeniye, kontekst, uverennostj i status proverki, chtobyi kandidatnaya svyazj ne vyiglyadela kak podtverzhdyonnoye znaniye.

## Svyazannyiye dokumentyi

- [Dostup k vnutrennim sostoyaniyam](../Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../Dokumentaciya/06-obzor-agentskikh-ciklov.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-14 01:15:40 MSK - Zakrepitj avtomaticheskiye semanticheskiye svyazi lichnogo FUM](../Zhurnal/2026-07-14_01-15-40_MSK_zakrepitj-avtomaticheskiye-semanticheskiye-svyazi-lichnogo-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d5036631abf3e2712a3a7c1db1334cfc27ff8eaac9adcb73cfef1904814b6f4f -->
<!-- FUM-MD-RECENCY:END -->
