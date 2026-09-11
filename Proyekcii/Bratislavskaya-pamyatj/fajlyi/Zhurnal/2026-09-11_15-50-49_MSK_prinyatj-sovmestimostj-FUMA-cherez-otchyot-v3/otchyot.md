# Otchyot 2026-09-11 15:50:49 MSK - Prinyatj sovmestimostj FUMA cherez otchyot v3

Novaya obyichnaya priyomka shesti paketov cherez podderzhannyij M format v3/report-v2 posle kontroljnoj tochki Q. Do polucheniya rezuljtatov finaljnaya gotovnostj ne zayavlyayetsya. Realizaciya shesti paketov ostayotsya v `69e267b75f83f3f762379cfb61dd09c3d4df125f`; Q sokhranyayet posleduyusjhuyu istoriyu i soglasovannyij vyibor granicyi.

## Profilj vremeni vyipolneniya

| Stadiya               | Dliteljnostj         | Granicyi i sposob izmereniya                                                 |
| -------------------- | -------------------- | -------------------------------------------------------------------------- |
| Podgotovka           | ne izmereno          | Obsjhij monotonnyij interval ne sobiralsya                                     |
| Pryamyiye proverki      | po strokam nizhe      | Obyortka izmeryayet realjnyiye processyi; vlozhennyiye shagi ne summiruyutsya povtorno |
| Zamyikaniye i dostavka | vne mashinnoj granicyi | Razreshyonnyiye dejstviya posle zakryitiya otchyota                                 |

Granica profilya: etap nachat 2026-09-11 15:50:49 MSK. Mashinno izmeryayutsya toljko pryamyiye vyizovyi obyortki; chteniye, ozhidaniye obsjhego tyazhyologo okna i dostavka ne ocenivayutsya zadnim chislom. FIFO ne primenyalsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:9cf3af66302e0b776631fc4df53b555d81c723de84e3b7cbbaf2ad275e1ad698 -->

| Vyizov                                                                              | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj] Proveritj aktualjnostj reyestra pered priyomkoj v3                          | 0,403 s      | uspeshno   |
| [Korenj] Proveritj svyaznostj podgotovlennogo etapa v3                              | 39,833 s     | uspeshno   |
| [Korenj] Standartnaya itogovaya priyomka sovmestimosti FUMA cherez v3                  | 338,324 s    | neuspeshno |
| [Korenj] Vyidelitj oshibki adresnogo skanera posle otkaza polnoj proverki            | 0,16 s       | neuspeshno |
| [Korenj] Lokalizovatj tochnyiye kategorii skanera s yego shtatnyimi zavisimostyami        | 22,034 s     | neuspeshno |
| [Korenj] Proveritj skaner posle oboznachennoj redakcionnoj pravki citatyi            | 22,085 s     | uspeshno   |
| [Korenj] Povtoritj standartnuyu priyomku posle redakcionnoj pravki citatyi            | 850,348 s    | neuspeshno |
| [Korenj] Vosproizvesti otkaz nablyudeniya chteniya osnovaniya do ispravleniya            | 0,094 s      | neuspeshno |
| [Korenj] Podtverditj yedinstvennoye chteniye i sbros mezhdu vyizovami posle ispravleniya  | 0,101 s      | uspeshno   |
| [Korenj] Izmeritj adresnyij nabor prodolzheniya posle korrekcii nablyudayemogo metoda   | 1,505 s      | uspeshno   |
| [Korenj] Proveritj reyestr posle svyazi proyavleniya 0066 so shagom 0175                | 0,425 s      | uspeshno   |
| [Korenj] Proveritj svyaznostj vkhoda posle vosstanovleniya testa i proyavleniya 0066    | 41,246 s     | uspeshno   |
| [Korenj] Prinyatj podgotovlennyij paket posle ispravleniya nablyudayemogo metoda chteniya | 751,853 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2068,411 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Pervaya adresnaya proverka aktualjnosti planovogo reyestra proshla za 0,403271250 s. Posle nablyudyonnogo koda 0 otdeljno uspeshno sformirovan predprosmotr; mashinnaya zapisj imeyet skhemu `fum.test-run.v3`, nezapolnennyikh markerov ne ostalosj. Do full zakanchivayutsya soderzhateljnyiye zapisi, generatoryi, recency i indeks; adresnaya svyaznostj proveryayet gotovuyu podgotovku. Predusmotren standartnyij dokumentacionnyij smoke, a ne shirokij profilj vsekh testov.

## Resheniya i ogranicheniya

Pervaya standartnaya polnaya popyitka v3 zavershilasj kodom 1 za 338,324110375 s na skanere, posle uspeshnoj ustanovki i proverki 6536 fajlov proyekcii. [Adresnaya lokalizaciya](materialyi/diagnostika-skanera.md) nashla odin perechenj Git OID v novoj arkhivnoj citate Q, oshibochno raspoznannyij kak POSIX-putj. Sokhranenyi otkaz pervichnogo importa pomosjhnika i posleduyusjhaya nastoyasjhaya lokalizaciya. Rassmotrennoye tochnoye isklyucheniye ne voshlo v konechnyij rezuljtat: promezhutochnaya pravka politiki otmenena. Po ukazaniyu koordinatora tekusjhij dokument soderzhit oboznachennuyu redakcionnuyu vyiderzhku s zapyatyimi i tochnoj ssyilkoj na bajtyi originala v Q. Obyichnyiye 351, kandidatnyiye 419 i scanner sokhranenyi. Adresnaya zapisj `46c711a7-8703-4eae-ba4a-c611472c50ac` podtverdila ispravleniye: 22,085018667 s, kod 0, oshibok scanner net. Sleduyusjhij full trebuyet podgotovlennogo vkhoda i novogo tyazhyologo okna. Pervaya popyitka ostayotsya v etoj istorii.

