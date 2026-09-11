# Otchyot 2026-09-11 05:42:33 MSK - Podgotovitj sleduyusjhiye napravleniya

Etap prodolzhayet podgotovku soglasovannyikh napravlenij cherez sokhranyayemyij priyom. Pervyij matematicheskij zapusk prinyat v predyidusjhem kommite; yego predmetnaya kontroljnaya tochka opublikovana ispolnitelem, itogovaya priyomka yesjhyo zavisit ot uzkoj dorabotki proyekcii. Paralleljno prinimayetsya paketnaya komanda vyipuska diagnosticheskikh kartochek i podgotavlivayutsya posledovateljnyiye postanovki perenosa rabochikh derevjyev i interpretatora s UTF-32.

<!-- FUM-INTAKE: e956b9bee25b4e0bb93d632313464ac08fb1745c317d376508a165c7128d2175 -->

Otvet: Prinyata realizaciya vozobnovlyayemogo perenosa rabochikh derevjyev: FUM-STEP-0207 i FUM-REQ-0066. Pervyij rezuljtat — sokhranyayemyij plan, konechnaya tranzakciya i avtonomnaya proverka vosstanovleniya odnogo linked worktree s rekursivnyimi submodule i ignoriruyemyimi dannyimi. Perenos zhivyikh derevjyev ostayotsya otdeljnyim primeneniyem posle svezhej proverki vladeniya i vneshnikh privyazok. Sozdaniye otdeljnoj zadachi schitayetsya nezavershyonnyim do otveta oficialjnogo instrumenta i rannego nablyudeniya yeyo iskhodnoj bazyi.

Osnovaniye: Yavnaya komanda razreshayet realizaciyu avtomatizacii perenosa; podtverzhdyonnoye predshestvuyusjheye utochneniye otnositsya k papke «Poduzlyi» v papke proyekta. Obsjhiye podtverzhdyonnyiye komandyi ob avtomatizacii vsego perechislennogo razreshayut priyom, nomera i otdeljnuyu vidimuyu zadachu. Pozdneye utochneniye trebuyet iskhodnogo worktree ot tochnogo kommita prinyatoj postanovki. Pervyij prinimayemyij srez ogranichen instrumentom i avtonomnyimi fiksturami; istoricheskaya inventarizaciya ne dayot tekusjhego dopuska k peremesjheniyu zhivyikh derevjyev. Pervichnyiye ekzemplyaryi e956b9bee25b4e0bb93d632313464ac08fb1745c317d376508a165c7128d2175 i 127c7ec860f6bc223c54949ac8872a86715503bdb9218be9ee634a4df04de099 prochitanyi v polnom kontekste 0177; originalyi i pozdneye utochneniye sokhranenyi v zaprose tekusjhego etapa.

## Profilj vremeni vyipolneniya

| Stadiya                                            | Dliteljnostj    | Granicyi i sposob izmereniya                                              |
| ------------------------------------------------- | --------------- | ----------------------------------------------------------------------- |
| Vosstanovleniye istochnikov i soderzhateljnaya rabota | ne izmereno     | Pervichnyiye komandyi, RO, integraciya i podgotovka postanovki               |
| Vosstanovleniye realjnogo priyoma 0207              | 6,613514750 s   | Odin zapusk biznes-komandyi do sokhranyonnogo rezuljtata; proverki vlozhenyi |
| Pryamyiye proverki etapa                             | 136,954917334 s | Vosemj terminaljnyikh zapisej v3; vse uspeshnyi                             |
| Polnyij smoke-check tekusjhego snimka                | ne zapuskalsya   | Kontroljnaya tochka s nezavershyonnyim obyyomom; finaljnaya priyomka predstoit  |

