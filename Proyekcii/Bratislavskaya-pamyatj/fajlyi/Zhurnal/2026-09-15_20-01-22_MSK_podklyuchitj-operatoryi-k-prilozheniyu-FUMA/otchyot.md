# Otchyot 2026-09-15 20:01:22 MSK - Podklyuchitj operatoryi k prilozheniyu FUMA

V prinimayemom prilozhenii FUMA poyavilsya rannij komandnyij vkhod v susjhestvuyusjhij interpretator. On preobrazuyet vkhod i sokhranyayet opredeleniye, tipizirovannyiye dannyiye, rezuljtat i trassu v kontejner nablyudenij togo zhe processa. Povtor vosstanavlivayetsya iz pamyati posle udaleniya iskhodnyikh fajlov. Kod i sborochnyiye vkhodyi prinyatyi celikom iz proverennoj vetki.

## Otvetyi i prinyatyij obyyom

Porucheniye nachatj integraciyu narabotok v osnovnoj rantajm ispolnyayetsya ogranichennoj nastoyasjhej vertikaljyu. Ayo🙂 preobrazuyetsya iz UTF-8 v 12 bajtov UTF-32LE, trassa soderzhit tri pravila. Tekstovaya normalizaciya ostayotsya dopolniteljnyim scenariyem. Kopii interpretatora i dekodera ne sozdavalisj; sobstvennogo IPC mezhdu etimi komponentami net.

Ukazaniye vsegda sozdavatj merge-kommit primenyayetsya k etoj postavke: sokhranyayutsya oba roditelya i istoriya avtora. Sluzhebnyiye konfliktyi svedenyi avtomatizaciyej navigacii i indeksa; doslovnyiye poljzovateljskiye zaprosyi sokhranenyi.

Planirovaniye uzhe vozobnovleno: d1f6e7d2 opublikovan s roditelyami 1eeaeee6 i d76d9d87, udalyonnyij OID proveren kornem. Vladelec prodolzhayet soderzhateljnoye obnovleniye plana i kanonicheskikh pravil; ni eto soobsjheniye, ni checkpoint rantajma ne zamenyayut ikh priyomku.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj  | Granicyi i sposob izmereniya                             |
| ------------------------ | ------------- | ------------------------------------------------------ |
| Svedeniye vetok           | ne izmereno   | Merge, navigaciya i tochnaya granica                       |
| Skvoznoye ispolneniye      | v materialakh  | Dva binarnika posledovateljno, sborka isklyuchena         |
| Adresnyiye proverki       | v tablice nizhe | Monotonnyiye zameryi otchyotnoj obyortki                     |

Granica profilya: priyom tekusjhej vertikali do checkpoint; sborka u avtora sokhranena otdeljnyim svideteljstvom. Vlozhennyiye vremena i stadii ne summiruyutsya povtorno. FIFO, polnyij smoke i peresborka proyekcii ne vyipolnyalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                  | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------ | ------------ | --------- |
| [korenj] Proveritj oba binarnika na obyyedinyonnoj FUMA  | 2,91 s       | uspeshno   |
| [korenj] Podgotovitj nablyudayemyiye polya kommita rantajma | 6,789 s      | uspeshno   |
| [korenj] Proveritj strukturu i diff sliyaniya rantajma   | 23,149 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 32,848 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Oba nastoyasjhikh binarnika proshli odinakovyij rasshirennyij nabor: polozhiteljnyiye vkhodyi, zapresjhyonnyiye i smeshannyiye parametryi razreshenij, povrezhdyonnyiye dannyiye, sokhraneniye nakoplennogo prefiksa, povtor tekstovogo i bajtovogo ispolneniya posle udaleniya fajlov, neizmennostj rezuljtata i novaya identichnostj zapisi. Vvedyonnyij pri obzore bajtovyij replay proveryayet yavno ozhidayemyiye bajtyi i trassu; defekt production-koda ne byil ustanovlen, vyimyishlennyij RED ne zayavlyayetsya.

Nezavisimyij obzor proveril rannij putj do GUI, otsutstviye dublirovaniya ispolneniya, nakopleniye i povtor. Tochnaya Git-sverka vsekh otslezhivayemyikh vkhodov prilozheniya i dvukh bibliotek, vklyuchaya manifestyi i resursyi, pozvolila pereispoljzovatj uzhe sobrannyiye binarniki. Privatnyiye runtime-biblioteki, SDK i toolchain ne attestuyutsya etoj sverkoj. Korenj proveryayet postavku na tekusjhej mashine, ne zayavlyaya novoj vosproizvodimoj sborki vsego prilozheniya.

Resheniye optimizacii: pryamoj vyizov susjhestvuyusjhego ispolnitelya i sokhraneniye v tom zhe processe; povtornaya kompilyaciya neizmennyikh vkhodov ne nuzhna. Profili oboikh binarnikov sokhranenyi s vkhodami i SHA, dopolniteljnoye uskoreniye otnositeljno nesusjhestvuyusjhej predyidusjhej vertikali ne zayavlyayetsya.

Publikacionnaya granica peredana s tochnyim istochnikom: iskhodnyij skaner diagnostiroval toljko dve neizmennyiye stroki test_ustojchivyiye_svideteljstva.py:183 i :199. Korenj uzhe podtverdil te zhe dve stroki na predyidusjhem obyyedinyonnom snimke; prilozheniye, proverka i rukovodstva pobajtovo sovpadayut s istochnikom, sobstvennyiye materialyi prosmotrenyi otdeljno. Novyiye sborochnyiye vkhodyi ne sozdavalisj.

Zaklyuchiteljnyij dopusk snachala otklonil otsutstviye dvukh obyazateljnyikh pryamyikh ssyilok na tekusjhiye zapros i otchyot: odna ssyilka na ikh katalog ne zamenyayet etot kontrakt. Pryamyiye ssyilki vosstanovlenyi; sam dopusk ne izmenyalsya.

## Resheniya i ogranicheniya

Posle durable save oshibka dostavki stdout mozhet zavershitj vyizov kodom 2 pri uzhe sokhranyonnom nablyudenii; otvet mozhet otsutstvovatj ili byitj chastichnyim. Slepoj povtor sposoben dobavitj zapisj. Granica zapisana v rukovodstve; idempotentnaya dostavka kvitancii i inyyekcionnyij test stdout yesjhyo ne realizovanyi.

Eto checkpoint ogranichennoj vertikali, ne priyomka vsego FUMA, vsekh API i master. Proyekciya ostayotsya na perenesyonnom v 34fd25cf pokolenii s nezavershyonnoj nezavisimoj proverkoj; yeyo otstavaniye i status ne skryivayutsya. Posle kommita prodolzhayetsya finansovaya postavka d7259ac2 i priyom postoyannogo planirovaniya.

## Istochniki

- [Iskhodnyij zapros](zapros.md), [predyidusjhij etap](../2026-09-15_19-45-05_MSK_slitj-istoriyu-modeli-v-fuma/otchyot.md).
- [Rukovodstvo](../../Prilozheniya/FUMA/macOS/docs/ispolneniye-operatora.md).
- [Materialyi proverki](materialyi/).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 20:08:55 MSK -->
<!-- content-sha256: sha256:547d76cd32c2bf14fbb6b77d7c630754abbd14dba5c83ebe53033d488f4ec467 -->
<!-- FUM-MD-RECENCY:END -->
