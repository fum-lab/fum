# [Otkryityij vopros](../Glossarij/otkryityij-vopros.md): razvilka giperseti i agentskogo cikla [FUM](../Glossarij/FUM.md)

Ekspluatacionnyij status: dejstvuyusjhaya zapisj repozitoriya vyipolnyayetsya vruchnuyu zapuskayemyimi posledovateljnyimi sessiyami. Opisannaya nizhe avtomaticheski vozobnovlyayemaya svyazka Git + Codex s continuation, FIFO, handoff i selector sokhranyayet svideteljstvo prezhnego povedencheskogo prototipa, no ne yavlyayetsya tekusjhim marshrutom rabotyi.

Vopros chastichno proyasnyon. Blizhajshij dejstvuyusjhij prototip [FUM](../Glossarij/FUM.md) mozhno vesti po dvum raznyim trayektoriyam, i oni proveryayut raznyiye svojstva proyekta.

Pervyij putj - byistreye razvernutj prototip [nejronnoj giperseti FUM](../Glossarij/nejronnaya-gipersetj-FUM.md) na tekusjhej Git-infrastrukture, Codex i lokaljnoj [pamyati FUM](../Glossarij/pamyatj-FUM.md). Takoj putj dayot uzhe dejstvuyusjhij kontur trebovanij, dokumentov, zaprosov, zhurnalov, proverok, kommitov i poshagovogo otbora. Yego risk v tom, chto sobstvennyij [agentskij cikl](../Glossarij/agentskij-cikl.md) FUM ostayotsya ne polnostjyu dostupnyim: vneshnij cikl Codex vedyot rabotu, a FUM poka nasleduyet yego cherez pravila repozitoriya, a ne ispolnyayet sobstvennyij vlozhennyij cikl.

Vtoroj putj - nachinatj s realizacii minimaljnogo agentskogo cikla. On blizhe k arkhitekturnomu yadru FUM, potomu chto pozvolyayet yavno upravlyatj nablyudeniyem, vyiborom dejstviya, modeljnyim shagom, proverkoj, ostanovkoj i zapisjyu trassyi. Yego risk v tom, chto dlya vlozheniya ciklov drug v druga nuzhen upravlyayemyij chistyij modeljnyij shag: lokaljnaya LLM, proveryayemaya zaglushka ili rezhim `Codex CLI`, gde on rabotayet kak prostoj LLM-provajder, a ne kak samostoyateljnyij agentskij cikl.

## Neodnoznachnostj

Tekusjhij Git- i Codex-kontur uzhe dayot povedencheskij prototip avtomaticheski vozobnovlyayemoj rabotyi na masshtabe diskretnyikh zadach. Neyasnostj teperj prokhodit po granice dostatochnosti etogo svideteljstva dlya daljnejshej [korobochnoj realizacii FUM](../Glossarij/korobochnaya-realizaciya-FUM.md): kakiye svojstva podtverzhdenyi vneshnej orkestraciyej, a kakiye trebuyut sobstvennogo runtime i sobyitijnogo vkhoda.

Prototip na Git + Codex byistreye pokazyivayet gipersetevuyu prirodu FUM: pamyatj razvivayetsya, zaprosyi svyazyivayutsya, proizvodnaya dokumentaciya utochnyayetsya, lokaljnyiye avtomatizacii proveryayut rezuljtat, a Git fiksiruyet nasledovaniye izmenenij. No takoj prototip mozhet podtverditj toljko vneshnyuyu organizaciyu pamyati i otbora, yesli ne otdelitj sloj FUM ot upravlyayusjhego agentskogo cikla Codex.

Prototip sobstvennogo cikla luchshe proveryayet rekursivnostj i vozmozhnostj vlozheniya ciklov: odin cikl mozhet vyizvatj, ogranichitj, nablyudatj ili ocenitj drugoj. No dlya etogo neljzya polagatjsya na neprozrachnyij vneshnij agentskij runtime kak na modeljnyij shag. Nuzhno ponyatj, dostupna li chistaya LLM lokaljno, dostatochno li ona kachestvenna dlya zadach FUM, ili mozhno ispoljzovatj `Codex CLI` strogo v rezhime LLM-provajdera bez delegirovaniya yemu vsego cikla.

## Voprosyi dlya proyasneniya

