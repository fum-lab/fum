# MVP-kandidat: yedinaya tochka lokaljnoj rabotyi

## Pasport

- Status: [MVP-kandidat](../../../Glossarij/MVP-kandidat.md).
- Gorizontyi dorozhnoj kartyi: [lichnyij agent i yedinaya tochka vzaimodejstviya](../../dorozhnaya-karta.md).
- Poljzovatelj: chelovek, kotoryij khochet rabotatj s pamyatjyu FUM cherez odin kontur namereniya, podtverzhdeniya, dejstviya i rezuljtata.
- Minimaljnyij rezuljtat: lokaljnaya poverkhnostj, kotoraya prinimayet namereniye poljzovatelya, nakhodit relevantnyiye materialyi pamyati, predlagayet bezopasnyiye dejstviya, zaprashivayet podtverzhdeniya i fiksiruyet itog.

## Produktovaya ideya dlya zapuska

Produkt: **Yedinoye prilozheniye lokaljnoj pamyati FUM** - odin poljzovateljskij kontur dlya poiska konteksta, vyibora bezopasnogo dejstviya, podtverzhdeniya, proverki i zapisi rezuljtata.

Pervyij poljzovatelj - chelovek, kotoryij rabotayet s pamyatjyu FUM i khochet formulirovatj namereniye odin raz, a ne vruchnuyu iskatj nuzhnyiye dokumentyi, vspominatj pravila sessii i zapuskatj razroznennyiye proverki.

Pervyij scenarij zapuska: poljzovatelj vvodit namereniye vrode "najdi planovyij material i podgotovj obnovleniye". Prilozheniye pokazyivayet najdennyiye istochniki pamyati, predlagayet odno lokaljnoye dejstviye, prosit podtverzhdeniye, vyipolnyayet yego cherez susjhestvuyusjhuyu avtomatizaciyu ili yavnyij instrument, zapuskayet proverku i sokhranyayet rezuljtat v fajlakh pamyati.

Sostav pervogo reliza:

- yedinoye lokaljnoye prilozheniye kak osnovnaya poljzovateljskaya poverkhnostj pervoj [korobochnoj realizacii FUM](../../../Glossarij/korobochnaya-realizaciya-FUM.md);
- poisk po dokumentacii, glossariyu, voprosam i planovyim materialam;
- tri razreshyonnyikh dejstviya: pokazatj najdennyij kontekst, zapustitj proverku svyaznosti, podgotovitj chyornovik izmeneniya bez vneshnikh servisov;
- obyazateljnoye podtverzhdeniye pered zapisjyu fajlov, dliteljnoj proverkoj ili kommitom;
- zapisj rezuljtata v obyichnuyu cepochku rabochej sessii: zapros, izmenyonnyiye fajlyi, proverka, zhurnal i Git-istoriya.

CLI- ili TUI-vkhod `fum local` mozhet ostavatjsya vnutrennim, diagnosticheskim ili razrabotcheskim sposobom zapuska, no on ne dolzhen byitj osnovnoj formoj pervogo korobochnogo poljzovateljskogo opyita.

Inzhenernyij putj k etomu produktu, naprotiv, mozhet i dolzhen nachinatjsya bez GUI. [Nachaljnyij korobochnyij prototip](../../../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md) snachala proveryayet shtatnoye vosproizvodimoye popolneniye pamyati i ogranichennoye vnutrenneye ispolneniye, zatem vyivodit iz prinyatogo sostoyaniya inertnuyu deklarativnuyu modelj predstavleniya i lishj posle etogo podklyuchayet renderer. Bezokonnyij bootstrap ne podmenyayet produktovyij kriterij yedinogo prilozheniya.

Kriterij gotovnosti k zapusku: poljzovatelj mozhet otkryitj odno prilozheniye i projti odin lokaljnyij scenarij ot namereniya do sokhranyonnogo rezuljtata, vidya istochniki, podtverzhdaya dejstviye i poluchaya proveryayemyij sled v pamyati FUM.

Daljnyaya celevaya vekha etogo kandidata - perejti ot yedinogo prilozheniya lokaljnoj pamyati k lokaljnomu agentu na vyidelennoj mashine s lokaljno zapuskayemoj siljnoj LLM. Pervyij reliz ne obyazan reshatj vyibor zheleza i modeli: kriterii takogo vyibora ostayutsya v [otkryitom voprose o lokaljnoj LLM i vyidelennoj mashine](../../../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md). Pri etom pervyij reliz dolzhen sokhranyatj takuyu formu poljzovateljskogo kontura, kotoruyu pozzhe mozhno perenesti na vyidelennyij [apparatnyij FUM-uzel](../../../Glossarij/apparatnyij-FUM-uzel.md): namereniye, lokaljnaya pamyatj, modeljnyij shag, podtverzhdeniye, dejstviye, proverka i trassa.

