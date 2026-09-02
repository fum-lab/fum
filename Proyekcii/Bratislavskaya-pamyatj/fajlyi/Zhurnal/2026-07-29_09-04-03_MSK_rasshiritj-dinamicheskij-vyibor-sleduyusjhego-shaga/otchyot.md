# Otchyot 2026-07-29 09:04:03 MSK - Rasshiritj dinamicheskij vyibor sleduyusjhego shaga

Avtozapusk boljshe ne ogranichen vyiborom vnutri zaraneye podgotovlennogo pula `ready`. On sam vyichislyayet gotovnostj vsego konechnogo whitelist po tochnyim zavershyonnyim kartochechnyim zavisimostyam i toljko posle etogo ranzhiruyet poluchivshijsya pul. Tekusjhij `master` uzhe dayot odin realjno gotovyij bezopasnyij shag vmesto ruchnoj smenyi statusa.

## Rezuljtat

Rabochij nabor vetki perevedyon so skhemyi `4` na skhemu `5`. Dolgovechnaya zapisj kandidata teperj khranit `dispatch = automatic | paused | blocked` i `requires_completed_card_ids`. Dlya `automatic` heartbeat vozvrasjhayet runtime-`ready`, toljko kogda kazhdaya obyazateljnaya kartochka imeyet literal-status `completed`; `active`, `absorbed` i `withdrawn` usloviye ne vyipolnyayut. Svobodnyij tekst, setj, sekretyi, vremya, sreda i modeljnyij vyivod ne interpretiruyutsya kak gotovnostj.

Yavnyiye `paused` i `blocked` ne otkryivayutsya avtomaticheski i sokhranyayut nepustoye usloviye vozobnovleniya. Nevalidnaya zavisimostj zakryivayet vesj nabor: otklonyayutsya otsutstvuyusjhiye kartochki, dublikatyi, self-edge i ciklyi. Nezavershyonnyij `automatic` poluchayet runtime-`paused`, no ne meshayet nezavisimomu kandidatu statj `ready`.

Snimok `selection.id` rasshiren obyyavleniyami i vyichislennyimi statusami vsekh kandidatov, putyami i khyeshami ikh sobstvennyikh kartochek, usloviyami yavnogo vozobnovleniya, nezavershyonnyimi zavisimostyami, tochnyimi statusami, putyami i khyeshami obyazateljnyikh kartochek, polnyim gotovyim pulom, pobeditelem i dokazateljstvom ranzhirovaniya. Izmeneniye nablyudyonnoj zavisimosti ili puti negotovoj kartochki poetomu delayet prezhnij claim ustarevshim bez iskusstvennoj smenyi `step_id`; izmeneniye samoj specifikacii kandidata po-prezhnemu trebuyet novogo pokoleniya.

Finaljnyij kriticheskij audit vyiyavil i zakryil dopolniteljnuyu race-granicu claim. Idempotentnoye vosstanovleniye susjhestvuyusjhej rezervacii teperj vyipolnyayet same-OID Git-tranzakciyu, kotoraya atomarno peresveryayet i vershinu vetki, i sluzhebnuyu ssyilku. Blob s tekusjhim `selection_id`, no chuzhim `step_id` ili `selection_head`, boljshe ne prinimayetsya kak tochnyij povtor. Otdeljnyiye regressii vosproizvodyat prodvizheniye `HEAD`, protivorechivuyu susjhestvuyusjhuyu i konkurentno ustanovlennuyu rezervacii.

Realjnyij `master` soderzhit 26 kandidatov: odin runtime-`ready`, 23 runtime- ili yavno `paused` i dva `blocked`. Yedinstvennyij gotovyij kandidat — `FUM-STEP-0072`, dlya kotoroj zavershena obyazateljnaya `FUM-STEP-0023`; yeyo lokaljnaya fikstura ne trebuyet seti, sekretov, vneshnego dejstviya ili realjnoj LLM. Pozdnyaya cepochka sama budet otkryivatjsya po mere literal-zaversheniya predshestvennikov. FUM-STEP-0102 ostayotsya yavnoj pauzoj do zakonno nastroyennogo provajdera, a FUM-STEP-0095 i FUM-STEP-0105 — yavnyimi blokirovkami.

Postoronnij probel v rabochem sostoyanii LinguisticKit ustranyon otdeljno. Vlozhennyij repozitorij chist, gitlink ne menyalsya i ukazyivayet na zakreplyonnyij `837e2ce107b97ee7b9d3344c9fe99142281fe393`.

## Proiskhozhdeniye vkladov

