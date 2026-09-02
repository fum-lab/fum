# Otchyot 2026-08-05 21:02:54 MSK - Ispravitj avtozapusk

Avtozapusk vosstanovlen posle nesovmestimogo izmeneniya host-snimka zadach. Planovyiye tiki prodolzhali prikhoditj kazhdyiye pyatj minut, odnako `codex_app__list_threads` uzhe vozvrasjhal zakryituyu skhemu `4` s otdeljnyim massivom `pinnedThreads`, a heartbeat treboval skhemu `2`, otsutstviye etogo polya i nakhozhdeniye sobstvennoj zakreplyonnoj zadachi v `threads`. Poetomu kazhdyij tik korrektno zakryivalsya do chteniya reyestra, claim i sozdaniya zadachi.

Repozitornyij i zhivoj heartbeat-kontrakt perevedyon na tochnyij tekusjhij profilj: shestj verkhneurovnevyikh polej, dva massiva zadach i yedinyij nablyudayemyij spisok s globaljnoj unikaljnostjyu identifikatorov. Sobstvennaya zadacha mozhet nakhoditjsya v lyubom iz massivov; priznak zakrepleniya po-prezhnemu ostayotsya ustanovochnyim UI-invariantom, a ne runtime-polnomochiyem. Posle pereklyucheniya pervyij planovyij tik proshyol host-proverku i ostanovilsya toljko na ozhidayemo zanyatoj etoj sessiyej FIFO-ocheredi.

## Rezuljtat

Zhivoj `list_threads` podtverdil `schemaVersion === 4`, tochnyiye polya `schemaVersion`, `untrustedDataNotice`, `pinnedThreads`, `threads`, `unavailableHosts` i `unavailableSources`, yedinstvennuyu zakreplyonnuyu zapisj dispetchera i zakryityiye znacheniya `kind` i `status`. Istoriya dispetchera otdelila prichinu ot raspisaniya: do drejfa skhema dopuskala tiki k `queue_busy`, zatem kazhdyij tik vozvrasjhal otkaz profilya, khotya avtomatizaciya ostavalasj `ACTIVE` s `FREQ=MINUTELY;INTERVAL=5`.

