# Predregistraciya sravniteljnoj eksperimentaljnoj priyomki preimusjhestv FUM

Kartochka versii `1` zaraneye fiksiruyet budusjhuyu sravniteljnuyu proverku utverzhdeniya, chto [FUM](../Glossarij/FUM.md) uluchshayet vneshne nablyudayemuyu sposobnostj agenta pri odinakovyikh ogranicheniyakh. Ona otdelyayet effektyi mekhanicheskikh tochek vosstanovleniya, proveryayemoj pamyati, kontekstno ogranichennyikh rabochikh paketov, otdeljnogo proveryayusjhego i neskoljkikh razlichimyikh [poduzlov](../Glossarij/poduzel-FUM.md).

Izmeryayemyiye progonyi po etoj kartochke ne vyipolnyalisj. Planovyiye polya nizhe neljzya menyatj posle nachala pervoj izmeryayemoj serii: soderzhateljnoye izmeneniye vyipuskayet novuyu versiyu s otdeljnyim identifikatorom i ssyilkoj na etu kartochku.

## Pasport

- **Identifikator i versiya:** `fum-comparative-acceptance; 1`.
- **Nazvaniye:** `Сравнительная экспериментальная приёмка преимуществ FUM`.
- **Tip sredyi:** `модельная`, a dlya lokaljnyikh snimkov zadach takzhe `текст, данные и код`.
- **Sozdayusjhij uzel ili nablyudatelj:** dokumentacionnyij prototip FUM formiruyet protokol; budusjhij ispolnitelj serii i otdelyonnyij vneshnij ocensjhik dolzhnyi byitj nazvanyi v neizmenyayemom manifeste zapuska.
- **Data sozdaniya:** `2026-08-02 MSK`.
- **Istochnik voprosa:** [trebovaniye o sravniteljnoj eksperimentaljnoj priyomke](../Trebovaniya/🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md).
- **Predshestvuyusjhaya versiya ili roditeljskij eksperiment:** `нет`.
- **Urovenj dostupa i dopustimyiye operacii:** kartochka publikacionno otkryita; budusjhemu ispolnitelyu razreshayutsya toljko chteniye zakreplyonnogo otkryitogo vkhoda, modeljnyiye i lokaljnyiye instrumentaljnyiye dejstviya vnutri odnorazovoj izolirovannoj kopii i sokhraneniye trassyi. Setj, platnyij provajder, publikaciya dannyikh, izmeneniye chuzhogo repozitoriya ili remote i raskryitiye skryitogo ocensjhika ne razreshenyi etoj kartochkoj.

## Vopros

- **Issledovateljskij vopros:** povyishayet li odnoagentnyij FUM s proveryayemoj pamyatjyu i kontekstno ogranichennyimi rabochimi paketami dolyu avtonomno prinyatyikh vneshnim ocensjhikom reshenij po sravneniyu s obyichnyim agentskim ciklom pri obsjhej bazovoj modeli, odinakovom agregatnom byudzhete i odnom vneshnem kriterii zaversheniya?
- **Pochemu vopros vazhen:** lokaljnaya celostnostj, chislo artefaktov i zavershyonnyiye shagi ne dokazyivayut poleznostj agenta; do uslozhneniya arkhitekturyi nuzhno izmeritj vneshnyuyu sposobnostj i cenu kazhdogo dobavlennogo mekhanizma.
- **Vkhodit v oblastj:** shestj zaraneye zadannyikh variantov, zakryityij nabor lokaljno vosproizvodimyikh zadach, skryitaya priyomka, prinuditeljnyiye sboi, konfliktyi i povrezhdeniye pamyati, tri povtora i perechislennyiye nizhe metriki.
- **Ne vkhodit v oblastj:** universaljnoye preimusjhestvo FUM, perenos na drugiye modeli i domenyi, kachestvo dolgoj realjnoj ekspluatacii, power-loss durability, semanticheskaya nezavisimostj odinakovyikh modelej, bezopasnostj proizvoljnogo vneshnego dejstviya i produktovaya gotovnostj.

## Gipoteza

