+++
schema_version = 1
card_id = "FUM-STEP-0086"
status = "completed"
+++
# Dobavitj CAS-integraciyu beskonfliktnyikh kommitov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj k prototipu serializovannyij integrator beskonfliktnyikh kandidatnyikh commit. Integrator dolzhen proveritj pasporta i dostizhimostj kandidatov, postroitj itog otnositeljno tochnoj tekusjhej vershinyi, sokhranitj iskhodnyiye commit poduzlov v Git-rodoslovnoj, vyipolnitj obyazateljnyiye proverki i atomarno obnovitj celevoj ref toljko compare-and-swap. Lyuboj tekstovyij konflikt, dvizheniye celevoj vershinyi ili neuspeshnaya proverka dolzhnyi zavershatj popyitku bez publikacii.

## Rezuljtat

V proveryayemyij mnogoagentnyij SwiftPM-prototip dobavlen `CandidateCommitIntegrator` dlya uzkoj lokaljnoj integracii v yavno peredannyij bare-repozitorij. On prinimayet kanonicheski uporyadochennyij neizmenyayemyij nabor OID i khyeshej pasportov, nezavisimo vosstanavlivayet kazhdyij rezuljtat pishusjhego poduzla, sveryayet obsjhij roditeljskij commit i podderzhivayet svezhuyu celevuyu vershinu toljko kak dokazannogo potomka etoj obsjhej bazyi.

Lokaljnyij vladelec serializuyetsya blokirovkoj, privyazannoj k fizicheskomu celevomu repozitoriyu i polnomu ref. Obyichnoye Git-sliyaniye ne ispoljzuyet resolver, zapresjhayet sistemnyiye i repozitornyiye merge-atributyi, otseivayet kollizii putej posle normalizacii, sekretyi, mashinnyij musor i vyikhod itogovogo dereva za obyyedinyonnuyu oblastj kandidatov. Nepustoj nabor obyazateljnyikh proverok razreshayetsya toljko zakryityim doverennyim reyestrom i povtorno ispolnyayetsya pri vosstanovlenii podgotovlennoj popyitki.

Itogovyij commit imeyet pryamyikh roditelej v poryadke `ожидаемая вершина, канонически отсортированные кандидаты`; iskhodnyiye commit ne perepisyivayutsya i ostayutsya dostizhimyimi. Podgotovlennyij commit uderzhivayetsya otdeljnyim pryamyim ref integracionnogo klona, a kanonicheskij pasport sokhranyayetsya do peredachi obyyektov. Yedinstvennaya publikacionnaya operaciya ispoljzuyet tranzakciyu `git update-ref --stdin` s `option no-deref` i tochnyim staryim OID. Proigrannyij CAS, izmenivshayasya celj, tekstovyij konflikt, povrezhdeniye i proval proverki ne obnovlyayut celevoj ref; tochnyij uspeshnyij povtor i poteryannyij otvet posle CAS vosstanavlivayutsya idempotentno.

Trinadcatj avtonomnyikh scenariyev na nastoyasjhikh vremennyikh Git-repozitoriyakh pokryivayut odin i neskoljko sovmestimyikh commit, svezhuyu bazu posle dvizheniya celi, realjnyij proigryish CAS, sboi do i posle CAS, sborku musora, tochnyij i izmenyonnyij povtor, povrezhdeniye, tekstovyij konflikt, smyislovoj otkaz validatora, nebezopasnuyu konfiguraciyu, symbolic ref, peresecheniye runtime-katalogov, normalizovannyiye kollizii putej i yedinstvennogo vladeljca pri raznyikh integracionnyikh kornyakh. Integrator ne razreshayet konfliktuyusjhiye derevjya, ne zapuskayet paralleljnyikh ispolnitelej, ne vyipolnyayet push i ne menyayet FIFO-ocheredj obsjhego checkout.

## Istochniki

- [iskhodnyij zapros 2026-08-03 21:37:49 MSK — Dobavitj CAS-integraciyu beskonfliktnyikh kommitov](../../Zhurnal/2026-08-03_21-37-49_MSK_dobavitj-CAS-integraciyu-beskonfliktnyikh-kommitov/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye ob izolirovannom paralleljnom ispolnenii i proveryayemoj integracii](../../Trebovaniya/✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md)
- [FUM-STEP-0085 — izolirovannyij pishusjhij poduzel i kandidatnyij commit](✅-FUM-STEP-0085-dobavitj-izolirovannyij-pishusjhij-poduzel-i-kandidatnyij-commit.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:eb66ecafe4f0b2b88bc32976c9ab647da6907fd38f84f9e732e67fea774445cf -->
<!-- FUM-MD-RECENCY:END -->
