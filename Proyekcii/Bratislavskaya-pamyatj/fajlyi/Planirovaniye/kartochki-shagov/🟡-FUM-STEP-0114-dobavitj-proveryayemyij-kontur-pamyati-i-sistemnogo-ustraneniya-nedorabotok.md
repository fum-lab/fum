+++
schema_version = 1
card_id = "FUM-STEP-0114"
status = "active"
+++
# Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj v dokumentacionnyij prototip FUM yedinyij proveryayemyij kontur, pri kotorom kazhdaya zamechennaya nedorabotka poluchayet kanonicheskuyu [kartochku sboya](../../Glossarij/kartochka-sboya.md) s istochnikom, numerovannyim proyavleniyem, narushennyim ozhidaniyem i mekhanizmom ili riskom povtoreniya. Aktivnaya kartochka dvustoronne svyazyivayetsya s aktualjnyim shagom, ustranyonnaya podtverzhdayet sistemnuyu meru, poglosjhyonnaya peredayot ryad proyavlenij kanonicheskoj kartochke, a snyataya dokazyivayet oproverzheniye nablyudeniya libo neprimenimostj ozhidaniya. Razovaya korrekciya rezuljtata bez meryi protiv povtoreniya ne schitayetsya zakryitiyem.

## Pochemu sejchas

Soderzhateljnyij otvet na neposredstvennyij vopros o susjhnosti FUM ne byil sokhranyon v razdele «Voprosyi i otvetyi», khotya pravila dopustimosti takogo materiala uzhe susjhestvovali. Ispravleniye toljko propusjhennogo materiala zakryivayet yedinichnyij sluchaj, no ne ustranyayet razryiv mezhdu zapisannyim pravilom i yego ispolneniyem. Nuzhen obsjhij kontur, kotoryij ne pozvolyayet zamechennoj nedorabotke ischeznutj iz pamyati do dokazannogo predotvrasjheniya povtoreniya.

## Kriterii zaversheniya

