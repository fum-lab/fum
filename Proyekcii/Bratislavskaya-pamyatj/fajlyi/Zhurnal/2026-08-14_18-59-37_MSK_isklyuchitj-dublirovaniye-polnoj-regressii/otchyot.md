# Otchyot 2026-08-14 18:59:37 MSK - Isklyuchitj dublirovaniye polnoj regressii

Zavershena FUM-STEP-0147: uspeshnyij putj rabochej sessii teperj razlichayet adresnyiye, diagnosticheskiye i polnyiye proverki i prinimayet rovno odin finaljnyij polnyij smoke-check. Kazhdyij novyij zapusk zapisyivayetsya po zakryitoj skheme `fum.test-run.v3` s shestipolevyim profilem klassa, avtomaticheskim SHA-256-otpechatkom Git-snimka, klyuchami polnyikh naborov, prichinoj diagnostiki, ssyilkoj na nablyudayemyij otkaz i ozhidayemyim dopolniteljnyim svideteljstvom. Tochno raspoznannyij smoke-check poluchayet klyuchi iz fakticheski sformirovannogo plana, a iskhodyi — iz dostignutyikh nablyudenij, a ne iz svobodnoj metki vyizova.

Analiticheskij plan sopostavlyayet rannij polnyij ili diagnosticheskij okhvat s finaljnyim planom na tom zhe snimke. On otdeljno pokazyivayet dliteljnostj, status i osnovaniye kazhdogo peresecheniya i nepokryitogo diagnosticheskogo ostatka, razreshayet lokalizaciyu toljko po tochnomu UUID predshestvuyusjhego neuspeshnogo zapuska na tom zhe otpechatke i otklonyayet povtornuyu polnuyu regressiyu bez takogo svideteljstva. Komanda toljko dlya chteniya `проверить-план` dopuskayet lishj otkryituyu sessiyu, rovno odin uspeshnyij terminaljnyij polnyij progon, yego posledneye polozheniye i neizmennostj snimka posle nego. Otobrazhayemyij normativnyij kontur stadij ostayotsya deklaraciyej protokola; mashinnyij verdikt stroitsya toljko iz dokazannyikh invariantov zapisej i otpechatka, a RED/GREEN, planovyiye kontraktyi, svezhestj i svyaznostj podtverzhdayutsya otdeljnyimi profiljnyimi proverkami.

## Profilj vremeni vyipolneniya

| Stadiya                                  | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                       |
| --------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Marshrutizaciya, rezervirovaniye i dopusk  | ne izmereno  | Yedinaya predvariteljnaya proverka do nachala soderzhateljnoj rabotyi; monotonnaya granica ne sokhranyalasj                                               |
| TDD-realizaciya i audityi                 | ne izmereno  | Neperekryivayusjhiyesya RED/GREEN-vyizovyi izmerenyi otchyotnoj obyortkoj i perechislenyi v mashinnom bloke; ruchnaya rabota yedinoj granicyi ne imela              |
| Pravila i planovaya pamyatj               | ne izmereno  | Soderzhateljnoye redaktirovaniye, kanonicheskoye pereimenovaniye kartochki i peresborka proizvodnyikh reyestrov; yedinaya monotonnaya granica ne sokhranyalasj  |
| Finaljnyij polnyij smoke-check            | ne izmereno  | Mashinnyij blok razdeljno sokhranyayet neuspeshnuyu polnuyu popyitku i yedinstvennuyu uspeshnuyu finaljnuyu zapisj na ispravlennom Git-snimke                 |
| Terminaljnaya peredacha rezuljtata        | ne izmereno  | Stadiyu zamknut khyeshirovannaya kvitanciya rezuljtata i chteniye osvobozhdeniya slota; ona ne vkhodit v dostupnyij do kommita mashinnyij zhurnal               |

Granica profilya: s 2026-08-14 18:59:37 MSK do terminaljnoj kvitancii rezuljtata i osvobozhdeniya `слот-0006`; okhvat vklyuchayet marshrutizaciyu, dopusk, soderzhateljnuyu rabotu, proverki i terminaljnuyu peredachu, no ne posleduyusjhiye otdeljnyiye naznacheniya recenzenta i integratora.

