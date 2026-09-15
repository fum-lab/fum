# Prinyataya integraciya fuma i master

Eto zapisj fakticheski zavershyonnyikh operacij predyidusjhego etapa. [Yego zakryityij otchyot](../../2026-09-11_23-55-50_MSK_prinyatj-sliyaniye-s-profilyami-prodolzheniya/otchyot.md) i desyatj iskhodnyikh mashinnyikh zapisej ostayutsya istochnikom rezuljtatov proverok.

| Obyyekt | Podtverzhdyonnoye znacheniye |
| --- | --- |
| Vedusjhaya osnova L | `a728283474931eda71cd581ca5429121124ba3f6` |
| Prinimayusjhij master M1 | `5670e469f0cd271c80484e3ebcac0ca40971cba2` |
| Prinyatyij kommit C | `e95d7f5d1ef6387454b7825932cfbd737e600473` |
| Derevo T | `82c77d3b186712acb99401f42c10f75d86696988` |
| Roditeli C | Rovno `[L, M1]`, v etom poryadke |
| Polnyij zapusk | `75f5e68e-4b63-4ccb-9311-5710b75b63b3`, 24 etapa, 13 testovyikh naborov, kod 0 |
| Zakryityij snimok report-v2 | SHA-256 `fec258f0389f37947e9867b3cf981ceee2b44753f6d149a7047e1e15527ef541` |
| Otpechatok zapuska i zakryitiya | `sha256:a26e31320107650dc5c8e868f4c293f4e344a0dd387f2ade0aafe2213a620652` |
| Plan finaljnoj proyekcii | `sha256:5f2230dfbddd880cfe380e16ae5e4b96299c612121cb2506f330e917239cd380` |
| Sostav proyekcii | 7969 iskhodnyikh i celevyikh fajlov; 7970 upravlyayemyikh fajlov vmeste s manifestom |

Polnaya proverka vyipolnyalasj celyim prinimayusjhim konturom M1 nad kandidatom. Posle zakryitiya otchyota vyipolnenyi odna finaljnaya generaciya i nezavisimaya proverka manifesta. Proverki snimka, svezhesti i svyaznosti proshli; yedinstvennoye preduprezhdeniye `git diff --check` otnositsya k konechnomu probelu v starom doslovnom soobsjhenii o Windows VM. Stroka s LF imeyet SHA-256 `1c0f8def07b6c91200def1ccff67ec058de094893d5923c6bbda2c522ed72e23` i pobajtovo sovpadayet s iskhodnikom L i prezhnej kontroljnoj tochkoj. Iskhodnyij tekst sokhranyon.

Nezavisimyij chitatelj proveril sokhrannostj 29 fajlov prinyatoj predposyilki, 28 prezhnikh svideteljstv i 21 iskhodnogo JSON. Vyisokij [chitatelj zakryitogo otchyota iz M1](../../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/proverka-sliyaniya-iz-master.md) podtverdil C, roditelej, T, otpechatok i proiskhozhdeniye polnogo zapuska s kodom 0. Eto dokazateljstvo priyomki dannogo kommita; ostatok postoyannoj zadachi ocenivayetsya otdeljno.

Sobstvennaya vetka `refs/heads/codex/интеграция-fuma-master-профили-01a07d3d` opublikovana obyichnyim exact push; udalyonnyij OID otdeljno prochitan i raven C. Naznachennyij pisatelj `fuma` vyipolnil fast-forward L → C, podtverdil HEAD, indeks T, chistotu i sokhrannostj poljzovateljskogo sostoyaniya, zatem opublikoval C v odnoimyonnuyu vetku s otdeljnyim chteniyem udalyonnogo OID. Dopolniteljnogo merge-kommita net.

Posle etogo [uzkij ispolnitelj prodvizheniya](../../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/prodvizheniye-prinyatogo-sliyaniya.md) povtoril vyisokij dopusk iz neizmennogo M1 i soglasoval primary master, indeks i rabochiye fajlyi s C. Otvet — `завершено`, kod 0; korenj otdeljno podtverdil HEAD C, symbolic ref `refs/heads/master`, T i chistoye derevo. Master obnovlyon lokaljno; yego push ne vyipolnyalsya. Privatnyij intent i tochnyiye lokaljnyiye komandyi sokhranenyi vne Git.

| Operaciya | Dliteljnostj | Granica izmereniya |
| --- | --- | --- |
| Polnyij zapusk | 1073,760321584 s | Vremya iskhodnoj mashinnoj zapisi obyortki |
| Vneshnij zapusk polnogo kontura | 1075,501693875 s | Vklyuchayet zapusk samoj obyortki; ne summiruyetsya s predyidusjhej strokoj |
| Finaljnoye primeneniye proyekcii | 247,537050917 s | Odin fakticheskij process, kod 0 |
| Nezavisimaya proverka manifesta | 113,156006959 s | Ispravlennaya polnaya komanda, kod 0; rannij otkaz CLI uchtyon otdeljno |
| Vyisokij chitatelj C iz M1 | 0,651086375 s | Vneshnij monotonnyij tajmer, kod 0 |
| Fast-forward fuma | 0,146432541 s | Izmereniye naznachennogo pisatelya fuma |
| Publikaciya fuma | 2,367544500 s | Izmereniye naznachennogo pisatelya; readback otdeljno |
| Prodvizheniye primary master | 10,864508250 s | Uzkij ispolnitelj s povtornoj priyomkoj i soglasovannyim perekhodom |

Vse znacheniya otnosyatsya k nazvannyim granicam; vnutrenniye i vneshniye vremena ne skladyivayutsya. [Tekusjhij zapros](../zapros.md) prodolzhayet rabotu s paketom shesti novyikh zadach.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 01:19:38 MSK -->
<!-- content-sha256: sha256:695348c2406df452c35a0489ffd00f23957601eb3eb213cd799fb86801f513ef -->
<!-- FUM-MD-RECENCY:END -->