Tekusjhij kontur chelovek - Codex - Obsidian-khranilisjhe mozhno rassmatrivatj kak ruchnoj proobraz etogo MVP-kandidata, a sam repozitorij - kak [dokumentacionnyij prototip FUM](../../../Glossarij/dokumentacionnyij-prototip-FUM.md). On uzhe dayot yedinyij rabochij vkhod cherez agentskuyu sessiyu, obsjhuyu [pamyatj FUM](../../../Glossarij/pamyatj-FUM.md) v repozitorii, chelovekochitayemuyu navigaciyu v Obsidian, proverki i Git-fiksaciyu rezuljtata. Pervyij produktovyij shag dolzhen ne kopirovatj interfejs Codex ili Obsidian, a opisatj, kakiye elementyi etogo proobraza stanovyatsya obyazateljnyim kontraktom lokaljnoj tochki rabotyi i budusjhej [korobochnoj realizacii FUM](../../../Glossarij/korobochnaya-realizaciya-FUM.md).

[Tenevoj redaktor prodolzhenij](../../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md) yavlyayetsya realizovannyim komponentnyim predshestvennikom etogo MVP-kandidata. On uzhe proveryayet lokaljnuyu poljzovateljskuyu poverkhnostj, rabotu s odnim fajlom, lokaljnyij modeljnyij shag i sokhraneniye ogranichennoj trassyi sravneniya, no ne prinimayet obsjheye namereniye, ne isjhet materialyi pamyati, ne predlagayet i ne podtverzhdayet dejstviya, ne vyipolnyayet avtomatizacii i ne zavershayet rabochuyu sessiyu v Git. Poetomu status MVP-kandidata i yego kriterii priyomki ne menyayutsya.

[SwiftPM-prototip vosproizvodimogo popolneniya pamyati](../../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) yavlyayetsya vtoryim komponentnyim predshestvennikom: on uzhe stroit kanonicheskiye snimok i proiskhozhdeniye cherez sobstvennyiye operacii i diagnostiruyet nalichiye markerov predposyilok budusjhej GUI-proyekcii. Paket namerenno ne sozdayot okna, ne validiruyet specifikaciyu predstavleniya, ne khranit dolgovremennyiye pokoleniya i ne dokazyivayet yedinoye prilozheniye `P11`.

## Pochemu eto mozhet byitj pervyim MVP

Etot kandidat blizhe vsego k produktovomu obrazu FUM kak rabochej tochki mezhdu chelovekom i cifrovoj sredoj. Dazhe bez vneshnikh MCP-servisov mozhno pokazatj osnovnoj princip: poljzovatelj formuliruyet namereniye odin raz, a FUM pomogayet najti kontekst, vyibratj dejstviye, vyipolnitj lokaljnuyu avtomatizaciyu i sokhranitj rezuljtat.

Yedinoye prilozheniye usilivayet etot kandidat kak pervuyu korobochnuyu formu: ono pokazyivayet ne toljko otdeljnuyu komandu ili avtomatizaciyu, a celjnuyu postavlyayemuyu poverkhnostj budusjhego [lichnogo FUM-agenta](../../../Glossarij/lichnyij-FUM-agent.md). Eto samyij demonstriruyemyij, no i samyij slozhnyij kandidat. Yego bezopasneye stroitj posle boleye uzkikh konturov: pamyati rabochej sessii, glossarnoj proverki, arkhivirovaniya materialov i minimaljnogo agentskogo cikla.

## Proveryayemyij MVP

Minimaljnyij variant dolzhen umetj:

- zapuskatjsya kak yedinoye lokaljnoye prilozheniye;
- prinyatj tekstovoye namereniye poljzovatelya;
- najti relevantnyiye dokumentyi, glossarnyiye terminyi, voprosyi i planovyiye materialyi;
- predlozhitj odin ili neskoljko lokaljnyikh dejstvij s ponyatnyim effektom;
- zaprositj podtverzhdeniye pered zapisjyu fajlov, zapuskom dliteljnoj proverki ili kommitom;
- vyipolnitj vyibrannoye lokaljnoye dejstviye cherez susjhestvuyusjhuyu avtomatizaciyu ili yavnyij instrument;
- sokhranitj rezuljtat v pamyati: zapros, izmenyonnyiye fajlyi, proverku, zhurnal i itog.
- vyivoditj modelj predstavleniya iz kanonicheskoj pamyati i versionirovannyikh operatorov, a poljzovateljskoye dejstviye vozvrasjhatj kak sobyitiye togo zhe proveryayemogo kontura.

## Kriterii priyomki

