# [Sistema strukturiruyusjhikh operatorov FUM](../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md)

[Sistema strukturiruyusjhikh operatorov FUM](../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md) yavlyayetsya obsjhej arkhitekturnoj abstrakciyej dlya znachiteljnoj chasti trebovanij, kotoryiye ranjshe byili opisanyi cherez [pamyatj FUM](../Glossarij/pamyatj-FUM.md), potokovuyu samostrukturizaciyu, moduljnostj, yazyik avtomatizacij, obyyasnimostj LLM i proveryayemoye dejstviye. Ona otvechayet na odin skvoznoj vopros: kak [FUM](../Glossarij/FUM.md) perevodit potok nablyudenij, tekstov, dejstvij, sledov instrumentov, chelovecheskikh obyyasnenij i LLM-predlozhenij v imenovannyiye, proveryayemyiye i pereispoljzuyemyiye formyi, vklyuchaya tekstovyiye i ekrannyiye predstavleniya. V etoj roli sistema rabotayet kak vneshnij simvolicheskij interfejs mezhdu neyavnyimi znaniyami cheloveka i neyavnyimi znaniyami LLM.

V etoj ramke [strukturiruyusjhij operator FUM](../Glossarij/strukturiruyusjhij-operator-FUM.md) yavlyayetsya ne prosto pravilom razbora i ne toljko elementom slovarya. Eto dvunapravlennaya yedinica, kotoraya umeyet raspoznavatj formu vo vkhodnom potoke, porozhdatj sovmestimuyu formu obratno, otobrazhatj strukturu v chelovekochitayemuyu proyekciyu, khranitj usloviya primenimosti, cenu, doveriye, proiskhozhdeniye, primeryi, ogranicheniya, ostatki i svyazi s drugimi operatorami. Sistema operatorov opisyivayet uzhe ne odin takoj element, a graf ikh sovmestnoj rabotyi: kak oni skladyivayutsya v obyyasneniye, konkuriruyut, utochnyayutsya, perekhodyat mezhdu urovnyami abstrakcii i stanovyatsya materialom dlya avtomatizacij, modulej, planov, interfejsov i dejstvij.

## Skvoznaya rolj

Operatornaya sistema svyazyivayet nizhnij sloj vospriyatiya s verkhnimi sloyami myishleniya. Na vkhode ona poluchayet potok: bajtyi, tekst, kod, TeX, Markdown, zhurnal dejstvij, poljzovateljskij zapros, trassu instrumenta, povedeniye LLM ili fragment vneshnej sredyi. Na vyikhode ona dolzhna davatj kompaktnoye opisaniye, v kotorom vidno, kakiye fragmentyi obyyasnenyi izvestnyimi operatorami, kakiye ostalisj diagnosticheskim ostatkom, kakiye kandidatyi poyavilisj i kakiye proverki nuzhnyi pered zakrepleniyem.

Poleznaya rabochaya analogiya dlya etoj roli - ribosomnaya translyaciya, no v nej nuzhno razlichatj tri roli. Informacionnaya RNK sootvetstvuyet vkhodnomu potoku ili linejnoj zapisi: ona zadayot posledovateljnostj schityivaniya, no sama yesjhyo ne yavlyayetsya sobrannoj formoj. Transportnaya RNK sootvetstvuyet [strukturiruyusjhemu operatoru FUM](../Glossarij/strukturiruyusjhij-operator-FUM.md): ona svyazyivayet raspoznavayemyij fragment zapisi s perenosimyim elementom sborki. Ribosoma sootvetstvuyet ispolniteljnomu mekhanizmu, kotoryij posledovateljno primenyayet takiye sootvetstviya, uderzhivayet poryadok i ogranicheniya, soyedinyayet elementyi i porozhdayet sobrannuyu formu.

V FUM vkhodnoj potok, kod, TeX, Markdown, trassa dejstviya ili poljzovateljskij zapros mogut rassmatrivatjsya kak linejnyij nositelj instrukcii. Sobstvenno znaniye khranitsya ne toljko v etoj zapisi i ne toljko v gotovom rezuljtate. Ono khranitsya v operatornoj sisteme: v proveryayemyikh sootvetstviyakh mezhdu fragmentami potoka, elementami sborki, usloviyami primenimosti, ogranicheniyami, obratnyim porozhdeniyem i diagnosticheskimi ostatkami. Ispolniteljnyij sloj FUM ispoljzuyet takiye operatoryi, chtobyi sobratj boleye krupnuyu strukturu: tekst, kod, TeX-dokument, plan, ekrannuyu kartu ili drugoj artefakt.

Eta analogiya ne dolzhna ponimatjsya bukvaljno. Biologicheskaya translyaciya opirayetsya na zakreplyonnyij geneticheskij kod, a [strukturiruyusjhiye operatoryi FUM](../Glossarij/strukturiruyusjhij-operator-FUM.md) ostayutsya proveryayemyimi i izmenyayemyimi gipotezami: oni mogut byitj predlozhenyi chelovekom, LLM ili avtomatizaciyej, prokhoditj proverku na potokakh, konkurirovatj, oslablyatjsya, utochnyatjsya i ukhoditj v arkhiv. Odnako ribosomnaya analogiya podchyorkivayet vazhnyij arkhitekturnyij princip: FUM dolzhen khranitj ne toljko iskhodnyiye posledovateljnosti i ne toljko uzhe sobrannyiye produktyi, no i vosproizvodimyij sloj translyacii mezhdu zapisjyu i sobrannoj formoj.

