+++
schema_version = 1
card_id = "FUM-STEP-0207"
status = "completed"
+++
# Realizovatj perenos rabochikh derevjyev

## Zadacha

Realizovatj pervyij sokhranyayemyij instrument perenosa odnogo linked worktree v predelakh odnogo fajlovogo toma s rekursivnyimi submodule. Rezuljtat vklyuchayet plan bez zapisi, ispolneniye konechnoj tranzakcii, prodolzheniye posle preryivaniya i tochnyij povtor. Predmetnyij priyom vyipolnyayetsya na avtonomnyikh lokaljnyikh fiksturakh.

Instrument realizuyet [vozobnovlyayemyij perenos rabochikh derevjyev](../../Trebovaniya/🟡-vozobnovlyayemyij-perenos-rabochikh-derevjyev.md). Pervyij perenos ne menyayet OID, refs, indeks i lokaljnyiye dannyiye peremesjhayemyikh repozitoriyev; menyayutsya toljko fizicheskoye razmesjheniye i soglasovannyiye Git-privyazki.

## Pochemu sejchas

Poljzovatelj poruchil avtomatizirovatj perenos takikh uzlov dlya posleduyusjhego obyyedineniya vetok raznyikh poljzovatelej. Podtverzhdyonnoye predyidusjheye utochneniye otnositsya k papke «Poduzlyi» v papke proyekta. Istoricheskaya inventarizaciya obnaruzhila linked worktree, rekursivnyiye submodule i ignoriruyemyiye dannyiye; ona zadayot formu fikstur, no ne dokazyivayet tekusjhuyu gotovnostj zhivyikh katalogov k perenosu.

Do novogo koda izuchitj susjhestvuyusjhiye mekhanizmyi kanonicheskogo JSON i chteniya Git-obyyektov v Instrumentyi/fum-snimki-indeksa, proverki metadannyikh zavisimostej v Instrumentyi/fum-proverka-git-zavisimostej i ustojchivogo pereimenovaniya bez zamenyi v Instrumentyi/fum-bratislavskaya-proyekciya-pamyati. Istoricheskaya FUM-STEP-0148 sokhranyayet proiskhozhdeniye topologii, bez dopuska starogo pula i FIFO.

## Kriterii zaversheniya

- Kanonicheskij konechnyij plan svyazyivayet identichnostj operacii, ozhidayemyiye iskhodnyiye HEAD, polnyiye refs, indeksyi, common-dir, Git-privyazki vlozhennyikh repozitoriyev i otnositeljnyiye marshrutyi. Chastnoye sopostavleniye s fizicheskimi kornyami ostayotsya vne publikuyemogo rezuljtata. Postroyeniye i prosmotr plana nichego ne zapisyivayut.
- Pervyij RED ispoljzuyet otdeljnyij lokaljnyij linked worktree, rekursivnyij submodule i ignoriruyemyij fajl: posle perenosa kataloga process preryivayetsya do remonta privyazok, novyij process vosstanavlivayet tu zhe operaciyu i sokhranyayet vse iskhodnyiye bajtyi, OID, refs i indeksyi. Otkryityiye fiksturyi dopolniteljno pokryivayut otnositeljnyiye i absolyutnyiye ssyilki .git i core.worktree.
- Konechnyij avtomat faz sokhranyayetsya do sootvetstvuyusjhikh effektov. Primeneniye i vozobnovleniye sveryayut tochnyij istochnik, naznacheniye, sokhranyonnoye namereniye i fakticheskuyu fazu; poteryannyij otvet ne vyizyivayet povtornogo peremesjheniya. Posle kazhdogo ustojchivogo perekhoda zakreplenyi zatronutyiye katalogi i sostoyaniye. Remont ogranichen metadannyimi perenosimogo worktree i yego vlozhennyikh repozitoriyev.
- Uzhe zanyatoye naznacheniye, izmenivshijsya istochnik ili indeks, chuzhoye vladeniye, nesoglasovannaya Git-privyazka, nesovpadayusjhij registr, symlink v upravlyayusjhem puti i drugoj fajlovyij tom dayut yavnyij otkaz do nepredusmotrennoj zapisi. Susjhestvuyusjhiye katalogi i fajlyi naznacheniya ne zamenyayutsya.
- Katalog perenositsya so vsemi otslezhivayemyimi, neotslezhivayemyimi i ignoriruyemyimi dannyimi. Povtor ne ispoljzuyet clean, prune, remove, peresozdaniye worktree libo inicializaciyu zavisimostej dlya vosstanovleniya iskhodnogo sostoyaniya.
- Avtonomnyiye RED/GREEN i profilj otdeljno pokazyivayut sbor plana, pereimenovaniye, remont, sverku i vozobnovleniye. Do zayavleniya podderzhki kazhdoj platformyi yestj vosproizvodimyij zapusk na nej; otsutstviye platformennogo svideteljstva sokhranyayetsya kak ogranicheniye.
- Opublikovannyiye iskhodniki, fiksturyi i komandyi vosproizvedeniya nakhodyatsya v tematicheskom instrumente monorepozitoriya. Pervyij rezuljtat ne peremesjhayet zhivyiye poljzovateljskiye derevjya i ne menyayet sokhranyonnyiye proyektyi Codex. Gotovnostj Git-privyazok i gotovnostj vneshnikh privyazok razlichayutsya.

