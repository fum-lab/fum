# Otchyot 2026-08-11 23:30:57 MSK - Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki

Periodicheskij avtozapusk FUM zamenyon prichinnoj cepochkoj imenovannoj Git-vetki. Teperj kornevaya zadacha, kotoraya sobirayetsya sozdatj osmyislennyij kommit, zaraneye sozdayot rovno odnu otdeljnuyu zadachu-prodolzheniye v tom zhe sokhranyonnom lokaljnom proyekte, dozhidayetsya yeyo tochnogo ozhidayusjhego FIFO-bileta i svyazyivayet yeyo identifikator s atomarnyim `commit+handoff`. Prodolzheniye ne poluchayet pravo zapisi iz prompt: ono zhdyot svoyej pozicii, perechityivayet fakticheskij novyij `HEAD`, podtverzhdayet obyichnyij dopusk i napryamuyu zapuskayet vetochnyij selector.

Staryij pyatiminutnyij heartbeat udalyon iz Codex desktop, a prezhnyaya postoyannaya zadacha dispetchera snyata s zakrepleniya i arkhivirovana s sokhraneniyem istorii. Oba zadaniya mashinnogo reyestra perevedenyi v `retired`, poslednyaya neopredelyonnaya runtime-rezervaciya shtatno terminalizirovana bez povtora host-effekta, a dispetcher, periodicheskaya analitika, avtomaticheskaya pochinka, recovery-soobsjheniya, reservation/claim i `Stop`/`Start` ostavlenyi toljko kak istoricheskoye proiskhozhdeniye i sovmestimostj bez runtime-polnomochij. Kanonicheskiye trebovaniya, dokumentaciya, pravila, glossarij i planirovaniye pereklyuchenyi na obyazateljnoye prodolzheniye vetki.

Novyij queue-kontrakt khranit svyazj v neizmenyayemoj Git-kvitancii, mashinno trebuyet rebyonka posle aktivacii protokola i vosstanavlivayet tochnyij rezuljtat dazhe posle posleduyusjhikh peredach FIFO. Uzhe susjhestvuyusjhiye boleye ranniye biletyi ne obkhodyatsya: sozdannyij rebyonok ostayotsya svyazan s kommitom, no dopuskayetsya toljko v svoyej pozicii i prodolzhayet fakticheskuyu vershinu vetki.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                                  |
| ------------------------ | ------------ | ----------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | Dopusk podtverzhdyon, no otdeljnyiye monotonnyiye metki nachala i konca ozhidaniya ne sokhranyalisj.                   |
| Soderzhateljnaya rabota    | ne izmereno  | Proyektirovaniye, host-migraciya, pravki i nezavisimoye revjyu perekryivalisj; yedinyij tajmer ne zapuskalsya.       |
| Celevyiye proverki         | po zhurnalu   | Tochnyiye dliteljnosti vsekh pryamyikh zapuskov izmeryayutsya monotonnyimi chasami v upravlyayemom bloke nizhe.           |
| Polnyij smoke-check       | 2353,081 s   | Finaljnyij polnyij kontur vyipolnil vse `77` stadij i stal poslednej zaregistrirovannoj proverkoj.            |
| Atomarnyij commit+handoff | ne izmereno  | Vyipolnyayetsya posle zakryitiya otchyota i sozdaniya exact prodolzheniya; v snimok proverok ne vkhodit.               |

Granica profilya: nachinayetsya kanonicheskoj metkoj zaprosa. Pryamyiye proverki uchityivayutsya otdeljno, a host-sozdaniye prodolzheniya i finaljnaya Git-peredacha vyipolnyayutsya posle zakryitiya proverochnogo snimka.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:2d73522b8ed6f570ec140ba1ab00428843e4dc5339314eb495b6b0c0f09c8c70 -->