Takoj sloj obobsjhayet neskoljko uzhe opisannyikh linij.

[Obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](../Glossarij/obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md) nakhodit syiroj material dlya kandidatov: povtoryayemyiye fragmentyi, kontekstyi, perekhodyi, oshibki, sovpadeniya i ustojchivyiye sledyi. [Potokovaya samostrukturizaciya FUM](../Glossarij/potokovaya-samostrukturizaciya-FUM.md) obyyasnyayet, kak eti kandidatyi rozhdayutsya iz potoka i prokhodyat proverku poljzyi. [Pamyatj FUM](../Glossarij/pamyatj-FUM.md) khranit operatoryi, ikh proiskhozhdeniye, statusyi, primeryi i istoriyu podtverzhdenij. [Iyerarkhiya funkcij i dannyikh FUM](../Glossarij/iyerarkhiya-funkcij-i-dannyikh-FUM.md) pokazyivayet, chto operator odnovremenno yavlyayetsya funkciyej dlya razbora vkhoda i dannyimi dlya boleye bazovoj funkcii, kotoraya mozhet etot operator proveritj, izmenitj, usilitj ili otklonitj.

## Graf operatorov

Sistema strukturiruyusjhikh operatorov ne dolzhna byitj ploskim spiskom pravil. Rabochaya forma blizhe k stratificirovannomu grafu: odin nizkourovnevyij operator mozhet uchastvovatj v neskoljkikh sintaksicheskikh, semanticheskikh, diskursivnyikh, instrumentaljnyikh i deyateljnostnyikh strukturakh. Ryobra grafa fiksiruyut raspoznavaniye, porozhdeniye, obobsjheniye, perevod, obyyasneniye, specializaciyu, kompoziciyu, konflikt, otkaz, ustarevaniye i proverochnuyu zavisimostj.

Nizkiye operatoryi mogut byitj privyazanyi k konkretnoj forme zapisi: okonchaniyu, suffiksu, variantu transliteracii, TeX-komande, Markdown-bloku, JSON-polyu, imeni fajla, shell-komande ili elementu interfejsnogo sobyitiya. Boleye vyisokiye operatoryi opisyivayut roli, frejmyi, tipyi otnoshenij, poljzovateljskiye namereniya, planovyiye shagi, avtomatizacii, arkhitekturnyiye invariantyi i drugiye smyislovyiye formyi, kotoryiye mogut perenositjsya mezhdu yazyikami, domenami i instrumentami.

Mezhyyazyikovyiye i mezhdomennyiye svyazi dolzhnyi idti cherez promezhutochnyiye smyislovyiye uzlyi, a ne cherez pryamoye priravnivaniye poverkhnostnyikh form. Yesli russkij fragment, anglijskij fragment i programmnaya konstrukciya svyazanyi odnim operatorom, sistema dolzhna khranitj obsjhij smyisl, urovenj abstrakcii, yazyikovo-specifichnyiye ostatki, poteri perevoda, ogranicheniya primeneniya i primeryi, na kotoryikh svyazj byila podtverzhdena.

## Tekstovo-yazyikovyiye operatoryi vo vneshnej pamyati

Dlya sovmestnogo kontura cheloveka i LLM [tekstovo-yazyikovyiye strukturiruyusjhiye operatoryi FUM](../Glossarij/tekstovo-yazyikovoj-strukturiruyusjhij-operator-FUM.md) yavlyayutsya prioritetnyim profilem operatornoj pamyati. Ikh ustojchivyij graf vneshen otnositeljno biologicheskoj pamyati cheloveka, parametrov i tekusjhego konteksta LLM, no vkhodit v [pamyatj FUM](../Glossarij/pamyatj-FUM.md). Chelovek i LLM v predelakh razreshyonnogo dostupa mogut chitatj, porozhdatj, proveryatj, ispravlyatj, svyazyivatj i povtorno ispoljzovatj odnu simvolicheskuyu formu, ne trebuya pryamogo dostupa k vnutrennemu sostoyaniyu drugoj storonyi.

Tekst i yazyik zadayut raznyiye osi profilya. Tekst dayot simvolyi, pisjmennostj, razmetku, adresuyemyiye fragmentyi i dokumentnuyu strukturu; yazyik svyazyivayet leksiku, morfologiyu, sintaksis, semantiku, pragmatiku i diskurs. Poetomu kod ili TeX mogut imetj tekstovo-formaljnyiye operatoryi bez yestestvenno-yazyikovoj semantiki, a ustnaya rechj, zhest ili muljtimodaljnoye sobyitiye mogut imetj tekstovuyu proyekciyu, ne ischerpyivayusjhuyu iskhodnuyu formu. Operatornyij graf dolzhen yavno khranitj urovenj svyazi, pervichnyij material i poteri proyekcii.

Prakticheskij prioritet etogo profilya voznikayet potomu, chto tekst mozhno iskatj, citirovatj, svyazyivatj, sravnivatj po versiyam i snova pomesjhatj v kontekst LLM; chelovek mozhet chitatj i ispravlyatj tu zhe zapisj. Minimaljnaya proverka dolzhna ocenivatj raspoznavaniye, porozhdeniye, obratnyij prokhod, perenos mezhdu kontekstami, tochnuyu ili smyislovuyu vosstanovimostj, ekonomiyu vnimaniya i konteksta, snizheniye oshibok i vliyaniye na sovmestnoye dejstviye. Takoj prioritet ne prevrasjhayet tekst v okonchateljnuyu ontologiyu i ne zamenyayet pervichnyiye istochniki, drugiye modaljnosti, lokaljnuyu pamyatj uchastnikov, dostup, agentskij cikl ili tekhnicheskij protokol.

