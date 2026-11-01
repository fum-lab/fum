# Otchyot 2026-09-16 13:52:17 MSK - Zakrepitj roli vetok i granicu paralleljnoj proverki

Utochnyon dokumentaljnyij poryadok postoyannyikh vetok i povtornogo ispoljzovaniya vyivoda ob izolyacii proverochnogo snimka.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Istochniki i chitayusjhij obzor | ne izmereno | Adresnaya sverka pervichnyikh zapisej i obzor tekusjhikh kontraktov |
| Dokumentacionnaya deljta | ne izmereno | Pravila, inventarj, dva opisaniya i Zhurnal |
| Adresnyiye proverki | po zapuskam | Monotonnoye vremya otchyotnoj obyortki |

Granica profilya: istochniki, sobstvennaya dokumentacionnaya pravka i adresnyiye proverki; sozdaniye kommita i publikaciya otdeljno, chuzhoj polnyij profilj ne vklyuchyon.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                               | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------------- | ------------ | --------- |
| [korenj] Proveritj roli vetok i usloviya paralleljnoj proverki                       | 26,977 s     | uspeshno   |
| [korenj] Proveritj svezhestj i diff posle obzora i pozdnego utochneniya osnovnoj papki | 1,851 s      | uspeshno   |
| [korenj] Proveritj svezhestj i diff posle utochneniya pokryivayusjhego prefiksa            | 1,89 s       | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 30,718 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:03c2f55492a7197d3b6f0bd4b77c527c8e90588800ba7c5b525ea4e75f330f26.
Kontekst soderzhimogo: sha256:2cba9a2135ff3263a41d6a3fb68bcf74621cf105e0debf751f4ed352e4a3b6eb.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Adresnyij kontur vklyuchayet dekompoziciyu pravil, neizmennyij mashinnyij reyestr, strukturu Zhurnala, recency i diff. Zaklyuchiteljnyij sozdatelj kommita vyipolnyayet nastoyasjhuyu svyaznostj. Nikakoj realizacii ili tyazhyoloj proyekcii ne dobavleno.

## Otvetyi na pervichnyiye komandyi

Nizhe sokhranenyi vidimyiye otvetyi kornya FUMA na vopros o vetkakh, soglasiye i prosjbu zakrepitj obnaruzhennuyu granicu paralleljnoj proverki, v iskhodnom poryadke:

`fuma` uzhe postoyannaya vetka, i osnovnuyu razrabotku razumno vesti v nej. `master` mozhno ostavitj dlya boleye redkikh, proverennyikh postavok: neobkhodimostj obnovlyatj yego posle kazhdogo etapa sejchas dobavlyayet zaderzhki.

Nachatuyu integraciyu predlagayu zakonchitj, a zatem sobiratj rabochiye izmeneniya v `fuma` i ot neyo obnovlyatj vetki zadach. Otdeljno proveryu, kakiye tekusjhiye instrumentyi dejstviteljno zavyazanyi na `master`, chtobyi ne obesjhatj pereklyucheniye, kotoroye oni poka ne podderzhivayut.

Delayem: `fuma` — postoyannaya osnovnaya vetka razrabotki i integracii, `master` — periodicheskiye proverennyiye postavki. Nachatuyu integraciyu zavershayem. Zakreplyu etot poryadok v pravilakh i dokumentacii; novyiye zadachi i obratnuyu dostavku budem privyazyivatj k aktualjnoj `fuma`.

Zafiksiruyu eto kak pravilo s usloviyami: **proverka izolirovannogo snimka ne trebuyet ostanavlivatj zapisj v druguyu vetku, yesli yeyo zhivoye sostoyaniye ne vkhodit v proveryayemyiye zavisimosti**.

Sokhranim osnovaniye i granicyi proverki. Povtornyij razbor ponadobitsya pri izmenenii proverochnogo kontura ili zavisimostej. Samogo fakta raznyikh rabochikh derevjyev dlya takogo vyivoda nedostatochno.

Da, mozhem sdelatj imenno tak: **osnovnaya papka — `fuma`, otdeljnoye rabocheye derevo — `master` dlya stabiljnyikh vyipuskov**.

Snachala zavershim tekusjhuyu integraciyu. Zatem nuzhno adaptirovatj dopusk vyipuska: sejchas on trebuyet `master` imenno v osnovnoj papke. Posle etogo perenesyom vladeniye `fuma` i pereklyuchim checkout, sokhraniv nezakommichennyiye izmeneniya i privyazki zadach. Prosto vyipolnitj `git switch` sejchas nedostatochno.

## Rezuljtat i ogranicheniya

