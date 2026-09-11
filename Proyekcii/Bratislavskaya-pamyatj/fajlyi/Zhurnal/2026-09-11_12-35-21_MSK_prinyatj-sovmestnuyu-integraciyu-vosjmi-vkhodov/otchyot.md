# Otchyot 2026-09-11 12:35:21 MSK - Prinyatj sovmestnuyu integraciyu vosjmi vkhodov

Vosjmoj vkhod shablonov `acab107170a4a1243b76cba4f25b0b408e735603` obyyedinyon s semjyu prinyatyimi vkhodami v rabochem dereve ot `d649d565d4b8542ca1e332e09f5ca095a4958f80`. Etot etap gotovit sobstvennuyu obsjhuyu priyomku, zakryityij nabor svideteljstv i vosproizvodimyij kandidat dlya peredachi yedinstvennomu pisatelyu fuma. Uspekh i dliteljnosti proverok opredelyayutsya mashinnyimi zapisyami nizhe; publikaciya i fakticheskaya peredacha zakreplyayutsya sleduyusjhim etapom.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Komanda vosjmogo sliyaniya | 0.226922625 s | Monotonnyiye granicyi, vozvrat 1 s tremya konfliktami |
| Razresheniye kanonicheskikh konfliktov | 50.901735667 s | Ot vozvrata merge do razresheniya; vklyuchayet chteniye i sopostavleniye |
| Predyidusjhiye sliyaniya, indeksyi, kommityi i dostavka | v materiale izmerenij | Otdeljnyiye iskhodnyiye intervalyi bez summirovaniya vlozhennyikh rabot |
| Adresnyiye proverki i polnyij standartnyij smoke-check | po tablice nizhe | Shtatnaya obyortka i vlozhennyiye nablyudeniya polnogo zapuska |
| Finaljnaya proyekciya posle zakryitiya i peredacha | sleduyusjhij etap | Fakticheskiye granicyi sokhranyayutsya posle vyipolneniya |

Granica profilya: podgotovka vosjmogo vkhoda i obsjhej priyomki, vklyuchaya predyidusjhiye izmerennyiye etapyi v materiale. CPU/RSS otdeljnogo merge dostupnyi v chastnoj zapisi; fizicheskij I/O i otdeljnaya stoimostj nablyudeniya ne izmerenyi. Ozhidaniye prinyatogo vkhoda 0201 peresekalosj s poleznoj podgotovkoj i ne schitayetsya chistyim prostoyem. Tyazhyoloye okno soglasovano s koordinatorom; otdeljnyij benchmark zavershilsya do obsjhej priyomki.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:45ee2af1407d4d77a246a4d8c3ff1db5aff9730f9958d6eed972d7e881940a53 -->

| Vyizov                                                                          | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------ | ------------ | --------- |
| [Integrator postavok] Sobratj sovmestnyij planovyij reyestr                       | 0,516 s      | uspeshno   |
| [Integrator postavok] Obnovitj svezhestj sovmestnogo kanona                     | 1,264 s      | uspeshno   |
| [Integrator postavok] Sovmestno prinyatj vosemj obyyedinyonnyikh vkhodov             | 25,125 s     | neuspeshno |
| [Integrator postavok] Proveritj voprosyi posle udaleniya povtornoj ssyilki        | 6,567 s      | uspeshno   |
| [Integrator postavok] Obnovitj svezhestj ispravlennogo indeksa voprosov         | 1,303 s      | uspeshno   |
| [Integrator postavok] Prinyatj vosemj vkhodov posle ispravleniya indeksa voprosov | 432,581 s    | neuspeshno |
| [Integrator postavok] Proveritj politiku posle snyatiya ustarevshikh isklyuchenij    | 23,397 s     | uspeshno   |
| [Integrator postavok] Obnovitj svezhestj posle utochneniya politiki               | 2,227 s      | uspeshno   |
| [Integrator postavok] Proveritj svyaznostj podgotovlennogo obsjhego kandidata     | 49,611 s     | neuspeshno |
| [Integrator postavok] Obnovitj svezhestj opisaniya udalenij proyekcii             | 1,19 s       | uspeshno   |
| [Integrator postavok] Proveritj svyaznostj s tochnyimi udaleniyami proyekcii        | 58,193 s     | uspeshno   |
| [Integrator postavok] Prinyatj obsjhij kanon posle utochneniya politiki i svyaznosti | 1332,087 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1934,061 s.

