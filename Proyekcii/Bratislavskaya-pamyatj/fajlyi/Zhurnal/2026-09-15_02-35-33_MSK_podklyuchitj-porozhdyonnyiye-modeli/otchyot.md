# Otchyot 2026-09-15 02:35:33 MSK - Podklyuchitj porozhdyonnyiye modeli

Porozhdyonnyiye modeli podklyuchenyi yavnyim profilem k nastoyasjhemu CLI i adapteru kyesha. Prezhnij profilj ostayotsya znacheniyem po umolchaniyu. Funkcionaljnyiye adresnyiye proverki proshli; iskhod standartnoj finaljnoj priyomki fiksiruyetsya v upravlyayemom bloke nizhe. Obsjhiye modeli, kontrakt i generator ne izmenenyi.

## Profilj vremeni vyipolneniya

| Stadiya                        | Dliteljnostj       | Granicyi i sposob izmereniya                                 |
| ----------------------------- | ------------------ | ---------------------------------------------------------- |
| Analiz i podgotovka           | ne izmereno        | Chteniye iskhodnikov, postanovki i pozdnikh utochnenij          |
| Iskhodnyij cikl shesti chtenij    | 466.551 ms         | Mediana semi ciklov, nastoyasjhij CLI i disk, API simulirovan |
| Pervoye podklyucheniye modelej    | 616.349 ms         | Ta zhe smesj; pervonachaljnyij byudzhet prevyishen                |
| Itogovyij prezhnij profilj      | 464.664 ms         | Semj ciklov, mezhprofiljnaya sverka SHA vne izmereniya        |
| Itogovyij porozhdyonnyij profilj  | 574.528 ms         | Semj ciklov; cena postroyeniya i proverki modelej vklyuchena   |
| Standartnaya finaljnaya priyomka | sm. pryamyiye zapuski | 24 shaga, itog i dliteljnostj v upravlyayemom bloke           |

Granica profilya: etap nachat 2026-09-15 02:35:33 MSK. Pryamyiye proverochnyiye processyi uchityivayutsya nizhe; vremena ciklov yavlyayutsya vlozhennyimi pokazatelyami i k nim ne pribavlyayutsya. Chteniye, podgotovka i publikaciya otdeljno ne izmerenyi. FIFO i avtomaticheskoj peredachi net.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:388b5ab44ea8487c0e1582e7136c654edde53a0248b7fb98e879e09bea240c19 -->

| Vyizov                                                                                                           | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj optimizacii konteksta] Izmeritj iskhodnyij realjnyij CLI i kyesh do podklyucheniya modelej                      | 3,391 s      | uspeshno   |
| [Korenj optimizacii konteksta] RED: proveritj yavnyij CLI-profilj i prezhnyuyu sovmestimostj                         | 1,855 s      | neuspeshno |
| [Korenj optimizacii konteksta] RED: proveritj vyibor profilya na prinyatom kyeshe                                    | 0,262 s      | neuspeshno |
| [Korenj optimizacii konteksta] GREEN: proveritj oba CLI-profilya i tochnyij byudzhet s putyom i LF                    | 0,494 s      | uspeshno   |
| [Korenj optimizacii konteksta] GREEN: proveritj prezhnyuyu sovmestimostj i strogiye granicyi profilya CLI             | 2,221 s      | uspeshno   |
| [Korenj optimizacii konteksta] GREEN: proveritj Node-adapter, kyesh, SHA i arifmetiku profilya                     | 1,514 s      | uspeshno   |
| [Korenj optimizacii konteksta] Izmeritj prezhnij profilj realjnogo CLI i kyesha posle podklyucheniya                  | 3,381 s      | uspeshno   |
| [Korenj optimizacii konteksta] Izmeritj porozhdyonnyij profilj realjnogo CLI i kyesha posle podklyucheniya              | 4,362 s      | uspeshno   |
| [Korenj optimizacii konteksta] Lokalizovatj nakladnyiye raskhodyi: prezhnij CLI s cProfile                           | 0,068 s      | uspeshno   |
| [Korenj optimizacii konteksta] Lokalizovatj nakladnyiye raskhodyi: porozhdyonnyij CLI s cProfile                       | 0,089 s      | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj semantiku i byudzhet posle ustraneniya lishnego importa                    | 2,462 s      | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj stoimostj posle ustraneniya lishnego importa: prezhnij                    | 3,34 s       | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj stoimostj posle ustraneniya lishnego importa: porozhdyonnyij                | 4,025 s      | uspeshno   |
| [Korenj optimizacii konteksta] Zakrepitj mezhprofiljnyiye SHA rezuljtatov i vremya: prezhnij                         | 3,42 s       | uspeshno   |
| [Korenj optimizacii konteksta] Zakrepitj mezhprofiljnyiye SHA rezuljtatov i vremya: porozhdyonnyij                     | 4,204 s      | uspeshno   |
| [Korenj optimizacii konteksta] Primenitj yavnyij porozhdyonnyij profilj k raneye prinyatomu nativnomu snimku           | 0,108 s      | uspeshno   |
| [Korenj optimizacii konteksta] Sveritj SHA rezuljtatov, vkhodyi i vse serii s iskhodnyim byudzhetom                   | 0,036 s      | uspeshno   |
| [Korenj optimizacii konteksta] Sveritj sobstvennyiye imena pyati izmenyonnyikh iskhodnikov                             | 0,343 s      | neuspeshno |
| [Korenj optimizacii konteksta] Proveritj Node-scenarii posle parametrizacii otkryitoj oshibki                     | 1,494 s      | uspeshno   |
| [Korenj optimizacii konteksta] Sveritj imena posle uprosjheniya fabriki nativnogo otveta                           | 0,455 s      | neuspeshno |
| [Korenj optimizacii konteksta] Podtverditj nulevoj ostatok pyati iskhodnikov i tochnoye pereimenovaniye polya profilya | 0,432 s      | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj registraciyu 0045/0004, sokhraneniye prezhnikh proyavlenij i reyestr          | 0,45 s       | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj tochnyij indeks pered standartnoj priyomkoj CLI-profilya                   | 0,028 s      | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj svyaznostj i pervichnyiye komandyi pered standartnoj priyomkoj               | 43,65 s      | neuspeshno |
| [Korenj optimizacii konteksta] Proveritj svyaznostj shtatnyim rezhimom vnutri otchyotnoj obyortki                      | 43,969 s     | uspeshno   |
| [Korenj optimizacii konteksta] Proveritj okonchateljnyij indeks s zaregistrirovannoj granicej vyizova              | 0,03 s       | uspeshno   |
| [Korenj optimizacii konteksta] Prinyatj yavnyij CLI-profilj standartnyim finaljnyim konturom                         | 1004,077 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1130,16 s.

