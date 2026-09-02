# Opisaniye FUM dlya razrabotchikov PO

FUM uzhe rabotayet kak svyaznaya lokaljnaya inzhenernaya pamyatj i imeyet dejstvuyusjhij bezokonnyij Swift-kontur vosproizvodimogo izmeneniya pamyati. Odnovremenno pervyij produktovyij URL-srez poluchil versionirovannyij kontrakt i atomarnyiye kartochki trebovanij, no samogo produktovogo URL-servisa, yedinogo prilozheniya i sobstvennogo agentskogo runtime yesjhyo net. Dokumentacionnaya stadiya ostayotsya nezavershyonnoj so statusom `5 из 6`.

## Pasport opisaniya

- Adresat: razrabotchiki PO, inzheneryi agentskikh sistem, arkhitektoryi i tekhnicheskiye uchastniki, ocenivayusjhiye vosproizvodimostj i granicyi realizacii FUM.
- Celj: pokazatj fakticheski rabotayusjhiye konturyi, otdelitj inzhenernyij headless-prototip ot specificirovannogo produktovogo URL-servisa i oboznachitj proveryayemyij putj k korobochnoj forme.
- Status: polnaya peresborka 2026-07-28 20:06:05 MSK.
- Avtomatizaciya: [postroyeniye opisaniya FUM dlya adresata](Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md), profilj `для-разработчиков-ПО-v2`.
- Osnovnyiye istochniki: [pasport dokumentacionnogo prototipa i URL-sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md), [pasport nachaljnogo korobochnogo prototipa](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md), [ispolnyayemyij headless-prototip](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md), [stadii planirovaniya](../Planirovaniye/stadii/README.md), [staryij audit produktovogo pasporta](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md) i chetyire kartochki trebovanij pervogo URL-sreza.
- Ogranicheniya: opisaniye ne vvodit trebovaniya, ne schitayet vneshnij Codex sobstvennyim runtime FUM, ne povyishayet lokaljnyij CLI ili Swift-prototip do produkta i ne vyivodit perekhod stadii iz rezuljtata povtornogo audita, kotoryij ne yavlyayetsya vkhodom profilya `v2`.

## Kratkaya formulirovka

Tekusjhij FUM sostoit iz tryokh razlichimyikh sloyov. [Dokumentacionnyij prototip FUM](../Glossarij/dokumentacionnyij-prototip-FUM.md) uzhe svyazyivayet poljzovateljskiye zaprosyi, istochniki, proizvodnuyu dokumentaciyu, trebovaniya, planyi, zhurnalyi, lokaljnyiye proverki i Git-kommityi v dolgovremennuyu [pamyatj proyekta](../Glossarij/pamyatj-FUM.md). Bezokonnyij Swift-paket perenosit chastj etikh svojstv v sobstvennyiye mekhanizmyi pamyati i ispolneniya. Pervyij produktovyij URL-srez poka susjhestvuyet toljko kak proveryayemaya specifikaciya budusjhego servisa.

Vneshnyaya sessiya Codex mozhet chitatj pamyatj, izmenyatj fajlyi, zapuskatj proverki i prodolzhatj vetku cherez repozitornyiye mekhanizmyi, no ostayotsya vneshnej inzhenernoj poverkhnostjyu. Sobstvennyij [agentskij cikl FUM](../Glossarij/agentskij-cikl.md) dolzhen otdeljno realizovatj nablyudeniye, modeljnyij shag, dejstviye, proverku, ostanovku i sokhraneniye rezuljtata vnutri postavlyayemogo kontura.

## Chto uzhe rabotayet

### Svyaznaya inzhenernaya pamyatj

Repozitorij yavlyayetsya rabotayusjhim rannim konturom FUM, a ne toljko sobraniyem konceptualjnyikh tekstov. Doslovnyij zapros otdelyon ot proizvodnoj dokumentacii, trebovaniya imeyut ustojchivyiye identifikatoryi i svyazi, planirovaniye predstavleno cheloveku i mashine, a rabochaya sessiya vozvrasjhayet proverennyij rezuljtat v istoriyu. Lokaljnyiye [avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md) proveryayut strukturu pamyati, planovyiye reyestryi, ssyilki, sluzhebnuyu svezhestj i ispolnyayemyiye prototipyi.

