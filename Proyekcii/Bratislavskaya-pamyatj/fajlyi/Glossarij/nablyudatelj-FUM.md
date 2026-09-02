# Nablyudatelj FUM

Nablyudatelj FUM - uzel, ispolniteljnyij substrat ili uchastnik, dlya kotorogo [FUM](FUM.md) predyyavlyayet svoj [interfejs](interfejs-FUM-uzla.md) na opredelyonnom urovne abstrakcii i voplosjheniya.

Nablyudatelem mozhet byitj CPU, GPU, LLM, chelovek, [poduzel FUM](poduzel-FUM.md), servisnyij adapter ili sostavnoj [FUM-uzel](FUM-uzel.md). Odin i tot zhe sloj FUM dlya raznyikh nablyudatelej vyiglyadit po-raznomu: CPU poluchayet instrukcii, pamyatj i preryivaniya; GPU - buferyi, tenzoryi, yadra vyichislenij i graf ispolneniya; LLM - kontekst, skhemyi, instrukcii i trassyi; chelovek - tekst, ekran, obyyasneniye, podtverzhdeniye i rezuljtat.

Nablyudatelj FUM ne obyazateljno yavlyayetsya samostoyateljnyim agentom i ne poluchayet avtomaticheski pravo menyatj nablyudayemyij sloj. Dlya ustojchivogo interfejsa vazhno fiksirovatj profilj nablyudatelya: urovenj abstrakcii, formu voplosjheniya, dostupnyiye signalyi, dopustimyiye operacii, kartu sootvetstviya s nizhnim sloyem i izvestnyiye poteri nablyudayemosti.

Cherez [nablyudateljskuyu otnositeljnostj FUM](nablyudateljskaya-otnositeljnostj-FUM.md) etot profilj stanovitsya ne spravochnoj detaljyu, a chastjyu samogo opisaniya informacionnoj sistemyi: bez nablyudatelya, formyi predyyavleniya i kartyi [preobrazovanij mezhdu nablyudatelyami FUM](preobrazovaniye-mezhdu-nablyudatelyami-FUM.md) opisaniye ostayotsya nepolnyim.

## Svyazannyiye dokumentyi

- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Arkhitektura FUM](../Dokumentaciya/22-arkhitektura-FUM.md)
- [Virtualizovannyiye sredyi FUM i dolgovremennaya pamyatj](../Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-23 12:36:20 MSK -->
<!-- content-sha256: sha256:9127e9e099f78cae3d1eaed7afa8e91ff53058bbd635639c11b05f3d66869b10 -->
<!-- FUM-MD-RECENCY:END -->