Granica profilya: nachalo 2026-09-11 05:42:33 MSK; nablyudyonnyij konec okhvachennoj rabotyi 2026-09-11 07:08:13 MSK. Posleduyusjhaya kontroljnaya svyaznostj, Git-publikaciya i peredacha yesjhyo ne vkhodyat. Docherniye izmereniya i vlozhennyiye intervalyi ne summiruyutsya s kalendarnyim vremenem svoyego etapa.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                           | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj 0201] Proveritj integraciyu paketa diagnostiki i dolgovechnogo khranilisjha  | 32,295 s     | uspeshno   |
| [Korenj 0201] Sobratj reyestr posle fakticheskogo vyipuska diagnosticheskogo paketa | 0,376 s      | uspeshno   |
| [Korenj 0201] Proveritj reyestr s diagnosticheskimi shagami                        | 0,384 s      | uspeshno   |
| [Korenj 0201] Proveritj neobyazateljnyij graf v proyekcii posle integracii         | 7,488 s      | uspeshno   |
| [Korenj 0201] Proveritj vosstanovleniye negotovogo priyoma posle integracii       | 74,853 s     | uspeshno   |
| [Korenj 0201] Proveritj pokryitiye pravil posle zakrepleniya priyoma                | 0,102 s      | uspeshno   |
| [Korenj 0201] Proveritj mashinnyiye puti posle shesti deklaracij                    | 21,213 s     | uspeshno   |
| [Korenj 0201] Proveritj pervyij reyestr obyazateljstva i ostatok 0201              | 0,244 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 136,955 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Pervichnyij istochnik podtverzhdyon shtatnyim chitatelem bez zapisi; prochitannyiye komandyi i soderzhaniye budusjhikh postanovok sokhranyayutsya razdeljno ot sluzhebnoj koordinacii.
- RO-revjyu paketnoj komandyi vyiyavilo dve granicyi do dostavki: fakticheskij staryij format 0035 bez TOML i dva zaraneye podgotovlennyikh plana odnogo ID posle chastichnogo primeneniya. Ispolnitelj nablyudal RED i ispravil obe; korenj prochital ogranichennyij staryij zagolovok i povtornuyu proverku sosednikh ID pod zamkom. Shestj fajlov perenesenyi iz `4779f4d541a78effad2679bac1ed3a7e4f285403`; SHA-256 integracionnogo diff `9ebe0001b5d1566eda88f6aa3eb213ade58685df6ac5204bbcc480888a542de5`. Yedinstvennaya posleduyusjhaya pravka opisaniya zamenyayet ssyilku na neperenesyonnyij Zhurnal tochnyim Git-istochnikom. Sobstvennyiye 51 adresnyij test proshli; postroyeniye i proverka reyestra proshli.
- Prinyatyij paket realjno vyipustil desyatj fajlov: pyatj novyikh kartochek 0053–0057, obnovlyonnuyu 0035, shagi 0204/0205 i dva indeksa. SHA-256 smyislovogo vkhoda `1d46490523f347fd45c63a5a3022956c2f0180ec49229bf29e280427aa33234b`, kontroljnaya summa plana `4860182e5c9e6b513e2419f8d19c485910caf22a5eca460c67bb3f7f1abebdd2`; vse itogovyiye bajtyi sverenyi. Nezavisimoye RO-revjyu podtverdilo granicyi proyavlenij i ogranichennyiye ustraneniya; sovremennaya kartochka 0020 o CF-Ray ne poglosjhayetsya staryim osirotevshim zapuskom. Plan i kvitanciya s fizicheskimi kornyami ostayutsya privatnyimi.
- Prezhneye ispravleniye 0052/0203 otnositsya k svyaznosti; proyekciya imela otdeljnuyu obyazateljnuyu proverku susjhestvovaniya grafa. Minimaljnyiye tri fajla `7acc2de8ca1dcbefd82c16faecd1c31bdfa6e648` prinyatyi posle RO; SHA-256 diff `993c30bdd60da3960601e8b178da05676ed9ed9a4080d1617bd2989f17b9299a`. Semj sobstvennyikh adresnyikh scenariyev proshli, vklyuchaya sinteticheskiye primeneniye i nezavisimyij manifest bez kataloga grafa, sokhraneniye poljzovateljskogo fajla i otricateljnyiye puti. Susjhestvuyusjhij predikat svyaznosti ne izmenyon. Polnaya matematicheskaya priyomka posle peredachi ispravleniya yesjhyo ozhidayetsya.
- Paket susjhestvuyusjhikh 0052/0203 primenyon otdeljno: chetyire fajla sootvetstvuyut planu `a364a03479dd1b4f2d89bd1de89214e934cdf96887cc42320de2313d77344164`. Sokhranenyi iskhodnyiye proyavleniya 0001/0002 i ogranichennoye staroye ustraneniye; matematicheskij otkaz stal proyavleniyem 0003. Oba susjhestvuyusjhikh identifikatora aktivnyi do podtverzhdeniya novogo puti otkaza.

## Resheniya i ogranicheniya

