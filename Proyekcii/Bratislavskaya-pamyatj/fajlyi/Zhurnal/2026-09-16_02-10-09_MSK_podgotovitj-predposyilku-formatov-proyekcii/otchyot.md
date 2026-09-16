# Otchyot 2026-09-16 02:10:09 MSK - Podgotovitj predposyilku formatov proyekcii

Podgotovlena kontroljnaya tochka minimaljnogo prinimayusjhego kontura dlya tochnyikh scenariyev CJS, kornevoj `.mailmap` i perekhoda ot proverennogo pokoleniya M. Iskhodnyiye M/L zakreplenyi; zapisj vedyotsya toljko v sobstvennoj novoj vetke.

## Profilj vremeni vyipolneniya

| Stadiya                       | Dliteljnostj | Granicyi i sposob izmereniya                             |
| ---------------------------- | ------------ | ------------------------------------------------------ |
| Podgotovka kontroljnoj tochki | 1633.159 s   | Ot sokhranyonnogo monotonic_ns dopuska do tekusjhego sreza |
| Pryamyiye zapuski               | sm. nizhe     | Terminaljnyiye mashinnyiye zapisi; vkhodyat v obsjhij interval  |
| Kompaktnyij profilj           | izmeren      | Syiryiye vyiborki i SHA vkhodov v profilj-formatov.json     |
| Polnaya priyomka               | ne nachata    | Izvestnoye iskhodnoye raskhozhdeniye ostatka M               |
| Kontroljnaya tochka            | gotovitsya    | Otkryityij otchyot; itogovoj priyomki net                   |

Granica profilya: izmeren konechnyij podgotoviteljnyij srez. Vremya pryamyikh zapuskov vkhodit v nego i ne summiruyetsya povtorno. Posleduyusjhiye proverki svyaznosti i kommit etoj granicej ne okhvachenyi. FIFO i avtomaticheskiye prodolzheniya ne ispoljzuyutsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                     | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj predposyilki formatov] RED tochnyikh scenarnyikh putej na iskhodnom M                    | 0,233 s      | neuspeshno |
| [Korenj predposyilki formatov] RED tochnoj kartyi avtorov na iskhodnom M                      | 0,359 s      | neuspeshno |
| [Korenj predposyilki formatov] RED vklyucheniya tochnyikh scenariyev v inventarj M                | 0,079 s      | neuspeshno |
| [Korenj predposyilki formatov] GREEN tochnyikh scenariyev i sokhraneniya bajtov                  | 4,791 s      | uspeshno   |
| [Korenj predposyilki formatov] GREEN kartyi avtorov i otkazov sosednim putyam                | 2,699 s      | uspeshno   |
| [Korenj predposyilki formatov] GREEN scenarnogo razbora i inventarya obyyavlenij             | 0,982 s      | uspeshno   |
| [Korenj predposyilki formatov] Zakreplyonnaya kompaktnaya fikstura master                     | 0,344 s      | uspeshno   |
| [Korenj predposyilki formatov] Zakreplyonnaya kompaktnaya fikstura master-izmenyonnoye          | 0,337 s      | uspeshno   |
| [Korenj predposyilki formatov] Zakreplyonnaya kompaktnaya fikstura vedusjhej                    | 0,344 s      | uspeshno   |
| [Korenj predposyilki formatov] RED perekhoda polnogo pokoleniya M k novoj politike           | 0,347 s      | neuspeshno |
| [Korenj predposyilki formatov] GREEN zakreplyonnyikh perekhodov i nastoyasjhikh stadij sliyaniya     | 6,699 s      | uspeshno   |
| [Korenj predposyilki formatov] Profilj konechnogo dopuska i kompaktnogo perekhoda            | 2,949 s      | uspeshno   |
| [Korenj predposyilki formatov] Soglasovannostj skhem i prezhniye otkazyi perekhoda              | 13,395 s     | uspeshno   |
| [Korenj predposyilki formatov] Deshyovyij otkaz tochnogo ostatka pered vyiborom polnoj priyomki  | 4,897 s      | neuspeshno |
| [Korenj predposyilki formatov] Inventarj tekusjhego ostatka dlya lokalizacii otkaza           | 4,666 s      | uspeshno   |
| [Korenj predposyilki formatov] Sravneniye s inventaryom chistogo prinyatogo M                  | 7,522 s      | uspeshno   |
| [Korenj predposyilki formatov] Sokhraneniye prezhnego inventarya i perevoda tryokh yazyikov        | 1,543 s      | uspeshno   |
| [Korenj predposyilki formatov] Sokhraneniye prezhnego konechnogo adaptera i otkazov JavaScript | 0,276 s      | uspeshno   |
| [Korenj predposyilki formatov] Publikacionnaya chistota minimaljnogo paketa                  | 23,794 s     | neuspeshno |
| [Korenj predposyilki formatov] Tochnyiye isklyucheniya raspoznavatelya i otkryitoj fiksturyi CJS    | 0,251 s      | uspeshno   |
| [Korenj predposyilki formatov] Publikacionnaya chistota posle tryokh tochnyikh deklaracij         | 22,749 s     | uspeshno   |
| [Korenj predposyilki formatov] Obnovitj svezhestj dokumentov kontroljnoj tochki              | 1,173 s      | uspeshno   |
| [Korenj predposyilki formatov] Proverka tochnogo diff kontroljnoj tochki                     | 0,053 s      | uspeshno   |
| [Korenj predposyilki formatov] Svezhestj posle utochneniya granicyi profilya i pokoleniya        | 1,165 s      | uspeshno   |
| [Korenj predposyilki formatov] Proverka polnogo indeksa posle ispravleniya konca testa      | 0,025 s      | uspeshno   |
| [Korenj predposyilki formatov] Svezhestj okonchateljnogo otchyota kontroljnoj tochki            | 1,346 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 103,018 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Poluchenyi chetyire ozhidayemyikh RED: neizvestnyiye tochnyiye CJS-puti, neizvestnaya kornevaya `.mailmap`, otkaz ikh obkhoda inventaryom M i otsutstviye priznannogo vladeniya M4365. Posle minimaljnyikh izmenenij proshli 4 scenarnyikh, 3 mailmap, 15 proverok razbora i inventarya, 5 perekhodnyikh i 10 prezhnikh proverok perekhoda, skhem i nastoyasjhego sliyaniya. Vse otkazyi i povtoryi sokhranenyi mashinnyimi zapisyami. Staryij uspeshnyij full PR3 otnositsya k svoyemu derevu D i ne obyyavlyayetsya priyomkoj novoj predposyilki.