Operatornyij graf dolzhen byitj ne toljko vnutrennej strukturoj razbora, no i istochnikom avtomaticheskikh vozmozhnostej [semanticheskoj navigacii po pamyati](../Glossarij/navigaciya-po-pamyati-FUM.md). Kogda operator svyazyivayet dva adresuyemyikh fragmenta cherez obsjheye ponyatiye, sobyitiye, rolj, prichinnoye otnosheniye, proiskhozhdeniye ili drugoj smyislovoj uzel, ispolniteljnyij sloj mozhet po etomu sootvetstviyu vyichislitj tipizirovannyij perekhod bez zaraneye rasstavlennoj Markdown-ssyilki. Interfejs vprave materializovatj yego kak ssyilku, rebro grafa, rekomendaciyu ili marshrut, no sokhranyayet putj obratno k operatoru i iskhodnyim fragmentam.

Avtomaticheskoye obnaruzheniye ne oznachayet avtomaticheskogo utverzhdeniya istinnosti. Dlya kazhdoj svyazi operatornaya sistema razdeljno khranit iniciatora predlozheniya ili vyivoda (chelovek, LLM libo avtomatizaciya), ispolniteljnyij kontur, primenyonnyij operator, iskhodnyiye materialyi i ikh proiskhozhdeniye, status proverki (kandidatnaya, podtverzhdyonnaya libo otklonyonnaya svyazj) i formu predyyavleniya (dinamicheskij perekhod, Markdown-ssyilka, rebro grafa, rekomendaciya libo marshrut). Kontekst, osnovaniye, uverennostj, kontrprimeryi i istoriya prinyatiya ili otkloneniya dopolnyayut eti polya; chelovecheskoye avtorstvo ne yavlyayetsya garantiyej istinnosti, a operatornyij vyivod ne prepyatstvuyet posleduyusjhemu podtverzhdeniyu. Zakrepleniye kandidata i izmeneniye iskhodnogo teksta ostayutsya otdeljnyimi proveryayemyimi dejstviyami.

## Yestestvennyij yazyik kak yazyik sinkhronizacii znanij

Yestestvennyij yazyik rassmatrivayetsya v FUM kak uzhe slozhivshijsya yazyik [sinkhronizacii znanij](../Glossarij/yestestvenno-yazyikovaya-sinkhronizaciya-znanij-FUM.md) mezhdu agentami chelovecheskogo obrazca. Yego operatornoye predstavleniye ne svoditsya k imenovaniyu uchastnikov. V sinkhronizacii sovmestno rabotayut slovarj, morfologiya, sintaksis, semantika, pragmatika i diskurs: oni svyazyivayut ponyatiya, sobyitiya, roli, vremya, modaljnostj, prichinnostj, dokazateljnostj, namereniya, voprosyi, obyazateljstva, citirovaniye, povestvovaniye i ispravleniye neponimaniya.

Operatornyij graf dolzhen razlichatj po menjshej mere neskoljko svyazannyikh urovnej yazyikovogo akta:

- nablyudayemuyu formu vyiskazyivaniya i yeyo yazyikovyiye variantyi;
- referentyi, roli uchastnikov i kontekst;
- soderzhaniye utverzhdeniya, voprosa, pobuzhdeniya ili drugogo rechevogo akta;
- modaljnostj, istochnik, stepenj uverennosti i izvestnyiye osnovaniya;
- diskursivnuyu svyazj s predyidusjhimi replikami, otvetami, utochneniyami i vozrazheniyami;
- izmeneniye lokaljnoj modeli poluchatelya, obsjhej rabochej pamyati i ozhidayemogo dejstviya.

Takoj graf ne kopiruyet vnutrenneye sostoyaniye govoryasjhego v adresata. On khranit proveryayemuyu proyekciyu togo, chto byilo vyirazheno, kak ponyato, chto izmenilosj v modeli poluchatelya i gde ostalosj raskhozhdeniye. Polnyij cikl vklyuchayet vyiskazyivaniye, interpretaciyu, otvet ili proverku, obnaruzheniye oshibki, utochneniye i povtornoye obnovleniye pamyati. Podrobnyij arkhitekturnyij kontur opisan v dokumente [Yestestvennyij yazyik i sinkhronizaciya znanij FUM](34-yestestvennyij-yazyik-i-sinkhronizaciya-znanij-FUM.md).

### [Rolevaya semantika setevogo vzaimodejstviya FUM](../Glossarij/rolevaya-semantika-setevogo-vzaimodejstviya-FUM.md) kak chastnyij sloj

Lichnyiye mestoimeniya yavlyayutsya naglyadnoj, no chastnoj chastjyu yazyikovoj sinkhronizacii: oni ne toljko nazyivayut uchastnikov, no i zadayut ikh polozheniye otnositeljno tekusjhego akta obsjheniya.

