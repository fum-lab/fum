# Otchyot 2026-08-14 18:45:51 MSK - Ignorirovatj izmeneniya Obsidian pri starte zadachi

> Eto istoricheskij otchyot vetki-kandidata. Yego blanket-politika dlya vsej `.obsidian/`, staryij FIFO/worktree-kontur i lokaljnyiye oboznacheniya dvukh sboyev ne stali dejstvuyusjhimi pri posleduyusjhem semanticheskom sliyanii s `manual-sequential-v1`; iskhodnyiye bajtyi i kartochki ostayutsya dostizhimyi cherez vtorogo roditelya `1de99504e46497f4d384ee6c5fc110063bcbfb6c`.

Vesj tochnyij kornevoj `.obsidian/` perevedyon v lokaljnoye sostoyaniye checkout: korne-yakornoye pravilo dejstvuyet na vsyo derevo, prezhniye shestj fajlov snyatyi s Git-uchyota bez udaleniya lokaljnyikh kopij, a Git-inventarj etogo kornya stal pustyim. Teplovaya karta prodolzhayet obnovlyatjsya lokaljnoj avtomatizaciyej i ostayotsya strogoj pri nalichii lokaljnoj paryi; svezhij checkout bez `.obsidian/` prokhodit read-only-proverku bez materializacii.

Odnovremenno ustranyon vosproizvedyonnyij startovyij otkaz `dirty_primary_bootstrap`: tri startovyikh perekhoda ocheredi ignoriruyut staged-, unstaged- i untracked-sostoyaniye toljko vnutri tochnogo kornevogo `.obsidian/`. Lyuboj vneshnij putj, registrovyij dvojnik, vlozhennyij `x/.obsidian`, gryaznyij podmodulj ili izmeneniye vyidelennogo slota sokhranyayet zakryityij otkaz.

## Profilj vremeni vyipolneniya

| Stadiya                | Dliteljnostj        | Granicyi i sposob izmereniya                                                                      |
| --------------------- | ------------------- | ----------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO | ne izmereno         | Ot pervogo zakryitogo otkaza do dopuska v otdeljnyij slot; yedinyij tajmer ne zapuskalsya            |
| Soderzhateljnaya rabota | ne izmereno         | Analiz, TDD, migraciya Git-inventarya, dokumentaciya i kartochki sboyev; yedinyij tajmer ne zapuskalsya |
| Celevyiye proverki      | sm. mashinnyij zhurnal | Tochnyiye dliteljnosti kazhdogo pryamogo zapuska sokhranenyi v upravlyayemom bloke nizhe                  |
| Polnyij smoke-check    | sm. mashinnyij zhurnal | Predfinaljnyij polnyij kontur sokhranyayetsya otdeljnoj mashinnoj zapisjyu                              |
| Terminaljnaya fiksaciya | ne izmereno         | Zavershayetsya ograzhdyonnoj kvitanciyej rezuljtata worktree-linii                                    |

Granica profilya: ot pervoj startovoj marshrutizacii tekusjhej zadachi do terminaljnoj kvitancii rezuljtata; ozhidaniye slota vklyucheno, no otdeljno ne izmeryalosj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:f9ea8cf1ac31638effd85b8655214abbfad95778627fa53aef9d1ed84c9affd8 -->

