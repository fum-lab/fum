# MCP-server

MCP-server - servisnyij adapter, cherez kotoryij vneshnij servis predostavlyayet [FUM](FUM.md) instrumentyi, resursyi, operacii i sostoyaniye v forme, prigodnoj dlya mashinnogo vyizova i nablyudeniya.

V arkhitekture FUM MCP-server rassmatrivayetsya kak chastnyij sluchaj [ustrojstva vospriyatiya i dejstviya FUM](ustrojstvo-vospriyatiya-i-dejstviya-FUM.md): on dayot agentu nablyudeniya o servise i pozvolyayet vyipolnyatj dejstviya v yego srede. Yesli takoj adapter stanovitsya ustojchivoj chastjyu rabotyi, yego ispoljzovaniye dolzhno opisyivatjsya kak [avtomatizaciya FUM](avtomatizaciya-FUM.md) ili chastj avtomatizacii s yavnyimi versiyami, pravami dostupa, skhemami vkhodov i vyikhodov, oshibkami i trassami vyizovov.

MCP-server ne raven [interfejsu FUM-uzla](interfejs-FUM-uzla.md). On mozhet byitj chastjyu vneshnego interfejsa FUM, no ne opisyivayet celikom vnutrennyuyu pamyatj uzla, poljzovateljskij kontur namereniya, podtverzhdeniya, [granicyi vlasti](granica-vlasti-FUM.md), proiskhozhdeniye reshenij i peredachu [narabotok](narabotka.md).

Svyazka FUM i MCP-serverov dolzhna podderzhivatj [yedinuyu tochku vzaimodejstviya s kompjyuterom](yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md), v kotoroj poljzovatelj formuliruyet namereniye cherez FUM, a servisnyiye dejstviya vyipolnyayutsya cherez proveryayemyiye mashinnyiye kontraktyi.

## Svyazannyiye dokumentyi

- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Vosproizvodimyiye avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-06-26 10:50:43 MSK -->
<!-- content-sha256: sha256:858434b1da5d971c603af3c67810ebb30d07c6ba382be645237ad1fe64c0af29 -->
<!-- FUM-MD-RECENCY:END -->
