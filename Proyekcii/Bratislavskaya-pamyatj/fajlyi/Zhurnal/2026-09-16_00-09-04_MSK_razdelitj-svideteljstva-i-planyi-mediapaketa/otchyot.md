# Otchyot 2026-09-16 00:09:04 MSK - Razdelitj svideteljstva i planyi mediapaketa

Generator versii 2 otdelyayet material novosti ot finansovogo svideteljstva i osnovaniya proverennogo rezuljtata. Celaya JSON-zapisj vyibrannogo operatorom avtora proveryayetsya po neizmenyayemomu Git-adresu, khyeshu i soglasovannosti polej. Proverka formata ne udostoveryayet avtora, ispolneniye proverki ili bankovskuyu operaciyu. Plan boljshe ne podpisyivayetsya kak proverennyij rezuljtat.

[Realjnyij paket](materialyi/mediapaket.json) poluchen CLI s kodom 0. On opisyivayet plan, sokhranyayet vse pyatj denezhnyikh znachenij, period, poluchatelya, osnovaniye proverki i finansovoye svideteljstvo neizvestnyimi. SHA-256 paketa `82d423402331e6c18120b0423a63c0284e0c82e1fbb74457e126837171ab412c` sovpal s rezuljtatom desyati povtorov profiljnogo scenariya. [Rukovodstvo](../../Instrumentyi/fum-reyestr-planirovaniya/mediapaket-podderzhki.md) opisyivayet zapusk, v2, yavnuyu migraciyu, istochniki i granicyi doveriya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Razbor i realizaciya | otdeljno ne izmereno | Analiz, redaktirovaniye i ozhidaniye read-only-obzorov cheredovalisj; summa rabochego vremeni ne vyivoditsya iz raznosti chasov |
| Pryamyiye proverki | po mashinnyim zapisyam nizhe | Monotonnyiye intervalyi kazhdogo dochernego processa shtatnoj obyortki, vklyuchaya neuspekhi |
| Sborka odnogo paketa v2 | mediana 59,781292 ms | 10 vyizovov sobratj; Git-chteniye, validaciya i shablonyi; podgotovka i zapisj profilya isklyuchenyi |
| Podgotovka korrekcii ssyilok | mediana 0,031354 ms | 10 preobrazovanij tochnyikh prezhnikh bajtov itogovyim helper; chteniye i zapisj rezuljtata vne intervala |
| Polnaya priyomka i proyekciya | ne vyipolnyalisj | Ogranichennyij checkpoint po porucheniyu; tyazhyoloye okno zanimayet koordinator |
| Kommit i Git-peredacha | vne etogo izmereniya | Vyipolnyayutsya posle samostoyateljnogo terminaljnogo uspekha zaklyuchiteljnoj svyaznosti |

Granica profilya: tekusjhij etap nachat v 2026-09-16 00:09:04 MSK; opisaniye izmerenij sostavleno pri nablyudenii chasov 2026-09-16 00:51:55 MSK (21:51:55 UTC). Eto nablyudyonnaya granica oformleniya, ne izmereniye aktivnogo truda. Pozdniye proverki uchityivayutsya nizhe otdeljnyimi intervalami; finaljnaya proverka checkpoint, kommit i push vne zamyikayusjhegosya izmereniya. FIFO i avtomaticheskij handoff ne primenyayutsya.

[Itogovyij profilj generatora](materialyi/profilj-mediapaketa-itog.json) soderzhit 10 dliteljnostej 56,287–62,877 ms, versii sredyi i khyeshi vkhoda, koda, zavisimostej i shablonov. Vneshnij kyesh ne ochisjhalsya; korotkij profilj zapuskalsya pri yesjhyo vyipolnyavshemsya adresnom nabore testov. Znacheniya opisyivayut etu nagruzku, ne izolirovannyij benchmark. Mediana nizhe zaraneye zadannyikh 500 ms, poetomu nezavisimyiye Git-proverki sokhranenyi; otdeljnogo algoritmicheskogo uskoreniya ne zayavlyayetsya. Prezhnij profilj Sol i [predvariteljnyij v2](materialyi/profilj-mediapaketa-v2.json) ne zamenenyi. Kontrakt izmenilsya, sravneniye etikh chisel ne dokazyivayet uskoreniye.