| Yazyikovaya forma     | Kontekstnaya rolj                                          | Chto trebuyet yavnoj privyazki                   |
| ------------------ | --------------------------------------------------------- | -------------------------------------------- |
| `я`                | Tekusjhij govoryasjhij ili istochnik vyiskazyivaniya               | Ustojchivyij identifikator govoryasjhego          |
| `ты`               | Yedinichnyij pryamoj adresat                                  | Identifikator adresata                       |
| `мы`               | Gruppa, v kotoruyu vklyuchyon govoryasjhij                       | Tochnyij sostav gruppyi i vklyuchyonnostj adresata |
| `вы`               | Odin vezhlivo oboznachennyij adresat ili neskoljko adresatov | Chislo i nabor adresatov                      |
| `он`, `она`, `оно` | Yedinichnyij uchastnik ili obyyekt tretjyego lica               | Konkretnyij referent                          |
| `они`              | Gruppa tretjikh uchastnikov                                 | Sostav i versiya gruppyi                       |

Eti formyi yavlyayutsya kontekstnyimi rolyami, a ne postoyannyimi identifikatorami uzlov. V otvetnoj replike prezhnij adresat mozhet statj `я`, a prezhnij govoryasjhij - `ты`; citirovaniye sozdayot vlozhennyij centr rechi; `мы` ne raskryivayet sostav gruppyi i ne dokazyivayet pravo govoryasjhego predstavlyatj yeyo.

Dlya mashinnogo vzaimodejstviya kazhdyij znachimyij akt obsjheniya dolzhen sokhranyatj iskhodnoye vyiskazyivaniye, yego interpretaciyu, rechevoj akt, modaljnostj, dokazateljnostj i vyizvannoye izmeneniye modeli, a takzhe svyazyivatj yazyikovyiye roli s ustojchivyimi metadannyimi: identifikatorom govoryasjhego, adresatami, upominayemyimi uzlami i gruppami, versiyej sostava gruppyi, vremenem, kontekstom, proiskhozhdeniyem, granicami citirovaniya, delegirovaniyem i [urovnyami dostupa](../Glossarij/urovenj-dostupa.md). Sistema dolzhna razlichatj «uzel soobsjhil», «FUM interpretiroval», «FUM prinyal kak rabocheye znaniye» i «ostalosj raskhozhdeniye». Sama yazyikovaya forma ne yavlyayetsya autentifikaciyej, razresheniyem ili podtverzhdeniyem polnomochij.

V operatornom grafe mestoimennaya forma otnositsya k yazyikovo-specifichnomu sloyu, a govoryasjhij, adresat, vklyuchayusjhaya gruppa i tretjya storona - k boleye vyisokim semanticheskim rolyam. Perekhod mezhdu yazyikami dolzhen sokhranyatj eti roli i otdeljno otmechatj neodnoznachnosti: naprimer, vklyuchyon li adresat v `мы`, yavlyayetsya li `вы` yedinstvennyim vezhlivyim adresatom ili gruppoj i kakoj nabor uzlov oboznachayet `они`.

Vyiraziteljnaya dostatochnostj yazyika otnositsya k semanticheskomu sloyu i ne zamenyayet transportnyij protokol, dostavku, autentifikaciyu, soglasovaniye, kontrolj dostupa ili vosstanovleniye posle oshibok. Kriterii dostatochnoj sinkhronizacii, minimaljnyij kontrakt yazyikovogo akta, granicyi yestestvennogo yazyika i privyazka rolej k konkretnyim uzlam ostayutsya [otkryityim voprosom](../Voprosyi/2026-07-13_20-34-23_MSK_granicyi-yestestvenno-yazyikovoj-sinkhronizacii-znanij-FUM.md).

## Ekrannyiye predstavleniya

Operatornaya sistema mozhet ispoljzovatjsya ne toljko dlya porozhdeniya teksta. Poskoljku operator khranit formu, svyazi, proiskhozhdeniye, urovenj abstrakcii, status proverki i usloviya primenimosti, tot zhe graf mozhet porozhdatj graficheskiye predstavleniya strukturirovannyikh znanij na ekrane: kartyi ponyatij, sloi abstrakcii, cepochki proiskhozhdeniya, konfliktyi obyyasnenij, proverochnyiye zavisimosti, diagnosticheskiye ostatki i marshrutyi ot obsjhego vyivoda k primeram.

Dlya cheloveka takaya forma yavlyayetsya interfejsnoj proyekciyej operatornogo grafa. Uzel na ekrane ne dolzhen byitj toljko podpisjyu ili dekorativnoj tochkoj: on dolzhen vesti k sootvetstvuyusjhemu operatoru, istochniku, primeru, trasse, statusu doveriya ili izvestnoj potere. Ryobra graficheskogo predstavleniya dolzhnyi razlichatj tip svyazi: raspoznavaniye, porozhdeniye, obobsjheniye, perevod, kompoziciyu, konflikt, proverku, ustarevaniye ili perekhod k dejstviyu.

Ekrannoye predstavleniye mozhet byitj szhatyim i nablyudateljski udobnyim, no ono ne dolzhno pritvoryatjsya polnoj strukturoj, yesli chastj informacii skryita. Interfejs obyazan pokazyivatj, gde vizualizaciya yavlyayetsya obratimoj proyekciyej operatornogo grafa, gde ona yavlyayetsya smyislovyim priblizheniyem, a gde ostayotsya neobyyasnyonnyij ostatok. Dejstviya cheloveka s takoj kartoj - raskryitiye uzla, filjtraciya urovnya, prinyatiye, otkloneniye, ispravleniye ili predlozheniye svyazi - mogut stanovitjsya novyimi sobyitiyami operatornoj sistemyi i prokhoditj obyichnyij cikl proverki.

