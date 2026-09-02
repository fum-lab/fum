# Nablyudateljskaya otnositeljnostj informacionnyikh sistem

[FUM](../Glossarij/FUM.md) fiksiruyet [nablyudateljskuyu otnositeljnostj FUM](../Glossarij/nablyudateljskaya-otnositeljnostj-FUM.md) kak issledovateljskij i arkhitekturnyij princip: lyubuyu informacionnuyu sistemu s nablyudatelem nuzhno opisyivatj vmeste s tem, dlya kogo ona nablyudayema, cherez kakoj interfejs ona predyyavlena i kakiye preobrazovaniya nuzhnyi, chtobyi svyazatj eto opisaniye s drugimi nablyudatelyami.

Etot princip beryot iz obsjhej teorii otnositeljnosti ne gotovyiye fizicheskiye uravneniya, a boleye obsjhij urok: opisaniye sistemyi ne dolzhno pritvoryatjsya nezavisimyim ot formyi nablyudeniya. V fizike nablyudatelj i sistema koordinat ne yavlyayutsya dekorativnoj pripiskoj k miru. V FUM analogichno: [interfejs FUM-uzla](../Glossarij/interfejs-FUM-uzla.md), sostoyaniye, dejstviye, oshibka, trassa ili rezuljtat ne schitayutsya polnyimi, yesli v nikh ne ukazan profilj [nablyudatelya FUM](../Glossarij/nablyudatelj-FUM.md).

## Princip

Informacionnaya sistema s nablyudatelem opisyivayetsya ne toljko svoim vnutrennim sostoyaniyem, no i sposobom predyyavleniya etogo sostoyaniya. Dlya FUM eto oznachayet, chto ustojchivoye opisaniye dolzhno fiksirovatj:

- nablyudayemuyu sistemu ili sloj;
- profilj nablyudatelya: chelovek, LLM, CPU, GPU, servis, poduzel ili sostavnoj uzel;
- dostupnyiye nablyudatelyu signalyi, operacii i ogranicheniya dostupa;
- sistemu koordinat opisaniya: ekran, tekst, fajl, tenzor, trassu, API, zhurnal, graf pamyati ili drugoj format;
- preobrazovaniya mezhdu opisaniyami dlya raznyikh nablyudatelej;
- invariantyi, kotoryiye dolzhnyi sokhranyatjsya pri preobrazovanii;
- poteri nablyudayemosti, neodnoznachnosti i otkaznyiye rezhimyi;
- dostupnyij putj vozvrata k boleye polnomu istochniku ili yavnuyu otmetku, pochemu takoj perekhod nevozmozhen.

Poetomu fraza "sistema izmenilasj" nepolna bez voprosa "dlya kakogo nablyudatelya, na kakom urovne i v kakom predstavlenii eto izmeneniye vidno". Dlya cheloveka izmeneniye mozhet byitj novyim abzacem v dokumente; dlya Git - diff-om strok; dlya LLM - izmeneniyem konteksta i ssyilok; dlya proverki svyaznosti - novyim sostoyaniyem grafa trebovanij; dlya nizhelezhasjhego ispolneniya - posledovateljnostjyu fajlovyikh operacij.

## Invariantyi i preobrazovaniya

Raznyiye nablyudateli ne obyazanyi videtj odnu i tu zhe formu. No [pamyatj FUM](../Glossarij/pamyatj-FUM.md) dolzhna khranitj svyazj mezhdu formami, chtobyi smyisl ne ischezal pri perekhode mezhdu sloyami.

Naprimer, odin i tot zhe rezuljtat mozhet susjhestvovatj kak chelovekochitayemyij tekst, Markdown-fajl, Git-commit, zapisj v zhurnale, nabor ssyilok na istochniki, proverka avtomatizacii i sostoyaniye indeksa. Eti formyi ne tozhdestvennyi, no mezhdu nimi dolzhnyi sokhranyatjsya invariantyi: istochnik trebovaniya, avtorizovannoye namereniye, zatronutyiye fajlyi, proverka, ogranicheniya primenimosti i proiskhozhdeniye rezuljtata.

