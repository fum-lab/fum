# Interfejs FUM-uzla

Interfejs FUM-uzla - ustojchivaya granica, cherez kotoruyu [FUM-uzel](FUM-uzel.md) nablyudayet i organizuyet sebya iznutri, prinimayet vneshniye signalyi, predyyavlyayet rezuljtatyi drugim uzlam, poljzovatelyam i servisam, a takzhe ogranichivayet dostup k svoim sostoyaniyam i dejstviyam.

Interfejs imeyet dve storonyi. Vnutrennij interfejs vklyuchayet [pamyatj](pamyatj-FUM.md), [vnutrenniye sostoyaniya](vnutrenneye-sostoyaniye.md), planyi, trassyi, [modeljnuyu sredu](modeljnaya-sreda.md), poduzlyi, lokaljnyiye avtomatizacii i urovni dostupa, dostupnyiye samomu uzlu dlya nablyudeniya i rabotyi. Vneshnij interfejs vklyuchayet poljzovateljskij kontur, servisnyiye adapteryi, [MCP-serveryi](MCP-server.md), obmen [narabotkami](narabotka.md), vkhodnyiye signalyi, vyikhodnyiye rezuljtatyi, podtverzhdeniya i ogranicheniya peredachi.

Odin i tot zhe FUM-sloj mozhet imetj raznyiye interfejsnyiye predyyavleniya dlya raznyikh [nablyudatelej FUM](nablyudatelj-FUM.md): CPU, GPU, LLM, cheloveka, poduzla, servisa ili drugogo sostavnogo uzla. Poetomu interfejs dolzhen fiksirovatj ne toljko dostupnyiye operacii, no i profilj nablyudatelya, dlya kotorogo eti operacii stanovyatsya osmyislennyimi.

Interfejs FUM-uzla ne svoditsya k vizualjnomu poljzovateljskomu interfejsu. On vklyuchayet mashinnyiye kontraktyi, sobyitiya, formatyi pamyati, prava dostupa, proiskhozhdeniye reshenij, proveryayemyiye trassyi, perekhodyi k istochnikam polnoj informacii i yavnyiye otkaznyiye rezhimyi.

MCP-server yavlyayetsya vozmozhnoj chastjyu vneshnego interfejsa FUM-uzla, no ne zamenyayet yego celikom: MCP opisyivayet mashinnyij dostup k servisu, a interfejs FUM-uzla opisyivayet vsyu granicu nablyudeniya, smyisla, dejstviya, dostupa i proiskhozhdeniya uzla.

## Svyazannyiye dokumentyi

- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Arkhitektura FUM](../Dokumentaciya/22-arkhitektura-FUM.md)
- [Dostup k vnutrennim sostoyaniyam](../Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md)
- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Virtualizovannyiye sredyi FUM i dolgovremennaya pamyatj](../Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)
- [Nablyudatelj FUM](nablyudatelj-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-02 11:17:07 MSK -->
<!-- content-sha256: sha256:470b0becee348ad634da9b689474c60cf699a9c81d5ec4922757f71c62289476 -->
<!-- FUM-MD-RECENCY:END -->