- V `AGENTS.md` nedorabotka opredelena kak nablyudayemoye nesootvetstviye prinyatomu pravilu, trebovaniyu, soglasovannomu povedeniyu ili yavno ispravlennomu poljzovatelem ozhidaniyu i otlichena ot novogo pozhelaniya, nepodtverzhdyonnogo predpolozheniya i otkryitogo voprosa.
- Dlya kazhdoj zamechennoj nedorabotki sokhranyayutsya kartochka sboya, istochnik, neizmenyayemoye numerovannoye proyavleniye, narushennoye ozhidaniye, granica povtoreniya, mekhanizm ili risk povtoreniya i vyibrannyij putj ustraneniya.
- Dlya chetyiryokh statusov proveryayutsya raznyiye iskhodyi: `активна` trebuyet aktualjnuyu vzaimno svyazannuyu kartochku shaga; `устранена` — ustojchivuyu meru i dokazateljstvo protiv kriteriyev zakryitiya; `поглощена` — kanonicheskuyu kartochku, vklyucheniye vsekh iskhodnyikh proyavlenij bez perenumeracii i dopustimyij iskhod celi; `снята` — dokazateljstvo oproverzheniya nablyudeniya libo formaljnoj neprimenimosti ozhidaniya.
- Razovaya ruchnaya korrekciya bez izmeneniya pravila, shablona, avtomatizacii, testa ili drugogo vosproizvodimogo mekhanizma ne perevodit nedorabotku v ustranyonnoye sostoyaniye.
- Proverka svyaznosti rabochej sessii libo otdeljnaya lokaljnaya avtomatizaciya zakryito otklonyayet kartochku s neizvestnyim statusom, povtornyim identifikatorom, otsutstvuyusjhim obyazateljnyim razdelom, povrezhdyonnyim ryadom proyavlenij ili bez dopustimogo dlya yeyo statusa iskhoda.
- Dlya aktivnogo sboya proveryayetsya vzaimnaya ssyilka khotya byi na odnu susjhestvuyusjhuyu aktualjnuyu kartochku shaga. Nachinaya so vtorogo podtverzhdyonnogo proyavleniya, yego tochnyij lokaljnyij nomer obyazan byitj osnovaniyem svyazi v kartochke sboya i istochnikom novoj libo aktualizirovannoj kartochki shaga; neizmenyonnaya obsjhaya ssyilka eto dokazateljstvo ne zamenyayet.
- Kanonicheskaya kartochka vklyuchayet ssyilki na vse proyavleniya tranzitivno poglosjhyonnyikh kartochek pod iskhodnyimi lokaljnyimi nomerami; indeksnyiye znacheniya pervogo nablyudeniya, poslednego nablyudeniya i chisla proyavlenij vyichislyayutsya po ikh obyyedineniyu bez dublikatov i ciklov poglosjheniya.
- Avtonomnyiye fiksturyi pokryivayut [FUM-SBOJ-0001](../../Sboi/FUM-SBOJ-0001-propusk-voprosno-otvetnogo-materiala.md), [FUM-SBOJ-0002](../../Sboi/FUM-SBOJ-0002-samovoljnaya-otmena-ozhidayusjhego-FIFO-bileta.md), [FUM-SBOJ-0003](../../Sboi/FUM-SBOJ-0003-obkhod-HEAD-bootstrap-pri-pervichnom-vkhode-v-FIFO.md), [FUM-SBOJ-0004](../../Sboi/FUM-SBOJ-0004-nevernoye-razresheniye-uglovoj-Markdown-ssyilki-planovyim-reyestrom.md), [FUM-SBOJ-0005](../../Sboi/FUM-SBOJ-0005-interpretaciya-Markdown-ssyilki-vnutri-strochnogo-koda-proverkoj-svyaznosti.md), [FUM-SBOJ-0006](../../Sboi/FUM-SBOJ-0006-opechatka-puti-tekusjhego-zaprosa-pri-uchyote-proverki.md), [FUM-SBOJ-0007](../../Sboi/FUM-SBOJ-0007-propusk-opornoj-datyi-grafa-posle-perekhoda-cherez-polnochj-MSK.md), [FUM-SBOJ-0008](../../Sboi/FUM-SBOJ-0008-pustoj-scenarij-orkestracii-proverki-bez-dochernego-vyizova.md), [FUM-SBOJ-0009](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md), [FUM-SBOJ-0010](../../Sboi/FUM-SBOJ-0010-maskirovka-rannego-otkaza-sostavnoj-shell-diagnostiki.md), [FUM-SBOJ-0011](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md), [FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md), nedorabotku, ustranyonnuyu v toj zhe sessii, poglosjhyonnyij dublikat, povtor posle ustraneniya i vyiskazyivaniye, kotoroye ne yavlyayetsya nablyudayemyim sboyem.
- Sluchaj soderzhateljnogo otveta na pryamoj vopros o FUM proveryayetsya kak regressiya: otsutstviye svyazannoj zapisi v `Вопросы и ответы/` obnaruzhivayetsya, a nalichiye papki zaprosa i voprosno-otvetnogo materiala prokhodit proverku.
- Kontur vklyuchyon v obsjhij smoke-check, rabotayet lokaljno bez seti i sekretov i ne trebuyet semanticheskogo pereoformleniya istoricheskikh sessij do yavno zafiksirovannoj granicyi vvedeniya pravila.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [FUM-SBOJ-0001 — Propusk voprosno-otvetnogo materiala ob FUM](../../Sboi/FUM-SBOJ-0001-propusk-voprosno-otvetnogo-materiala.md)
- [FUM-SBOJ-0002 — Samovoljnaya otmena ozhidayusjhego FIFO-bileta](../../Sboi/FUM-SBOJ-0002-samovoljnaya-otmena-ozhidayusjhego-FIFO-bileta.md)
- [FUM-SBOJ-0003 — Obkhod HEAD-bootstrap pri pervichnom vkhode v FIFO](../../Sboi/FUM-SBOJ-0003-obkhod-HEAD-bootstrap-pri-pervichnom-vkhode-v-FIFO.md)
- [FUM-SBOJ-0004 — Nevernoye razresheniye uglovoj Markdown-ssyilki planovyim reyestrom](../../Sboi/FUM-SBOJ-0004-nevernoye-razresheniye-uglovoj-Markdown-ssyilki-planovyim-reyestrom.md)
- [FUM-SBOJ-0005 — Interpretaciya Markdown-ssyilki vnutri strochnogo koda proverkoj svyaznosti](../../Sboi/FUM-SBOJ-0005-interpretaciya-Markdown-ssyilki-vnutri-strochnogo-koda-proverkoj-svyaznosti.md)
- [FUM-SBOJ-0006 — Opechatka puti tekusjhego zaprosa pri uchyote proverki](../../Sboi/FUM-SBOJ-0006-opechatka-puti-tekusjhego-zaprosa-pri-uchyote-proverki.md)
- [FUM-SBOJ-0007 — Propusk opornoj datyi grafa posle perekhoda cherez polnochj MSK](../../Sboi/FUM-SBOJ-0007-propusk-opornoj-datyi-grafa-posle-perekhoda-cherez-polnochj-MSK.md)
- [FUM-SBOJ-0008 — Pustoj scenarij orkestracii proverki bez dochernego vyizova](../../Sboi/FUM-SBOJ-0008-pustoj-scenarij-orkestracii-proverki-bez-dochernego-vyizova.md)
- [FUM-SBOJ-0009 — Ruchnoye ugadyivaniye lokaljnyikh putej pered vyizovom](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md)
- [FUM-SBOJ-0010 — Maskirovka rannego otkaza sostavnoj shell-diagnostiki](../../Sboi/FUM-SBOJ-0010-maskirovka-rannego-otkaza-sostavnoj-shell-diagnostiki.md)
- [FUM-SBOJ-0011 — Kopirovaniye kriteriyev shagov v kartochki sboyev](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md)
- [FUM-SBOJ-0012 — Pereobesjhannoye adresuyemoye dokazateljstvo proyavleniya](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-03_17-01-51_MSK_zakrepitj-sistemnoye-ustraneniye-nedorabotok/zapros.md)
- [pravila rabochikh sessij](../../AGENTS.md)
- [pravila razdela voprosov i otvetov](<../../Voprosyi i otvetyi/README.md>)
- [audit pokryitiya voprosov i otvetov](../../Instrumentyi/fum-audit-pokryitiya-voprosov-i-otvetov/SKILL.md)
- [proverka svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 01:09:33 MSK -->
<!-- content-sha256: sha256:03f165ee51faeb2fc83561a824ca0235b9cbeae63b1e58f95b2cae2b95908e53 -->
<!-- FUM-MD-RECENCY:END -->
