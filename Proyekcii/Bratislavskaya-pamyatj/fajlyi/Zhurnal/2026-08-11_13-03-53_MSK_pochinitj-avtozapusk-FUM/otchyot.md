# Otchyot 2026-08-11 13:03:53 MSK - Pochinitj avtozapusk FUM

Diagnostika lokalizovala nezapusk ne v raspisanii, statuse avtomatizacii, vetke ili vyibore kartochki, a v nezavershyonnoj nested host-granice. Heartbeat uspel sokhranitj obsjhuyu rezervaciyu, kartochochnyij claim i sostoyaniye `вызов_мог_состояться`, no vyizov sozdaniya zadachi byil opisan bez obyazateljnogo `await`. JavaScript-isolate mog zavershitjsya, otbrosiv nezavershyonnyij Promise: novaya zadacha ne poyavilasj v dostupnom host-snimke, a obe rezervacii praviljno ostalisj v ograzhdyonnoj neopredelyonnosti bez razresheniya na povtor ili osvobozhdeniye.

Kanonicheskij prompt ispravlen minimaljno: dochernij prompt teperj polnostjyu gotovitsya do dolgovechnoj granicyi, a odin `functions.exec` posledovateljno ozhidayet tochnuyu komandu granicyi i rovno odin nested-vyizov sozdaniya zadachi cherez ogranichennyij `Promise.race`, ne vozvrasjhaya upravleniye modeli mezhdu nimi. Odnovremenno zakryita fakticheski nablyudyonnaya skhema zapisej `list_threads` i usilena pobajtovaya proverka snimkov `Stop`/`Start` i migracii. Susjhestvuyusjhaya zhivaya avtomatizaciya obnovlena na meste odin raz i pri posleduyusjhem chtenii soderzhit tochnyij rezuljtat renderer, odnako polnaya zhivaya priyomka ne zavershena: tekusjhaya neopredelyonnaya rezervaciya po-prezhnemu ostanavlivayet tiki na nesovpadenii terminalizacii, a idle-marshrut posle peredachi yesjhyo dolzhen nablyudatjsya upravlyayusjhim khodom.

## Diagnostika po sloyam

### 1. Raspisaniye, status i istoriya tikov

Po sovokupnosti imeni, vida, naznacheniya, raspisaniya i statusa najdena rovno odna susjhestvuyusjhaya heartbeat-avtomatizaciya. Ona ostayotsya aktivnoj i zapuskayetsya kazhdyiye pyatj minut; drugaya heartbeat-zapisj s inyim naznacheniyem ostayotsya priostanovlennoj i v remont ne vklyuchalasj.

Problemnyij tik proshyol ranniye host-proverki, obsjhuyu rezervaciyu, kartochochnyij claim i dolgovechnuyu komandu `начать-вызов-среды`, no ne ostavil podtverzhdyonnoj sozdannoj zadachi. Posleduyusjhiye tiki do remonta bezopasno ne povtoryali vneshnij effekt. Posle obnovleniya prompt prochitanyi chetyire zavershyonnyikh tika: kazhdyij ostanovilsya na tochnom nesovpadenii terminalizacii prezhnej next-step-rezervacii i ne vyipolnyal host-effektov. Poetomu ni `queue_busy`, ni ispravlennaya cepochka sozdaniya, ni polnyij idle-marshrut v zhivoj istorii poka ne nablyudalisj.

### 2. FIFO, vetka i rabochaya kopiya

Do pervoj mutacii podtverzhdenyi imenovannaya vetka `master`, sootvetstvuyusjhaya zakryitomu planu vershina, pustoj indeks, otsutstviye konfliktov i chistaya rabochaya kopiya. Remontnaya zadacha pervyim instrumentaljnyim dejstviyem voshla v FIFO, dozhdalasj dopuska i proshla zakryityiye `bind-run` i `verify-run`. Vo vremya diagnostiki ona ostavalasj yedinstvennyim vladeljcem bez ozhidayusjhikh biletov; vetka i istoriya ne pereklyuchalisj.

### 3. Obsjhij reyestr i lokaljnyij vyibor

