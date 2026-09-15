# Sovmestnaya klassifikaciya ostatka obyyavlenij

Obsjhij ostatok43091 polnostjyu svyazan s istoricheskim massivom43163 cherez sokhranyonnyiye promezhutochnyiye inventari. Novyij neobosnovannyij ostatok soglasovannogo izmeneniya raven nulyu. Istoricheskiye latinskiye obyyavleniya sokhranyayutsya kak ogranichennaya granica migracii; perevod vsego FUM zavershyonnyim ne obyyavlyayetsya.

| Granica                | Python | Swift | Mermaid | Vsego |
| ---------------------- | ------ | ----- | ------- | ----- |
| Istoricheskaya436909     | 16110  | 26593 | 460     | 43163 |
| Promezhutochnaya          | 16667  | 26673 | 460     | 43800 |
| Sobstvennaya28ae        | 16628  | 26076 | 460     | 43164 |
| Obyyedinyonnaya81a + cf64 | 16555  | 26076 | 460     | 43091 |

## Polnota i iskhodnyiye bajtyi

[Istoricheskoye vosproizvedeniye](vosproizvedeniye-istoricheskogo-inventarya.json) vernulo tochnyij SHA546e604159370f81e9c0a5e68f572d68cf245852b7a1de7d3cc4e76e1b6a746b, a ne toljko sovpavsheye chislo. [Istoricheskij manifest](istoricheskij-vkhod-manifest.json) zakreplyayet1819Gitblobs. [Obsjhij manifest momenta skanirovaniya](obsjhij-inventarj-vkhodyi.json) zakreplyayet2134vkhoda,vklyuchaya1806nulevyikh. Yego iskhodnyiye SHA opisyivayut imenno vyipolnennyij process; posleduyusjhiye dokumentacionnyiye izmeneniya rassmatrivayutsya otdeljno.

[Polnyiye deljtyi](polnyiye-deljtyi-inventarya.json) ispoljzuyut muljtimnozhestva klyuchej «putj, yazyik, vid, imya, stroka, stolbec», sokhranyayut povtornyiye zapisi i ne svodyat odinakovyiye imena v mnozhestvo. Posledovateljnyiye perekhodyi imeyut udaleniya/dobavleniya3029/3666,1210/574 i387/314. Tochnyiye obsjhiye chasti ravnyi40134,42590 i42777 sootvetstvenno. Vse izmenyonnyiye klyuchi sokhranenyi; obsjhiye vosstanavlivayutsya iz zakreplyonnyikh vkhodov.

Tri oblasti ispoljzuyutsya s prioritetom sobstvennyiye43 → Python0173-22 → Swift124 bez sobstvennyikh43. Peresecheniye sobstvennyikh43 iSwift124 sostavlyayet7putej; ostaljnyiye peresecheniya pustyi. Eti spiski ne summiruyutsya kak neperesekayusjhiyesya.

## Istoricheskij perekhod k43800

Bez koordinat sobstvennaya oblastj dobavila120 zapisej, unasledovannyiye22Python-puti dali−1/+515, ostaljnyiye puti Swift-klassifikacii−4/+7. Vne etikh oblastej izmeneniya imyon, vidov i kratnosti otsutstvuyut. Eto vnovj vyichislennyiye pokazateli sravneniya sokhranyonnyikh massivov, a ne prezhneye utverzhdeniye o gotovnosti.

Chetyire ischeznuvshiye Swift-zapisi AutomationAndSynchronization.swift — inputHash×1,argument×2,separator×1 — otnosyatsya k prezhnemu izmeneniyu ispolneniya do tekusjhej klassifikacii. Semj promezhutochnyikh lozhnyikh zapisej return,try,contains×2,count×2,for zatem vkhodyat v udalyonnyiye lozhnyiye roli Swift-klassifikacii. Ikh neljzya poteryatj pri sravnenii toljko pozdnikh granic.

[Koordinatyi vne oblastej](istoricheskiye-koordinatyi-vne-oblastej.json) soderzhat1825par v17putyakh. Dlya1817par podtverzhdeno ravenstvo iskhodnyikh strok Git; dlya vosjmi — izmenyonnoye vyirazheniye pri tom zhe nablyudayemom imeni i vide. Posledniye vklyuchayut SCRIPT_PATH/SCRIPTS_DIR v testakh publikacionnoj chistotyi, target/representation/stage v planovom reyestre i others v strukture zaprosov. Ravenstvo imeni ne vyidayotsya za neizmennostj vyirazheniya; SHA obeikh iskhodnyikh strok i oba blob sokhranenyi; bukvaljnyiye stroki vosproizvodyatsya po ukazannyim koordinatam bez publikacii povtornyikh kopij testovyikh putej.