[Itogovyij profilj helper](materialyi/korrekciya-ssyilok-itogovyij-profilj.json) poluchen na chastnoj kopii iskhodnyikh tryokh zaprosov s proverennyimi SHA. Yego patch i SHA rezuljtatov sovpali s pervonachaljnoj [tochnoj korrekciyej](materialyi/korrekciya-ssyilok.json); povtornoj zapisi staryikh zaprosov ne byilo.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                              | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------ | ------------ | --------- |
| [Astra] RED granic svideteljstva mediapaketa                       | 5,871 s      | neuspeshno |
| [Astra] GREEN celyikh svideteljstv i yavnyikh vidov materiala           | 14,176 s     | uspeshno   |
| [Astra] Profilj novogo mediapaketa na realjnom plane               | 0,695 s      | uspeshno   |
| [Astra] RED tryokh zamechanij nezavisimogo revjyu                      | 14,197 s     | neuspeshno |
| [Astra] RED adresnoj korrekcii ssyilok i proverka lokaljnosti Git   | 0,329 s      | neuspeshno |
| [Astra] GREEN ispravlenij revjyu, Git i korrekcii ssyilok            | 15,413 s     | neuspeshno |
| [Astra] GREEN s nezavisimyim inventaryom lokaljnyikh Git-obyyektov      | 15,498 s     | neuspeshno |
| [Astra] GREEN s yavnoj promisor-fiksturoj i polozhiteljnyim kontrolem | 15,261 s     | uspeshno   |
| [Astra] Podgotovitj i izmeritj tochnuyu korrekciyu desyati ssyilok      | 0,091 s      | uspeshno   |
| [Astra] Regressii v2 s utochnyonnoj granicej khyesha vyivoda             | 15,107 s     | uspeshno   |
| [Astra] Profilj itogovogo generatora v2                            | 0,717 s      | uspeshno   |
| [Astra] RED granicyi sleduyusjhego razdela korrekcii                   | 0,185 s      | neuspeshno |
| [Astra] Regressii v2 posle ogranicheniya razdela korrekcii           | 16,364 s     | uspeshno   |
| [Astra] RED probeljnyikh i Setext-granic razdela                     | 0,161 s      | neuspeshno |
| [Astra] Itogovyiye regressii mediapaketa i granic korrekcii          | 12,992 s     | uspeshno   |
| [Astra] Profilj itogovoj korrekcii na tochnyikh iskhodnyikh bajtakh       | 0,083 s      | uspeshno   |
| [Astra] Ranniye polya novoj paryi Zhurnala                             | 0,121 s      | uspeshno   |
| [Astra] Sborka reyestra posle registracii povtorov                  | 0,459 s      | uspeshno   |
| [Astra] Aktualjnostj reyestra i svezhesti Markdown                   | 1,822 s      | uspeshno   |
| [Astra] Sborka i sverka yavnogo kriteriya STEP0170                   | 0,93 s       | uspeshno   |
| [Astra] Obnovleniye reyestra posle perenosa korrekcii v materialyi    | 1,14 s       | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 131,612 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki i nablyudayemyiye otkazyi