- **Proveryayemoye utverzhdeniye:** variant `V3` — odnoagentnyij FUM s proveryayemoj pamyatjyu i rabochimi paketami — pri odinakovyikh agregatnyikh ogranicheniyakh prevoskhodit obyichnyij cikl `V0` po avtonomnomu vneshnemu uspekhu minimum na `10` procentnyikh punktov i ne uvelichivayet lozhnoye zaversheniye boleye chem na `3` procentnyikh punkta.
- **Ozhidayemoye nablyudeniye:** na vsekh `50` osnovnyikh zadachakh parnaya raznostj dolej avtonomnogo vneshnego uspekha `V3 - V0` ne menjshe `+0,10`, nizhnyaya granica yeyo `95 %` klasternogo bootstrap-intervala vyishe `0`, a verkhnyaya granica `95 %` intervala raznosti lozhnyikh zavershenij ne vyishe `+0,03`.
- **Usloviye oproverzheniya:** verkhnyaya granica `95 %` intervala raznosti avtonomnogo vneshnego uspekha `V3 - V0` ne vyishe `0` libo nizhnyaya granica intervala raznosti lozhnyikh zavershenij vyishe `+0,03`.
- **Neodnoznachnyij iskhod:** vse ostaljnyiye rezuljtatyi, nedostatok khotya byi odnoj osnovnoj zadachi, narusheniye slepotyi, smena protokola ili otsutstviye doverennogo izmereniya obyazateljnoj metriki ne podderzhivayut i ne oprovergayut gipotezu.
- **Konkuriruyusjhiye obyyasneniya:** preimusjhestvo mozhet byitj vyizvano toljko checkpoint, toljko pamyatjyu, toljko rabochimi paketami, otdeljnyim proveryayusjhim, parallelizmom poduzlov, poryadkom zapuskov, versiyej provajdera ili neravnyim byudzhetom. Sosedniye variantyi i blochnaya randomizaciya prednaznachenyi dlya ikh razlicheniya.
- **Iskhodnyij issledovateljskij status:** `гипотеза FUM`.

## Metod

### Variantyi

Kazhdyij variant nasleduyet predyidusjhij i dobavlyayet rovno odno novoye vozdejstviye. Vse unasledovannyiye mekhanizmyi sokhranyayut odnu i tu zhe versiyu; smeshivatj izmeneniye mekhanizma s izmeneniyem prompt, modeli, byudzheta ili ocensjhika zapresjheno.

| Kod | Nazvaniye                                | Unasledovannaya osnova | Yedinstvennoye novoye vozdejstviye                                                                                  |
| --- | --------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------- |
| V0  | Obyichnyij agentskij cikl                  | net                   | kontrolj: obyichnyij linejnyij agent bez checkpoint, proveryayemoj pamyati, rabochikh paketov i otdeljnyikh rolej          |
| V1  | Kontrolj s tochkami vosstanovleniya       | V0                    | mekhanicheskij checkpoint tochnoj trassyi i runtime-kursora bez semanticheskoj pamyati FUM                            |
| V2  | Odnoagentnyij cikl s proveryayemoj pamyatjyu | V1                    | adresuyemyiye podtverzhdyonnyiye pokoleniya pamyati; kontekstno ogranichennyikh rabochikh paketov yesjhyo net                     |
| V3  | Odnoagentnyij FUM                        | V2                    | kontekstno ogranichennyij rabochij paket s celjyu, vkhodami, byudzhetom, proverkami i yavnoj peredachej                  |
| V4  | FUM s otdeljnyim proveryayusjhim             | V3                    | odna otdelyonnaya rolj proveryayusjhego bez prava avtorskogo ispravleniya; proizvoditelj ostayotsya odin                 |
| V5  | FUM s neskoljkimi poduzlami             | V4                    | ne meneye dvukh razlichimyikh proizvoditelej s otdeljnyimi rolyami, paketami i proiskhozhdeniyem; proveryayusjhij ne menyayetsya |

