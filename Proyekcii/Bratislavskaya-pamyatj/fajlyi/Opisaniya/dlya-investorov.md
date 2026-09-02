# Opisaniye [FUM](../Glossarij/FUM.md) dlya investorov

## Pasport opisaniya

- Adresat: investoryi i partnyoryi, ocenivayusjhiye dolgosrochnuyu tekhnologicheskuyu vozmozhnostj.
- Celj: obyyasnitj, pochemu [FUM](../Glossarij/FUM.md) mozhet byitj investicionno znachimyim proyektom, ne vyidavaya proyektnyiye gipotezyi za podtverzhdyonnyiye kommercheskiye faktyi.
- Status: polnaya peresborka 2026-06-23 13:08:36 MSK cherez bazovuyu vosproizvodimuyu skhemu; zamenyayet versiyu ot 2026-06-22 10:05:04 MSK.
- Avtomatizaciya: [Postroyeniye opisaniya FUM dlya adresata](Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md).
- Osnovnyiye istochniki: [obzor proyekta](../Dokumentaciya/00-obzor-proyekta.md), [modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md), [publikaciya i licenziya](../Dokumentaciya/02-publikaciya-i-licenziya.md), [evolyuciya i myishleniye](../Dokumentaciya/03-evolyuciya-i-myishleniye.md), [moduljnaya arkhitektura FUM](../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md), [obzor agentskikh ciklov](../Dokumentaciya/06-obzor-agentskikh-ciklov.md), [obmen narabotkami i urovni dostupa](../Dokumentaciya/09-obmen-narabotkami-i-urovni-dostupa.md), [gibridnyiye uzlyi i socialjnaya fraktaljnostj](../Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md), [decentralizaciya FUM i granicyi vlasti](../Dokumentaciya/15-decentralizaciya-i-granicyi-vlasti.md), [nauchnyiye issledovaniya FUM i otkryitiya](../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md), [vosproizvodimyiye avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md), [opisaniya FUM dlya adresatov](../Dokumentaciya/18-opisaniya-FUM-dlya-adresatov.md), [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md), [indeks otkryityikh voprosov](../Voprosyi/README.md).
- Ogranicheniya: v tekusjhej [pamyati](../Glossarij/pamyatj-FUM.md) ne zafiksirovanyi kommercheskiye metriki, kliyentskiye vnedreniya, yuridicheskaya struktura, finansovaya modelj, investicionnyiye usloviya ili promyishlennaya ekspluataciya.

## Fiksaciya obnovleniya

Eta versiya peresobrana kak yavnyij rezuljtat vyizova [avtomatizacii FUM](../Glossarij/avtomatizaciya-FUM.md), a ne kak tochechnaya ruchnaya pravka prezhnego teksta. Pri peresborke dobavleno trebovaniye o svyazke [FUM](../Glossarij/FUM.md) i [MCP-serverov](../Glossarij/MCP-server.md) kak [yedinoj tochke vzaimodejstviya s kompjyuterom](../Glossarij/yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md), a investicionnaya ramka utochnena vokrug snizheniya [modaljnosti prilozhenij](../Glossarij/modaljnostj-prilozhenij.md), sokrasjheniya dublirovaniya koda i umenjsheniya rasstoyaniya ot idei do voplosjheniya.

## Kratkaya formulirovka

[FUM](../Glossarij/FUM.md) - otkryityij proyekt agenta sleduyusjhego pokoleniya, gde centraljnyim aktivom yavlyayetsya ne otdeljnyij chat-interfejs, a svyaznaya [pamyatj FUM](../Glossarij/pamyatj-FUM.md): [iskhodnyiye zaprosyi](../Glossarij/iskhodnyij-zapros.md), [proizvodnaya dokumentaciya](../Glossarij/proizvodnaya-dokumentaciya.md), glossarij, [otkryityiye voprosyi](../Glossarij/otkryityij-vopros.md), vosproizvodimyiye [avtomatizacii FUM](../Glossarij/avtomatizaciya-FUM.md), rezuljtatyi rabochikh sessij i kommityi.

Investicionnaya gipoteza sostoit v tom, chto sleduyusjhij klass cennyikh AI-sistem budet otlichatjsya ne toljko kachestvom modeli, no i sposobnostjyu statj rabochim sloyem mezhdu chelovekom i cifrovoj sredoj. Svyazka [FUM](../Glossarij/FUM.md) i [MCP-serverov](../Glossarij/MCP-server.md) dolzhna pozvolitj poljzovatelyu formulirovatj namereniye v odnom meste, a agentu - vyizyivatj servisyi, sokhranyatj proiskhozhdeniye dejstvij, prevrasjhatj uspeshnyiye posledovateljnosti v perenosimyiye [narabotki](../Glossarij/narabotka.md) i sokrasjhatj putj ot idei do voplosjheniya.

