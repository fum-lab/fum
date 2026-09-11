# Otchyot 2026-09-11 02:44:12 MSK - Obnovitj pokoleniye po prezhnej politike

Realizovan uzkij perekhod prezhnego pokoleniya v2 na rasshirennuyu politiku prilozheniya. Susjhestvuyusjhaya celj proveryayetsya po odnomu polnomu istoricheskomu kontraktu; posle dokazateljstva vladeniya novoye pokoleniye stroitsya iz tekusjhego kanona. Itogovyij validator trebuyet dejstvuyusjhij khyesh politiki. Sam istoricheskij manifest i proveryayemoye prezhneye derevo do tranzakcii ne ispravlyayutsya.

## Nablyudeniya i vosstanovleniye

Pervyij checkpoint `c192a3e9c92246fd5e5f1ce89490322f5ee25644` sokhranil dopusk formatov, no propustil tri znacheniya JSON Schema i perekhod staroj politiki. Eto byili dva blokera obsjhej priyomki. Skhema ispravlena otdeljnyim opublikovannyim kommitom `0f534e49fa3c8abdbb1b71aa7b1a29bb8bf1389a`: [predyidusjhij otchyot](../2026-09-11_02-30-48_MSK_soglasovatj-skhemu-formatov-prilozheniya/otchyot.md) khranit RED devyati raskhozhdenij i GREEN tryokh testov. Nyineshnij etap ispravlyayet vtoroj bloker. Koordinator centralizovanno registriruyet oba nablyudeniya; novyiye nomera lokaljno ne vyidelyalisj.

Fikstura sozdana kodom iz kommita `aeae18cb146a34563ff39c84d9bc5ef59fffab91`, blob `03d8e6531d4c327528a639adb4ff793bb9c825e9`, SHA-256 koda `74b320d2201e4203a1f506985063eb97d4be93cd0476f5f8fa68386b82635c88`. Polnyij prezhnij kontrakt imeyet kanonicheskij khyesh `sha256:9f262153c9de986270cec76ad3c37da34c99ace0c187474ba8a1bc736222220a`. Pered ispolneniyem prezhnego koda vosproizvodyasjhij scenarij sveryayet yego tochnyij khyesh, zatem sveryayet polnyij khyesh kontrakta. Fikstura soderzhit odin `.txt` s kirillicej i CRLF, yego tochnyij vyikhod, prezhnij plan i manifest, proiskhozhdeniye i prostuyu inyyecirovannuyu tablicu imyon. Zhivoj LinguisticKit ne vyizyivayetsya.

Pervyij podgotoviteljnyij zapusk fiksturyi ne imel HEAD vremennogo repozitoriya; on ostanovilsya do sozdaniya fiksturyi. Dobavlena obyichnaya fiksaciya yedinstvennogo iskhodnika v sobstvennom vremennom Git-repozitorii. Vtoroj zapusk uspeshen. Pervyij vyizov sozdaniya papki Zhurnala neverno peredal datu vmesto metki imeni i byil otvergnut do zapisi; povtor s kanonicheskoj metkoj sozdal odnu papku.

RED iz pyati testov dal dve realjnyiye oshibki: `применить_поколение` otklonyalo staryij khyesh i pri neizmennom kanone, i posle dobavleniya `.c`/`.pbxproj`. Neizvestnaya politika, povrezhdyonnyij fajl i lishnij fajl uzhe otvergalisj. Posle uzkogo vyibora istoricheskogo kontrakta vse pyatj scenariyev proshli, vklyuchaya nezavisimuyu validaciyu i pobajtovo odinakovyij povtor.

Rasshirennaya regressiya proverila podmenu formatnyikh polej, smyislovogo khyesha plana, iskhodnogo snimka, polnyij istoricheskij obyyekt, yego otsutstviye i simvolicheskuyu ssyilku, a takzhe rezhim starogo vyikhoda. Pervyij zapusk iz 13 testov dal odin defekt ozhidaniya: fakticheskij praviljnyij otkaz nachinalsya s «Rezhim», regulyarnoye vyirazheniye ozhidalo strochnuyu bukvu. Ispravleno toljko ozhidaniye, ispolnyayemyij kod ne menyalsya.