`V2` nuzhen, chtobyi ne pripisyivatj sovmestnyij effekt pamyati i rabochikh paketov odnomu vozdejstviyu. `V5` nasleduyet yedinstvennogo proveryayusjhego `V4`, poetomu sosedneye sravneniye `V5 - V4` menyayet toljko chislo i razdeleniye proizvoditelej. Razlichimostj oznachayet raznyiye identifikatoryi rolej, vkhodnyiye paketyi i proiskhozhdeniye, no pri obsjhej bazovoj modeli ne obyyavlyayetsya semanticheskoj nezavisimostjyu.

### Obsjhiye usloviya

- Tochnyij identifikator i reviziya bazovoj modeli, provider identity, parametryi semplirovaniya, bazovyij sistemnyij prompt, runtime-obraz, OS, instrumentaljnyij allowlist, publichnyij tekst zadachi i iskhodnyij snimok fiksiruyutsya v manifeste do pervogo izmeryayemogo progona. Razlichayetsya toljko minimaljnaya zaraneye khyeshirovannaya obyortka, neobkhodimaya dlya obyyavleniya mekhanizma i rolej konkretnogo varianta; ona ne soderzhit podskazok po zadache, skryityikh kriteriyev ili dopolniteljnyikh polnomochij.
- Dlya kazhdoj zadachi odin vneshnij ocensjhik ispoljzuyet odin i tot zhe skryityij kontrakt zaversheniya vo vsekh variantakh. Vnutrenneye soobsjheniye agenta o zavershenii ne yavlyayetsya uspekhom.
- Kazhdyij progon zavershayetsya po odnomu pravilu: pri pervom terminaljnom zayavlenii ispolnitelya, dostizhenii obsjhego limita libo srabatyivanii obsjhej politiki bezopasnosti. Posle etogo odin i tot zhe vneshnij ocensjhik opredelyayet uspekh; skryityij otkaz ne otkryivayet dopolniteljnuyu popyitku.
- Na odin progon prikhoditsya obsjhij predel: `24` modeljnyikh vyizova, `120 000` vkhodnyikh tokenov, `24 000` vyikhodnyikh tokenov, `180` instrumentaljnyikh vyizovov, `90` minut wall-clock i `25 USD` fakticheskoj stoimosti. Menjshij provider-limit, neobkhodimyij dlya otdeljnogo razresheniya, zapisyivayetsya novoj versiyej do serii, a ne menyayetsya mezhdu variantami.
- `V4` i `V5` delyat tot zhe agregatnyij predel mezhdu proizvoditelyami i proveryayusjhim; umnozheniye byudzheta na chislo rolej zapresjheno. Vremya paralleljnyikh processov schitayetsya po wall-clock, a tokenyi, vyizovyi i denjgi summiruyutsya po vsem processam varianta.
- Soderzhateljnaya pomosjhj cheloveka ne predusmotrena. Lyuboye izmeneniye resheniya, prompt, fajlov ili vyibora instrumenta chelovekom registriruyetsya kak vmeshateljstvo; takoj progon ne mozhet datj pervichnyij avtonomnyij uspekh, no ne udalyayetsya iz vyiborki.
- V kazhdoj izmeryayemoj popyitke ispoljzuyetsya svezhaya odnorazovaya kopiya tochnogo iskhodnogo snimka. Sostoyaniye, soobsjheniya, kyesh i pamyatj odnogo varianta, zadachi ili povtora ne perenosyatsya v drugoj.

### Zadachi, obyyom i povtoryi

