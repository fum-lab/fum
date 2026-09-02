# Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM

[Preobrazovaniye mezhdu nablyudatelyami FUM](../Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md) versii `1` — eto odna napravlennaya JSON-zapisj perekhoda ot zakreplyonnogo iskhodnogo sloya k predstavleniyu dlya drugogo [nablyudatelya FUM](../Glossarij/nablyudatelj-FUM.md). Zapisj pokazyivayet, kakiye signalyi byili dostupnyi po obe storonyi perekhoda, chto sokhranilosj, chto poteryalosj, na kakom osnovanii perekhod priznan obratimyim ili neobratimyim i mozhno li otdeljno perejti ot proizvodnoj formyi k sokhranyonnomu istochniku.

Format prevrasjhayet [nablyudateljskuyu otnositeljnostj FUM](../Glossarij/nablyudateljskaya-otnositeljnostj-FUM.md) v proveryayemyij dokumentaljnyij kontrakt. On ne trebuyet odinakovogo predstavleniya dlya cheloveka, LLM, CPU, GPU, servisa ili poduzla, no zapresjhayet molchalivo vyidavatj udobnuyu proyekciyu za iskhodnyij sloj.

## Yedinica formata

Odin obyyekt opisyivayet rovno odin perekhod `source → target` v obyyavlennoj oblasti `scope`. Napravleniye susjhestvenno: zapisj `A → B` nichego ne utverzhdayet o perekhode `B → A`, poka obratnoye preobrazovaniye ne nazvano i ne provereno. Cepochka `A → B → C` sostoit iz dvukh zapisej; yeyo invariantyi, poteri i obratimostj neljzya vyivoditj prostyim kopirovaniyem iz zvenjyev bez otdeljnoj proverki kompozicii.

`transformation_id` stabiljno identificiruyet zapisj v publikacionnom nabore versii `1` i ne pereispoljzuyetsya dlya drugogo smyisla perekhoda. Semanticheskij validator avtomaticheski skaniruyet vesj katalog etogo nabora i proveryayet unikaljnostj ID sovmestno, dazhe yesli yemu peredan toljko odin dopolniteljnyij fajl. `provenance_refs` svyazyivayet zapisj kak minimum s normativnyim opisaniyem formata i iskhodnyim trebovaniyem libo drugim osnovaniyem sozdaniya; otnositeljnyiye ssyilki razreshayutsya ot kornya pamyati FUM, a vneshniye osnovaniya poluchayut ustojchivyij publikacionnyij identifikator.

Tochnaya strukturnaya forma zakreplena v [JSON Schema versii 1](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json). Neizvestnyiye polya zapresjhenyi. Mezhpolevuyu ssyilochnuyu celostnostj, ischerpyivayusjhij uchyot signalov, sovmestimostj obratimosti s poteryami i zapret mashinno-lokaljnyikh putej proveryayet [semanticheskij validator versii 1](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py). Zapisj prinimayetsya toljko posle oboikh urovnej proverki. Izmeneniye sostava ili smyisla polej trebuyet novoj versii, a ne molchalivogo rasshireniya versii `1`.

Verkhneurovnevyij karkas soderzhit sleduyusjhiye polya; vlozhennyiye obyazateljnyiye polya i dopustimyiye znacheniya v primere opusjhenyi:

```json
{
  "schema_version": 1,
  "transformation_id": "...",
  "scope": {},
  "source": {},
  "target": {},
  "transformation": {},
  "signal_mappings": [],
  "invariants": [],
  "losses": [],
  "reversibility": {},
  "full_information_route": {},
  "provenance_refs": []
}
```

## Oblastj i storonyi perekhoda

`scope` zadayot nablyudayemuyu sistemu, utverzhdeniye o perekhode, dopustimoye mnozhestvo iskhodnyikh sostoyanij, predposyilki i isklyucheniya. Zdesj zhe opredelyayetsya «polnaya informaciya»: ne absolyutnoye sostoyaniye mira ili chuzhogo uzla i ne proizvoljnyij udobnyij nabor polej, a polnyij zakreplyonnyij `source` v yavno nazvannoj proyekcii. Iskhodnyiye signalyi dolzhnyi ischerpyivayusjhe razlozhitj etu proyekciyu dlya tochnogo snimka; primenimostj vyivoda ob obratimosti pri etom proveryayetsya na vsyom obyyavlennom `source_domain`, a ne toljko na odnom ekzemplyare.