Pervyij dopusk svyaznosti vyiyavil nezapolnennyij avtomaticheskij blok otchyotnoj tablicyi i netochnoye imya obyazateljnogo razdela profilya. Razdel nazvan po kontraktu Zhurnala, tablica sformirovana shtatnyim predprosmotrom; eto ne menyayet kod ili rezuljtatyi proverok.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granica izmereniya |
| --- | --- | --- |
| Vyibor prezhnej politiki | 0,000160 s | Okruglyonnaya mediana pyati serij po 1000 vyizovov |
| Perekhod odnogo fajla | 1,129449 s | Mediana pyati perekhodov; podgotovka fiksturyi isklyuchena |
| Poslednyaya adresnaya regressiya | 10,869 s | Vnutrennyaya dliteljnostj 14 testov unittest |
| Polnyij smoke-check | ne zapuskalsya | Tyazhyoloye okno vyideleno drugoj rabote |
| Podgotovka i revjyu | ne izmereno | Net otdeljnogo nepreryivnogo sekundomera |

### Resheniye po profilyu

Do izmereniya zadanyi porogi: mediana vyibora prezhnej politiki do 1 ms i sinteticheskogo perekhoda odnogo fajla do 2 s ne trebuyut optimizacii. Pyatj serij po 1000 vyizovov dali medianu vyibora tekusjhej politiki 27,439375 mks, prezhnej — 159,820250 mks. Pyatj perekhodov odnogo `.txt` dali medianu 1,129449 s. [Syiryiye vyiborki](materialyi/profilj-perekhoda.json) svyazyivayut chisla s khyeshami koda i dejstvuyusjhej politiki.

Izmeryayetsya progretaya fajlovaya sistema macOS 27.0 arm64 i Python 3.14.7. Podgotovka fiksturyi i vremennogo Git-repozitoriya isklyuchena iz vremeni perekhoda. Eto neboljshoj sinteticheskij vkhod, ne profilj tyisyach fajlov ili Swift. Dobavlennyij bezopasnyij razbor prezhnego obyyekta ne sozdayot znachimoj nagruzki v izmerennoj granice; optimizaciya i kyeshirovaniye ne vvodyatsya. Povtornogo profilya radi povtoreniya net: ispolnyayemyij kod posle izmereniya ne menyalsya. Profilj klassifikacii formatov predyidusjhego etapa sokhranyayet svoyu otdeljnuyu granicu.

Dlya vosproizvedeniya iz kornya chistogo klona nuzhnyi Python i Git; testyi ispoljzuyut uzhe sokhranyonnuyu fiksturu i ne trebuyut istoricheskogo kommita ili Swift. Vyizovyi zapisyivayutsya sobstvennoj otchyotnoj obyortkoj:

~~~text
python3 -B -m unittest discover -s Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests -p test_братиславская_проекция_памяти.py -k переход_прежнего_v2
python3 -B Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests/фикстуры/профиль-перехода-прежнего-v2.py --выход /tmp/fum-профиль-перехода.json
~~~

Peresozdaniye samoj fiksturyi trebuyet dostupnogo obyyekta ukazannogo kommita Git; celj vyivoda dolzhna byitj novyim vremennyim fajlom:

~~~text
python3 -B Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests/фикстуры/создать-прежнее-поколение-v2.py --корень-репозитория . --выход /tmp/fum-прежнее-поколение-v2.json
~~~

Vremya ozhidaniya ocheredi ne primenimo: FIFO ne ispoljzuyetsya. Polnyij smoke-check, Swift i zhivaya generaciya ne vyipolnyalisj po razdeleniyu resursnogo okna. Vremya podgotovki i chelovecheskogo revjyu otdeljno sekundomerom ne izmeryalosj. Pryamyiye zapuski izmerenyi otchyotnoj obyortkoj; yeyo vnutrenniye nakladnyiye raskhodyi i daljnejshaya publikaciya ne vkhodyat v dliteljnosti dochernikh processov.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                               | Dliteljnostj | Rezuljtat                          |
| ----------------------------------------------------------------------------------- | ------------ | ---------------------------------- |
| [Formatyi] Fikstura: tochnyij prezhnij kod i kontrakt iz Git                            | 0,299 s      | neuspeshno                          |
| [Formatyi] Fikstura: vosproizvedeniye prezhnego pokoleniya posle sozdaniya HEAD          | 0,403 s      | uspeshno                            |
| [Formatyi] RED: perekhod tochnogo prezhnego v2 i zasjhitnyiye otkazyi                        | 1,057 s      | neuspeshno                          |
| [Formatyi] GREEN: perekhod zakreplyonnogo prezhnego v2 i zasjhitnyiye otkazyi                | 4,884 s      | uspeshno                            |
| [Formatyi] Regressiya: perekhod, polnyij snimok, strogiye metadannyiye i versiya 1          | 7,937 s      | neuspeshno                          |
| [Formatyi] Profilj: vyibor politiki i sinteticheskij perekhod odnogo fajla              | 7,385 s      | uspeshno                            |
| [Formatyi] GREEN: polnyij perekhod, zasjhitnyiye otkazyi, skhemyi, versiya 1 i idempotentnostj | 11,041 s     | uspeshno                            |
| [Formatyi] Proiskhozhdeniye: povtoryayemyiye bajtyi fiksturyi i polnogo prezhnego kontrakta    | 0,509 s      | uspeshno                            |
| [Formatyi] Dopusk perekhoda: exact diff i svyaznostj etapa                             | 40,01 s      | neuspeshno                          |
| [Formatyi] Dopusk: svyaznostj posle shtatnogo zapolneniya otchyotnogo bloka               | 0,000 s      | ne zaversheno — net itogovoj zapisi |