| Vyizov                                                                                      | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------ | ------------ | --------- |
| [kornevoj agent] TDD-red: startovoye isklyucheniye kornevoj .obsidian                          | 13,167 s     | neuspeshno |
| [kornevoj agent] TDD-green: startovoye isklyucheniye kornevoj .obsidian                        | 18,225 s     | uspeshno   |
| [kornevoj agent] TDD-red: lokaljnaya teplovaya karta vne Git                                 | 0,132 s      | neuspeshno |
| [kornevoj agent] TDD-green: lokaljnaya teplovaya karta vne Git                               | 0,168 s      | neuspeshno |
| [kornevoj agent] TDD-green: lokaljnaya teplovaya karta vne Git, povtor                       | 0,17 s       | uspeshno   |
| [kornevoj agent] TDD-red: lokaljnyij .obsidian vne proyektnogo inventarya                     | 0,429 s      | neuspeshno |
| [kornevoj agent] TDD-green: lokaljnyij .obsidian vne proyektnogo inventarya                   | 0,403 s      | uspeshno   |
| [kornevoj agent] TDD-red: yavnyij propusk otsutstvuyusjhej lokaljnoj teplovoj kartyi             | 0,181 s      | neuspeshno |
| [kornevoj agent] TDD-green: yavnyij propusk otsutstvuyusjhej lokaljnoj teplovoj kartyi           | 0,188 s      | uspeshno   |
| [kornevoj agent] TDD-green: lokaljnyij .obsidian ne udovletvoryayet proyektnuyu ssyilku          | 0,182 s      | uspeshno   |
| [kornevoj agent] TDD-red: Git-politika lokaljnogo .obsidian                                | 0,239 s      | neuspeshno |
| [kornevoj agent] TDD-green: Git-politika lokaljnogo .obsidian                              | 0,237 s      | uspeshno   |
| [kornevoj agent] TDD-red: marker snyatiya kornevoj .obsidian s Git-uchyota                     | 0,538 s      | neuspeshno |
| [kornevoj agent] TDD-green: marker snyatiya kornevoj .obsidian s Git-uchyota                   | 0,556 s      | uspeshno   |
| [kornevoj agent] Regressiya: strogaya chastichnaya i povrezhdyonnaya lokaljnaya para grafa          | 0,079 s      | neuspeshno |
| [kornevoj agent] Polnyij nabor svezhesti lokaljnogo grafa Obsidian                           | 1,008 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor pula worktree-poduzlov                                       | 264,474 s    | uspeshno   |
| [kornevoj agent] RED: effektivnoye ignorirovaniye kornevogo Obsidian                         | 0,528 s      | neuspeshno |
| [kornevoj agent] RED: konfiguraciya podmodulya ne skryivayet gryazj                             | 0,952 s      | neuspeshno |
| [kornevoj agent] RED: tochnyij registr kornya Obsidian                                        | 0,132 s      | neuspeshno |
| [kornevoj agent] GREEN: effektivnoye ignorirovaniye kornevogo Obsidian                       | 0,505 s      | uspeshno   |
| [kornevoj agent] GREEN: konfiguraciya podmodulya ne skryivayet gryazj                           | 1,13 s       | uspeshno   |
| [kornevoj agent] GREEN: tochnyij registr kornya Obsidian                                      | 0,18 s       | uspeshno   |
| [kornevoj agent] RED: tochnoye snyatiye Obsidian s Git-uchyota                                   | 5,936 s      | neuspeshno |
| [kornevoj agent] RED: obe storonyi Git-pereimenovaniya                                       | 0,728 s      | neuspeshno |
| [kornevoj agent] GREEN: tochnoye snyatiye Obsidian s Git-uchyota                                 | 1,561 s      | uspeshno   |
| [kornevoj agent] GREEN: obe storonyi Git-pereimenovaniya                                     | 0,133 s      | uspeshno   |
| [kornevoj agent] Povtornyij polnyij nabor pula worktree-poduzlov                             | 255,239 s    | uspeshno   |
| [kornevoj agent] Polnyij nabor svezhesti lokaljnogo grafa Obsidian posle ukrepleniya          | 1,281 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor proyektnogo fajlovogo inventarya                               | 0,4 s        | uspeshno   |
| [kornevoj agent] Polnyij nabor svyaznosti rabochej sessii posle ukrepleniya                    | 3,519 s      | uspeshno   |
| [kornevoj agent] Validaciya planovogo reyestra                                               | 0,492 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti Markdown posle migracii ssyilok                          | 0,902 s      | uspeshno   |
| [kornevoj agent] Proverka lokaljnoj teplovoj kartyi i Git-politiki Obsidian                 | 0,748 s      | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj tekusjhej rabochej sessii                            | 35,39 s      | neuspeshno |
| [kornevoj agent] Predfinaljnaya svyaznostj tekusjhej rabochej sessii, povtor                    | 32,324 s     | neuspeshno |
| [kornevoj agent] Materializaciya zakreplyonnoj zavisimosti LinguisticKit                     | 6,488 s      | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj posle materializacii zavisimosti                  | 32,084 s     | uspeshno   |
| [kornevoj agent] Proverka publikacionnoj chistotyi diff                                      | 0,134 s      | uspeshno   |
| [kornevoj agent] Predfinaljnyij polnyij smoke-check repozitoriya                              | 46,509 s     | neuspeshno |
| [kornevoj agent] Diagnostika literal-yakorej pravila Obsidian                               | 14,618 s     | neuspeshno |
| [kornevoj agent] Regressiya grafa posle bezopasnogo predstavleniya ignore-yakorya              | 1,155 s      | uspeshno   |
| [kornevoj agent] Regressiya svyaznosti posle bezopasnogo predstavleniya ignore-yakorya          | 4,979 s      | neuspeshno |
| [kornevoj agent] Regressiya svyaznosti posle predstavleniya ignore-yakorya, povtor              | 4,881 s      | uspeshno   |
| [kornevoj agent] Regressiya obsjhego proyektnogo fajlovogo kontrakta                           | 0,493 s      | uspeshno   |
| [kornevoj agent] Proverka mashinno-lokaljnyikh putej posle predstavleniya ignore-yakorya         | 15,345 s     | uspeshno   |
| [kornevoj agent] Povtornaya proverka publikacionnoj chistotyi diff                            | 0,121 s      | uspeshno   |
| [kornevoj agent] Predfinaljnyij polnyij smoke-check repozitoriya, povtor                      | 44,142 s     | neuspeshno |
| [kornevoj agent] Sukhoj plan perevoda novogo parametra proyektnogo inventarya                 | 0,077 s      | uspeshno   |
| [kornevoj agent] Diagnostika izmeneniya inventarya obyyavlenij koda                           | 78,212 s     | uspeshno   |
| [kornevoj agent] Diagnostika izmeneniya inventarya obyyavlenij koda, povtor                   | 75,579 s     | uspeshno   |
| [kornevoj agent] Kompaktnyij audit izmeneniya ostatka latinskikh obyyavlenij                   | 0,077 s      | neuspeshno |
| [kornevoj agent] Kompaktnyij audit izmeneniya ostatka latinskikh obyyavlenij, ispravlennyij     | 58,175 s     | neuspeshno |
| [kornevoj agent] Kompaktnyij audit ostatka otnositeljno chistogo HEAD                        | 9,657 s      | uspeshno   |
| [kornevoj agent] Podtverzhdeniye nulevogo prirosta latinskikh obyyavlenij                      | 3,829 s      | uspeshno   |
| [kornevoj agent] Proverka snimka obyyavlenij koda posle nulevogo prirosta                   | 3,79 s       | uspeshno   |
| [kornevoj agent] Itogovaya regressiya proyektnogo fajlovogo kontrakta                         | 0,402 s      | uspeshno   |
| [kornevoj agent] Itogovaya regressiya lokaljnoj teplovoj kartyi Obsidian                      | 1,209 s      | uspeshno   |
| [kornevoj agent] Itogovaya regressiya svyaznosti rabochej sessii                               | 3,356 s      | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check repozitoriya                                   | 268,41 s     | neuspeshno |
| [kornevoj agent] GREEN: repozitornyij sleduyusjhij shag iz terminaljnoj vetki pula              | 1,937 s      | uspeshno   |
| [kornevoj agent] Regressii sleduyusjhego shaga dlya terminaljnoj vetki pula                     | 1,945 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor sleduyusjhego shaga vetki posle ispravleniya pool-self-test       | 190,663 s    | uspeshno   |
| [kornevoj agent] Povtornoye podtverzhdeniye nulevogo prirosta obyyavlenij posle pool-self-test | 3,815 s      | uspeshno   |
| [kornevoj agent] Proverka snimka obyyavlenij posle pool-self-test                           | 3,823 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle ustraneniya pool-self-test                                 | 38,513 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle ustraneniya pool-self-test               | 1100,219 s   | neuspeshno |
| [kornevoj agent] Regressii vosstanovlennogo helper markera snyatiya Obsidian s Git-uchyota     | 0,811 s      | uspeshno   |
| [kornevoj agent] Polnaya regressiya svyaznosti posle vosstanovleniya helper                    | 4,115 s      | uspeshno   |
| [kornevoj agent] Inventarizaciya obyyavlenij posle vosstanovleniya helper                     | 9,226 s      | uspeshno   |
| [kornevoj agent] Proverka snimka obyyavlenij posle vosstanovleniya helper                    | 6,179 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle oformleniya FUM-SBOJ-0019                                  | 35,962 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle vosstanovleniya helper                   | 3523,004 s   | neuspeshno |
| [kornevoj agent] Polnyij smoke-check posle vosstanovleniya prervannoj sessii                 | 3102,254 s   | uspeshno   |
| [kornevoj agent] Itogovaya svyaznostj posle uspeshnogo polnogo smoke-check                    | 37,575 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 9376,219 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-matricyi otdeljno vosproizveli prezhnij startovyij otkaz dlya tryokh komand, opasnoye povtornoye vklyucheniye `.obsidian/`, nepolnoye snyatiye s Git-uchyota, poteryu iskhodnoj storonyi rename, skryitiye gryaznogo podmodulya i registrovyij dvojnik `.Obsidian/`.
- Profiljnyiye zelyonyiye progonyi podtverzhdayut tochnuyu startovuyu granicu, stroguyu chistotu slot-worktree, effektivnoye ignorirovaniye, pustoj itogovyij Git-inventarj, sokhrannostj lokaljnyikh kopij i semantiku teplovoj kartyi v svezhem checkout.
- Pervyij polnyij smoke-check ostanovilsya na mashinnoj klassifikacii bukvaljnogo Git-ignore-yakorya v proizvodnyikh dokumentakh. Tochnyij runtime-kontrakt vyinesen v obsjhuyu kirillicheskuyu konstantu, a dokumentaciya opisyivayet korne-yakornuyu semantiku bez lozhnogo absolyutnogo puti; profiljnaya proverka mashinno-lokaljnyikh putej posle ispravleniya prokhodit bez novogo policy-isklyucheniya.
- Povtornyij polnyij smoke-check doshyol do kontrolya obyyavlenij i ostanovilsya na nesovpavshem koordinatnom snimke. Inventarizaciya otdelila 17 novyikh latinskikh obyyavlenij ot 1 382 sdvinutyikh prezhnikh zapisej: vse novyiye imena perevedenyi na kirillicu ili svedenyi k prezhnej yedinstvennoj privyazke, posle chego chislo obyyavlenij i raspredeleniye po yazyikam tochno sovpali s iskhodnyim snimkom (`43 213`; Mermaid — `460`, Python — `16 195`, Swift — `26 558`). Lokaljnyij navyik perevoda obyyavlenij obnovil toljko otpechatok koordinatnogo ostatka, a yego samostoyateljnaya proverka proshla.
- Sleduyusjhij polnyij smoke-check proshyol rannij prefiks i vyiyavil master-zavisimoye predpolozheniye repozitornogo testa sleduyusjhego shaga: test vyizyival selector dlya aktivnogo runtime work-ref pula, no ozhidal soderzhimoye `master`. Ispravlennyij self-test trebuyet otsutstviye zapisi u vetki pula, otdeljno proveryayet kanonicheskij `master`, a izolirovannaya otricateljnaya fikstura sokhranyayet zakryityij otkaz nastoyasjhikh `validate` i `show`. Polnyij profiljnyij nabor posle ispravleniya zavershil `187` testov bez oshibok.
- Polnyij smoke-check posle etogo ispravleniya doshyol do shaga `32` i vyiyavil regressiyu obsjhej rabochej kopii: posle smenyi porucheniya subagent udalil kak yakobyi osirotevshij metod `ошибки_маркера_снятия_обсидиана_с_учёта`, khotya tri susjhestvuyusjhikh testa prodolzhali yego vyizyivatj. Metod vosstanovlen; tochechnyiye regressii zavershilisj `3/3`, polnyij profilj svyaznosti — `81/81`.
- [Pervyij polnyij povtor posle vosstanovleniya metoda](materialyi/zapuski-proverok/73_2ad122c0-9011-43d7-afe2-ad16de51022f.json) byil prervan zakryitiyem processa s kodom `120` i ne schitayetsya uspeshnoj priyomkoj. [Povtor posle vosstanovleniya sessii](materialyi/zapuski-proverok/74_a716d133-d8ca-4922-83d3-d80b9d6aeaa8.json) zavershilsya kodom `0`: proshli vse `77` shagov polnogo smoke-check za `3102,254` s.
- Polnyiye naboryi zatronutyikh avtomatizacij, svyaznostj tekusjhej sessii i obsjhij smoke-check zavershilisj uspeshno; ikh tochnyiye rezuljtatyi i dliteljnosti sokhranenyi v mashinnom bloke zapuskov.