Takoj ekrannyij sloj sleduyet opisyivatj operatorno, a ne kak otdeljnuyu ruchnuyu vizualizaciyu. Operator proyekcii prinimayet tipizirovannyij fragment grafa i zadayot, vo chto on prevrasjhayetsya dlya cheloveka: uzel, rebro, kontejner, tablicu, vremennuyu shkalu, AST, graf dokazateljstva, kartu konfliktov ili drugoj vid. Yego profilj dolzhen khranitj ne toljko `render`, no i skhemu vzaimodejstviya: kakiye dejstviya cheloveka dopustimyi, kak oni perevodyatsya obratno v izmeneniye strukturyi, kakiye proverki zapuskayutsya i kakaya chastj proyekcii ostayotsya vosstanovimoj.

## Obyyasnimostj

Sistema operatorov yavlyayetsya proveryayemyim interfejsom obyyasnimosti mezhdu chelovekom, LLM i boleye nizkimi vyichisliteljnyimi sloyami. Ona ne obesjhayet napryamuyu rasshifrovatj vesa LLM kak prozrachnyij slovarj i ne delayet chelovecheskoye znaniye polnostjyu dostupnyim bez ostatka. Vmesto etogo ona dayot vneshnij simvolicheskij sloj mezhdu dvumya neyavnyimi oblastyami znaniya: navyikami, associaciyami, namereniyami i razlicheniyami cheloveka s odnoj storonyi i vesami, svyazyami, aktivaciyami, kontekstnyimi sledami i veroyatnostnyimi privyichkami LLM s drugoj.

Chelovek i LLM sovmestno vyinosyat svoi znaniya v formu operatorov. Chelovek mozhet nazvatj razlicheniye, privesti primer, ukazatj granicu ili oshibku; LLM mozhet predlozhitj regulyarnostj, obobsjheniye, perevodimyij shablon ili nedostayusjhuyu formu. Algoritmyi posle etogo ne prinimayut operator po avtoritetu istochnika: oni proveryayut yego na potokakh, primenyayut k novyim sluchayam, sravnivayut s konkuriruyusjhimi operatorami, vyiyavlyayut oshibki, diagnosticheskiye ostatki i nedostayusjhiye strukturyi.

Dlya cheloveka operator dayot ponyatnoye imya, primeryi, granicyi i obyyasneniye. Dlya LLM on dayot kompaktnuyu oporu v kontekstnom okne i vozmozhnostj ne vyivoditj kazhdyij raz tu zhe strukturu zanovo. Dlya lokaljnyikh avtomatizacij on zadayot proveryayemyij kontrakt: chto raspoznayotsya, chto porozhdayetsya, kakiye ostatki dopustimyi, kakiye oshibki dolzhnyi fiksirovatjsya i kakiye usloviya zapresjhayut zakrepleniye novogo pravila. Za schyot etogo znaniye stanovitsya obyyasnimyim, szhimayemyim, perenosimyim, proveryayemyim i povtorno ispoljzuyemyim, ne teryaya svyazi s proiskhozhdeniyem i granicami primenimosti.

## Svyazj s avtomatizaciyami i modulyami

[Yazyik avtomatizacij FUM](../Glossarij/yazyik-avtomatizacij-FUM.md) mozhno rassmatrivatj kak odin iz verkhnikh sloyov operatornoj sistemyi. Komanda, deklarativnyij blok, proverka, shag workflow ili skhema otchyota stanovyatsya ustojchivyimi potomu, chto dlya nikh yestj operatoryi raspoznavaniya, porozhdeniya, validacii, trassirovki i obyyasneniya. Poetomu avtomatizaciya ne dolzhna byitj neprozrachnyim skriptom, kotoryij sluchajno srabotal; ona dolzhna imetj operatornyij profilj, ponyatnyij cheloveku, LLM i lokaljnomu proverochnomu konturu.

Svyazj mezhdu yazyikom avtomatizacij i sistemoj operatorov dolzhna byitj tesnoj, a ne spravochnoj. Operatornaya sistema zadayot obsjhij graf proveryayemyikh form, a yazyik avtomatizacij yavlyayetsya ispolnyayemoj proyekciyej tekh operatorov, kotoryiye mozhno stabilizirovatj sintaksisom, tipami, effektami, proverkami i trassoj. Novaya konstrukciya yazyika avtomatizacij dolzhna rassmatrivatjsya kak kandidat v operator ili semejstvo operatorov; novyij operator, kotoryij ustojchivo povtoryayetsya v rabochikh sessiyakh, mozhet statj konstrukciyej yazyika, yesli yemu nuzhen zapusk, validaciya ili perenos mezhdu uzlami.

[Modulj FUM](../Glossarij/modulj-FUM.md) mozhet vyirasti iz operatora ili svyazki operatorov, yesli oni ustojchivo poleznyi, imeyut yasnyiye vkhodyi i vyikhodyi, prokhodyat proverki i trebuyut otdeljnogo ispolneniya. V etom smyisle operatornaya sistema zadayot rannij sloj moduljnosti: snachala poyavlyayetsya proveryayemaya forma, zatem povtoryayemoye primeneniye, zatem specializirovannaya avtomatizaciya, adapter, ekspert ili modulj.

