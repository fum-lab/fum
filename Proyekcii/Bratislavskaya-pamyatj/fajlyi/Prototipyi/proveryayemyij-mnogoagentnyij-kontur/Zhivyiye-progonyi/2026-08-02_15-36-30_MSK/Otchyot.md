# Zhivoj raspredelyonnyij progon Codex i peredacha novoj sessii

Progon zavershilsya iskhodom `goal_met`: dva vneshnikh ispolnitelya Codex razdeljno po nablyudayemoj granice rabochikh paketov otvetili na odin vopros k lokaljnoj pamyati FUM, otdeljnyij proveryayusjhij pokomponentno podtverdil vse 11 opublikovannyikh utverzhdenij, a korenj prinyal rezuljtat po dokazateljstvam bez golosovaniya. Raskhozhdenij, otklonyonnyikh utverzhdenij i neustranyonnyikh konfliktov ne obnaruzheno. Polnyij mashinochitayemyij paket sokhranyon v odnom podtverzhdyonnom adresuyemom pokolenii, kotoroye kanonicheski vosproizvoditsya iz `CURRENT`.

Otdeljnaya novaya kornevaya sessiya Codex ispolnila sokhranyonnyij paket FUM-STEP-0083 i opublikovala pokoleniye-preyemnik `sha256:e759453e8f7cf12b3ddf735f20ffba7b374fe413c5046943ee40799e04661b9a` poverkh tochnogo roditelya `sha256:c9c721deb92d3a2552af273a7304c66de99abc6f9637c7a6564733a0b0c8c089`. Eto mashinno proveryayemaya strukturnaya attestaciya odnogo perenosa po sokhranyonnoj pamyati. Ona ne dokazyivayet nedostupnyij nablyudeniyu fakt otsutstviya skryitogo chteniya prezhnego chata ili inyikh nesokhranyonnyikh kanalov i ne obobsjhayetsya na gotovuyu dolgovremennuyu pamyatj libo vnutrennij mnogoagentnyij runtime FUM.

Polozhiteljnyij iskhod iskhodnogo progona otnositsya toljko k rabote Codex kak vneshnikh ispolnitelej lokaljnogo stenda. On ne dokazyivayet nezavisimostj modelej, kriptograficheskuyu podlinnostj rolej, istinnostj vkladov, raspredelyonnyij konsensus ili sokhrannostj posle poteri pitaniya.

## Vopros i organizaciya progona

Rabochij vopros byil sformulirovan tak: «Kakiye utverzhdeniya o vosstanovlenii raspredelyonnogo epizoda FUM podtverzhdenyi tekusjhej lokaljnoj pamyatjyu, kakiye ispolnyayemo proverenyi i chto ostayotsya nedokazannyim?»

Do zapuska kazhdyij paket proshyol ispolnyayemyij preflight FUM-STEP-0075. Proizvoditeli poluchili raznyiye roli i neperesekayusjhiyesya pervichnyiye vkhodyi; rezuljtatyi drug druga im ne raskryivalisj do publikacii oboikh vkladov. Proveryayusjhij byil zapusjhen toljko posle etogo i poluchil oba vklada vmeste s chetyirjmya pervichnyimi fajlami i dvumya avtonomnyimi komandami proverki.

| Rolj                 | Publichnyij ispolnitelj             | Pervichnyiye vkhodyi                                                                                                    | Preflight |
| -------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------- |
| Normativnyij analitik | `codex.worker.normative.v1`        | dokument 49 i trebovaniye o proveryayemom mnogoagentnom konture                                                       | `ready`   |
| Ispolnyayemyij auditor  | `codex.worker.executable.v1`       | pasport prototipa i `DistributedEpisodeAcceptance.swift`                                                          | `ready`   |
| Proveryayusjhij          | `codex.verifier.repository.v1`     | dva opublikovannyikh vklada, chetyire pervichnyikh istochnika, `acceptance all` i polnyij SwiftPM test-suite                | `ready`   |
| Selektor i arkhivist  | `codex.root.selector.v1`           | opublikovannyiye vkladyi, proverka, nablyudayemoye proiskhozhdeniye, resheniye, terminaljnyij iskhod i paket sleduyusjhej sessii   | korenj    |