Chastj adresnyikh vyizovov vyipolnyalasj paralleljno. Poetomu summa dliteljnostej strok mashinnogo bloka pokazyivayet polnyij uchtyonnyij obyyom pryamyikh zapuskov i ne yavlyayetsya vremenem odnoj posledovateljnoj stadii ili vsej sessii po nastennyim chasam.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:2640f6be4b994ddfd0060eb2ff98939053f249fcf61651d2d86af436fa763d6e -->

| Vyizov                                                                                         | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] RED: ekonomnyij poryadok proverok i obnaruzheniye dublirovaniya                   | 7,439 s      | neuspeshno |
| [kornevoj agent] GREEN: profilirovannyij ekonomnyij poryadok proverok                            | 8,326 s      | neuspeshno |
| [kornevoj agent] GREEN: povtor profilirovannogo ekonomnogo poryadka proverok posle ispravleniya | 8,797 s      | uspeshno   |
| [kornevoj agent] GREEN: ograzhdeniye poslednego polnogo progona i rezhima v3                     | 8,683 s      | uspeshno   |
| [kornevoj agent] RED: usilennyiye granicyi ekonomnogo plana proverok                             | 10,052 s     | neuspeshno |
| [kornevoj agent] GREEN: usilennyiye granicyi ekonomnogo plana proverok                           | 19,64 s      | neuspeshno |
| [kornevoj agent] GREEN: polnyij nabor avtomatizacii profilirovannyikh zapuskov                   | 16,919 s     | uspeshno   |
| [kornevoj agent] RED: chteniye profilirovannoj istorii obsjhim smoke-check                        | 0,131 s      | neuspeshno |
| [kornevoj agent] GREEN: chteniye profilirovannoj istorii obsjhim smoke-check                      | 0,122 s      | uspeshno   |
| [kornevoj agent] RED: neuspeshnaya nepokryitaya diagnostika                                       | 17,148 s     | neuspeshno |
| [kornevoj agent] RED: povtor finala i aktivnaya zapisj                                         | 17,963 s     | neuspeshno |
| [kornevoj agent] GREEN: plan diagnostik i povtor polnogo progona                              | 16,524 s     | uspeshno   |
| [kornevoj agent] RED: mashinno-lokaljnyiye puti chitayut v3                                        | 2,416 s      | neuspeshno |
| [kornevoj agent] GREEN: mashinno-lokaljnyiye puti chitayut v3                                      | 2,307 s      | uspeshno   |
| [kornevoj agent] RED: dokazannyij plan otdelyon ot normativnogo kontura                         | 0,177 s      | neuspeshno |
| [kornevoj agent] RED: otpechatok uchityivayet dirty gitlink                                       | 0,787 s      | neuspeshno |
| [kornevoj agent] RED: novyiye proverki zapresjhenyi vo vremya finala                                | 0,518 s      | neuspeshno |
| [kornevoj agent] GREEN: polnyij nabor otchyotov o zapuskakh proverok                              | 17,732 s     | uspeshno   |
| [kornevoj agent] RED: tochnyiye flagi i obyazateljnyij razdelitelj CLI                             | 0,128 s      | neuspeshno |
| [kornevoj agent] RED: tochnyiye flagi i obyazateljnyij razdelitelj CLI                             | 0,93 s       | neuspeshno |
| [kornevoj agent] GREEN: tochnyij CLI i dokazannyij snimok                                        | 19,064 s     | uspeshno   |
| [kornevoj agent] RED: istoricheskij khvost zakryivayet novyij zapusk                               | 0,717 s      | neuspeshno |
| [kornevoj agent] RED: gotovyij snimok neljzya vozobnovitj                                       | 0,805 s      | neuspeshno |
| [kornevoj agent] RED: izmenyonnyij podmodulj zakryivayet otpechatok                                | 1,179 s      | neuspeshno |
| [kornevoj agent] GREEN: istoriya, vozobnovleniye i podmoduli                                    | 23,407 s     | uspeshno   |
| [kornevoj agent] Adresnaya proverka potrebitelya istorii smoke-check                            | 30,015 s     | uspeshno   |
| [kornevoj agent] Adresnaya proverka mashinno-lokaljnyikh putej                                    | 2,966 s      | uspeshno   |
| [kornevoj agent] RED: fail-closed granicyi plana i vozobnovleniya                               | 1,996 s      | neuspeshno |
| [kornevoj agent] GREEN: fail-closed granicyi plana i vozobnovleniya                             | 1,741 s      | uspeshno   |
| [kornevoj agent] RED: stabiljnaya svezhestj upravlyayemogo bloka zapuskov                         | 0,09 s       | neuspeshno |
| [kornevoj agent] GREEN: stabiljnaya svezhestj upravlyayemogo bloka zapuskov                       | 0,081 s      | uspeshno   |
| [kornevoj agent] Adresnaya proverka avtomatizacii profilirovannyikh zapuskov                     | 21,668 s     | uspeshno   |
| [kornevoj agent] Adresnaya proverka svezhesti Markdown                                          | 0,218 s      | uspeshno   |
| [kornevoj agent] GREEN: polnyij nabor stabiljnoj svezhesti Markdown                             | 0,293 s      | uspeshno   |
| [kornevoj agent] Adresnaya proverka selektora sleduyusjhego shaga                                  | 197,031 s    | neuspeshno |
| [kornevoj agent] Adresnaya proverka planovogo reyestra                                          | 4,367 s      | uspeshno   |
| [kornevoj agent] Vosproizvodimaya validaciya planovogo reyestra                                  | 0,512 s      | uspeshno   |
| [kornevoj agent] Zapret novyikh latinskikh obyyavlenij koda                                       | 3,952 s      | neuspeshno |
| [kornevoj agent] GREEN: zapisj osnovnoj vetki proveryayetsya iz pool-worktree                    | 1,614 s      | uspeshno   |
| [kornevoj agent] GREEN: kirillicheskiye obyyavleniya i stabiljnaya svezhestj                        | 0,283 s      | uspeshno   |
| [kornevoj agent] GREEN: zapret novyikh latinskikh obyyavlenij koda                                | 3,824 s      | neuspeshno |
| [kornevoj agent] Diagnostika ostatka latinskikh obyyavlenij                                     | 7,458 s      | uspeshno   |
| [kornevoj agent] GREEN: polnyij nabor selektora sleduyusjhego shaga                                | 6,219 s      | neuspeshno |
| [kornevoj agent] GREEN: obnovlyonnyij snimok latinskikh obyyavlenij                               | 11,691 s     | neuspeshno |
| [kornevoj agent] GREEN: povtor proverki snimka obyyavlenij posle vosstanovleniya                | 3,742 s      | uspeshno   |
| [kornevoj agent] GREEN: povtor polnogo nabora selektora posle vosstanovleniya                  | 179,612 s    | uspeshno   |
| [kornevoj agent] RED: lokalizaciya trebuyet imenno neuspeshnyij status                            | 1,045 s      | neuspeshno |
| [kornevoj agent] GREEN: lokalizaciya trebuyet imenno neuspeshnyij status                          | 1,029 s      | uspeshno   |
| [kornevoj agent] GREEN: polnyij nabor tochnoj lokalizacii otkaza                                | 24,119 s     | uspeshno   |
| [kornevoj agent] Diagnostika ostatka posle tochnoj lokalizacii otkaza                          | 3,821 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti Markdown                                                   | 0,916 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti grafa Obsidian                                             | 0,507 s      | uspeshno   |
| [kornevoj agent] Proverka svyaznosti rabochej sessii                                            | 32,924 s     | neuspeshno |
| [kornevoj agent] Proverka reyestra planirovaniya                                                | 0,487 s      | uspeshno   |
| [kornevoj agent] Proverka mashinno-lokaljnyikh putej                                             | 15,295 s     | uspeshno   |
| [kornevoj agent] Zapret novyikh latinskikh obyyavlenij koda                                       | 3,738 s      | uspeshno   |
| [kornevoj agent] Proverka probeljnoj chistotyi diff                                             | 0,057 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka svyaznosti rabochej sessii                                  | 33,917 s     | uspeshno   |
| [kornevoj agent] Finaljnaya kompleksnaya proverka repozitoriya                                   | 49,165 s     | neuspeshno |
| [kornevoj agent] Povtornaya proverka Git-zavisimosti LinguisticKit                             | 0,538 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka svezhesti Markdown posle polnoj popyitki                    | 0,87 s       | uspeshno   |
| [kornevoj agent] Povtornaya proverka grafa Obsidian posle polnoj popyitki                       | 0,466 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka svyaznosti posle polnoj popyitki                            | 33,05 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka reyestra posle polnoj popyitki                              | 0,455 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka probeljnoj chistotyi diff                                   | 0,038 s      | uspeshno   |
| [kornevoj agent] Obyazateljnyij povtor finaljnoj kompleksnoj proverki repozitoriya               | 3160,337 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 4044,058 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Posledovateljnyiye RED/GREEN-fiksturyi zakrepili zakryituyu v3-skhemu, obyazateljnyij profilj, neizmenyayemyij Git-snimok, yedinstvennyij finaljnyij polnyij progon, chestnoye otobrazheniye dublej i vosstanovleniye snimka `.2` posle kazhdoj avarijnoj fazyi.
- Otricateljnyiye scenarii otklonyayut povtor polnogo progona na neizmenyonnom snimke, nevalidnyiye skhemyi i polya, nepolnuyu diagnostiku, ssyilku na otsutstvuyusjhij, uspeshnyij ili posleduyusjhij otkaz, nepokryityij neuspeshnyij ostatok, gonki s aktivnyim full, pozdnij zapusk i izmeneniye snimka posle finala.
- Posle dopolniteljnogo RED-audita polnostjyu proshli 74 testa otchyotnoj obyortki za 23,999 s, 46 testov potrebitelya smoke-istorii za 29,860 s, 32 testa mashinno-lokaljnyikh putej za 2,851 s i 9 testov Markdown-recency za 0,205 s.
- Novyiye sobstvennyiye obyyavleniya sokhranenyi kirillicheskimi; mashinnyij ostatok istoricheskikh latinskikh Python-obyyavlenij umenjshilsya na shestj, s 16 195 do 16 189, i yego snimok obnovlyon toljko shtatnoj avtomatizaciyej.
- Planovaya pamyatj proshla 53 testa reyestra, vosproizvodimuyu validaciyu i 186 testov selektora sleduyusjhego shaga; repozitornyij test teperj proveryayet exact zapisj `master` nezavisimo ot dopusjhennoj pool-vetki tekusjhego worktree.
- Svezhestj, svyaznostj i publikacionnaya chistota proshli na predfinaljnom soderzhateljnom snimke. Pervyij polnyij smoke-check ostanovilsya na lokaljnoj konfiguracii svezhego klona LinguisticKit; obyazateljnyij povtor vyipolnyayetsya posle shtatnogo vosstanovleniya `upstream` i fiksacii novogo snimka, a obe dliteljnosti i iskhoda ostayutsya v zakryitom mashinnom bloke vyishe.