`source` i `target` imeyut odinakovyij karkas:

- `layer_ref` ukazyivayet sloj ili artefakt otnositeljno kornya [pamyati FUM](../Glossarij/pamyatj-FUM.md) libo ustojchivyim publikacionnyim identifikatorom;
- `state_ref` zakreplyayet konkretnoye sostoyaniye, versiyu, khyesh ili identifikator proizvodnogo znacheniya;
- `representation` nazyivayet sistemu koordinat: bajtyi, UTF-8-tekst, Markdown, JSON, DOM, ekran, trassu, tenzor ili druguyu formu;
- `observer_profile` fiksiruyet klass nablyudatelya, urovenj abstrakcii, voplosjheniye, sistemu koordinat, dostupnyiye operacii i ogranicheniya dostupa;
- `observed_signals` perechislyayet dostupnyiye etomu nablyudatelyu signalyi s lokaljnyimi identifikatorami, smyislom, nositelem i ssyilkami na svideteljstva.
- `inventory_check` podtverzhdayet, chto perechislennyiye signalyi bez propuskov pokryivayut vsyo sootvetstvuyusjheye predstavleniye v obyyavlennoj proyekcii.

Yesli ischerpyivayusjhuyu inventarizaciyu neljzya podtverditj, zapisj yesjhyo ne prinimayetsya kak rezuljtat versii `1`: neizvestnyij ostatok nuzhno sdelatj otdeljnyim iskhodnyim signalom i uchestj kak sokhranyonnyij libo poteryannyij. Uspeshnaya proverka celevogo inventarya analogichno ne pozvolyayet skryitj celevoj vyivod, kotoromu ne ukazano proiskhozhdeniye.

Profilj nablyudatelya ne dokazyivayet [agentnostj FUM](../Glossarij/agentnostj-FUM.md) i ne vyidayot razresheniye na dejstviye. On toljko ogranichivayet, dlya kogo i pri kakikh usloviyakh utverzhdeniye o predstavlenii imeyet smyisl.

`transformation` nazyivayet pryamoj metod, yego versiyu, opisaniye, predusloviya i dostupnyiye ssyilki na realizaciyu. Otsutstvuyusjhaya realizaciya dopustima dlya dokumentaljnogo ili matematicheskogo pravila, no togda proverka ne dolzhna pritvoryatjsya ispolneniyem nesusjhestvuyusjhego koda.

## Karta signalov i poterj

`signal_mappings` svyazyivayet odin ili neskoljko iskhodnyikh signalov s odnim ili neskoljkimi celevyimi. Kazhdaya svyazj soderzhit pravilo, status, `invariant_ids` i nablyudayemoye svideteljstvo. `preserved` oznachayet sokhraneniye obyyavlennoj semanticheskoj ekvivalentnosti, a ne obyazateljno bajtovoye tozhdestvo, i trebuyet khotya byi odnogo svyazannogo invarianta s itogom `passed`; `transformed` oboznachayet vyichislennoye predstavleniye bez samostoyateljnogo zayavleniya o sokhranenii; `aggregated` obyyedinyayet neskoljko razlichij ili znachenij. Otsutstviye poteri sleduyet ne iz odnogo nazvaniya statusa, a iz invariantov i proverki obratimosti. Kazhdyij celevoj signal dolzhen imetj proiskhozhdeniye v karte; otdeljno porozhdyonnyij vyivod vsyo ravno svyazyivayetsya so svoimi vkhodnyimi signalami i pravilom vyivoda.

Dlya kazhdogo iskhodnogo signala vnutri `scope` obyazano vyipolnyatjsya khotya byi odno iz uslovij:

1. signal pokryit khotya byi odnoj zapisjyu `signal_mappings`;
2. signal yavno vklyuchyon v `losses`.

Eti usloviya ne obrazuyut isklyuchayusjheye «ili». Yesli mapping peredayot toljko chastj razlichij iskhodnogo signala, tot zhe `signal_id` odnovremenno vklyuchayetsya v `losses`; inache agregaciya, kvantizaciya ili chastichnaya redakciya mogli byi vyiglyadetj kak polnoye sokhraneniye. Aljternativa — zaraneye razlozhitj nositelj na otdeljnyiye atomarnyiye signalyi i nezavisimo uchestj sokhranyonnuyu i utrachennuyu chasti. Status mapping sam po sebe ne dokazyivayet otsutstviye poteri: eto sleduyet iz obyyavlennoj ekvivalentnosti, invariantov i proverki obratimosti.