- Itogovyij polnyij nabor: **39 testov, OK, 12,898 s**, [doslovnyij stdout](materialyi/vyivod-final-green-006.txt), producer zavershyon s kodom 0. Proverenyi celj i material, otdeljnoye osnovaniye rezuljtata i protokol, tipyi i nuli, sootvetstviye kazhdogo finansovogo polya vklyuchaya null, dublikatyi polnogo JSON, vstroyennyiye zapisi, puti i Git-tipyi, replacement refs, otsutstviye dozagruzki, povtoryayemostj, CLI bez bajtkoda i granica korrekcii ssyilok.
- Pervyij RED: 32 testa, pyatj failures i 11 errors; chetyire konteksta starogo finansovogo khvosta vosproizveli prinyatiye vstroyennoj zapisi. Sleduyusjhij nabor iz 32 proshyol. Nezavisimyij obzor zatem vyiyavil razdelyayemuyu ssyilku na vkhod, nekorrektnuyu podpisj otchyota bez svideteljstva i zapisj bajtkoda CLI; vse tri vosproizvedenyi i ispravlenyi.
- Dva neuspeshnyikh zapuska iz 38 testov zavershilisj na preduslovii partial-clone-fiksturyi: blob uzhe prisutstvoval do generatora. Eto oshibka postroyeniya proverki, a ne dokazannaya zagruzka generatorom. Fikstura zamenena yavnyim lokaljnyim promisor-naborom bez blob; polozhiteljnyij kontrolj obyichnyim Git podtverdil vozmozhnostj zagruzki, a generator otkazal bez yeyo vyipolneniya. Posleduyusjhiye naboryi proshli.
- Dlya helper otdeljno sokhranenyi otkaz do poyavleniya modulya i dva RED granicyi sleduyusjhego razdela. Itogovyij otkaz okhvatyivayet otstup, tab, pustoj ATX i Setext. Semj variantov nakhodyatsya v odnoj regressii; konkretnyij primenyonnyij patch ne vyikhodil za razreshyonnyij razdel.
- [Reyestr vyivoda](materialyi/svideteljstva-vyivoda.json) svyazyivayet samostoyateljnyiye artefaktyi s kodom proizvoditelya i khyeshami oboikh polnyikh privatnyikh potokov. Dlya obyichnogo runner stdout skopirovan pobajtno; dlya pryamyikh unittest s pustyim stdout otdeljno oboznachena zamena lokaljnogo puti v stderr. Istoricheskaya podpisj «SHA-256 polnogo stderr» otnosilasj toljko k tekstu unittest: preduprezhdeniya dochernego Git mogli idti v stderr otdeljno. Tekusjhij producer nazyivayet etu granicu tochno; polnyij potok podtverzhdayetsya manifestom zakhvata.
- U zapisi poryadka 5 nazvaniye shire fakticheskogo vyizova: vyipolnenyi toljko dva testa `-k коррекция`, Git-kontrolj v neyo ne vkhodil. V odnom pozdnem vyizove imya kataloga obyortki byilo nabrano s zaglavnoj P; lokaljnaya FS razreshila tot zhe fajl, zapusk zavershilsya i sokhranyon. Itogovyij nabor vyipolnen s tochnyim kanonicheskim registrom. Eti ogranicheniya ne skryivayutsya pereimenovaniyem prezhnikh zapisej.
- Posle perenosa svyaznostj na dereve indeksa `49d4d023e3a033d1c48b6fd32709c219dcda85b1` zavershilasj s kodom 0; [stdout](materialyi/uspekh-svyaznosti-002.txt) sokhranyon. Dopolniteljnaya smyislovaya sverka zatem obnaruzhila dve ustarevshiye stroki indeksa sboyev: obnovlenyi chislo proyavlenij 0071 i status, chislo i osnovnoj shag 0078. Poetomu etot uspekh ne perenositsya avtomaticheski na okonchateljnyij snimok: zaklyuchiteljnyij dopusk povtoryayetsya pered kommitom.
- Pervaya zaklyuchiteljnaya svyaznostj terminaljno zavershilasj s kodom 1 do kommita: layout ne dopuskayet otdeljnyij fajl korrekcii ryadom s zaprosom i otchyotom. [Polnyij otkaz](materialyi/otkaz-svyaznosti-001.txt) sokhranyon; fajl perenesyon v materialyi, ssyilki obnovlenyi. Uspeshnyij iskhod ne podstavlen vmesto otkaza.
- Pervonachaljnaya sborka reyestra otklonila yesjhyo oformlyayemyij razdel istochnikov STEP0174: dobavlennyij abzac ne imel markera spiska. Marker vosstanovlen do sokhraneniya reyestra; nablyudyonnyij kod 1 ne schitayetsya uspeshnoj generaciyej.
- Pervyij import istorii modeli otkazal iz-za otsutstvovavshego kataloga materialov; posle yego sozdaniya shtatnyij import zavershilsya s kodom 0. Eto podgotovka artefakta, a ne uspeshnyij test. [Nablyudayemaya istoriya](materialyi/istoriya-modeli.json) sokhranyayet fakticheskuyu Astra Ultra i predyidusjhiye modeli bez vyivoda o nevidimyikh pereklyucheniyakh.