## Resheniya i ogranicheniya

- v1 i v2 ostayutsya strogo chitayemyimi istoricheskimi formatami; novaya zapisj vsegda imeyet skhemu v3. Istoricheskij prefiks v1 mozhet perejti k v3, a prisutstviye v2 ili boleye pozdnej legacy-zapisi posle v3 zakryivayet novyij zapusk do starta dochernego processa. Tochno raspoznannyij smoke-check poluchayet toljko klass `полная`.
- Otpechatok vklyuchayet `HEAD`, otdeljno indeks i rabocheye derevo s binarnyimi tracked-raznicami, a takzhe bajtyi vsekh neignoriruyemyikh untracked-putej. Iz nego isklyuchenyi toljko tekusjhiye `отчёт.md` i `материалы/запуски-проверок/`; gryaznyij inicializirovannyij podmodulj zakryivayet vyichisleniye otkazom. Poetomu vse ostaljnyiye soderzhateljnyiye puti indeksiruyutsya do finaljnogo polnogo progona.
- `проверить-план` rabotayet toljko v otkryitoj sessii bez snimka i zhurnala vosstanovleniya. `закрыть` determinirovanno sokhranyayet takzhe negotovyij fakticheskij plan, a vosstanovleniye `.2` dokatyivayet uzhe nachatyij perekhod; gotovyij profilirovannyij snimok i istoricheskij snimok s v2 ne otkryivayutsya zanovo.
- Sluzhebnyij blok zapuskov otchyota isklyuchyon iz smyislovogo dajdzhesta Markdown-recency s sovmestimyim chteniyem prezhnego polnogo dajdzhesta. Poetomu predprosmotr i zakryitiye mashinnogo bloka ne menyayut svezhestj otchyota, globaljnyij indeks i dokazannyij Git-snimok.
- Odin rannij `git diff --check` byil oshibochno vyizvan napryamuyu vnutri kombinirovannogo osmotra toljko dlya chteniya do finaljnogo snimka. Eto chestno zafiksirovano kak narusheniye obyazateljnoj otchyotnoj obyortki; priyomochnaya proverka budet povtorena ograzhdyonno i zapisana v mashinnom zhurnale.
- Posle perepodklyucheniya Codex prezhnij task-route byil vosstanovlen iz zakreplyonnogo `protocol_oid`; povtornyij dopusk podtverdil tot zhe `слот-0006`, ref, HEAD, generation i activation. Dva oborvannyikh proverochnyikh processa sokhranenyi otdeljnyimi terminaljnyimi zapisyami s kodom `120`, zatem oba GREEN-vyizova povtorenyi bez perepisyivaniya istorii.
- Pervaya polnaya popyitka doshla do avtonomnoj proverki LinguisticKit i vyiyavila, chto obyichnyij `git submodule update` materializoval toljko remote `origin`. Lokaljnyij navyik Git-zavisimostej vosstanovil obyazateljnyij `upstream`, fetch-refspec i pinned checkout komandoj `init`, ne menyaya `.gitmodules` libo gitlink; povtor polnogo progona razreshyon toljko posle etoj chestnoj neuspeshnoj zapisi i novogo Git-otpechatka.
- Kornevyiye nezakommichennyiye bajtyi `.obsidian/` ne chitalisj i ne prisvaivalisj. V izolirovannom `слот-0006` kanonicheskoye pereimenovaniye mekhanicheski obnovilo ssyilku v `.obsidian/graph.json`; pri posleduyusjhej integracii chuzhiye kornevyiye bajtyi dolzhnyi byitj sokhranenyi otdeljno, bez ikh prisvoyeniya etim rezuljtatom.
- Publikaciya rezuljtata, otdeljnoye revjyu, integraciya, povtornoye revjyu i CAS `master` idut posle terminaljnoj kvitancii etogo pisatelya kak otdeljnyiye ograzhdyonnyiye naznacheniya; oni ne podmenyayut kvitanciyu rezuljtata.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [zavershyonnaya FUM-STEP-0147](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0147-isklyuchitj-dublirovaniye-polnoj-regressii-pered-finaljnyim-smoke-check.md)
- [kontrakt otchyotov o zapuskakh proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)
- [kontrakt kompleksnoj proverki](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [kontrakt Markdown-recency](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md)
- [kontrakt proverki Git-zavisimostej](../../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md)
- [kontrakt perevoda obyyavlenij koda](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-15 01:01:18 MSK -->
<!-- content-sha256: sha256:503cd31b3e154927d1820943906634eaad7e233c1a396a8c2f9a5b6d94c30b27 -->
<!-- FUM-MD-RECENCY:END -->
