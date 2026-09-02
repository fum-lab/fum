# Poljzovateljskiye istorii FUM

Razdel poljzovateljskikh istorij FUM perevodit trebovaniya i arkhitekturnyiye resheniya proyekta na yazyik chelovecheskikh scenariyev: kto vzaimodejstvuyet s [FUM](../../Glossarij/FUM.md), chego pyitayetsya dobitjsya, v kakom kontekste dejstvuyet i kakoj nablyudayemyij rezuljtat dolzhen poluchitj. Etot sloj nuzhen, chtobyi budusjhaya [korobochnaya realizaciya FUM](../../Glossarij/korobochnaya-realizaciya-FUM.md), prototipyi, interfejsnyiye resheniya i proverki ne teryali svyazj s zhivyimi zadachami poljzovatelej.

Poljzovateljskaya istoriya v etom razdele ne zamenyayet [iskhodnyij zapros](../../Glossarij/iskhodnyij-zapros.md), [proizvodnuyu dokumentaciyu](../../Glossarij/proizvodnaya-dokumentaciya.md), arkhitekturnoye trebovaniye ili otkryityij vopros. Ona sobirayet ikh v proveryayemyij scenarij primeneniya: rolj poljzovatelya, namereniye, cennostj, usloviya zapuska, ozhidayemoye povedeniye FUM, kriterii priyomki i ssyilki na proiskhozhdeniye trebovanij.

Razdel khranitsya otdeljnoj papkoj vnutri `Документация/`, potomu chto poljzovateljskiye istorii dolzhnyi masshtabirovatjsya kak nabor samostoyateljnyikh materialov. Vkhodnoj fajl zadayot naznacheniye, format i pravila popolneniya; ustojchivyiye scenarii razmesjhayutsya ryadom s nim v otdeljnyikh Markdown-fajlakh.

## Format istorii

Minimaljnaya poljzovateljskaya istoriya FUM fiksiruyet:

- rolj ili tip poljzovatelya;
- celj poljzovatelya v forme nablyudayemogo rezuljtata;
- cennostj rezuljtata dlya poljzovatelya, [FUM-uzla](../../Glossarij/FUM-uzel.md) ili [pamyati FUM](../../Glossarij/pamyatj-FUM.md);
- kontekst i predvariteljnyiye usloviya;
- osnovnoj scenarij vzaimodejstviya;
- vazhnyiye aljternativnyiye khodyi ili otkazyi;
- kriterii priyomki i lokaljnyiye proverki;
- granicyi primenimosti, neceli i razlichiye tekusjhego i celevogo statusov;
- istochniki trebovanij, svyazannyiye dokumentyi, otkryityiye voprosyi i tekusjhij status.

Istoriya dolzhna byitj dostatochno konkretnoj, chtobyi po nej mozhno byilo obsuzhdatj prototip, interfejs ili proverku, no ne dolzhna prezhdevremenno podmenyatj proyektnoye resheniye. Yesli scenarij upirayetsya v neodnoznachnostj trebovanij, takaya neodnoznachnostj vyinositsya v `Вопросы/`, a istoriya ssyilayetsya na sootvetstvuyusjhij otkryityij vopros.

## Indeks istorij

- [Kalendarj, raspisaniye i poyezdki cherez FUM](vesti-kalendari-i-planirovatj-poyezdki.md) - lichnyij FUM-agent pomogayet vesti kalendarj, soglasovyivatj raspisaniye, planirovatj poyezdki, vyizyivatj taksi i sokhranyatj proiskhozhdeniye reshenij.
- [Vesti svyaznuyu pamyatj FUM](vesti-svyaznuyu-pamyatj-FUM.md) - uchastnik sokhranyayet namereniye, istochniki, proizvodnyiye izmeneniya, proverki i prodolzheniye kak vosstanavlivayemuyu prichinnuyu cepochku.
- [Rabotatj s lichnyim FUM-agentom na vyidelennoj mashine](rabotatj-s-lichnyim-FUM-agentom-na-vyidelennoj-mashine.md) - vladelec vyipolnyayet ogranichennuyu rabochuyu sessiyu v upravlyayemom lokaljnom konture s yavnyimi vneshnimi zavisimostyami.
- [Obnovlyatj opisaniya FUM dlya adresatov](obnovlyatj-opisaniya-FUM-dlya-adresatov.md) - uchastnik polnostjyu peresobirayet adresnyij material iz aktualjnoj pamyati bez nepodtverzhdyonnyikh obesjhanij i novogo paralleljnogo istochnika trebovanij.
- [Zapuskatj vosproizvodimuyu avtomatizaciyu FUM](zapuskatj-vosproizvodimuyu-avtomatizaciyu-FUM.md) - poljzovatelj zapuskayet versionirovannuyu proceduru s yavnyimi vkhodami, effektami, proverkami, trassoj i obyyasnimoj granicej vosproizvodimosti.
- [Obmenivatjsya narabotkami mezhdu FUM-uzlami](obmenivatjsya-narabotkami-mezhdu-FUM-uzlami.md) - uzlyi peredayut i prinimayut proveryayemyiye paketyi bez poteri proiskhozhdeniya, urovnej dostupa i prava na otkaz.
- [Gotovitj proveryayemyij srez budusjhej korobochnoj realizacii FUM](gotovitj-proveryayemyij-srez-budusjhej-korobochnoj-realizacii-FUM.md) - inzhener perenosit odin ogranichennyij kontrakt v samostoyateljnyij lokaljnyij kontur i ne vyidayot prototip za gotovyij produkt.

