# Otchyot 2026-09-12 03:06:20 MSK - Sokratitj povtornyij analiz politiki putej

Iskhodnyij updater chitayet kazhdyij fajl odin raz, no povtoryayet polnyij `scan_text` i razdeleniye strok dlya kazhdoj yego deklaracii. Vyibran lokaljnyij kyesh rezuljtata polnogo analiza vnutri odnogo vyizova: oblastj politiki, polnota konteksta, schyotchiki i atomarnaya zapisj sokhranyayutsya. Na kontroljnom otkryitom vkhode primerno 1 MiB s 12 deklaraciyami mediana obnovleniya umenjshilasj s 9,544 do 0,879 s, tochnogo povtornogo vyizova — s 8,848 do 0,806 s. V kazhdom vyizove vyipolnyayetsya odin polnyij razbor vmesto dvenadcati. Itogovaya politika pobajtovo odinakova.

Soobsjheniye 183 poluchayet izmeryayemyij otvet o stoimosti proverok; princip soobsjheniya 195 primenyayetsya k povtornomu razboru; soobsjheniye 263 prodolzhayet rabotu posle obnovleniya sistemyi. Zapusk shesti zadach poruchen prezhnemu yedinstvennomu vladeljcu podgotovlennogo paketa. Sobstvennoye derevo kornya i chuzhiye rabochiye derevjya ne smeshivayutsya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Iskhodnoye obnovleniye, okolo 1 MiB | mediana 9,544 s | Tri otdeljnyikh obnovleniya, monotonnyij tajmer vnutri profilirovsjhika |
| Obnovleniye s odnokratnyim razborom | mediana 0,879 s | Tot zhe vkhod, 12 deklaracij, tri obnovleniya |
| Proverki i polnyiye profiljnyiye vyizovyi | po zapisyam nizhe | Vklyuchayut podgotovku fikstur i otdeljnyiye povtoryi; ne skladyivayutsya s vlozhennyimi intervalami |
| Finaljnaya priyomka | ne vyipolnena | Novyij polnyij progon i novaya proyekciya v kontroljnuyu tochku ne vkhodyat |

Granica profilya: tekusjhij etap posle kommita `2f10d879`; pryamyiye proverki uchityivayutsya otdeljno, vlozhennyiye intervalyi profilirovsjhika ne pribavlyayutsya k obsjhemu vremeni. Vremya predyidusjhikh etapov ne vosstanavlivayetsya zadnim chislom.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                 | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------- | ------------ | --------- |
| [Kornevaya zadacha] Krasnaya granica odnokratnogo analiza fajla v pakete                 | 2,303 s      | neuspeshno |
| [Kornevaya zadacha] Iskhodnyij profilj paketnogo analiza na tryokh otkryityikh fiksturakh       | 0,101 s      | neuspeshno |
| [Kornevaya zadacha] Iskhodnyij profilj posle dobavleniya zakreplyonnoj zavisimosti skanera  | 218,03 s     | uspeshno   |
| [Kornevaya zadacha] Proverki paketnogo analiza i prezhnego tochnogo obnovleniya politiki   | 3,153 s      | uspeshno   |
| [Kornevaya zadacha] Zelyonaya granica odnokratnogo analiza polnogo fajla                  | 4,308 s      | uspeshno   |
| [Kornevaya zadacha] Profilj odnokratnogo analiza na prezhnikh otkryityikh fiksturakh          | 23,956 s     | uspeshno   |
| [Kornevaya zadacha] Kontroljnyij iskhodnyij profilj posle prekrasjheniya postoronnej nagruzki | 57,338 s     | uspeshno   |
| [Kornevaya zadacha] Kontroljnyij profilj odnokratnogo analiza na sopostavimom vkhode      | 6,681 s      | uspeshno   |
| [Kornevaya zadacha] Proverka otkaza profilya pri izmenenii yego iskhodnikov                | 1,616 s      | uspeshno   |
| [Kornevaya zadacha] Profilj s proverkoj neizmennosti vsekh izmeryayemyikh iskhodnikov         | 3,962 s      | uspeshno   |
| [Kornevaya zadacha] Proverka publikacionnoj chistotyi optimizacii i yeyo svideteljstv       | 109,411 s    | uspeshno   |
| [Kornevaya zadacha] Proverka sokhranyonnogo planovogo reyestra                             | 2,251 s      | uspeshno   |
| [Kornevaya zadacha] Proverka svezhesti Markdown tekusjhej kontroljnoj tochki                | 10,269 s     | uspeshno   |
| [Kornevaya zadacha] Proverka tochnogo indeksirovannogo diff kontroljnoj tochki            | 0,178 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 443,557 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:4712624f49cf0e23aa83a5d67d2e35a1440a7fe665d60d80dd51241ea23a2155.
Kontekst soderzhimogo: sha256:d1b4d3fec4859fb02f671d31b5d20aecd3087d144eeacdad9eadbda48b18959d.
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