| Vyizov                                                                                             | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Adresnyiye testyi obyazateljnogo prodolzheniya vetki                                   | 4,919 s      | neuspeshno |
| [kornevoj agent] Povtor adresnyikh testov obyazateljnogo prodolzheniya vetki                           | 5,608 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor FIFO-ocheredi posle dobavleniya prodolzheniya                           | 265,962 s    | neuspeshno |
| [kornevoj agent] Peresborka reyestra planirovaniya posle snyatiya avtozapuska                         | 0,139 s      | neuspeshno |
| [kornevoj agent] Povtor peresborki reyestra planirovaniya                                           | 0,378 s      | uspeshno   |
| [kornevoj agent] Strukturnaya proverka pryamogo vetochnogo selector                                  | 0,819 s      | neuspeshno |
| [kornevoj agent] Obnovleniye khyeshej kartochek pryamogo vetochnogo selector                             | 0,953 s      | uspeshno   |
| [kornevoj agent] Povtor strukturnoj proverki pryamogo vetochnogo selector                           | 0,874 s      | uspeshno   |
| [kornevoj agent] Adresnyiye testyi dolgovechnoj kvitancii i strogogo FIFO                             | 20,216 s     | uspeshno   |
| [kornevoj agent] Polnyij nabor FIFO posle dolgovechnoj kvitancii prodolzheniya                        | 297,648 s    | neuspeshno |
| [kornevoj agent] Povtor integracionnogo kontrakta FIFO posle snyatiya heartbeat                     | 0,134 s      | neuspeshno |
| [kornevoj agent] Povtor integracionnogo kontrakta posle aktualizacii publikacionnoj granicyi       | 0,144 s      | neuspeshno |
| [kornevoj agent] Povtor integracionnogo kontrakta posle aktualizacii transportnoj granicyi         | 0,147 s      | uspeshno   |
| [kornevoj agent] Adresnyiye testyi obyazateljnogo prodolzheniya na itogovom snimke                      | 0,13 s       | neuspeshno |
| [kornevoj agent] Adresnyiye testyi obyazateljnogo prodolzheniya na itogovom snimke — tochnyij spisok      | 18,234 s     | uspeshno   |
| [kornevoj agent] Obnovleniye khyeshej kartochek vetochnogo nabora                                       | 0,831 s      | uspeshno   |
| [kornevoj agent] Peresborka planovogo reyestra posle snyatiya dispetchera                             | 0,343 s      | uspeshno   |
| [kornevoj agent] Validaciya peresobrannogo planovogo reyestra                                       | 0,358 s      | uspeshno   |
| [kornevoj agent] Validaciya pryamogo selektora sleduyusjhego shaga                                      | 0,792 s      | uspeshno   |
| [kornevoj agent] Regressiya snyatogo dispetcherskogo kontura                                         | 50,644 s     | neuspeshno |
| [kornevoj agent] Polnyij nabor FIFO posle vnedreniya obyazateljnogo prodolzheniya                      | 244,158 s    | uspeshno   |
| [kornevoj agent] Polnyij nabor pryamogo selektora vetki                                             | 160,386 s    | neuspeshno |
| [kornevoj agent] Adresnyiye testyi finish-clean i pozdnego replay kvitancii                          | 4,586 s      | uspeshno   |
| [kornevoj agent] Polnyij FIFO posle izolyacii finish-clean ot legacy                                | 233,777 s    | uspeshno   |
| [kornevoj agent] Obnovleniye khyeshej kartochek posle unifikacii linejnyikh cepochek                      | 0,792 s      | uspeshno   |
| [kornevoj agent] Finaljnaya peresborka planovogo reyestra posle unifikacii topologii                | 0,376 s      | uspeshno   |
| [kornevoj agent] Povtor regressii istoricheskogo dispetcherskogo kontura                            | 404,976 s    | uspeshno   |
| [kornevoj agent] Povtor polnogo nabora pryamogo selektora posle snyatiya heartbeat-testov            | 152,44 s     | neuspeshno |
| [kornevoj agent] Finaljnaya validaciya planovogo reyestra                                            | 0,371 s      | uspeshno   |
| [kornevoj agent] Finaljnaya validaciya rabochego nabora vetki                                        | 0,864 s      | uspeshno   |
| [kornevoj agent] Adresnyij test neispolnyayemoj heartbeat-spravki                                    | 0,19 s       | uspeshno   |
| [kornevoj agent] Adresnyij test kanonicheskogo nabora vetki posle snyatiya shaga                       | 2,095 s      | neuspeshno |
| [kornevoj agent] Povtor kanonicheskogo nabora vetki posle obnovleniya pokoleniya                     | 2,111 s      | uspeshno   |
| [kornevoj agent] Finaljnyij polnyij nabor pryamogo selektora vetki                                   | 149,125 s    | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown posle migracii prodolzhenij                          | 0,686 s      | uspeshno   |
| [kornevoj agent] Peresborka teplovoj kartyi grafa Obsidian                                         | 0,379 s      | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj rabochej sessii                                           | 26,582 s     | neuspeshno |
| [kornevoj agent] Povtor obnovleniya svezhesti posle zamyikaniya otchyota                                | 0,612 s      | uspeshno   |
| [kornevoj agent] Povtor peresborki grafa posle zamyikaniya svezhesti                                 | 0,383 s      | uspeshno   |
| [kornevoj agent] Povtor predfinaljnoj svyaznosti posle pokryitiya fajlov                             | 26,352 s     | uspeshno   |
| [kornevoj agent] Polnyij smoke-check obyazateljnogo prodolzheniya Git-vetki                           | 7,753 s      | neuspeshno |
| [kornevoj agent] Povtor polnogo smoke-check vne sandbox SwiftPM                                   | 44,121 s     | neuspeshno |
| [kornevoj agent] Diagnostika mashinno-lokaljnogo puti posle smoke                                  | 12,778 s     | neuspeshno |
| [kornevoj agent] Filjtraciya tochnyikh oshibok proverki lokaljnyikh putej                                | 0,091 s      | neuspeshno |
| [kornevoj agent] Povtor filjtracii tochnyikh oshibok lokaljnyikh putej                                  | 0,091 s      | neuspeshno |
| [kornevoj agent] Tochnaya filjtraciya oshibok lokaljnyikh putej                                         | 12,457 s     | neuspeshno |
| [kornevoj agent] Povtor proverki mashinno-lokaljnyikh putej posle uzkogo isklyucheniya                  | 12,574 s     | neuspeshno |
| [kornevoj agent] Tochnaya diagnostika ostavshegosya policy-fence lokaljnyikh putej                      | 12,465 s     | neuspeshno |
| [kornevoj agent] Opredeleniye tochnogo ustarevshego policy-fence lokaljnyikh putej                     | 12,476 s     | neuspeshno |
| [kornevoj agent] Povtor opredeleniya tochnogo ustarevshego policy-fence                              | 12,737 s     | neuspeshno |
| [kornevoj agent] Finaljnaya proverka mashinno-lokaljnyikh putej posle snyatiya stale-fence              | 12,775 s     | uspeshno   |
| [kornevoj agent] Finaljnoye obnovleniye svezhesti Markdown pered smoke-check                         | 0,618 s      | uspeshno   |
| [kornevoj agent] Finaljnaya peresborka teplovoj kartyi grafa pered smoke-check                      | 0,383 s      | uspeshno   |
| [kornevoj agent] Finaljnaya svyaznostj rabochej sessii pered smoke-check                             | 25,999 s     | uspeshno   |
| [kornevoj agent] Finaljnyij povtor polnogo smoke-check obyazateljnogo prodolzheniya                   | 33,532 s     | neuspeshno |
| [kornevoj agent] Povtor obnovleniya svezhesti posle obezlichivaniya otchyota                            | 0,626 s      | uspeshno   |
| [kornevoj agent] Povtor peresborki grafa posle obezlichivaniya otchyota                               | 0,391 s      | uspeshno   |
| [kornevoj agent] Povtor svyaznosti posle obezlichivaniya otchyota                                      | 26,164 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check obyazateljnogo prodolzheniya                            | 36,776 s     | neuspeshno |
| [kornevoj agent] Sravneniye latinskikh obyyavlenij izmenyonnyikh fajlov s HEAD                          | 0,14 s       | neuspeshno |
| [kornevoj agent] Povtor sravneniya latinskikh obyyavlenij s Unicode-putyami                           | 2,321 s      | uspeshno   |
| [kornevoj agent] Proverka snimka latinskogo ostatka posle udaleniya obyyavlenij                     | 4,44 s       | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti posle snimka obyyavlenij                                      | 0,616 s      | uspeshno   |
| [kornevoj agent] Peresborka grafa posle snimka obyyavlenij                                         | 0,378 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle obnovleniya snimka obyyavlenij                                     | 26,183 s     | uspeshno   |
| [kornevoj agent] Polnyij smoke-check posle obnovleniya snimka obyyavlenij                            | 43,305 s     | neuspeshno |
| [kornevoj agent] Proverka dvunapravlennosti voprosa o publikacii                                  | 5,043 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti posle obratnyikh ssyilok voprosa                                | 0,622 s      | uspeshno   |
| [kornevoj agent] Peresborka grafa posle obratnyikh ssyilok voprosa                                   | 0,372 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle zamyikaniya voprosa o publikacii                                   | 26,215 s     | uspeshno   |
| [kornevoj agent] Polnyij smoke-check posle zamyikaniya obratnyikh ssyilok                               | 36,469 s     | neuspeshno |
| [kornevoj agent] Povtor proverki snimka posle sdviga Mermaid-skhemyi                                | 4,597 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti posle povtornogo snimka obyyavlenij                           | 0,615 s      | uspeshno   |
| [kornevoj agent] Peresborka grafa posle povtornogo snimka obyyavlenij                              | 0,382 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle povtornogo snimka obyyavlenij                                     | 26,575 s     | uspeshno   |
| [kornevoj agent] Polnyij smoke-check posle povtornogo Mermaid-snimka                               | 590,962 s    | neuspeshno |
| [kornevoj agent] Istoricheskiye testyi snyatogo instrumenta pochinki s izolirovannoj fiksturoj         | 36,634 s     | neuspeshno |
| [kornevoj agent] Povtor istoricheskikh testov snyatogo instrumenta pochinki s izolirovannoj fiksturoj | 36,99 s      | uspeshno   |
| [kornevoj agent] Obnovleniye snimka obyyavlenij posle izolyacii istoricheskoj fiksturyi                | 4,564 s      | uspeshno   |
| [kornevoj agent] Proverka snimka obyyavlenij posle izolyacii istoricheskoj fiksturyi                  | 4,434 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti posle izolyacii istoricheskoj fiksturyi                         | 0,671 s      | uspeshno   |
| [kornevoj agent] Peresborka grafa posle izolyacii istoricheskoj fiksturyi                            | 0,391 s      | uspeshno   |
| [kornevoj agent] Finaljnyiye istoricheskiye testyi snyatogo instrumenta pochinki                         | 36,94 s      | uspeshno   |
| [kornevoj agent] Finaljnoye obnovleniye svezhesti pered povtorom smoke-check                         | 0,619 s      | uspeshno   |
| [kornevoj agent] Finaljnaya peresborka grafa pered povtorom smoke-check                            | 0,389 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle izolyacii istoricheskoj fiksturyi pochinki                           | 26,338 s     | uspeshno   |
| [kornevoj agent] Finaljnyij polnyij smoke-check posle izolyacii istoricheskoj fiksturyi                | 2353,081 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 5615,607 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Pervyij adresnyij progon vyiyavil oshibochnoye testovoye ozhidaniye publichnogo polya, a povtor posle ispravleniya testa proshyol. Polnyij rannij nabor ocheredi zatem razlichimo ostanovilsya na ustarevshem staticheskom utverzhdenii prezhnego `AGENTS.md`; eto stalo vkhodom dlya usileniya integracionnogo kontrakta.
- Pervaya peresborka reyestra planirovaniya vyiyavila nezamknutuyu semanticheskuyu svyazj novogo trebovaniya so snyatyim FUM-REQ-0028. Posle dobavleniya vzaimnoj svyazi povtor proshyol.
- Pervyij `validate` pryamogo selector vyiyavil ustarevshiye khyeshi kartochek. Ograzhdyonnoye obnovleniye khyeshej i povtornaya strukturnaya proverka uspeshno podtverdili rabochij nabor vetki.
- Devyatj adresnyikh scenariyev podtverdili dolgovechnuyu kvitanciyu, tochnyij i nesovpadayusjhij replay, strogij FIFO pri boleye rannem bilete, otkaz do sozdaniya commit object, SHA-1/SHA-256, Unicode-ref i bezopasnyij prompt. Odin oshibochno sostavlennyij zapusk vyibral nolj testov i zavershilsya kodom `5`; sleduyusjhij vyizov s tochnyimi identifikatorami vyipolnil vse devyatj uspeshno.
- Posledovateljnyiye polnyiye naboryi FIFO snachala vyiyavili tri ustarevshikh staticheskikh ozhidaniya prezhnikh formulirovok, zatem proshli na usilennom kontrakte. Posle adversarial-review dobavlenyi otdeljnyiye scenarii, gde aktivirovannyij `finish-clean` ne kasayetsya legacy-perekhodov, a roditeljskaya kvitanciya perezhivayet svyazannyij kommit rebyonka; itogovyij nabor vyipolnil `170` testov uspeshno.
- Pervyiye polnyiye naboryi selector i dispetchera razlichimo upali, potomu chto prezhniye testyi vsyo yesjhyo trebovali zhivoj heartbeat-shablon i dva aktivnyikh zadaniya kanonicheskogo reyestra. Kanonicheskiye artefaktyi teperj proveryayutsya kak snyatyiye i neispolnyayemyiye, a avtonomnaya sovmestimostj dispetcherskogo koda ispoljzuyet toljko testovyiye legacy-fiksturyi. Itogovyiye naboryi proshli: `186` testov selector (`34` yavno istoricheskikh testa propusjhenyi) i `140` testov dispetchera.
- Posle unifikacii linejnyikh fork-cepochek povtorno obnovlenyi khyeshi FUM-STEP-0120, FUM-STEP-0121 i FUM-STEP-0126, peresobran i provalidirovan planovyij reyestr, a rabochij nabor `refs/heads/master` podtverzhdyon kak `valid` s `17` kandidatami i dvumya gotovyimi shagami.
- Pervyij polnyij smoke-check razlichimo ostanovilsya na zaprete `sandbox-exec` dlya SwiftPM. Povtor vne sandbox proshyol Swift-manifestyi i pervyiye chetyire stadii, posle chego tochnaya proverka mashinno-lokaljnyikh putej vyiyavila otricateljnuyu testovuyu stroku proverki domashnego sokrasjheniya i dve osirotevshiye policy-zapisi prezhnego live-navyika selector. Shtatnyij obnovitelj dobavil odin fingerprint toljko dlya testovoj stroki i atomarno snyal oba boljshe ne susjhestvuyusjhikh URI-fence; itogovyij samostoyateljnyij progon proverki putej proshyol. Sleduyusjhij polnyij zapusk dokazal, chto doslovnoye vosproizvedeniye zapresjhyonnogo sokrasjheniya v samom obyyasnenii otchyota takzhe korrektno blokiruyetsya; obyyasneniye obezlicheno bez rasshireniya policy.
- Ocherednoj polnyij zapusk proshyol proverku putej i ostanovilsya na snimke istoricheskogo ostatka latinskikh obyyavlenij. Mashinnoye sravneniye izmenyonnyikh fajlov s `HEAD` ne nashlo ni odnogo novogo latinskogo obyyavleniya: udalenyi toljko prezhnyaya privyazka `text`, parametr `self` i imya snyatogo heartbeat-testa, a ostaljnyiye razlichiya byili pozicionnyimi sdvigami. Posle yavnogo revjyu shtatnaya avtomatizaciya obnovila snimok; samostoyateljnaya proverka podtverdila tochnoye sovpadeniye `43 192` ostavshikhsya istoricheskikh obyyavlenij.
- Sleduyusjhij polnyij zapusk proshyol pervyiye vosemj stadij i na proverke aktivnyikh voprosov vyiyavil tri otsutstvuyusjhiye obratnyiye svyazi voprosa o publikacii vetki. Dokumentyi ob obyazateljnom prodolzhenii i vosproizvodimyikh avtomatizaciyakh, a takzhe snyatoye trebovaniye dispetchera teperj yavno uderzhivayut publikaciyu drugikh refs v otdeljnoj otkryitoj granice; samostoyateljnaya proverka podtverdila `16` aktivnyikh voprosov i `100` dvunapravlennyikh celej. Vstavka prozyi vyishe susjhestvuyusjhej Mermaid-skhemyi sdvinula pozicii prezhnikh uzlov bez izmeneniya ikh sostava, poetomu tochnyij snimok obyyavleniya povtorno obnovlyon s tem zhe kolichestvom `43 192` i otdeljno provalidirovan.
- Polnyij zapusk posle povtornogo snimka obyyavlenij proshyol `44` stadii i ostanovilsya na avtonomnyikh testakh snyatogo instrumenta pochinki: oni oshibochno chitali uzhe neispolnyayemuyu kanonicheskuyu spravku kak prezhnij renderer-shablon. Minimaljnyij prezhnij format vyinesen v yavno neispolnyayemuyu fiksturu toljko pod `tests/fixtures`, a otdeljnyij test zapresjhayet vozvrasjhatj v kanonicheskuyu spravku tekstovyij blok i runtime-marker. Pervyij adresnyij povtor razlichimo vyiyavil registrozavisimuyu stroku samoj fiksturyi; posle istoricheskoj formulirovki ogranicheniya povtor vyipolnil `14` testov uspeshno.
- Odin vspomogateljnyij read-only `validate` byil po oshibke povtoryon napryamuyu pri diagnostike schyotchikov i ne voshyol v mashinnyij zhurnal. Pozdneye tak zhe napryamuyu byila vyizvana read-only-proverka svezhesti, chtobyi podtverditj ozhidayemoye ustarevaniye otchyota posle `предпросмотр`; ona zavershilasj razlichimyim otkazom i nichego ne izmenila. Oba kanonicheskikh validatora uzhe imeli uspeshnyiye obyornutyiye zapisi i posle soderzhateljnyikh pravok povtoryayutsya cherez obyazateljnuyu obyortku.
- Exact host-udaleniye povtorno podtverdilo sostoyaniye `not_found` dlya prezhnego heartbeat-identifikatora. Eto dokazyivayet otsutstviye imenno snyatoj FUM-avtomatizacii i ne traktuyetsya kak izmeneniye drugikh raspisanij.
- Prezhnyaya postoyannaya zadacha dispetchera uspeshno snyata s zakrepleniya i arkhivirovana. Nezavershyonnaya legacy-rezervaciya shtatno zavershena iskhodom `неопределённый`: poteryannyij host-effekt ne povtoryalsya, a istoricheskij claim ne udalyalsya po dogadke.
- Fakticheskij FIFO-snimok podtverdil otdeljnyij boleye rannij poljzovateljskij bilet. Kontrakt i testyi sokhranyayut yego poziciyu; rebyonok tekusjhego kommita budet zaregistrirovan posle vsekh boleye rannikh biletov, susjhestvuyusjhikh k momentu registracii, i ne poluchit skryitogo prioriteta.
- Posle izolyacii istoricheskoj fiksturyi povtorno proshli recency, graf i svyaznostj rabochej sessii. Finaljnyij polnyij smoke-check zatem vyipolnil vse `77` stadij uspeshno za `2353,081` s i stal poslednej zaregistrirovannoj proverkoj pered zakryitiyem mashinnogo snimka.

