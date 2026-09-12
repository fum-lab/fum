+++
schema_version = 1
card_id = "FUM-STEP-0218"
status = "active"
+++
# Obnovitj README i realizovatj yego srez aktualjnosti

## Zadacha

Obnovitj kornevoj README i realizovatj pervyij ispolnyayemyij srez [proveryayemoj aktualjnosti yego poljzovateljskikh marshrutov](../../Trebovaniya/🟡-proveryayemaya-aktualjnostj-marshrutov-README.md) na osnove susjhestvuyusjhego [FUM-STEP-0165](🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md). Itog — korotkaya tekusjhaya instrukciya i vosproizvodimyij vyichislyayemyij JSON-signal potrebnosti yeyo obnovleniya. Eto porucheniye otdeljnoj realizacii, a ne toljko posleduyusjhego planirovaniya.

Pozdneye porucheniye dobavlyayet vtoroye opredeleniye togo zhe mekhanizma — potrebnostj integracii vetok. Ono ispolnyayetsya tem zhe obsjhim AutomationExecutor i ne zamenyayet iskhodnyij README-scenarij.

## Pochemu sejchas

Chelovek pryamo poruchil obnovitj README, sozdatj osjhusjheniye neobkhodimosti yego obnovleniya i realizovatj s proverkoj funkcionaljnuyu chastj mekhanizma. V zakreplyonnoj baze postanovki `6ba824c69f09abb46cb5f356ce60e458cf99ecdd` README ne vyol k sokhranyonnyim iskhodnikam FUMA. Obsjhaya modelj vnimaniya, DETEKTOR-02 i scenarii zavisimogo ustarevaniya uzhe splanirovanyi; otsutstvuyet ispolnyayemaya svyazj imenno s aktualjnostjyu etoj instrukcii.

## Kriterii zaversheniya

- Sokhranyon polnyij pervonachaljnyij README-kontrakt i realizovano vtoroye opredeleniye potrebnosti integracii po konechnomu kontraktu nizhe; prodemonstrirovanyi razdeljnyiye ancestry/priyomka, pryamoj A/B na odnikh faktakh i vse otricateljnyiye granicyi. Iskhodnyiye v1 i regressii prokhodyat bez podmenyi semantiki.

- Vyipolnen konechnyij operatornyij kontrakt nizhe: odin obsjhij binarnik, odin nablyudayemyij vkhod i dva opredeleniya s raznoj celjyu dayut dokazanno raznyiye rezuljtatyi i trassyi; generic-kod ne soderzhit specialjnogo operatora README, prezhnij v1 sokhranyon.