Priyomochnyiye raundyi: gotov.
Kontekst Git-snimka: sha256:f75d4de3ef36c97a63dcd988debcb05028ae02e863a4372b461853c148939f48.
Kontekst soderzhimogo: sha256:bf7e977d766b20a68d77ace24a464393a61258df2d13cd6ec178f750e49317b9.
Polnyikh popyitok: 3; uspeshnyikh: 1.
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

## Proverki

Sovmestnyij standartnyij dokumentacionnyij smoke-check soderzhit 24 shaga, vklyuchaya trinadcatj razreshyonnyikh naborov. Klass obyortki «polnaya» otnositsya k etomu sostavnomu zapusku. Adresnyiye proverki okhvatyivayut izmenyonnyiye sovmestnyiye granicyi; raneye prinyatyiye neizmenyonnyiye Swift-fajlyi, arkhivyi i sobstvennyiye naboryi ne trebuyut novyikh optimizacij ili novyikh benchmark. Posle zakryitiya vyipolnyayetsya shtatnaya finaljnaya proyekciya i nezavisimaya proverka manifesta po obyyedinyonnomu kontraktu.

## Resheniya i ogranicheniya

Adresnaya svyaznostj posle postroyeniya proyekcii vyiyavila dva ozhidayemyikh udaleniya yeyo staryikh kartochek 0176 i 0177, ne perechislennyikh zaprosom. V kanonicheskom sloye zavershyonnyiye kartochki uzhe sokhranenyi predyidusjhimi vkhodami. Zapros dopolnen tochnyimi udalyonnyimi proizvodnyimi putyami; dopolniteljnogo izmeneniya kartochek ili generatora ne trebuyetsya. Otkaz proverki sokhranyon v istorii.

Vtoroj full `c805d599-17d0-4676-b222-561334e3455a` zavershilsya za 433.809469250 s na kontrakte schyotchika politiki putej. Postroyeniye obsjhej proyekcii proshlo za 269.453 s, nezavisimyij manifest — za 113.861 s. Sliyaniye politik sokhranilo dva uzhe nenuzhnyikh isklyucheniya staroj linii 0201 dlya strok Git hooks avtonomnyikh fikstur, togda kak prinyatyij 0177 uzhe ispoljzuyet `os.devnull` i ne soderzhit prezhnikh literalov. Eti dva tochnyikh isklyucheniya snimayutsya shtatnyim manifestom; susjhestvuyusjheye `definition-051` pereschityivayetsya bez izmeneniya kak obyazateljnaya deklaraciya komandyi. Novyikh razreshenij ne dobavlyayetsya, ostavshiyesya 419 zapisej sokhranyayutsya. Posleduyusjhaya adresnaya proverka i novyij full proveryayut ispravlennuyu politiku.

Pervyij sovmestnyij full `4398f116-4f8c-4fdb-9660-7117998f5480` zavershilsya otkazom na chetvyortom shage: odin otkryityij matematicheskij vopros byil povtoryon v indekse voprosov. Pervyiye tri shaga proshli, proyekciya i testovyiye naboryi yesjhyo ne zapuskalisj. Udalena toljko vtoraya odinakovaya ssyilka; soderzhaniye voprosa i yego status sokhranenyi. Otkaz ostayotsya v istorii v4, povtornaya priyomka svyazyivayetsya s novyim UUID i ispravlennyim soderzhimyim.

