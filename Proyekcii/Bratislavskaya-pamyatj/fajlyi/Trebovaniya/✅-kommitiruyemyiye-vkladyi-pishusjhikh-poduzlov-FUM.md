# Kommitiruyemyiye vkladyi pishusjhikh poduzlov FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0024 -->

Ekspluatacionnyij status: otlozheno. Kartochka sokhranyayet kandidatnyiye commits pishusjhikh poduzlov i otdeljnuyu integraciyu kak celevuyu arkhitekturu; yeyo imperativnyij tekst ne aktiviruyet paralleljnogo pisatelya, result-ref ili integratora v tekusjhem repozitorii.

Kazhdyij dopusjhennyij k izmeneniyu pamyati pishusjhij poduzel FUM dolzhen vyipolnyatj odin ogranichennyij rabochij paket ot tochnogo Git-sostoyaniya v sobstvennoj izolirovannoj oblasti i peredavatj kazhdyij osmyislennyij publikacionno dopustimyij rezuljtat kak adresuyemyij kandidatnyij commit. Integraciya rezuljtata v roditeljskuyu vetku yavlyayetsya otdeljnyim proveryayemyim resheniyem i ne dolzhna stiratj iskhodnyij commit poduzla.

## Semanticheskiye svyazi

- **zavisit ot:** [kontekstno posiljnyikh ispolnyayemyikh shagov](🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md) — odin pishusjhij poduzel dolzhen zavershitj sobstvennyij commit i peredachu v predelakh odnogo ogranichennogo rabochego paketa.
- **usilivayet:** [proveryayemyij mnogoagentnyij kontur FUM](🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md) — ustojchivyij Git-obyyekt delayet proiskhozhdeniye pishusjhego vklada adresuyemyim, no ne prevrasjhayet obsjhij runtime ili obsjhij istochnik v nezavisimoye svideteljstvo.
- **trebuyetsya dlya:** [izolirovannogo paralleljnogo ispolneniya i proveryayemoj integracii](✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md) — integrator mozhet prinimatj paralleljnyiye rezuljtatyi toljko posle ikh fiksacii otdeljnyimi kandidatnyimi commit.

## Kriterii proverki

- kazhdyij zapusk sokhranyayet tochnyiye identifikatoryi epizoda, kartochki, pokoleniya shaga i pishusjhego poduzla, iskhodnyij `base_oid`, polnyij ref rabochej vetki i identichnostj repozitoriya;
- pishusjhij poduzel izmenyayet toljko sobstvennyij klon i unikaljnuyu vetku i ne menyayet checkout, indeks, refs ili istoriyu roditeljskogo integratora;
- osmyislennyij publikacionno dopustimyij diff zavershayetsya nepustyim kandidatnyim commit, a `no-op`, blokirovka do zapisi i publikacionno nedopustimyij rezuljtat poluchayut yavnyij tipizirovannyij iskhod bez iskusstvennogo pustogo commit;
- pasport rezuljtata svyazyivayet commit i tree s khyeshami obyazateljnyikh vkhodov, razreshyonnoj oblastjyu izmenenij, fakticheskim diff, vyipolnennyimi proverkami, izvestnyimi ogranicheniyami i marshrutom peredachi;
- prinyatyij, otklonyonnyij, vyitesnennyij ili konfliktuyusjhij kandidat ostayotsya dostizhimyim po ustojchivomu ref do yavnogo proveryayemogo resheniya ob arkhivirovanii, a yego sostoyaniye integracii khranitsya otdeljno ot soderzhaniya;
- dlya vsekh dopusjhennyikh zapuskov schitayetsya pokryitiye commit: dolya osmyislennyikh publikacionno dopustimyikh pishusjhikh rezuljtatov, zavershivshikhsya kandidatnyim commit; isklyucheniya perechislyayutsya po tipam, a ne udalyayutsya iz otchyota molcha;
- raznyiye commit, vetki, klonyi ili fork uluchshayut izolyaciyu i proiskhozhdeniye, no sami po sebe ne povyishayut nezavisimostj svideteljstva.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: avtonomnyij local-bare stend zapuskayet dva `WritingSubnodeExecutor` paralleljno ot odnogo zakreplyonnogo paketa v raznyikh klonakh i unikaljnyikh vetkakh. Oba osmyislennyikh publikacionno dopustimyikh zapuska zavershayutsya dvumya kandidatnyimi commit s vosstanavlivayemyimi pasportami i sokhranyonnyimi refs, a iskhodnyij checkout ostayotsya neizmennyim. Otchyot pokryitiya svorachivayet pyatj fakticheskikh sobyitij dopusjhennyikh zapuskov i tri sobyitiya integracii: otdeljno tipiziruyet `commit`, `no-op`, blokirovku, publikacionnyij otkaz i konflikt, a pustoj commit opredelyayet toljko po realjnomu ravenstvu dereva sozdannogo commit bazovomu derevu. Kandidatyi ostayutsya dostizhimyimi i pri neizvestnom konflikte, kotoryij zavershayetsya `resolution_required` bez dvizheniya celevogo ref.

Trebovaniye ne zastavlyayet sozdavatj pustyiye, neproveryayemyiye ili publikacionno nedopustimyiye commit radi metriki i ne razreshayet pishusjhemu poduzlu obkhoditj granicyi dostupa.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-05 00:37:53 MSK — Provesti avtonomnuyu skvoznuyu priyomku repozitornoj kompozicii](../Zhurnal/2026-08-05_00-37-53_MSK_provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii/zapros.md)
- [iskhodnyij zapros 2026-08-03 21:37:49 MSK — Dobavitj CAS-integraciyu beskonfliktnyikh kommitov](../Zhurnal/2026-08-03_21-37-49_MSK_dobavitj-CAS-integraciyu-beskonfliktnyikh-kommitov/zapros.md)
- [iskhodnyij zapros 2026-08-03 18:46:53 MSK — Dobavitj izolirovannyij pishusjhij poduzel i kandidatnyij commit](../Zhurnal/2026-08-03_18-46-53_MSK_dobavitj-izolirovannyij-pishusjhij-poduzel-i-kandidatnyij-commit/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:68382fcd3d8e5d3c667a31775920a2ad24df8b59f4583ebf37395b8735b815be -->
<!-- FUM-MD-RECENCY:END -->