Pravilo121 utochnyayet roli fuma/master i tochnoye nachalo zadach; pravilo o planirovaniye soglasovano s dostavkoj v fuma. Pravilo188 sokhranyayet usloviya povtornogo ispoljzovaniya zaklyucheniya: tochnyij snimok, kontur i zavisimosti, vladeljcyi, zhivyiye vkhodyi i razreshyonnyiye mutacii. Izmeneniye etikh uslovij trebuyet novogo razbora; nezavisimyij zhurnaljnyij kommit sam po sebe yego ne trebuyet. Raznyiye worktree nedostatochnyi dlya vyivoda ob izolyacii. Eto proveryayemyij poryadok, a avtomaticheskoye kyeshirovaniye dopuska poka ne realizovano.

README i tekusjheye chelovekochitayemoye opisaniye soglasovanyi s rolyami vetok. Obratnaya dostavka, start ot tochnoj postanovki i kontur stabiljnogo vyipuska C[L,M] uzhe susjhestvuyut i ne izmenenyi. Deljta ne utverzhdayet vyipolnennuyu integraciyu, smenu default branch ili zaversheniye tekusjhego polnogo profilya drugoj zadachi.

Koordinator soobsjhil konkretnyij precedent: otdeljnoye derevo integratora s Pfull87, proverka 45 instrumentov/paketov ne chitayet zhivoye znacheniye fuma; upominaniye branch-next-step proveryayet susjhestvovaniye. Yego checkout, indeks, zavisimosti i konfiguraciya ostayutsya neizmennyimi. Eto sokhranyonnoye soobsjheniye koordinatora, ne nezavisimo vyipolnennyij zdesj povtor vsekh 45 proverok i ne universaljnyij dopusk dlya budusjhikh konturov. Perenosimostj opredelyayut zafiksirovannyiye vyishe usloviya.

Nezavisimyij obzor predlozheniya adaptacii podtverdil soglasovannostj tryokh iskhodov i neizvestnosti. V predyidusjhem zaprose ispravlena toljko neodnoznachnostj perechnya: STEP0165 i reyestr nazvanyi neizmenyonnyimi. Priyom Max ostayotsya nezavershyonnyim posle tryokh sokhranyonnyikh otkazov; povtor podgotovki ne zapuskalsya.

[Unasledovannaya granica proyekcii](materialyi/granica-sokhranyonnoj-proyekcii.json) sokhranena bez perepisyivaniya: pokoleniye ne pokryivayet novyiye kanonicheskiye fajlyi i yego nezavisimaya priyomka ne zavershena. Eto kontroljnaya tochka po000188, ne finaljnaya priyomka vsego proyekta.

## Istochniki

- [Zapros, oblastj i tochnyiye originalyi](zapros.md).

Pervaya [kvitanciya prefiksa](materialyi/sverka-pervichnogo-prefiksa.json) istoricheski otnositsya k snimku do voprosa ob osnovnoj papke. V nyom poslednim prosmotren vopros o zapisi fuma v otdeljnom dereve. Dlya pozdnego voprosa ob osnovnoj papke i otveta podgotovka soobsjheniya kommita vtoroj versii ispoljzuyet [novuyu kvitanciyu](materialyi/sverka-pervichnogo-prefiksa-2.json): granica 900558862, SHA-256 `f148db571e2cd30caacb56dca403402e158dc03644d2982a534b9906e03166b1`; ona pokryivayet diapazonyi [900408922, 900409375) i [900429494, 900430600). Obe kopii yavlyayutsya tochnyimi polnyimi zavershyonnyimi LF-prefiksami, pereproverennyimi SHA po native; prezhnyaya kvitanciya ne vyidayotsya za pokryivayusjhuyu pozdniye zapisi. Pozdnyaya aktualjnostj sveryayetsya otdeljno.


Chitayusjhij obzor obnaruzhil dvusmyislennoye trebovaniye otdeljnogo zaprosa na publikaciyu «osnovnoj vetki» v opisanii52. Posle pereopredeleniya yeyo kak fuma eta fraza konfliktovala so shtatnoj otpravkoj svoyej nemasternoj vetki. Ona adresno utochnena do postavki/publikacii master i PR; povtornogo razresheniya na soglasovannuyu otpravku fuma ne dobavleno. Budusjhij perenos fuma v osnovnuyu papku opisan kak celevoj, s yesjhyo ne vyipolnennyimi predposyilkami.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 14:04:55 MSK -->
<!-- content-sha256: sha256:0007bb2febaca49e1e64d76e0f81ac7467f18a8147bb83e4219d0d82131f29f5 -->
<!-- FUM-MD-RECENCY:END -->
