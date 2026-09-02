+++
schema_version = 1
card_id = "FUM-STEP-0123"
status = "completed"
+++
# Dobavitj kornevoye revjyu i CAS-integraciyu cepochki

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj otdeljnyij revjyu-klon, proveryayemyij konvert pull request, mashinochitayemyij pasport proverki vsej dochernej cepochki i marshrutizator prinyatogo diapazona. Dlya paryi [vetvevyikh fork FUM](../../Glossarij/vetvevoj-fork-FUM.md) proveryayusjhaya zadacha dejstvuyet kak ograzhdyonnaya vosstanavlivayemaya sessiya togo zhe roditeljskogo fork v roli moderatora: ona svyazyivayet proverennoye obsjheye iskhodnoye sostoyaniye, obe zamorozhennyiye vershinyi i zaraneye zakreplyonnyiye kriterii i vyibirayet levyij rezuljtat, pravyij rezuljtat, sovmestimoye obyyedineniye, dorabotku, otkloneniye oboikh libo neopredelyonnostj. Kontrakt takzhe razlichayet sobstvennyij rezuljtat rebyonka, rezuljtat dlya proyektnogo repozitoriya i publikacionno chistyij [perenosimyij navyik FUM](../../Glossarij/perenosimyij-navyik-FUM.md) dlya obsjhego core. Resheniye privyazyivayetsya k tochnyim PR-base i PR-head, chastnyim pasportam i kriteriyam, povtoryayet mashinnyiye proverki, sokhranyayet smyislovyiye zamechaniya i dopuskayet CAS toljko po pravilam vyibrannogo marshruta posle yavnogo prinyatiya vsej cepochki libo tochnogo prefiksa.

## Pochemu sejchas

Tekusjhij integrator prinimayet odnopaketnyiye kandidatyi s obsjhim neposredstvennyim roditelem i ne imeyet smyislovogo barjyera revjyu. Proverka i prinyatiye mnogoshagovoj vershinyi nuzhnyi posle poyavleniya kornevogo reyestra i resursno-konfliktnogo raspredeleniya.

## Kriterii zaversheniya

- Pasport revjyu zakreplyayet proveryayusjhego, marshrut rezuljtata, tochnyij diapazon, kriterii, proverki, strukturirovannyiye zamechaniya, korrelyacii i odin iskhod: prinyato, na dorabotku, otkloneno ili neopredelyonno.
- Pasport moderacii zakreplyayet odin identifikator roditelya-moderatora, otdeljnuyu popyitku moderacii, obsjheye pokoleniye i proverennoye iskhodnoye sostoyaniye, roditeljskij rabochij ref, ref sostoyaniya moderacii i sovpadayusjhij s roditeljskim celevoj ref integracii, oba dochernikh fork i ikh neizmenyayemyiye bazyi, vershinyi i refs rezuljtatov; resheniye okhvatyivayet oba rezuljtata, a izmeneniye lyuboj vershinyi, kriteriya ili roditeljskoj celi annuliruyet yego.
- Konvert pull request zakreplyayet postavsjhika, iskhodnyij i celevoj repozitorii, polnyiye refs, identifikator PR, pokoleniye naznacheniya, base/head, diapazon, publikacionnyij audit i sostoyaniye host. Povtor posle poteryannogo otveta vyipolnyayet avtoritetnyij readback i ne sozdayot dublikat; zakryitiye, povtornoye otkryitiye, force-push, dvizheniye base ili head i neizvestnyij iskhod imeyut yavnyiye sostoyaniya i ne pereispoljzuyut staroye prinyatiye.
- Izmeneniye base, head, lyubogo chastnogo pasporta ili kriteriya annuliruyet staroye prinyatiye; dorabotka sozdayot novoye pokoleniye naznacheniya, a ne perepisyivayet resheniye. Yesli prinyat toljko tochnyij prefiks, dlya lyubogo marshruta sozdayutsya novoye pokoleniye kandidatnogo ref i novyij pasport, a dlya obsjhego core-marshruta — novaya vetka i otdeljnyij pull request s PR-head na vershine prefiksa; neprinyatyij ostatok sokhranyayetsya v iskhodnom pokolenii.
- Integrator perechislyayet vesj dostizhimyij diapazon ot bazyi do vershinyi i proveryayet, chto kazhdyij yego kommit imeyet rovno odnogo roditelya — predyidusjhuyu vershinu cepochki; merge-kommit ili inoye otkloneniye ot linejnosti zakryivayet popyitku. Obsjhij vklad rebyonka v core sokhranyayetsya v rodoslovnoj bez squash; sobstvennyij dochernij i proyektnyij marshrutyi soblyudayut otdeljno zakreplyonnyij kontrakt svoyej celi.
- Toljko prinyatoye resheniye razreshayet tochnyij CAS sootvetstvuyusjhego celevogo ref; dvizheniye celi, neizvestnyij konflikt, proigrannyij CAS ili neprinyatyij ostatok sokhranyayut kandidatyi i ne dvigayut ref.
- Vyibor odnogo rebyonka dopuskayet fast-forward libo obyichnuyu integraciyu yego diapazona, a obyyedineniye dvukh sovmestimyikh diapazonov — otdeljnyij mnogoroditeljskij kommit na integracionnoj granice. Toljko otdeljnyij integrator posle dejstviteljnogo resheniya mozhet CAS-perekhodom prodvinutj zamorozhennyij roditeljskij rabochij ref ot ozhidayemoj bazyi. Docherniye cepochki ostayutsya linejnyimi, moderator ne pishet ikh refs, a derevo porozhdeniya ne smeshivayetsya s DAG integracii.
- Prinyatyij sobstvennyij rezuljtat rebyonka dopuskayet otdeljnyij perekhod gitlink assembly k proverennomu dochernemu commit. Yego konflikt ne prokhodit tekusjhij resolver avtomaticheski, a sostoyaniye `принято_в_ребёнке_обновление_gitlink_ожидается` sokhranyayet tochnyiye OID i pozvolyayet idempotentno prodolzhitj perekhod.
- Posle CAS perenosimogo navyika v core susjhestvuyusjhij fork poluchayet sostoyaniye `принято_в_ядре_синхронизация_ребёнка_ожидается`: yego zerkaljnyij `master` sinkhroniziruyetsya s tochnyim pokoleniyem core, osnova perenositsya v novuyu rolevuyu vetku i novyij dochernij commit proveryayetsya. Zatem odin CAS-kommit assembly odnovremenno obnovlyayet core-gitlink i dochernij gitlink libo dokazyivayet, chto core-gitlink uzhe raven prinyatomu OID; PR-head obsjhego core nikogda ne zapisyivayetsya v gitlink rebyonka neposredstvenno.