Pri uspeshnom `inventory_check` takoj sploshnoj uchyot ne pozvolyayet detali iskhodnoj proyekcii ischeznutj mezhdu sloyami bez otmetki. Poterya fiksiruyet zatronutyiye signalyi, vid, prichinu, posledstviye, vozmozhnostj vosstanovleniya toljko iz celevogo predstavleniya i svideteljstva. Versiya `1` razlichayet propusk, agregaciyu, kvantizaciyu, redaktirovaniye po dostupu, nedostupnostj, neodnoznachnostj, utratu proiskhozhdeniya i prekrasjheniye khraneniya. Etot slovarj opisyivayet nablyudayemyij iskhod perekhoda, a ne universaljnuyu teoriyu informacii.

## Sokhranyayemyiye invariantyi

`invariants` soderzhit ne obsjhiye pozhelaniya, a proveryayemyiye otnosheniya mezhdu storonami perekhoda. Dlya kazhdogo invarianta zadayutsya:

- lokaljnyij identifikator;
- utverzhdeniye;
- sravnivayemyiye vyirazheniya na iskhodnoj i celevoj storone;
- otnosheniye ekvivalentnosti;
- metod, itog `passed`, `failed` ili `inconclusive` i ssyilki na svideteljstva.

Invariant schitayetsya sokhranyonnyim toljko pri `passed`. Bajtovoye ravenstvo yavlyayetsya odnim iz vozmozhnyikh otnoshenij, no ne znacheniyem po umolchaniyu: sokhraneniye zagolovka, poryadka sobyitij ili avtorizovannogo namereniya trebuyet sobstvennogo yavno sformulirovannogo sravneniya.

## Proverka obratimosti ili neobratimosti

`reversibility` otdelyayet vozmozhnostj vosstanovitj istochnik iz celevogo znacheniya ot vozmozhnosti nezavisimo otkryitj sokhranyonnyij istochnik. V versii `1` dostupnyi chetyire vyivoda:

- `reversible` — v obyyavlennoj oblasti ukazano obratnoye preobrazovaniye i uspeshnyij round-trip sokhranyayet iskhodnuyu ekvivalentnostj;
- `partially_reversible` — obratnyij metod vosstanavlivayet toljko yavno perechislennoye sobstvennoye podmnozhestvo iskhodnyikh signalov, a kazhdyij signal vne nego imeyet nevosstanovimuyu poteryu;
- `irreversible` — proverennaya kolliziya libo inoye svideteljstvo neinyyektivnosti pokazyivayet, chto celevoye znacheniye ne opredelyayet iskhodnoye;
- `undetermined` — imeyusjhikhsya svideteljstv nedostatochno; takoj vyivod dopustim dlya chestnogo chernovika, no ne podtverzhdayet vyipolnennuyu proverku obratimosti ili neobratimosti.

Proverka vyipolnyayetsya v sleduyusjhem poryadke:

1. Proveritj strukturnuyu skhemu, unikaljnostj identifikatorov, ssyilki, oblastj, ischerpyivayusjhiye inventari storon i sploshnoye pokryitiye iskhodnyikh i celevyikh signalov.
2. Vyipolnitj ili vosproizvesti pryamoj metod `F` na zakreplyonnyikh iskhodnyikh primerakh.
3. Proveritj celevyiye signalyi i kazhdyij zayavlennyij invariant.
4. Dlya `reversible` proveritj `G(F(s)) ≈S s`; yesli oblastj celevyikh znachenij obyyavlena polnostjyu, dopolniteljno proveritj `F(G(t)) ≈T t`.
5. Dlya `partially_reversible` vyipolnitj tot zhe round-trip toljko dlya perechislennogo sobstvennogo vosstanavlivayemogo podmnozhestva, proveritj otsutstviye yego peresecheniya s nevosstanovimyimi poteryami i yavno uchestj nevosstanovimoj poterej kazhdyij ostaljnoj iskhodnyij signal.
6. Dlya `irreversible` predyyavitj `s1 ≉S s2`, dlya kotoryikh `F(s1) ≈T F(s2)`, libo otdeljnoye proveryayemoye dokazateljstvo neinyyektivnosti. Neudacha odnogo kandidata `G` sama po sebe neobratimostj ne dokazyivayet.
7. Zafiksirovatj metod, rezuljtat, svideteljstva i granicu vyivoda. Konechnaya fikstura podtverzhdayet svoj domen, a ne universaljnoye svojstvo vsekh vozmozhnyikh vkhodov.