Prinyatyij `fum source archive` yavlyayetsya lokaljnyim instrumentaljnyim konturom dokumentacionnogo prototipa. On prinimayet ogranichennyij HTML-URL, sobirayet staging-snimok, proveryayet manifest, atomarno zamenyayet upravlyayemyij nabor fajlov i svyazyivayet istochnik s zaprosom. Eto poleznyij obrazec povedeniya i regressii, no ne produktovyij servis istochnikov: yego granica proiskhozhdeniya, podtverzhdeniya i fajlovoj ustanovki ne podmenyayet budusjhuyu yedinuyu produktovuyu tranzakciyu.

### Bezokonnyij Swift-kontur pamyati

[Prototip vosproizvodimogo popolneniya pamyati](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) — dejstvuyusjhij inzhenernyij Swift-paket bez GUI, seti, sekretov, vneshnikh SwiftPM-zavisimostej i realjnoj LLM. On prinimayet versionirovannyiye sobyitiya, vyipolnyayet toljko ogranichennyiye operacii `remember` i `compose`, stroit kanonicheskiye snimok, trassu proiskhozhdeniya i inertnuyu modelj predstavleniya, a zatem mozhet podtverditj rezuljtat kak vosstanavlivayemoye pokoleniye.

Tekusjheye pokoleniye zakreplyayet yazyikonejtraljnyij profilj kanonicheskogo JSON, polnyij zhurnal prinyatyikh sobyitij i povtornoye ispolneniye redjyuserov. Sotrudnichayusjhiye processyi ispoljzuyut mezhprocessnyij compare-and-swap ukazatelya `CURRENT`; otdeljnyiye processnyiye scenarii podtverzhdayut, chto posle avarijnogo zaversheniya vosstanavlivayetsya prezhneye libo polnostjyu proveryayemoye novoye pokoleniye. Eto dokazateljstvo soglasovannosti posle avarii processa na zayavlennoj lokaljnoj granice, a ne universaljnaya garantiya sokhrannosti pri otklyuchenii pitaniya.

Inertnaya modelj predstavleniya vyivoditsya iz prinyatoj pamyati i preobrazuyet dopustimoye namereniye obratno v obyichnuyu programmu sobyitij. Renderer, okno i samostoyateljnaya domennaya istina GUI otsutstvuyut. Poetomu paket podtverzhdayet proiskhozhdeniye budusjhego predstavleniya, no ne zhiznesposobnostj poljzovateljskogo interfejsa, produktovuyu upakovku, realjnuyu modelj ili gotovyij agentskij runtime.

Bezokonnyij cikl dostupen obyichnomu neinteraktivnomu processu:

```bash
./Прототипы/воспроизводимое-пополнение-памяти/запустить.sh fixture
./Прототипы/воспроизводимое-пополнение-памяти/запустить.sh --help
```

Codex mozhet byitj yedinstvennoj inzhenernoj poverkhnostjyu etikh progonov, no ne vkhodit v postavku paketa i ne yavlyayetsya skryitoj zavisimostjyu rezuljtata.

### Drugiye dejstvuyusjhiye prototipyi

[Tenevoj redaktor prodolzhenij](../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md) proveryayet lokaljnoye sopostavleniye chelovecheskogo i modeljnogo prodolzhenij odnogo teksta. [Prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md) otdelyayet fizicheskiye perekhodyi klavish ot avtopovtora i diagnosticheskikh predstavlenij neskoljkikh macOS API. Oba kontura ostayutsya issledovateljskimi: oni ne dokazyivayut gotovnostj vsej FUM, promyishlennuyu upakovku ili zavershyonnuyu modelj bezopasnosti.

