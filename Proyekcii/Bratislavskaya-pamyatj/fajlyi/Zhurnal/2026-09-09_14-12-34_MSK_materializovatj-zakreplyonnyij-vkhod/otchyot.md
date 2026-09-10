# Otchyot 2026-09-09 14:12:34 MSK - Materializovatj zakreplyonnyij vkhod

Realizovanyi materializaciya zakreplyonnyikh fajlov i nezavisimaya sverka bez ispolneniya. Komanda koordinatora prinyata v prezhnem sobstvennom worktree ot 48c0a98d6682f8d3ec2492addcb07f28bb679bf7. Iskhodnoye derevo, reyestr i zavisimosti proveryayutsya povtorno; toljko podtverzhdyonnyiye syiryiye fajlyi poluchayut lokaljnuyu kvitanciyu. Oba flaga dopuska vsegda false. Obsjhiye pravila, reyestryi, kartochki, run-v4/report-v3 i Proyekcii ne izmenenyi.

Utochneniye koordinatora «Prinyato: sokhranyaj iskhodnyiye v3…» prinyato: predyidusjhiye zapisi ostayutsya neizmennyimi; otdeljnaya zavershayusjhaya papka s yavnyim flagom nachala v4 razreshena. Polnyij adresnyij nabor i povtor profilya budut ssyilatjsya na predmetnyiye RED/GREEN etogo etapa. Soglasovannyij obyyom ostayotsya materializaciyej bez ispolneniya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Adresnyiye proverki | V upravlyayemom bloke | Fakticheskiye verkhneurovnevyiye processyi obyortki |
| Materializaciya, 2 povtornyikh / unikaljnyikh puti | 1,665 / 1,696 s | Sinteticheskiye vkhodyi, 21 fakticheskij fajl s zavisimostjyu |
| Materializaciya, 100 povtornyikh / unikaljnyikh putej | 1,730 / 6,780 s | 119 fakticheskikh fajlov, rezhimyi 0644/0755 |
| Obsjhij smoke | Ne zapuskalsya | Yavno zapresjhyon koordinatorom v etom dereve |

Granica profilya: ot podgotovki vremennyikh fikstur do poslednej nezavisimoj sverki chetyiryokh scenariyev. Podgotovka izmeryayetsya otdeljno. Metki proverki vkhoda, chteniya Git, sozdaniya, sverki i fsync vlozhenyi i ne skladyivayutsya. Proverochnyij process uzhe vklyuchayet eti intervalyi. Publikaciya razrabotcheskogo kommita i peredacha koordinatoru vne izmerennogo intervala. Profilj khranit Python heap peak, obyyom i fakticheskiye chteniya Git; pamyatj dochernego Git ne izmeryalasj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:938a250e1f598913d855bec21b0a535ca72b3ced95483f7f3983171845167a80 -->

| Vyizov                                                                          | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------ | ------------ | --------- |
| [Korenj materializacii] Kontrakt materializacii do realizacii                  | 0,103 s      | neuspeshno |
| [Korenj materializacii] Pervaya realizaciya materializacii i otkazov             | 110,765 s    | uspeshno   |
| [Korenj materializacii] CLI i avarijnyiye granicyi do podklyucheniya komand          | 14,944 s     | neuspeshno |
| [Korenj materializacii] Podmena imenovannyikh putej vo vremya sverki — RED        | 3,595 s      | neuspeshno |
| [Korenj materializacii] Podmena fajla posle otkryitiya do pervogo fstat — RED    | 2,107 s      | neuspeshno |
| [Korenj materializacii] Podmena UUID materializacii i alias reyestra — RED      | 3,658 s      | neuspeshno |
| [Korenj materializacii] CLI i obnaruzhivayemyiye podmenyi — GREEN                   | 67,054 s     | uspeshno   |
| [Korenj materializacii] Otkaz posle kyesha i vo vtorom bloke fajla               | 5,417 s      | uspeshno   |
| [Korenj materializacii] Profilj materializacii povtornyikh i unikaljnyikh obyyektov | 23,198 s     | uspeshno   |
| [Korenj materializacii] Sobstvennyiye imena materializacii do perevoda           | 0,095 s      | neuspeshno |
| [Korenj materializacii] Sukhoj plan perevoda imyon testov materializacii         | 0,07 s       | uspeshno   |
| [Korenj materializacii] Sobstvennyiye russkiye imena materializacii — GREEN       | 0,091 s      | uspeshno   |
| [Korenj materializacii] Diff realizacii do kontroljnoj tochki                   | 0,049 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 231,146 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Pervyij RED otsutstvuyusjhego modulya otdelyon ot realjnyikh povedencheskikh RED recenzii. Osnovnoj nabor posle ispravlenij — 20 uspeshnyikh testov za 66,950 s; dopolniteljnyiye 2 testa ischeznoveniya istochnika posle kyesha i otkazov vtorogo bloka/kvitancii uspeshnyi za 5,302 s. Fakticheskiye zapisi soderzhat otdeljnoye vneshneye vremya kazhdogo processa. Posle tokenovogo pereimenovaniya imyon obsjhij adresnyij nabor vsego instrumenta ostayotsya sleduyusjhej rabotoj.