- Osnovnaya vyiborka soderzhit rovno `50` nezavisimyikh zadach: po `10` v kazhdom iz pyati zaraneye zadannyikh sloyov — neodnoznachnostj, skryitaya funkcionaljnaya priyomka, prinuditeljnoye preryivaniye, konflikt izmenenij i povrezhdyonnaya pamyatj.
- Do raskryitiya rezuljtatov otdeljno zapechatyivayutsya po `2` rezervnyiye zadachi kazhdogo sloya. Rezerv zamenyayet toljko zadachu, priznannuyu nevalidnoj iz-za dokazannoj utechki, povrezhdeniya ocensjhika, nevernoj licenzii ili infrastrukturnoj oshibki do pervogo modeljnogo otveta; oshibku agenta, ischerpaniye byudzheta i neuspekh ne zamenyayut.
- Kazhdaya para `задача × вариант` vyipolnyayetsya `3` raza v svezhikh sredakh. Minimaljnaya izmeryayemaya seriya ravna `50 × 6 × 3 = 900` progonam; yedinicej statisticheskogo vyivoda ostayotsya zadacha, a povtoryi vlozhenyi v neyo.
- Yesli provider podderzhivayet zakreplyayemyij seed, odna i ta zhe trojka seed ispoljzuyetsya dlya vsekh shesti variantov odnoj zadachi. Inache nezavisimostj povtora obespechivayetsya svezhej sessiyej i sluchajnyim poryadkom, a otsutstviye upravlyayemogo seed fiksiruyetsya kak ogranicheniye.
- Poryadok variantov balansiruyetsya vnutri kazhdogo bloka `задача × повтор` determinirovannoj perestanovkoj iz zaraneye opublikovannogo seed randomizacii. Analiz do zakryitiya vsekh osnovnyikh blokov zapresjhyon.

### Inyyekcii uslovij

- V sloye neodnoznachnosti otkryityij tekst namerenno dopuskayet ne meneye dvukh razumnyikh traktovok; skryityij kontrakt zaraneye opredelyayet, yavlyayetsya li prinyatyim rezuljtatom bezopasnoye utochneniye, yavnaya ostanovka ili realizaciya invarianta, obsjhego dlya traktovok.
- Skryitaya funkcionaljnaya priyomka primenyayetsya ko vsem zadacham, a otdeljnyij sloj soderzhit zadachi, gde publichnyiye testyi nedostatochnyi i osnovnoj defekt obnaruzhivayetsya toljko zakryityim naborom.
- V sloye preryivaniya harness zavershayet process srazu posle pervoj nenulevoj prinyatoj pravki rabochego dereva i do sleduyusjhego modeljnogo otveta. Novyij process `V0` poluchayet toljko iskhodnyij prompt i sokhranivshuyusya rabochuyu kopiyu; `V1`–`V5` poluchayut toljko sostoyaniye, razreshyonnoye svoim variantom.
- V sloye konfliktov harness posle pervoj prinyatoj pravki primenyayet odin zaraneye zapechatannyij konfliktuyusjhij patch k toj zhe lokaljnoj kopii. Setj, remote i izmeneniye iskhodnogo chuzhogo repozitoriya ne ispoljzuyutsya.
- V sloye povrezhdyonnoj pamyati odin proizvodnyij artefakt prodolzheniya zamenyayetsya zaraneye podgotovlennoj versiyej s pravdopodobnyim, no nevernyim utverzhdeniyem; kanonicheskij istochnik ostayotsya dostupen dlya proverki. `V0` i `V1` poluchayut tot zhe material kak obyichnuyu zametku prodolzheniya, a `V2`–`V5` — kak nepodtverzhdyonnyij kandidat pamyati. Eta neizbezhnaya raznica analiziruyetsya otdeljno i ne schitayetsya chistyim strukturnyim ravenstvom nositelej.

### Politika povtorov i ostanovki

- Do `900` validnyikh osnovnyikh progonov net rannej ostanovki po uspekhu, neuspekhu, ozhidayemoj bespoleznosti ili promezhutochnoj velichine effekta.
- Do serii vyipolnyayutsya ne boleye `6` tekhnicheskikh shakedown-zadach, otsutstvuyusjhikh v osnovnoj i rezervnoj vyiborkakh. Ikh rezuljtatyi ne vkhodyat v analiz i ne razreshayut nastraivatj variantyi po skryityim iskhodam.
- Odin infrastrukturnyij perezapusk dopustim toljko yesli sboj proizoshyol do pervogo modeljnogo otveta, pervoj zapisi i raskhoda izmeryayemogo byudzheta. Posle lyubogo iz etikh sobyitij oshibka ostayotsya iskhodom progona.
- Seriya ostanavlivayetsya bez vyivoda o gipoteze pri otzyive razresheniya, prevyishenii zaraneye razreshyonnoj obsjhej stoimosti, smene modeli ili evaluator-obraza, dokazannoj utechke bez zapechatannogo rezerva, narushenii izolyacii, potere obyazateljnoj trassyi libo riske dlya dannyikh i vneshnikh sistem.
- Planovoye zaversheniye nastupayet posle `900` validnyikh osnovnyikh progonov i zakryitiya nabora rezuljtatov. Dobavleniye nablyudenij posle prosmotra effekta zapresjheno; rasshireniye trebuyet novoj versii i otdeljnogo analiza.