## Zhiznennyij cikl

Kandidat v operator mozhet poyavitjsya iz statisticheskoj povtoryayemosti, chelovecheskogo ukazaniya, LLM-predlozheniya, rezuljtata avtomatizacii, oshibki razbora ili nablyudayemogo dejstviya. Yego neljzya prinimatj toljko potomu, chto tekusjhaya pamyatj ne smogla obyyasnitj fragment. Snachala sistema dolzhna sokhranitj diagnosticheskij ostatok: fragment, chastichnyiye sovpadeniya, neudavshiyesya operatoryi, tip konflikta, konkuriruyusjhiye obyyasneniya i vozmozhnyiye prichinyi.

Posle etogo kandidat prokhodit proverku. On dolzhen uluchshatj kompaktnostj opisaniya, predskazaniye, obratnoye porozhdeniye, perenosimostj, dejstviye ili obyyasnimostj pri razumnoj cene khraneniya, vyichislenij i slozhnosti, a takzhe pri dopustimom riske pereobobsjheniya. U operatora dolzhnyi byitj statusyi: gipoteza, nizkodoveriteljnyij operator, podtverzhdyonnyij operator, konfliktuyusjhij operator, otklonyonnyij operator, ustarevshij operator ili operator, ozhidayusjhij vneshnej proverki.

Zakrepleniye operatora ne zavershayet rabotu. Sistema dolzhna khranitj istoriyu primenenij, polozhiteljnyiye i otricateljnyiye primeryi, izmeneniya versii, svyazi s istochnikami, proverki, sluchai otkaza i usloviya otkata. Yesli operator nachinayet vreditj novyim razboram, dubliruyet drugoj operator ili skryivayet vazhnyij ostatok, on dolzhen oslablyatjsya, utochnyatjsya, slivatjsya s drugim operatorom ili ukhoditj v arkhiv.

Dlya operatora eti perekhodyi yavlyayutsya chastnyim sluchayem [upravlyayemogo zabyivaniya FUM](../Glossarij/upravlyayemoye-zabyivaniye-FUM.md). Posle oslableniya nizhe pokonturnogo poroga operator perestayot uchastvovatj v obyichnom raspoznavanii, porozhdenii i marshrutizacii dannogo kontura, no pri dopustimom khranenii ostavlyayet v kholodnom arkhive identichnostj, stabiljnuyu privyazku k predku, proiskhozhdeniye, istoriyu vesa i proveryayemoye osnovaniye vosstanovleniya. Novaya potrebnostj zapuskayet [vspominaniye FUM](../Glossarij/vspominaniye-FUM.md) i povtornuyu proverku. Bezvozvratnostj utverzhdayetsya dlya nazvannoj oblasti vosstanovleniya, gde ustojchivo ne ostalosj dostatochnogo osnovaniya; skhodnyij nezavisimyij budusjhij operator imeyet novoye proiskhozhdeniye. Fizicheskoye udaleniye vyipolnyayetsya otdeljno po polnomochnomu pravilu privatnosti, bezopasnosti ili khraneniya.

## Granicyi

Sistema strukturiruyusjhikh operatorov ne yavlyayetsya yedinoj okonchateljnoj ontologiyej realjnosti. Ona ne dolzhna prevrasjhatj udobnyiye formyi tekusjhego prototipa v vechnyiye klassyi i ne dolzhna stiratj material, kotoryij poka ne ukladyivayetsya v izvestnyiye strukturyi. Diagnosticheskij ostatok yavlyayetsya chastjyu znaniya, a ne musorom.

Eta sistema takzhe ne zamenyayet [nejronnuyu gipersetj FUM](../Glossarij/nejronnaya-gipersetj-FUM.md), [agentskij cikl](../Glossarij/agentskij-cikl.md), modeljnuyu sredu, Git-evolyuciyu ili fizicheskiye konturyi dejstviya. Ona dayot obsjhij yazyik, cherez kotoryij eti sloi mogut predyyavlyatj svoi formyi drug drugu: chto raspoznano, chto porozhdeno, chto provereno, chto ostalosj neyasnyim, kakoj urovenj menyayetsya i pochemu eto izmeneniye schitayetsya dopustimyim.

## Minimaljnyij prototip

Pervyij Swift-prototip operatornoj sistemyi dolzhen proveryatj malyij, no skvoznoj kontur. Minimaljnyij nabor vklyuchayet reyestr operatorov, profilj operatora, graf svyazej, primeryi, diagnosticheskiye ostatki, statusyi kandidatov, proverku szhatiya, proverku obratnogo porozhdeniya, rezhimyi polnostjyu vosstanovimogo i smyislovogo szhatiya, operator proyekcii dlya prostoj ekrannoj kartyi, skhemu obratnogo sobyitiya ot dejstviya cheloveka, a takzhe fiksturyi dlya mezhyyazyikovyikh i mezhdomennyikh svyazej.

Dejstvuyusjhij [prototip pamyati strukturiruyusjhikh operatorov](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/README.md) sokhranyayet sobyitiye pruning, perevodit udalyonnogo kandidata v `obsolete` i uderzhivayet yego identifikator i istoriyu otbora. Eto yesjhyo ne realizaciya upravlyayemogo zabyivaniya: pokonturnyij ves i porog prekrasjheniya rabotyi, meta-urovenj obnaruzheniya, razdeleniye khraneniya i rabotosposobnosti, vspominaniye, bezvozvratnoye zabyivaniye i otbor ikh tempa ne realizovanyi.