Obsjheye vremya pryamyikh zapuskov proverok: 73,525 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Vosstanovleniye posle perezapuska

Posle soobsjheniya koordinatora o poljzovateljskom perezapuske prezhnij ispolnitelj processa stal nedostupen: chteniye po sokhranyonnomu identifikatoru vernulo `Unknown process id`; v lokaljnom spiske processov obyortka i dochernyaya svyaznostj ne najdenyi. Mashinnaya zapisj `10_f687f3df-8532-4008-83af-9d01b4b4b793.json` sokhranila sostoyaniye «vyipolnyayetsya» s neizvestnyimi dliteljnostjyu, kodom i statusom. Uspekh etoj svyaznosti ne nablyudalsya. Predyidusjhiye 14 uspeshnyikh testov i profilj sokhranenyi.

Zapisj ne udalena, ne pereimenovana i ne zamenena vyimyishlennyim zaversheniyem. Obyyavlyatj kod, dliteljnostj libo signal zadnim chislom neljzya. Nalichiye osirotevshej aktivnoj zapisi zakryivayet obyichnyij dopusk kontroljnoj tochki; tekusjhij CLI otchyotnoj avtomatizacii ne predostavlyayet otdeljnogo vosstanovleniya takogo sluchaya. Koordinator uvedomlyon o tochnom prepyatstvii. Poka sokhranyayetsya podgotovlennyij indeks, prodolzheniye rabotyi i integracionnaya priyomka ne obyyavlyayutsya zavershyonnyimi.

## Priyomka i peredacha

Nezavisimyij chitatelj proveril ispolnyayemuyu granicu: vyibran odin zakreplyonnyij obyyekt, sokhranenyi vse proverki polnogo manifesta i dereva, finaljnyij barjyer tekusjhej politiki ne izmenyon. Zamechaniye o registre testovogo ozhidaniya ispravleno. Dlya neizvestnoj prezhnej politiki otricateljnyij test menyayet ogranicheniye puti i pereschityivayet svyazannyiye khyeshi plana i manifesta: otvergayetsya soglasovannaya neizvestnaya politika, a ne toljko sluchajno isporchennyij khyesh.

Konechnyij adresnyij progon uspeshno zavershil 14 testov i vklyuchayet vosemj novyikh scenariyev perekhoda, susjhestvuyusjhuyu strogostj vladeniya, znacheniya skhem, sokhrannostj versii 1, tochnyiye formatyi i atomarnuyu idempotentnostj. Svyaznostj i proverka exact diff fiksiruyutsya otdeljno pered kontroljnoj tochkoj. Eto checkpoint nakoplennogo kontura, ne zaversheniye FUM-STEP-0176: korenj integriruyet proverennyiye fajlyi, peresobirayet obsjhiye indeksyi i proveryayet zhivoj perekhod s obsjhim smoke-check.

Zhivoye staroye pokoleniye v vyidelennom dereve ne zapuskalosj i ne izmenyalosj; obyichnyiye iskhodniki prilozheniya ostayutsya oblastjyu drugogo pisatelya. Pravila agentov, topologiya zavisimostej i Git-konfiguraciya etim etapom ne menyalisj.

## Istochniki

- [Iskhodnyij zapros i upravleniye](zapros.md).
- [Pervyij etap formatov](../2026-09-11_02-06-54_MSK_podderzhatj-formatyi-prilozheniya-v-proyekcii/otchyot.md).
- [Ispravleniye skhemyi](../2026-09-11_02-30-48_MSK_soglasovatj-skhemu-formatov-prilozheniya/otchyot.md).
- [Kontrakt i scenarii](../../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:25:27 MSK -->
<!-- content-sha256: sha256:46204b296f892411a5353cc4767e976ece59de8ad1ab5ec225711e9b996e5e33 -->
<!-- FUM-MD-RECENCY:END -->