- Kornevoj README obyyasnyayet nachalo rabotyi, obyichnyij zapros, nablyudayemyij rezuljtat, proverku, utochneniye, prodolzheniye i ostanovku. Sokhranenyi rovno odin `## Как использовать FUM сейчас`, pryamaya `Документация/README.md`, ponyatnaya pryamaya ssyilka k `Приложения/FUMA/README.md` i predel 12 000 Unicode-simvolov s recency.
- README pravdivo razlichayet proverennyiye sborki, chetyire samostoyateljnyikh paketa, yesjhyo ne podklyuchyonnyikh k prilozheniyu, ustanovsjhiki s kodom 2 i nedokazannyiye ustanovlennyij perenosimyij `.app` i zhivyiye sensoryi. Svezhiye dokazateljstva mogut utochnitj eti granicyi; ozhidaniye ne vyidayotsya za rezuljtat. Povtornyij perenos vsekh vosjmi paketov ne vkhodit v rabotu.
- V monorepozitorii sokhranenyi iskhodniki ogranichennogo sborsjhika/detektora, versionirovannaya skhema, konechnyiye vkhodyi, otkryityiye fiksturyi, CLI i instrukcii vosproizvedeniya iz chistogo klona s obyyavlennyimi zavisimostyami. Rezuljtat poluchayetsya bez skryitogo API i bez chteniya chastnyikh dannyikh po umolchaniyu.
- Vkhod yavno zadayot odnu zadachu, odin kornevoj README s versiyej, konechnyij nabor nablyudayemyikh marshrutov, zavisimosti i versii osnovanij, vremya ocenki i versiyu detektora. Vyikhod fiksiruyet skhemu, prichinu, dokazateljstva, neizvestnostj, sostoyaniye rassmotreniya i podtverzhdeniye ustraneniya. Dopustimyiye sostoyaniya, perekhodyi i kriterii sbrosa konechnyi i dokumentirovanyi do proverki.
- Funkcionaljnyij cikl proveryayetsya celikom: nablyudeniye → znachimostj → vnimaniye → vyibor dejstviya → proverka rezuljtata → izmeneniye sostoyaniya. Potrebnostj sokhranyayetsya do podtverzhdyonnogo ustraneniya raskhozhdeniya otnositeljno tekusjhikh osnovanij README. Prosmotr i rassmotreniye ne snimayut yeyo i ne dayut novyikh polnomochij; nedostupnyij istochnik ne prevrasjhayetsya v sostoyaniye «vsyo aktualjno».
- Pereispoljzuyutsya [DETEKTOR-02](../rabochij-kontekst-zadachi/detektoryi.json), [KONTEKST-02–04](../rabochij-kontekst-zadachi/scenarii-priyomki.json) i [modelj vnimaniya](../rabochij-kontekst-zadachi/modelj-vnimaniya.md). Adapteryi 0177/0160 podklyuchayutsya lishj pri neobkhodimosti i po dejstviteljnyim kontraktam; otsutstvuyusjhij adapter ne vyidumyivayetsya. Ekrannyij attention/MCP dopustim kak predstavleniye gotovogo signala, no ne trebuyetsya dlya minimaljnogo CLI-sreza.
- TDD snachala fiksiruyet nezavisimyiye ozhidayemyiye rezuljtatyi: izmenivshijsya znachimyij marshrut uderzhivayet signal posle prosmotra i rassmotreniya; podtverzhdyonnoye ispravleniye na tekusjhikh versiyakh snimayet yego; izmeneniye postoronnego istochnika ne sozdayot trevogu; nedostupnostj sokhranyayetsya; staroye podtverzhdeniye posle novoj versii nedejstviteljno; povtor i vosstanovleniye na tekh zhe vkhodakh vosproizvodimyi. Sokhranyayutsya realjnyiye RED/GREEN i izmeryayemyij profilj na otkryityikh sopostavimyikh vkhodakh.
- Susjhestvuyusjhiye check-readme-index i recency ispoljzuyutsya po ikh fakticheskomu naznacheniyu. Recency/hash sami ne ocenivayut smyisl; README ne perepisyivayetsya na kazhdyij kommit. Itog obyyasnyayet stoimostj chteniya i vyichisleniya, granicyi neizvestnosti i ostatok 0165. Proizvoljnyij procent effektivnosti ne naznachayetsya.

## Konechnyij kontrakt operatornogo sreza

Pervyij minimaljnyij proveryayemyij sluchaj — pryamaya ssyilka kornevogo README na prinyatyij Prilozheniya/FUMA/README.md. Adapter izvlekayet realjnyiye ssyilki s privyazkoj k bajtam README, OID/khyeshi vyibrannyikh istochnikov, dostupnostj, prezhneye sostoyaniye i obratnuyu svyazj; on ne vyichislyayet zaraneye nuzhnoObnovitj, znachimostj ili ustraneno. Znachimostj, uderzhaniye vnimaniya i vyibor sleduyusjhego dejstviya stroyatsya na opredelenii grafa strukturiruyusjhikh operatorov. Obsjhij ispolnitelj 0208 poluchayet rovno neobkhodimyiye ogranichennyiye strukturirovannyiye vkhod/vyikhod i obsjhiye operacii sopostavleniya polej/vkhozhdeniya v konechnyij spisok. Selektoryi, usloviya, neobkhodimyiye svyazi proiskhozhdeniya i iskhodyi zadayot opredeleniye. Dopustim konechnyij graf vkhod → sopostavleniye → rezuljtat bez ciklov i obsjhego planirovsjhika. V obsjhem kode net specialjnogo operatora README.

Dokazannoye otsutstviye obyazateljnoj ssyilki dayot raskhozhdeniye. Izmeneniye hash istochnika dayot povod peresmotretj, no ne dokazyivayet smyislovoye ustarevaniye. Nedostupnostj, narushennaya privyazka ili ustarevshij srez dayut unknown; prezhneye sostoyaniye pri unknown ne ischezayet. Rassmotreno ne oznachayet ustraneno; snyatiye potrebnosti trebuyet proverennogo novogo svideteljstva otnositeljno tekusjhikh osnovanij.