- Vse dejstviya s pobochnyimi effektami trebuyut yavnogo podtverzhdeniya ili zaraneye razreshyonnogo pravila.
- Poljzovatelj vidit, kakiye istochniki pamyati ispoljzovanyi dlya predlozheniya.
- Yesli dejstviye nevozmozhno vyipolnitj, sistema sokhranyayet prichinu i predlagayet sleduyusjhij bezopasnyij shag.
- Rezuljtat ne teryayetsya v interfejse: on popadayet v fajlyi pamyati FUM i Git-istoriyu.
- Pervyij variant rabotayet polnostjyu lokaljno bez vneshnikh servisov.
- Polnoye vosproizvedeniye pokazyivayet proiskhozhdeniye khotya byi odnogo ekrannogo elementa i odnogo izmeneniya pamyati, vyizvannogo dejstviyem poljzovatelya; renderer ne khranit otdeljnuyu domennuyu istinu.

## Ne vkhodit v pervyij variant

- Universaljnoye upravleniye vsemi prilozheniyami poljzovatelya.
- Fizicheskoye dejstviye, vneshniye finansovyiye operacii ili dostup k privatnyim servisam.
- Polnocennaya setj MCP-serverov i dolgovremennaya avtonomiya bez zaprosa poljzovatelya.
- Okonchateljnyij vyibor vyidelennoj mashinyi, lokaljnoj LLM i runtime-infrastrukturyi dlya celevoj vekhi.

## Zavisimosti

- [Ispolnyayemyij agentskij cikl](../04-ispolnyayemyij-agentskij-cikl/README.md) kak mekhanizm sostoyaniya i trassyi.
- [Pamyatj rabochej sessii](../01-pamyatj-rabochej-sessii/README.md) kak kontur fiksacii rezuljtata.
- Lokaljnyiye avtomatizacii, kotoryiye uzhe imeyut proverki i ponyatnyiye granicyi dejstviya.

## Riski

- Prezhdevremennaya universaljnostj mozhet razmyitj proveryayemostj pervogo produkta.
- Nuzhno ne pereputatj udobnyij interfejs s realjnoj agentskoj pamyatjyu: vse znachimyiye dejstviya dolzhnyi sokhranyatjsya v repozitorii.
- Neljzya sozdavatj gotovyij ekran kak seed ili podderzhivatj paralleljnoye ruchnoye sostoyaniye GUI: zhiznesposobnostj dolzhna voznikatj iz vnutrennikh mekhanizmov pamyati i ispolneniya FUM.
- Bez strogikh podtverzhdenij yedinaya tochka mozhet prevratitjsya v skryituyu vlastj nad rabochej sredoj, chto protivorechit trebovaniyam k granicam vlasti FUM.

## Pervyij eksperiment

Zavershyonnyij inzhenernyij eksperiment [FUM-STEP-0074](../../kartochki-shagov/✅-FUM-STEP-0074-dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu.md) ostalsya bezokonnyim: podtverzhdyonnoye pokoleniye vosstanavlivayetsya, iz pamyati vyivoditsya inertnaya modelj predstavleniya, a dopustimoye namereniye preobrazuyetsya obratno v versionirovannoye sobyitiye pamyati. Etot rezuljtat ne dokazyivayet zhiznesposobnyij GUI; renderer mozhno podklyuchatj toljko posle proyasneniya [granicyi GUI iz vnutrennikh mekhanizmov FUM](../../../Voprosyi/2026-07-24_10-44-28_MSK_granica-GUI-iz-vnutrennikh-mekhanizmov-FUM.md).

Pervyij produktovyij eksperiment ostayotsya boleye shirokim: poljzovatelj prosit najti i obnovitj planovyij material, yedinoye prilozheniye pokazyivayet najdennyiye istochniki, predlagayet izmeneniye, vyipolnyayet yego posle podtverzhdeniya, zapuskayet proverku ssyilok i sozdayot otchyot rabochej sessii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../../../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 19:50:33 MSK](../../../Zhurnal/2026-06-25_19-50-33_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 10:34:02 MSK](../../../Zhurnal/2026-06-26_10-34-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-29 10:59:18 MSK](../../../Zhurnal/2026-06-29_10-59-18_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-29 12:44:23 MSK](../../../Zhurnal/2026-06-29_12-44-23_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij](../../../Zhurnal/2026-07-14_08-54-56_MSK_sozdatj-prototip-raskhozhdeniya-prodolzhenij/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)

## Opornyiye materialyi

- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Lokaljnyij agent FUM na vyidelennoj mashine](../../../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Yedinaya tochka vzaimodejstviya s kompjyuterom](../../../Glossarij/yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Lichnyij FUM-agent](../../../Glossarij/lichnyij-FUM-agent.md)
- [Tenevoj redaktor prodolzhenij](../../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md)
- [Trebovaniye FUM-REQ-0021 — GUI kak proyekciya vnutrennej pamyati i ispolneniya](../../../Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md)
- [Otkryityij vopros o granice GUI iz vnutrennikh mekhanizmov FUM](../../../Voprosyi/2026-07-24_10-44-28_MSK_granica-GUI-iz-vnutrennikh-mekhanizmov-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:dbeda7f45311f87d1b21837c79da0a014a913006349c0d01661a2543a8c6d425 -->
<!-- FUM-MD-RECENCY:END -->