## Chto stroitsya

[FUM](../Glossarij/FUM.md) proyektiruyetsya kak agent polnogo cikla razrabotki i issledovaniya: on dolzhen pomogatj formulirovatj trebovaniya, stavitj [gipotezyi](../Glossarij/gipoteza-FUM.md), provoditj [eksperimentyi](../Glossarij/eksperiment-FUM.md), pisatj kod, proveryatj rezuljtat i oformlyatj [otkryitiya](../Glossarij/otkryitiye-FUM.md). Dolgosrochnyij oriyentir - [FUM](../Glossarij/FUM.md)-agent, sposobnyij uchastvovatj v sozdanii sobstvennoj sleduyusjhej versii vplotj do sposobnosti napisatj samogo sebya.

Novyij poljzovateljskij gorizont proyekta - [yedinaya tochka vzaimodejstviya s kompjyuterom](../Glossarij/yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md). V etom rezhime [lichnyij FUM-agent](../Glossarij/lichnyij-FUM-agent.md) stanovitsya osnovnyim centrom rabotyi poljzovatelya, a servisyi podklyuchayutsya cherez [MCP-serveryi](../Glossarij/MCP-server.md), instrumentyi, resursyi i drugiye nablyudayemyiye konturyi. Eto dolzhno umenjshatj neobkhodimostj pereklyuchatjsya mezhdu mnozhestvom kliyentskikh prilozhenij i interfejsnyikh rezhimov.

Arkhitekturnaya stavka proyekta - [fraktaljnaya](../Glossarij/fraktaljnyij-uzel-myishleniya.md) setj [FUM-uzlov](../Glossarij/FUM-uzel.md), vdokhnovlennaya povtoryayemyimi modulyami neokorteksa. Malyiye uzlyi mogut stanovitjsya [modulyami FUM](../Glossarij/modulj-FUM.md), [poduzlami](../Glossarij/poduzel-FUM.md), lichnyimi agentami cheloveka, [gibridnyimi uzlami](../Glossarij/gibridnyij-uzel.md) i boleye krupnyimi socialjnyimi sistemami.

Prakticheskoye yadro proyekta segodnya nakhoditsya v pamyati. Repozitorij uzhe fiksiruyet trebovaniya, arkhitekturnyiye osnovaniya, otkryityiye neopredelyonnosti, glossarnyiye opredeleniya, pravila rabochikh sessij i pervyiye vosproizvodimyiye skhemyi. Eto rannyaya stadiya, no imenno takoj sloj delayet proyekt proveryayemyim i prigodnyim dlya otkryitoj publikacii.

## Pochemu eto mozhet byitj interesno investoru

FUM nacelen na problemu, kotoraya stanovitsya vazhneye po mere rosta avtonomnosti AI-agentov: kak sdelatj rabotu agenta ne odnorazovoj, a nasleduyemoj, proveryayemoj i uluchshayemoj. Yesli sistema ne khranit proiskhozhdeniye trebovanij, istoriyu reshenij, statusyi neopredelyonnosti, prava dostupa i iskhodnyiye tekstyi avtomatizacij, ona plokho masshtabiruyetsya kak inzhenernyij produkt.

Vtoroj investicionno znachimyij sloj - problema [modaljnosti prilozhenij](../Glossarij/modaljnostj-prilozhenij.md). Segodnya poljzovatelj i razrabotchiki platyat za razroznennostj servisov: raznyiye prilozheniya zanovo realizuyut pokhozhiye interfejsnyiye scenarii, a chelovek vruchnuyu perenosit namereniye i rezuljtat mezhdu nimi. Yesli servisyi predostavlyayut nadyozhnyiye mashinnyiye kontraktyi cherez [MCP-serveryi](../Glossarij/MCP-server.md), FUM mozhet statj obsjhim agentskim sloyem, kotoryij pereispoljzuyet [moduli](../Glossarij/modulj-FUM.md), proverki, pravila dostupa i [patternyi pamyati](../Glossarij/pattern-pamyati.md) mezhdu servisami.