Vosjmoj merge imel toljko tri kanonicheskikh konflikta: navigaciya iskhodnogo zaprosa, indeks Zhurnala i indeks svezhesti. Zasjhisjhyonnyiye tekstyi iskhodnogo zaprosa pobajtovo sovpali u oboikh roditelej. Ispolnyayemyiye fajlyi obyyedinenyi avtomaticheski. Nezavisimyij analiz podtverdil sokhraneniye `Callable`, `start_session`, `подготовить_начало` i parametra ustanovki iz FUMA; rannyaya proverka ustanovlennyikh tipov sootvetstvuyet prinyatomu acab. Proverka dvunapravlennosti voprosov prisutstvuyet odin raz pered proyekciyej v oboikh profilyakh. Istoricheskij plan ustanovki shablona sokhranyon kak svideteljstvo, ne primenyalsya.

Celoye prezhneye pokoleniye Proyekcii vosstanovleno iz pervogo roditelya do shtatnoj obsjhej generacii. Ono ne podmenyayet kanonicheskiye iskhodniki. Kontrakt proyekcii sokhranyayet obyyedineniye formatov prilozheniya, konechnogo JS-adaptera, neobyazateljnogo grafa i prezhnej sovmestimosti. Vse prinyatyiye zakryityiye zhurnalyi i snimki sokhranyayutsya; sobstvennaya novaya istoriya ispoljzuyet v4.

Sedjmoj kommit `d649d565d4b8542ca1e332e09f5ca095a4958f80`, derevo `f9c8fa08ec6bb6751954c886fbf8faa9b04d8326`, roditeli `[48d6c42f49e2c5a033d314eb4dc26ddddd0f0086, f49eeee3fd80a87cd63391d6606dafa19cd6d2b8]` proshyol svyaznostj i dostavlen: udalyonnyij OID sovpal. Yego diff-check vernul 2 toljko iz-za 48 preduprezhdenij iskhodnogo probeljnogo oformleniya: 8 v HTML Unicode, 21 i 19 v dvukh `.patch.txt`-etalonakh. Vse 23 fajla prototipa i arkhiva pobajtovo sverenyi s f49; iskhodnyiye bajtyi sokhranenyi.

Pervyij vyizov starta tekusjhego Zhurnala peredal chelovekochitayemuyu datu vmesto metki iz stem i byil otklonyon do zapisi. Povtor peredal tochnuyu metku. Pri podgotovke navigacii pervyij chastnyij obkhod neverno prinyal klyuchi slovarya `_canonical_requests` za puti i ostanovilsya do navigacionnyikh zapisej; povtor ispoljzoval `canonical_request_path` i zasjhisjhyonnuyu tranzakciyu. Eti oshibki podgotovki ne skryivayutsya i ne obyyavlyayutsya uspeshnyimi proverkami.

V plane vosjmoj vkhod, sovmestnyij dopusk i peredacha ostayutsya dostupnyimi do fakticheskikh svideteljstv. Predvariteljno svyazannyij UUID polnogo zapuska i khyeshi rezuljtatov ne oznachayut uspekha do poyavleniya prinyatogo kommita. Posle realjnogo prinyatiya i peredachi novyij etap zavershit zapisi plana, sokhranyaya zakryityij nabor C. Vetka fuma i master zdesj ne izmenyayutsya; daljnejshij dopusk master otdeljnyij i podchinyayetsya pravilam yego zakreplyonnogo istochnika.

## Istochniki

- [Zapros etapa](zapros.md).
- [Sobstvennyij plan](materialyi/planyi/prodolzheniye.json).
- [Vosemj tochnyikh vkhodov](../2026-09-11_11-52-54_MSK_obyyedinitj-priyom-napravlenij-FUMA/materialyi/vkhodyi.json).
- [Prinyatyiye shablonyi](../2026-09-11_10-36-27_MSK_avtomatizirovatj-rasshireniye-shablonov/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 13:03:06 MSK -->
<!-- content-sha256: sha256:77d0385939bcdc959e79baca2bfb8730567a639caa079a03cb6586b712d3c1b5 -->
<!-- FUM-MD-RECENCY:END -->