Skryitoye rassuzhdeniye ispolnitelej, soobsjheniya orkestratora i nepublichnyiye identifikatoryi dochernikh zadach ne obyyavlenyi obsjhej pamyatjyu i ne sokhranyalisj. Sokhranenyi publichnyiye roli, identifikatoryi rabochikh paketov, tochnyiye SHA-256 vkhodov i rezuljtatov i kornevaya identichnostj sessii.

## Vkladyi i otdeljnaya proverka

Normativnyij analitik sformuliroval pyatj utverzhdenij o kanonicheskom vosstanovlenii, neizmenyayemom sokhranenii raznoglasij, ispolnyayemoj priyomke i granice dokazannogo. Ispolnyayemyij auditor sformuliroval shestj utverzhdenij o realizacii kontrakta, pobajtovom vozobnovlenii, tochnoj granice perezapuska, otkaze lozhnomu konsensusu, zakryitom otkaze na byudzhete i fiksturnoj oblasti priyomki.

Proveryayusjhij sopostavil kazhdyij `claim_id` s nazvannyim fajlom i tochnyim diapazonom strok. Vse 11 ocenok poluchili `passed`; `failed` i `inconclusive` otsutstvuyut. Dve svezhiye komandyi dali nablyudayemyiye rezuljtatyi:

| Komanda                                                                                         | Iskhod    | Nablyudayemaya dliteljnostj | Proverennaya granica                                                                                               |
| ----------------------------------------------------------------------------------------------- | -------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `./Прототипы/проверяемый-многоагентный-контур/запустить.sh acceptance all --repo-root .`        | `passed` | 30,002 s                 | chetyire zapisannyikh scenariya, vklyuchaya `goal_met`, lozhnyij konsensus, byudzhet i ozhidaniye podtverzhdeniya                 |
| `swift test --package-path Прототипы/проверяемый-многоагентный-контур`                           | `passed` | 185,718 s                | 80 nablyudavshikhsya na moment proverki XCTest-testov bez otkazov; novyiye testyi arkhivatora dobavlenyi posle etoj sverki |

Soglasiye dvukh vkladov ne ispoljzovalosj kak dokazateljstvo. Resheniye `accepted` vyibralo toljko 11 proshedshikh proverku utverzhdenij, ne otklonilo ni odnogo i sokhranilo pustoj spisok raznoglasij.

## Nablyudayemaya korrelyaciya i otricateljnyiye rezuljtatyi

Oba proizvoditelya rabotali cherez odnu poverkhnostj collaboration v odnoj kornevoj sessii Codex, byili zapusjhenyi bez otdeljnogo model override i chitali odnu iskhodnuyu vershinu obsjhego checkout. Eti tri osnovaniya sokhranenyi kak gruppyi korrelyacii. Razlichiye rolej, paketov i pervichnyikh vkhodov i zapret prezhdevremennogo obmena rezuljtatami nablyudalisj, no tochnaya aktivnaya modelj sredoj ne raskryita, poetomu semanticheskaya nezavisimostj ne schitayetsya dokazannoj.

Proverka yavno sokhranila otricateljnyiye rezuljtatyi:

- zhivoj mnogomodeljnyij runtime, zhivyiye modeljnyiye provajderyi i instrumentyi, setj i udalyonnaya koordinaciya ne proveryalisj;
- kriptograficheskaya podlinnostj rolej, semanticheskaya nezavisimostj proizvoditelej, istinnostj vkladov i dostovernostj telemetrii nedoverennogo adaptera ne dokazanyi;
- lokaljnyij uspekh ne dokazyivayet power-loss durability, raspredelyonnyij konsensus ili gotovuyu dolgovremennuyu pamyatj FUM;
- chetyiryokhscenarnaya acceptance-komanda ne zamenyayet otdeljnyiye regressii staging-ukazatelya i orphan-pokoleniya;
- dva zapuska Swift Testing soobsjhili nolj obyyavlennyikh testov; nablyudayemoye pokryitiye toj proverki obespechili XCTest-naboryi iz 22 i 58 testov.