- Kakiye tochnyiye granicyi imeyet svideteljstvo Git + Codex kak povedencheskogo prototipa gipersetevoj FUM i kakiye yego svojstva neljzya perenositj na sobstvennyij runtime?
- Kak budusjhij realjnyij provajder dolzhen podtverditj sovmestimostj s kontraktom chistogo modeljnogo shaga: identichnostj modeli, parametryi generacii, predel vremeni, otmenu i otsutstviye skryityikh dejstvij?
- Mozhno li ispoljzovatj `Codex CLI` kak prostoj LLM-provajder bez peredachi yemu vsego agentskogo cikla, i kak eto proveritj lokaljno bez setevyikh sekretov v testakh?
- Yesli nuzhen lokaljnyij LLM-provajder, kakiye minimaljnyiye trebovaniya k kachestvu, kontekstu, skorosti i stoimosti dostatochnyi dlya pervogo ogranichennogo cikla?
- Kak sravnivatj dva puti na odnoj fiksture: gipersetevoj prototip na Git + Codex i minimaljnyij runtime cikla s chistyim modeljnyim shagom?
- Mozhet li pervyij etap prinyatj promezhutochnuyu formu: trassirovsjhik cikla s modeljnoj zaglushkoj, poka realjnyij LLM-provajder vyibirayetsya otdeljno?

## Prakticheskaya ramka

Posle ocenki vyibora arkhitekturnogo podkhoda planirovaniye dolzhno razlichatj tri urovnya rezuljtata:

- gipersetevoj prototip na tekusjhej infrastrukture, kotoryij dokazyivayet svyaznostj pamyati, proiskhozhdeniye, Git-nasledovaniye i poshagovyij otbor;
- specifikaciyu i fiksturu agentskogo cikla, kotoryiye dokazyivayut format trassyi, ostanovku, oshibki i proveryayemostj bez obyazateljnogo realjnogo LLM-provajdera;
- runtime agentskogo cikla s chistyim modeljnyim shagom, kotoryij toljko posle otdeljnoj proverki mozhet ispoljzovatj lokaljnuyu LLM ili `Codex CLI` kak provajdera.

## Chastichnoye proyasneniye

[Ocenka vyibora arkhitekturnogo podkhoda k realizacii FUM](../Zhurnal/2026-07-10_05-03-09_MSK_sravnitj-variantyi-realizacii/materialyi/ocenki/ocenka-vyibora-arkhitekturnogo-podkhoda-k-realizacii-FUM.md) utochnyayet poryadok realizacii. Pervyim shagom vyibirayetsya repozitornyij gipersetevoj kontur na tekusjhej Git/Codex/lokaljnoj pamyati, potomu chto on uzhe podtverzhdyon kodom lokaljnyikh avtomatizacij, proverkami, pravilami sessii i Git-nasledovaniyem. Minimaljnyij trassirovsjhik agentskogo cikla stanovitsya sleduyusjhim proveryayemyim artefaktom, a yedinoye lokaljnoye prilozheniye - boleye pozdnim integratorom korobochnoj stadii.

Tekusjhaya granica teperj sformulirovana tochneye: preobladayusjhij smyislovoj sloj nyineshnej [pamyati FUM](../Glossarij/pamyatj-FUM.md) sostoit iz doslovnogo teksta cheloveka i proizvodnogo teksta LLM, porozhdayemogo vo vneshnej agentskoj sessii Codex. Tem samyim dokumentacionnyij prototip dokazyivayet sovmestno formiruyemuyu tekstovuyu pamyatj i yeyo vneshnyuyu organizaciyu, a ne sobstvennyij runtime cikla FUM.

Tekusjhij Git + Codex-kontur s branch-scoped FIFO, obyazateljnyim sozdaniyem prodolzheniya do kommita, atomarnoj peredachej vetki i pryamyim vyiborom [sleduyusjhego shaga vetki](../Glossarij/sleduyusjhij-shag-vetki.md) proyasnyayet yesjhyo odnu granicu. On uzhe yavlyayetsya povedencheskim prototipom prodolzhayemogo cikla na masshtabe diskretnyikh zadach, a ne toljko formoj odnoj rabochej sessii. Poljzovateljskaya zadacha mozhet izmenitj pamyatj, trebovaniya, ogranicheniya i vyibor sleduyusjhego shaga, poetomu menyayet posleduyusjhuyu nablyudayemuyu trayektoriyu rabotyi. Pri etom ona ne vyitesnyayet nemedlenno uzhe dopusjhennogo vladeljca FIFO, vneshnij runtime Codex ne stanovitsya sobstvennyim runtime FUM, a nablyudayemaya trayektoriya ne vklyuchayet skryityiye rassuzhdeniya modeli. Prezhnij pyatiminutnyij heartbeat-dispetcher yavlyayetsya istoricheskoj realizaciyej i boljshe ne vkhodit v dejstvuyusjheye svideteljstvo etogo kontura.

