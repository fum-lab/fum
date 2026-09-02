# Minimaljnyij pasport [peredavayemogo rezuljtata FUM](../Glossarij/peredavayemyij-rezuljtat-FUM.md)

Minimaljnyij pasport versii `1` - eto mashinno chitayemaya JSON-zapisj ob odnom zakreplyonnom sostoyanii odnogo rezuljtata. Ona svyazyivayet materializovannyiye artefaktyi s proiskhozhdeniyem, proverkami, ozhidayemoj i fakticheskoj stoimostjyu, uverennostjyu proizvodyasjhego uzla, adresatami i nablyudayemyim sostoyaniyem kazhdoj peredachi. Pasport peredayotsya ryadom s rezuljtatom ili obnaruzhivayetsya po ustojchivoj ssyilke, no ne zamenyayet sam rezuljtat, yego iskhodnyiye materialyi i dokazateljstva.

Versiya `1` prednaznachena dlya dokumentacionnogo prototipa [FUM](../Glossarij/FUM.md). Yeyo tochnaya struktura zakreplena v [JSON Schema](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/skhema-pasporta-v1.json), mezhpolevyiye invariantyi - v [semanticheskom validatore](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/proveritj-pasport-v1.py), a zapolnennaya [fikstura FUM-STEP-0025](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/primer-pasporta-FUM-STEP-0025.json) pokazyivayet pasport uzhe zavershyonnoj rabochej sessii s izvestnyim commit SHA.

## Yedinica pasporta

`passport_id` identificiruyet konkretnuyu redakciyu pasporta, a `result.result_id` - sam peredavayemyij rezuljtat. Odin pasport opisyivayet toljko odno zakreplyonnoye sostoyaniye rezuljtata v yavno nazvannoj oblasti. Izmeneniye smyisla rezuljtata, nabora artefaktov, ikh zakreplyonnogo sostoyaniya ili uzhe zapisannyikh faktov trebuyet novoj redakcii pasporta; prezhnyaya redakciya ukazyivayetsya cherez `supersedes_passport_id`, a ne perepisyivayetsya kak budto ona vsegda soderzhala novyiye svedeniya.

`result` soderzhit:

- ustojchivyij `result_id`, vid i kratkoye opisaniye rezuljtata;
- `scope.claim` - proveryayemoye utverzhdeniye, radi kotorogo rezuljtat peredayotsya;
- kriterii priyomki, predpolagayemyiye sposobyi primeneniya, predusloviya, riski i isklyucheniya granicyi;
- nepustoj spisok `artifacts` s lokaljnyimi identifikatorami, rolyami, publikacionno prigodnyimi ssyilkami i tochnyim zakrepleniyem sostoyaniya.

Oblastj dolzhna pozvolyatj adresatu otlichitj to, chto pasport utverzhdayet, ot togo, chego on ne proveryal. Ssyilka na manifest izmenyonnyikh fajlov dopustima kak otdeljnyij artefakt, no ne otmenyayet yavnogo perechisleniya osnovnyikh nositelej rezuljtata.

## Istochniki i proiskhozhdeniye

`provenance` svyazyivayet rezuljtat s proizvodyasjhim [FUM-uzlom](../Glossarij/FUM-uzel.md), iskhodnyimi trebovaniyami i materialami, roditeljskimi rezuljtatami i nositelem zakreplyonnogo sostoyaniya. Dlya Git-rezuljtata `origin` nazyivayet repozitorij, rolj linii proiskhozhdeniya i tochnyij commit SHA. Rolj razlichayet bazovyij upstream, fork, vozvrasjhyonnoye v upstream uluchsheniye i inoj yavno opisannyij sluchaj; odin SHA bez konteksta repozitoriya etogo razlichiya ne sokhranyayet.