Obyazateljnyij nezavisimyij test pryamo vyizyivayet AutomationExecutor.vyipolnitj s odnim vkhodom i tem zhe binarnikom: opredeleniye A trebuyet otsutstvuyusjhuyu ssyilku, B otlichayetsya toljko celjyu i trebuyet prisutstvuyusjhuyu. Razlichayutsya rezuljtat, khyesh opredeleniya i trassa. Povrezhdeniye proiskhozhdeniya dayot unknown oboim opredeleniyam. considered pri sokhranyayusjhemsya raskhozhdenii ne dayot resolved. Rasshireniye imeyet yavnuyu novuyu versiyu; prezhniye opredeleniya, nablyudeniya, povedeniye v1 i regressii sokhranyayutsya. Polnyij yazyik grafov, Metal i avtonomnaya fabrika ne vkhodyat v etot srez.

Tochnyiye oporyi: [kontrakt 0208](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/konechnoye-ispolneniye.md), [obsjhij ispolnitelj](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Sources/FUMStructuringOperatorMemory/IspolneniyeOperatorov.swift) i [iskhodnyiye testyi](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Tests/FUMStructuringOperatorMemoryTests/ProverkiChistogoIspolneniya.swift).

## Granica realizacii i peredachi

Dostatochen konechnyij CLI-srez s dvumya deklarativnyimi opredeleniyami, realjnyim README, iskhodnikami, fiksturami, proverkami i profilem. Polnaya realizaciya 0165, universaljnyij dvizhok emocij i dokazateljstvo subyyektivnogo perezhivaniya ne zayavlyayutsya. Novyij postoyannyij zapusk i vneshniye dejstviya trebuyut samostoyateljnogo osnovaniya.

Podgotovka E0/E1 sokhranyala postanovku bez native-zapuska. Realizaciya E2 nachata v otdeljnoj native-zadache posle rannego podtverzhdeniya tochnogo kommita postanovki; yeyo tyazhyolyiye okna soglasuyutsya s koordinatorom.

## Sostoyaniye realizacii E2

Obnovlenyi README i tekusjhij poryadok rabotyi; zapisanyi obsjhij graf v2, dva opredeleniya, sborsjhiki, CLI i otkryityiye fiksturyi. Python RED/GREEN podtverzhdenyi; posle pervogo Swift RED novyij API proshyol adresnyij GREEN: 10 testov, vklyuchaya 33 scenariya, oba A/B opredeleniya i oba A/B chuvstviteljnosti. Zatem proshli 52 testa polnoj regressii paketa, strogij lint, Release-sborka i skvoznoj profilj s realjnyim ciklom README i tremya arkhivnyimi Git-primerami. Po izmereniyam prinyato resheniye sokhranitj realizaciyu bez dopolniteljnogo kyeshirovaniya. Ostayutsya finaljnaya dokumentacionnaya priyomka, kommit, dostavka vetki i zapisj yeyo tochnogo OID. [Kontrakt i komandyi](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/operatornoye-vnimaniye.md); [otchyot E2](../../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/otchyot.md). Prikladnoj rezuljtat ne zakryivayet vesj STEP0165 i REQ0044.

## Vtoroye opredeleniye: potrebnostj integracii

Odin obsjhij AutomationExecutor s yavnoj novoj versiyej ogranichennogo rasshireniya ispolnyayet dva deklarativnyikh opredeleniya: aktualjnostj README i potrebnostj v integracii vetok. Prezhnij v1, iskhodnyiye opredeleniya, nablyudeniya i regressii sokhranyayutsya. README-kontrakt, realjnyiye ssyilki s bajtovoj privyazkoj i pryamoj A/B-test pervogo opredeleniya sokhranyayutsya polnostjyu. Selektoryi, usloviya, neobkhodimyiye svyazi proiskhozhdeniya i iskhodyi zadayot opredeleniye; adapteryi toljko izvlekayut faktyi. Obsjhij ispolnitelj ne poluchayet specialjnyikh operatorov README ili «nuzhno integrirovatj».

