# Istoriya: obmenivatjsya narabotkami mezhdu FUM-uzlami

Vladeljcu ili operatoru uzla nuzhno peredavatj proverennyiye [narabotki](../../Glossarij/narabotka.md) drugim [FUM-uzlam](../../Glossarij/FUM-uzel.md) i prinimatj chuzhiye rezuljtatyi bez slepogo kopirovaniya. Perenosimaya yedinica pamyati dolzhna nesti ne toljko soderzhaniye, no i proiskhozhdeniye, versiyu, primenimostj, zavisimosti, proverochnyij status i [urovenj dostupa](../../Glossarij/urovenj-dostupa.md).

Cennostj obmena sostoit v setevom nasledovanii udachnyikh reshenij pri sokhranenii lokaljnoj avtonomii. Poluchatelj dolzhen imetj pravo proveritj, adaptirovatj ili otklonitj paket, a dostup k otdeljnoj narabotke ne dolzhen prevrasjhatjsya vo vlastj nad pamyatjyu, identichnostjyu ili budusjhimi resheniyami uzla-istochnika.

## Poljzovateljskaya istoriya

Kak vladelec uzla-istochnika ili uzla-poluchatelya, ya khochu peredatj libo prinyatj narabotku s proveryayemyim pasportom i ogranicheniyami, chtobyi poleznyij rezuljtat mozhno byilo pereispoljzovatj bez poteri proiskhozhdeniya, privatnosti i prava na obosnovannyij otkaz.

## Osnovnoj scenarij

1. Uzel-istochnik vyidelyayet ustojchivuyu narabotku i formiruyet paket s identifikatorom, versiyej, naznacheniyem, granicami primenimosti, zavisimostyami, istochnikami i proverkami.
2. Istochnik naznachayet adresatov i razdeljnyiye prava chteniya, ispoljzovaniya, izmeneniya, publikacii i daljnejshej peredachi.
3. Pered eksportom FUM otdelyayet publichnyiye i razreshyonnyiye chasti ot privatnyikh, zakryityikh ili ogranichennyikh materialov.
4. Uzel-poluchatelj proveryayet istochnik, adresata, dostup, sovmestimostj, zavisimosti, proverochnyij status i konfliktyi s lokaljnoj pamyatjyu.
5. Poluchatelj zapuskayet razreshyonnyiye lokaljnyiye proverki i vyibirayet nablyudayemyij iskhod: prinyatj, adaptirovatj, otklonitj libo otlozhitj do utochneniya.
6. Prinyataya ili adaptirovannaya narabotka sokhranyayetsya kak vneshnij vklad s iskhodnyim proiskhozhdeniyem, nasleduyemyimi ogranicheniyami i osnovaniyem resheniya.
7. Proizvodnyij paket i daljnejshaya peredacha sokhranyayut primenimyiye ogranicheniya; status dostavki otlichayetsya ot priyomki i dokazannoj poleznosti.

## Aljternativyi i otkazyi

- Yesli dostup ne predostavlen ili predpolagayemoye ispoljzovaniye shire razreshyonnogo, soderzhimoye ne importiruyetsya; bezopasnyiye metadannyiye ogranicheniya sokhranyayutsya toljko kogda eto dopustimo.
- Yesli paket smeshivayet raznyiye urovni dostupa, eksportiruyetsya toljko dokazanno razreshyonnaya chastj bez skryitoj privatnoj nagruzki.
- Yesli zavisimosti nesovmestimyi ili trebovaniya konfliktuyut, poluchatelj sokhranyayet raskhozhdeniye, variantyi adaptacii i osnovaniye otkaza vmesto molchalivogo sliyaniya.
- Yesli proverka trebuyet nedostupnogo sekreta ili vneshnego sostoyaniya, rezuljtat ostayotsya neproverennyim v etoj srede i ne povyishayetsya do prinyatogo avtomaticheski.
- Otzyiv razresheniya menyayet daljnejshiye dopustimyiye operacii i fiksiruyetsya v proiskhozhdenii; on ne perepisyivayet istoriyu obmena zadnim chislom.

## Kriterii priyomki

- Paket imeyet mashinno obrabatyivayemyij pasport s identifikatorom, versiyej, naznacheniyem, primenimostjyu, proiskhozhdeniyem, zavisimostyami, proverkami i dostupom.
- Prava chteniya, ispoljzovaniya, izmeneniya, publikacii i daljnejshej peredachi razlichayutsya.
- Poluchatelj sokhranyayet rezuljtatyi proverok i yavnoye resheniye o priyomke, adaptacii ili otkaze.
- Adaptaciya ne stirayet iskhodnyij istochnik, proverochnyij status i nasleduyemyiye ogranicheniya.
- Konflikt i neizvestnostj ostayutsya nablyudayemyimi, a publichnyij paket ne soderzhit privatnyikh ili ogranichennyikh fragmentov.
- Dostavka, podtverzhdeniye polucheniya, prinyatiye i poleznostj ne podmenyayut drug druga.

## Granica primenimosti

Istoriya ne sozdayot yedinuyu globaljnuyu pamyatj, obyazateljnyij konsensus ili avtomaticheskoye doveriye mezhdu uzlami. Tekusjhij pasport peredavayemogo rezuljtata yavlyayetsya dokumentaljnyim kontraktom, a ne transportom, kriptograficheskim reyestrom ili razresheniyem dostupa. Prakticheskiye predelyi avarijnogo vmeshateljstva, kvoruma i ostatochnoj avtonomii ostayutsya v [otkryitom voprose o granicakh vlasti uzlov FUM](../../Voprosyi/2026-06-22_07-51-48_MSK_granicyi-vlasti-uzlov-FUM.md).

## Status

Tekusjhij status: publichnyij Git-obmen i dokumentaljnyij pasport peredavayemogo rezuljtata pokazyivayut otdeljnyiye mekhanizmyi proiskhozhdeniya, versij i proverki, no ne obrazuyut mezhuzlovoj runtime.

Celevoj status: samostoyateljnyiye FUM-uzlyi vyipolnyayut eksport, dostavku, proverku i lokaljnoye resheniye o priyomke s razdeljnyimi pravami i nablyudayemyimi otkazami.

## Istochniki trebovanij

- [iskhodnyij zapros o napolnenii poljzovateljskikh istorij FUM](../../Zhurnal/2026-07-28_10-56-30_MSK_napolnitj-poljzovateljskiye-istorii-FUM/zapros.md)

## Opornyiye dokumentyi

- [Obmen narabotkami i urovni dostupa](../09-obmen-narabotkami-i-urovni-dostupa.md)
- [Minimaljnyij pasport peredavayemogo rezuljtata FUM](../39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md)
- [Publichnyij upstream i forki pamyati FUM](../27-publichnyij-upstream-i-forki-pamyati.md)
- [Repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:80ecf9e9a43c4b062144ef0718aea5b3da0eef444ff4b6e213bfcaf8f8adb42f -->
<!-- FUM-MD-RECENCY:END -->