- Podtverzhdyonnyiye komandyi razreshayut perenos i interpretator. Pervyij perenos prinimayetsya na avtonomnyikh fiksturakh odnogo linked worktree v predelakh odnogo toma, vklyuchaya submodule i ignoriruyemyiye dannyiye; zhivyiye poljzovateljskiye derevjya etim etapom ne peremesjhayutsya. Interpretator pereispoljzuyet susjhestvuyusjhij Swift-prototip: snachala chistoye ispolneniye bez expectedOutput, zatem strogiye iskhodnyiye bajtyi UTF-8, skalyaryi i yavno vyibrannaya serializaciya UTF-32.
- Kazhdyij novyij priyom sokhranyayet polnyiye indeksyi, poetomu posledovateljnostj odnogo napravleniya zavershayetsya kommitom postanovki, zakrepleniyem i nativnyim otvetom do podgotovki sleduyusjhego. Obsjhiye nomera naznachayet odin susjhestvuyusjhij raspredelitelj; proizvoljnyiye nomera iz chernovika ne ispoljzuyutsya.
- Matematicheskaya zadacha sokhranila `1a51647b7339aad3760ed09857063ccae791659a`: karta, vosemj voprosov i predlozheniye FUM-STEP-0206. Status khoda completed ne oznachayet zaversheniya 0202. Predmetnoye RO-revjyu zamechanij ne vyiyavilo. Tochnoj postavkoj 7acc2de peredano prodolzheniye toj zhe zadachi `01a08e36-fa9e-7e50-b3a4-99119926a4d8` s yavnyimi gpt-6-astra/ultra; novogo sozdaniya matematiki ne vyipolnyalosj.
- Raspredelitelj realjno zarezerviroval perenos FUM-STEP-0207/FUM-REQ-0066 (sobyitiye `c036a4b975d4ac473e37eae6a550338482c5e1cbe41a68a6e2476d555daaf867`) i interpretator FUM-STEP-0208/FUM-REQ-0067 (sobyitiye `9946f99064d68fe913941ca8f9a2a00a3db692fe293655f3ad5e529cede570f1`). Predmetnyiye vkhodyi proshli nezavisimoye RO, ozhidayemyiye iskhodnyiye khyeshi sovpali. Prezhneye utverzhdeniye o soglasovannosti obratnyikh otnoshenij byilo oshibochnyim: realjnyij sborsjhik otklonil simmetrichnoye «dopolnyayet». Dejstvuyusjhij slovarj trebuyet obratnoye «dopolnyayetsya». Dlya 0207 vyipolnena sokhranyayemaya korrekciya, dlya yesjhyo ne primenyonnogo 0208 ispravlen privatnyij vkhod. Sam rezerv ne oznachayet sozdaniya kartochek libo native-zadach.
- Profilj paketnoj komandyi avtora: podgotovka 193,444 ms, primeneniye 594,997 ms, povtor 512,888 ms na pyati otkryityikh fiksturakh; daljnejshaya optimizaciya ne potrebovalasj. Profilj proyekcii dlya 25 ssyilok iz gotovogo plana: otsutstvuyusjhij graf 368,880 → 30,638 ms; susjhestvuyusjhij 5,122 ms; pokhozheye imya 0,633 ms. Git-ignore pereispoljzuyetsya toljko vnutri odnogo formirovaniya s zaklyuchiteljnoj proverkoj, predmetnaya granica kazhdoj ssyilki sokhranena. Zameryi ne vklyuchayut Git-podgotovku plana, Swift i ustanovku; obsjhego uskoreniya proyekcii ne zayavlyayetsya.
- Posle vosstanovleniya tekusjhij pervichnyij JSONL kornya prochitan do granicyi 28742453 bajta, SHA-256 `4f5ebf787c5d23ee2118623d32db31fc02f07eaca5e6526433dead49c06974b8`: odin podtverzhdyonnyij chelovecheskij vopros, polnota istinna, khvost i pozdneye dopisyivaniye nulevyiye. Otvet o chisle derevjyev ostayotsya prezhnim: ispoljzovatj zanyatyiye nezavisimyiye uchastki, sleduyusjhiye derevjya sozdavatj pod soglasovannyiye postanovki.
- Pri poiske komandyi start korenj snachala ukazal nesusjhestvuyusjhij request-folders.py i poluchil otkaz Python do zapisi; zatem prochital realjnyij inventarj scripts i primenil dokumentirovannuyu struktura-papok-zaprosov.py. Nablyudeniye sokhranyayetsya dlya sopostavleniya susjhestvuyusjhemu FUM-SBOJ-0009, bez novogo nomera po odnomu pokhozhemu soobsjheniyu.
- Ostatok 0201 vklyuchayet vyipusk diagnostiki, zaversheniye dvukh novyikh postanovok, susjhestvuyusjhiye 0154 i 0165, kanonicheskoye zakrepleniye postoyannogo sposoba priyoma i itogovuyu priyomku. Etot etap ne obyyavlyayet ikh zavershyonnyimi.

