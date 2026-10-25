# Podgotovka FUMA dlya iOS

Poljzovatelj aktiviroval napravleniye iOS. Pervaya postavka — prilozheniye FUMA v Simulator s obsjhimi Swift-paketami interpretatora i kontejnera. Zapusk yesjhyo ne podtverzhdyon. [Iskhodnaya komanda i otvet](../../Zhurnal/2026-09-15_20-55-24_MSK_sokhranitj-medijnyij-plan-i-zapuski-platform/otchyot.md).

## Pervyij vosproizvodimyij rezuljtat

Avtomatizaciya sobirayet i zapuskayet prilozheniye na yavno vyibrannom ustanovlennom iOS Simulator. Dejstviye interfejsa vyipolnyayet susjhestvuyusjheye operatornoye preobrazovaniye stroki «Ayo🙂» v UTF-32LE, sokhranyayet opredeleniye, vkhod, rezuljtat i trassu v kontejner vnutri sandbox. Posle perezapuska prilozheniye vosproizvodit te zhe znacheniya po sokhranyonnyim dannyim bez iskhodnyikh vneshnikh fajlov. Oshibki zapisi vidnyi cheloveku; uspeshnaya kvitanciya pri otkaze ne poyavlyayetsya.

Srezyi prinimayutsya posledovateljno: snachala obsjhij runtime, sokhraneniye i replay v prilozhenii; zatem minimaljnyij Metal-kadr iz operatornoj scenyi. Otsutstviye gotovoj obsjhej scenyi ne blokiruyet pervuyu proverku runtime i ne razreshayet yeyo dublirovaniye v iOS.

Sobstvennyij graficheskij putj iOS — Metal. Pervyij graficheskij srez perevodit minimaljnuyu obsjhuyu operatornuyu scenu v nablyudayemyij kadr. Sistemnaya obolochka otvechayet za poverkhnostj, vvod i zhiznennyij cikl. Shriftovoj render ne podmenyayetsya CoreText. Dostupnostj Metal v vyibrannom Simulator proveryayetsya otdeljno; yego uspekh ne dokazyivayet rabotu fizicheskogo iPhone.

## Vladeniye i proverki

Platformennyiye importyi i realizacii vyibirayutsya cherez #if canImport i #if os v sootvetstvuyusjhikh komponentakh; usloviya linkovki zadayutsya i v obsjhem manifeste. Nalichiye modulya ne dokazyivayet nalichiye konkretnogo API ili vozmozhnosti GPU. Razdeleniye po susjhnostyam sokhranyayetsya, otdeljnyikh derevjyev koda na OS net.

Pozdneye utochneniye poljzovatelya otmenilo otdeljnyij katalog Swift-koda iOS. Celevaya struktura — yedinyij Prilozheniya/FUMA/Package.swift s obsjhimi Sources i Tests po modulyam i susjhnostyam. iOS pishet toljko yavno naznachennyiye novyiye fajlyi etoj obsjhej strukturyi i neobkhodimyiye nastrojki sborki prilozheniya. Obsjhij manifest, perenos susjhestvuyusjhikh iskhodnikov i perenosimostj kontejnera/interpretatora prinadlezhat odnomu vladeljcu Android. Do yego postavki iOS ne izmenyayet peremesjhayemyiye fajlyi; mozhet nezavisimo proveryatj ustanovlennyij Simulator i gotovitj konfiguraciyu bez dublirovaniya yadra.

Proverki ustanavlivayut tochnyiye bajtyi, replay posle perezapuska, sokhrannostj pri otkaze i otsutstviye lozhnogo uspekha. Ispolnyayemyiye izmeneniya prokhodyat TDD i profilj. Izmereniya razdelyayut sborku, zapusk, preobrazovaniye, zapisj i replay; resheniye ob optimizacii otnositsya k sopostavimomu scenariyu.

Versii Xcode, SDK i Simulator nablyudayutsya pered sborkoj. Sborki i dannyiye prilozheniya ostayutsya vne Git. Platnaya registraciya, App Store, podpisj dlya rasprostraneniya i dejstviya s fizicheskim ustrojstvom etim srezom ne naznachenyi. Nedostayusjhaya sreda ili nesovmestimostj paketa sokhranyayutsya kak konkretnoye prepyatstviye.

Postanovka svyazana s susjhestvuyusjhimi [platformennyim trebovaniyem](../../Trebovaniya/🟡-zapusk-FUMA-na-celevyikh-platformakh.md), [graficheskim trebovaniyem](../../Trebovaniya/🟡-graficheskiye-interfejsyi-FUMA.md) i [FUM-STEP-0182](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md); novyikh nomerov etot etap ne vyidayot.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:29:06 MSK -->
<!-- content-sha256: sha256:a6a3d32bb9438bdf9dcdcefecf1da0db77dfa5dacf2bc171d82ee1c299c5e552 -->
<!-- FUM-MD-RECENCY:END -->