## Granica pervogo nabora

Istorii opisyivayut celevyiye poljzovateljskiye i inzhenernyiye scenarii na osnove uzhe zakreplyonnoj pamyati. Oni otdeljno nazyivayut povedeniye, kotoroye nablyudayetsya v dokumentacionnom prototipe, svojstva dejstvuyusjhikh uzkikh prototipov i yesjhyo ne realizovannyiye chasti budusjhej korobochnoj FUM. Nalichiye istorii ne podtverzhdayet gotovnostj interfejsa, sobstvennogo agentskogo runtime, vneshnego servisa, fizicheskogo dejstviya ili produktovogo reliza.

## Pravila popolneniya

Novaya istoriya dobavlyayetsya toljko vmeste so ssyilkami na istochniki trebovanij i zatronutuyu proizvodnuyu dokumentaciyu. Yesli istoriya osnovana na svezhem poljzovateljskom zaprose, v yeyo istochnikakh ukazyivayetsya `запрос.md` iz sootvetstvuyusjhej papki v `Журнал/`, a sam zapros sokhranyayetsya doslovno po obyichnyim pravilam rabochej sessii.

Kriterii priyomki formuliruyutsya cherez nablyudayemyiye priznaki: sozdannyij fajl, projdennaya proverka, podtverzhdyonnaya navigaciya, vosproizvedyonnaya avtomatizaciya, ponyatnoye sostoyaniye interfejsa ili drugoj proveryayemyij rezuljtat. Razmyityiye formulirovki vrode "poljzovatelyu udobno" dopustimyi toljko posle utochneniya cherez konkretnoye povedeniye.

Povtoryayusjhiyesya formatyi istorij, tablicyi kriteriyev, matricyi rolej ili scenarnyiye proverki rassmatrivayutsya kak kandidatyi na lokaljnuyu avtomatizaciyu FUM: shablon, generator, validator ili mashinno chitayemyij reyestr. Do poyavleniya takoj avtomatizacii tekusjhij razdel ostayotsya chelovekochitayemyim mestom sborki poljzovateljskikh scenariyev.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-28 10:56:30 MSK - Napolnitj poljzovateljskiye istorii FUM](../../Zhurnal/2026-07-28_10-56-30_MSK_napolnitj-poljzovateljskiye-istorii-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-03 08:43:45 MSK - Sozdatj razdel poljzovateljskikh istorij](../../Zhurnal/2026-07-03_08-43-45_MSK_sozdatj-razdel-poljzovateljskikh-istorij/zapros.md)
- [iskhodnyij zapros 2026-07-03 09:03:59 MSK - Opisatj kalendarno transportnyiye dejstviya FUM](../../Zhurnal/2026-07-03_09-03-59_MSK_opisatj-kalendarno-transportnyiye-dejstviya-FUM/zapros.md)

## Opornyiye dokumentyi

- [Obzor proyekta](../00-obzor-proyekta.md)
- [Modelj pamyati FUM](../01-modelj-pamyati-FUM.md)
- [Arkhitektura FUM](../22-arkhitektura-FUM.md)
- [Interfejs FUM-uzla](../25-interfejs-FUM-uzla.md)
- [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:79226f36d12f178b39a2342337e758180664ea069dae818aaec773a79bc2e444 -->
<!-- FUM-MD-RECENCY:END -->
