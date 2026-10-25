# Otchyot 2026-09-19 06:20:43 MSK - Prinyatj podgotovku proverok i kommita

Prodolzhayetsya komanda «Prodolzhaj drugiye rabotyi.». Dva posledovateljnyikh uluchsheniya sokhranenyi v fuma: b4df957bbb344ac5e9f945c92f192323faf07170 i 8304cb5f612d1dc681c548cf1ba80bdea4c6e722. Dlya oboikh proverenyi tochnyij obyyekt, soobsjheniye, roditeli, derevo, identichnosti, chistyij checkout i udalyonnyij OID. D22 ostayotsya na pauze. Tekusjhij etap sobirayet obsjhuyu priyomku etikh izmenenij, ne yavlyayetsya novyim soobsjheniyem cheloveka i ne obyyavlyayet zavershyonnyimi ostaljnyiye obyazateljstva FUMA.

Pervyij pomosjhnik bezopasno gotovit sluzhebnyij blok novogo otchyota vnutri nastoyasjhego uchtyonnogo zapuska. Vtoroj pozvolyayet povtorno podgotovitj soobsjheniye i konechnyij sostav bez perepisyivaniya istorii modeli, kogda svezhij JSONL ne dobavil nablyudenij. Sokhranenyi otkazyi po povrezhdeniyu, propuskam i smene nablyudenij. Obyyedinyonnyij srez ne menyayet importyor i finaljnyiye trebovaniya prinyatiya.

## Svideteljstvo realjnogo povtornogo primeneniya

V J33 novyij rezhim primenyon k nastoyasjhemu istochniku tekusjhej zadachi: importyor prochital 1 064 454 793 bajta, podtverdil polnotu i nolj novyikh nablyudenij; SHA sokhranyonnoj istorii ne izmenilsya. Po novoj podgotovke sozdan tot zhe proverennyij snimok bez povtoreniya obyazateljnyikh proverok. Eto nablyudeniye ogranicheno etim zapuskom; ne yavlyayetsya obsjhej ekonomiyej tokenov ili izmereniyem doli nedeljnogo limita. Privatnaya sverka sokhranyayet polnyij rezuljtat vne publichnogo checkout.

Po API vo vremya J33 ispoljzovano 94% nedeljnogo limita akkaunta; ostatok 6%. Eto sovokupnoye ispoljzovaniye, a ne stoimostj dannoj rabotyi. Resursoyomkij testovyij kontur ispoljzuyetsya dlya itogovoj priyomki. Pervaya popyitka otkazala po nepolnomu sostavu etapa; povtor dopuskayetsya posle ispravleniya opisannogo nizhe propuska.

## Otkaz pervoj priyomki i ispravleniye sostava

Pervaya standartnaya popyitka zavershilasj otkazom na shage 12 posle 11 uspeshnyikh shagov za 585,350 s. Sborsjhik zakonomerno obnovil v planovom reyestre otpechatok kartochki FUM-STEP-0174, izmenyonnoj v J32. YA ne perechislil etot proizvodnyij fajl v sostave tekusjhego zaprosa, poetomu svyaznostj otklonila yego kak neozhidannyij putj. Otkaz sokhranyon v mashinnoj istorii; prinyatiye ne sostoyalosj. V zapros dobavlen tochnyij putj reyestra, yego yedinstvennyij izmenyonnyij otpechatok sveryon s kartochkoj. Pered povtornoj polnoj popyitkoj vyipolnyayetsya adresnaya proverka svyaznosti, chtobyi obnaruzhitj takoj propusk do dorogoj proyekcii.

Pri podgotovke adresnoj sverki oshibochno vyibran diagnosticheskij klass bez klyuchej polnyikh naborov; obyortka otklonila komandu do sozdaniya zapisi i zapuska proverki. Dlya proverki ispravlennogo soderzhimogo vyibran adresnyij klass. Eto otkaz podgotovki, a ne dopolniteljnyij rezuljtat testov.

