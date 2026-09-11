+++
schema_version = 1
card_id = "FUM-STEP-0201"
status = "active"
+++
# Avtomatizirovatj priyom napravlenij FUMA

## Zadacha

Sozdatj yedinyij vosproizvodimyij vkhod priyoma podtverzhdyonnogo napravleniya: iskhodnoye soobsjheniye s pozdnimi utochneniyami, sokhranyonnaya para komandyi i otveta, unikaljnyiye mezhvetochnyiye nomera, kartochki i peredacha razreshyonnoj nezavisimoj rabotyi vidimoj zadache Codex Desktop. Povtor prodolzhayet sokhranyonnyiye stadii. Smyislovoye resheniye ostayotsya yavnyim vkhodom modeli.

## Pochemu sejchas

Poljzovatelj razreshil vsyu cepochku posle utochneniya yeyo sostava. Ruchnoye vyideleniye nomerov uzhe privelo k kollizii mezhdu vetkami; prostoye sozdaniye zadachi ne dokazyivayet yeyo fakticheskiye derevo, vetku i modelj.

## Kriterii zaversheniya

- Pereispoljzovanyi chitatelj FUM-STEP-0177, struktura Zhurnala, reyestr planirovaniya, recency, otchyotnyiye proverki i svyaznostj. JSONL i privatnyiye sostoyaniya ne publikuyutsya.
- Mezhprocessnyij uchyot odnoj Git-bazyi sokhranyayet proiskhozhdeniye, vse zanyatyiye nomera i yavnyiye rezervyi; raznyiye sobyitiya razlichayutsya, povtor ne vyidelyayet novuyu gruppu nomerov. Mezhklonovaya unikaljnostj bez koordinatora ne zayavlyayetsya.
- Razreshyonnoye sozdaniye prokhodit realjnyij podderzhannyij adapter Codex Desktop; podtverzhdenyi taskID, fizicheskij putj, polnyij ref, HEAD, zaproshennaya i nablyudyonnaya modeli. Poteryannyij otvet i odin clientThreadId ne razreshayut povtor sozdaniya.
- Dokazanyi RED/GREEN dlya povtorov, gonki, pozdnego utochneniya, povrezhdyonnogo istochnika, chuzhogo pisatelya, chastichnoj zapisi i kommita; sokhranenyi otkryityiye profili i resheniye ob optimizacii.
- Matematika sluzhit pervyim poleznyim priyomochnyim vkhodom toljko na planirovaniye: zakreplenyi FUM-STEP-0202 i FUM-REQ-0065. Utochneniye susjhestvuyusjhego FUM-STEP-0165 pereispoljzuyet kartochku i zadachu planirovsjhika.
- Posle priyomki obyazateljnoye ispoljzovaniye zakrepleno v kanonicheskikh pravilakh; yavnaya ostanovka cheloveka sokhranyayet prioritet. Finaljnaya priyomka i publikaciya svoyej vetki podtverzhdenyi; samostoyateljnoj integracii v master net.

## Granica pervogo etapa

Podgotovlenyi primitivyi allocator i sokhranyayemyikh stadij, adresnyiye regressii i profilj. Vyisokourovnevyij dopusk proiskhozhdeniya i realjnyij most yesjhyo ne podklyuchenyi; nizkourovnevyij `начать_попытку` ne yavlyayetsya samostoyateljnyim razresheniyem vneshnego vyizova. FUM-STEP-0196 (vidimostj) i FUM-STEP-0198 (koordinaciya nomerov) yavlyayutsya svyazannyimi kriteriyami, ikh predmetnaya realizaciya ne dubliruyetsya.

## Istochniki

- [Komandyi, utochneniye sostava i raspredeleniye rabotyi](../../Zhurnal/2026-09-11_01-40-19_MSK_avtomatizirovatj-priyom-napravlenij-FUMA/zapros.md).
- [Pervyij etap i fakticheskij ostatok](../../Zhurnal/2026-09-11_01-40-19_MSK_avtomatizirovatj-priyom-napravlenij-FUMA/otchyot.md).
- [Chitatelj iskhodnyikh soobsjhenij](🟡-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:07:47 MSK -->
<!-- content-sha256: sha256:9f390a062743197be003d07038758a81a223127bfa0855828c26a8f33e7dd141 -->
<!-- FUM-MD-RECENCY:END -->