Pyatnadcatj funkcij testa bratislavskoj proyekcii v43800 imeyut koordinatyi roditelya c93, kommita2e01e5dc9a130ea0fb2f6c10514d7db56817361b, blob94e5ff20a0f26630c5048ec9751f3e040426e77c. Kommitc93 dobavil vyishe nikh chetyire stroki CJS-putej i stroku rasshireniya.cjs; blob6698e5bfd89a7267ab53a5517e59294f694b0279. Poetomu sleduyusjhij perekhod dayot dopolniteljnyiye−15/+15 toljko koordinat, s tochnyimi neizmennyimi strokami obyyavlenij.

## Sobstvennaya oblastj i Swift

Iz120 sobstvennyikh dobavlenij predyidusjhaya migraciya snyala67:39Python i28Swift. Konechnyiye53 zapisi tochnyim muljtimnozhestvom sovpali s [sokhranyonnyimi vneshnimi interfejsami](../../2026-09-14_21-11-44_MSK_sveritj-obsjhuyu-granicu-priyomki/materialyi/klassifikaciya-deljtyi-svift.json). Povtoreniye etikh53 v dvukh materialakh ne uvelichivayet ikh kolichestvo. ChetyireCJS-scenariya i pyatj podderzhannyikh.js/.cjs vkhodov vkhodyat v polnyij okhvat s nulevyim ostatkom.

Globaljnaya Swift-deljta−1156/+559 polnostjyu sovpala s toj zhe sokhranyonnoj klassifikaciyej, vklyuchaya kratnostj i koordinatyi. Vne sobstvennoj oblasti−1128/+559:1112lozhnyikh rolej,14dubliruyusjhikh rolej i dva perenosa roli;557dejstviteljnyikh raneye skryityikh privyazok dokazanyi istoricheskimi bajtami436909, yesjhyo dva dobavleniya sootvetstvuyut perenosu roli. Pri sliyanii vesjSwift26076 iMermaid460 ostalisj tochnyimi muljtimnozhestvami predyidusjhego massiva43164.

## Unasledovannyij Python i fakticheskij styik

Python16628 +312 −385 =16555. Tochno neizmennyi16241zapisj; dopolniteljno sokhranenyi dva perenesyonnyikhPopen, chto dayot387udalenij/314dobavlenij polnogo klyucha. Vse312dobavlenij sovpali s [effektom skanera](../../2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/materialyi/effekt-python-skanera.json). Ikh [proiskhozhdeniye](../../2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/materialyi/proiskhozhdeniye-rasshireniya-python.json) svyazyivayet307s436909 i pyatj s zasjhisjhyonnyim before bazyic93. Pyatj uzhe vkhodyat v121istoricheskuyu zapisj before i ne dobavlyayutsya k nej vtoroj raz.

[Vse385perevodov](popozicionnyiye-perevodyi-python.json) proverenyi kornem po staromu AST, diapazonu tokena, posledovateljnyim khyeshirovannyim pravkam i yedinstvennomu novomu AST-uzlu pri tochnyikh konechnyikh bajtakh. Eto68funkcij,126parametrov,178privyazok,13atributov;340pervyikh planovyikh privyazok,odna mezhfajlovaya svyazj i44privyazki plana zhivyikh izmeritelej. Dve stroki podklyucheniya istoricheskogo adaptera obyyasnyayutPopen51/59→53/61. Neobyyasnyonnyikh zapisej net.

Dvadcatj shestj snyatyikh vneshnikhAST-rolej iz otdeljnogo sravneniya0173 otsutstvovali v nashem massive43164 i povtorno ne vyichitayutsya. Raznica16555protiv16594v otdeljnom effekte0173 ravna39: konechnyij JSON-filjtr snimayet30zapisej na tekh zhe bajtakh dvukh fajlov, yesjhyo devyatj uzhe byili perevedenyi v tryokh sobstvennyikh iskhodnikakh. [Obsjhaya mashinnaya svodka](sovmestnaya-klassifikaciya-ostatka.json) perechislyayet eti puti i khyeshi. Vse semj dopolniteljnyikh Python-putej obsjhego vkhoda imeyut nulevoj ostatok.

## Granica priyomki

Smyislovaya klassifikaciya razreshayet shtatnoye obnovleniye tochnogo snimka. Yego proverka, yavno vyibrannyij polnyij CLI-profilj, zakryitiye otchyota i finaljnoye pokoleniye proyekcii ostayutsya samostoyateljnyimi obyazateljnyimi dejstviyami. Klassifikaciya ne obyyavlyayet ikh uzhe vyipolnennyimi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 23:50:17 MSK -->
<!-- content-sha256: sha256:86ad7772876ab8bf2264e9f4d4dc0073707f9dda23777aedc989046aa1a420e1 -->
<!-- FUM-MD-RECENCY:END -->