Zayavleniye `reversible` nesovmestimo s nevosstanovimoj poterej v obyyavlennom `scope`. Zayavleniye `irreversible` trebuyet khotya byi odnoj yavnoj poteri s `recoverable_from_target = false`; kolliziya bez sootvetstvuyusjhego uchyota poteri ne prinimayetsya. Dostupnaya ssyilka na original ne ustranyayet kolliziyu pryamogo preobrazovaniya: ona dayot drugoj putj chteniya, no ne prevrasjhayet celevoye znacheniye v dostatochnyij vkhod obratnoj funkcii.

## Marshrut k polnoj informacii

`full_information_route` proveryayetsya nezavisimo ot `reversibility`. Polnyij putj nachinayetsya v `target_delivery_context`: versiya `1` trebuyet materializovannyij kontekst postavki, kotoryij ukazyivayet na postavlyayemuyu ryadom sidecar-zapisj. Vlozhennyij `record_discovery` fiksiruyet `delivery_context_ref`, lokator, sposob svyazatj tochnyiye `transformation_id` i `target.state_ref`, a takzhe uspeshnuyu proverku. Posle obnaruzheniya zapisi `source_binding` obyazan tochno sovpastj s `source.layer_ref` i `source.state_ref`, a shagi vedut k tomu zhe zakreplyonnomu istochniku. Goloye celevoye znacheniye bez proverennoj svyazi s zapisjyu ne udovletvoryayet trebovaniyu navigacii versii `1`; vstroyennaya zapisj i vneshnij reyestr ostayutsya kandidatami sleduyusjhej versii.

Marshrut imeyet odin iz statusov:

- `available` — shagi razreshayutsya pri zayavlennyikh ogranicheniyakh, vedut k tochnomu iskhodnomu sostoyaniyu, a `covered_signal_ids` tochno pokryivayet vesj iskhodnyij inventarj;
- `restricted` — marshrut i istochnik izvestnyi i `covered_signal_ids` pokryivayet vesj iskhodnyij inventarj, no dlya chteniya nuzhno yavno ukazannoye pravo ili vneshneye usloviye;
- `unavailable` — perekhod k obyyavlennomu istochniku nevozmozhen; zapisj nazyivayet prichinu, zatronutyiye signalyi i svideteljstvo granicyi.

Vse tri statusa yavlyayutsya proverennyimi utverzhdeniyami i trebuyut `check.status = passed`; nedostatok svideteljstv ne razreshayet nazvatj marshrut dostupnyim, ogranichennyim ili nevozmozhnyim. Marshrut zadayot mashinnyij okhvat po identifikatoram signalov, ssyilki na istochnik, posledovateljnostj shagov, ogranicheniya dostupa i otdeljnuyu proverku. Ssyilka na obsjhij tezis, budusjhij pasport ili pokhozhij dokument ne schitayetsya marshrutom k tochnomu iskhodnomu snimku. Mashinno-lokaljnyiye absolyutnyiye puti, sekretyi, tokenyi i privatnyiye URL zapresjhenyi; ispoljzuyutsya otnositeljnyiye puti pamyati ili ustojchivyiye publikacionnyiye identifikatoryi.

## Lokaljnyiye proverochnyiye primeryi

[Obratimaya fikstura](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-obratimogo-preobrazovaniya.json) rassmatrivayet stroguyu dekodirovku bajtov statji `Глоссарий/FUM.md` v UTF-8-tekst. Povtornoye kodirovaniye dayot iskhodnuyu posledovateljnostj bajtov, poteri otsutstvuyut, a [materializovannyij kontekst postavki](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-obratimoj-fiksturyi.json) obnaruzhivayet zapisj po tochnomu `binding` i vedyot k fajlu, podtverzhdyonnomu SHA-256.

