+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0150"
"статус" = "активна"
+++
# Aktivnaya ssyilka zaprosa vne vklyuchyonnogo pokoleniya

## Nablyudayemyij sboj

Polnyij standartnyij dopusk finansovogo sreza ostanovilsya na shage5 primeneniya proyekcii: aktivnaya Markdown-ssyilka zaprosa vela na `Proyekcii/README.md`, ne vkhodyasjhij vo vklyuchyonnoye pokoleniye. Fakt susjhestvovaniya iskhodnoj celi ne oznachal yeyo dopustimosti vnutri pokoleniya.

## Granica povtoreniya

Aktivnaya lokaljnaya ssyilka iz vklyuchyonnogo iskhodnika razreshayetsya po fajlovoj sisteme, no yeyo celj ne vklyuchena v proveryayemoye pokoleniye. Eto ne0051 s neobyyavlennyimi susjhestvuyusjhimi izmeneniyami, ne0035 s udalyonnyim otsutstvuyusjhim putyom i ne0071 s nepolnoj paroj Zhurnala. Skhodstvo obsjhego instrumenta ne obyyedinyayet eti prichinyi.

## Proyavleniya

### FUM-SBOJ-0150/PROYAVLENIYE-0001

[Iskhodnaya zapisj92221d2e](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/iskhodnaya-zapisj-3_92221d2e-ee5d-44ce-b693-d9becb559f48.json): kod2, 97,160715875 s po obyortke. [Proverennyij zakhvat](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/nablyudeniye-otkaza-3.json) svyazyivayet rawSHA kanalov i tochnoye soobsjheniye o stroke37 zaprosa J6. Posle zamenyi ssyilki obyichnyim tekstom sleduyusjhij polnyij zapusk proshyol etot shag, no otkazal na inoj granice0051; obsjhego uspekha ne byilo.

## Ozhidaniye i klassifikaciya

Podgotovka zaprosa dolzhna vyiyavlyatj nesovmestimostj aktivnoj ssyilki i obyyavlennogo pokoleniya do dorogogo dopuska. Validator praviljno otklonil nedopustimuyu celj; defekt samoj proverki ne ustanovlen. Nedorabotka otnositsya k podgotovke i rannej diagnostike istochnikov.

## Mekhanizm i sistemnoye ustraneniye

Ustanovlennyij mekhanizm otkaza — raskhozhdeniye celi aktivnoj ssyilki s vklyuchyonnyim pokoleniyem. Lokaljnoye sderzhivaniye — ubratj nedopustimuyu aktivnuyu svyazj, sokhraniv neobkhodimyiye svedeniya obyichnyim tekstom. Trebuyetsya rannyaya read-only proverka tem zhe kontraktom pokoleniya s tochnyim istochnikom, strokoj i prichinoj. Novaya realizaciya ne vyipolnena.

## Svyazannyiye shagi

- [FUM-STEP-0231](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0231-proveryatj-ssyilki-otnositeljno-pokoleniya.md) — rannyaya diagnostika po proyavleniyu0001.

## Kriterii zakryitiya

Do zapuska dorogoj proyekcii proveryayemyij mekhanizm vyiyavlyayet aktivnuyu celj vne vklyuchyonnogo pokoleniya i prinimayet dopustimuyu celj. Obyichnyij tekst ne schitayetsya aktivnoj ssyilkoj. Iskhodniki ne perepisyivayutsya proverkoj; izmeneniya vkhoda posle sverki obnaruzhivayutsya. Sistemnaya mera i yeyo adresnyiye dokazateljstva obyazateljnyi, odnogo uspeshnogo ispravlennogo etapa nedostatochno.

## Istochniki

- [Postanovka, naznacheniye ID i granicyi](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/zapros.md).
- [Naznacheniye0150 i0231](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/naznacheniye-0150-i-0231.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 17:48:33 MSK -->
<!-- content-sha256: sha256:f8313cffe8fdbed2efa4a39b58815e80d2c45db4a579bb30a73553f2772d9fad -->
<!-- FUM-MD-RECENCY:END -->
