+++
schema_version = 1
card_id = "FUM-STEP-0085"
status = "completed"
+++
# Dobavitj izolirovannyij pishusjhij poduzel i kandidatnyij commit

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj k prototipu avtonomnyij ispolnitelj odnogo pishusjhego rabochego paketa. Ispolnitelj dolzhen sozdatj otdeljnyij klon ot tochnogo `base_oid`, naznachitj unikaljnuyu vetku, primenitj determinirovannoye izmeneniye toljko v razreshyonnoj oblasti, vyipolnitj obyyavlennyiye proverki i sokhranitj osmyislennyij rezuljtat kandidatnyim commit s mashinochitayemyim pasportom. Roditeljskij checkout, indeks, refs i istoriya ne dolzhnyi izmenyatjsya.

## Rezuljtat

V [proveryayemyij mnogoagentnyij kontur](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/README.md) dobavlen `WritingSubnodeExecutor`. On prinimayet proverennyij WorkPackage v1 i otdeljnyij tipizirovannyij zapros s ustojchivyimi identifikatorami epizoda, pokoleniya shaga, kartochki, zapuska, poduzla i repozitoriya, tochnyimi `base_oid` i celevyim ref i konechnyim naborom determinirovannyikh zapisej. Do mutacii kandidatnogo checkout povtoryayetsya polnyij predpuskovoj analiz paketa, vklyuchaya khyeshi vkhodov, oblastj, isklyucheniya, zavisimosti, proverki, handoff i byudzhetyi.

Ispolnitelj sozdayot vne istochnika otdeljnyij klon bez lokaljnyikh hardlink i alternates, proveryayet sobstvennyiye Git directory i common-dir i naznachayet unikaljnyiye branch ref i result ref. Zapisj razreshena toljko obyichnyim fajlam vnutri `listed_paths_only`; fakticheskij staged diff i zakryityiye deklarativnyiye proverki povtorno sveryayutsya do sozdaniya odnogo nepustogo neposredstvennogo commit ot `base_oid`. Specifikacii proverok vkhodyat v khyesh zaprosa, poetomu pod tem zhe identifikatorom neljzya nezametno podmenitj ispolnyayemuyu semantiku.

Istochnik i vosstanavlivayemyij klon prokhodyat fajlovyij audit do Git-komand: specialjnyiye obyyektyi i ssyilki vnutri `.git` zapresjhenyi, config chitayetsya bez perekhoda po ssyilke, a dopustimyiye lokaljnyiye klyuchi obrazuyut zakryityij spisok. Vosstanovleniye otdeljno proveryayet obyichnyiye komponentyi `runs`, kataloga zapuska, klona i pasportov, pryamoj tip `commit` u oboikh refs i sovpadeniye SHA-256 kanonicheskogo pasporta s ustojchivoj kvitanciyej.

Vneshnij kanonicheskij pasport svyazyivayet tochnyiye bajtyi paketa i otchyota preflight, pobajtovyij snimok iskhodnogo repozitoriya, identifikatoryi, commit, tree, roditelya, oba refs, vkhodyi, zavisimosti, byudzhetyi, fakticheskiye puti i khyesh diff, proverki, ogranicheniya i podgotovlennyij, no yesjhyo ne prinyatyij i ne opublikovannyij marshrut peredachi. Mashinnyiye puti ostayutsya vo vneshnem runtime-kontekste. Oba refs fiksiruyutsya odnoj Git-tranzakciyej, pasport i kvitanciya iskhoda — atomarnyimi neizmenyayemyimi fajlami. Tochnyij povtor `run_id` sveryayet khyesh zaprosa i samostoyateljno proveryayet prezhniye pasport, klon, refs, commit, tree, roditelya i diff; oborvannaya popyitka vozobnovlyayetsya v novom klone s sokhraneniyem prezhnego klona kak diagnosticheskogo artefakta, a konfliktuyusjheye soderzhimoye zakryivayetsya otdeljnyim iskhodom.

Tipizirovannyiye otricateljnyiye iskhodyi razlichayut `no-op`, blokirovku do zapisi, vyikhod za scope, gryaznyij istochnik, izmenivshijsya vkhod, sekret, publikacionnyij otkaz, proval proverki, smenu bazyi i konflikt zapuska; ikh kvitancii obespechivayut tot zhe iskhod pri tochnom povtore, a iskusstvennyij commit i result ref ne sozdayutsya. Avtonomnyiye testyi pokryivayut obyazateljnyiye polozhiteljnyiye i otricateljnyiye scenarii, otdeljnyij bezokonnyij process vosstanovleniya pasporta, oborvannuyu popyitku, povrezhdeniye ref, simvolicheskuyu ssyilku vmesto pasporta i pobajtovo-obyyektnuyu neizmennostj iskhodnogo checkout. Postavka ne zapuskayet modelj ili setj, ne integriruyet kandidat, ne vyipolnyayet push i ne podklyuchayet tekusjhikh subagentov obsjhej rabochej kopii k novomu ispolnitelyu.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-03_18-46-53_MSK_dobavitj-izolirovannyij-pishusjhij-poduzel-i-kandidatnyij-commit/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye o kommitiruyemyikh vkladakh pishusjhikh poduzlov FUM](../../Trebovaniya/✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md)
- [FUM-STEP-0084 — topologiya i pasport repozitornoj kompozicii](✅-FUM-STEP-0084-zakrepitj-topologiyu-i-pasport-repozitornoj-kompozicii-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:6477dffad89cf2b064ba760887a6aa82b6b7ffbfc2571041b9633b151fce3b8a -->
<!-- FUM-MD-RECENCY:END -->