- Iskhodnaya adresnaya proverka: odin ozhidayemyij otkaz na povtornom polnom razbore, dva ostaljnyikh scenariya uspeshnyi.
- Pervaya popyitka profilya ostanovilasj na importe do izmerenij: v zakreplyonnoj kopii iskhodnikov otsutstvoval modulj strukturyi zaprosov. Zavisimostj dobavlena iz togo zhe iskhodnogo kommita; proizvodstvennyij updater ne menyalsya.
- Otdeljnaya oshibochnaya komanda s opechatkoj v imeni otchyotnoj obyortki zavershilasj kodom 2 do zapuska proverochnogo processa. Vesj sostavnoj vyizov s podgotovkoj zavisimosti zanyal 0,138791 s; eto ne dliteljnostj testa i ne dopolniteljnaya mashinnaya zapisj uspeshno zapusjhennoj proverki.

## Sravneniye i vosproizvodimostj

[Kontrolj do](materialyi/profili/kontrolj-do.json) i [kontrolj posle](materialyi/profili/kontrolj-posle.json) soderzhat po tri zapuska: 9,544 / 8,463 / 11,303 s i 0,879 / 1,083 / 0,793 s. Razmer vkhoda — 1 049 866 bajt, SHA-256 `8c7b71118d0d43a7c02add2698523d401ac21e6a4ce74acaebc91f95be716593`. SHA-256 rezuljtiruyusjhej politiki vo vsekh zapuskakh — `88f32ca24d52a44313b96906dc4a330db65640a23e566a80dfb002f6656cecba`. Polnyiye schyotchiki, poryadok deklaracij, neizmennostj vkhoda, bajtov politiki, inode i vremeni izmeneniya pri povtore proveryayutsya samim scenariyem.

Pervuyu paru primerno na 4 MiB takzhe sokhranyayut [iskhodnyij profilj](materialyi/profili/do.json) i [profilj izmeneniya](materialyi/profili/posle.json). Sosednyaya zadacha soobsjhila o rekursivnom zapuske 107 processov Python: eti ranniye vremena ne prinimayutsya za izmereniye uskoreniya pri odinakovoj nagruzke. Kontroljnaya para vyipolnena posle soobsjheniya o prekrasjhenii etikh processov i adresnogo chteniya spiska processov; obsjhej izolyacii CPU ot prochikh zadach ne byilo. Poluchennyij vyiigryish otnositsya k dannomu vkhodu updater, ne ko vsej proverke ili peresborke proyekcii.

Iskhodnaya realizaciya zakreplena kommitom `2f10d879e8f2dba8493ad1cb3a84aa40fc4df8b2`; [proiskhozhdeniye iskhodnikov](materialyi/proiskhozhdeniye-profilya/iskhodniki.json) perechislyayet chetyire fajla i SHA-256. Dlya zapuska prezhnej realizacii peremennaya `FUM_CHECKED_CODE_ROOT` ukazyivala na vremennuyu kopiyu etikh fajlov s sokhranyonnoj otnositeljnoj strukturoj. Eto kopiya iz monorepozitoriya, a ne otdeljnaya postavka komponenta. Tekusjhij modulj fiksturyi ostavalsya obsjhim dlya obeikh storon.