Ispravlenyi [kornevoj kontrakt](../../AGENTS.md), [dokumentaciya dispetchera](../../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md), [navyik sleduyusjhego shaga](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [ispolnyayemyij heartbeat-shablon](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md), planovyij sloj i reyestr instrumentov. Testovyiye fiksturyi teperj modeliruyut zakreplyonnyij dispetcher v `pinnedThreads` i druguyu aktivnuyu zadachu v `threads`, a proverki trebuyut obyyedineniya oboikh massivov i otkloneniya povtornogo id vnutri lyubogo massiva ili mezhdu nimi.

Novyiye testyi ispoljzuyut russkiye smyislovyiye obyyavleniya i tem samyim udalili 18 zapisej istoricheskogo latinskogo ostatka. Sravneniye s `HEAD` ne obnaruzhilo ni odnogo dobavlennogo latinskogo obyyavleniya; posle etogo [tochnyij snimok](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json) osmyislenno obnovlyon na umenjshennyij inventarj iz 43 335 zapisej.

Zhivaya avtomatizaciya obnovlena cherez polnyij snimok i povtornuyu tochnuyu proverku. Izmenilisj toljko `prompt` i sluzhebnoye `updated_at`; imya, celevaya zadacha, proyekt, status i raspisaniye sokhranenyi. Novyij prompt imeyet 19 145 bajt i SHA-256 `6facaa32fca98ed60514368ec89a5d9ca8ddcbdf2b6f67a72f98ade6db2ee7d4`.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj                  | Granicyi i sposob izmereniya                                                                                          |
| ------------------------ | ----------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | otsutstvovalo                 | Atomarnyij `join` srazu vernul `admitted`; otdeljnogo intervala ozhidaniya ne byilo                                      |
| Soderzhateljnaya rabota    | otdeljno ne izmeryalasj        | Tri paralleljnyikh audita, analiz host-snimka, TDD, dokumentaciya, migraciya i nablyudeniye pervogo planovogo tika       |
| Celevyiye proverki         | sm. upravlyayemyij blok          | Summa verkhneurovnevyikh adresnyikh vyizovov do smoke-check; vlozhennyiye etapyi ne skladyivayutsya povtorno                    |
| Polnyij smoke-check       | sm. poslednyuyu mashinnuyu stroku | Poslednij zapisyivayemyij vyizov okhvachennoj granicyi                                                                     |
| Atomarnyij commit+handoff | vne chislovoj granicyi          | Vyipolnyayetsya posle zakryitiya snimka i sluzhebnyikh samossyilochnyikh proverok                                                |

Granica profilya: nachalo — metka sessii `2026-08-05 21:02:54 MSK`; konec — rezuljtat poslednego predfinaljnogo polnogo smoke-check. Zakryitiye snimka, proverki yego samossyilochnoj svyaznosti i commit+handoff vyipolnyayutsya posle mashinnoj summyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:8157a0e94d3d7fdaf8bb422bc90df1d642808b7357b78e42abb4c4f58eb8f561 -->

| Vyizov                                                                       | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] TDD-red kontrakta snimka zadach schemaVersion 4             | 0,497 s      | neuspeshno |
| [kornevoj agent] TDD-green kontrakta snimka zadach schemaVersion 4           | 0,507 s      | uspeshno   |
| [kornevoj agent] Polnyij unittest universaljnogo dispetchera                  | 17,01 s      | uspeshno   |
| [kornevoj agent] Polnyij unittest sleduyusjhego shaga vetki                      | 127,754 s    | uspeshno   |
| [kornevoj agent] Obnovleniye Markdown-recency                                | 0,682 s      | uspeshno   |
| [kornevoj agent] Obnovleniye teplovoj kartyi Obsidian                         | 0,348 s      | uspeshno   |
| [kornevoj agent] Predfinaljnoye obnovleniye Markdown-recency                  | 0,614 s      | uspeshno   |
| [kornevoj agent] Predfinaljnoye obnovleniye teplovoj kartyi Obsidian           | 0,347 s      | uspeshno   |
| [kornevoj agent] Predfinaljnyij polnyij smoke-check repozitoriya               | 1597,306 s   | neuspeshno |
| [kornevoj agent] Sravneniye ostatka obyyavlenij v izmenyonnyikh testakh           | 0,078 s      | neuspeshno |
| [kornevoj agent] Povtor sravneniya ostatka obyyavlenij v izmenyonnyikh testakh    | 0,231 s      | uspeshno   |
| [kornevoj agent] Obnovleniye umenjshennogo snimka ostatka obyyavlenij koda     | 4,295 s      | uspeshno   |
| [kornevoj agent] Proverka umenjshennogo snimka ostatka obyyavlenij koda       | 4,301 s      | uspeshno   |
| [kornevoj agent] Povtornoye predfinaljnoye obnovleniye Markdown-recency        | 0,61 s       | uspeshno   |
| [kornevoj agent] Povtornoye predfinaljnoye obnovleniye teplovoj kartyi Obsidian | 0,345 s      | uspeshno   |
| [kornevoj agent] Povtornyij predfinaljnyij polnyij smoke-check repozitoriya     | 1604,226 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3359,151 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-red vosproizvyol odin ozhidayemyij otkaz: prezhnij shablon ne soderzhal obyyedineniya `pinnedThreads` i `threads`. Posle izmeneniya tot zhe nabor iz 22 testov proshyol polnostjyu.
- Polnyij unit-kontur universaljnogo dispetchera proshyol 31 test, a polnyij unit-kontur sleduyusjhego shaga vetki — vesj nabor bez oshibok. Ikh nablyudyonnyiye dliteljnosti sokhranyayutsya v upravlyayemom bloke.
- Zhivoj snimok host podtverdil skhemu `4`: dispetcher nakhodilsya rovno odin raz v `pinnedThreads`, ostaljnyiye zadachi — v `threads`; oba massiva nedostupnosti byili pustyi.
- Tochnaya proverka migracii podtverdila sostoyaniye `updated_and_verified`, toljko polya `prompt` i `updated_at`, otsutstviye povtornogo obnovleniya, status `ACTIVE` i neizmennoye raspisaniye `FREQ=MINUTELY;INTERVAL=5`.
- Pervyij planovyij tik posle ispravleniya nachalsya v `2026-08-05T18:22:45Z` i zavershilsya soobsjheniyem «Ocheredj zanyata; novyij zapusk ne sozdavalsya». Dva neposredstvenno predshestvovavshikh tika zavershalisj otkazom strogogo profilya, poetomu smena rezuljtata dokazyivayet prokhozhdeniye ispravlennogo host-gejta.
- Pervyij polnyij smoke-check proshyol 67 iz 75 shagov i na shage 68 obnaruzhil nesovpadeniye tochnogo snimka obyyavlenij. Adresnoye sravneniye dokazalo otsutstviye novyikh latinskikh obyyavlenij, udaleniye 18 prezhnikh i toljko pozicionnyiye sdvigi ostaljnogo inventarya; obnovlyonnyij snimok prinyat strogoj proverkoj s itogom 43 335 obyyavlenij.
- Poslednyaya stroka upravlyayemogo bloka yavlyayetsya avtoritetnyim rezuljtatom predfinaljnogo polnogo smoke-check. Snimok zakryivayetsya i commit+handoff vyipolnyayetsya toljko pri yeyo statuse `успешно`; posleduyusjhiye zamyikayusjhiye proverki ne dobavlyayutsya v zakryituyu chislovuyu granicu.