## Chto specificirovano, no ne realizovano

### Pervyij produktovyij URL-srez

[Pasport pervogo produktovogo sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) zadayot kontrakt `fum.source-ingest.v1` dlya odnogo publichnogo HTTPS-URL s prostyim HTML-otvetom. [Mashinnaya skhema versii 1](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza/kontrakt-pervogo-URL-sreza-v1.schema.json) razlichayet podgotovku plana, svyazannoye podtverzhdeniye i ispolneniye, zakreplyayet versii soobsjhenij, manifesta, proiskhozhdeniya i stabiljnyikh oshibok.

Kontrakt razdelyon na chetyire kanonicheskiye kartochki:

- [FUM-REQ-0031 — bezopasnyij priyom publichnogo HTML-URL](../Trebovaniya/🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md) zadayot fazovuyu setevuyu modelj i otricateljnuyu matricu;
- [FUM-REQ-0032 — privyazannoye podtverzhdeniye i minimaljnyiye prava](../Trebovaniya/🟡-privyazannoye-podtverzhdeniye-i-minimaljnyiye-prava-priyoma-istochnika.md) svyazyivayet odnorazovoye resheniye poljzovatelya s tochnyim planom, URL, oblastjyu, pravami i politikoj;
- [FUM-REQ-0033 — produktovoye proiskhozhdeniye prinyatogo istochnika](../Trebovaniya/🟡-produktovoye-proiskhozhdeniye-prinyatogo-istochnika.md) vklyuchayet uzkij minimaljnyij sloj `P1` v vertikaljnyij srez;
- [FUM-REQ-0034 — atomarnoye prinyatiye snimka i proiskhozhdeniya](../Trebovaniya/🟡-atomarnoye-prinyatiye-snimka-i-proiskhozhdeniya-istochnika.md) trebuyet odnoj tranzakcionnoj granicyi vidimosti snimka, manifesta, ukazatelya i obyazateljnoj svyazi.

Eti materialyi delayut budusjhuyu realizaciyu odnoznachneye, no sami nichego ne skachivayut, ne ustanavlivayut i ne publikuyut. Postavlyayemogo servisa, yego transporta, produktovogo khranilisjha, crash/restart-priyomki, integracii s yedinyim prilozheniyem i razresheniya na zhivoye setevoye dejstviye eta peresborka ne sozdayot. Susjhestvuyusjhij CLI i atomarnyiye pokoleniya headless-pamyati ostayutsya raznyimi iskhodnyimi obrazcami i ne dokazyivayut produktovyij URL-invariant.

## Perekhod mezhdu stadiyami

[Stadiya dokumentacionnogo prototipa](../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md) imeyet binarnyij checklist i sokhranyayet status **`5 из 6`**. Yedinstvennyij aktivnyij MVP i yego pervyij lokaljnyij reliz prinyatyi, pasport pervogo produktovogo sreza susjhestvuyet, a ogranichennyij bezokonnyij inzhenernyij putj otdeljno razreshyon. Zakryitiye kontraktnyikh zamechanij i otdeljnyij rezuljtat povtornogo audita sami po sebe ne vyipolnyayut poslednij punkt: dlya perekhoda nuzhnyi otdeljnyij vyibor i razresheniye proverennoj produktovoj realizacii.

Inzhenernyij sloj [korobochnoj realizacii FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) uzhe aktiven v forme posledovateljnyikh headless-srezov. Eto ne oznachayet gotovnosti produktovoj stadii. Pervyij poljzovateljskij vyipusk dolzhen statj yedinyim lokaljnyim prilozheniyem, a dejstvuyusjhij paket poka ne realizuyet polnyij produktovyij reyestr proiskhozhdeniya `P1`, sobstvennyij runtime `P7`, yedinoye prilozheniye `P11` ili URL-servis `P3`.