Koordinator prinyal novyij otdeljnyij v3/report-v2-etap. Staryiye v4, vklyuchaya SIGINT i adresnoye vosstanovleniye, sokhranyayutsya v Q bez peremarkirovki. Novyij format vyibran radi sovmestimoj priyomki po M, ne dlya sokryitiya neudachnoj popyitki. Obyazateljnostj reader-v4 otozvana; predlozheniye dostatochnogo svideteljstva Unix-rezhimov ostayotsya posleduyusjhej rabotoj.

Koordinator yavno peredal tyazhyoloye okno posle fakticheskogo zaversheniya gostevogo profilya Linux i podtverzhdeniya otsutstviya drugikh tyazhyolyikh processov. VM ostayotsya bez nagruzki; finansovaya zadacha propuskayet gotovyij vkhod etoj priyomki. Pered full projdena adresnaya svyaznostj za 39,833483125 s i sformirovan aktualjnyij predprosmotr. Vo vremya processa kanonicheskiye vkhodyi ne redaktiruyutsya. Odin ispolnitelj pishet svoj checkout. Master/fuma, chuzhiye indeksyi i istoriya ne menyayutsya.

Posle uspeshnoj priyomki i zakryitiya sleduyut shtatnaya para zamyikaniya proyekcii, razreshyonnyiye read-only proverki, single-parent P, obyichnyij push i chteniye udalyonnogo OID. Staryij chitatelj iz M otdeljno svyazyivayet novyij zakryityij otchyot s Q→P. Eto obyichnaya priyomka; C2 trebuyet samostoyateljnogo strogogo kontura iz novogo M.

Posle adresnogo ustraneniya i podgotovki obnovlyonnogo vkhoda koordinator peredal okno odnogo povtornogo standartnogo full. Yego polnyij potok sokhranyayetsya v chastnom zhurnale vne Git; publichnyij otchyot khranit fakticheskiye mashinnyiye iskhodyi. Pri uspekhe snachala proveryayetsya plan, zatem zakryivayetsya otchyot i vyipolnyayetsya ustanovlennaya para zamyikaniya.

## Istochniki

Podgotovlennyij vkhod posle oformleniya `FUM-СБОЙ-0066/ПРОЯВЛЕНИЕ-0003` proshyol proverku planovogo reyestra `04d562c9-2a57-49b0-8650-b41b9e4d19d0` za 0,425415834 s i svyaznostj `c161d27d-ad89-480d-9794-ae1387029027` za 41,246365583 s. Nezavisimyij read-only-audit podtverdil tochnyiye dve stroki ispravleniya, sokhrannostj staryikh proyavlenij, dvustoronnyuyu svyazj 0066 so shagom 0175 i razreshimostj istoricheskikh Git-ssyilok; susjhestvennyikh zamechanij net. Vse docherniye ispolniteli zavershilisj. Posle zaversheniya finansovogo smoke i finaljnoj paryi proyekcii koordinator yavno peredal okno tretjyego standartnogo full R3. Vkhod podgotovlen posle realjnoj korrekcii 0066; prezhniye 12 terminaljnyikh zapisej sokhranyayutsya. Pri uspekhe sleduyut proverka plana, zakryitiye i ustanovlennaya para zamyikaniya.

Povtornaya polnaya popyitka zavershilasj kodom 1 za 850,348437917 s posle 23 uspeshnyikh shagov. [Diagnostika chteniya osnovaniya](materialyi/diagnostika-chteniya-osnovaniya.md) ustanovila iskhodnoye rassoglasovaniye M: test schitayet `read_text`, production chitayet `read_bytes`. V poslednem nabore odin otkaz iz 238 testov. Pervichnyij potok sokhranyon chastno, terminaljnaya zapisj ostayotsya v R3, zakryitiya i publikacii P ne byilo. Koordinator prinyal dvukhstrochnuyu korrektirovku, uzhe sokhranyonnuyu v L; tochnyij minimaljnyij source/diff — `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95`, iskhodnyij paket formatov. Tochnyij RED — 0,093797709 s, zatem GREEN — 0,101170708 s. Profilirovannyij adresnyij modulj iz 13 testov proshyol za 1,504784917 s po obyortke; celevoj test — 4,350208 ms. Utverzhdeniya sokhranenyi, production ne menyalsya, daljnejshaya optimizaciya ne trebuyetsya. Eto realjnaya ispravlennaya prichina sleduyusjhego full posle podgotovki vkhoda i peredachi okna.

- [Iskhodnyiye komandyi i tochnaya granica](zapros.md).
- [Prezhnij otchyot s dvumya v4-zapisyami](../2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/otchyot.md).
- [Karta shesti perenosov](../2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/materialyi/karta-perenosa.md).
- [Sovmestimostj chitatelya i proverennyij plan](../2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/materialyi/granica-chitatelya-i-priyomki.md).
- [FUM-SBOJ-0066, soglasovannoye proyavleniye 0003](../../Sboi/FUM-SBOJ-0066-ustarevshaya-podstanovka-metoda-chteniya.md) — iskhodnoye rassoglasovaniye M, adresno vosstanovlennoye prezhnej deljtoj L; integraciya v master ostayotsya rabotoj koordinatora.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 17:22:52 MSK -->
<!-- content-sha256: sha256:9501440113fad18c93ac445f628ec722c814e0f43f08d1a28d06e949b412a5ed -->
<!-- FUM-MD-RECENCY:END -->
