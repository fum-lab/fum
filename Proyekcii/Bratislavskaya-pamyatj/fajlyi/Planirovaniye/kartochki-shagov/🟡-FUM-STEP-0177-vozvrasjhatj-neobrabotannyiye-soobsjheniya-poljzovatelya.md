+++
schema_version = 1
card_id = "FUM-STEP-0177"
status = "active"
+++
# Vozvrasjhatj neobrabotannyiye soobsjheniya poljzovatelya

## Zadacha

Realizovatj v FUM obyazateljnuyu dlya rabochej sessii avtomatizaciyu, kotoraya sopostavlyayet iskhodnyiye poljzovateljskiye soobsjheniya tekusjhego JSONL s dolgovechnoj istoriyej obrabotki i vozvrasjhayet polnyij neobrabotannyij ostatok. Eto sleduyusjhij etap posle tekusjhej podgotovki dopuska sliyaniya, pered perenosom sobstvennoj realizacii FUM-STEP-0176.

## Pochemu sejchas

Korenj povtorno zavershil otvet o statuse pri nezavershyonnoj zadache. Chernoviki sokhranilisj, no ikh nalichiye samo po sebe ne garantiruyet uchyota kazhdogo upravlyayusjhego soobsjheniya. Poljzovatelj predlozhil zamenitj ruchnoye vosstanovleniye iskhodnogo konteksta obyazateljnyim mashinnyim vkhodom, kotoryij obnaruzhivayet i novyiye soobsjheniya, i prezhniye propuski. Nalichiye JSONL, arkhiva ili spiska zadach yesjhyo ne oznachayet nalichiye takoj avtomatizacii.

## Kriterii zaversheniya

- Ispoljzovan susjhestvuyusjhij razbor JSONL i zhurnalirovaniya tam, gde yego kontrakt podkhodit. Iskhodniki, testyi, otkryityiye fiksturyi, scenarij izmerenij i instrukciya razmesjhenyi v monorepozitorii FUM; privatnyiye dialogi i absolyutnyiye lokaljnyiye puti v publichnyiye fiksturyi ne popadayut.
- Vkhod yavno privyazan k tekusjhej zadache i iskhodnomu fajlu. Soobsjheniye imeyet ustojchivuyu proveryayemuyu identichnostj s proiskhozhdeniyem; dva odinakovyikh povtornyikh soobsjheniya poljzovatelya ne skhlopyivayutsya po odnomu khyeshu teksta. Dubli transportnyikh predstavlenij, mnogochastnoye soderzhimoye i otvetyi na utochneniya obrabotanyi po yavnomu kontraktu.
- Chitatelj vozvrasjhayet vse soobsjheniya bez dejstviteljnoj otmetki obrabotki, vklyuchaya propuski pered poslednim kursorom. Kursor uskoryayet chteniye, no ne yavlyayetsya otmetkoj obrabotki. Otvet sokhranyayet iskhodnyij poryadok, tochnyij tekst i ssyilki na vlozheniya, razlichayet otsutstviye soobsjhenij i nedostupnostj istochnika.
- Chteniye, predlozheniye otveta i uspeshnaya obrabotka razlichayutsya. Dolgovechnaya otmetka obrabotannogo soobsjheniya ssyilayetsya na sokhranyonnyiye iskhodnuyu komandu, soderzhateljnyij otvet i resheniye: ispolneniye, aktualjnuyu rabotu, utochneniye libo obosnovannyij otkaz. Otmetka ne obyyavlyayet vyipolnennyim iskhodnoye obyazateljstvo. Udaleniye ili podmena sootvetstvuyusjhego svideteljstva obnaruzhivayetsya.
- Kazhdoye najdennoye staroye soobsjheniye rassmatrivayetsya s posleduyusjhimi svyazannyimi utochneniyami. Sokhranyayetsya obosnovannyij vyivod: aktualjno, utochneno, zameneno, otmeneno, uzhe vyipolneno libo neyasno; vyivod ssyilayetsya na tochnyiye soobsjheniya i svideteljstva. Istoricheskaya komanda ne poluchayet aktualjnyikh polnomochij toljko po otsutstviyu otmetki obrabotki. Pri neyasnosti ona ostayotsya na razbore; podtverzhdyonnaya otmena ili zamena schitayetsya obrabotkoj s proiskhozhdeniyem, a ne ispolneniyem prezhnej komandyi. Regressii vklyuchayut otmenyonnoye porucheniye, pozdneye suzheniye obyyoma i izmeneniye prioriteta.
- Obnovleniye istorii atomarno i idempotentno; perezapusk posle chastichnogo chteniya ili zapisi ne teryayet soobsjheniye. Proverenyi dobavleniye khvosta, nezavershyonnaya poslednyaya stroka, usecheniye, zamena fajla i neodnoznachnostj proiskhozhdeniya. Istoricheskiye soobsjheniya bez podtverzhdyonnoj obrabotki vozvrasjhayutsya kak ostatok, a ne avtomaticheski pogashayutsya pri pervom zapuske.
- Obyichnyij proyektnyij vkhod obyazateljno vyizyivayet avtomatizaciyu pered planirovaniyem posle vosstanovleniya konteksta i pered finaljnyim dopuskom rabochej sessii; novyiye soobsjheniya, postupivshiye v khode rabotyi, proveryayutsya do zavisyasjhego ot nikh resheniya. Oshibka chteniya i nepustoj neobrabotannyij ostatok ne vyidayut razresheniye zaversheniya. Podklyucheniye k realjnomu host-runtime zayavlyayetsya toljko v podtverzhdyonnoj granice.
- Rabotosposobnostj podtverzhdena adresnyimi RED/GREEN, obyazateljnyim profilem pervichnogo i povtornogo chteniya i analizom optimizacii. Minimaljnaya otkryitaya fikstura vklyuchayet staryij propusk, povtor odinakovoj komandyi, pozdneye utochneniye i vosstanovleniye posle preryivaniya. Polnoye povtornoye chteniye boljshogo JSONL ne trebuyetsya pri kazhdom vyizove posle proverki iskhodnoj granicyi.
- Rukovodstvo obyyasnyayet cheloveku zapusk, vozvrasjhyonnyij ostatok, sposob podtverditj obrabotku, vosstanovleniye i predelyi. Obyazateljnoye povedeniye zakrepleno v kanonicheskikh pravilakh i primenimom priyomochnom konture; do etogo ruchnaya sverka yavno ostayotsya vremennyim sposobom.