[Tenevoj redaktor prodolzhenij](../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md) dobavlyayet vtoroye chastichnoye svideteljstvo: lokaljnaya LLM uzhe proverena kak chistyij ogranichennyij subprocess-shag, kotoryij poluchayet toljko tekstovyij kontekst cherez standartnyij vvod, ne imeyet instrumentov i vozvrasjhayet prodolzheniye v nablyudayemyij poljzovateljskij kontur. Eto snimayet vopros o principialjnoj dostupnosti lokaljnogo modeljnogo shaga dlya uzkoj tekstovoj fiksturyi, no sam redaktor ne realizuyet polnyij cikl nablyudeniya, vyibora dejstviya, podtverzhdeniya, proverki i obnovleniya pamyati.

[Kontrakt chistogo modeljnogo shaga](../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md) versii `1` i [determinirovannyij Swift-prototip](../Prototipyi/chistyij-modeljnyij-shag/README.md) proyasnyayut obsjhij interfejs: vesj kontekst peredayotsya yavno, provajder ne poluchayet effektnyikh vozmozhnostej, rezuljtat ostayotsya inertnyim tekstom, a identichnostj, limityi, khyesh vkhoda i oshibki nablyudayemyi. Eto dokazyivayet granicu na zaglushke, no ne kachestvo realjnoj LLM i ne nalichiye u `Codex CLI` rezhima bez sobstvennogo agentskogo cikla.

[Zapros o nachaljnom korobochnom prototipe](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) vyibirayet sleduyusjhij sobstvennyij Swift-kontur posle Git-giperseti: snachala bezokonnoye vosproizvodimoye popolneniye pamyati, zatem postepennoye vnutrenneye ispolneniye i toljko posle etogo GUI, vyivedennyij iz tekh zhe mekhanizmov. Eto snimayet neopredelyonnostj blizhajshego inzhenernogo napravleniya, no yesjhyo ne dokazyivayet polnyij agentskij runtime, realjnogo LLM-provajdera ili kriterij zhiznesposobnogo GUI.

[Utochneniye o nachaljnoj korobochnoj stadii](../Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md) rasshiryayet eto resheniye s pervogo bootstrap na posledovateljnostj rannikh inzhenernyikh srezov: sobstvennyij GUI FUM ne yavlyayetsya barjyerom ikh zapuska, analiza i testirovaniya, a vneshnyaya sessiya Codex mozhet ostavatjsya yedinstvennoj rabochej poverkhnostjyu. Tem samyim byistryij putj Git + Codex yavno prinyat dlya vsej nachaljnoj inzhenernoj chasti stadii. Eto ne otvechayet na voprosyi o sobstvennom runtime, sobyitijnom vkhode vo vremya aktivnoj rabotyi, realjnom LLM-provajdere ili poljzovateljskoj postavke, poetomu razvilka ostayotsya chastichno proyasnyonnoj.

Vopros ne zakryivayetsya polnostjyu. Ostayotsya realizovatj sobstvennyij runtime cikla, proveritj nablyudeniye razreshyonnogo poljzovateljskogo vvoda na urovne sobyitij vo vremya aktivnoj rabotyi i yego primeneniye na bezopasnoj kontroljnoj tochke, a takzhe proveritj realjnyij LLM-provajder po obsjhemu kontraktu. Dopolniteljno nuzhno opredelitj mesto otdeljnogo modeljnogo vyizova v trasse i runtime, podtverditj otmenu i tajm-aut vneshnego processa i ustanovitj granicu, posle kotoroj uzkij lokaljnyij provajder stanovitsya dostatochnyim dlya vlozheniya ciklov.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-07-10 05:03:09 MSK - Sravnitj variantyi realizacii](../Zhurnal/2026-07-10_05-03-09_MSK_sravnitj-variantyi-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla](../Zhurnal/2026-07-03_15-36-48_MSK_utochnitj-razvilku-giperseti-i-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-14 00:36:30 MSK - Utochnitj tekstovyij sostav pamyati dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-14_00-36-30_MSK_utochnitj-tekstovyij-sostav-pamyati-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij](../Zhurnal/2026-07-14_08-54-56_MSK_sozdatj-prototip-raskhozhdeniya-prodolzhenij/zapros.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK - Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK - Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:10:35 MSK - Razreshitj nachaljnuyu korobochnuyu FUM bez GUI cherez Codex](../Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)

## Zatronutaya dokumentaciya

- [Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md](2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md)
- [Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md](../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md](../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md)
- [Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md](../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:51:31 MSK -->
<!-- content-sha256: sha256:1aeaaee56d19b3013d7f07d7ff9ad5beaa9d31e20875006f67c9eaaac349e2f5 -->
<!-- FUM-MD-RECENCY:END -->
