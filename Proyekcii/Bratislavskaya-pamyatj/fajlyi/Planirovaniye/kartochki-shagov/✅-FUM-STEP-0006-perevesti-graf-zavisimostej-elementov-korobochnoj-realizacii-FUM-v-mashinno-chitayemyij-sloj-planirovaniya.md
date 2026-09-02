+++
schema_version = 1
card_id = "FUM-STEP-0006"
status = "completed"
+++
# Perevesti graf zavisimostej elementov korobochnoj realizacii FUM v mashinno chitayemyij sloj planirovaniya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Perevesti [graf zavisimostej elementov korobochnoj realizacii FUM](../stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md) v mashinno chitayemyij sloj planirovaniya: identifikatoryi elementov, zavisimosti, parallelizuyemyiye vetki, blokiruyusjhiye riski, kriterii gotovnosti i svyazj s [MVP-kandidatami](../MVP-kandidatyi/README.md).

## Rezuljtat

Sozdana [mashinnaya proyekciya grafa korobochnoj realizacii](../stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.json) skhemyi `fum.planning.boxed-implementation-dependency-graph.v1`. Ona zakreplyayet tochnyij nabor elementov `P0`–`P16`, tochnyiye ryobra Mermaid, otdeljnyiye tekstovyiye predposyilki i kriterii gotovnosti, tri dokazannyiye paralleljnyiye gruppyi, pyatnadcatj blokiruyusjhikh riskov i svyazi so vsemi shestjyu MVP-kandidatami.

Graf privyazan k khyeshu [Markdown-istochnika](../stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md) bez `FUM-MD-RECENCY` i celikom vklyuchyon v [planovyij reyestr](../reyestr-trebovanij-variantov-i-kandidatov.json) skhemyi v7. Avtonomnyiye testyi proveryayut uspeshnoye vstraivaniye, sokhraneniye tochnogo nabora `P0`–`P16` i otkaz dlya neizvestnoj zavisimosti, cikla, zavisimyikh elementov v paralleljnoj gruppe, neizvestnogo MVP i ustarevshego khyesha; polnyij rezuljtat zafiksirovan v [iskhodnom zaprose](../../Zhurnal/2026-07-24_05-27-17_MSK_perevesti-graf-zavisimostej-korobochnoj-realizacii-v-mashinnyij-sloj/zapros.md) i [zhurnaljnom otchyote](../../Zhurnal/2026-07-24_05-27-17_MSK_perevesti-graf-zavisimostej-korobochnoj-realizacii-v-mashinnyij-sloj/otchyot.md).

Rezuljtat ostayotsya planovoj gipotezoj, a ne ispolnyayemyim raspisaniyem: on ne dokazyivayet fakticheskuyu gotovnostj, ne razreshayet nachalo korobochnoj stadii i ne razreshayet vneshniye ili fizicheskiye dejstviya. Raskhozhdeniya iskhodnyikh predstavlenij, vse nesnyatyiye zamechaniya audita pervogo URL-sreza, produktovogo proiskhozhdeniya, poryadka `P7`/`P8` i granicyi podtverzhdenij sokhranenyi kak yavnyiye blokeryi.

## Istochniki

- [iskhodnyij zapros 2026-07-24 05:27:17 MSK - Perevesti graf zavisimostej korobochnoj realizacii v mashinnyij sloj](../../Zhurnal/2026-07-24_05-27-17_MSK_perevesti-graf-zavisimostej-korobochnoj-realizacii-v-mashinnyij-sloj/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:23:15 MSK - Vyistroitj graf zavisimostej korobochnoj realizacii FUM](../../Zhurnal/2026-07-03_11-23-15_MSK_vyistroitj-graf-zavisimostej-korobochnoj-realizacii-FUM/zapros.md), [graf zavisimostej elementov korobochnoj realizacii FUM](../stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md), [stadiya korobochnoj realizacii FUM](../stadii/02-korobochnaya-realizaciya-FUM/README.md), [svodnaya tablica trebovanij i realizacij](../svodnaya-tablica-trebovanij-i-realizacij.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f6b8f30c5a93f2c1e63a91d7d38bd313ba3d0ed5bf1c8e1ea4a1e0f7f58963f1 -->
<!-- FUM-MD-RECENCY:END -->
