# Otchyot 2026-09-16 14:20:17 MSK - Sokhranitj prichinu otkaza priyoma

Podgotovlena ogranichennaya kontroljnaya tochka diagnostiki i chteniya pervichnogo istochnika. Otvet CLI versii `fum.отказ-приёма.2` sokhranyayet bezopasnyiye etap, tip, kod i cepochku izvestnyikh obyortok. Proizvoljnyiye vlozhennyiye tekstyi i privatnyiye puti ne publikuyutsya. Prichinyi prezhnikh Max2/3 ostayutsya neizvestnyimi.

Podgotovka pereispoljzuyet indeks odnogo shtatnogo seansa, privyazannogo k istochniku, UUID, kornyu i rezhimam. Obe proverki resheniya, istoriya, svideteljstva, HEAD i pozdnij khvost proveryayutsya povtorno. Seans chuzhogo istochnika ili rezhima zakryito otvergayetsya. Gotovyij ostatok ne kyeshiruyetsya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Realizaciya i adresnoye revjyu | ne izmereno | Ruchnyiye intervalyi analiza ne vosstanovlenyi iz vremeni soobsjhenij |
| RED diagnosticheskogo kontrakta | 9,817 s | unittest: 22 testa, tri ozhidayemyiye oshibki otsutstvuyusjhej diagnostiki |
| RED povtornogo razbora | 66,530 s | unittest: 15 testov, odin ozhidayemyij otkaz, chetyire razbora vmesto odnogo |
| GREEN kompozicii do proverki privyazki | 69,220 s | unittest: 15 testov; istoricheskaya proverka promezhutochnogo snimka |
| Regressii chitatelya i obrabotki | 37,251 s | unittest: 84 testa posle privyazki shtatnogo seansa |
| Podgotovka s otdeljnyimi seansami | 2,164 s | Mediana tryokh operacij itogovogo otkryitogo profilya |
| Podgotovka s obsjhim seansom | 2,121 s | Mediana tryokh sopostavimyikh operacij togo zhe profilya |

Granica profilya: adresnyiye lokaljnyiye intervalyi ot pervogo RED do itogovogo profilya. Obsjhiye zatratyi modeli, denezhnaya cena, pikovaya pamyatj i polnaya priyomka ne izmeryalisj. Sozdaniye fikstur isklyucheno iz operacii podgotovki, no vklyucheno v polnoye vremya nablyudeniya profilya. Vlozhennyiye intervalyi ne summiruyutsya s obsjhej dliteljnostjyu.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                         | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------- | ------------ | --------- |
| [korenj] RED: sokhraneniye bezopasnoj prichinyi otkaza priyoma                     | 9,977 s      | neuspeshno |
| [korenj] GREEN: bezopasnaya prichina i prezhniye granicyi priyoma                   | 9,904 s      | neuspeshno |
| [korenj] Adresnaya proverka realjnoj obyortki i publichnogo CLI                  | 10,1 s       | uspeshno   |
| [korenj] Diagnostika vlozhennoj prichinyi i pozdnego vvoda                       | 10,201 s     | uspeshno   |
| [korenj] RED: yedinstvennyij razbor pri podgotovke i neodnoznachnyij pozdnij vvod | 66,703 s     | neuspeshno |
| [korenj] GREEN: obsjhij seans podgotovki sokhranyayet pozdnyuyu sverku               | 69,393 s     | uspeshno   |
| [korenj] Sopostavimyij otkryityij profilj chteniya pri podgotovke                  | 17,512 s     | uspeshno   |
| [korenj] RED: prinadlezhnostj seansa i rezhim pereproverki                      | 0,931 s      | neuspeshno |
| [korenj] GREEN: diagnostika i privyazka seansa k istochniku i rezhimu            | 10,935 s     | uspeshno   |
| [korenj] Regressii shtatnogo chitatelya i obrabotki soobsjhenij                    | 37,44 s      | uspeshno   |
| [korenj] Proverka tochnogo ostatka obyyavlenij koda                             | 7,067 s      | neuspeshno |
| [korenj] Adresnaya sverka nasleduyemogo ostatka obyyavlenij                      | 7,651 s      | uspeshno   |
| [korenj] Profilj itogovoj privyazki obsjhego seansa                              | 17,018 s     | uspeshno   |
| [korenj] RED: prezhnij tip otkaza normalizacii istochnika                       | 0,188 s      | neuspeshno |
| [korenj] GREEN: tip otkaza normalizacii i polnaya pereproverka                 | 11,651 s     | uspeshno   |
| [korenj] Itogovyij profilj prinyatoj diagnosticheskoj deljtyi                     | 14,152 s     | uspeshno   |
| [korenj] Obyazateljnyiye adresnyiye proverki kontroljnoj tochki diagnostiki         | 133,225 s    | uspeshno   |
| [korenj] Dopusk posle ispravleniya oformleniya Zhurnala pri neizmennom kode      | 26,314 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 460,362 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:ebf0eaaccac0e5871e20af38bd3aed0721ac7fb501e0a8544b297f9f3293ddeb.
Kontekst soderzhimogo: sha256:b0e743d740bc97ec325b51cf4751216f013127014894b60aec0ba7ee682ee802.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Shtatnyiye zapisi nizhe sokhranyayut kazhdyij promezhutochnyij RED, neudachnuyu podstanovku pervogo GREEN i uspeshnyiye adresnyiye rezuljtatyi. Obyazateljnyiye proverki kontroljnoj tochki svyazyivayutsya s tochnyim indeksom otdeljno; istoricheskiye rezuljtatyi ne zamenyayut etot dopusk.