## Vosstanovleniye priyoma i tekusjheye sostoyaniye

Posle realjnogo otkaza `missing inverse semantic relation: FUM-REQ-0027 дополняет FUM-REQ-0066` semj uzhe ustanovlennyikh fajlov sokhranyalisj bez ruchnogo ispravleniya. Negotovoye sobyitiye ne imelo postanovki, nablyudeniya ili vneshnej popyitki. Ogranichennaya dorabotka dostavlena kommitom `17ef8a59fa3c67a73e54c2348189afcb10849585` ot `4779f4d541a78effad2679bac1ed3a7e4f285403`; udalyonnyij OID podtverzhdyon ispolnitelem. Pyatj fajlov koda i testov perenesenyi pobajtno, iz chelovecheskogo opisaniya dobavlen toljko novyij razdel. Integracionnyij patch shesti fajlov imeyet SHA-256 `e3c7b89c5c093a85b230d0b193a2944765e66771ed14f43debcae63a5ad234a2`. Staryij chernovik patch ne primenyalsya.

Dochernyaya proverka sokhranyayet realjnyiye RED dlya otsutstvuyusjhego sposoba vosstanovleniya, nedopustimogo izmeneniya zagolovka i nesovmestimogo povtora prezhnej popyitki posle izmeneniya obsjhego indeksa. Posle ispravlenij proshli 75 adresnyikh testov za 157,923 s i tri dopolniteljnyikh scenariya za 17,639 s. V svoyom dereve korenj zapustil polnyij novyij modulj: 11 testov proshli za 74,616 s. Eto otdeljnyiye granicyi zapuskov, oni ne skladyivayutsya s dochernim kalendarnyim vremenem. Finaljnyij profilj tryokh realjnyikh Git-fikstur: mediana korrekcii 2770,760 ms, tochnogo povtora 245,164 ms; vlozhennyiye sborka reyestra 33,242 ms i ustanovka stadii 991,270 ms vkhodyat v celoye ispravleniye. Daljnejshaya optimizaciya ne obosnovana; vneshnego vyizova v profile net.

Korenj vyipolnil dokumentirovannuyu `исправить-план` s odnim tochnyim ispravleniyem otnosheniya 0027 k 0066. SHA-256 privatnogo vkhoda `e5f2d702615e94c0abdb25bfbe3eca8e14bfa3eedd900b7f24486e3d6986b91a`; kanonicheskij khyesh namereniya `13b600d88ef1603c929e469f358d774aaeb339592f76604031823834032185c8`. Operaciya zanyala 6,613514750 s i vernula kod 0, `готов: true`, te zhe FUM-STEP-0207/FUM-REQ-0066. SHA-256 privatnogo nablyudeniya `569fa2c74fccce53b5485be575dee8fdf61623223101a76650f32acf46fd1fa0`. Nezavisimoye chteniye podtverdilo neizmennyij pervonachaljnyij plan `7189e69a0526b504f6f93fce542f35ee19323532e4075359947cc9c5b6ba6bb5`, tochnyiye effektivnyiye bajtyi semi fajlov i reyestra, sokhranyonnyij povtorno nablyudyonnyij otkaz i otsutstviye vneshnej popyitki. Pervonachaljnyij otkaz i probel vosstanovleniya ostayutsya v diagnosticheskom ostatke 0201 do vyipuska kanonicheskoj kartochki posle zaversheniya zakrepleniya 0207; izmeneniye obsjhego indeksa do etogo narushilo byi prinyatuyu postanovku.

V pravila instrumentov pereneseno podtverzhdyonnoye ukazaniye o vidimyikh zadachakh ot kommita postanovki i postoyannom primenenii sokhranyayemogo priyoma. Inventarj menyayet toljko khyesh odnoj temyi i kratkoye soderzhaniye 000162/000171; iskhodnoye pokryitiye, identifikatoryi, marshrutyi i polnomochiya sokhranenyi. Nezavisimoye RO proverilo polnyij inventarj. Eta pravka svoyej vetki ne obyyavlyayetsya integraciyej v master.