## Podtverzhdyonnaya cepochka pokolenij

Ispolnyayemyij arkhiv perechital 15 perechislennyikh artefaktov cherez descriptor-walk s zapretom simvolicheskikh ssyilok i neogranichenno blokiruyusjhikh fajlov, sveril ikh SHA-256, chetyire paryi rabochikh paketov i preflight, proiskhozhdeniye, korrelyacii, smyislovuyu soglasovannostj vkladov, proverki, resheniya i terminaljnogo iskhoda i vstroil tochnyiye bajtyi vmeste s kanonicheskim zaprosom. Syiroj JSON kazhdogo artefakta prokhodit rekursivnuyu zakryituyu skhemu s zapretom povtornyikh klyuchej i leksicheski drobnyikh znachenij v celochislennyikh polyakh. Pervoye domennoye pokoleniye profilya `fum.live-distributed-run-generation.v1` poluchilo adres `sha256:c9c721deb92d3a2552af273a7304c66de99abc6f9637c7a6564733a0b0c8c089`. Vstroyennyij zapros imeyet SHA-256 `sha256:683093d7ab94f5def071b28cec7bc3955237e4d329572595c1f1f066de6fee38`.

Kazhdyij sokhranyonnyij preflight svyazan s tochnyimi bajtami svoyego paketa i obyazan imetj `ready` bez narushenij. Arkhivator svezho povtoryayet analiz paketa FUM-STEP-0083 po yego obyazateljnyim vkhodam; zavershivshiyesya paketyi proizvoditelej i proveryayusjhego ne pereschityivayutsya po izmenivshemusya posle ikh publikacii checkout. Poetomu sokhranyonnyiye otchyotyi fiksiruyut zayavlennuyu i nablyudavshuyusya kornem posledovateljnostj v granicakh stenda, no ne yavlyayutsya kriptograficheskim dokazateljstvom vremeni zapuska ili otsutstviya skryitogo obmena.

Do vozobnovleniya povtornaya komanda `live show` poluchila sostoyaniye `replayed`, adres pervogo pokoleniya, 15 artefaktov, resheniye `accepted`, iskhod `goal_met` i kartochku peredachi FUM-STEP-0083. SHA-256 fajla pokoleniya sovpal s togdashnim adresom `CURRENT`, a izvlechyonnyij iz otchyota obyyekt pokoleniya pobajtovo sovpal s sokhranyonnyim kanonicheskim fajlom. Poslednyaya izolirovannaya peresborka i yeyo povtornoye chteniye vmeste zanyali 3,354 s s uchyotom dvukh zapuskov probnika; otdeljnoye chteniye ustanovlennogo togda `CURRENT` zanyalo 1,542 s.

Arkhivnyij zapros takzhe prokhodit otdeljnuyu kanonizaciyu zakryitoj skhemyi. Pokoleniye sokhranyayet eti kanonicheskiye bajtyi v Base64, poetomu `request_sha256` pereschityivayetsya posle vosstanovleniya, a ne ostayotsya neproveryayemoj deklaraciyej. Vozobnovleniye s `run_id = fum.live-distributed-codex.2026-08-02.resume-once.v1` sformirovalo zakryityij 16-artefaktnyij profilj s yedinstvennyim `handoff_result`, semjyu `input_checks` so statusom `passed` i terminaljnyim iskhodom `goal_met`. Novyij [`memory/CURRENT.json`](memory/CURRENT.json) ukazyivayet na `sha256:e759453e8f7cf12b3ddf735f20ffba7b374fe413c5046943ee40799e04661b9a`, a pokoleniye nazyivayet tochnyim roditelem `sha256:c9c721deb92d3a2552af273a7304c66de99abc6f9637c7a6564733a0b0c8c089`. Dva posledovateljnyikh rezuljtata `live show` dlya novoj vershinyi pobajtovo sovpali i povtorno podtverdili vsyu cepochku predkov. Popyitka publikacii poverkh povrezhdyonnoj cepochki po-prezhnemu zakryivayetsya otkazom do izmeneniya `CURRENT`.