Adresnaya sverka zatem obnaruzhila ustarevshiye recency-metki: poyasneniye otkaza byilo dopisano vo vremya zapuska. Eto moya oshibka poryadka operacij. Poyasneniya zavershayutsya do obnovleniya metok i povtornoj proverki; vo vremya neyo kanonicheskoye soderzhimoye ne izmenyayetsya.

## Sverka dokumentacii

Opisaniye otchyotnoj obyortki soderzhit komandu pervogo zapuska i granicu aktivnogo predprosmotra. Rukovodstvo sozdaniya kommita opisyivayet otdeljnyij povtornyij rezhim, prezhnij v2-vkhod, svezhuyu sverku i usloviya otkaza. Kornevoj poljzovateljskij scenarij FUM ne izmenilsya, poetomu README ne perepisyivayetsya. Avtomaticheskoye sozdaniye kommita finaljnogo rezhima po-prezhnemu ne podderzhano: itog fiksiruyetsya susjhestvuyusjhim protokolom posle zakryitiya i proverki proyekcii.

## Profilj vremeni vyipolneniya

| Stadiya                      | Dliteljnostj | Granicyi i sposob izmereniya                         |
| --------------------------- | ------------ | -------------------------------------------------- |
| Podgotovka itogovogo snimka | ne izmereno  | Zhurnal i sokhraneniye proiskhozhdeniya do proverok      |
| Standartnaya priyomka         | ne izmereno  | Fakticheskaya dliteljnostj fiksiruyetsya obyortkoj nizhe |

Granica profilya: adresnaya podgotovka i standartnyiye popyitki otrazhayutsya otdeljnyimi pryamyimi vyizovami; finaljnoye zamyikaniye proyekcii vyipolnyayetsya posle zakryitiya vne mashinnoj granicyi po dejstvuyusjhemu pravilu. Kalendarnoye vremya razrabotki zadnim chislom ne vosstanavlivayetsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:946009834913cb5469f3b4eb240da255004a8c9a1bf34c4d0010fecdbf3d4f49 -->

| Vyizov                                                      | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------- | ------------ | --------- |
| [korenj] Pervaya proverka polej priyomki J34                 | 1,577 s      | uspeshno   |
| [korenj] Standartnaya priyomka podgotovki proverok i kommita | 585,42 s     | neuspeshno |
| [korenj] Sveritj ispravlennyij sostav etapa J34             | 24,647 s     | neuspeshno |
| [korenj] Proveritj stabiljnyij ispravlennyij sostav J34      | 24,964 s     | uspeshno   |
| [korenj] Standartnaya priyomka ispravlennogo sostava J34     | 1561,73 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2198,338 s.

Priyomochnyiye raundyi: gotov.
Kontekst Git-snimka: sha256:01f743defe8b7703a279fa5b8561aacf14be233aed1893f69ac8a6ed8d696904.
Kontekst soderzhimogo: sha256:8a75830bb968cccc16572e350aa23570ffce45908f936167ba0b51e37c46528c.
Polnyikh popyitok: 2; uspeshnyikh: 1.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: vyipolneno.
Usloviye «snimok sovpadayet»: vyipolneno.
Usloviye «soderzhimoye sovpadayet»: vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Resheniya i ogranicheniya

Do uspeshnogo zamyikaniya sokhranyayetsya status nezavershyonnoj priyomki. Posledneye prinyatoye pokoleniye do etogo etapa otnositsya k J30, 22522716d237a5837d12c46040cd6d2896f21766. Gotovnostj opredelyayetsya fakticheskim itogom mashinnoj istorii, zakryitiyem i nezavisimyim manifestom, a ne planom ili prezhnimi zelyonyimi testami.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Podgotovka pervoj proverki](../2026-09-19_05-52-59_MSK_podgotovitj-pervuyu-proverku-polej/otchyot.md).
- [Povtornaya podgotovka kommita](../2026-09-19_06-08-46_MSK_sokhranyatj-istoriyu-pri-povtornoj-podgotovke/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 06:41:05 MSK -->
<!-- content-sha256: sha256:96c15c1dc6100e2172808a03c8cc98ad13cfc3d02b8a126baa1c586cf6c95a62 -->
<!-- FUM-MD-RECENCY:END -->
