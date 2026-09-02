+++
schema_version = 1
card_id = "FUM-STEP-0143"
status = "active"
+++

# Dobavitj proveryayemyij marshrut zapominaniya vyiyavlennyikh principov

Vyiyavleniye poleznogo pravila v dialoge yesjhyo ne oznachayet, chto ono stalo chastjyu dolgovremennoj [pamyati FUM](../../Glossarij/pamyatj-FUM.md). Nuzhen nablyudayemyij marshrut ot tochnogo svideteljstva k kanonicheskomu nositelyu, proverke libo yavnomu resheniyu ne zakreplyatj pravilo sejchas.

## Zadacha

Dobavitj v dokumentacionnyij prototip FUM yavnyij marshrut, po kotoromu kazhdyij zaregistrirovannyij v [rabochej sessii](../../Glossarij/rabochaya-sessiya.md) kandidat na obobsjhayemyij princip, invariant ili povtorno primenimyij sposob dejstviya poluchayet tochnoye iskhodnoye svideteljstvo, formulirovku, oblastj i gorizont dejstviya, proverochnyij status i odin iz zakryitogo nabora iskhodov: `закреплён`, `уже закреплён`, `отложен` ili `отклонён`.

Prinyatyij operacionnyij princip svyazyivayetsya s proveryayemyim kontraktom, testom, [avtomatizaciyej FUM](../../Glossarij/avtomatizaciya-FUM.md) libo aktualjnoj kartochkoj ikh sozdaniya. Kanonicheskiye pravila i trebovaniya ostayutsya v svoikh predmetnyikh oblastyakh; zhurnaljnyij inventarj marshrutov ne stanovitsya vtoryim nezavisimo redaktiruyemyim istochnikom istinyi.

## Pochemu sejchas

Princip lokaljnogo vosproizvedeniya avtomatizacij i ikh razvitiya cherez [TDD](../../Glossarij/TDD.md) uzhe zakreplyon iskhodnyim zaprosom 2026-06-23, pravilami rabochej sessii i dokumentaciyej o vosproizvodimyikh avtomatizaciyakh. Tekusjhij dialog obnaruzhil otdeljnyij razryiv: priznaniye novogo principa v otvete ne dokazyivayet yego dolgovremennuyu fiksaciyu i ne ostavlyayet mashinno proveryayemogo resheniya o daljnejshej sudjbe.

Susjhestvuyusjhiye konturyi sokhranyayut zaprosyi, proveryayut svyaznostj rabochej sessii i otdeljno marshrutiziruyut nablyudayemyiye sboi, no ne trebuyut polnogo iskhoda dlya yavno vyiyavlennyikh polozhiteljnyikh principov. Poetomu novyij marshrut dopolnyayet, a ne dubliruyet kartochki sboyev i kanonicheskiye pravila.

## Kriterii zaversheniya