## Dannyiye

- **Vkhodyi:** zapechatannyij manifest soderzhit `task_id`, sloj, licenziyu, SHA-256 iskhodnogo snimka, SHA-256 otkryitogo prompt, SHA-256 evaluator-obraza i skryitogo kontrakta, raspisaniye inyyekcij, variant, povtor, seed, modelj, runtime, instrumentyi i vse byudzhetyi.
- **Preobrazovaniya:** orkestrator sozdayot svezhuyu kopiyu, primenyayet toljko obyyavlennuyu konfiguraciyu varianta, zapuskayet inyyekcii po nablyudayemyim sobyitiyam, sobirayet tipizirovannuyu trassu i posle terminala peredayot itog otdeljnomu ocensjhiku.
- **Vyikhodyi i svideteljstva:** polnyij zhurnal model- i tool-vyizovov, provider usage, monotonnoye vremya, snimki checkpoint i pamyati, proiskhozhdeniye rabochikh paketov i rolej, patch i derevo rezuljtata, iskhod skryitoj priyomki, vmeshateljstva, konfliktyi, regressii i khyeshi vsekh artefaktov.
- **Polnota i smesjheniya:** pyatj sloyov pokryivayut zaraneye vyibrannyiye vidyi nagruzki, no ne predstavlyayut vse yazyiki, repozitorii, dliteljnosti i realjnyiye sredyi; zadacha yavlyayetsya yedinicej vyivoda, poetomu tri povtora ne izobrazhayutsya kak `150` nezavisimyikh zadach.
- **Dostup i chuvstviteljnostj:** otkryityiye vkhodyi dolzhnyi imetj publikacionno dopustimuyu licenziyu. Skryityiye testyi, rezuljtatyi i provider-trassyi ostayutsya v razreshyonnom zakryitom khranilisjhe do otdeljnogo resheniya o publikacii; sekretyi i personaljnyiye dannyiye v nabor ne vkhodyat.

### Zasjhita ot utechki skryityikh kriteriyev

- Kurator nabora i vneshnij ocensjhik otdelenyi ot ispolnitelej variantov. Do zapuska publikuyutsya toljko khyeshi polnogo task-manifest i evaluator-obraza; soderzhimoye skryitogo kontrakta ne popadayet v prompt, rabochuyu kopiyu, peremennyiye sredyi, dostupnyiye puti ili setj ispolnitelya.
- Ocensjhik zapuskayetsya posle terminaljnogo iskhoda v otdeljnoj chistoj kopii i vozvrasjhayet orkestratoru toljko tipizirovannyij itog i metriki. Imena skryityikh testov, ozhidayemyiye znacheniya i diagnosticheskiye logi ne vozvrasjhayutsya ispolnitelyu i ne ispoljzuyutsya dlya sleduyusjhego povtora.
- Mezhdu progonami zapresjhenyi obsjhaya modeljnaya istoriya, obsjhaya FUM-pamyatj, kyesh skryitogo vyivoda i ruchnaya korrektirovka. Dostup k evaluator-artefaktu ili povtornoye ispoljzovaniye raskryitogo kriteriya delayet zadachu nevalidnoj vo vsekh variantakh do raskryitiya sravniteljnyikh itogov.
- Rezervnaya zamena vyibirayetsya po zaraneye zafiksirovannomu poryadku vnutri togo zhe sloya. Posle raskryitiya uslovij ili agregatov zamenyatj zadachi neljzya.

## Sreda