Podtverzhdenyi A pri zhivyikh B→C, otsutstviye zapasnogo chteniya iz checkout, raw gitlink i neprozrachnyij arkhiv, otsutstviye zapuska filjtrov i instrumentov, otdeljnyiye inode, rezhimyi, pustyiye derevjya, otsutstviye lishnikh/propusjhennyikh fajlov. Short/zero/ENOSPC lokalizovanyi na payload, vtoroj blok i kvitanciyu; otkazyi kazhdogo fsync ne dayut prinimayemogo rezuljtata. Realjnyiye docherniye processyi ostanavlivayutsya na chetyiryokh granicakh pending/fajl/podgotovka kvitancii/ustanovka. Podmenyi naznacheniya i roditelya sokhranyayut vneshniye kontroljnyiye bajtyi.

Read-only-recenzent nashyol i korenj vosproizvyol RED: zamena fajla posle open do pervogo fstat; zamena vlozhennogo kataloga i dobavleniye fajla vo vremya obkhoda; izmeneniye UUID kvitancii; registrovyij alias reyestra. Ispravleniya poluchili GREEN, recenzent novyikh blokerov ne nashyol. Proverki imyon vyiyavili sobstvennyiye latinskiye chasti imyon testov i vneshneye pereopredeleniye `os.link`; posledneye vyirazheno cherez standartnyij mock API, sobstvennyiye imena perevedenyi dejstvuyusjhej avtomatizaciyej po khyeshirovannoj karte. Proverka sobstvennogo ostatka GREEN.

## Resheniya i ogranicheniya

- Sozdaniye dopuskayetsya toljko v novom naznachenii pod chastnyim katalogom tekusjhego UID; vse puti zakreplyayutsya deskriptorami bez symlink. Susjhestvuyusjhiye chastichnyiye sledyi ne ochisjhayutsya.
- Kvitanciya materializacii ne yavlyayetsya priyomochnoj kvitanciyej0155. Yeyo UUIDv5 nezavisimo vyivoditsya iz input/path/device/inode; sluchajnyij UUID operacii pending imeyet druguyu rolj. Povtor trebuyet svezhej polnoj sverki.
- Pending dolgovechno sozdayotsya do naznacheniya i snimayetsya posle zapisi, sinkhronizacii i nezavisimoj sverki. Posle finaljnogo fsync-otkaza vosstanovleniye pending yavlyayetsya best effort; otsutstviye uspeshnogo vozvrata ne podmenyayetsya obesjhaniyem bezuslovnogo vosstanovleniya. Proizvoljnyij vrazhdebnyij process togo zhe UID ne okhvachen polnoj atomarnoj garantiyej.
- Git alternates i vlozhennyiye gitlink yavno ne podderzhanyi. Zhivyiye fajlyi ne zamenyayut otsutstvuyusjhiye obyyektyi. Ispolneniye, ocheredj dostavki/otmena, deljta vyikhoda i polnoye zakryitiye0155 ostayutsya za granicej.
- Obnaruzhena sobstvennaya procedurnaya oshibka: pervyij zapusk etoj novoj papki ne soderzhal `--приёмочные-раунды`, poetomu obyortka pravomerno sozdala v3. Zapisi ne perepisanyi i ne nazvanyi v4. Dejstvuyusjhij perekhod starogo prefiksa trebuyet soderzhateljnogo izmeneniya obyortki; radi ispravleniya zapuska ono ne vyipolnyayetsya. Etot ogranichennyij etap fiksiruyetsya s yavnoj ostavshejsya rabotoj, zatem novyij zavershayusjhij etap nachinayet chistuyu v4-istoriyu. Novyikh zadach Codex ne sozdayotsya.
- Nastoyasjhij indeks FUM novyim protokolom ne prinimalsya. Publikuyetsya toljko sobstvennyij razrabotcheskij kod i proverochnyiye materialyi, ne poljzovateljskij payload. Polnyij smoke, proyekciya i obsjhaya priyomka ostayutsya u koordinatora.

## Istochniki

- [Iskhodnaya komanda](zapros.md).
- [Kontrakt materializacii](../../Instrumentyi/fum-snimki-indeksa/materializaciya.md).
- [Profilj](materialyi/profilj-materializacii.json).
- [Karta imyon](materialyi/karta-russkikh-imyon.json) i [rezuljtat avtomatizacii](materialyi/rezuljtat-pereimenovaniya.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 14:49:20 MSK -->
<!-- content-sha256: sha256:b8bbe2cce4c605ad994f46547344f3c41022c1c288643e38ff6f08d815da5252 -->
<!-- FUM-MD-RECENCY:END -->