Ekonomnyij poryadok proverok: gotov.
Otdeljnaya diagnosticheskaya proverka: 1,514 s; rezuljtat: uspeshno; naboryi: adapter-otveta-i-svodka-profilya-node; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 1,494 s; rezuljtat: uspeshno; naboryi: adapter-otveta-i-svodka-profilya-node; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

RED d454805d: 19 primerov nastoyasjhego CLI otkazali iz-za otsutstviya yavnogo flaga. RED 81056aee: sokhranyonnyij strogij profilj fakticheski proignorirovan i vernul prezhnij uspekh. Oba iskhodnyikh otkaza sokhranenyi. Posle realizacii otdeljnyiye adresnyiye proverki CLI podtverdili tochnyij UTF-8+LF-byudzhet s putyom N/N−1 i granicyi profilya. Poslednyaya proverka posle ustraneniya lishnego importa takzhe sveryayet prezhnij stdout s neizmenyonnyim etalonom vo vsekh 19 sluchayakh. Polnyij Node-nabor vne standartnogo Python-kontura proshyol 12 testov: realjnyij CLI, SHA, novyij i sokhranyonnyij rezhimyi, tochnyij byudzhet, otkaz bez porchi prinyatogo kyesha, rannyaya validaciya profilya i arifmetika svodki.

V obsjhej oblasti rezuljtatyi prezhnego i porozhdyonnogo CLI ravnyi pobajtno. Vne neyo prezhnij uspekh sokhranyon, a strogij profilj yavno otkazyivayet s konkretnoj prichinoj i pustyim stdout: Int64 i drobi v oshibke i opuskayemom elemente, glubina 64/65, kanonicheski sovpadayusjhiye klyuchi, UUID i vneshniye BOM/UTF-16/UTF-32. Polnyiye snimki ne menyayutsya. Uzhe susjhestvuyusjhiye polozhiteljnyiye cache/SHA-scenarii ispoljzovanyi bez sozdaniya dublikatov.

[Primeneniye prinyatogo snimka](materialyi/primeneniye-prinyatogo-snimka.json): realjnyij adapter i CLI s yavnyim porozhdyonnyim profilem perechitali prezhnij nativnyij snimok SHA `60977d36dd50e329055f342d5f92ec7d60c82654560512f6000aa531cb32696d`; 885 → 2595 bajtov, rezuljtat raven prezhnemu prinyatomu. Vyipolnen odin CLI, novyikh API i zapisej polnogo fajla net; zapisj kyesha podtverzhdena zanovo. Svezhestj zhivogo sostoyaniya ne utverzhdayetsya.

[Sravneniye profilej](materialyi/sravneniye-profilej.json) proveryayet vse semj serij: odinakovyiye iskhodnyiye SHA, bajtyi, chislo fajlov i vyizovov. Poslednyaya para zakrepila 42 ravnyikh SHA rezuljtata, isklyuchiv lishj izmenyayemyij privatnyij putj. [Kriterij](materialyi/kriterij-profilya.json) zadan do zamerov; yego porog ne povyishalsya.