Chetyire razlichimyikh read-only-audita proverili raznyiye granicyi. Beauvoir klassificiroval aktivnyiye kartochki vne pula i dokazal, chto bezopasno dobavitj toljko FUM-STEP-0072. Wegener postroil tochnuyu kartu rezhimov i zavershyonnyikh zavisimostej tekusjhej cepochki, vklyuchaya nezavisimostj FUM-STEP-0096 ot zablokirovannoj FUM-STEP-0095. Curie proveril normativnyij kaskad i soglasovannostj skhemyi. Finaljnyij algoritmicheskij audit otdeljno proveryayet parser, graf zavisimostej, identity snapshot i claim fencing. Kornevoj ispolnitelj realizoval i svyol izmeneniya, a vyivodyi vyibiralisj po kontraktu i nablyudayemyim kartochechnyim faktam, a ne golosovaniyem.

## Profilj vremeni vyipolneniya

| Stadiya                                    | Dliteljnostj | Granicyi i sposob izmereniya                                                                                     |
| ----------------------------------------- | -----------: | -------------------------------------------------------------------------------------------------------------- |
| Registraciya i dopusk FIFO                 |  ne izmereno | Registraciya byila vyipolnena do soderzhateljnyikh mutacij; otdeljnyij skvoznoj tajmer v vosstanovlennom khode ne vyolsya. |
| Proyektirovaniye i realizaciya               |  ne izmereno | Chteniye, redaktirovaniye i razlichimyiye subagentnyiye audityi chastichno perekryivalisj i ne podmenyayutsya summoj processov. |
| Pryamyiye proverki do polnogo smoke-check    |    255,943 s | Sovokupnyij call-time vsekh perechislennyikh nizhe pryamyikh zapuskov do sostavnoj repozitornoj proverki.               |
| Polnyij repozitornyij smoke-check           |    331,320 s | Odin vneshnij vyizov iz 61 shaga; vlozhennyiye smoke-timings otdeljno ne summiruyutsya.                                |

### Pryamyiye zapuski proverok

| Vyizov                                                        | Dliteljnostj | Rezuljtat                                                                                 |
| ------------------------------------------------------------ | -----------: | ----------------------------------------------------------------------------------------- |
| `[root]` pervyij polnyij nabor testov selektora                 |     30,001 s | ne zaversheno (instrumentaljnyij otvet ne soderzhal konechnogo statusa processa)              |
| `[root]` shestj novyikh testov dinamicheskoj gotovnosti           |      3,727 s | uspeshno                                                                                   |
| `[root]` polnyij nabor do migracii realjnogo `master`          |     38,644 s | neuspeshno (yedinstvennyij sboj podtverdil ozhidayemuyu nesovmestimostj prezhnej skhemyi `4`)       |
| `[root]` pervaya realjnaya proverka `validate` i `show`         |      0,837 s | uspeshno (`ready_count=1`, vyibrana FUM-STEP-0072)                                          |
| `[root]` pervyij skan mashinno-lokaljnyikh putej                  |     10,095 s | neuspeshno (posle pravki teksta ustareli dva tochnyikh razreshyonnyikh otpechatka)                  |
| `[root]` diagnosticheskij vyizov skanera po oshibochnomu imeni    |      0,000 s | neuspeshno (ukazan otsutstvuyusjhij putj scenariya)                                             |
| `[root]` povtornyij skan do obnovleniya otpechatkov              |     10,134 s | neuspeshno (podtverzhdenyi toljko dve izmenivshiyesya stroki politiki)                          |
| `[root]` skan posle uzkogo obnovleniya otpechatkov              |     10,280 s | uspeshno                                                                                   |
| `[root]` itogovyij avtonomnyij nabor selektora                  |     39,570 s | uspeshno (83 testa)                                                                        |
| `[root]` realjnyij `validate` rabochego nabora                  |      0,560 s | uspeshno (26 kandidatov, `ready=1`, `paused=23`, `blocked=2`)                              |
| `[root]` realjnyij `show` rabochego nabora                      |      0,510 s | uspeshno (FUM-STEP-0072, policy `dynamic-readiness-source-history-first-parent-v2`)        |
| `[root]` peresborka planovogo reyestra                         |      0,240 s | uspeshno                                                                                   |
| `[root]` pervaya proverka reyestra s oshibochnyim imenem argumenta |      0,060 s | neuspeshno (CLI trebuyet `--registry`, a ne `--output`)                                      |
| `[root]` ispravlennaya proverka planovogo reyestra              |      0,290 s | uspeshno                                                                                   |
| `[root]` poisk ostatochnyikh skhemyi `4` i policy `v1`             |      0,100 s | uspeshno (v dejstvuyusjhem konture sovpadenij ne najdeno)                                     |
| `[root]` proverka sostoyaniya LinguisticKit                     |      0,090 s | uspeshno (submodule chist, gitlink `837e2ce107b97ee7b9d3344c9fe99142281fe393`)             |
| `[final_code_review]` kriticheskij nabor selektora             |     39,215 s | uspeshno (83 testa do zakryitiya tryokh najdennyikh fence-defektov)                              |
| `[root]` sintaksicheskaya proverka selektora                    |      0,100 s | uspeshno                                                                                   |
| `[root]` chetyire regressii finaljnogo audita                   |      2,790 s | uspeshno                                                                                   |
| `[root]` povtornaya peresborka planovogo reyestra               |      0,230 s | uspeshno                                                                                   |
| `[root]` povtornaya proverka planovogo reyestra                 |      0,240 s | uspeshno                                                                                   |
| `[root]` polnyij nabor selektora posle fence-ispravlenij       |     41,510 s | uspeshno (87 testov)                                                                       |
| `[root]` povtornyij skan mashinno-lokaljnyikh putej               |     10,350 s | uspeshno                                                                                   |
| `[root]` povtornyij realjnyij `validate`                        |      0,500 s | uspeshno (26 kandidatov, `ready=1`, `paused=23`, `blocked=2`)                              |
| `[root]` povtornyij realjnyij `show`                            |      0,510 s | uspeshno (vyibrana FUM-STEP-0072, fence obnovlyon)                                           |
| `[root]` finaljnyij poisk staroj terminologii                  |      0,100 s | uspeshno (pryamyiye protivorechiya schema `5` ustranenyi)                                        |
| `[root]` pervaya materializaciya Markdown-recency               |      0,560 s | uspeshno (obnovlenyi 30 fajlov)                                                             |
| `[root]` pervaya materializaciya grafa Obsidian                 |      0,300 s | uspeshno (teplovaya karta i opornaya data obnovlenyi)                                         |
| `[root]` pervaya proverka svyaznosti sessii                     |     14,350 s | uspeshno                                                                                   |
| `[root]` predvariteljnaya proverka publikacionnogo diff        |      0,050 s | uspeshno (`git diff --check`)                                                              |
| `[root]` proverka publikacionnogo remote i URL                |      0,000 s | uspeshno (`origin`, odin credential-free HTTPS URL `github.com`, URL rewrite otsutstvuyet) |
| `[root]` polnyij repozitornyij smoke-check                      |    331,320 s | uspeshno (61/61; vnutrennij total — 331,261 s)                                              |