## Proiskhozhdeniye i granicyi

Osnovnaya komanda — «Delaj avtomatizaciyu perenosa takikh uzlov — ona prigoditsya pri myordzhe raznyikh vetok raznyikh poljzovatelej.». Pervichnyij ekzemplyar e956b9bee25b4e0bb93d632313464ac08fb1745c317d376508a165c7128d2175 otnositsya k zadache 01a07d3d-d376-7ad2-aafc-67e4c25a67eb. Tochnyiye bajtyi s zavershayusjhim LF i podtverzhdyonnyiye predshestvuyusjhiye utochneniya sokhranyayutsya v svyazannom zaprose.

Perenos mezhdu tomami, perenos zhivyikh derevjyev, razresheniye Git-konfliktov, izmeneniye naznachenij Codex i vozobnovleniye istoricheskogo avtokonvejyera v pervyij rezuljtat ne vkhodyat. Dlya kazhdogo sleduyusjhego primeneniya trebuyetsya novaya proverka fakticheskogo sostoyaniya i vladeniya.

## Rezuljtat

Sokhranyon [instrument perenosa](../../Instrumentyi/fum-perenos-rabochikh-derevjyev/SKILL.md) s planom bez zapisi, proveryayemyimi privatnyimi privyazkami, ustojchivyimi fazami, ogranichennyim remontom i povtorom otdeljnyim processom. [Otchyot realizacii](../../Zhurnal/2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/otchyot.md) svyazyivayet pervonachaljnyij RED, 15 regressionnyikh kontraktov i dopolniteljnuyu avarijnuyu fiksturu pervichnoj podgotovki, iskhodnyij/itogovyij profili i tochnyiye komandyi vosproizvedeniya.

Pervichnaya podgotovka do ustanovki osnovnogo zhurnala imeyet yavnyij bezopasnyij otkaz s sokhraneniyem neizvestnogo khvosta; avtomaticheskoye prodolzheniye nachinayetsya posle ustanovki namereniya. Realjnaya podderzhka podtverzhdena toljko na macOS arm64. Plan i scenarii ne menyayut proyektyi Codex; pervyij zhivoj perenos i dopolniteljnyiye platformyi ostayutsya otdeljnoj priyomkoj FUM-REQ-0066.

## Istochniki

- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:03:10 MSK -->
<!-- content-sha256: sha256:d6757424425b23cf80db27ffc51963b23e09622333fbac1c14a13b332bfd504f -->
<!-- FUM-MD-RECENCY:END -->