## Resheniya i ogranicheniya

- Tekusjhij kontrakt sovpadayet s tochnyim opublikovannyim istochnikom koda L s politikoj `519247e248fca466e3344aaf256e04c7df31c6fdcc41fd5c8ad80858643b34bc`. Dlya vladeniya prezhnim pokoleniyem sokhranyayutsya polnyij M `43652412d709576d3cbda4fa22538a6ad030789f6224315b52c97dfae4e96f3c` i susjhestvuyusjhij polnyij most `9f262153c9de986270cec76ad3c37da34c99ace0c187474ba8a1bc736222220a`.
- Perenosyatsya toljko neobkhodimyiye scenarnyiye chasti inventarya. Massovyij perevod Python/Swift, pereimenovaniye CJS, pozdnij Finder, chuzhiye snimki ostatka i shirokiye overlays isklyuchenyi iz soglasovannogo sostava.
- Politika kandidata privyazana k okonchateljnomu L `14044dfd994cf16b5061fb245b18a8e5abf0ac7d` i yego derevu `d9af1d9e69f288c602a78e5e3edab5337b41ef58`; obyichnaya policy sokhranyayet sobstvennuyu prinyatuyu oblastj.
- Osnovnoye sliyaniye i prodvizheniye master trebuyut predyyavlennogo prinyatogo rezuljtata i otdeljnogo koordinirovannogo okna; etot etap ikh ne vyipolnyayet.

## Izmerennyij profilj i proiskhozhdeniye

[Profilj formatov](materialyi/profilj-formatov.json) svyazyivayet polnyiye vkhodnyiye SHA s iskhodnyimi izmereniyami `perf_counter_ns`. Mediana proverki chetyiryokh scenariyev — 170,684 ms za pyatj povtorov; vladeniye polnyim staryim manifestom — 0,367 ms za dvadcatj povtorov. Na kompaktnom pokolenii perekhod zanyal 893,548 ms, nezavisimaya proverka — 301,788 ms, neizmennyij povtor — 614,584 ms. Eti znacheniya ne yavlyayutsya profilem polnoj repozitorii ili Swift.