Obsjheye vremya pryamyikh zapuskov proverok: 587,263 s.

Granica profilya: ot pervogo pryamogo nabora testov posle dopuska do polnogo repozitornogo smoke-check vklyuchiteljno; kalendarnaya dliteljnostj soderzhateljnoj rabotyi i paralleljnyikh auditov otdeljno ne izmeryalasj. Povtornaya materializaciya recency posle zapisi samogo profilya i kratkaya finaljnaya read-only-sverka ostayutsya za rekursivnoj granicej.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex desktop app i agentskij runtime — versii aktivnoj sessii ne raskryivayutsya sredoj; ispoljzovanyi dlya kornevoj sessii i koordinacii chetyiryokh razlichimyikh read-only-auditov.
- `functions.exec`, `exec_command`, `apply_patch`, `update_plan` i `collaboration.*` — kontraktyi sredyi Codex bez otdeljno raskryityikh versij; ispoljzovanyi dlya lokaljnyikh processov, tochechnyikh pravok, plana i subagentov.
- `fum-ocheredj-zadach-git-vetki`, `fum-sleduyusjhij-shag-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-materialyi-zaprosov`, `fum-reyestr-planirovaniya`, `fum-proverka-mashinno-lokaljnyikh-putej`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej [lokaljnyikh navyikov](../../Instrumentyi/); ispoljzovanyi dlya ocheredi, vyibora shaga, vremeni MSK, proiskhozhdeniya, planovogo kaskada, publikacionnoj chistotyi, svezhesti, svyaznosti i smoke-check.
- `zsh 5.9`, `git 2.54.0`, `Python 3.14.6` i `ripgrep 15.2.0` — ispoljzovanyi dlya lokaljnogo chteniya, poiska, Git-diagnostiki, generatorov i proverok. Vneshnyaya setj dlya soderzhateljnoj rabotyi ne ispoljzovalasj.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [trebovaniye vyibora sleduyusjhego shaga](../../Trebovaniya/✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md)
- [rabochij nabor sleduyusjhego shaga vetki](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [kartochka FUM-STEP-0072](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0072-opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom.md)
- [iskhodnyij zapros o vyibore po istorii kommitov](../2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:094706a4b96f60eb42d3c7bc3f7e4c47dcbff9c0a245d44515336a3700d39a3d -->
<!-- FUM-MD-RECENCY:END -->