Preobrazovaniya mogut byitj neobratimyimi. Skrinshot interfejsa teryayet chastj strukturyi DOM ili fajlovoj sistemyi; kratkoye opisaniye teryayet podrobnostj trassyi; mashinnyij JSON mozhet byitj tochen dlya servisa, no beden dlya cheloveka. Nablyudateljskaya otnositeljnostj trebuyet ne ustranyatj takiye poteri lyuboj cenoj, a yavno otmechatj ikh v interfejse, zhurnale, istochnike ili pasporte uzla.

Klyuchevoye trebovaniye k takim perekhodam - ne podmenyatj istochnik proizvodnoj formoj. Yesli rezuljtat predyyavlen kak skrinshot, svodka, kartochka, indeks, zhurnal ili mashinnyij sloj, ryadom dolzhen sokhranyatjsya perekhod k boleye polnoj informacii: iskhodnomu fajlu, DOM-snimku, trasse, API-otvetu, papke istochnika, zhurnalu zapuska, commit-u ili nizhelezhasjhemu sloyu pamyati. Kogda takoj perekhod tekhnicheski nevozmozhen, publikacionno nedopustim ili poteryan na granice nablyudeniya, eto fiksiruyetsya kak granichnyij sluchaj s ukazaniyem kharaktera poteri.

[Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md) zakreplyayet eto trebovaniye dlya tekusjhej fiksacii v pamyati dokumentacionnogo prototipa kak odnu napravlennuyu zapisj: tochnyiye storonyi perekhoda, sploshnuyu kartu signalov, proverennyiye invariantyi, yavnyiye poteri, vyivod ob obratimosti i otdeljno proverennyij marshrut k iskhodnomu sloyu. Predstavleniye togo zhe kontrakta v budusjhem runtime opredelyayetsya otdeljno.

## Informacionnyiye gorizontyi

Svyazj [FUM](../Glossarij/FUM.md) s obsjhej teoriyej otnositeljnosti mozhno utochnitj cherez motiv rasprostraneniya informacii. Obsjhaya teoriya otnositeljnosti vazhna dlya FUM ne toljko kak obraz otnositeljnosti nablyudatelya, no i kak predeljnaya geometricheskaya vizualizaciya togo, kakiye sobyitiya mogut prichinno vliyatj drug na druga i kakiye oblasti ostayutsya za gorizontom dostupnoj obratnoj svyazi.

Eta svyazj mozhet okazatjsya siljneye prostoj krasivoj analogii. Na kosmologicheskikh masshtabakh razvitiya [FUM](../Glossarij/FUM.md), gde uzlyi razdelenyi predeljnoj skorostjyu rasprostraneniya signalov, zaderzhkami svyazi, avtonomnyimi proizvodstvennyimi konturami i neobratimyim [fizicheskim dejstviyem](../Glossarij/fizicheskoye-dejstviye-FUM.md), obsjhaya teoriya otnositeljnosti zadayot kandidatnyij yazyik dlya sistemyi ogranichenij: prichinnoj svyaznosti, lokaljnosti nablyudatelej, gorizontov obratnoj svyazi, sokhranyayemyikh invariantov i oblastej, gde polnaya sinkhronizaciya nevozmozhna. V takom statuse ona stanovitsya ne ukrasheniyem opisaniya, a [gipotezoj FUM](../Glossarij/gipoteza-FUM.md) o svyazannoj sisteme sootvetstvij, kotoruyu nuzhno otdeljno proveryatj v pasporte fizicheskikh analogij.