[Neobratimaya fikstura](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-neobratimogo-preobrazovaniya.json) zakreplyayet odin ekzemplyar statji vnutri domena Markdown-dokumentov i izvlekayet toljko pervyij zagolovok. Zagolovok `FUM` sokhranyayetsya, ostaljnoye soderzhimoye yavno teryayetsya, a stroki `# FUM\n\nA\n` i `# FUM\n\nB\n` iz togo zhe domena obrazuyut proverennuyu kolliziyu. Yeyo [kontekst postavki](38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-neobratimoj-fiksturyi.json) obnaruzhivayet sidecar-zapisj, kotoraya po-prezhnemu vedyot k polnoj iskhodnoj statjye; navigaciya ostayotsya nezavisimoj ot obratimosti.

Obe fiksturyi publikacionno chistyi, ne trebuyut seti, sekretov ili modeljnogo provajdera. Semanticheskij validator na standartnoj biblioteke Python proveryayet identifikatoryi, ssyilochnuyu celostnostj, inventari, pokryitiye signalov, soglasovannostj poterj s obratimostjyu, mashinno-lokaljnyiye puti i marshrutyi. Lokaljnaya predmetnaya proverka dopolniteljno sveryayet tochnyij khyesh istochnika, invariantyi, UTF-8 round-trip i kolliziyu.

## Granica primenimosti

Versiya `1` opisyivayet fiksaciyu odnogo perekhoda mezhdu dvumya obyyavlennyimi predstavleniyami dokumentacionnogo prototipa FUM. Ona ne yavlyayetsya runtime, kompilyatorom, transportom, universaljnoj ontologiyej nablyudatelej, chislovoj metrikoj informacionnoj poteri ili razresheniyem na chteniye i dejstviye. Format ne vosstanavlivayet skryitoye vnutrenneye sostoyaniye nablyudatelya, ne sokhranyayet skryityiye rassuzhdeniya modeli i ne dokazyivayet tozhdestvo raznyikh urovnej sistemyi. On zakreplyayet toljko strukturu materializovannoj svyazi s sidecar-zapisjyu; konkretnyij transport sidecar, vstroyennaya zapisj i ustrojstvo vneshnego reyestra ostayutsya za predelami versii `1`.

Kompoziciya perekhodov, potokovyiye preobrazovaniya, veroyatnostnyiye predstavleniya, stoimostj, zaderzhka, kriptograficheskoye proiskhozhdeniye i obsjhaya metrika kachestva ostayutsya posleduyusjhimi sloyami. Pri ikh dobavlenii neljzya oslablyatj yavnyij uchyot signalov, poterj, invariantov, obratimosti i marshruta k istochniku.

[Minimaljnyij pasport peredavayemogo rezuljtata FUM](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md) mozhet svyazatj marshrut peredachi s etoj zapisjyu preobrazovaniya, yesli adresat poluchayet inoye predstavleniye rezuljtata. Status dostavki ostayotsya nezavisimyim ot sokhraneniya invariantov, obratimosti i marshruta k polnomu istochniku: uspeshnyij transport ne dokazyivayet ni odnogo iz etikh svojstv.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 12:53:46 MSK - Opisatj minimaljnyij pasport peredavayemogo rezuljtata FUM](../Zhurnal/2026-07-23_12-53-46_MSK_opisatj-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/zapros.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-26 11:39:57 MSK](../Zhurnal/2026-06-26_11-39-57_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [kartochka FUM-STEP-0025](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0025-opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)

## Opornyiye materialyi

- [Interfejs FUM-uzla](25-interfejs-FUM-uzla.md)
- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Reyestr kartochek sootvetstviya FUM](28-reyestr-kartochek-sootvetstviya-FUM/README.md)
- [Minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)
- [otkryityij vopros ob abstrakcii urovnej nablyudayemoj Vselennoj](../Voprosyi/2026-06-26_12-19-03_MSK_abstrakciya-urovnej-nablyudayemoj-vselennoj-FUM.md)
- [otkryityij vopros o granicakh yestestvenno-yazyikovoj sinkhronizacii znanij](../Voprosyi/2026-07-13_20-34-23_MSK_granicyi-yestestvenno-yazyikovoj-sinkhronizacii-znanij-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2be60bcf87b44883f5a08631ba1cf0bb1abe349ad5f21d8492238133bc21aa52 -->
<!-- FUM-MD-RECENCY:END -->