## Resheniya i ogranicheniya

- Ispravleniye sokhranyayet fail-closed-podkhod: prinimayetsya toljko fakticheski nablyudyonnaya skhema `4` s tochnyim zakryityim naborom polej. Budusjhij drejf skhemyi snova ostanovit tik i potrebuyet dokazannogo obnovleniya kontrakta, a ne neogranichennogo prinyatiya neizvestnyikh dannyikh.
- `pinnedThreads` i `threads` obyyedinyayutsya do proverki identichnosti, povtorov i drugikh `active`-zadach. Eto ne oslablyayet UI-invariant zakrepleniya: heartbeat prosto ne vyivodit yego iz mestopolozheniya zapisi.
- Snimok ostatka obyyavlenij ne oslablen i ne rasshiren: yedinstvennoye soderzhateljnoye izmeneniye inventarya — udaleniye latinskikh imyon perepisannyikh testov i lokaljnyikh peremennyikh. Pozicionnyiye izmeneniya ostavshegosya ostatka neizbezhno vkhodyat v tochnyij otpechatok i poetomu zafiksirovanyi toljko posle mashinnogo sravneniya s `HEAD`.
- Kontrakt host ne soobsjhayet polnotu `threads` za predelami peredannogo limita 50 nezakreplyonnyikh zadach. Susjhestvuyusjheye neatomarnoye okno mezhdu povtornoj inventarizaciyej i sozdaniyem zadachi takzhe sokhranyayetsya i yavno dokumentiruyetsya.
- Zhivoj canary ne dolzhen byil sozdatj sleduyusjhuyu zadachu: tekusjhaya ispravlyayusjhaya sessiya yavlyayetsya vladeljcem FIFO. Rezuljtat `queue_busy` podtverzhdayet vosstanovleniye marshruta do ocheredi, a fakticheskoye sozdaniye sleduyusjhego shaga budet razresheno toljko posle atomarnoj peredachi etoj sessii i sleduyusjhego svobodnogo tika.
- Tri rannikh diagnosticheskikh zapuska subagentov sostoyalisj do aktivacii mashinnogo zhurnala proverok i poetomu ne predstavlenyi kak yego zapisi. Kornevoj agent povtorno provyol oba unit-kontura cherez obyazateljnuyu obyortku, a obsjhij smoke-check povtoryayet primenimyiye reyestrovyiye, strukturnyiye i publikacionnyiye proverki; iskusstvennyiye stroki dlya rannikh zapuskov ne sozdavalisj.
- Sessiya obnovlyayet toljko lokaljnyij repozitorij i uzhe susjhestvuyusjhuyu zhivuyu avtomatizaciyu. Git-publikaciya ne vyipolnyayetsya: lokaljnyij commit+handoff ne svyazan s `push`.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:cd3eb848f950cd7ec6b22eb2b6bb250316ba7977fe2cdae186f098988c3b2b3e -->
<!-- FUM-MD-RECENCY:END -->