Ta zhe blizostj proyavlyayetsya ne toljko na daljnem kosmologicheskom gorizonte, no i na blizhnem inzhenernom masshtabe. V proyektirovanii mikrochipov na vyisokikh chastotakh konechnaya skorostj rasprostraneniya elektromagnitnogo signala, zaderzhki v mezhsoyedineniyakh, taktovyiye domenyi i nevozmozhnostj mgnovennoj globaljnoj sinkhronizacii stanovyatsya prakticheskimi ogranicheniyami. Dlya [FUM](../Glossarij/FUM.md) eto dayot blizhnij inzhenernyij primer toj zhe disciplinyi: [kremniyevyij substrat](../Glossarij/kremniyevyij-substrat-FUM.md) dolzhen opisyivatjsya kak fizicheski raspredelyonnaya sistema s lokaljnyimi nablyudatelyami, zaderzhkami, oblastyami soglasovannosti i granicami prichinnoj svyaznosti, a ne kak abstraktnaya mgnovennaya vyichisliteljnaya poverkhnostj.

Eto utochneniye ne utverzhdayet, chto gravitacionnyiye effektyi obsjhej teorii otnositeljnosti pryamo susjhestvennyi dlya obyichnogo mikrochipa. Vazhneye perenos proveryayemogo ogranicheniya: signal imeyet konechnuyu skorostj v srede, sostoyaniye ne stanovitsya dostupnyim vsem chastyam sistemyi odnovremenno, a znachit arkhitektura vyichisliteljnogo nositelya FUM dolzhna uchityivatj lokaljnostj, vremya rasprostraneniya i cenu sinkhronizacii uzhe na apparatnom urovne.

V etoj analogii vneshnij kosmologicheskij gorizont pokazyivayet granicu oblasti, iz kotoroj nablyudatelj uzhe ne mozhet poluchitj polnyij signal. Gorizont chyornoj dyiryi dayot drugoj obraz: vnutrennyaya podsistema mozhet prodolzhatj vliyatj na vneshneye opisaniye toljko cherez grubyiye sokhranyayemyiye parametryi, takiye kak massa, zaryad i spin, togda kak polnaya vnutrennyaya konfiguraciya dlya vneshnego nablyudatelya nedostupna.

Dlya FUM eto ne fizicheskoye utverzhdeniye o chyornyikh dyirakh i ne perenos uravnenij obsjhej teorii otnositeljnosti v arkhitekturu. Eto disciplina opisaniya informacionnyikh sistem: yesli v sostavnom [FUM-uzle](../Glossarij/FUM-uzel.md) yestj vnutrennyaya podsistema bez polnocennoj obratnoj svyazi, yeyo nuzhno opisyivatj kak oblastj s gorizontom nablyudayemosti. V takom opisanii fiksiruyutsya dostupnyiye vneshniye parametryi, poteryannyiye ili nedostupnyiye sostoyaniya, dopustimyiye kanalyi obratnoj svyazi, urovenj uverennosti i usloviya, pri kotoryikh granica mozhet izmenitjsya.

Etot motiv svyazyivayet nablyudateljskuyu otnositeljnostj s dostupom k [vnutrennim sostoyaniyam](../Glossarij/vnutrenneye-sostoyaniye.md) i [vnutrennimi modelyami drugikh uzlov](../Glossarij/vnutrennyaya-modelj-drugogo-uzla.md). FUM dolzhen razlichatj polnoye vnutrenneye sostoyaniye, chastichnuyu proyekciyu, agregirovannyij vneshnij parametr i neizvestnuyu oblastj. Osobenno vazhno ne vyidavatj agregirovannoye opisaniye za polnyij dostup: gorizont nablyudayemosti dolzhen byitj chastjyu modeli, a ne skryityim provalom v nej.

### Gorizontnaya struktura agenta

[Gorizont agenta FUM](../Glossarij/gorizont-agenta-FUM.md) otnositsya ne k odnoj universaljnoj granice, a k opredelyonnomu vidu dostupnosti. Kak minimum nuzhno razlichatj gorizont nablyudeniya - otkuda signal mozhet izmenitj sostoyaniye agenta - i gorizont dejstviya - gde sostoyaniye agenta mozhet prichinno izmenitj sredu. Oni mogut ne sovpadatj: uzel sposoben nablyudatj nedostupnuyu dlya dejstviya oblastj ili zapuskatj posledstviya, rezuljtat kotoryikh sam uzhe ne uvidit.

