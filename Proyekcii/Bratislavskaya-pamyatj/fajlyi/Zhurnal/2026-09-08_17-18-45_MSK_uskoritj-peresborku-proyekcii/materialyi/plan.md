# Realizaciya pervogo etapa uskoreniya proyekcii

Prioritet zadan [poljzovatelem](../zapros.md). Etap realizuyet maloye uskoreniye iz [predyidusjhego plana](../../2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/materialyi/planyi/plan.md).

1. Sravnitj izolirovannyiye Debug i Release na tochnyikh odinakovyikh vkhodakh i zakreplyonnoj zavisimosti. Iskhodnyij ogranichennyij profilj sokhranyon; sleduyusjhij zamer ispoljzuyet vesj podgotovlennyij vkhod proyekcii, a ne obrezannyiye dokumentyi.
2. Cherez RED/GREEN vnedritj odnokratnuyu Release-sborku i pryamoj zapusk yeyo produkta s sokhraneniyem dinamicheskoj biblioteki, izolyacii i nezavisimyikh vyichislenij. Etot kod podgotovlen, 114 testov proshli.
3. Sokhranitj izmereniya i promezhutochnyij kommit postoyannoj zadachi. Poluchitj fakticheskoye vremya celoj peresborki s vnutrennej proverkoj i otdeljnoj nezavisimoj proverki. Ne vyidavatj otnosheniye vremeni transliteracii za uskoreniye vsego kontura.
4. Vyipolnitj predfinaljnuyu priyomku aktualjnogo kanonicheskogo snimka, zakryitj otchyot, odin raz peresobratj i nezavisimo proveritj okonchateljnoye pokoleniye, sozdatj itogovyij lokaljnyij kommit.

Kriterij etogo etapa: tochnyiye stroki, puti, rezhimyi i bajtyi pokoleniya sokhranyayutsya, a izmerennoye vremya ispolneniya sokrasjhayetsya. Sborka i rabota SwiftPM otdelenyi ot preobrazovaniya. Kyesh mezhdu processami, inkrementaljnyij generator i izmeneniye algoritma registra ostayutsya daljnejshimi napravleniyami i ne obyyavlyayutsya vyipolnennyimi.

Docherniye agentyi proveryayut konkretnyiye chasti toljko chteniyem; korenj pishet svoyo derevo. Razresheniye poljzovatelya na otdeljnyiye docherniye vetki i worktree primenyayetsya pri poyavlenii nezavisimoj pishusjhej chasti. Sejchas dopolniteljnyij pisatelj ne nuzhen.

## Istochniki

- [Otchyot i otvetyi](../otchyot.md).
- [Iskhodnoye sravneniye](profili/sravneniye-debug-release.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 17:30:03 MSK -->
<!-- content-sha256: sha256:fc2bbafc2a2f11df3b3e53bb6425d8b08cac1e39569878b4f9e9e09a8bd8a512 -->
<!-- FUM-MD-RECENCY:END -->