Obsjhij reyestr dispetchera korrekten i soderzhit dva aktivnyikh zadaniya. Specializirovannyij `validate` podtverdil rabochij nabor iz `18` kandidatov: `2` vyichislennyikh `ready`, `12` yavnyikh `paused` i `4` yavnyikh `blocked`. Svezhij `show` vyibral gotovuyu kartochku po prichine izmeneniya istochnika. Proizvodnyij reyestr planirovaniya peresobran posle izmeneniya kartochki i zatem proshyol otdeljnyij `validate`.

### 4. Obsjhaya rezervaciya, claim i ispolnitelj

Obsjhaya next-step-rezervaciya nakhoditsya v faze `вызов_мог_состояться`: u neyo net podtverzhdyonnogo iskhoda, host-svideteljstva, privyazki FIFO-ispolnitelya ili kvitancii vozobnovleniya. Kartochochnyij claim skhemyi `5` takzhe ne svyazan s ispolnitelem. Vetka, vershina vyibora, popyitka, lease, vyibor, shag i kartochka u obsjhego i specializirovannogo sloyov soglasovanyi pobajtovo.

Eto ne staryij claim posle otkata: on sovpadayet so svezhim `show` na tekusjhej vershine. Eto post-boundary-neopredelyonnostj, poetomu pre-host `release`, novyij lease, povtor claim i povtor sozdaniya zadachi zapresjhenyi. Upravlyayusjhij fence i analiticheskaya rezervaciya neaktivnyi.

### 5. Renderer i zhivoj prompt

Do remonta polnyij snapshot zhivogo prompt otlichalsya ot rezuljtata renderer. Posle yedinstvennogo obnovleniya na meste posleduyusjhij readback podtverdil pobajtovoye sovpadeniye prompt s tekusjhim renderer i sokhraneniye aktivnogo statusa, zakryitogo nabora polej, otsutstviya prezhnikh opcionaljnyikh polej i tipov `version`, `created_at`, `updated_at`.

Nemedlennaya popyitka mashinno podtverditj polnyij snimok posle obnovleniya zavershilasj ranjshe ustojchivogo readback, a vremennyij snimok «do» posle otkaza kontura ne sokhranilsya. Poetomu tochnyij old/new-diff vsekh znachenij neljzya chestno vosstanovitj: dokazanyi tekusjhij kanonicheskij prompt i tekusjhaya forma zapisi, no ne polnyij razreshyonnyij diff toljko `prompt` i `updated_at`. Povtornoye obnovleniye, udaleniye, sozdaniye zamenyi ili otkat ne vyipolnyalisj.

### 6. Host-metadata, transport i zakryitaya skhema

Fakticheskij `list_threads` vozvrasjhayet polnyij JSON-tekst, kotoryij razbirayetsya rovno odin raz do obyyekta skhemyi `4`. Verkhnij urovenj zakryit shestjyu polyami: `schemaVersion`, `untrustedDataNotice`, `pinnedThreads`, `threads`, `unavailableHosts`, `unavailableSources`; oba massiva nedostupnosti pustyi.

Zapisi oboikh massivov imeyut obsjhiye obyazateljnyiye polya `id`, `kind`, `projectId`, `status`, `title`, `summary`, `updatedAt`. Codex-zapisj dopolniteljno trebuyet strokovyiye `hostId` i `cwd`, ChatGPT-zapisj zapresjhayet ikh; zakreplyonnaya zapisj imeyet odnobazovyij celochislennyij `pinnedIndex`, nezakreplyonnaya zapresjhayet yego. Para `summaryOriginalChars` i `summaryTruncated` opcionaljna toljko sovmestno i sokhranyayet tipyi chisla i boolean. Identifikatoryi unikaljnyi vnutri massivov i mezhdu nimi, a sobstvennaya Codex-zadacha prinimayetsya v `idle` libo `notLoaded`. Neizvestnoye pole, wrapper, vlozhennaya JSON-stroka, Markdown, prefiks, suffiks, massiv, `null` i rekursivnyij razbor zakryivayut tik.

`read_thread` otdeljno podtverdil strokovyij transport skhemyi `1`, zakryityiye polya zadachi i khodov i zavershyonnyiye stadii poslednikh tikov. Nested host-vyizovyi vyipolnyayutsya vnutri `functions.exec`; kazhdyij sozdannyij Promise teperj obyazan byitj yavno ozhidayemyim.

## Ispravleniye