- **Tip sredyi:** `модельная` i `текст, данные и код` v odnorazovyikh lokaljnyikh kopiyakh.
- **Sostav i versii:** tochnyiye modelj, provider, runtime, OS, biblioteki, CLI, evaluator i orkestrator fiksiruyutsya khyeshami i versiyami v manifest serii; kartochka ne podmenyayet etot vosproizvodimyij snimok.
- **Setj, sekretyi i razresheniya:** tekusjhaya predregistraciya ne trebuyet i ne razreshayet setj, sekretyi ili oplatu. Lyuboj realjnyij provider, zagruzka nabora, vneshnij repozitorij ili platnyij raskhod trebuyut otdeljnogo yavnogo razresheniya do sozdaniya manifest serii.
- **Razreshyonnyiye effektyi:** posle otdeljnogo razresheniya — zapisj toljko v odnorazovyiye lokaljnyiye kopii i zakryitoye khranilisjhe artefaktov eksperimenta v predelakh obyyavlennogo byudzheta.
- **Zapresjhyonnyiye effektyi:** push, publikaciya rezuljtatov, izmeneniye chuzhogo checkout ili remote, dejstviye nad poljzovateljskimi dannyimi, sozdaniye uchyotnyikh zapisej, pokupka dostupa i perenos skryityikh kriteriyev ispolnitelyu.
- **Granica vosproizvodimosti:** protokol i budusjhij lokaljnyij harness dolzhnyi byitj vosproizvodimyi bez seti na zapisannyikh fiksturakh; model- i provider-nedeterminizm, zakryityij nabor i platnaya chastj zhivoj serii vosproizvodyatsya toljko pri otdeljnom dostupe i razreshenii.

Rezuljtatyi modeljnoj sredyi otnosyatsya toljko k zakreplyonnyim modeli, runtime, zadacham i usloviyam i ne yavlyayutsya nablyudeniyami vneshnego mira sami po sebe.

## Proverka

### Vneshnij kriterij i analiz

- **Uspekh otdeljnogo progona:** skryityij kontrakt vozvrasjhayet `accepted`, vse obyazateljnyiye testyi i task-specific rubric-porogi projdenyi, zapresjhyonnogo effekta net i byudzhet ne prevyishen.
- **Avtonomnyij vneshnij uspekh:** vneshnij uspekh poluchen bez soderzhateljnogo vmeshateljstva cheloveka; eto pervichnaya binarnaya metrika.
- **Podderzhka gipotezyi:** vyipolnenyi vse usloviya ozhidayemogo nablyudeniya dlya `V3 - V0` na polnoj osnovnoj vyiborke.
- **Oproverzheniye gipotezyi:** vyipolneno khotya byi odno zaraneye zadannoye usloviye oproverzheniya.
- **Neodnoznachnyij iskhod:** podderzhka i oproverzheniye ne dostignutyi libo narushena polnota ili validnostj serii.
- **Lokaljnyij sposob proverki:** validator zanovo sveryayet manifest, chislo blokov, khyeshi, byudzhetyi i polnotu metrik, zatem vyichislyayet task-level sredneye tryokh povtorov i `10 000` klasternyikh bootstrap-perevyiborok zadach s zakreplyonnyim seed analiza.
- **Sosedniye sravneniya:** `V1 - V0`, `V2 - V1`, `V3 - V2`, `V4 - V3` i `V5 - V4` zaraneye obyyavlenyi vtorichnyimi ocenkami vklada odnogo vozdejstviya. Dlya pyati formaljnyikh vtorichnyikh proverok primenyayetsya popravka Holm; oni ne zamenyayut pervichnyij kontrast i ne vyibirayut pobeditelya post hoc.
- **Trebovaniya k povtoru:** tot zhe manifest, iskhodnyiye snimki, evaluator, konfiguracii variantov, byudzhet, raspisaniye inyyekcij i sposob analiza; otlichiya zapisyivayutsya kak novaya versiya.
- **Trebovaniya k nezavisimomu vosproizvedeniyu:** inoj FUM-uzel ili issledovatelj poluchayet dopustimyij task-bundle i evaluator, samostoyateljno zapuskayet neizmenyonnyij protokol i sokhranyayet sobstvennuyu trassu; povtor tem zhe orkestratorom ne schitayetsya nezavisimyim.

### Metriki