Shestj tochnyikh deklaracij mashinnyikh putej perenesenyi iz rezuljtata matematicheskoj zadachi s sokhraneniyem yeyo smyislovyikh ID, kategorij i prichin. V svoyom fajle vyirazheniye Markdown nakhoditsya na stroke 208 vmesto 205; vyibrannaya stroka sverena po soderzhimomu. Chetyire opredeleniya proverok i dve avtonomnyiye Git-fiksturyi dobavlenyi shtatnoj `obnovitj-policy.py`, kotoraya soobsjhila `changes=6`. Prezhnij privatnyij chernovik s netochnoj poziciyej ne primenyalsya. Manifest tekusjhego etapa imeyet SHA-256 `a8ddf4d728ceb9130ad97ea3df1238fead92c289ff2d642f4cbba220f2a711dc`.

Sokhranenyi sobstvennyij reyestr obyazateljstva 0201 skhemyi v2 i plan iz pyatnadcati rabot. Pervaya zapisj osnovana na iskhodnom kommite `11f7b8d8deb471e380c9d091552f91b361a3338a` i doslovnoj komande v `32cac61b3e90023ccfb854b5311fc0e4c37865d4`. Rezhim razovyij otnositsya k ogranichennomu obyyomu 0201, postoyannaya FUMA ne zavershayetsya. Priyomki pustyi; nyineshniye v3-zapuski ne podmenyayut trebuyemuyu budusjhuyu priyomku v4. Sleduyusjhij etap sokhranit predmetnyiye originalyi dlya 0154, 0165 i chetyiryokh pozdnikh napravlenij do ikh priyoma.

Matematicheskaya zadacha zavershila prinyatiye pervogo plana kommitom `b762bd0cb77fdbcc418141a1f33800a7bdb630a6`, roditelj `1a51647b7339aad3760ed09857063ccae791659a`, derevo `1b065e4463e1246375df0aed9799f3ccd459cd35`; publikaciya i chistota podtverzhdenyi ispolnitelem i koordinatorom. Polnyij dopusk: 24 iz 24, 841,914 s vnutri zapuska i 841,984153042 s v obyortke; UUID zapuska `f3d82b5e-8dea-45db-900d-79ecec5941f7`. Zakryityij snimok imeyet SHA-256 `91a0803eaa2af30e0a4302180afa831617b1ae7d1f2b28599953b16485dea1cc`. Pokazannyiye vyishe ozhidaniya opisyivayut boleye rannij moment etogo etapa. FUM-STEP-0202 zavershyon v dostavlennoj vetke; 0206 ostayotsya predlozheniyem bez realizacii. Perenos predmetnyikh fajlov i statusov v svoyo derevo sleduyet posle vneshnej popyitki 0207, chtobyi sokhranitj yeyo indeksyi.

Pri tekusjhem vosstanovlenii sobstvennyij pervichnyij JSONL prochitan bez zapisi do granicyi 36976123 bajta, SHA-256 `fe6d44687fa95b57f9211bff389efa2a161003b26b905b7a52b419b9f2d2bbdc`: odin podtverzhdyonnyij chelovecheskij vopros, polnyij snimok, nulevyiye nepolnyij khvost i pozdneye dopisyivaniye. Pervichnyij vopros o chisle derevjyev i pozdniye vidimyiye otvetyi sverenyi; novyikh chelovecheskikh komand v etom istochnike net. Tekusjhiye HEAD, polnyij ref, fizicheskij korenj i UUID povtorno prochitanyi; drugogo pisatelya svoyego dereva ne obnaruzheno.

Koordinator peredal dve ogranichennyiye zadachi daljnejshego profilirovaniya: proyekciya s nezavisimyim manifestom i nakoplennaya stoimostj adresnyikh regressij. Dlya 0176 proyekciya sostavila 199,879 + 91,140 = 291,019 s, dlya 0177 — 234,784 + 94,626 = 329,410 s; trinadcatj regressij sootvetstvenno 384,656 iz 757,007 s i 424,189 iz 808,710 s, maksimaljnaya odinochnaya 144,616 s. Eto raznyiye zapuski i vlozhennyiye granicyi; chisla ne obyyedinyayutsya s matematicheskim dopuskom. Pered vyideleniyem novyikh ID nuzhno sopostavitj dejstvuyusjhiye 0174/0205 i uzhe vyipolnennoye ispravleniye 0147. Eti nablyudeniya ne zaderzhivayut zapuski 0207/0208 i ne oslablyayut nezavisimyij manifest.