Prototip dolzhen pokazatj, kak odin i tot zhe operatornyij sloj rabotayet na neskoljkikh tipakh materiala: russkom tekste, translite, anglijskoj konstrukcii, Markdown-bloke, TeX-komande, fragmente koda, dejstvii agenta i zapisi rabochej sessii. Vazhnyij kriterij uspekha - ne polnota pokryitiya, a sposobnostj sokhranyatj proiskhozhdeniye, razlichatj podtverzhdyonnyij razbor i gipotezu, ne prinimatj oshibku vkhoda za novoye pravilo i obyyasnyatj, kak operator pomogayet pamyati, LLM, avtomatizacii ili modulyu.

Otdeljnaya fikstura dolzhna sravnivatj odin material kak syiroj tekst i kak [tekstovo-yazyikovoye operatornoye predstavleniye](../Glossarij/tekstovo-yazyikovoj-strukturiruyusjhij-operator-FUM.md). Sravneniye provoditsya dlya cheloveka, LLM i ikh sovmestnogo kontura po vosstanovimosti smyisla, raskhodu vnimaniya i konteksta, obnaruzheniyu i ispravleniyu oshibok, perenosu mezhdu rabochimi sessiyami i uspeshnosti posleduyusjhego dejstviya. Fikstura dolzhna sokhranyatj pervichnyij material i vklyuchatj sluchaj, v kotorom tekstovaya proyekciya proigryivayet drugoj modaljnosti ili formaljnoj strukture.

Otdeljnyij scenarij dolzhen nachinatjsya s dvukh ili neskoljkikh tekstovyikh fragmentov bez yavnyikh ssyilok. Prototip prokhodit cepochku `распознавание операторов -> кандидатная семантическая связь -> типизированный переход в интерфейсе -> принятие или отклонение -> сохранение происхождения` i proveryayet, chto iskhodnyij tekst ne menyayetsya bez otdeljnogo dejstviya. Fikstura zaraneye razmechayet ozhidayemyiye svyazi i otricateljnyiye paryi, a dlya neodnoznachnyikh sluchayev zadayot yavnuyu proceduru ekspertnogo resheniya. Po etomu etalonu ocenivayutsya obosnovannostj perekhoda, dolya lozhnyikh svyazej i poleznostj navigacii; rezuljtat takzhe dolzhen pokazyivatj uverennostj, iniciatora vyivoda, ispolniteljnyij kontur, primenyonnyij operator, iskhodnyiye materialyi i kontrprimer.