## Resheniya i ogranicheniya

- V Git dejstvuyet rovno odno korne-yakornoye pravilo dlya `.obsidian/`; avtomatizacii dopolniteljno dokazyivayut yego effektivnoye dejstviye, otsutstviye povtornogo vklyucheniya i pustoj Git-inventarj. Pokhozhij `.Obsidian/` ne isklyuchayetsya.
- Snyatiye s uchyota razresheno toljko kak tochnoye sovpadeniye nepustogo HEAD-inventarya s staged `D` pri sokhranyonnoj obyichnoj lokaljnoj kopii kazhdogo prezhnego fajla. Istoriya ne perepisyivalasj.
- Generator teplovoj kartyi ostayotsya chastjyu rabochego kontura. Obyichnyij zapusk sozdayot ili obnovlyayet lokaljnyiye `graph.json` i sidecar; read-only-rezhim propuskayet toljko polnostjyu otsutstvuyusjhuyu paru, a chastichnoye, povrezhdyonnoye ili ustarevsheye sostoyaniye otklonyayet.
- Ignoriruyemyij `.obsidian/` ne yavlyayetsya proyektnyim vkhodom i ne mozhet udovletvoryatj aktivnyiye Markdown-ssyilki. Istoricheskiye aktivnyiye ssyilki Zhurnala na eti lokaljnyiye fajlyi zamenenyi na tekstovyiye inline-code puti, chtobyi fresh checkout ostavalsya svyaznyim.
- Startovoye isklyucheniye otnositsya toljko k kornevomu `.obsidian/` na perekhodakh `маршрутизировать`, `зарезервировать-себя` i `присоединиться-к-линии`. Proverki chistotyi vyidelennyikh worktree, terminaljnyiye perekhodyi, `перейти-на-цепочку` i chelovecheskij `break-glass` ne oslablenyi; Git-konfiguraciya ne mozhet skryitj gryaznyij podmodulj.
- Runtime work-ref `refs/heads/codex/подузлы/**` ne poluchayet perenosimuyu zapisj sleduyusjhego shaga. Ordinary branch FIFO sokhranyayet selector i terminal `committed`, a terminaljnyij pisatelj pula zavershayet smoke-sessiyu kvitanciyej `result_frozen` s posleduyusjhim osvobozhdeniyem chistogo slota.
- Posle smenyi porucheniya subagent obsjhej rabochej kopii proveryayet aktualjnyiye ssyilki po vsemu tekusjhemu derevu do udaleniya yakobyi neispoljzuyemogo obyyavleniya ili pravki i ne otkatyivayet chuzhiye libo sovmestnyiye izmeneniya bez yavnoj koordinacii s kornem.
- FUM-SBOJ-0007 zakryivayetsya novoj lokaljnoj politikoj, a utrativshaya primenimostj FUM-STEP-0135 snyata bez lozhnogo zayavleniya o realizacii. Otdeljnaya FUM-SBOJ-0017 sokhranyayet proyavleniye startovoj blokirovki i dokazateljstvo sistemnogo ustraneniya.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [FUM-SBOJ-0007 — propusk opornoj datyi grafa posle polunochi](../../Sboi/FUM-SBOJ-0007-propusk-opornoj-datyi-grafa-posle-perekhoda-cherez-polnochj-MSK.md)
- [FUM-SBOJ-0017 — blokirovka starta izmeneniyami v kornevoj `.obsidian/`](../../Sboi/FUM-SBOJ-0017-blokirovka-starta-zadachi-izmeneniyami-v-kornevoj-obsidian.md)
- Istoricheskiye opisaniya trebovaniya sleduyusjhego shaga dlya terminaljnoj vetki pula i udaleniya ispoljzuyemogo vspomogateljnogo metoda sokhranenyi toljko v dostizhimoj istorii kandidata: ikh lokaljnyiye identifikatoryi stolknulisj s kanonicheskimi kartochkami `master`.
- [vosproizvodimyiye avtomatizacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 12:06:18 MSK -->
<!-- content-sha256: sha256:fe06a53b2d706ad97156b6b9b8c63561b4975ab0f726ad58aab88fd671a092e6 -->
<!-- FUM-MD-RECENCY:END -->
