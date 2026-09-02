# Ogranichennoye avtomaticheskoye razresheniye Git-konfliktov

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0026 -->

Ekspluatacionnyij status: otlozheno vmeste s avtomaticheskim integracionnyim konturom. Kartochka sokhranyayet celevoj fail-closed resolver-kontrakt, no ne razreshayet obyichnoj ruchnoj sessii zapuskatj integratora, menyatj candidate/target refs ili avtomaticheski slivatj konflikt.

FUM dolzhen avtomaticheski razreshatj toljko te Git-konfliktyi, dlya kotoryikh zaraneye zaregistrirovano determinirovannoye pravilo s proveryayemoj oblastjyu primenimosti i posleduyusjhej polnoj proverkoj rezuljtata. Neizvestnyij, neodnoznachnyij ili soderzhateljnyij konflikt dolzhen sokhranyatj vse iskhodnyiye commit i zavershatj popyitku integracii yavnyim sostoyaniyem `resolution_required`, a ne skryityim vyiborom odnoj storonyi.

## Semanticheskiye svyazi

- **zavisit ot:** [izolirovannogo paralleljnogo ispolneniya i proveryayemoj integracii](✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md) — razresheniye konflikta dolzhno vyipolnyatjsya nad tochnyimi kandidatnyimi commit i svezhej vershinoj celevoj vetki vnutri odnoj serializovannoj popyitki.

## Kriterii proverki

- reyestr resolver-pravil zadayot tochnyij klass fajlov, predusloviya, algoritm, versiyu, ozhidayemyiye invariantyi i obyazateljnyiye proverki kazhdogo razresheniya;
- proizvodnyiye indeksyi, reyestryi i drugiye generiruyemyiye fajlyi razreshayutsya peresborkoj iz kanonicheskikh istochnikov, a ne postrochnyim vyiborom `ours` ili `theirs`;
- obyyedineniye zapisej po ustojchivyim identifikatoram dopuskayetsya toljko pri dokazannoj unikaljnosti, soglasovannoj skheme i otsutstvii raznyikh znachenij odnogo normativnogo polya;
- uspeshnoye razresheniye sozdayot otdeljnyij proveryayemyij integracionnyij commit, sokhranyayusjhij iskhodnyiye konfliktuyusjhiye commit v rodoslovnoj i mashinochitayemo nazyivayusjhij primenyonnoye pravilo;
- posle avtomaticheskogo razresheniya povtoryayutsya strukturnyiye validatoryi, celevyiye testyi, proverka publikacionnoj chistotyi i polnyij obyazateljnyij kontur celevogo repozitoriya;
- konflikt vne zaregistrirovannogo klassa, narusheniye predusloviya, raskhozhdeniye skhem, neuspeshnaya proverka ili smyislovoye protivorechiye zakryivayut publikaciyu i sokhranyayut diagnosticheskij artefakt s oboimi variantami;
- modeljnyij resolver mozhet predlozhitj novyij kandidatnyij commit, no yego rezuljtat ne prinimayetsya avtomaticheski tem zhe ispolnitelem i prokhodit obyichnuyu otdeljnuyu proverku;
- avtonomnyiye fiksturyi pokryivayut uspeshnuyu peresborku proizvodnogo fajla, dopustimoye obyyedineniye po identifikatoram, neizvestnyij konflikt, protivorechivoye pole, semantic conflict bez tekstovogo markera i sboj proverki posle razresheniya.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: v [proveryayemom Swift-prototipe](../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/README.md) realizovan reyestr versii `1` dlya dvukh tochnyikh klassov: polnoj peresborki proizvodnogo manifest i base-aware-obyyedineniya kanonicheskikh zapisej po ustojchivomu ID. Pasport integracii versii `2` sokhranyayet binding pravila, invariantyi rezuljtata i dva progona obyazateljnyikh proverok. Tridcatj avtonomnyikh Git-scenariyev [kartochki FUM-STEP-0087](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0087-dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md) podtverzhdayut razreshyonnyiye i fail-closed-iskhodyi na nastoyasjhikh lokaljnyikh Git-repozitoriyakh.

Realizovannyij reyestr ne obesjhayet razreshitj lyuboj konflikt, ne ispolnyayet proizvoljnyij kod proverok i ne schitayet otsutstviye tekstovyikh markerov dokazateljstvom sovmestimosti rezuljtatov. Modeljnoye predlozheniye ostayotsya obyichnyim kandidatnyim commit i prokhodit tu zhe vneshnyuyu proverku.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-04 02:55:45 MSK — Dobavitj ogranichennoye avtomaticheskoye razresheniye Git-konfliktov](../Zhurnal/2026-08-04_02-55-45_MSK_dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:dd7103cec7c59fb5e8b76738f0e937f697c29c50b1958e586fda76bce1d112c6 -->
<!-- FUM-MD-RECENCY:END -->