## Resheniya i ogranicheniya

- Host-zadacha sozdayotsya do Git-kommita, a ne posle nego. Takoj poryadok sokhranyayet bukvaljnuyu obyazannostj kommityasjhej sessii i isklyuchayet podtverzhdyonnyij kommit bez uzhe susjhestvuyusjhego rebyonka; rebyonok do handoff sposoben toljko zaregistrirovatjsya i zhdatj.
- Neodnoznachnyij `create_thread` zakryivayet kommit i avtomaticheskij povtor. Tekusjhaya host-poverkhnostj ne predostavlyayet caller-defined idempotency key, avtoritetnyij poisk poteryannogo rezuljtata ili tranzakciyu s Git, poetomu bezuslovnaya zhivuchestj posle lyubogo padeniya chestno ne zayavlyayetsya.
- Dolgovechnaya Git-kvitanciya nuzhna otdeljno ot odnoslotovogo `last_completion`: pozdnij tochnyij replay ne zavisit ot sleduyusjhego `finish-clean` ili kommita inoj zadachi. Nesovpavshij libo otsutstvuyusjhij rebyonok zakryivayetsya otkazom.
- Marker novogo trebovaniya v `HEAD` i neobratimyij priznak v sostoyanii ocheredi ne pozvolyayut posleduyusjhej pravke dokumentacii molcha vernutj legacy-kommit bez prodolzheniya. Avtonomnyiye istoricheskiye fiksturyi bez markera sokhranyayut sovmestimostj.
- Tekusjhaya uzhe dopusjhennaya sessiya yavlyayetsya yedinstvennyim bootstrap-isklyucheniyem: yeyo staryij HEAD-bootstrap yesjhyo ne znayet novogo flaga i kvitancii, no sobstvennyij kommit vsyo ravno razreshyon lishj posle exact host-sozdaniya i nablyudayemogo waiting-bileta rebyonka. Vse daljnejshiye kommityi idut cherez novyij mashinnyij kontrakt.
- Strogij FIFO vazhneye neposredstvennogo rodstva sosednikh ispolnitelej. Yesli pered rebyonkom uzhe yestj zakonnaya zadacha, ona prinimayet vetku pervoj; rebyonok pozzhe perechityivayet fakticheskij `HEAD` i prodolzhayet vetku bez ispolneniya ustarevshego prompt kak polnomochiya.
- Lokaljnyij commit+handoff ne vyipolnyayet `push`. Publikaciya ostayotsya otdeljnyim yavno razreshyonnyim transportnyim dejstviyem.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 03:02:14 MSK -->
<!-- content-sha256: sha256:cd683304d5712b255c8a849cc29c67138916754323dda62d028890ce1340400c -->
<!-- FUM-MD-RECENCY:END -->