Vkhod vtorogo opredeleniya soderzhit identichnostj repozitoriya; tochnyiye iskhodnyiye commit/tree; vyibrannuyu stadiyu marshruta cherez vedusjhuyu vetku fuma k master i yeyo osnovaniye; tochnyij nablyudyonnyij target OID; ancestry i polnotu istorii; svideteljstvo priyomki s report/schema/commit i istochnikom proveryayusjhego; prezhnij signal, fakt rassmotreniya, kvitanciyu integracii libo podtverzhdyonnuyu otmenu. Nablyudyonnyij target HEAD yavlyayetsya versiyej svideteljstva, a ne novoj identichnostjyu signala pri kazhdom kommite. Identichnostj oblasti svyazyivayet repozitorij, iskhodnuyu postavku i vyibrannuyu stadiyu marshruta. Stadiya master prinimayet rezuljtat stadii fuma, a ne perepryigivayet s iskhodnoj bokovoj vetki.

Konechnyiye iskhodyi vtorogo opredeleniya:

- Proverennaya postavka yesjhyo ne vklyuchena v vyibrannuyu celj — potrebnostj integrirovatj v etoj oblasti.
- Imeyetsya toljko checkpoint libo predmetnaya postanovka — razobratj nedostayusjhij dopusk, bez utverzhdeniya gotovnosti integracii.
- Iskhodnyij commit uzhe ancestor celi, no podkhodyasjhej kvitancii net — razobratj podtverzhdeniye vklyucheniya; povtornoye sliyaniye togo zhe ancestor ne predlagayetsya.
- Vkhod otsutstvuyet, imeyet nepodderzhannuyu skhemu, protivorechiye, narushennuyu svyazj OID libo nepolnuyu istoriyu — unknown. Prezhnyaya aktivnaya prichina ne stirayetsya.
- Commit vklyuchyon i kvitanciya integracii sovpadayet s iskhodnoj postavkoj, yeyo priyomkoj i vyibrannoj oblastjyu — potrebnostj snimayetsya toljko v etoj oblasti.
- Podtverzhdyonnaya otmena delayet potrebnostj neprimenimoj. Otmetka considered sama po sebe ne oznachayet resolved.

Ancestry ne dokazyivayet sokhrannostj rezuljtata posle revert. Utrata rezuljtata trebuyet otdeljnogo razbora, a ne predlozheniya povtorno slitj uzhe vklyuchyonnyij ancestor. Status priyomki ne beryotsya iz proizvoljnoj stroki ready: svyazyivayutsya tochnyiye versii skhemyi, neizmenyayemyiye iskhodnyiye fajlyi i khyeshi, rezuljtat proveryayusjhego i yego oblastj. Pervyij srez yavno podderzhivayet nablyudyonnyij format zakryitogo v3/report-v2; nepodderzhannyij v4 ne prinimayetsya po analogii.

Nezavisimyiye fiksturyi vklyuchayut chuzhuyu kvitanciyu i chuzhoj OID, nepolnuyu istoriyu, nepodderzhannyij v4, ancestor bez kvitancii, podtverzhdyonnoye vklyucheniye, considered pri sokhranyonnoj prichine, otmenu, revert i zapret pereskoka srazu v master. Pryamoj A/B-test vyizyivayet tot zhe AutomationExecutor.vyipolnitj na odnom vkhode i tom zhe binarnike: dva opredeleniya otlichayutsya toljko vyibrannoj celjyu i dayut raznyiye result/hash/trace. Pri povrezhdenii proiskhozhdeniya oba dayut unknown s sokhraneniyem prezhnego aktivnogo sostoyaniya.

Demonstraciya chitayet fiksirovannyiye realjnyiye Git-obyyektyi i ikh susjhestvuyusjhiye svideteljstva; priyomka i ancestry pokazyivayutsya otdeljno. Ni detektor, ni yego primer ne vyipolnyayut merge, push, zapusk zadach, vyidachu novyikh polnomochij ili zapisj obrabotki 0177. Vyibor dejstviya yavlyayetsya vyichislennyim predlozheniyem, a yego ispolneniye trebuyet samostoyateljnogo razresheniya. Polnyij yazyik grafov, Metal, avtonomnaya fabrika, razbor shriftov, sborka Swift/LLVM/Clang i zerkalirovaniye zavisimostej ne vkhodyat v etot konechnyij srez.

## Nastraivayemaya chuvstviteljnostj dvukh opredelenij