[Nezavisimyij obzor koda](materialyi/nezavisimyij-obzor-koda.json) svyazan s SHA vosjmi fajlov. Posle adresnogo povtornogo chteniya susjhestvennyikh zamechanij ne ostalosj. Obzor ne zamenyayet formaljnyij dopusk. Ranniye polya paryi, reyestr, recency i zaklyuchiteljnaya svyaznostj vyipolnyayutsya na podgotovlennom snimke; kommit dopuskayetsya toljko posle terminaljnogo koda 0.

## Korrekciya prezhnikh rezuljtatov i planirovaniye

[Otdeljnaya korrekciya istorii](materialyi/korrekciya-istorii.md) sokhranyayet lozhnyiye utverzhdeniya tryokh prezhnikh etapov, fakticheskoye porucheniye Luna high, native diapazonyi rannego kommita i pozdnego otkaza svyaznosti. Staryiye otchyotyi, proverki i paketyi ne perepisyivalisj. Izmenenyi toljko desyatj destination staryikh zaprosov, ikh sluzhebnaya svezhestj i shtatnaya navigaciya predyidusjhego etapa.

Soglasovanno zaregistrirovanyi 0071/0008–0010 i 0078/0002. Kartochka 0078 snova aktivna; prezhnyaya ogranichennaya priyomka sokhranena. Povtoryi svyazanyi s aktivnyimi STEP0174 i STEP0170. Ikh obsjhiye meryi etim ispravleniyem ne realizovanyi. Novyiye globaljnyiye nomera ne vyidelyalisj.

## Resheniya i ogranicheniya

Eto podgotovka kontroljnoj tochki v sobstvennoj vetke `refs/heads/codex/финансирование-фума-01a0904a` ot `abc217c2760c6cbeb778833116a619ba8df644ad`. Opublikovannyiye low/high/Sol sravniteljnyiye refs proverenyi zhivyim Git-zaprosom; prezhniye oshibochnyiye lokaljnyiye imena sokhranenyi. Vneshniye finansovyiye dejstviya, soobsjheniya v socseti, akkauntyi, platezhi i efiryi ne vyipolnyalisj.

Sokhranyonnoye pokoleniye proyekcii: manifest SHA-256 `7bb832cb4bf99cbfe598867ed05051a6c7bc923e07a16b5e582ad7509a3bab47`, vkhodnoj inventarj `6515d4f4743cff97119d390d273b78d6527a18bc1df9a6a74098153204d2dda2`, plan `8ad10aba095d0c695f4d65176fdba2a92806f95fa727f7518946bccca758235e`. Eto istoricheskoye pokoleniye obsjhej bazyi; novyikh kanonicheskikh fajlov v nyom net. Yego priyomka zanovo zdesj ne proveryalasj. Polnaya priyomka, aktualjnaya proyekciya, integraciya i prinyatiye rezuljtata koordinatorom ostayutsya nezavershyonnyimi; checkpoint i push ne zamenyayut ikh.

Posle uspeshnogo dopuska — lokaljnyij kommit, tochnaya otpravka svoyej vetki, proverka udalyonnogo OID i peredacha koordinatoru dlya obzora. Zatem zapisj prekrasjhayetsya po sokhranyonnomu ogranichennomu porucheniyu; soglasovannyiye finansovyiye dannyiye zayavitelya i vneshnij zapusk ostayutsya otdeljnyim ozhidaniyem.

## Istochniki

- [Iskhodnyij zapros i pozdneye utochneniye](zapros.md).
- [Korrekciya istorii](materialyi/korrekciya-istorii.md), [pervichnyiye diapazonyi](materialyi/granicyi-pervichnyikh-sobyitij.json), [pobajtnaya sverka prezhnikh par](materialyi/svideteljstva-prezhnikh-par.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:03:43 MSK -->
<!-- content-sha256: sha256:584e2c52e4efa5c5f9c9ee73b7b838740c546b1833d4efb2fbfed5511c117622 -->
<!-- FUM-MD-RECENCY:END -->