Proyekt predlagayet rassmatrivatj pamyatj kak glavnyij sloj agentskoj infrastrukturyi. [Avtomatizacii FUM](../Glossarij/avtomatizaciya-FUM.md) dolzhnyi byitj chastjyu etoj pamyati: s iskhodnyimi tekstami, skhemami vkhodov i vyikhodov, proverkami, versiyami i istoriyej izmenenij. Dazhe postroyeniye adresnogo opisaniya oformleno kak vosproizvodimaya procedura, chtobyi proizvodnyij tekst mozhno byilo peresobratj iz yavnyikh istochnikov.

Otdeljnaya vozmozhnostj - [otkryitostj FUM](../Glossarij/otkryitostj-FUM.md). Repozitorij vedyotsya pod [CC0 1.0 Universal](../LICENZIYA.md), potomu chto agent, sposobnyij razvivatj i v predele pisatj samogo sebya, dolzhen imetj nasleduyemuyu, proveryayemuyu i pereispoljzuyemuyu osnovu. Dlya investora eto oznachayet, chto rannyaya cennostj proyekta lezhit ne v zakryitom obesjhanii, a v proveryayemom osnovanii, vokrug kotorogo mozhet rasti setj uchastnikov, realizacij i proizvodnyikh [narabotok](../Glossarij/narabotka.md).

Dlya personaljnogo primeneniya otkryitostj osobenno vazhna. [Lichnyij FUM-agent](../Glossarij/lichnyij-FUM-agent.md) potencialjno rabotayet so vsemi sferami lichnoj zhizni cheloveka, poetomu doveriye k nemu ne dolzhno trebovatj veryi v zakryityij mekhanizm. Pri etom otkryitostj agenta ne ravna publikacii lichnoj pamyati: chuvstviteljnyiye materialyi dolzhnyi zasjhisjhatjsya [urovnyami dostupa](../Glossarij/urovenj-dostupa.md), proiskhozhdeniyem reshenij i [granicami vlasti](../Glossarij/granica-vlasti-FUM.md).

## Otlichiye ot obyichnoj LLM-obertki

FUM ne opisyivayetsya kak interfejs vokrug odnoj modeli. Proyekt zadayot boleye shirokij sloj: [agentskij cikl](../Glossarij/agentskij-cikl.md), pamyatj, [avtomaticheskiye organyi vospriyatiya](../Glossarij/avtomaticheskij-organ-vospriyatiya-FUM.md), [avtomaticheskiye organyi dejstviya](../Glossarij/avtomaticheskij-organ-dejstviya-FUM.md), [MCP-serveryi](../Glossarij/MCP-server.md) kak servisnyiye adapteryi, vnutrenniye modeli drugikh uzlov, urovni dostupa, otkryityiye voprosyi bezopasnosti i vosproizvodimyiye avtomatizacii.

LLM v etoj kartine mozhet byitj lokaljnoj ili vneshnej chastjyu agenta, no ne yedinstvennyim istochnikom ustojchivosti. Ustojchivostj dolzhna voznikatj iz svyazki modeli, pamyati, proverok, procedur obnovleniya i sposobnosti prevrasjhatj udachnyiye posledovateljnosti dejstvij v perenosimyiye [patternyi pamyati](../Glossarij/pattern-pamyati.md).

## Tekusjhij status

Tekusjhij publichnyij sloj FUM - rannyaya [pamyatj proyekta](../Glossarij/pamyatj-FUM.md) v vide Git-repozitoriya. V nej uzhe opisanyi modelj pamyati, evolyucionnoye osnovaniye myishleniya, moduljnaya arkhitektura, agentskiye ciklyi, nablyudayemostj vnutrennikh sostoyanij, obmen narabotkami, vnutrenniye modeli drugikh uzlov, gibridnyiye uzlyi, fizicheskoye dejstviye, kosmicheskij gorizont, decentralizaciya, nauchnyiye issledovaniya, vosproizvodimyiye avtomatizacii i trebovaniye k FUM kak yedinoj tochke vzaimodejstviya s kompjyuterom.

Pri etom investorskoye opisaniye dolzhno chestno fiksirovatj: proyekt yesjhyo ne predyyavlyayet podtverzhdyonnyikh ryinochnyikh metrik, produktovoj voronki, vyiruchki, promyishlennoj ekspluatacii, gotovoj seti MCP-integracij ili yuridicheski oformlennoj investicionnoj konstrukcii. Yego cennostj na etoj stadii - v yasnoj issledovateljsko-inzhenernoj ramke i v discipline pamyati, kotoraya mozhet statj fundamentom budusjhej sistemyi.