Gorizontyi pamyati, predskazaniya, kommunikacii, koordinacii, nasledovaniya i [lichnosti agenta FUM](../Glossarij/lichnostj-agenta-FUM.md) yavlyayutsya kandidatnoj tipologiyej, a ne gotovyim ischerpyivayusjhim spiskom. Kazhdyij tip dolzhen poluchitj otdeljnyij mekhanizm, napravleniye, oblastj, vremennoj interval, zaderzhku, metriku, profilj nablyudatelya, uverennostj i pravilo izmeneniya. Bez etogo slovo «gorizont» toljko pereimenuyet neizvestnuyu granicu.

Gorizontyi mogut peresekatjsya, rasshiryatjsya instrumentami, suzhatjsya pri otkazakh i razlichatjsya dlya chteniya, zapisi i obratnoj svyazi. Vneshnij instrument, organizaciya ili drugoj agent mogut vkhoditj v rasshirennyij kontur koordinacii dlya konkretnoj zadachi, no eto ne peredayot avtomaticheski ikh vnutrennyuyu oblastj, polnomochiya ili lichnostj rassmatrivayemomu uzlu. Izmeneniye gorizontov mozhet zatragivatj nepreryivnostj agenta; kriterii etoj granicyi vyinesenyi v [otkryityij vopros](../Voprosyi/2026-07-14_01-55-34_MSK_kriterii-agentnosti-i-nepreryivnosti-FUM.md).

## [Okruzhayusjhaya sreda](../Glossarij/okruzhayusjhaya-sreda-FUM.md) kak sinkhronizator

Dlya [FUM](../Glossarij/FUM.md) nablyudateljskaya otnositeljnostj svyazana ne toljko s formoj opisaniya, no i s rabotoj sredyi, v kotoroj nablyudateli i agentyi soglasuyut svoi sostoyaniya. [Okruzhayusjhaya sreda FUM](../Glossarij/okruzhayusjhaya-sreda-FUM.md) sinkhroniziruyet agentov cherez konechnuyu skorostj rasprostraneniya signalov, stolknoveniya, obmen vesjhestvom i energiyej, khimicheskiye svyazi, biologicheskuyu obratnuyu svyazj, socialjnyiye normyi, ekonomicheskiye cenyi, vyichisliteljnyiye protokolyi ili drugiye ogranicheniya urovnya.

Takaya sreda sama mozhet byitj opisana kak agent ili [FUM-uzel](../Glossarij/FUM-uzel.md) sleduyusjhego masshtaba. Vlozhennostj zdesj principialjna: molekula mozhet byitj sredoj dlya atomnyikh vzaimodejstvij i agentom v khimicheskoj reakcii; kletka - sredoj dlya molekulyarnyikh processov i agentom v tkani; chelovek - sredoj dlya kletok i agentom v socialjnoj ili ekonomicheskoj sisteme; ekonomika - sredoj sinkhronizacii mnozhestva chelovecheskikh i organizacionnyikh agentov i agentom v boleye krupnoj civilizacionnoj srede.

V etoj ramke obsjhaya teoriya otnositeljnosti i kvantovaya mekhanika vyistupayut kak dva predeljnyikh sluchaya okruzhayusjhej sredyi. Obsjhaya teoriya otnositeljnosti pokazyivayet predel geometricheskoj i prichinnoj sinkhronizacii na boljshikh masshtabakh: lokaljnostj, gorizontyi, zaderzhki i nevozmozhnostj obsjhego mgnovennogo sostoyaniya. Kvantovaya mekhanika pokazyivayet predel nizkourovnevyikh vzaimodejstvij, gde ustojchivyiye konfiguracii, veroyatnostnyiye perekhodyi i akt nablyudeniya yesjhyo ne otdelenyi ot samoj fizicheskoj sredyi.

