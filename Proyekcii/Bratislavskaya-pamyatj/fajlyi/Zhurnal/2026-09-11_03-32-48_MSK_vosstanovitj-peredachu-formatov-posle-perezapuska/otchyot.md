# Otchyot 2026-09-11 03:32:48 MSK - Vosstanovitj peredachu formatov posle perezapuska

Podgotovlennyij perenos formatov i uzkij perekhod staroj politiki sokhranenyi posle perezapuska v novoj okhvachennoj granice. Devyatj soderzhateljnyikh fajlov ne menyayutsya. Novyij etap podtverzhdayet celostnostj rezuljtata i peredayot yego kornyu dlya obsjhej priyomki.

## Sokhranyonnoye nezavershyonnoye proiskhozhdeniye

[Prezhnij otchyot](../2026-09-11_02-44-12_MSK_obnovitj-pokoleniye-po-prezhnej-politike/otchyot.md) i vse yego JSON sokhranenyi pobajtovo. Zapisj №10 ostayotsya «vyipolnyayetsya» s neizvestnyimi kodom, vremenem i statusom; realjno process posle perezapuska ne najden. Etot prezhnij etap ne zakryit i ne obyyavlen proshedshim svyaznostj. Nikakaya dliteljnostj ili uspeshnyij rezuljtat yemu ne prisvoyenyi.

Korenj razreshil novyij realjnyij etap vosstanovleniya posle chteniya pravil i nezavisimogo audita. Tochnyij [snimok khyeshej](materialyi/snimok-svideteljstv.json) okhvatyivayet prezhniye otchyot i JSON, a takzhe devyatj soderzhateljnyikh fajlov. [Iskhodnyij zapros do navigacii](materialyi/prezhnij-zapros-do-navigacii.base64) sokhranyon v obratimom Base64 s SHA-256. Posle shtatnogo sozdaniya novoj papki razreshenyi toljko navigaciya i recency prezhnego zaprosa.

Podgotoviteljnyij scenarij snachala sozdal papku etapa, zatem ostanovilsya iz-za yesjhyo otsutstvuyusjhego kataloga materialov. Novyij etap povtorno ne sozdavalsya. Prezhnij zapros do navigacii vosstanovlen iz sobstvennogo neizmenyonnogo indeksa, kuda yego tochnyiye bajtyi byili postavlenyi pered perezapuskom; materialyi zapisanyi posle sozdaniya kataloga. Prezhniye otchyot i mashinnyiye zapisi ne izmenilisj.

Pervyij adresnyij zapusk podtverdil khyeshi, no obsjhij staged whitespace-check otklonil konechnyij probel doslovnogo poljzovateljskogo soobsjheniya v prezhnem novom zaprose. Poljzovateljskij original sokhranyon; whitespace-check adresovan tochno devyati soderzhateljnyim fajlam postavki. Proverka khyeshej prezhnikh svideteljstv i iskhodnogo zaprosa ne oslablena. Povtor kasayetsya toljko etoj lyogkoj proverki, 14 testov i profilj ne zapuskalisj vnovj.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Sokhranyonnaya regressiya | 10,869 s | 14 GREEN predyidusjhego etapa; ne povtoryalasj |
| Sokhranyonnyij perekhod odnogo fajla | 1,129449 s | Mediana pyati izmerenij predyidusjhego etapa |
| Podgotovka vosstanovleniya | ne izmereno | Otdeljnyij sekundomer ne zapuskalsya |
| Swift, zhivaya proyekciya i obsjhij smoke-check | ne zapuskalisj | Finaljnyij kontur ostayotsya u kornya |

Granica profilya: novyij etap nachat 2026-09-11 03:32:48 MSK; nizhe uchtenyi toljko dva sobstvennyikh pryamyikh zapuska proverki celostnosti. Staryiye izmereniya privedenyi kak sokhranyonnyiye svideteljstva. Vremya ozhidaniya, utrachennogo processa i pryamogo dopuska checkpoint v eti dliteljnosti ne vkhodit.

Ispolnyayemyij kod i izmerennyiye vkhodyi ne menyayutsya; osnovanij povtoryatj profilj ili optimizirovatj net. Novaya lyogkaya proverka izmeryayetsya obyortkoj nizhe. Vremya avarijno poteryannogo processa ne izvestno i ne zamenyayetsya vremenem obnaruzheniya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                             | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------- | ------------ | --------- |
| [Formatyi] Vosstanovleniye: celostnostj podgotovlennogo diff i prezhnikh svideteljstv | 0,256 s      | neuspeshno |
| [Formatyi] Vosstanovleniye: tochnyiye svideteljstva i diff devyati fajlov postavki      | 0,197 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 0,453 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki i peredacha

[Adresnyij scenarij](materialyi/proveritj-sokhranyonnyiye-svideteljstva.py) sravnivayet khyeshi 21 neizmenyayemogo fajla, tochnyiye bajtyi devyati fajlov v indekse, sokhranyonnyij iskhodnik zaprosa za isklyucheniyem razreshyonnyikh navigacii i recency, uspeshnuyu zapisj prezhnej regressii i neizmenyonnuyu osirotevshuyu zapisj. Dopolniteljno profilj svyazyivayetsya s fakticheskim SHA-256 ispolnyayemogo koda i proveryayetsya staged diff.

Pervyij pryamoj dopusk tekusjhego checkpoint otklonil sokrasjhyonnoye imya tretjyej kolonki profilya. Ono zameneno tochnyim imenem iz kontrakta Zhurnala. Sleduyusjhij dopusk potreboval yavnuyu stroku «Granica profilya:»; ona dobavlena posle chteniya vsej funkcii proverki tablichnogo profilya. Sokhranyonnyiye prezhniye fajlyi ne menyayutsya.

Posle terminaljnogo zaversheniya novoj proverki formiruyetsya shtatnyij predprosmotr i vyipolnyayetsya pryamoj read-only dopusk checkpoint tekusjhego zaprosa. Eto sokhraneniye nakoplennogo rezuljtata, ne finaljnaya priyomka prezhnego etapa ili FUM-STEP-0176. Korenj poluchit devyatj soderzhateljnyikh fajlov i chetyire sobstvennyikh Zhurnala, peresoberyot obsjhiye indeksyi i proverit integrirovannyij rezuljtat.

## Istochniki

- [Iskhodnyij zapros i razreshyonnaya granica](zapros.md).
- [Prezhnij etap perekhoda](../2026-09-11_02-44-12_MSK_obnovitj-pokoleniye-po-prezhnej-politike/otchyot.md).
- [Pervyij etap formatov](../2026-09-11_02-06-54_MSK_podderzhatj-formatyi-prilozheniya-v-proyekcii/otchyot.md).
- [Ispravleniye skhemyi](../2026-09-11_02-30-48_MSK_soglasovatj-skhemu-formatov-prilozheniya/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:40:20 MSK -->
<!-- content-sha256: sha256:83743dde41b3c6297127292bb76db1ed821792ae69bdf1eefb8ca29d8dc3259f -->
<!-- FUM-MD-RECENCY:END -->