## Kontroljnaya tochka

Pervaya zaklyuchiteljnaya svyaznostj kontroljnoj tochki vernula kod 1: `used tools section must include fum-moskovskoye-vremya-rabochej-sessii for canonical MSK time`. Kanonicheskoye vremya byilo polucheno shtatno, no spisok instrumentov zaprosa ne nazyival tochnyij identifikator avtomatizacii. Dobavlena zapisj susjhestvuyusjhego instrumenta so ssyilkoj i sposobom proverki versii; kod i postanovka ne menyalisj. Eto read-only-proverka kontroljnoj tochki vne mashinnogo bloka po 000188; yeyo polnaya dliteljnostj ne izmerena. Posle ispravleniya povtoryayetsya toljko zaklyuchiteljnaya svyaznostj. Proyavleniye vklyuchayetsya v ostavshuyusya sverku diagnostiki 0201.

Vosemj pryamyikh proverok zavershilisj uspeshno: integracionnyiye scenarii paketa i grafa, postroyeniye i validaciya reyestra, vosstanovleniye priyoma, pokryitiye pravil, mashinnyiye puti i sobstvennyij reyestr obyazateljstv. Validator dekompozicii podtverdil 221 pravilo i 11 tem; resheniye prodolzheniya — «prodolzhitj» s nezavershyonnyim obyazateljstvom 0201. Tekusjhij otchyot ostayotsya otkryityim kontroljnyim snimkom bez finaljnoj priyomki.

Promezhutochnyij kommit sokhranyayet susjhestvuyusjheye pokoleniye proyekcii iz `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`: SHA-256 manifesta `cc02a0482eeddea16d44b9049b9f062dc9004f3c09f97b47c9b71c288b7dde98`, khyesh plana `e635e8b9bb6abc57e66c2d6e4afe5d8b6825cd0dda559d3e81da5d562015d668`, khyesh iskhodnogo inventarya `544a1e4a110118a3a9e8957b50a3c4a8330380136ef524186f0892861bf62ff2`. Ono otstayot ot novyikh kanonicheskikh fajlov i ne yavlyayetsya ikh priyomkoj. Polnaya peresborka i nezavisimyij manifest ostayutsya obyazateljnyimi dlya finaljnogo rezuljtata 0201.

Posle kommita pervyim zavershayetsya zakrepleniye i yedinstvennaya vneshnyaya popyitka 0207. Zatem novyij etap prinimayet 0208, predmetnuyu matematicheskuyu postavku, susjhestvuyusjhiye 0154/0165, chetyire pozdnikh predmetnyikh utochneniya i diagnosticheskiye ostatki. Ustojchivyij konechnyij spisok sokhranyon v [plane prodolzheniya](materialyi/planyi/prodolzheniye.json); konechnoye obyazateljstvo ne pogasheno.

## Istochniki

- [Postavka vosstanovleniya negotovogo priyoma](https://github.com/fum-lab/fum/blob/17ef8a59fa3c67a73e54c2348189afcb10849585/Журнал/2026-09-11_06-14-42_MSK_восстанавливать-неготовый-приём/отчёт.md).
- [Prinyatyij matematicheskij plan i polnyij dopusk](https://github.com/fum-lab/fum/blob/b762bd0cb77fdbcc418141a1f33800a7bdb630a6/Журнал/2026-09-11_06-05-48_MSK_принять-план-математического-направления/отчёт.md).

- [iskhodnyij zapros](zapros.md)
- [Postavka paketnoj komandyi](https://github.com/fum-lab/fum/blob/4779f4d541a78effad2679bac1ed3a7e4f285403/Журнал/2026-09-11_05-17-24_MSK_выпускать-пакет-диагностики/отчёт.md).
- [Postavka neobyazateljnogo grafa proyekcii](https://github.com/fum-lab/fum/blob/7acc2de8ca1dcbefd82c16faecd1c31bdfa6e648/Журнал/2026-09-11_05-35-51_MSK_сохранить-ссылку-на-необязательный-граф-в-проекции/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:11:55 MSK -->
<!-- content-sha256: sha256:c821499f1e28d8d9957085161f89cf886a8304727366d3bc3227d5d5c118639f -->
<!-- FUM-MD-RECENCY:END -->
