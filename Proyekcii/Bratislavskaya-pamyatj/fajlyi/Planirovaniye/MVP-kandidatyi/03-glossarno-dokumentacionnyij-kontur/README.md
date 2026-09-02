# MVP-kandidat: glossarno-dokumentacionnyij kontur

## Pasport

- Status: [MVP-kandidat](../../../Glossarij/MVP-kandidat.md).
- Gorizontyi dorozhnoj kartyi: [svyaznaya pamyatj proyekta](../../dorozhnaya-karta.md) i [vosproizvodimyiye avtomatizacii](../../dorozhnaya-karta.md).
- Poljzovatelj: avtor dokumentacii FUM, kotoryij dobavlyayet novyiye ponyatiya, obnovlyayet tekstyi i podderzhivayet svyaznostj terminov.
- Minimaljnyij rezuljtat: lokaljnyij kontur, kotoryij pomogayet nakhoditj novyiye ustojchivyiye terminyi, proveryatj statji glossariya, obnovlyatj indeks i rasstavlyatj poleznyiye ssyilki na uzhe zavedyonnyiye terminyi.

## Produktovaya ideya dlya zapuska

Produkt: **Redaktor svyaznoj dokumentacii FUM** - lokaljnaya proverka, kotoraya pomogayet avtoru ne ronyatj terminologicheskuyu setj proyekta.

Pervyij poljzovatelj - avtor dokumentacii, kotoryij pered kommitom khochet ponyatj, gde v izmenyonnyikh Markdown-fajlakh propusjhenyi ssyilki na uzhe zavedyonnyiye terminyi, gde poyavilsya novyij ustojchivyij termin i ne sloman li indeks glossariya.

Pervyij scenarij zapuska: poljzovatelj ukazyivayet nabor izmenyonnyikh fajlov. Redaktor stroit otchyot: najdennyiye upotrebleniya terminov bez ssyilok, kandidatyi v novyiye terminyi, statji s nevernyim zagolovkom, otsutstvuyusjhiye stroki v `Глоссарий/README.md` i bityiye ssyilki.

Sostav pervogo reliza:

- komanda ili scenarij `fum glossary check <files>`;
- chteniye tekusjhego indeksa i statej `Глоссарий/`;
- otchyot bez avtomaticheskoj pravki fajlov;
- predlozheniya ssyilok dlya sklonyayemyikh form s sokhraneniyem iskhodnogo teksta;
- minimaljnaya fikstura s neskoljkimi terminami, propusjhennoj ssyilkoj i novyim slovosochetaniyem.

Kriterij gotovnosti k zapusku: avtor mozhet zapustitj proverku pered kommitom i poluchitj ponyatnyij spisok dejstvij po glossariyu bez setevyikh zavisimostej i bez avtomaticheskogo zakrepleniya sluchajnyikh formulirovok.

## Pochemu eto mozhet byitj pervyim MVP

Glossarij yavlyayetsya yazyikovyim karkasom pamyati FUM. Chem boljshe proyekt rastet, tem vazhneye ne teryatj smyisl terminov, ne ploditj neyavnyiye sinonimyi i ne ostavlyatj dokumentyi bez ssyilok na uzhe opredelyonnyiye ponyatiya.

Etot kandidat blizok k tekusjhej praktike: glossarij uzhe vedyotsya kak otdeljnyij razdel, a lokaljnyij navyik `fum-glossarij` zadayot pravila izmeneniya terminov. MVP mozhet snachala byitj proverkoj i otchyotom, a ne polnocennyim redaktorom.

## Proveryayemyij MVP

Minimaljnyij variant dolzhen umetj:

- proveritj, chto kazhdyij fajl termina nachinayetsya s zagolovka `# <Термин>`;
- proveritj nalichiye termina v `Глоссарий/README.md`;
- najti v izmenyonnyikh dokumentakh upotrebleniya uzhe zavedyonnyikh terminov bez ssyilok i vyidatj predlozheniya;
- najti novyiye povtoryayusjhiyesya slovosochetaniya, kotoryiye pokhozhi na ustojchivyiye terminyi;
- proveritj, chto ssyilki iz glossariya i na glossarij ne bityiye;
- sformirovatj otchyot, kotoryij agent ili chelovek mozhet prinyatj, otklonitj ili ispoljzovatj dlya pravki.

## Kriterii priyomki

- Proverka rabotayet lokaljno bez seti.
- Lozhnyiye srabatyivaniya ne menyayut fajlyi avtomaticheski.
- Dlya sklonyayemyikh form predlagayetsya ssyilka na statjyu v imeniteljnom padezhe, a tekst ssyilki sokhranyayet praviljnuyu formu.
- Novyij termin sozdayotsya toljko posle yavnogo resheniya, a ne iz-za odnogo sluchajnogo upotrebleniya.
- Indeks glossariya ostayotsya chitayemyim i predskazuyemo uporyadochennyim.

## Ne vkhodit v pervyij variant

- Avtomaticheskoye perepisyivaniye terminologicheskikh statej.
- Semanticheskoye obyyedineniye terminov bez uchastiya cheloveka.
- Polnaya ontologiya FUM ili grafovaya baza znanij.

## Zavisimosti

- `Глоссарий/README.md` i statji terminov.
- `Инструменты/fum-glossarij/SKILL.md`.
- Pravilo o ssyilkakh na soderzhateljnyiye upotrebleniya glossarnyikh terminov iz [AGENTS.md](../../../AGENTS.md).

## Riski

- Izbyitochnoye kolichestvo ssyilok mozhet ukhudshitj chitayemostj dokumentacii.
- Slishkom agressivnoye vyiyavleniye terminov mozhet zakreplyatj sluchajnyiye formulirovki.
- Nuzhno razlichatj poleznuyu terminologicheskuyu svyaznostj i mekhanicheskoye prevrasjheniye kazhdogo slova v ssyilku.

## Pervyij eksperiment

Sdelatj otchyot dlya izmenyonnyikh Markdown-fajlov: kakiye glossarnyiye terminyi uzhe upotreblenyi bez ssyilki, kakiye novyiye slovosochetaniya povtoryayutsya neskoljko raz, kakiye ssyilki na glossarij ne prokhodyat proverku. Na pervom shage otchyot ne dolzhen sam redaktirovatj fajlyi.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)

## Opornyiye materialyi

- [Glossarij FUM](../../../Glossarij/README.md)
- [Lokaljnyij navyik fum-glossarij](../../../Instrumentyi/fum-glossarij/SKILL.md)
- [Modelj pamyati FUM](../../../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](../../../Dokumentaciya/08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:60e7504c911e9d30bd6ff5547b73ce624869b749060d3495d5ea235d64eee365 -->
<!-- FUM-MD-RECENCY:END -->