[Adresnaya sverka imyon](materialyi/imena-podklyucheniya.json) podtverdila 0 → 0 dlya pyati konechnyikh ispolnyayemyikh iskhodnikov. Otkazyi 18 i 20 sokhranenyi: snachala dva prisvaivaniya vneshnikh polej v teste, zatem sobstvennoye smeshannoye imya metadannyikh. Fabrika otkryitogo otveta parametrizovana; vse 12 Node-testov povtorno proshli. [Yedinstvennaya zamena imeni polya](materialyi/pereimenovaniye-polya-profilya.json) svyazala SHA dvukh poslednikh izmerenij s tekusjhim profilem: menyayetsya toljko imya posle izmeryayemoj granicyi; znacheniye, intervalyi i vyizyivayemyij runtime neizmennyi, zameryi radi imeni ne povtoryayutsya.

[Sboj 0045/0004](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md) i [kvitanciya registracii](materialyi/kvitanciya-registracii-0045.json) sokhranyayut novoye proyavleniye, prezhniye 0001–0003 i dvustoronniye svyazi s 0165/0173. Koordinator yavno prinyal raskryituyu granicu proizvoditeljnosti dlya zaversheniya funkcionaljnogo sreza; budusjhaya optimizaciya malyikh sluzhebnyikh otvetov k tekusjhej priyomke ne dobavlyayetsya.

[Sboj 0134](../../Sboi/FUM-SBOJ-0134-kontroljnaya-tochka-vnutri-obyortki.md) sokhranyayet oshibochnyij vyibor checkpoint-rezhima vnutri aktivnoj obyortki: zapisj 24, kod 1, 43.649792917 s. Obyichnyij rezhim proshyol na tom zhe otpechatke v zapisi 25 za 43.969157125 s. [Nablyudeniye](materialyi/nablyudeniye-rezhima-svyaznosti.json) podtverzhdayet neizmennostj proveryayusjhikh iskhodnikov; [kvitanciya registracii](materialyi/kvitanciya-registracii-0134.json) svyazyivayet novyij aktivnyij sboj s 0174. Kod proverki ne menyalsya, pervonachaljnyij otkaz ne podmenyon.

## Resheniya i ogranicheniya

Obyichnyij CLI i adapter po umolchaniyu ispoljzuyut prezhneye predstavleniye. `--профиль порождённый` i `профиль_представления` yavno vyibirayut obsjhij zakryityij profilj. Neizvestnyij profilj adapter otklonyayet do rabotyi s kyeshem i instrumentami. Avtomaticheskogo vozvrata k prezhnemu predstavleniyu net. Novyij neprinyatyij snimok posle otkaza ostayotsya neprinyatyim; smena profilya bez API obesjhana toljko dlya uzhe prinyatogo snimka.

Profilj vyiyavil lishnij import prezhnego modulya v porozhdyonnoj vetvi. [Diagnostika](materialyi/diagnostika-importa.json) sokhranila otdeljnuyu cenu importa modelej i postroyeniya dataclass; vlozhennyiye intervalyi ne summiruyutsya. Importyi raznesenyi po vetvyam. Posle izmeneniya odna seriya proshla vesj inzhenernyij byudzhet, poslednyaya — toljko cikl i tri iz chetyiryokh grupp: krupnoye sokhranyonnoye chteniye 83.964 ms pri predele 82.019 ms. Ustojchivoye soblyudeniye vsego byudzheta i uskoreniye ne zayavlyayutsya. Porozhdyonnyij rezhim funkcionaljno dostupen kak yavnyij vyibor i dorozhe prezhnego. Daljnejsheye izmeneniye obsjhego generatora ne opravdano etim ogranichennyim izmereniyem i ne vyipolneno.

Oba dochernikh recenzenta rabotali toljko chteniyem. Zamechaniye o pobajtnoj proverke prezhnego stdout uchteno; posle nego adresnyij test povtoryon. Dopolneniye SHA semantiki v profile potrebovalo poslednej paryi izmerenij dlya ustraneniya konkretnogo probela sopostavimosti. Syiryiye nativnyiye dannyiye, pstats i JSONL ostayutsya privatnyimi.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Proiskhozhdeniye prodolzheniya](materialyi/proiskhozhdeniye-prodolzheniya.json).
- [Postanovka podklyucheniya](materialyi/postanovka-podklyucheniya.json).
- [Kvitanciya predyidusjhej priyomki](../2026-09-15_02-26-52_MSK_podtverditj-dostavku-sovmestnoj-priyomki/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 03:22:57 MSK -->
<!-- content-sha256: sha256:7bd4272680bd1f1253b79a7915bd1f0cf7377a672e324dbdcd08d417e5042acd -->
<!-- FUM-MD-RECENCY:END -->