Dobavlena minimaljnaya obezlichennaya JSON-fikstura nablyudyonnogo `list_threads`: odna zakreplyonnaya Codex-zapisj, odna nezakreplyonnaya Codex-zapisj s soglasovannoj paroj summary-metadata i odna ChatGPT-zapisj. Ona sokhranyayet fakticheskiye tipyi, vlozhennostj, prisutstviye polej i skvoznuyu unikaljnostj, no ne soderzhit realjnyikh host-identifikatorov ili lokaljnyikh putej.

Razlichimyij test snachala padal na prezhnem kontrakte, ne soderzhavshem polnogo profilya zapisej i obyazateljnogo `await`. Posle pravki on trebuyet podgotovku dochernego prompt do host-granicyi, zatem `await tools.exec_command(...)` i rovno odin `await Promise.race([tools.codex_app__create_thread(...), таймаут])` v odnom uchastke bez `text(...)`, vozvrata ili perekhoda modeli. Kanonicheskij prompt, pravila i oba lokaljnyikh navyika opisyivayut odnu i tu zhe posledovateljnostj.

Proverka host-snimkov boljshe ne sravnivayet normalizovannyiye slovari obyichnyim Python-ravenstvom. `Stop`/`Start` i migraciya ispoljzuyut rekursivnoye raw-sravneniye s tochnyim sovpadeniyem tipov i prisutstviya: smena alias naznacheniya, `True` na `1`, vlozhennyij boolean na integer i inoj neozhidannyij diff otklonyayutsya. Dlya sluzhebnogo `updated_at` dopuskayetsya izmeneniye znacheniya, no ne prisutstviya ili predstavleniya tipa.

Nablyudyonnyij sboj sokhranyon kak vtoroye proyavleniye aktivnoj kartochki `FUM-СБОЙ-0008`; svyazannaya kartochka `FUM-STEP-0136` rasshirena s proverochnyikh dochernikh processov na obyyavlennyiye nested host-effektyi. Eto predotvrasjhayet povtor konkretnogo okna v heartbeat, no polnoye sistemnoye ustraneniye zabyityikh Promise po-prezhnemu trebuyet strukturirovannogo konverta effekta, predusmotrennogo etoj kartochkoj.

## Matrica nakoplennyikh regressij

| Klass                                      | Proverennyij rezuljtat                                                                                                                                             |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Poteryannyij otvet claim                     | Razreshyon toljko tochnyij povtor s tem zhe lease do pervogo host-effekta; novyij lease i povtor posle granicyi zakryityi.                                                  |
| Sobstvennyij `idle` / `notLoaded`           | Oba sostoyaniya dopustimyi dlya yedinstvennoj sobstvennoj Codex-zapisi i ne podmenyayut proverku identichnosti.                                                           |
| `pinnedThreads` i `threads`                | Massivyi obyyedinyayutsya bez isklyuchenij; povtoryi vnutri ili mezhdu nimi otklonyayutsya.                                                                                    |
| Mezhtikovaya izolyaciya                        | Lease i priznak vyizova ne perenosyatsya mezhdu soobsjheniyami heartbeat; neterminaljnaya rezervaciya pri etom ostayotsya dolgovechnyim fence.                                  |
| `Stop` / `Start`                           | Razreshyon toljko raw-diff statusa i odnotipnogo `updated_at`; alias, tipyi, prompt i ostaljnyiye polya sokhranyayutsya.                                                     |
| Obyyekt i stroka JSON                       | Obyyekt ispoljzuyetsya napryamuyu, polnyij JSON-tekst razbirayetsya odin raz; rekursivnyij razbor i obyortki zapresjhenyi.                                                      |
| Nested host-granica                        | Polnyij vkhod gotov do granicyi; granica i odin create yavno ozhidayutsya v odnom `functions.exec`. Neustranimoye bez host-idempotency crash-okno ostayotsya fail-closed.     |
| Versiya i tochnyiye polya                       | Skhema `4`, shestj verkhnikh polej i zakryityiye profili Codex, ChatGPT, pinned i summary-paryi zakreplenyi fiksturoj i testom.                                             |
| Proyekciya svobodnoj ocheredi                 | Lokaljnyij `heartbeat-status` i selector proverenyi; recent-massiv host ne vyidayotsya za dokazateljstvo globaljnogo prostoya.                                          |
| Staryij claim posle otkata                  | V tekusjhem sostoyanii ne nablyudayetsya; claim sovpadayet s tekusjhimi vershinoj i vyiborom, a stale-variantyi ostayutsya zakryityi testami.                                     |
| Obsjhij i kartochochnyij fence                  | Vetka, vershina, popyitka, lease, vyibor, shag i kartochka soglasovanyi; oba sloya poka ne svyazanyi s ispolnitelem i ne razreshayut vneshnij povtor.                           |