Takim obrazom, korrektnaya granica sejchas vyiglyadit tak: bezokonnyij kontur mozhno prodolzhatj proveryayemyimi inzhenernyimi shagami; URL-kontrakt mozhno ispoljzovatj kak vkhod otdeljnogo vyibora realizacii; ni zakryitiye zamechanij, ni povtornyij audit ne nachinayut produktovyij servis. Produktovaya rabota trebuyet otdeljnogo vyibora i razresheniya, a gotovnostj — ispolnyayemoj priyomki postavlyayemogo komponenta.

## Otkryityiye inzhenernyiye granicyi

- [Razvilka giperseti i sobstvennogo agentskogo cikla](../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md) yesjhyo ne svedena k odnomu produktovomu runtime.
- [Kriterii lokaljnoj LLM i vyidelennoj mashinyi](../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md) trebuyut otdeljnogo pasporta i vosproizvodimogo profilya proverki.
- Renderer i zhiznesposobnyij GUI dolzhnyi byitj vyivedenyi iz prinyatoj pamyati i ispolneniya, a ne dobavlenyi kak nezavisimyij istochnik sostoyaniya.
- URL-servis dolzhen yesjhyo realizovatj setevyiye ogranicheniya, odnorazovoye podtverzhdeniye, minimaljnyij produktovyij reyestr proiskhozhdeniya i obsjhuyu tranzakciyu snimka so svyazjyu.
- Power-loss durability, mnogopoljzovateljskij dostup, udalyonnyiye servisyi, fizicheskiye dejstviya i daljnyaya avtonomiya ne sleduyut iz lokaljnyikh processnyikh proverok i trebuyut sobstvennyikh razreshenij i stendov.

## Kak razrabotchiku nachatj rabotu

Dlya arkhitekturnogo vkhoda polezna cepochka: [obzor proyekta](../Dokumentaciya/00-obzor-proyekta.md) → [modelj pamyati](../Dokumentaciya/01-modelj-pamyati-FUM.md) → [agentskiye ciklyi](../Dokumentaciya/06-obzor-agentskikh-ciklov.md) → [arkhitektura](../Dokumentaciya/22-arkhitektura-FUM.md) → [interfejs uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md).

Dlya nablyudayemoj inzhenernoj realizacii sleduyet otdeljno prochitatj [pasport headless-kontura](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md) i yego [ispolnyayemyij paket](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md). Dlya budusjhego istochnikovogo servisa vkhodom sluzhat doc36, mashinnaya skhema i `FUM-REQ-0031`–`0034`; oni ne yavlyayutsya razresheniyem nachatj realizaciyu vne vyibrannogo planovogo shaga.

Novyij vklad dolzhen sokhranyatj proiskhozhdeniye, otdelyatj vyichisliteljnoye yadro ot effektov, zakreplyatj versii i otkaznyiye rezhimyi i dobavlyatj avtonomnuyu proverku na dostupnoj granice. Eto adresnoye opisaniye ostayotsya proizvodnoj proyekciyej: novyij normativnyij smyisl snachala fiksiruyetsya v zaprose, dokumentacii ili kartochke trebovaniya i toljko zatem popadayet v sleduyusjhuyu polnuyu peresborku.

## Istochniki

- [zakreplyonnyij profilj polnoj peresborki `для-разработчиков-ПО-v2`](Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [pasport dokumentacionnogo prototipa i pervogo produktovogo URL-sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)
- [mashinnaya skhema URL-kontrakta versii 1](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza/kontrakt-pervogo-URL-sreza-v1.schema.json)
- [pasport nachaljnogo korobochnogo prototipa](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)
- [prototip vosproizvodimogo popolneniya pamyati](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)
- [audit pasporta korobochnoj stadii 2026-07-22](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md)
- [stadiya dokumentacionnogo prototipa](../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md)
- [stadiya korobochnoj realizacii](../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md)
- [arkhitektura FUM](../Dokumentaciya/22-arkhitektura-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:815b708b15c74a5795528557514d330eddef004f5825a3acb2ad527970d6ecdc -->
<!-- FUM-MD-RECENCY:END -->
