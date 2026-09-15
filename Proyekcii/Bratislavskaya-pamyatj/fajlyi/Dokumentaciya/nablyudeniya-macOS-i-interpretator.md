# Nablyudeniya macOS i interpretator operatorov

FUMA poluchayet sobyitiya i vyipolnyayet obrasjheniya k macOS cherez sloj Swift-adapterov. Sloj peredayot tipizirovannyiye vkhodyi vnutrennemu API interpretatora strukturiruyusjhikh operatorov. Graf operatorov prevrasjhayet nablyudeniya v znachimyiye signalyi, vyibirayet reakciyu i formiruyet zapros sleduyusjhego dejstviya. Nablyudeniye sistemyi, yego interpretaciya i rezuljtat dejstviya sokhranyayutsya razdeljno.

Dokument zadayot prinyatyij kontrakt razrabotki. Polnyij okhvat API macOS i podklyucheniye etogo sloya k dejstvuyusjhemu interpretatoru yesjhyo ne podtverzhdenyi. Tekusjhij lokaljnyij detektor byudzheta vyivoda yavlyayetsya ogranichennyim pervyim uchastkom; yego nalichiye ne dokazyivayet nablyudeniya za vsemi instrumentami Codex.

## Pervyij skvoznoj scenarij

Swift-adapter nablyudayet poluchennyij vyivod processa i peredayot yego razmer s yedinicej «bajtyi», identichnostjyu istochnika i granicami izmereniya. Operatoryi sravnivayut razmer s yavno zadannyim byudzhetom. Pri prevyishenii voznikayet signal pereraskhoda; reakciya ispoljzuyet susjhestvuyusjheye kompaktnoye chteniye. Polnyij iskhodnyij rezuljtat sokhranyayetsya, a ogranichennoye predstavleniye soderzhit ukazateli na originalyi i yavnuyu nepolnotu vyibrannoj stranicyi.

Proverka sravnivayet odinakovyiye prinyatyiye vkhodyi, vyibrannoye dejstviye, sokhrannostj originalov i fakticheskij razmer rezuljtata. Bajtyi ne obyyavlyayutsya tokenami modeli. Nedostupnyij schyotchik ostayotsya neizvestnyim; propusjhennoye nablyudeniye ne zamenyayetsya nulyom.

## Obyazateljnaya pamyatj obrasjhenij

Kazhdyij vyizov i kazhdoye nablyudeniye FUMA cherez etot sloj zapisyivayutsya na postoyannyij nositelj. Dlya vyizova sokhranyayutsya identichnostj, zaproshennaya operaciya, prinyatyiye parametryi, iniciirovavshij operator i versiya grafa; zatem otdeljno fiksiruyutsya rezuljtat, oshibka ili otmena i monotonnaya dliteljnostj. Asinkhronnoye sobyitiye svyazyivayetsya s istochnikom, podpiskoj i poryadkom priyoma. Zapros dejstviya i podtverzhdyonnoye ispolneniye ne smeshivayutsya.

Pered vneshnim dejstviyem sokhranyayetsya namereniye. Yesli posle sboya rezuljtata net, vyizov ostayotsya nezavershyonnyim: otsutstviye zapisi ne dokazyivayet ni uspekha, ni togo, chto dejstviye ne proizoshlo. Povtor vneshnego dejstviya trebuyet opredeleniya bezopasnogo sposoba proverki yego fakticheskogo iskhoda.

Proiskhozhdeniye pozvolyayet svyazatj iskhodnoye nablyudeniye, putj operatorov, sformirovannyij signal i posleduyusjheye dejstviye. Povtornyij import ne sozdayot vtoroye sobyitiye, a realjnyiye povtornyiye obrasjheniya sokhranyayutsya otdeljnyimi ekzemplyarami. Izmeneniye poryadka konkurentnyikh vkhodov fiksiruyetsya kak chastj prinyatogo potoka, a ne skryivayetsya pod zayavleniyem determinizma.

## Vosproizvedeniye i khraneniye

Povtornoye ispolneniye grafa poluchayet sokhranyonnyiye vkhodyi i rezuljtatyi vneshnikh obrasjhenij vmeste s versiyami operatorov i obyyavlennyimi zavisimostyami. Chteniye zhivogo vremeni, sluchajnosti i tekusjhego sostoyaniya macOS ne podmenyayet eti vkhodyi. Vosproizvedeniye nablyudenij samo po sebe ne razreshayet povtoritj vneshniye pobochnyiye effektyi.