Eto ne prevrasjhayet [FUM](../Glossarij/FUM.md) v fizicheskuyu teoriyu. Prakticheskaya poljza formulirovki v drugom: pri perekhode mezhdu fizicheskim, khimicheskim, biologicheskim, nejronnyim, agentskim, socialjnyim i ekonomicheskim urovnyami nuzhno yavno ukazyivatj, kakaya sreda sinkhroniziruyet kakikh agentov, kakiye invariantyi sokhranyayutsya, kakiye sostoyaniya nedostupnyi nablyudatelyu i gde sreda sama stanovitsya nablyudayemyim uzlom sleduyusjhego urovnya.

Otnosheniye agenta i sredyi otnositeljno masshtaba, no ne tavtologichno: sreda mozhet rassmatrivatjsya kak agent sleduyusjhego urovnya toljko pri nalichii sobstvennyikh nablyudayemyikh mekhanizmov koordinacii i podderzhaniya organizacii. Obsjhiye zakonyi, yedinaya prichinnaya istoriya, kosmicheskaya setj ili nakhozhdeniye vnutri odnogo kosmologicheskogo gorizonta ne dokazyivayut [agentnostj FUM](../Glossarij/agentnostj-FUM.md) celogo. Gipoteza ob agentnosti nablyudayemoj Vselennoj trebuyet iskatj obratnyiye svyazi, vosstanovleniye posle vozmusjhenij, pamyatj i otlichimuyu organizaciyu, a takzhe zaraneye ukazyivatj vozmozhnyij otricateljnyij rezuljtat.

## Sledstviya dlya FUM

Dlya arkhitekturyi FUM eto stanovitsya skvoznyim ogranicheniyem. [FUM-uzel](../Glossarij/FUM-uzel.md) neljzya proyektirovatj kak vesjhj, u kotoroj yestj odin "nastoyasjhij" vid i neskoljko vtorichnyikh otobrazhenij. Uzel dolzhen imetj kartu nablyudatelej i preobrazovanij mezhdu ikh predstavleniyami.

[Agentskij cikl](../Glossarij/agentskij-cikl.md) v takom podkhode yavlyayetsya ne toljko posledovateljnostjyu shagov, no i perekhodom mezhdu sistemami nablyudeniya: poljzovateljskoye namereniye, modeljnyij kontekst, fajlovoye izmeneniye, proverka, zhurnal i peredavayemyij rezuljtat dolzhnyi svyazyivatjsya v odnu trassu.

[Modeljnaya sreda](../Glossarij/modeljnaya-sreda.md) dolzhna razlichatj status opisaniya: fakticheskoye nablyudeniye, rekonstrukciyu proshlogo, scenarij budusjhego, vnutrennyuyu modelj drugogo uzla i proverennuyu narabotku. Bez takogo razlicheniya FUM nachnyot smeshivatj koordinatyi raznyikh nablyudatelej i prinimatj udobnoye predstavleniye za samu sistemu.

## Kvantovyij predel i otbor nablyudatelej

V modeli [FUM](../Glossarij/FUM.md) liniya ot obsjhej teorii otnositeljnosti dopolnyayetsya vtoryim fizicheskim analogom. Yesli obsjhaya teoriya otnositeljnosti v obobsjhyonnom primenenii zadayot obraz predeljnoj geometrii prostranstva dlya nablyudatelya, to kvantovaya mekhanika mozhet rassmatrivatjsya kak oblastj, gde vopros nablyudatelya, vzaimodejstviya i ustojchivosti prostejshikh sostoyanij stanovitsya predeljno nizkourovnevyim.

V takoj issledovateljskoj ramke elementarnaya chastica, atom, molekula, kletka, telo cheloveka, chelovecheskaya psikhika, mozg i [FUM-uzel](../Glossarij/FUM-uzel.md) ne tozhdestvennyi, no mogut sravnivatjsya kak raznyiye urovni nablyudateljskoj organizacii. Prostyiye vzaimodejstvuyusjhiye elementyi obrazuyut boleye ustojchivyiye sostavnyiye konfiguracii, a takiye konfiguracii mogut stanovitjsya nablyudatelyami sleduyusjhego urovnya ili sredami dlya vlozhennyikh nablyudatelej.