Proveryayemyij signal processa uzhe viden na urovne samoj pamyati: adresnyiye opisaniya obnovlyayutsya ne pryamoj pravkoj, a peresborkoj cherez zakreplyonnuyu avtomatizaciyu. Eto neboljshoj, no vazhnyij primer togo, kak proyekt prevrasjhayet sobstvennyiye pravila v vosproizvodimuyu praktiku.

## Riski i otkryityiye voprosyi

Glavnyij risk - rasstoyaniye mezhdu siljnoj arkhitekturnoj gipotezoj i rabotayusjhej sistemoj. FUM dolzhen dokazatj, chto pamyatj, avtomatizacii, agentskiye ciklyi i servisnyiye adapteryi dejstviteljno dayut agentu izmerimoye preimusjhestvo v razrabotke, issledovanii, poljzovateljskom vzaimodejstvii i samouluchshenii.

Vtoroj risk - upravlyayemostj avtonomii. V proyekte uzhe vyidelenyi trebovaniya k [decentralizacii FUM](../Glossarij/decentralizaciya-FUM.md), [granicam vlasti](../Glossarij/granica-vlasti-FUM.md), urovnyam dostupa i otkryityim voprosam po apparatnoj, issledovateljskoj i kosmicheskoj avtonomii. Eti voprosyi neljzya obkhoditj: oni yavlyayutsya chastjyu investicionnoj ocenki, a ne vneshnim prilozheniyem k nej.

Tretij risk - vosproizvodimostj. Yesli avtomatizacii, opisaniya, proverki, MCP-vyizovyi i dejstviya ne budut sobiratjsya iz yavnyikh istochnikov, proyekt poteryayet glavnoye otlichiye. Poetomu eto opisaniye samo oformleno kak proizvodnyij artefakt, svyazannyij s istochnikami i avtomatizaciyej peresborki.

Sredi yavno zafiksirovannyikh neopredelyonnostej osobenno vazhnyi [status vnutrennikh FUM i modeljnyikh sred](../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md), [granicyi apparatnoj avtonomii FUM](../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md), [granicyi kosmicheskoj avtonomii FUM](../Voprosyi/2026-06-22_07-40-59_MSK_granicyi-kosmicheskoj-avtonomii-FUM.md), [granicyi vlasti uzlov FUM](../Voprosyi/2026-06-22_07-51-48_MSK_granicyi-vlasti-uzlov-FUM.md) i [granicyi issledovateljskoj avtonomii FUM](../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md).

## Blizhajshiye vekhi

Blizhajshaya cennostj dlya investora poyavlyayetsya tam, gde koncepciya pamyati prevrasjhayetsya v rabotayusjhij cikl: avtomatizacii nachinayut ne toljko opisyivatjsya, no i ispolnyatjsya; agentskiye dejstviya poluchayut proveryayemyiye trassyi; MCP-serveryi podklyuchayut realjnyiye servisnyiye vozmozhnosti; opisaniya dlya raznyikh auditorij peresobirayutsya iz dokumentacii; uspeshnyiye rabochiye posledovateljnosti oformlyayutsya kak perenosimyiye [narabotki](../Glossarij/narabotka.md).

Sleduyusjhij ubediteljnyij shag - prototip, v kotorom FUM vyipolnyayet ogranichennuyu inzhenernuyu, issledovateljskuyu ili poljzovateljskuyu zadachu cherez yedinuyu tochku vzaimodejstviya: fiksiruyet iskhodnyij zapros, vyibirayet servisnyiye dejstviya, vyizyivayet instrumentyi, proveryayet rezuljtat, stroit proizvodnuyu dokumentaciyu i obnovlyayet pamyatj tak, chtobyi drugoj uzel mog vosproizvesti khod rabotyi.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-22 09:40:25 MSK](../Zhurnal/2026-06-22_09-40-25_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 09:55:43 MSK](../Zhurnal/2026-06-22_09-55-43_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 10:00:58 MSK](../Zhurnal/2026-06-22_10-00-58_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 10:05:04 MSK](../Zhurnal/2026-06-22_10-05-04_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-23 13:08:36 MSK](../Zhurnal/2026-06-23_13-08-36_MSK/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 23:10:40 MSK -->
<!-- content-sha256: sha256:edb45b380e8fc73c8f99b1d1414366f68e0f0ad911a812f5e83859e25fdd8797 -->
<!-- FUM-MD-RECENCY:END -->
