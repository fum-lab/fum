# Korrekciya utverzhdenij tryokh prezhnikh etapov

Eto novoye nablyudeniye po opublikovannyim Git-obyyektam i pervichnomu zhurnalu ispolneniya. Ono ne perepisyivayet prezhniye otchyotyi, rezuljtatyi proverok, profili ili paketyi. Nachaljnaya granica ispravleniya — `abc217c2760c6cbeb778833116a619ba8df644ad`.

## Luna low

Kommit `b2df928066fa84d3bf7ab8100baf519e934e4233` ne podtverzhdayet zayavlennyij GREEN: vse chetyire sokhranyonnyiye mashinnyiye zapisi imeyut kod 1, vklyuchaya zapisj s nazvaniyem GREEN. Obyazateljnyij profilj i realjnyij paket etim etapom ne predstavlenyi. Para soderzhit povtornyij zagolovok instrumentov i nezapolnennyiye elementyi. Eti faktyi ne zamenyayutsya nyineshnimi uspeshnyimi testami.

## Luna high

Kommit `193279364854a6081491e02c26dd8c6f66dce0ca` sokhranil v novom zaprose prezhnyuyu postanovku vmesto dejstviteljnoj komandyi ispravleniya. [Pervichnyij tekst porucheniya](iskhodnoye-porucheniye-luna-high.txt) vosstanovlen iz native stroki 6683; yeyo [tochnyiye granicyi i SHA](granicyi-pervichnyikh-sobyitij.json) pozvolyayut proveritj proiskhozhdeniye. Eto delegirovaniye koordinatora, a ne novoye chelovecheskoye soobsjheniye.

Uspeshnyij iskhod vosjmi testov imel uzkuyu granicu; on ne dokazyival sootvetstviye finansovogo istochnika kazhdomu polyu i tipu operacii. Utverzhdeniye o desyati zamerakh za 0,623 s ne podkrepleno otdeljnyim profilem s iskhodnikami i dliteljnostyami. Tablica vremeni ostalasj shablonnoj. Realjnyij paket nazyival citatu celi proverennyim rezuljtatom; eto nevernaya klassifikaciya.

## Sol high

Kommit `abc217c2760c6cbeb778833116a619ba8df644ad` sokhranil razbor markera, dopuskavshij validnyij khvost vnutri plana ili obesjhaniya. Nyineshnij RED vosproizvyol eto na chetyiryokh kontekstakh. Paket ostavalsya prezhnim i prodolzhal obyyavlyatj celj proverennyim rezuljtatom. Mashinnyiye zapisi zapuskov bez stdout ne zamenyayut otsutstvovavshij samostoyateljnyij vyivod testov. Profilj s desyatjyu dliteljnostyami i khyeshami yavlyayetsya dejstviteljnyim istoricheskim izmereniyem; on sokhranyon, no ne dokazyivayet praviljnostj kontrakta.

Povtornyiye zagolovki, shablonyi i nevernyiye ssyilki ostalisj v opublikovannoj pare. Obyyavleniye kommita proshedshej kontroljnoj tochkoj byilo oshibochnyim: v 20:57:35.034 UTC byil vozvrasjhyon toljko pustoj vyivod bez terminaljnogo koda; v 20:57:42.777 uzhe podtverzhdyon commit abc217c; lishj v 20:57:56.176 pervichnyij zhurnal zafiksiroval zaversheniye proverki svyaznosti s kodom 1. Process proverki 30972 dlilsya 22,145298167 s i otkazal na puti, vyikhodyasjhem za korenj checkout. Mezhdu rannim vozvratom i kommitom vyizova ozhidaniya ne byilo. Chislo 30972 izvestno iz pozdnego native sobyitiya; ne utverzhdayetsya, chto prezhnij agent sokhranil etot identifikator iz rannego otveta. [Pozicii strok 7085, 7087, 7091, 7092 i 7110](granicyi-pervichnyikh-sobyitij.json) vklyuchayut tochnyiye SHA iskhodnyikh bajtov.

## Ogranichennoye izmeneniye sokhranyonnoj istorii

