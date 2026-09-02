# Otchyot 2026-08-26 13:36:12 MSK - Isklyuchitj dublirovaniye polnoj regressii pered finaljnyim smoke check

Podgotovleno semanticheskoye dvukhroditeljskoye sliyaniye kandidata `1a47d4746324bdb361d99398dc235d9bea192c4b` v iskhodnuyu vershinu `master` `7d3ef6ce601794678dac3e87f051dc0fc843c1bc`. Novyij kontur v3 svyazyivayet kazhduyu adresnuyu, diagnosticheskuyu ili polnuyu po roli proverku s Git-otpechatkom i yavno obnaruzhivayet perekryivayusjhiyesya polnyiye naboryi na odnom otpechatke. Uspeshnyij manual-putj dopuskayet `проверить-план` i posleduyusjheye zakryitiye toljko posle yedinstvennogo poslednego uspeshnogo smoke-check; otkaznoj plan mozhet byitj chestno sokhranyon kak `не готов`.

Dejstvuyusjhij `manual-sequential-v1` sokhranyon: FIFO, pool, selector, worktree, reviewer, integrator, CAS i continuation ostayutsya istoricheskimi konturami, a ne marshrutom tekusjhej pishusjhej sessii. Istoricheskij zhurnal kandidata vstroyen v khronologiyu, a FUM-STEP-0147 zavershena i snyata iz neispolnyayemoj planovoj vyiborki sleduyusjhikh shagov.

Lokaljnyij ignored `.obsidian/graph.json` ostalsya vne Git s iskhodnyim SHA-256 `8d50db66b47c1b5f2298cc9c2cf55bc2f6c6111aff520e8c49564369862fb8df`; otslezhivayemaya opornaya data Obsidian i drugiye ustojchivyiye nastrojki sokhranenyi.

## Profilj vremeni vyipolneniya

| Stadiya                  | Dliteljnostj         | Granicyi i sposob izmereniya                                                                                   |
| ----------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------ |
| Proverka dopuska zapisi | ne izmerena otdeljno | Do pervoj zapisi sverenyi `HEAD`, `master`, pervichnyij checkout, chistota i otsutstviye drugogo pisatelya |
| Semanticheskoye sliyaniye | ne izmerena otdeljno | Ot metki `13:36:12 MSK`: audit kandidata, merge, razresheniye 18 konfliktov, khronologiya i planirovaniye                |
| Adresnyiye proverki     | sm. mashinnyiye zapisi  | Kazhdyij vyizov uchtyon obyortkoj monotonnoj dliteljnostjyu i tochnyim Git-otpechatkom                                    |
| Standartnyij smoke-check  | sm. mashinnyiye zapisi   | Neuspeshnaya popyitka ostanovilasj na svyaznosti; posle ispravleniya zhurnala poslednij uspeshnyij sostavnoj vyizov ispoljzuyet standartnyij dokumentacionnyij profilj; CLI-polnyij profilj ne zapuskayetsya |
| Lokaljnyij merge-kommit | ne izmeryayetsya        | Odin lokaljnyij dvukhroditeljskij kommit na `refs/heads/master`; push i continuation ne vyipolnyayutsya                                      |

Granica profilya: ot kanonicheskoj metki `2026-08-26 13:36:12 MSK` do zakryitiya mashinnogo snimka; ozhidaniya FIFO ne byilo, peredacha ili sleduyusjhaya zadacha ne vkhodyat v kontur.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:cc65bd8d7f2687c877e00f6c01990f6ba1d07d262bfab153ff1ae400c587c775 -->