Istochniki ukazyivayutsya publikacionno chistyimi putyami otnositeljno kornya [pamyati FUM](../Glossarij/pamyatj-FUM.md) libo ustojchivyimi publichnyimi identifikatorami. Lokaljnyiye absolyutnyiye puti, domashniye sokrasjheniya, sekretyi, privatnyiye URL i mashinno-zavisimyiye perenapravleniya zapresjhenyi.

Yesli `result.state_ref` i `provenance.origin.commit` sovpadayut kak odin `git:commit`, vse lokaljnyiye ssyilki pasporta razreshayutsya s tochnyim registrom v dereve etogo kommita, a ne v tekusjhem checkout. Poetomu istoricheskij pasport sokhranyayet iskhodnyiye puti dazhe posle perestrojki aktualjnyikh papok. Pri inom zakreplenii lokaljnyiye ssyilki po-prezhnemu proveryayutsya v tekusjhem korne pamyati.

Pasport rezuljtata, materializovannogo tem zhe Git-kommitom, ne mozhet zaraneye soderzhatj SHA etogo kommita: khyesh zavisit ot soderzhimogo pasporta. Poetomu zapolnennaya fikstura versii `1` opisyivayet predyidusjhij zavershyonnyij rezuljtat. V budusjhem tekusjheye pokoleniye mozhet poluchitj okonchateljnoye Git-zakrepleniye vo vneshnem [reyestre proiskhozhdeniya FUM](../Glossarij/reyestr-proiskhozhdeniya-FUM.md) ili v sleduyusjhej neizmenyayemoj redakcii pasporta; podstavlyatj predpolagayemyij SHA neljzya.

## Proverka

`verification` khranit otdeljnyiye proverki s unikaljnyimi identifikatorami. Kazhdaya proverka nazyivayet:

- kontur `internal` ili `external`;
- proveryayemyiye artefaktyi;
- metod;
- status `passed`, `failed`, `inconclusive` ili `not_run`;
- nablyudayemyiye svideteljstva libo yavnuyu prichinu otsutstviya rezuljtata.

`passed` i `failed` trebuyut svideteljstva. `inconclusive` i `not_run` ne dokazyivayut kachestvo i ne podmenyayutsya otsutstviyem polya. Vnutrennyaya proverka, vyipolnennaya proizvodyasjhim uzlom, ne stanovitsya vneshnej toljko potomu, chto ispoljzovala test ili avtomatizaciyu; kontur opredelyayetsya nezavisimostjyu ocenivayusjhej storonyi.

Pasport mozhet ssyilatjsya na sobyitiya `result` i `check` [minimaljnoj trassyi ispolnyayemogo agentskogo cikla](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md), ne kopiruya vsyu trassu i ne raskryivaya skryityiye rassuzhdeniya modeli.

## Stoimostj

`cost.expected` i `cost.actual` fiksiruyutsya razdeljno. Kazhdyij sloj imeyet pokryitiye `complete`, `partial` ili `unknown` i raskladyivayet stoimostj na nablyudayemyiye komponentyi: vyichisleniye, kalendarnoye vremya, kommunikaciyu, proverku, vosstanovleniye posle oshibok, chelovecheskoye vnimaniye, denjgi, energiyu libo yavno nazvannyij inoj vid.

Izmerennaya ili ocenyonnaya velichina soderzhit chislo, yedinicu i osnovaniye. Neizvestnaya velichina soderzhit `null` vmesto chisla i yedinicyi i obyyasnyayet prichinu neizvestnosti. Neizvestnaya stoimostj ne ravna nulyu, chastichnoye pokryitiye ne vyidayotsya za polnyij itog, a nesovmestimyiye yedinicyi ne skladyivayutsya v odnu psevdotochnuyu summu.

## Uverennostj

`confidence` otnositsya k tochnomu utverzhdeniyu `scope.claim` i nazvannyim artefaktam. Ona khranit ocenivayusjhij uzel, status `estimated` ili `unknown`, metod i osnovaniya. Chislovoye znacheniye `0..1` dopustimo toljko dlya yavnoj ocenki; bez kalibrovki ono ostayotsya vnutrennej shkaloj, a ne veroyatnostjyu obyyektivnoj istinnosti.