Privatnyiye nablyudeniya khranyatsya v lokaljnoj pamyati FUMA. Otkryityij repozitorij poluchayet toljko publikacionno dopustimyiye materialyi. Dlya krupnyikh binarnyikh dannyikh sokhranyayutsya ssyilki i kontroljnyiye summyi fakticheskogo soderzhimogo; ikh razmesjheniye sleduyet prinyatomu sposobu khraneniya vne Git. Khyesh bez dostupnogo soderzhimogo ne oznachayet polnocennogo vosproizvedeniya.

Nuzhno opredelitj proveryayemuyu granicu sluzhebnyikh operacij samogo zhurnala, inache zapisj kazhdogo sobstvennogo sistemnogo vyizova porozhdayet beskonechnuyu rekursiyu. Eta granica, garantii dolgovechnosti, povedeniye pri zapolnenii diska i uchyot poteryannyikh vkhodov dolzhnyi byitj yavno opisanyi i proverenyi do zayavleniya polnogo pokryitiya. Vnutrenniye obrasjheniya zakryityikh sistemnyikh frameworks neljzya obyyavlyatj nablyudyonnyimi toljko potomu, chto zapisan vkhod v publichnyij API.

## Priyomka pervogo uchastka

- Odin sokhranyonnyij vvod dayot odinakovyij signal i vyibor reakcii pri tekh zhe operatorakh i byudzhete.
- Prevyisheniye byudzheta vyizyivayet kompaktnoye chteniye bez vtorogo porucheniya cheloveka; neumestivshijsya rezuljtat vozvrasjhayet yavnyij otkaz bez skryitogo usecheniya.
- Sboj API, otmena, povtornoye sobyitiye, nedostupnostj istochnika i nezavershyonnyij vyizov razlichayutsya v pamyati.
- Profilj izmeryayet stoimostj samogo nablyudeniya i zhurnalirovaniya; podavleniye podrobnogo predstavleniya ne stirayet pervichnyiye dannyiye.
- Polnota pokryitiya podtverzhdayetsya perechnem podklyuchyonnyikh adapterov i proverennyimi granicami; otsutstvuyusjhiye istochniki perechislyayutsya yavno.

## Yazyik operatorov i diagnosticheskij interfejs

Yazyik opisaniya strukturiruyusjhikh operatorov dolzhen vyirazhatj tipyi vkhodov i vyikhodov, kompoziciyu, yavnoye sostoyaniye, poryadok obrabotki i vneshniye effektyi. Podsistema GUI opisyivayetsya tem zhe mekhanizmom: sobyitiya vvoda izmenyayut sostoyaniye interfejsa, operatoryi rasschityivayut komponovku i formiruyut komandyi otrisovki Metal. Konkretnyij sintaksis i ispolnyayemyij graf yesjhyo predstoit razrabotatj i proveritj.

V pervom diagnosticheskom scenarii Swift-chastj FUMA zapuskayet Codex CLI. Parametryi zapuska, peredannyiye soobsjheniya, stdout, stderr, dostupnyiye strukturirovannyiye sobyitiya i zaversheniye processa sokhranyayutsya do sokrasjheniya predstavleniya. Operatoryi perevodyat nablyudeniya v sostoyaniye diagnosticheskogo interfejsa, zatem v komandyi Metal. Polnyij potok sokhranyayetsya otdeljno ot tekusjhego okna prosmotra; bajtovyij byudzhet predstavleniya ne zamenyayet schyotchik tokenov modeli.

Otobrazhayutsya nablyudayemyiye zadacha, dejstviya, oshibki i dostupnyiye pokazateli resursov. Nedostupnyiye vnutrenniye sostoyaniya CLI pomechayutsya neizvestnyimi. Dlya dvukh nezavisimyikh potokov sokhranyayutsya istochnik i nablyudyonnyij poryadok chteniya; eto ne dokazateljstvo tochnogo obsjhego poryadka zapisi vnutri processa.

Priyomka pervogo skvoznogo sreza sravnivayet sostoyaniye interfejsa i komandyi otrisovki na odinakovom sokhranyonnom potoke pri zakreplyonnyikh versiyakh operatorov. Povtornoye vosproizvedeniye ne zapuskayet CLI ili yego instrumentyi zanovo. Polnoye sovpadeniye pikselej na raznyikh ustrojstvakh Metal trebuyet otdeljnogo proverennogo kontrakta; ono ne sleduyet toljko iz ravenstva komand.