Perekhod mezhdu urovnyami svyazyivayetsya s [obobsjhyonnyim darvinovskim algoritmom](../Glossarij/obobsjhyonnyij-darvinovskij-algoritm.md): voznikayut variantyi svyazej i sostoyanij, sreda i posleduyusjhiye vzaimodejstviya otbirayut ustojchivyiye konfiguracii, a zakreplyonnyiye konfiguracii stanovyatsya substratom dlya sleduyusjhego urovnya nablyudeniya. Kletka i mozg v etoj shkale yavlyayutsya boleye byistryimi i bogatyimi mashinami voplosjheniya otbora po sravneniyu s bazovyimi fizicheskimi processami.

V etom zhe smyisle fundamentaljnyiye osnovaniya izmenchivosti i nasledstvennosti pomesjhayutsya na kvantovyij urovenj. Izmenchivostj svyazyivayetsya s dopustimyimi sostoyaniyami, perekhodami i vzaimodejstviyami, a nasledstvennostj - ne s genami, a s uderzhaniyem i peredachej ustojchivyikh konfiguracij, kotoryiye sposobnyi statj materialom dlya sleduyusjhego urovnya nablyudateljskoj organizacii.

Iz etogo ne sleduyet, chto vse urovni nablyudayemoj Vselennoj yavlyayutsya odnim i tem zhe obyyektom. Dlya nablyudateljskoj otnositeljnosti vazhneye drugaya formulirovka: urovni mogut byitj raznyimi voplosjheniyami odnoj [obsjhej skhemyi FUM](../Glossarij/obsjhaya-skhema-FUM.md), yesli udayotsya pokazatj obsjhij nabor invariantov i preobrazovanij mezhdu predstavleniyami. Rabochij kandidat na takuyu skhemu - ustojchivyij uzel, kotoryij nablyudayet ili predyyavlyayet sostoyaniye v svoyej sisteme koordinat, uderzhivayet konfiguraciyu, dopuskayet variantyi, prokhodit otbor i mozhet stanovitjsya elementom sleduyusjhego urovnya. Etot kandidat ostayotsya [gipotezoj FUM](../Glossarij/gipoteza-FUM.md), poka ne opisanyi kriterii primenimosti i oproverzheniya; ikh vyibor sobran v [otkryitom voprose ob abstrakcii urovnej nablyudayemoj Vselennoj](../Voprosyi/2026-06-26_12-19-03_MSK_abstrakciya-urovnej-nablyudayemoj-vselennoj-FUM.md).

## Granica analogii

Nablyudateljskaya otnositeljnostj FUM ne utverzhdayet, chto matematicheskij apparat obsjhej teorii otnositeljnosti bukvaljno primenim k lyuboj informacionnoj sisteme. Eto [gipoteza FUM](../Glossarij/gipoteza-FUM.md) o perenose arkhitekturnoj disciplinyi: nablyudatelj, sistema koordinat, preobrazovaniye i invariant dolzhnyi byitj yavnyimi.

Tak zhe i svyazj s kvantovoj mekhanikoj ne utverzhdayet, chto [FUM](../Glossarij/FUM.md) uzhe obladayet fizicheskoj teoriyej elementarnyikh nablyudatelej. Ona fiksiruyet rabochij issledovateljskij yazyik: yesli opisaniye perekhodit mezhdu urovnyami ot elementarnyikh vzaimodejstvij k atomam, molekulam, kletkam, mozgu, chelovecheskoj psikhike, agentskim uzlam i ekonomicheskim sistemam, nuzhno yavno pokazyivatj, kakiye nablyudateli, sostoyaniya, variantyi, sredyi sinkhronizacii, mekhanizmyi otbora i ustojchivyiye konfiguracii predpolagayutsya na kazhdom urovne.