Uverennostj ne ravna vneshnemu kachestvu, uspeshnoj dostavke, priyomke adresatom ili razresheniyu na dejstviye. Nesoglasiye vneshnego kontura sokhranyayetsya otdeljnoj proverkoj, a ne perepisyivayet zadnim chislom vnutrennyuyu ocenku.

## Adresatyi i status peredachi

`recipients` obyyavlyayet adresatov do ssyilok na nikh iz marshrutov peredachi. Dlya kazhdogo adresata zadayutsya celj, urovenj dostupa i ogranicheniya. Sam pasport opisyivayet usloviye dostupa, no ne vyidayot pravo chteniya ili dejstviya.

Minimaljnaya versiya fiksiruyet riski cherez `scope.exclusions` i ogranicheniya konkretnogo adresata cherez `recipients[].constraints`; otsutstviye otdeljnogo chislovogo rejtinga riska ne oznachayet nulevoj risk.

`transfers` khranit status otdeljno dlya kazhdogo marshruta i nabora artefaktov:

- `planned` - peredacha zaplanirovana, no popyitka ne zafiksirovana;
- `attempted` - popyitka nablyudayema, okonchateljnyij iskhod yesjhyo ne podtverzhdyon;
- `delivered` - transport podtverdil dostavku obyyavlennomu adresatu;
- `acknowledged` - poluchatelj otdeljno podtverdil polucheniye;
- `failed` - nablyudayemaya popyitka zavershilasj neuspekhom;
- `cancelled` - marshrut otmenyon do podtverzhdyonnoj dostavki.

Statusyi posle `planned` trebuyut svideteljstva. `delivered` ne oznachayet `acknowledged`, a ni odin iz nikh ne oznachayet prinyatiye, poleznostj ili kachestvo rezuljtata. Prinyatiye i otkloneniye otnosyatsya k vneshnemu otboru i fiksiruyutsya vneshnej proverkoj. Dlya neskoljkikh adresatov ne vvoditsya dvusmyislennyij obsjhij status: kazhdyij marshrut ostayotsya nablyudayemyim samostoyateljno.

Yesli adresatu dostavlyayetsya inoye predstavleniye, marshrut mozhet ssyilatjsya na zapisj [preobrazovaniya mezhdu nablyudatelyami FUM](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md). Pasport ne dubliruyet kartu signalov i poterj, a uspeshnaya dostavka ne dokazyivayet obratimostj preobrazovaniya ili dostupnostj polnogo istochnika.

## Invariantyi versii 1

Validnyij pasport soblyudayet sleduyusjhiye pravila:

1. Vse lokaljnyiye identifikatoryi unikaljnyi, a ssyilki na artefaktyi, adresatov, proverki i roditeljskuyu redakciyu razreshimyi v predelakh zapisi.
2. Kazhdyij artefakt imeyet publikacionno prigodnuyu ssyilku i zakrepleniye sostoyaniya; Git-proiskhozhdeniye soderzhit repozitorij, rolj linii i tochnyij obyyekt commit.
3. Uspeshnaya ili neuspeshnaya proverka podtverzhdena nablyudayemyim svideteljstvom; vnutrennij i vneshnij konturyi ne smeshivayutsya.
4. Ozhidayemaya i fakticheskaya stoimostj razdelenyi, pokryitiye yavno nazvano, a neizvestnoye znacheniye ne zameneno nulyom.
5. Uverennostj svyazana s utverzhdeniyem, artefaktami i osnovaniyami i ne ispoljzuyetsya kak vneshnyaya ocenka ili razresheniye.
6. Kazhdyij marshrut ssyilayetsya na susjhestvuyusjhego adresata i artefaktyi; nablyudayemyij iskhod posle planirovaniya podtverzhdyon svideteljstvom.
7. Pasport ne soderzhit skryityikh rassuzhdenij, sekretov i mashinno-lokaljnyikh ssyilok.
8. Neizvestnyiye polya zapresjhenyi. Rasshireniye smyisla trebuyet novoj versii skhemyi.