## Ispolneniye peredachi FUM-STEP-0083

Rabochij paket [`рабочие-пакеты/FUM-STEP-0083.json`](rabochiye-paketyi/FUM-STEP-0083.json) imeyet identifikator `fum.live-run.2026-08-02.resume-once.v1`, SHA-256 `sha256:384c7a950a25bab9c18b1f2fafd381f144e93b3dbd85aafce492d0f6b87ab62b` i rezuljtat preflight `ready` bez narushenij. Novaya kornevaya sessiya `019fc38d-a1ac-7ba3-869c-54fc348626fd` ispolnila yego tak:

1. Nachala s `CURRENT`, proverila adres i kanonicheskiye bajtyi pokoleniya-roditelya.
2. Sverila vse semj obyazateljnyikh vkhodov s paketom i vstroyennyimi kopiyami; kazhdyij `input_check` poluchil `passed`.
3. Sokhranila tipizirovannyij `handoff_result`, svyazyivayusjhij tochnogo roditelya, prezhnyuyu kartochku, identifikator i SHA-256 paketa, novuyu kornevuyu sessiyu, terminaljnyij iskhod i `outcome = completed`.
4. Opublikovala rovno odno pokoleniye-preyemnik s 16 artefaktami i yedinstvennyim `handoff_result`, vklyuchyonnyim v terminaljnyiye svideteljstva.
5. Dvazhdyi vyipolnila `live show`; oba vyivoda sovpali pobajtovo, nazvali odnu vershinu i podtverdili polnuyu cepochku.

Paket, yego preflight i rezuljtat ispolneniya vstroyenyi v podtverzhdyonnuyu cepochku. Nablyudayemyiye artefaktyi pokazyivayut, chto novaya sessiya poluchila dostatochnyij mashinochitayemyij vkhod iz pamyati i vyipolnila predusmotrennyiye proverki. Eto utverzhdeniye ogranicheno strukturoj sokhranyonnyikh dannyikh i rezuljtatami ispolnyayemogo povtornogo chteniya: stend ne mozhet dokazatj otsutstviye skryitogo chteniya otchyota, prezhnego chata ili soobsjhenij ispolnitelej.

## Istochniki i proiskhozhdeniye

- [Iskhodnyij zapros sessii](../../../../Zhurnal/2026-08-02_15-36-30_MSK_provesti-zhivoj-raspredelyonnyij-progon-Codex-i-sokhranitj-peredachu/zapros.md)
- [Iskhodnyij zapros o vozobnovlenii raspredelyonnogo progona](../../../../Zhurnal/2026-08-02_21-01-15_MSK_vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta/zapros.md)
- [FUM-STEP-0082](../../../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0082-provesti-zhivoj-raspredelyonnyij-progon-Codex-i-sokhranitj-peredachu.md)
- [FUM-STEP-0083](../../../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0083-vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta.md)
- [Kontrakt vosstanavlivayemoj obsjhej pamyati](../../../../Dokumentaciya/49-kontrakt-vosstanavlivayemoj-obsjhej-pamyati-raspredelyonnogo-epizoda.md)
- [Pasport prototipa](../../README.md)
- Kornevaya sessiya iskhodnogo progona Codex: `019fc270-541d-7fa1-b6fd-78f0a25f2425`.
- Kornevaya sessiya vozobnovleniya Codex: `019fc38d-a1ac-7ba3-869c-54fc348626fd`.


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e6e13a7896709f90402addb66f04705101b0587a02bec30e4bcdad5333868d82 -->
<!-- FUM-MD-RECENCY:END -->