Obyazateljnaya yazyikovaya fikstura dolzhna vklyuchatj dva uzla s razlichnoj lokaljnoj pamyatjyu i posledovateljnostj `утверждение -> вопрос -> уточнение -> исправление -> пересказ получателем -> подтверждение или сохранённое расхождение -> совместное действие`. Ona dolzhna proveryatj ponyatiya, vremya, modaljnostj, prichinnoye obyyasneniye, istochnik i uverennostj, a takzhe chastnyij rolevoj sloj: smenu `я` i `ты`, variantyi sostava `мы`, prochteniya `вы`, ssyilku na `они`, citirovaniye i predstaviteljstvo sostavnogo uzla. Odin uchastnik dolzhen byitj LLM-podderzhivayemyim agentom, a otdeljnyij scenarij dolzhen povtoryatj tot zhe kontur mezhdu vnutrennimi poduzlami FUM. Proverka dolzhna pokazyivatj dostatochnuyu predmetnuyu sovmestimostj pri sokhranenii razlichij vnutrennikh sostoyanij i otdelyatj yazyikovoj smyisl ot identichnosti, sostava gruppyi, polnomochij, dostupa i dostavki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-31 12:20:47 MSK - Utochnitj vspominaniye i bezvozvratnoye zabyivaniye](../Zhurnal/2026-07-31_12-20-47_MSK_utochnitj-vspominaniye-i-bezvozvratnoye-zabyivaniye/zapros.md)
- [iskhodnyij zapros 2026-07-31 11:57:37 MSK - Zakrepitj upravlyayemoye zabyivaniye FUM](../Zhurnal/2026-07-31_11-57-37_MSK_zakrepitj-upravlyayemoye-zabyivaniye-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-06 10:05:34 MSK - Integrirovatj soderzhimoye ChatGPT dialoga](../Zhurnal/2026-07-06_10-05-34_MSK_integrirovatj-soderzhimoye-chatgpt-dialoga/zapros.md)
- [iskhodnyij zapros 2026-07-06 10:24:52 MSK - Opisatj nejrosetj kak sredu agentov](../Zhurnal/2026-07-06_10-24-52_MSK_opisatj-nejrosetj-kak-sredu-agentov/zapros.md)
- [iskhodnyij zapros 2026-07-06 13:34:08 MSK - Opisatj kompilyaciyu algoritmov v tenzornyij graf](../Zhurnal/2026-07-06_13-34-08_MSK_opisatj-kompilyaciyu-algoritmov-v-tenzornyij-graf/zapros.md)
- [iskhodnyij zapros 2026-07-06 14:49:39 MSK - Opisatj iyerarkhiyu funkcij i dannyikh](../Zhurnal/2026-07-06_14-49-39_MSK_opisatj-iyerarkhiyu-funkcij-i-dannyikh/zapros.md)
- [iskhodnyij zapros 2026-07-08 09:10:55 MSK - Opisatj strukturnyiye elementyi samostrukturizacii](../Zhurnal/2026-07-08_09-10-55_MSK_opisatj-strukturnyiye-elementyi-samostrukturizacii/zapros.md)
- [iskhodnyij zapros 2026-07-08 09:21:09 MSK - Utochnitj strukturnyiye elementyi FUM](../Zhurnal/2026-07-08_09-21-09_MSK_utochnitj-strukturnyiye-elementyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-08 10:18:09 MSK - Zakrepitj pamyatj strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_10-18-09_MSK_zakrepitj-pamyatj-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 10:34:09 MSK - Dobavitj istochnik pamyati strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_10-34-09_MSK_dobavitj-istochnik-pamyati-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 10:54:49 MSK - Utochnitj urovni strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_10-54-49_MSK_utochnitj-urovni-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 11:06:21 MSK - Svyazatj utochneniye pamyati strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_11-06-21_MSK_svyazatj-utochneniye-pamyati-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 11:25:24 MSK - Zakrepitj operatoryi kak interfejs obyyasnimosti](../Zhurnal/2026-07-08_11-25-24_MSK_zakrepitj-operatoryi-kak-interfejs-obyyasnimosti/zapros.md)
- [iskhodnyij zapros 2026-07-08 11:37:43 MSK - Svyazatj rasshirennuyu vetku strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_11-37-43_MSK_svyazatj-rasshirennuyu-vetku-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 11:49:28 MSK - Obobsjhitj sistemu strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_11-49-28_MSK_obobsjhitj-sistemu-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 11:58:07 MSK - Utochnitj vneshnij interfejs strukturiruyusjhikh operatorov](../Zhurnal/2026-07-08_11-58-07_MSK_utochnitj-vneshnij-interfejs-strukturiruyusjhikh-operatorov/zapros.md)
- [iskhodnyij zapros 2026-07-08 12:11:56 MSK - Svyazatj yazyik avtomatizacij i operatornuyu sistemu](../Zhurnal/2026-07-08_12-11-56_MSK_svyazatj-yazyik-avtomatizacij-i-operatornuyu-sistemu/zapros.md)
- [iskhodnyij zapros 2026-07-08 12:21:45 MSK - Svyazatj operatornuyu sistemu s graficheskim interfejsom](../Zhurnal/2026-07-08_12-21-45_MSK_svyazatj-operatornuyu-sistemu-s-graficheskim-interfejsom/zapros.md)
- [iskhodnyij zapros 2026-07-08 12:38:52 MSK - Zakrepitj operatornuyu pamyatj kak yadro FUM](../Zhurnal/2026-07-08_12-38-52_MSK_zakrepitj-operatornuyu-pamyatj-kak-yadro-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-09 10:50:38 MSK - Svyazatj operatornuyu sistemu s ribosomnoj translyaciyej](../Zhurnal/2026-07-09_10-50-38_MSK_svyazatj-operatornuyu-sistemu-s-ribosomnoj-translyaciyej/zapros.md)
- [iskhodnyij zapros 2026-07-09 11:01:42 MSK - Utochnitj roli v ribosomnoj analogii](../Zhurnal/2026-07-09_11-01-42_MSK_utochnitj-roli-v-ribosomnoj-analogii/zapros.md)
- [iskhodnyij zapros 2026-07-13 20:34:23 MSK - Zakrepitj rolevuyu semantiku vzaimodejstviya II-agentov](../Zhurnal/2026-07-13_20-34-23_MSK_zakrepitj-rolevuyu-semantiku-vzaimodejstviya-II-agentov/zapros.md)
- [iskhodnyij zapros 2026-07-13 22:00:22 MSK - Zakrepitj yestestvennyij yazyik kak yazyik sinkhronizacii znanij](../Zhurnal/2026-07-13_22-00-22_MSK_zakrepitj-yestestvennyij-yazyik-kak-yazyik-sinkhronizacii-znanij/zapros.md)
- [iskhodnyij zapros 2026-07-14 00:14:49 MSK - Zakrepitj operatoryi teksta i yazyika vo vneshnej pamyati](../Zhurnal/2026-07-14_00-14-49_MSK_zakrepitj-operatoryi-teksta-i-yazyika-vo-vneshnej-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-14 01:15:40 MSK - Zakrepitj avtomaticheskiye semanticheskiye svyazi lichnogo FUM](../Zhurnal/2026-07-14_01-15-40_MSK_zakrepitj-avtomaticheskiye-semanticheskiye-svyazi-lichnogo-FUM/zapros.md)

## Opornyiye dokumentyi

- [Modelj pamyati FUM](01-modelj-pamyati-FUM.md)
- [Obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)
- [Vosproizvodimyiye avtomatizacii FUM](17-vosproizvodimyiye-avtomatizacii.md)
- [LLM-oriyentirovannyij yazyik avtomatizacij](21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Arkhitektura FUM](22-arkhitektura-FUM.md)
- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Potokovaya samostrukturizaciya FUM](32-potokovaya-samostrukturizaciya-FUM.md)
- [Yestestvennyij yazyik i sinkhronizaciya znanij FUM](34-yestestvennyij-yazyik-i-sinkhronizaciya-znanij-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:268ae13652274d8ebd0b431869da2d668c1bf5655f21ec94b155518c3fb00636 -->
<!-- FUM-MD-RECENCY:END -->