## Zhivaya priyomka i ogranicheniya

Pervyij urovenj prinyat: razlichimyiye TDD-red/green, polnyij adresnyij nabor sleduyusjhego shaga, testyi dispetchera, fence pochinki i reyestr planirovaniya prokhodyat. Vtoroj urovenj prinyat lokaljno: itogovyij polnyij smoke-check proshyol vse `77` etapov, vklyuchaya primenimyiye repozitornyiye proverki, polnyiye naboryi ocheredi i sleduyusjhego shaga, Python-testyi, SwiftPM-testyi, sborki i strogij lint.

Tretij urovenj prinyat lishj chastichno. Tekusjhij readback soderzhit kanonicheskij prompt, no nemedlennyij polnyij exact-diff obnovleniya ne byil sokhranyon. Chetyire posleduyusjhikh tika ne povtorili host-effekt, odnako ostanovilisj ranjshe ispravlennoj cepochki na terminalizacii prezhnej neodnoznachnoj rezervacii. Polnyij idle-marshrut posle ukhoda remontnoj i upravlyayusjhej zadach dolzhen proveritj posleduyusjhij upravlyayusjhij khod; tekusjhaya zadacha yego ne zhdyot i ne obyyavlyayet avtozapusk vosstanovlennyim.

Susjhestvuyusjhaya avtomatizaciya ne udalyalasj, ne zamenyalasj i ne perevodilasj iz `PAUSED` v `ACTIVE`. Remont ne dobavlyalsya v heartbeat ili obsjhij reyestr zadanij; novaya zadacha pochinki ne sozdavalasj. Tekusjhaya neodnoznachnaya rezervaciya i claim ne osvobozhdalisj, sobstvennaya remontnaya rezervaciya posle peredachi ne terminaliziruyetsya, push i publikaciya ne vyipolnyayutsya.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                                       |
| ------------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | Dopusk podtverzhdyon, no otdeljnyiye monotonnyiye metki nachala i konca ozhidaniya ne sokhranyalisj.                        |
| Soderzhateljnaya rabota    | ne izmereno  | Analiz, host-chteniye, pravka i dokumentirovaniye perekryivalisj; otdeljnyij nepreryivnyij tajmer ne zapuskalsya.        |
| Celevyiye proverki         | po zhurnalu   | Tochnyiye dliteljnosti pryamyikh zapuskov izmerenyi monotonnyimi chasami v upravlyayemom bloke nizhe.                        |
| Polnyij smoke-check       | 2 292,966 s  | Finaljnyij polnyij kontur proshyol `77` iz `77` etapov i ostalsya poslednim zaregistrirovannyim vyizovom sessii.        |
| Atomarnyij commit+handoff | ne izmereno  | Vyipolnyayetsya posle zakryitiya otchyota odnoj queue-komandoj i ne vkhodit v zakryityij snimok proverok.                   |

Granica profilya: interval nachinayetsya kanonicheskoj metkoj zaprosa. Pryamyiye proverki izmeryayutsya otdeljno, a finaljnaya peredacha FIFO proiskhodit posle zakryitiya zhurnaljnogo snimka.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:3df27cb5cb4bb5577ffc7d2ad37e62b6ee3fb4cc20b456ae41574d0817709ddb -->