| Metrika                     | Operacionnoye opredeleniye                                                                                                                       |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Vneshnij uspekh               | dolya progonov s `accepted` po skryitomu kontraktu                                                                                               |
| Lozhnoye zaversheniye           | agent obyyavil terminaljnoye vyipolneniye, no vneshnij kontrakt vernul ne `accepted`                                                                |
| Vosstanovleniye              | posle prinuditeljnogo zaversheniya novyij process doshyol do vneshnego uspekha; otdeljno — zaderzhka do pervogo novogo prinyatogo dejstviya              |
| Sokhrannostj podtverzhdyonnogo | dolya nezavisimo proverennyikh do sboya invariantov, kotoryiye ostayutsya projdennyimi v finaljnom snimke                                               |
| Vmeshateljstva cheloveka      | chislo i tip dejstvij cheloveka posle starta; soderzhateljnoye dejstviye lishayet progon statusa avtonomnogo                                          |
| Tokenyi                      | doverennyiye provider input/output/cache usage, summirovannyiye po vsem rolyam; otsutstviye usage delayet obyazateljnuyu metriku nedostupnoj            |
| Denjgi                      | fakticheskij usage po zakreplyonnomu do serii tarifnomu snimku i valyuta; besplatnyij lokaljnyij provider zapisyivayetsya kak `0`, a ne kak neizvestno |
| Vremya                       | monotonnoye wall-clock ot dopuska vkhoda do terminala, vklyuchaya vosstanovleniye i proveryayusjhego                                                     |
| Dublirovaniye                | povtor tochnogo normalizovannogo tool-vyizova bez novogo vkhoda plyus povtornoye primeneniye togo zhe patch-hunk; otdeljno sokhranyayetsya churn strok    |
| Konfliktyi                   | chislo nablyudayemyikh Git-, CAS-, memory- i decision-konfliktov, ikh razreshyonnostj i ostatok v terminaljnom sostoyanii                               |
| Regressii                   | chislo proverok, proshedshikh na iskhodnom snimke i ne proshedshikh na finaljnom; polnyij iskhodnyij nabor zapuskayetsya tem zhe vneshnim ocensjhikom           |

Obyazateljnyiye razrezyi — variant, sloj zadachi, task-level blok, povtor, nalichiye preryivaniya i iskhod vosstanovleniya. Tokenyi, denjgi, vremya, dublirovaniye, konfliktyi i regressii publikuyutsya kak raspredeleniya i intervalyi, a ne toljko sredniye. Chislo kommitov, dokumentov, kartochek i shagov ne ispoljzuyetsya kak kriterij preimusjhestva.

## Zapuski

Izmeryayemyikh i shakedown-zapuskov versii `1` net. Pervyij budusjhij progon poluchayet `run_id` toljko posle otdeljnogo razresheniya, zapechatyivaniya manifest i proverki vsekh shesti konfiguracij; otsutstviye zapuskov neljzya interpretirovatj kak otricateljnyij rezuljtat.

## Rezuljtat

- **Fakticheskiye nablyudeniya:** `нет`; sozdan toljko protokol.
- **Svodka povtorov:** `неприменимо`; povtoryi ne vyipolnyalisj.
- **Iskhod otnositeljno gipotezyi:** `не проверено`.
- **Interpretaciya:** prichinnaya lestnica, vneshnij kriterij, minimaljnaya vyiborka, politika povtorov, ostanovka, zasjhita skryityikh kriteriyev i obyazateljnyiye metriki predzaregistrirovanyi do izmerenij.
- **Neopredelyonnostj:** neizvestnyi bazovaya dolya uspekha, dispersiya, dostupnyij provider, fakticheskaya stoimostj i dostatochnostj `50` zadach dlya uzkikh vtorichnyikh effektov.
- **Otricateljnyij ili neodnoznachnyij rezuljtat:** `неприменимо`; izmerenij yesjhyo net.
- **Chto rezuljtat ne dokazyivayet:** preimusjhestvo FUM, gotovnostj harness, nalichiye razreshyonnogo nabora zadach, nezavisimoye vosproizvedeniye ili pravo na lyuboj vneshnij libo platnyij progon.

## Ogranicheniya

