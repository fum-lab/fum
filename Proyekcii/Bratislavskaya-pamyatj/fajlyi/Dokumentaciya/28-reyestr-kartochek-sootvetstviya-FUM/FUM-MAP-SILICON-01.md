# FUM-MAP-SILICON-01: Kremniyevyij substrat i mikrochipnaya lokaljnostj

Eta kartochka fiksiruyet kremniyevyij substrat i mikrochipnuyu lokaljnostj kak blizhnij apparatnyij sloj dlya FUM. Ona nuzhna, chtobyi budusjhaya korobochnaya realizaciya uchityivala fizicheskiye ogranicheniya vyichisliteljnogo nositelya, a ne opisyivala razum kak abstraktnuyu mgnovennuyu sistemu bez zaderzhek, lokaljnosti i cenyi sinkhronizacii.

## Kartochka

- Identifikator: `FUM-MAP-SILICON-01`.
- Obyyekt sopostavleniya: kremniyevyij substrat i mikrochipnaya lokaljnostj.
- Sloj: apparatnyij inzhenernyij sloj.
- Nablyudatelj: proyektirovsjhik lokaljnogo FUM-agenta, runtime korobochnoj realizacii i budusjhij FUM-uzel, uchityivayusjhij apparatnyiye ogranicheniya svoyego nositelya.
- Sootvetstviye obsjhej skheme: konechnaya skorostj signala, zaderzhki mezhsoyedinenij, taktovyiye domenyi, lokaljnyiye kyeshi i cena sinkhronizacii sopostavlyayutsya s lokaljnyimi nablyudatelyami, granicami prichinnoj svyaznosti i poteryami mgnovennoj globaljnoj nablyudayemosti.
- Sokhranyayemyiye invariantyi: dejstviye imeyet stoimostj, nablyudeniye lokaljno, soglasovaniye trebuyet vremeni, pamyatj nakhoditsya na konkretnom nositele, a arkhitektura dolzhna uchityivatj zaderzhki i sboi nizhnego sloya.
- Poteri nablyudayemosti: karta ne zamenyayet inzhenernyij pasport konkretnogo ustrojstva, ne vyivodit fiziku mikroskhem iz dokumentacii FUM i ne opisyivayet vse urovni apparatnoj optimizacii.
- Perekhod k istochniku: blizhajshij istochnik - budusjhij pasport [kremniyevogo substrata FUM](../../Glossarij/kremniyevyij-substrat-FUM.md), svyazannyij s dokumentami o lokaljnom agente i fizicheskom dejstvii.
- Granicyi analogii: sopostavleniye primenimo k inzhenernomu proyektirovaniyu vyichisliteljnogo nositelya; ono oslabevayet, kogda rassuzhdeniye perekhodit k fizike elementarnyikh chastic ili kosmologicheskim masshtabam bez otdeljnogo pasporta analogii.
- Proverka: pasport substrata dolzhen ukazyivatj apparatnyij profilj, runtime, lokaljnuyu LLM, pamyatj, trassyi, proverki, ogranicheniya zaderzhek i kriterii otkaza.
- Status uverennosti: kandidat dlya otdeljnogo pasporta kremniyevogo substrata.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:33:38 MSK](../../Zhurnal/2026-07-02_11-33-38_MSK/zapros.md)

## Opornyiye dokumentyi

- [Lokaljnyij agent FUM na vyidelennoj mashine](../24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Fizicheskoye dejstviye FUM i apparatnyiye uzlyi](../13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [Arkhitektura FUM](../22-arkhitektura-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f3bbe7e2494a8bee88570ebfdeba9b909adc52ff4f099e672c26bfe068892513 -->
<!-- FUM-MD-RECENCY:END -->