## Nablyudayemostj i nastrojka avtomatizacij dlya LLM

LLM poluchayet predstavleniye o tom, chto vyipolnyayetsya avtomaticheski i pochemu: identichnostj i versiya opredeleniya, pravilo zapuska, proiskhozhdeniye vkhodov, fakticheski projdennyiye operatoryi, tekusjheye sostoyaniye, rezuljtatyi i oshibki. Deklaraciya avtomatizacii sama po sebe ne dokazyivayet yeyo zapusk. Sostoyaniye stroitsya iz nablyudenij; nepolnota i ustarevaniye ostayutsya vidimyimi.

Nastrojka vyirazhayetsya yazyikom opisaniya strukturiruyusjhikh operatorov. Predlagayemoye izmeneniye, proverennoye opredeleniye i fakticheski primenyonnaya versiya razlichayutsya. Trassa posleduyusjhego zapuska ssyilayetsya na primenyonnuyu versiyu; vosproizvedeniye ispoljzuyet sokhranyonnuyu versiyu i ne podmenyayet yeyo tekusjhej nastrojkoj.

Dlya ekonomii konteksta snachala vyidayutsya kompaktnoye sostoyaniye i znachimyiye izmeneniya s adresami polnoj trassyi. LLM mozhet zaprositj nuzhnyij uchastok s proiskhozhdeniyem; sokrasjhyonnoye predstavleniye ne udalyayet pervichnyiye nablyudeniya. Dostupnostj takogo kontura i primeneniye nastroyek poka yavlyayutsya trebovaniyami, a ne realizovannyimi vozmozhnostyami tekusjhego CLI.

## API Codex CLI v sisteme operatorov

Operatornyij adapter predostavlyayet komandam Codex CLI tipizirovannyiye vkhodyi i svyazyivayet otvetyi, sobyitiya i oshibki s identichnostjyu vyizova i zadachi. Parametryi, versiya protokola, versiya opredeleniya operatora i nablyudyonnyij iskhod sokhranyayutsya v pamyati. Inventarj realjno dostupnyikh operacij, ikh sovmestimostj i sposob podklyucheniya utochnyayutsya po ispoljzuyemoj postavke CLI.

Po posleduyusjhemu utochneniyu Swift-obolochka FUMA okhvatyivayet sami obrasjheniya, iniciiruyemyiye Codex CLI: oba potoka — k API modeli i k instrumentam i OS. Dlya kazhdogo nuzhnyi proveryayemyiye tochki podklyucheniya, zapros, iskhod i svyazj s operatornyim grafom. Podklyucheniye protokola upravleniya CLI ili zakhvat vyivoda processa sami po sebe ne dokazyivayut takogo okhvata. Reyestr pokryitiya perechislyayet kontroliruyemyiye operacii i izvestnyiye nepodklyuchyonnyiye puti.

Opisaniye operatora otdelyayet namereniye vyizova ot podtverzhdyonnogo rezuljtata. Neizvestnyij iskhod, poteryannaya svyazj i otmena vidimyi; povtor s vneshnimi effektami trebuyet yavnogo resheniya. Rezhim vosproizvedeniya podayot sokhranyonnyiye otvetyi v graf bez obrasjheniya k zhivomu Codex. Diagnosticheskij interfejs i kompaktnyij kontekst ispoljzuyut te zhe nablyudeniya i svyazi proiskhozhdeniya. Eto kontrakt sleduyusjhego adaptera, yego rabotosposobnostj yesjhyo ne podtverzhdena.

## Istochniki

- [Utochneniye ob oboikh potokakh obrasjhenij CLI](../Zhurnal/2026-09-15_15-57-32_MSK_utochnitj-granicyi-Swift-obolochki/zapros.md).
- [Komandyi o sloye Swift, interpretatore i obyazateljnoj pamyati](../Zhurnal/2026-09-15_15-13-26_MSK_zakrepitj-reakciyu-na-pereraskhod-konteksta/zapros.md).
- [Predyidusjhaya proverka kompaktnogo chteniya](../Zhurnal/2026-09-15_13-00-53_MSK_ispravitj-sboj-finaljnoj-proyekcii/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 16:01:28 MSK -->
<!-- content-sha256: sha256:8f36a5a73a80f8cd5e46b5ac470a9da75d6e1b7b444db9d866a529dc5d39fa71 -->
<!-- FUM-MD-RECENCY:END -->
