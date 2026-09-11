# Otchyot 2026-09-11 15:22:57 MSK - Proveritj paket sovmestimosti master i FUMA

Finaljnaya priyomka shesti paketov sovmestimosti posle opublikovannoj kontroljnoj tochki. Polnotu iskhodnogo obyyoma sokhranyayut [predyidusjhij otchyot](../2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/otchyot.md) i [karta perenosa](../2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/materialyi/karta-perenosa.md). Rezuljtat etapa ogranichen sobstvennoj vetkoj; FUM-STEP-0175 v master ne zavershyon.

## Profilj vremeni vyipolneniya

| Stadiya               | Dliteljnostj         | Granicyi i sposob izmereniya                                                       |
| -------------------- | -------------------- | -------------------------------------------------------------------------------- |
| Podgotovka i chteniye  | ne izmereno          | Monotonnyij obsjhij interval ne sobiralsya; zadnim chislom ne ocenivayetsya             |
| Standartnaya priyomka  | po stroke nizhe       | Pryamoj sostavnoj vyizov otchyotnoj obyortki; vlozhennyiye shagi ne skladyivayutsya povtorno |
| Zamyikaniye i dostavka | vne mashinnoj granicyi | Primeneniye, nezavisimaya proverka, tochnyij commit/push i readback posle zakryitiya   |

Granica profilya: etap nachat 2026-09-11 15:22:57 MSK; izmeryayetsya toljko obyyavlennyij pryamoj proverochnyij process. Chteniye, Git-publikaciya i zamyikaniye posle zakryitiya ne vklyuchayutsya v summu i ne ocenivayutsya zadnim chislom. FIFO ne primenyalsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                | Dliteljnostj | Rezuljtat         |
| -------------------------------------------------------------------- | ------------ | ----------------- |
| [Korenj] Itogovaya standartnaya priyomka paketa sovmestimosti           | 44,208 s     | prervano — SIGINT |
| [Korenj] Adresno proveritj ispravlennyij otchyot i svyaznostj podgotovki | 40,955 s     | uspeshno           |

Obsjheye vremya pryamyikh zapuskov proverok: 85,163 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:0a8db6f49e6f54b9906f6b331d73ee730d6c9700fa228da342afe491c4123c21.
Kontekst soderzhimogo: sha256:288e677f520fd3fafb0dc8375b433abd2f0a9e38fa84f54eba608b5512ab5d33.
Polnyikh popyitok: 1; uspeshnyikh: 0.
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

Soderzhateljnyij kod sovpadayet s kontroljnyim kommitom `69e267b75f83f3f762379cfb61dd09c3d4df125f`. Na nyom raneye proshli 82 sovmestnyikh adresnyikh testa i semj proverok sokhraneniya istochnika kontura i strogikh isklyuchenij. Adresnaya sverka podtverdila 419 isklyuchenij L, prezhniye 350 bez izmenenij i yedinstvennoye dobavleniye v obyichnuyu politiku; standartnyij scanner vernul 0. Profili ne obosnovali dopolniteljnyikh optimizacij.

Standartnaya priyomka zapuskayetsya komandoj `run-smoke-check.py --repo-root . --request <этот запрос> --commit-message-file <частный файл> --codex-thread-id <UUID задачи>` cherez sobstvennuyu obyortku s klassom `полная` i skhemoj v4. Yeyo fakticheskij iskhod khranitsya nizhe v mashinnom bloke; nazvaniye klassa ne oznachayet vyibora shirokogo CLI-profilya. Posle uspeshnogo zapuska sleduyut read-only `проверить-план`, zakryitiye otchyota, rovno odno shtatnoye primeneniye proyekcii i odna nezavisimaya proverka manifesta. Eti komandyi zamyikaniya ne dobavlyayut zapisj v zakryityij otchyot.

## Resheniya i ogranicheniya

Ispravlennyij predprosmotr proshyol adresnuyu proverku svyaznosti: otdeljnaya zapisj etogo etapa sokhranyayet uspeshnyij iskhod. Chteniyem vyiyavlena nesovmestimostj Git-chitatelya M s v4/report-v3. Posle razbora koordinator otozval predpolozheniye ob obyazateljnosti novogo chitatelya dlya blizhajshego C2: M yavno podderzhivayet otdeljnyij novyij etap v3/report-v2. Oba mekhanizma v pakete sokhranenyi pobajtovo iz M. Etot etap sokhranyayetsya otkryitoj kontroljnoj tochkoj, yego dve zapisi ne perepisyivayutsya. Sleduyusjhaya priyomka v otdeljnoj papke obuslovlena sovmestimostjyu s iskhodnyim M, ne obkhodom rannego otkaza.