| Vyizov                                                                                        | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Proverka obsjhego reyestra dispetchera                                          | 0,149 s      | uspeshno   |
| [kornevoj agent] Pokaz tekusjhego sleduyusjhego shaga                                              | 1,295 s      | uspeshno   |
| [kornevoj agent] Strukturnaya proverka sleduyusjhego shaga                                        | 0,995 s      | uspeshno   |
| [kornevoj agent] Sostoyaniye obsjhej rezervacii sleduyusjhego shaga                                  | 0,256 s      | uspeshno   |
| [kornevoj agent] Sostoyaniye ograzhdeniya upravleniya                                             | 0,195 s      | uspeshno   |
| [kornevoj agent] Sostoyaniye kartochochnoj pretenzii                                             | 0,264 s      | uspeshno   |
| [kornevoj agent] Sostoyaniye obsjhej analiticheskoj rezervacii                                    | 0,201 s      | uspeshno   |
| [kornevoj agent] Pobajtovoye sravneniye renderer i zhivogo prompt                               | 0,138 s      | uspeshno   |
| [kornevoj agent] Smyislovoj diff zhivogo prompt                                                | 0,131 s      | uspeshno   |
| [kornevoj agent] Trassa problemnogo heartbeat-tika                                           | 1,358 s      | uspeshno   |
| [kornevoj ispolnitelj] Razlichimyij TDD-red fakticheskoj host-skhemyi i ozhidayemogo sozdaniya       | 0,079 s      | neuspeshno |
| [kornevoj ispolnitelj] TDD-red strogogo readback posle Stop Start i migracii                 | 0,12 s       | neuspeshno |
| [kornevoj ispolnitelj] TDD-green host-skhemyi ozhidayemogo sozdaniya i strogogo readback          | 0,131 s      | uspeshno   |
| [kornevoj ispolnitelj] Polnyij adresnyij nabor renderer host-skhemyi i snapshot                  | 0,535 s      | neuspeshno |
| [kornevoj ispolnitelj] Povtor polnogo adresnogo nabora renderer host-skhemyi i snapshot        | 0,56 s       | uspeshno   |
| [kornevoj ispolnitelj] Polnyij adresnyij nabor adaptera sleduyusjhego shaga                        | 142,059 s    | neuspeshno |
| [kornevoj agent] Adresnyiye testyi zakryitoj skhemyi i ozhidayemogo host-vyizova                      | 0,565 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor sleduyusjhego shaga vetki posle ispravleniya ozhidanij               | 179,11 s     | uspeshno   |
| [subagent proverki dispetchera] Polnyij nabor obsjhego dispetchera posle ispravleniya host-granicyi | 483,498 s    | uspeshno   |
| [subagent proverki pochinki] Polnyij nabor ograzhdeniya pochinki avtozapuska                      | 43,742 s     | uspeshno   |
| [subagent proverki reyestra] Polnyij unittest-nabor reyestra planirovaniya                       | 3,843 s      | uspeshno   |
| [subagent proverki reyestra] Proverka aktualjnosti reyestra planirovaniya                       | 0,421 s      | uspeshno   |
| [kornevoj agent] Strukturnaya proverka rabochego nabora sleduyusjhego shaga                        | 0,976 s      | uspeshno   |
| [kornevoj agent] Dinamicheskij pokaz vyibrannogo sleduyusjhego shaga                               | 1,187 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown pered svyaznostjyu                               | 0,772 s      | uspeshno   |
| [kornevoj agent] Peresborka teplovoj kartyi grafa Obsidian                                    | 0,43 s       | uspeshno   |
| [kornevoj agent] Povtor svezhesti posle perechnya zatronutyikh fajlov                             | 0,724 s      | uspeshno   |
| [kornevoj agent] Pobajtovaya proverka publichnogo zaprosa v soobsjhenii kommita                  | 0,048 s      | uspeshno   |
| [kornevoj agent] Svyaznostj rabochej sessii pered polnyim smoke-check                           | 28,865 s     | neuspeshno |
| [kornevoj agent] Obnovleniye svezhesti posle ispravleniya profilya vremeni                       | 0,667 s      | uspeshno   |
| [kornevoj agent] Povtor svyaznosti posle ispravleniya profilya vremeni                          | 28,835 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check pochinki avtozapuska                             | 1,007 s      | neuspeshno |
| [kornevoj agent] Povtor polnogo smoke-check vne vlozhennoj pesochnicyi                          | 40,381 s     | neuspeshno |
| [kornevoj agent] Adresnyiye testyi posle pozicionno nejtraljnoj pravki                          | 0,5 s        | uspeshno   |
| [kornevoj agent] Proverka ostatka obyyavlenij posle pozicionno nejtraljnoj pravki             | 4,411 s      | uspeshno   |
| [kornevoj agent] Povtor polnogo nabora sleduyusjhego shaga posle pozicionnoj pravki              | 141,312 s    | uspeshno   |
| [kornevoj agent] Svezhestj posle pozicionno nejtraljnoj pravki                                | 0,615 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle pozicionno nejtraljnoj pravki                               | 26,449 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle pozicionnoj stabilizacii                  | 2292,966 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3429,79 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Zakryityiye repair-fence `bind-run` i `verify-run` proshli do pervoj mutacii.
- TDD-red vosproizvyol nepolnyij profilj fakticheskoj skhemyi, otsutstviye obyazateljnogo ozhidaniya nested-vyizova i dopusk alias/type-drejfa v snimkakh; te zhe proverki stali zelyonyimi posle minimaljnoj pravki.
- Polnyij nabor sleduyusjhego shaga proshyol `185` testov; renderer i snapshot-nabor otdeljno proshyol `34` testa. Polnyij nabor fence pochinki proshyol `13` testov, a reyestr planirovaniya — `53` testa i otdeljnyij `validate`.
- Specializirovannyiye `validate` i `show` uspeshno podtverdili tekusjhij rabochij nabor i gotovyij vyibor.
- Polnyij nabor dispetchera proshyol `140` testov. Itogovyij smoke-check ostalsya poslednej zaregistrirovannoj strokoj upravlyayemogo zhurnala i uspeshno proshyol `77` iz `77` etapov za `2 292,966` sekundyi.
- Pervyij smoke-check ostanovilsya na zaprete vlozhennoj sistemnoj pesochnicyi SwiftPM; tochnyij povtor vne neyo proshyol manifest-podgotovku i ranniye validatoryi, no vyiyavil pozicionnyij drejf vremennogo snimka latinskikh obyyavlenij. Novyiye testyi perenesenyi posle prezhnikh deklaracij, a raw-sravneniye vstroyeno s sokhraneniyem prezhnikh strok obyyavlenij; snimok snova sovpal bez obnovleniya ili rasshireniya. Posle etogo adresnyiye `7` testov i povtornyiye `185` testov sleduyusjhego shaga proshli.
- Posleduyusjhij zhivoj readback podtverdil kanonicheskij prompt i chetyire bezopasno zakryityikh tika bez host-effekta, no ne polnyij idle-marshrut.