## Sokhranyonnaya osnova realizacii

V kandidate C1 `436909208424595f7151f6febca75f89018c0bcb` uzhe yestj chistyiye chasti `Инструменты/fum-snimki-indeksa/scripts/диалог.py`, `происхождение_сообщений.py` i `очередь.py`: chteniye zavershyonnogo LF-prefiksa, UUID i khyesh session_meta, tochnyiye pozicii soobsjhenij, razlicheniye transportnyikh predstavlenij i istoriya dostavki/resheniya/podtverzhdeniya. Pereispoljzuyutsya primenimyiye chasti, bez vosstanovleniya vsego prezhnego mekhanizma ocheredi.

Tekusjhaya ocheredj ogranichena khvostom posle iskhodnogo kursora i obyyomom 64 MiB; ona ne dokazyivayet polnotu starogo ostatka. Ekzemplyar soobsjheniya sleduyet svyazyivatj s UUID zadachi, khyeshem iskhodnogo session_meta, diapazonom bajtov i khyeshem raw-stroki s LF. Proverka prinadlezhnosti citatyi spisku komand ne razlichayet odinakovyiye povtornyiye soobsjheniya. Ostatok vyichislyayetsya po vsem ekzemplyaram bez dejstviteljnoj obrabotki; staryiye otmetki perenosyatsya toljko pri odnoznachnom sootvetstvii ekzemplyaru. Neodnoznachnoye proiskhozhdeniye uchityivayetsya otdeljno i ne dayot rezuljtat «neobrabotannyikh net».

## Istochniki

- [Pryamyiye soobsjheniya i soderzhateljnyiye otvetyi](../../Zhurnal/2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/zapros.md).
- [Sokhranyonnyiye planyi i fakticheskij ostatok](../../Zhurnal/2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/otchyot.md).
- [Pravilo vosstanovleniya po iskhodnyim soobsjheniyam](../../AGENTS.md).
- [Sleduyusjhij perenos sobstvennoj realizacii](✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:510e20e9ca66984cced360b6e13a3e603512177a499965dc8f7a6e806c94fc96 -->
<!-- FUM-MD-RECENCY:END -->