## Rezuljtat

Dobavlen otdeljnyij fasad kornevogo prinyatiya gotovogo diapazona cepochki. Tri zakryityiye JSON-skhemyi versii `1`, strogij dekoder kanonicheskoj obyortki i Codable-tipyi zakreplyayut pasporta revjyu i moderacii i konvert zaprosa sliyaniya; neizvestnyiye, povtornyiye i nesovpavshiye dubli polej otklonyayutsya do sozdaniya domennogo znacheniya. Validator svyazyivayet nezavisimyiye roli, marshrut, tochnyiye base/head, kanonicheskiye puti repozitoriyev i polnyiye refs, vesj linejnyij diapazon, chastnyiye pasporta, kriterii, pervichnyiye i povtornyiye proverki, zamechaniya i korrelyacii. Lyuboj sdvig zakreplyonnoj granicyi annuliruyet resheniye; dorabotka i tochnyij prefiks trebuyut novogo pokoleniya i novyikh artefaktov, sokhranyaya neprinyatyij ostatok.

Uspeshnaya proverka vyidayot nedekodiruyemoye izvne razresheniye, khyesh-svyazannoye s kanonicheskimi putyami i refs oboikh repozitoriyev, tochnyimi diapazonami vyibrannyikh detej, celjyu i ozhidayemyimi vershinami mezhrepozitornoj sagi. Chistyij publichnyij reduktor prinimayet toljko ograzhdyonnyiye tem zhe resheniyem sobyitiya, tipiziruyet proigrannoye sravneniye, neizvestnyij konflikt, vyibor odnogo rebyonka, granicu sovmestimogo obyyedineniya i vozobnovlyayemyiye pending-sostoyaniya sobstvennogo, proyektnogo i core-marshrutov. Otdeljnyij effektnyij ispolnitelj v local-bare topologii povtorno proveryayet pryamyiye refs, format obyyektov, source head i vesj odnoroditeljskij diapazon, perenosit obyyektyi pod sluzhebnyij ref i vyipolnyayet exact old→new `update-ref`. Konkurentnyij sdvig ne perezapisyivayetsya; avtoritetnoye chteniye posle post-CAS-perekhvata i tochnyij povtor vosstanavlivayut uzhe vyipolnennyij perekhod.

Dvenadcatj chistyikh, pyatj effektnyikh local-bare i chetyire skhemnyikh scenariya pokryivayut polnoye i prefiksnoye prinyatiye, annulirovaniye resheniya, vse sostoyaniya konverta, tri marshruta, dvukh detej, oba pending-perekhoda mezhrepozitornoj sagi, zakryitostj runtime-dekodirovaniya, uspeshnyij i proigrannyij CAS, tochnyij povtor, poteryu otveta i zapret replay razresheniya v drugom repozitorii ili ref.

## Granica rezuljtata

Rezuljtat ne sozdayot realjnyiye Codex Desktop-zadachi, vneshniye fork/assembly, setevoj pull request i ne vyizyivayet modelj dlya zhivogo smyislovogo revjyu. Provider/host i repozitorii predstavlenyi chistyimi znacheniyami i vremennyimi bare-fiksturami. Fakticheskaya sborka mnogoroditeljskogo commit, izmeneniye submodule/gitlink i core-child-sinkhronizaciya ostayutsya chistyimi vozobnovlyayemyimi perekhodami do skvoznoj avtonomnoj priyomki FUM-STEP-0124; chteniye posle uspeshnogo CAS obnaruzhivayet posleduyusjhij sdvig, no ne otkatyivayet uzhe vyipolnennyij CAS. Zhivaya publikaciya ostayotsya FUM-STEP-0125–FUM-STEP-0126.

## Istochniki

- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0127 — resursno-konfliktnoye raspredeleniye cepochek](✅-FUM-STEP-0127-dobavitj-resursno-konfliktnoye-raspredeleniye-cepochek.md)
- [FUM-STEP-0086 — CAS-integraciya](✅-FUM-STEP-0086-dobavitj-CAS-integraciyu-beskonfliktnyikh-kommitov.md)
- [FUM-STEP-0087 — ogranichennyij resolver](✅-FUM-STEP-0087-dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-13 15:44:23 MSK -->
<!-- content-sha256: sha256:259364089d615bda2ac266969f7969ffb02ab0a0794f8b0e43dd304c0ccce69a -->
<!-- FUM-MD-RECENCY:END -->