- V pravilakh i glossarii opredelyon registriruyemyij kandidat na princip i provedena proveryayemaya granica mezhdu nim, razovyim porucheniyem, nablyudayemyim faktom, sboyem, gipotezoj i otkryityim voprosom.
- Dlya kazhdogo kandidata sokhranyayutsya tochnyij istochnik s adresuyemyim svideteljstvom, iniciator, razlicheniye pryamoj formulirovki i vyivoda, normalizovannaya formulirovka, oblastj i gorizont dejstviya, proverochnyij status, marshrutnyij iskhod i adres kanonicheskoj celi libo prichina resheniya.
- Kazhdyij novyij `запрос.md` posle yavno zakreplyonnoj vremennoj granicyi soderzhit razdel `## Выявленные принципы`: strukturirovannyiye zapisi ili tochnoye otricateljnoye svideteljstvo ob ikh otsutstvii.
- Iskhod `закреплён` ukazyivayet novyij kanonicheskij nositelj i primenimuyu proverku; `уже закреплён` — susjhestvuyusjhuyu ne boleye slabuyu zapisj bez dublya; `отложен` — aktualjnuyu kartochku shaga libo otkryityij vopros; `отклонён` — yavnoye osnovaniye bez stiraniya iskhodnogo nablyudeniya.
- Vremennyij prioritet poluchayet yavnyij gorizont dejstviya: formulirovka o sterzhnevoj celi na tekusjhij moment ne prevrasjhayetsya molcha v bessrochnoye pravilo.
- Dlya operacionnogo ili povtoryayemogo principa odnoj prozyi nedostatochno: zapisj ukazyivayet susjhestvuyusjhuyu avtomatizaciyu, test, deklarativnuyu proverku libo aktualjnuyu kartochku ikh sozdaniya. Dlya neavtomatiziruyemogo smyislovogo principa fiksiruyutsya kriterij proverki i prichina granicyi avtomatizacii.
- Ravnyij ili boleye siljnyij dejstvuyusjhij princip svyazyivayetsya kak susjhestvuyusjhij ekvivalent bez sozdaniya konkuriruyusjhego kanonicheskogo pravila.
- Princip, izvlechyonnyij iz sboya, ssyilayetsya na yego fakticheskoye dokazateljstvo, no ne dubliruyet kontur FUM-STEP-0114: kartochka sboya khranit proyavleniya nedorabotki, a marshrut principa — obobsjhayemoye pravilo i resheniye o yego fiksacii.
- Avtomatizacii strukturyi papok zaprosov i svyaznosti rabochej sessii cherez TDD sozdayut i zakryito proveryayut novyij razdel, obyazateljnyiye polya, dopustimyij iskhod, susjhestvovaniye i tip celi, vremennoj gorizont i proveryayemyij nositelj operacionnogo principa.
- Avtonomnyiye fiksturyi pokryivayut propusjhennyij princip, otricateljnoye svideteljstvo, novoye zakrepleniye, sopostavleniye s susjhestvuyusjhej zapisjyu bez dublya, otlozhennyij i otklonyonnyij iskhodyi, vremennyij princip bez gorizonta, bituyu celj i operacionnyij princip bez testa, avtomatizacii ili kartochki.
- Tekusjhij princip avtomatizacij i TDD sluzhit polozhiteljnoj regressiyej iskhoda `уже закреплён`; metaprincip neobkhodimosti zapominatj vnovj obnaruzhivayemyiye pravila — primer nemedlennogo zakrepleniya ruchnoj normyi v `AGENTS.md`, togda kak realizaciya yeyo obsjhego mashinnogo marshruta otlozhena na etu kartochku.
- Proverki obeikh zatronutyikh avtomatizacij i obsjhij smoke-check prokhodyat lokaljno bez seti i sekretov.
- Mashinnaya garantiya ogranichena polnotoj marshrutizacii zaregistrirovannyikh kandidatov i nalichiyem polozhiteljnoj libo otricateljnoj attestacii sessii; ona ne vyidayotsya za semanticheskuyu polnotu obnaruzheniya vsekh skryityikh principov yestestvennogo yazyika.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-08_21-25-13_MSK_zakrepitj-zapominaniye-vnovj-obnaruzhivayemyikh-principov/zapros.md)
- [iskhodnyij zapros o lokaljnom vosproizvedenii avtomatizacij i TDD](../../Zhurnal/2026-06-23_13-47-38_MSK/zapros.md)
- [pravila rabochikh sessij](../../AGENTS.md)
- [vosproizvodimyiye avtomatizacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [nablyudayemyij vkhodnoj signal](../../Glossarij/nablyudayemyij-vkhodnoj-signal.md)
- [trebovaniye FUM-REQ-0020 o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md)
- [avtomatizaciya strukturyi papok zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md)
- [avtomatizaciya svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-08 21:36:26 MSK -->
<!-- content-sha256: sha256:b4bae9fec3bed9f9b81ad4dcd08b018eadccb629e0e2f528715c6cc26ee4572c -->
<!-- FUM-MD-RECENCY:END -->