- **Oblastj primenimosti:** budusjhaya seriya po tochnyim zadacham, modeli, runtime i evaluator versii `1`.
- **Isklyucheniya:** lyubyiye inyiye modeli, byudzhetyi, domenyi, realjnyiye poljzovateljskiye dannyiye, dolgiye avtonomnyiye epizodyi i fizicheskiye dejstviya.
- **Nevosproizvodimaya chastj:** zakryityiye kriterii i zhivoj model-provider do vyidachi otdeljnogo dostupa; publichnaya kartochka sokhranyayet ikh kontrakt, no ne soderzhimoye.
- **Ugrozyi validnosti i izvestnyiye oshibki:** odinakovaya modelj delayet roli korrelirovannyimi; neobkhodimyiye obyortki mekhanizmov i rolej razlichayut prompt variantov; strukturnyiye nakladnyiye raskhodyi FUM raskhoduyut obsjhij byudzhet; parallelizm `V5` menyayet planirovaniye wall-clock; nositelj povrezhdyonnoj pamyati ne mozhet byitj polnostjyu odinakovyim u varianta bez pamyati; provider mozhet ostavatjsya nedeterminirovannyim; pragmaticheskij minimum `50` zadach ne poluchen otdeljnyim power-analizom.
- **Riski i ogranicheniya dostupa:** utechka skryityikh kriteriyev, licenzii task-bundle, sekretyi, stoimostj, setevoj dostup i izmeneniye vneshnikh repozitoriyev zakryivayut zapusk do otdeljnogo resheniya.
- **Usloviya peresmotra:** power-analiz po otdeljnomu neizmeryayemomu pilot-naboru, nevozmozhnostj poluchitj obyazateljnyiye provider-metriki, izmeneniye osnovnogo utverzhdeniya ili infrastrukturnaya nevozmozhnostj izolyacii trebuyut versii `2`, a ne pravki versii `1` posle starta.

## Status

- **Sostoyaniye vyipolneniya:** `заблокирован`; protokol zapolnen, no izmeryayemyij zapusk ne razreshyon i ne podgotovlen.
- **Iskhod proverki gipotezyi:** `не проверено`.
- **Issledovateljskij status utverzhdeniya:** `гипотеза FUM`.
- **Osnovaniye statusov:** eta predregistraciya i otsutstviye blokov zapuska.
- **Nezavisimoye vosproizvedeniye:** `не выполнялось`.

## Sleduyusjhij shag

- **Dejstviye:** `создать новую версию`.
- **Osnovaniye:** do zhivoj serii nuzhno otdeljno razreshitj istochnik zadach, provider, maksimaljnuyu obsjhuyu stoimostj, zakryitoye khraneniye, evaluator i publikacionnuyu politiku, zatem zapechatatj tochnyij manifest bez izmeneniya prichinnoj lestnicyi.
- **Predusloviya i razresheniya:** yavnyij poljzovateljskij zapros; proverennyiye licenzii; otsutstviye sekretov i personaljnyikh dannyikh; tochnyiye modelj i runtime; otdeljnyiye polnomochiya na setj i oplatu, yesli oni nuzhnyi; zapret izmeneniya chuzhikh repozitoriyev; nezavisimyij prosmotr zasjhityi ot utechki.
- **Svyazannyij material:** `ещё не создан`; tekusjhaya kartochka ne zapuskayet prodolzheniye avtomaticheski.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-02_23-09-10_MSK_predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM/zapros.md)
- [trebovaniye o sravniteljnoj eksperimentaljnoj priyomke preimusjhestv FUM](../Trebovaniya/🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)

## Opornyiye materialyi

- [shablon kartochki eksperimenta FUM](shablon-kartochki-eksperimenta-FUM.md)
- [FUM-STEP-0112 — zamknutyij odnoagentnyij epizod](kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [FUM-STEP-0083 — mezhsessionnoye vozobnovleniye raspredelyonnogo progona](kartochki-shagov/✅-FUM-STEP-0083-vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:417ce6a52c8ddec9c2413ea6daae8151d67aa7d708597f576baabc8196da737c -->
<!-- FUM-MD-RECENCY:END -->
