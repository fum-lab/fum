# Proveryayemaya aktualjnostj poljzovateljskikh marshrutov README

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0072 -->

FUMA dolzhna podderzhivatj proveryayemuyu aktualjnostj odnogo kornevogo README: svyazyivatj konechnyij yavno perechislennyij nabor poljzovateljskikh marshrutov s versiyami ikh osnovanij i vyichislyatj ogranichennyij signal potrebnosti obnovitj instrukciyu. Chelovek poluchayet korotkij pravdivyij marshrut ispoljzovaniya FUM i dokazateljstva togo, pochemu on trebuyet libo ne trebuyet peresmotra.

Tot zhe obsjhij ispolnitelj dolzhen vyichislyatj potrebnostj v integracii vetok po vtoromu deklarativnomu opredeleniyu s proveryayemyim proiskhozhdeniyem. Istoricheskiye zagolovok, putj i nomer trebovaniya sokhranyayutsya; pozdnyaya komanda rasshiryayet konkretnyij prikladnoj srez dvumya opredeleniyami i ne sozdayot obsjhij universaljnyij dvizhok vnimaniya.

## Semanticheskiye svyazi

- **dopolnyayet:** [nablyudayemoye sostoyaniye agentskogo runtime i interfejsa](🟡-nablyudayemoye-sostoyaniye-agentskogo-runtime-i-interfejsa.md) — prigodnostj instrukcii i sostoyaniye vyipolneniya samostoyateljnyi; vmeste oni pokazyivayut cheloveku, kak nachatj rabotu i chto fakticheski proiskhodit.

## Kriterii proverki

- Dva opredeleniya ispolnyayutsya odnim obsjhim AutomationExecutor novoj yavnoj versii; v1 i vesj pervonachaljnyij README-kontrakt sokhranenyi. Obyazateljnyiye iskhodyi vtorogo opredeleniya i yego nezavisimyiye testyi zakreplenyi nizhe.

- Kornevoj README soderzhit rovno odin vidimyij razdel `## Как использовать FUM сейчас`, pryamuyu ssyilku na `Документация/README.md`, ponyatnyij marshrut k `Приложения/FUMA/README.md` i ne boleye 12 000 Unicode-simvolov vmeste s recency. Nachalo rabotyi, obyichnyij zapros, rezuljtat, proverka, utochneniye, prodolzheniye i ostanovka opisanyi po fakticheskoj dostupnosti.
- Odin versionirovannyij konechnyij vkhod opredelyayet identichnostj README, poljzovateljskiye marshrutyi, znachimyiye zavisimosti, versii istochnikov i moment ocenki. Izmeneniye toljko postoronnego istochnika ne sozdayot signal dlya etogo marshruta; nedostupnostj znachimogo istochnika yavno sokhranyayetsya kak neizvestnostj.
- Vosproizvodimyij JSON razlichayet nablyudeniye, znachimostj, vnimaniye, vyibor dejstviya, proverku rezuljtata i izmeneniye sostoyaniya. On soderzhit prichinu, tochnyiye dokazateljstva s versiyami, neizvestnostj, sostoyaniye rassmotreniya i svideteljstvo podtverzhdyonnogo ustraneniya.
- Dokazannoye otsutstviye obyazateljnoj ssyilki uderzhivayet potrebnostj do proverki tekusjhej instrukcii otnositeljno tekusjhikh osnovanij. Izmeneniye hash istochnika oznachayet povod peresmotretj, no samo ne dokazyivayet smyislovogo ustarevaniya. «Uvidel» i «rassmotreno» ne snimayut sokhranyayusjheyesya raskhozhdeniye; prezhneye podtverzhdeniye ne perenositsya na novuyu versiyu. Ispravleniye libo obosnovannoye udaleniye marshruta podtverzhdayutsya otdeljno.
- Hash i recency ustanavlivayut fakt izmeneniya, no ne dokazyivayut smyislovuyu aktualjnostj. Susjhestvuyusjhiye strukturnyiye proverki README sokhranyayut svoyo naznacheniye. Ekran i MCP mogut otobrazhatj vyichislennyij signal, no ne opredelyayut identichnostj README.

## Ispolneniye na strukturiruyusjhikh operatorakh

Minimaljnyij realjnyij sluchaj — pryamaya ssyilka README na `Приложения/FUMA/README.md`. Znachimostj, uderzhaniye vnimaniya i vyibor sleduyusjhego dejstviya zadayot konechnoye opredeleniye grafa operatorov. Sistemnyij adapter postavlyayet nablyudeniya i ispolnyayet otdeljno razreshyonnoye dejstviye, no ne reshayet zaraneye, nuzhno li obnovleniye i ustranena li prichina.

[Obsjhij ispolnitelj 0208](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/konechnoye-ispolneniye.md) rasshiryayetsya rovno neobkhodimyimi strukturirovannyimi znacheniyami i obsjhimi sopostavleniyami; novaya versiya sokhranyayet v1. Usloviya, selektoryi, proveryayemyiye svyazi proiskhozhdeniya i iskhodyi prinadlezhat opredeleniyu, a ne specialjnomu kodu README. Nedostupnostj, narushennaya privyazka i ustarevshij srez dayut unknown s sokhraneniyem prezhnego sostoyaniya.

## Status i granicyi

Status trebovaniya — `🟡`.

Trebovaniye realizuyetsya v konechnom sreze E2; postavka poka ne prinyata. Zapisanyi [kontrakt, iskhodniki i komandyi](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/operatornoye-vnimaniye.md), fakticheskaya priyomka sokhranyayetsya v [otchyote](../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/otchyot.md). Podgotovka postanovki ne schitayetsya gotovnostjyu produkta. Obsjhaya osnova — [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md); yeyo ostaljnoj obyyom ostayotsya aktivnyim.

Pervoye opredeleniye ogranicheno odnim README i yavnyimi poljzovateljskimi marshrutami; vtoroye — potrebnostjyu integracii odnoj postavki v vyibrannoj oblasti marshruta. Subyyektivnoye perezhivaniye ne dokazano; universaljnyij dvizhok emocij, novoye raspisaniye, hooks, fonovyij zapusk, izmeneniye vneshnikh polnomochij i perepisyivaniye README na kazhdyij kommit ne vkhodyat v rezuljtat. Rassmotreniye ne oznachayet razresheniya dejstviya. Zhivyiye sensoryi, ustanovlennoye perenosimoye prilozheniye i podklyucheniye vsekh paketov ne zayavlyayutsya bez otdeljnogo dokazateljstva.

## Pozdneye rasshireniye: potrebnostj integracii

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

## Istochniki trebovanij

- [Realizaciya E2](../Zhurnal/2026-09-11_21-46-50_MSK_realizovatj-operatornoye-vnimaniye/zapros.md).

- [Utochneniye chuvstviteljnosti vesami i porogami](../Zhurnal/2026-09-11_20-28-44_MSK_utochnitj-chuvstviteljnostj-operatornogo-vnimaniya/zapros.md).

- [Pryamoye porucheniye realizacii potrebnosti integracii](../Zhurnal/2026-09-11_18-58-16_MSK_obnovitj-postanovku-operatornogo-vnimaniya/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_16-25-58_MSK_podgotovitj-postanovku-README/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 00:16:42 MSK -->
<!-- content-sha256: sha256:518d132be07adf20d3dec27bf7daa5a94c4033feb0e218aca5467f8c87d71ca5 -->
<!-- FUM-MD-RECENCY:END -->