Polnyiye kompaktnyiye pokoleniya izgotovlenyi zakreplyonnyimi kodom i kontraktom M/L s fiksirovannyim preobrazovaniyem imeni bez Swift. Test nastoyasjhego Git-sliyaniya podtverdil iskhodnyiye stadii 1=M4365, 2=L5192, 3=M4365, otkloneniye ostavshikhsya konfliktnyikh stadij nezavisimoj proverkoj i sokhraneniye kanonicheskikh bajtov obeikh storon. Povrezhdeniye polya polnogo M-kontrakta, yego otsutstviye i simvolicheskaya ssyilka sokhranyayut staroye pokoleniye. Neizvestnaya politika otklonyayetsya.

Vo vremya pervogo RED perekhoda dva novyikh testovyikh imeni soderzhali tekhnicheskoye slovo master; do GREEN ikh smyislovyiye chasti ispravlenyi na kirillicu. Pervichnaya zapisj RED ne perepisana. Read-only rebyonok otdeljno soobsjhil ob oshibochnom pryamom vyizove kornevogo continuation guard i kode 3; eto ne adresnoye svideteljstvo priyomki i ne podmenyayet zapisi kornevoj obyortki. Daljnejshiye dejstviya rebyonka prekrasjhenyi.

Posle pervoj uspeshnoj svyaznosti indeksnaya proverka vyiyavila lishnyuyu pustuyu stroku v konce novogo mailmap-testa. Predyidusjhij obyornutyij `git diff --check` okhvatyival toljko otslezhivayemuyu rabochuyu raznicu do indeksacii novyikh fajlov. Pryamoj indeksnyij vyizov vyipolnen vne obyortki po oshibke; yego zamechaniye sokhraneno zdesj, a zaklyuchiteljnyij kontrolj polnogo indeksa povtoryon cherez obyortku posle ispravleniya. Smyisl koda i profiljnyiye vkhodyi ne menyalisj. Pervaya svyaznostj ne vyidayotsya za dopusk okonchateljnogo indeksa.

## Ostatok i granica kontroljnoj tochki

Polnaya priyomka, proyekciya i okonchateljnyij PR ne vyipolnenyi. Vyibran obyazateljnyij CLI-profilj `полный`, odnako yego deshyovoye predusloviye otkazalo: sokhranyonnyij snimok ozhidayet 43163 obyyavleniya, chistyij M i predposyilka imeyut po 46914. [Sravneniye](materialyi/iskhodnoye-raskhozhdeniye-ostatka.json) fiksiruyet 0 dobavlennyikh i 0 udalyonnyikh imyon, 28 izmenenij koordinat susjhestvuyusjhikh zapisej. Bazovoye raskhozhdeniye M sostavlyayet 3751 obyyavleniye: 508 Python i 3243 Swift. Snimok ne obnovlyalsya; daljnejshij smyislovoj marshrut ostavlen koordinatoru.

Dopolniteljno proshli 11 prezhnikh testov perevoda i 17 testov konechnogo JS-adaptera, vsego 65 adresnyikh testov. Proverka mashinno-lokaljnyikh putej snachala otvergla dve sintaksicheskiye tiljdyi raspoznavatelya i slyesh otkryitoj regex-fiksturyi. [Tri tochnyiye deklaracii](materialyi/deklaracii-tochnyikh-scenarnyikh-isklyuchenij.json) vzyatyi iz L i primenenyi shtatnyim updater toljko k etim realjnyim strokam; pervichnyij otkaz sokhranyon, posleduyusjhij skaner zavershilsya kodom 0. Politika kandidata ostayotsya tochnyim obyyektom447 ot L14044, yeyo419+28 v proiskhozhdenii sravnivayutsya s prinyatyim M9d01.

Susjhestvuyusjheye pokoleniye `Proyekcii` sokhraneno pobajtno ot M i otstayot ot novyikh kanonicheskikh fajlov. SHA syiryikh bajtov manifesta: `753d2de44df95086d494545ce1164e39dea51ba4406cf7edf5fa0943977d6ac4`; yego politika: `sha256:43652412d709576d3cbda4fa22538a6ad030789f6224315b52c97dfae4e96f3c`. Yego proverennyij iskhodnyij inventarj — `sha256:18bb5a1ecae0a8930c4c8cc1fe5487d7644fc97985599e36c303ca6e545f18d9`. Polnyij progon i zhivaya generaciya ne zapuskalisj. Kontroljnaya tochka ne obyyavlyayetsya integraciyej, dostavkoj osnovnogo sliyaniya ili polnoj priyomkoj.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Naznacheniye i granica](materialyi/naznacheniye-i-granica.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 02:42:44 MSK -->
<!-- content-sha256: sha256:972569cda09a96d7f47e4895d806a7dd2148c90008d370ce4a0f6c1a8bcf03e0 -->
<!-- FUM-MD-RECENCY:END -->