## Zapolnennyij primer i proverka

[Primer pasporta FUM-STEP-0025](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/primer-pasporta-FUM-STEP-0025.json) opisyivayet rezuljtat predyidusjhej rabochej sessii: iskhodnyij zapros, zavershyonnuyu kartochku, normativnyij dokument, skhemu, validator i fiksturyi svyazanyi s commit `8d9fd9ac4a737b68e368ad2736e169499ec6b845`. Fakticheskoye kalendarnoye vremya mezhdu nachalom sessii i kommitom izmereno, a ne nablyudavshiyesya vyichisliteljnaya stoimostj i chelovecheskoye vnimaniye chestno ostavlenyi neizvestnyimi. Lokaljnaya vetka `master` ukazana adresatom s podtverzhdyonnoj dostavkoj; dostizhimostj rezuljtata iz publichnogo remote ne utverzhdayetsya.

Strukturnaya proverka vyipolnyayetsya po JSON Schema Draft 2020-12. Sokhranyayemyij validator dopolniteljno proveryayet ssyilki mezhdu razdelami, uslovnyiye statusyi, bezopasnyiye publikacionnyiye ssyilki, nalichiye lokaljnyikh materialov i Git-kommita. [Avtonomnyij testovyij nabor](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/test-proveritj-pasport-v1.py) prinimayet zapolnennyij primer i otklonyayet otricateljnyiye mutacii osnovnyikh invariantov.

## Granica primenimosti

Versiya `1` opisyivayet dokumentaljnyij snimok odnogo materializovannogo rezuljtata i yego otdeljnyikh marshrutov peredachi. Ona ne yavlyayetsya runtime, transportom, avtomaticheskim ocensjhikom, kriptograficheskim reyestrom, universaljnoj metrikoj kachestva, riska ili stoimosti, vyichisleniyem vesov i kredita, polnoj rodoslovnoj rezuljtata libo razresheniyem dostupa. Pasport ne dokazyivayet podlinnostj istochnika sverkh yavno zakreplyonnyikh ssyilok i vyipolnennyikh proverok.

Format ne opredelyayet avtomaticheskoye prinyatiye rezuljtata i ne obyyedinyayet neskoljko pasportov v polnuyu [evolyucionnuyu cepochku FUM](../Glossarij/evolyucionnaya-cepochka-FUM.md). Reyestr proiskhozhdeniya, vneshnij otbor, vyichisleniye poleznosti i marshrutizaciya sleduyusjhikh peredach ostayutsya sleduyusjhimi sloyami. Zapolnennaya fikstura podtverzhdayet toljko zavershyonnuyu sessiyu FUM-STEP-0025 v tekusjhem snimke pamyati i ne dokazyivayet prigodnostj formata dlya vsekh budusjhikh vidov rezuljtatov.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-23_12-53-46_MSK_opisatj-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/zapros.md)
- [kartochka FUM-STEP-0026](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0026-opisatj-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md)
- [napravleniye «Evolyucionnyiye cepochki i otbor»](../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/06-evolyucionnyiye-cepochki-i-otbor.md)

## Opornyiye materialyi

- [Git-infrastruktura evolyucionnyikh cepochek FUM](20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)
- [Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Reyestr proiskhozhdeniya FUM](../Glossarij/reyestr-proiskhozhdeniya-FUM.md)
- [Dvukhkonturnyij otbor FUM](../Glossarij/dvukhkonturnyij-otbor-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:39779b80a4042eb292847c1b9b9a4c56ab33d8bde202027735d3b814ace1f378 -->
<!-- FUM-MD-RECENCY:END -->