Odin obsjhij ispolnitelj i dva deklarativnyikh opredeleniya sokhranyayutsya. Chuvstviteljnostj ocenki zadayotsya nastraivayemyimi vesami vkhodnyikh signalov i porogami srabatyivaniya. Parametryi imeyut yavnuyu versiyu, proveryayemyij khyesh i konechnuyu podderzhannuyu oblastj znachenij; oni peredayutsya kak dannyiye opredeleniya, a ne pryachutsya v adaptere. Rezuljtat i trassa razlichayut versii i khyeshi opredeleniya, parametrov i fakticheskikh istochnikov. Dlya kazhdogo vkhodnogo signala obyyasnyayutsya nablyudyonnoye znacheniye, primenyonnyij ves, vklad v ocenku i svyazj s porogom; obyazateljnoye usloviye otdeljno vidno kak obyazateljnoye, a ne kak proizvoljnyij chislennyij vklad.

Vesa reguliruyut chuvstviteljnostj i prioritet rassmotreniya, sokhranyaya dokazannostj faktov. Otsutstvuyusjhaya obyazateljnaya ssyilka README ostayotsya raskhozhdeniyem, dazhe yesli yeyo ves snizhen. Nulevoj ves ne maskiruyet nedostupnostj, narushennoye proiskhozhdeniye, ustarevshij srez, otsutstviye obyazateljnoj priyomki libo inoj obyazateljnyij neizvestnyij fakt i ne prevrasjhayet unknown v uspeshnyij, razreshyonnyij ili ustranyonnyij iskhod. Rassmotreniye i unknown ne stirayut prezhnyuyu podtverzhdyonnuyu aktivnuyu prichinu. Smena parametrov sama po sebe ne yavlyayetsya svideteljstvom ustraneniya; snyatiye po-prezhnemu trebuyet proverennogo tekusjhego osnovaniya sootvetstvuyusjhego opredeleniya libo predusmotrennoj podtverzhdyonnoj otmenyi.

Priyomka chuvstviteljnosti vklyuchayet pryamyiye vyizovyi togo zhe AutomationExecutor.vyipolnitj na odinakovyikh faktakh, odnom binarnike i neizmennom opredelenii s naborami parametrov A i B: razlichayutsya chuvstviteljnostj, khyesh parametrov i obyyasnimaya trassa. Dlya kazhdogo iz dvukh opredelenij sokhranyayetsya khotya byi odin takoj vosproizvodimyij sluchaj. Proveryayutsya nulevoj ves obyazateljnogo neizvestnogo fakta, considered pri sokhranyayusjhemsya raskhozhdenii i smena poroga pri prezhnej aktivnoj prichine: oni ne dayut resolved. Nedopustimyiye, otsutstvuyusjhiye libo nepodderzhannyiye obyazateljnyiye parametryi dayut yavnyij neuspeshnyij iskhod po obyyavlennomu kontraktu, bez molchalivogo uspeshnogo znacheniya po umolchaniyu.

Eto dopolneniye vkhodit v prezhnij konechnyij srez realizacii s TDD, otdeljnyimi RED/GREEN, profilem i otkryityimi fiksturami. Ono ne vvodit tretjye opredeleniye, otdeljnyij dvizhok emocij, subyyektivnoye perezhivaniye libo novyiye vneshniye polnomochiya. Prezhnij v1, oba A/B-testa smenyi opredeleniya, realjnyiye marshrutyi README, stadii integracii i vse iskhodnyiye otricateljnyiye scenarii sokhranyayutsya.

## Istochniki

- [Komanda i khod realizacii E2](../../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/zapros.md).

- [Utochneniye chuvstviteljnosti vesami i porogami](../../Zhurnal/2026-09-11_20-28-44_MSK_utochnitj-chuvstviteljnostj-operatornogo-vnimaniya/zapros.md).

- [Pryamoye porucheniye realizacii potrebnosti integracii](../../Zhurnal/2026-09-11_18-58-16_MSK_obnovitj-postanovku-operatornogo-vnimaniya/zapros.md).

- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_16-25-58_MSK_podgotovitj-postanovku-README/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 00:16:42 MSK -->
<!-- content-sha256: sha256:3e8fc3070805f1b6fdb8f7167dbc384aefa33055e224b3a2506b468ae407f33b -->
<!-- FUM-MD-RECENCY:END -->