[Itogovyij profilj](materialyi/profilj-chteniya-priyoma-3.json) vklyuchayet khyeshi koda i shestj nezavisimyikh otkryityikh fikstur. Snimkov po-prezhnemu vosemj, vyichislenij ostatka chetyire. Razborov polnogo neizmennogo fajla stalo odin vmesto chetyiryokh; prochitano snimkami 730 646 vmesto 2 922 584 bajt, razobrano 2 003 vmesto 8 012 strok. Otdeljnyiye chteniya `сверить_границы` v schyotchik bajtov ne vkhodyat. Neboljshoye izmeneniye obsjhej dliteljnosti ne dokazyivayet uskoreniye zhivogo dopisyivayemogo JSONL. [Pervyij profilj](materialyi/profilj-chteniya-priyoma.json) otnositsya k promezhutochnoj realizacii do zasjhityi privyazki.

[Vtoroj profilj](materialyi/profilj-chteniya-priyoma-2.json) predshestvuyet vosstanovleniyu prezhnego tipa oshibki normalizacii. [Istoriya modeli posle izmeneniya chitatelya](materialyi/istoriya-modeli-2.json) soderzhit te zhe 67 sobyitij i posledneye Medium, chto [pervoye nablyudeniye](materialyi/istoriya-modeli.json); novyij kursor potrebovalsya iz-za izmeneniya khyesha realizacii. Dva otkaza podgotovki do Git sokhranenyi privatno: dopisyivaniye vo vremya nablyudeniya, zatem ustarevshij kursor realizacii. Tretjya podgotovka uspeshna; kommit na moment etogo teksta yesjhyo ne sozdan.

## Resheniya i ogranicheniya

- [Nasleduyemyij snimok obyyavlenij](materialyi/nasleduyemyij-ostatok-koda.json) raskhoditsya s inventaryom iskhodnogo `73169aee59883bacb0f0759f46ed4c475b80d57f`: fakticheski 46 250 protiv sokhranyonnyikh 43 091. Shtatnyiye funkcii razbora vsekh izmenyonnyikh i novyikh Python/Markdown-fajlov podtverdili neizmennostj nabora obyyavlenij; tekusjhaya deljta ne sozdayot raskhozhdeniye. Bazovyij snimok ne perepisan. Koordinator prinyal eto toljko kak ogranicheniye promezhutochnoj kontroljnoj tochki.
- [Sokhranyonnaya proyekciya](materialyi/granica-sokhranyonnoj-proyekcii.json) nasleduyetsya bez novoj polnoj proverki i ne yavlyayetsya prinyatoj itogovoj proyekciyej tekusjhego koda. Tyazhyolyij polnyij kontur zanyat integratorom.
- Priyom utochneniya Max, ustanovka predlozheniya FUM-SBOJ-0149 i staryiye 11 obyazateljstv ne obyyavlenyi zavershyonnyimi. STEP0165 i planovyij reyestr v etom etape ne redaktirovalisj. Istoricheskiye prichinyi otkazov ne rekonstruirovanyi.
- Sleduyusjhij otdeljnyij dokumentacionnyij etap zakrepit strategiyu snizheniya neobkhodimyikh usilij do prostyikh lokaljnyikh modelej, sorazmernyiye izmereniya i svyazj voprosa s nablyudeniyem. Kodovoye ispyitaniye lokaljnyikh modelej i obsjhaya telemetriya ne vyipolnenyi i ne vkhodyat v etu kontroljnuyu tochku.
- Lokaljnyij kommit i publikaciya svoyej vetki ne oznachayut integracii v `fuma` ili vyipuska `master`.

## Istochniki

- [iskhodnyij zapros i granicyi](zapros.md)
- [doslovnoye porucheniye koordinatora](materialyi/porucheniye-koordinatora.json)
- [nablyudeniya otkazov Max](../2026-09-16_13-25-42_MSK_zakrepitj-utochneniya-Max-i-poteryu-porucheniya/materialyi/otkazyi-priyoma.json)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 14:44:20 MSK -->
<!-- content-sha256: sha256:b330f0036978d6530a2126f22193ad791f04a985ae9d6877fdc3533f141b2115 -->
<!-- FUM-MD-RECENCY:END -->