Ispravlenyi toljko desyatj destination v razdelakh zatronutyikh fajlov tryokh zaprosov: 3 + 3 + 4. Shtatnaya navigaciya predyidusjhego zaprosa svyazana s novyim etapom. Doslovnyiye oblasti zaprosov, staryiye otchyotyi, mashinnyiye zapisi, profili i paketyi ne zamenyalisj. [Plan tochnoj korrekcii](korrekciya-ssyilok.json) sokhranyayet patch, SHA do i posle izmeneniya do recency i desyatj izmerenij podgotovki. Sluzhebnyiye metki svezhesti obnovlyayutsya otdeljno.

Pervonachaljnyij pomosjhnik dopuskal sleduyusjhij razdel; nezavisimyij obzor ustanovil, chto v etikh tryokh fakticheskikh fajlakh izmenenyi toljko nuzhnyiye destination, odnako obsjhij otkaz byil nedostatochen. Dopolniteljnaya RED-regressiya i ispravleniye teperj zapresjhayut sleduyusjhij H1/H2. Eto posleduyusjheye usileniye ne podmenyayet khyesh proizvoditelya uzhe vyipolnennoj korrekcii.

## Uchyot povtorov

[Svideteljstva prezhnikh par](svideteljstva-prezhnikh-par.json) svyazyivayut tochnyiye kommityi, puti, SHA, stroki shablonov i iskhodyi proverok. Tri otdeljnyiye paryi zaregistrirovanyi kak [0071/0008, 0009 i 0010](../../../Sboi/FUM-SBOJ-0071-nepolnaya-para-zhurnala-pered-kontroljnoj-tochkoj.md). Rannij kommit do zaversheniya proverki — otdeljnoye proyavleniye [0078/0002](../../../Sboi/FUM-SBOJ-0078-rannij-zapusk-potrebitelya-do-zaversheniya-proizvoditelya.md). Prezhneye ogranichennoye ustraneniye 0078 sokhranyayetsya istoricheski; kartochka snova aktivna.

Nomera soglasovanyi s koordinatorom i vladeljcem `planirovaniye`. Nezavisimyij read-only-audit proveril istoriyu celevyikh kartochek, 60 dostupnyikh iz 61 zaregistrirovannogo worktree i vse 371 ref / 249 tips. Yedinstvennyij nedostupnyij checkout udalyon; yego sokhranyonnyij HEAD vklyuchyon v Git-istoriyu. Na 2026-09-15T21:43:40.616373Z perechenj refs do i posle sovpal, SHA-256 `82274f154fe14dabcc2d6779ca84b736c9a0b16d22b9ec48fa9c3710047fb8a5`; zanyatyi 0071/0001–0007 i 0078/0001. Shtatnyij raspredelitelj naznachayet nomera kartochek, no ne sostavnyiye nomera proyavlenij; ispoljzovan [raneye ustanovlennyij koordinacionnyij sposob](../../2026-09-14_23-44-58_MSK_zaregistrirovatj-sboi-istochnikov-podderzhki/zapros.md). Vladelec podtverdil otsutstviye konfliktov; chuzhiye derevjya i obsjhij state ne izmenyalisj.

Publichnyiye sravniteljnyiye vetki proverenyi zhivyim `ls-remote`: `codex/sravneniye-luna-low-b2df9280`, `codex/sravneniye-luna-high-19327936`, `codex/sravneniye-sol-high-abc217c2` ukazyivayut na sootvetstvuyusjhiye polnyiye OID vyishe. Praviljnyiye lokaljnyiye `refs/heads/codex/...` sozdanyi; prezhniye oshibochnyiye imena s povtornyim `refs/heads/` ne udalyalisj. Nalichiye refs sokhranyayet istoriyu, a ne oznachayet priyomku yeyo soderzhimogo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:01:16 MSK -->
<!-- content-sha256: sha256:1dea3176f081a8e100ef9ce38d42aecd2763cb6551d4fb620f543d68fd549504 -->
<!-- FUM-MD-RECENCY:END -->