| Vyizov                                                                                                    | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Adresnyiye testyi zhurnaljnoj obyortki proverok                                              | 20,676 s     | uspeshno   |
| [kornevoj agent] Adresnyiye testyi proverki mashinno lokaljnyikh putej                                         | 2,154 s      | uspeshno   |
| [kornevoj agent] Adresnyiye testyi svezhesti Markdown                                                        | 0,243 s      | uspeshno   |
| [kornevoj agent] Adresnyiye testyi kompleksnoj proverki repozitoriya                                         | 23,688 s     | uspeshno   |
| [kornevoj agent] Proverka aktualjnosti planovogo reyestra                                                 | 0,38 s       | uspeshno   |
| [kornevoj agent] Proverka dekompozicii pravil agentov                                                    | 0,151 s      | uspeshno   |
| [kornevoj agent] Proverka snimka obyyavlenij koda                                                         | 22,142 s     | uspeshno   |
| [kornevoj agent] Adresnaya proverka legacy proyekcii sleduyusjhego shaga                                       | 1,175 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti Markdown posle generacii                                              | 0,713 s      | uspeshno   |
| [kornevoj agent] Proverka strukturyi papok zaprosov i khronologii                                          | 14,391 s     | uspeshno   |
| [kornevoj agent] Proverka probeljnoj chistotyi proindeksirovannogo sliyaniya                                 | 0,041 s      | uspeshno   |
| [kornevoj agent] Svyaznostj rabochej sessii pered finaljnyim smoke-check                                    | 32,011 s     | neuspeshno |
| [kornevoj agent] Finaljnyij standartnyij smoke-check dokumentacionnogo profilya                             | 67,617 s     | neuspeshno |
| [kornevoj agent] Povtornaya svyaznostj rabochej sessii posle yavnogo markera udaleniya                        | 32,037 s     | uspeshno   |
| [kornevoj agent] Finaljnyij standartnyij smoke-check dokumentacionnogo profilya posle ispravleniya svyaznosti | 134,632 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 352,051 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Tochnyiye `HEAD`, `refs/heads/master`, `MERGE_HEAD`, tip kandidata i merge-base sverenyi; nerazreshyonnyikh putej i conflict-marker net.
- 74 testa zhurnaljnoj obyortki, 70 testov smoke-ispolnitelya, 32 testa mashinno-lokaljnyikh putej, 9 testov recency i odin adresnyij legacy-test planovoj proyekcii prokhodyat.
- Planovyij reyestr, 210 dekompozirovannyikh pravil v 11 temakh i snimok 43 209 obyyavlenij koda sovpadayut s istochnikami.
- Khronologiya svyazyivayet importirovannuyu sessiyu mezhdu `18:46:19` i `19:25:10`; proyekciya `master` soderzhit 10 kandidatov: 2 dostupnyikh dlya ruchnogo vyibora, 5 priostanovlennyikh i 3 zablokirovannyikh.
- Predfinaljnaya svyaznostj i pervaya polnaya popyitka chestno zafiksirovali odin i tot zhe otkaz: prezhnij putj pereimenovannoj kartochki FUM-STEP-0147 otsutstvoval v yavnom perechne udalyonnyikh fajlov. V zapros dobavlen tochnyij marker udaleniya; povtornyiye proverki vyipolnyayutsya na novom Git-otpechatke, a neuspeshnyiye zapisi sokhranenyi bez perepisyivaniya.
- Vo vremya read-only-obzora pered staging komanda `git diff --check HEAD` byila oshibochno vklyuchena v obsjhij inspekcionnyij vyizov vne obyortki i zavershilasj nulevyim kodom; v priyomochnoye svideteljstvo vkhodit toljko povtor proverki indeksa cherez zhurnaljnuyu obyortku.
- Adresnyiye proverki, recency i svyaznostj zamyikayutsya yedinstvennyim finaljnyim standartnyim smoke-check; zakryityij snimok dokazyivayet otsutstviye dublya polnoj regressii, a probeljnaya chistota povtorno sveryayetsya read-only posle zakryitiya.

## Resheniya i ogranicheniya

- Skhema `fum.test-run.v3` khranit zakryityij shestipolevoj profilj, a `fum.test-run-report.v2` svyazyivayet zakryitiye s Git-otpechatkom. Istoricheskij v1-prefik dopustim toljko do pervoj v3-zapisi; v2 ne smeshivayetsya s v3, a lyubaya legacy-zapisj posle nachala v3-khvosta zapresjhena.
- Klass `полная` oboznachayet rolj yedinstvennogo finaljnogo sostavnogo vyizova, a ne obyazateljnyij CLI-profilj `--профиль полный`; dlya tekusjhego dokumentacionnogo prototipa finaljnyim yavlyayetsya standartnyij smoke-check.
- Importirovannyij mekhanizm adaptirovan k `manual-sequential-v1`: normativnyij kontur zavershayetsya odnim lokaljnyim kommitom na `master` bez continuation.
- Kandidatnaya data Obsidian `2026-08-15` ne prinyata: otslezhivayemyij `.obsidian/fum-recency-reference-date` sokhranyayet znacheniye tekusjhego `master`, a lokaljnyij `graph.json` ne otslezhivayetsya i ne peresobirayetsya.
- Kommit sozdayotsya rovno odin raz posle zakryitiya otchyota; push, vneshniye effektyi i sleduyusjhaya zadacha ne vyipolnyayutsya.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [istoricheskij zapros kandidata](../2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [istoricheskij otchyot kandidata](../2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/otchyot.md)
- [zavershyonnaya kartochka FUM-STEP-0147](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0147-isklyuchitj-dublirovaniye-polnoj-regressii-pered-finaljnyim-smoke-check.md)
- [pravilo proverok, kommita i publikacii](../../Pravila/agentov/proverki-kommit-i-publikaciya.md)
- [lokaljnaya avtomatizaciya otchyotov o zapuskakh proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)
- [lokaljnaya kompleksnaya proverka repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 14:38:01 MSK -->
<!-- content-sha256: sha256:c2252d18cbac2296997502f1b731b90b1488b064f27876aee99b8642590c76e6 -->
<!-- FUM-MD-RECENCY:END -->