## Resheniya i ogranicheniya

- Ispravleniye usilivayet predotvrasjheniye novogo propuska nested-vyizova, ne oslablyaya fail-closed-povedeniye uzhe voznikshej post-boundary-neopredelyonnosti.
- Vremennyij snimok neperevedyonnyikh obyyavlenij ne obnovlyalsya radi mekhanicheskogo sdviga strok: pravka sdelana pozicionno nejtraljnoj, a otdeljnaya proverka podtverdila iskhodnyij otpechatok ostatka.
- Neudachnaya nemedlennaya verifikaciya zhivogo obnovleniya ne byila osnovaniyem dlya vtorogo update: tekusjhaya zapisj prochitana zanovo i kanonichna, no otsutstvuyusjheye exact old/new-svideteljstvo chestno ostavleno nepolnoj chastjyu priyomki.
- Otsutstviye novoj zadachi v ogranichennom recent-snimke ne dokazyivayet, chto prezhnij host-vyizov ne sostoyalsya, poetomu tekusjhiye rezervaciya i claim sokhranyayutsya.
- `queue_busy` vo vremya remontnogo vladeniya dokazal byi toljko rannij gate. V fakticheski prochitannoj post-update-istorii tik do nego ne doshyol; etot urovenj ostayotsya ozhidayusjhim upravlyayusjhego nablyudeniya.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [FUM-SBOJ-0008 — Pustoj scenarij orkestracii bez dochernego vyizova](../../Sboi/FUM-SBOJ-0008-pustoj-scenarij-orkestracii-proverki-bez-dochernego-vyizova.md)
- [FUM-STEP-0136 — Ograditj obyyavlennyij dochernij effekt](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0136-ograditj-proverochnyij-khod-ot-pustogo-scenariya-orkestracii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-11 15:01:28 MSK -->
<!-- content-sha256: sha256:939e0e64347dc1133751cb92df8457bd51e2b88a6375af35c9e7d9120fab06da -->
<!-- FUM-MD-RECENCY:END -->