V budusjhem etot princip mozhet poluchitj boleye stroguyu formu: metriki stoimosti preobrazovaniya, meryi poteri nablyudayemosti, grafyi sootvetstviya mezhdu predstavleniyami, proverku obratimosti ili modeli "kriviznyi" informacionnogo prostranstva. Poka zhe blizhajshaya poljza prakticheskaya: ne proyektirovatj FUM tak, budto yestj odin universaljnyij interfejs, odinakovo ponyatnyij vsem sloyam.

Dlya takogo perekhoda nuzhen [reyestr kartochek sootvetstviya FUM](28-reyestr-kartochek-sootvetstviya-FUM/README.md). V nyom kazhdaya fizicheskaya, tekhnicheskaya ili nablyudateljskaya analogiya dolzhna fiksirovatj nablyudatelya, sistemu koordinat, invariantyi, poteri i proverku. Eto pozvolyayet zavoditj sootvetstviya vplotj do fiziki, ne smeshivaya issledovateljskuyu gipotezu s uzhe podtverzhdyonnoj arkhitekturoj.

## Blizhnij proveryayemyij sloj

Minimaljnaya napravlennaya zapisj perekhoda uzhe zakreplena v [formate preobrazovaniya mezhdu nablyudatelyami FUM](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md). Sleduyusjhij proveryayemyij shag - primenitj yeyo v pasporte [interfejsa FUM-uzla](../Glossarij/interfejs-FUM-uzla.md) dlya tekusjhego kontura chelovek - Codex - Obsidian-khranilisjhe. Takoj pasport dolzhen pokazatj, kakiye sostoyaniya vidit chelovek, kakiye fajlyi i instrumentyi vidit LLM-agent, chto fiksiruyet Git, chto proveryayut lokaljnyiye avtomatizacii i kakiye poteri voznikayut mezhdu etimi formami.

V etom pasporte otdeljno nuzhen sloj navigacii k istochnikam polnoj informacii: kakiye predstavleniya yavlyayutsya proizvodnyimi, kuda oni vedut dlya proverki detalej i kakiye perekhodyi priznanyi nevozmozhnyimi ili chastichno poteryannyimi.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 11:50:58 MSK - Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-26 11:39:57 MSK](../Zhurnal/2026-06-26_11-39-57_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 11:52:42 MSK](../Zhurnal/2026-06-26_11-52-42_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 11:58:26 MSK](../Zhurnal/2026-06-26_11-58-26_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 12:19:03 MSK](../Zhurnal/2026-06-26_12-19-03_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-01 16:19:24 MSK](../Zhurnal/2026-07-01_16-19-24_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-01 16:40:36 MSK](../Zhurnal/2026-07-01_16-40-36_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-01 16:46:04 MSK](../Zhurnal/2026-07-01_16-46-04_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 10:20:18 MSK](../Zhurnal/2026-07-02_10-20-18_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-14 01:55:34 MSK - Integrirovatj rekursivnuyu modelj agenta i sredyi](../Zhurnal/2026-07-14_01-55-34_MSK_integrirovatj-rekursivnuyu-modelj-agenta-i-sredyi/zapros.md)

## Opornyiye dokumentyi

- [Arkhitektura FUM](22-arkhitektura-FUM.md)
- [Interfejs FUM-uzla](25-interfejs-FUM-uzla.md)
- [Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Reyestr kartochek sootvetstviya FUM](28-reyestr-kartochek-sootvetstviya-FUM/README.md)
- [Virtualizovannyiye sredyi FUM i dolgovremennaya pamyatj](23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)
- [Dostup k vnutrennim sostoyaniyam](07-dostup-k-vnutrennim-sostoyaniyam.md)
- [Kosmicheskaya avtonomiya FUM i mezhzvyozdnoye rasseleniye](14-kosmicheskaya-avtonomiya-i-rasseleniye.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:579cf123b229dfa3383a65a84bc37fad679bb2d4c90f8ab58ee97ac1a48d96db -->
<!-- FUM-MD-RECENCY:END -->