[Pervaya versiya profilirovsjhika](materialyi/proiskhozhdeniye-profilya/pervaya-versiya.py) sokhranena pobajtovo: SHA-256 `19505d9d6f98a173e085348a80e063840c583ace6a034751b512e884d1185f8e` sovpadayet so vsemi chetyirjmya rannimi profilyami. Eta versiya snimala SHA posle serii. Izmeneniye izmeryayemyikh iskhodnikov vo vremya tekh serij ne ustanovleno, no avtomaticheskoj proverki ikh neizmennosti na obeikh granicakh yesjhyo ne byilo.

Po nezavisimomu obzoru dobavlena proverka SHA do i posle serii, vklyuchaya sam profilirovsjhik, modulj fiksturyi i strukturu zaprosov. Novaya skhema profilya imeyet versiyu 2; izmeryayemoye telo ne izmeneno. Otdeljnaya regressiya podtverzhdayet otkaz pri izmenenii bajtov ili ischeznovenii istochnika. Yeyo zapusk posle izmeneniya ne obyyavlyayetsya predvariteljnyim RED. [Korotkij profilj novoj skhemyi](materialyi/profili/neizmennostj-iskhodnikov.json) podtverzhdayet realjnoye prokhozhdeniye etoj granicyi. Dopolniteljnoj algoritmicheskoj optimizacii zdesj ne potrebovalosj: metadannyiye sobirayutsya za predelami izmeryayemogo obnovleniya.

Adresnaya posledovateljnostj: zapisj 1 — tri novyikh scenariya, odin ozhidayemyij RED; zapisj 4 — devyatj prezhnikh testov, nazvaniye vyizova byilo shire fakticheskogo shablona poiska; zapisj 5 — vse tri novyikh scenariya GREEN. Zapisj 9 otdeljno proveryayet proiskhozhdeniye profilya. Eti rezuljtatyi ne zamenyayut polnyij smoke-check.

Pervyij zaklyuchiteljnyij kontrolj svyaznosti zavershilsya otkazom za 177,773323 s: v perechne zatronutyikh fajlov zaprosa byili propusjhenyi materialyi tekusjhikh proverok i tri navigacionnyikh fajla. Eto oshibka oformleniya kornya. Perechenj dopolnen fakticheskimi celyami; kod i proverochnyiye pravila ne menyalisj. Neuspeshnyij zaklyuchiteljnyij kontrolj vyipolnen vne obyortki po rezhimu kontroljnoj tochki, yego dliteljnostj ne dobavlyayetsya k tablice pryamyikh zapisej.

Nezavisimoye chteniye novyikh imyon ne nashlo sobstvennyikh latinskikh obyyavlenij. Vneshnij metod `unittest.setUp` sokhranyon; tekusjhij analizator vklyuchayet yego v ostatok. Polnyij snimok ostatka v etom etape ne obnovlyalsya i ne obyyavlyayetsya proverennyim.

## Resheniya i ogranicheniya

- Sravnivayutsya odinakovyiye otkryityiye fiksturyi i tochnyiye rezuljtiruyusjhiye bajtyi politiki. Privatnyij arkhiv perepiski ne ispoljzuyetsya kak publikuyemyij testovyij vkhod.
- Kyesh mezhdu vyizovami ne sokhranyayetsya. Nezavisimyij itogovyij scanner ne zamenyayetsya kyeshirovannyim rezuljtatom updater.
- Susjhestvuyusjhaya proyekciya ot prinyatogo `e95d7f5d1ef6387454b7825932cfbd737e600473` otstayot ot novyikh fajlov; kontroljnaya tochka etogo etapa ne vyidayotsya za finaljnuyu priyomku.
- Tekusjhij ostatok: proverka kontroljnoj tochki, kommit i publikaciya; finaljnaya priyomka optimizacii i yeyo integraciya vyipolnyayutsya otdeljno. Posle etogo prodolzhayetsya soglasovannaya integracionnaya rabota.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [predyidusjhij etap](../2026-09-12_01-02-03_MSK_sokhranitj-integraciyu-i-rasshiritj-rabotu/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:55:25 MSK -->
<!-- content-sha256: sha256:c997dc0175f618e3d2330d30f8303d27d96fe8fb6ffb235b462a479819dc57be -->
<!-- FUM-MD-RECENCY:END -->