[Doslovnyiye utochneniya](materialyi/koordinacionnyiye-utochneniya.md) i [razbor](materialyi/granica-chitatelya-i-priyomki.md) sokhranyayut proiskhozhdeniye resheniya, tochnyij plan obyichnoj priyomki i yeyo otlichiye ot specialjnogo dopuska C2. Predlozheniye svideteljstva polnyikh Unix-rezhimov ostalosj posleduyusjhej rabotoj; nikakogo koda novogo adaptera i novyikh testov po nemu ne sozdavalosj. Otdeljnyiye [FUM-SBOJ-0079](../../Sboi/FUM-SBOJ-0079-zavisimyij-smoke-posle-otkaza-predprosmotra.md) i [FUM-SBOJ-0080](../../Sboi/FUM-SBOJ-0080-Git-chitatelj-ne-prinimayet-raundyi.md) svyazanyi s aktualjnoj kartochkoj 0175 i ne obyyavlenyi ustranyonnyimi.

Pervaya polnaya popyitka shtatno prervana cherez 44,208 s na primenenii proyekcii do avtonomnyikh testov. Prichina — sobstvennaya oshibka posledovateljnosti podgotovki: `предпросмотр` novogo pustogo zhurnala vernul 1, no posleduyusjhij smoke byil zapusjhen bez proverki iskhoda i sokhranil nezapolnennyij marker otchyota. Pozdnyaya priyomka takogo vkhoda zavedomo nevozmozhna. Pokoleniye etoj popyitki ne obyyavlyayetsya ustanovlennyim. Posle ostanovki ispravlen predprosmotr; novoye iskhodnoye svideteljstvo i granica vosstanovleniya vnesenyi v zapros. Povtor vyipolnyayetsya posle realjnogo ispravleniya otchyota i posledovateljnoj proverki podgotovki, ne kak povtor uspeshnogo polnogo zapuska.

Tri dochernikh analiza zakonchenyi; dopolniteljnyikh pisatelej net. Posledneye revjyu tipov i grafa ne nashlo blokiruyusjhikh zamechanij. Vse novyiye zavisimosti proveryayusjhej storonyi lezhat v rekursivno sveryayemom `Инструменты`. Osnovnoj mekhanizm sliyaniya, scanner, pravila, standartnyij profilj i gitlink sokhranenyi.

Tyazhyoloye okno pervonachaljnoj popyitki byilo peredano posle zaversheniya ustanovok, sborok i konvertacii VM; gostevaya 4 CPU / 8 GiB togda prostaivala. Posle SIGINT i adresnoj svyaznosti korenj podtverdil otsutstviye sobstvennyikh tyazhyolyikh processov i yavno osvobodil okno. Po pozdnej koordinacii snachala rabotayet Linux VM, zatem finansovaya zadacha, posle nikh eta zadacha. Do peredachi novyij full i boljshoye pokoleniye ne zapuskayutsya.

[FUM-SBOJ-0076](../../Sboi/FUM-SBOJ-0076-propusk-proverki-predkov-kataloga-tipov.md) ostayotsya aktivnyim do prinyatiya ispravleniya v master i proverki novogo kandidata. Sleduyusjhij shag koordinatora — prinyatj opublikovannyij paket v master, zakrepitj novyij M i proveritj kandidat s roditelyami [L, M] prezhnim strogim konturom iz novogo M. Staryij dopusk L ne dokazyivayet etu priyomku. Master/fuma i chuzhiye indeksyi ne menyayutsya.

## Istochniki

- [Iskhodnyiye komandyi i granica prodolzheniya](zapros.md).
- [Proiskhozhdeniye pervichnyikh komand](../2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/materialyi/proiskhozhdeniye-komand.json).
- [Sverka politiki](../2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/materialyi/sverka-politiki.json).
- [FUM-STEP-0175](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:47:51 MSK -->
<!-- content-sha256: sha256:7a1663eaa6ac64c5414e40acaf8022eb918b4044448a81864c915b5aa21165b6 -->
<!-- FUM-MD-RECENCY:END -->
