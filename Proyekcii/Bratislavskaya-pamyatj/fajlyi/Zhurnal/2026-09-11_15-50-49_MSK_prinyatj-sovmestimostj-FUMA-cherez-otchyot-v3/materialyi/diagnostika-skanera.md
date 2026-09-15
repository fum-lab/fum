# Lokalizaciya otkaza skanera v novoj arkhivnoj citate

Polnaya popyitka `f2de2e28-1931-4bee-8e8a-baec5ad875dc` zavershilasj kodom 1 za 338,324110375 s. Vlozhennyij smoke soobsjhil 338,242 s. Struktura i obe operacii reyestra proshli; primeneniye proyekcii za 207,616 s ustanovilo 6536 fajlov, nezavisimaya proverka za 92,972 s podtverdila pokoleniye. Skaner otkazal na shage 6/24 za 22,041 s. Avtonomnyiye testyi yesjhyo ne nachalisj: mashinnaya zapisj khranit 13 planovyikh naborov i pustyiye nablyudeniya. Zakryitiye otchyota ne vyipolnyalosj.

Vyivod skanera soderzhit 5614 strok razreshyonnyikh, istoricheskikh i oshibochnyikh nakhodok; pervichnyij otvet instrumenta usechyon. Polnyij syiroj potok ne obyyavlyayetsya sokhranyonnyim. Adresnaya povtornaya lokalizaciya ispoljzuyet tot zhe `scan_repository` i vyivodit toljko kategorii `error.*`; [realjno ispolnennyij scenarij](lokalizovatj-oshibki-skanera.py) sokhranyon dlya vosproizvedeniya.

Pervoye obrasjheniye k obyortke s diagnosticheskim klassom otkloneno do dochernego processa: ne zadanyi obyazateljnyiye naboryi i ozhidayemoye svideteljstvo. Poskoljku proveryayetsya odin scanner, a ne povtor polnogo avtonomnogo nabora, daleye vyibran adresnyij klass bez vyimyishlennyikh identifikatorov naborov. Zapisj `167f7492-80fb-4ffc-a313-4106088747dc` sokhranyayet fakticheskij otkaz importa `path_forms` za 0,160130917 s; proverki soderzhimogo v nej ne proizoshlo. V sleduyusjhem vyizove dobavlen shtatnyij katalog sosednikh zavisimostej skanera. Zapisj `cde092f2-58c6-4017-9c2f-7291800d1838` za 22,033667500 s vosproizvela rovno odnu oshibku.

Tochnaya nakhodka: fajl [koordinacionnyikh utochnenij](../../2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/materialyi/koordinacionnyiye-utochneniya.md), stroka 10, kategoriya `error.posix-absolute`. Novyij fajl poyavilsya v Q `00946efd0b16d95dc9e7ed49f45c1515a08e11c9`; yego yesjhyo ne byilo pri uspeshnoj adresnoj sverke v `69e267b75f83f3f762379cfb61dd09c3d4df125f`. Oshibka ne proiskhodit iz perenesyonnyikh iskhodnikov ili ustanovlennoj proyekcii.

Kosyiye chertyi v citate razdelyayut sokrasjhyonnyiye OID 17eb695b, 84d68a95, d5efcdbf i a219ab3b. Unicode-mnogotochiye pered pervyim raspoznannyim slyeshem dopuskayet nachalo POSIX-tokena; ostaljnyiye razdeliteli vkhodyat v tu zhe formu. Eto odno sovpadeniye perechnya Git-obyyektov, a ne realjnyij putj fajlovoj sistemyi.

Snachala susjhestvuyusjhij `obnovitj-policy.py` podgotovil [deklaraciyu odnogo tochnogo istoricheskogo sluchaya](politika-koordinacionnoj-citatyi.json), sokhranyaya vsyu stroku. Po pozdnemu vyiboru koordinatora eto promezhutochnoye izmeneniye otmeneno tochnyim vosstanovleniyem obyichnoj politiki iz HEAD; v konechnom vkhode ona snova soderzhit prezhniye 351 zapisi. Neispoljzuyemaya deklaraciya sokhranyayet proiskhozhdeniye rassmotrennogo varianta i ne yavlyayetsya dejstvuyusjhej politikoj.

Vyibrana yavno oboznachennaya redakcionnaya vyiderzhka: razdeliteli perechnya zamenenyi zapyatyimi. Pered blokom ukazano, chto on boljshe ne yavlyayetsya doslovnyim originalom; polnyiye iskhodnyiye bajtyi sokhranenyi v Q `00946efd0b16d95dc9e7ed49f45c1515a08e11c9`, blob `1c3fdf9e8c021c3ff409b9ee63bcd09dfddcfda7`, SHA-256 `6cb1985acef3a6962c4dcd64f9ad2f811719df49d2e606134e748ace5a393348`, i v nativnom dialoge. Ostaljnyiye soobsjheniya i pervichnyiye komandyi cheloveka ne menyalisj.

Takoye ispravleniye ne trebuyet rasshiryatj kandidatnuyu politiku radi novogo obyichnogo isklyucheniya: posle sliyaniya arkhivnyij dokument tozhe stanet vkhodom kandidata. Kod skanera, obyichnaya politika 351, kandidatnaya politika 419 i yeyo proiskhozhdeniye ostayutsya prezhnimi. Vse zapisi neudachnyikh zapuskov sokhranenyi.

Adresnaya zapisj `46c711a7-8703-4eae-ba4a-c611472c50ac` za 22,085018667 s podtverdila kod 0 i otsutstviye oshibok tekusjhego inventarya posle redakcionnoj pravki. Posle podgotovki vsekh kanonicheskikh vkhodov i novoj yavnoj peredachi tyazhyologo okna vozmozhen povtor standartnogo full. Neudachnaya popyitka ostayotsya chastjyu tekusjhej v3-istorii; ona ne obyyavlyayetsya uspeshnoj i ne skryivayetsya novoj papkoj.

Istochnik: [tekusjhij zapros](../zapros.md) i [mashinnyiye zapisi](zapuski-proverok/).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:19:36 MSK -->
<!-- content-sha256: sha256:e7a4fd47ca21599ce81632928627341f430f77bedc78f4fdfe81f733d02ad965 -->
<!-- FUM-MD-RECENCY:END -->
