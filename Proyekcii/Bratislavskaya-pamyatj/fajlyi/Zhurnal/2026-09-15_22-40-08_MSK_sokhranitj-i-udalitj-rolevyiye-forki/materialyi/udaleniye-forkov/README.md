# Arkhivirovaniye rolevyikh forkov

Scenarij sokhranyayet yavno perechislennyiye rolevyiye repozitorii FUM pered otdeljno razreshyonnyim udaleniyem. On ispoljzuyet ustanovlennyij Git, Git LFS i avtorizovannyij GitHub CLI. Osnovnoj repozitorij i zerkala zavisimostej isklyuchenyi tochnyim spiskom.

Zapusk vyipolnyayetsya iz kornya FUM. Peredajte dejstviye `подготовить`, absolyutnyij fizicheskij katalog vne Git cherez `--архив`, susjhestvuyusjhij lokaljnyij FUM cherez `--объекты` i tochnyiye polnyiye imena posle `--репозитории`. Otdeljnoye dejstviye `удалить` ispoljzuyet tot zhe arkhiv; samo nalichiye arkhiva razresheniyem na udaleniye ne yavlyayetsya. Polnyij primer argumentov dostupen cherez `--help`.

Dlya kazhdogo repozitoriya sokhranyayutsya nezavisimyij Git mirror, vse nablyudayemyiye Git refs, otvetyi GitHub i zhurnal otdeljnyikh vyizovov s dliteljnostjyu i SHA-256. Proveryayutsya Git-obyyektyi, ravenstvo ssyilok i otsutstviye zavisimosti ot drugogo object store. Nepustyiye Issues, PR, relizyi, razvyortyivaniya, Actions, wiki i LFS trebuyut rasshireniya arkhiva; scenarij ne vyidayot nepolnyij arkhiv za polnyij.

Pered udaleniyem povtorno proveryayutsya identichnostj, metadannyiye, Git refs i perechislennyiye resursyi. Fajlyi i katalogi arkhiva sinkhroniziruyutsya s postoyannyim nositelem. Namereniye sokhranyayetsya do vyizova GitHub CLI. Posle izvestnogo uspeshnogo otveta proveryayutsya HTTP 404 celevogo repozitoriya i dostupnostj osnovnogo FUM. Neizvestnyij iskhod ili otkaz ostavlyayut namereniye i zapresjhayut avtomaticheskij povtor; operator snachala razbirayet sokhranyonnyij otvet i tekusjheye sostoyaniye.

GitHub CLI trebuyet pravo `delete_repo`. Scenarij ne poluchayet yego samostoyateljno. API udalyayet po tochnomu imeni posle sverki ID; atomarnogo servernogo usloviya na etot ID on ne obesjhayet. Granica — soglasovannaya rabota vladeljca bez konkuriruyusjhego pereimenovaniya libo izmeneniya udalyayemyikh repozitoriyev. Rabotayusjhiye processyi i chuzhiye lokaljnyiye klonyi scenarij ne menyayet.

V etoj sessii podgotovleno 15 arkhivov s 258 Git refs. Pervaya popyitka udaleniya poluchila HTTP 403 iz-za otsutstviya nuzhnogo prava. Posle komandyi poljzovatelya udalitj forki samostoyateljno avtomaticheskoye udaleniye prekrasjheno; process obnovleniya avtorizacii otmenyon. Ni odin uspeshnyij rezuljtat udaleniya agentom ne zayavlyayetsya.

Proverki vyipolnyayutsya cherez shtatnuyu otchyotnuyu obyortku: `python3 -B -m unittest discover` s etim katalogom i shablonom `test_*.py`. Avtonomnyij nabor ne obrasjhayetsya k GitHub i proveryayet dopustimyiye celi, izmenivshiyesya istochniki, otsutstviye arkhiva, tochnyij CLI-vyizov i zapret povtornoj popyitki. Realjnyiye vneshniye zapuski sokhranyayutsya otdeljno v otchyote zadachi. Eto ogranichennyij prototip na Python/CLI; on yesjhyo ne podklyuchyon k Swift-adapteru i grafu strukturiruyusjhikh operatorov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:34:45 MSK -->
<!-- content-sha256: sha256:0e3551aa60f67ae82e238e6fa7cd3749121531542ec56248c697739eba6bee72 -->
<!-- FUM-MD-RECENCY:END -->
