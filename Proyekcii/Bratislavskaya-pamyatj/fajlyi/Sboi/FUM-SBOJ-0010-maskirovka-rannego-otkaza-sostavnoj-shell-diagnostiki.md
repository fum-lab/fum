+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0010"
"статус" = "активна"
+++
# Maskirovka rannego otkaza sostavnoj shell-diagnostiki

Kartochka sokhranyayet dva sluchaya lozhnogo uspekha posledovateljnoj shell-diagnostiki. Rannyaya obyazateljnaya podkomanda ne prochitala nuzhnyij istochnik, no poslednyaya podkomanda zavershilasj uspeshno, poetomu sostavnoj instrumentaljnyij vyizov vernul kod `0` i skryil nepolnotu rezuljtata na svoyej vneshnej granice.

## Nablyudayemyij sboj

V pervom vyizove dva obyazateljnyikh chteniya cherez `sed` zavershilisj soobsjheniyami `sed: No such file or directory`, posle chego uspeshnyij `rg` opredelil itogovyij kod vsego processa kak `0`. Vo vtorom vyizove chteniye kartochki FUM-SBOJ-0008 sostoyalosj, a sleduyusjhij `sed` poluchil oshibochno predpolozhennyij putj k FUM-STEP-0136 i zavershilsya tem zhe rannim otkazom; posleduyusjhiye chteniya tekusjhikh zaprosa i otchyota proshli, i posledneye iz nikh snova sdelalo itogovyij kod sostavnogo vyizova ravnyim `0`.

## Granica povtoreniya

Kartochka okhvatyivayet odin posledovateljnyij shell-vyizov iz neskoljkikh diagnosticheskikh podkomand, v kotorom do ispolneniya yestj obyazateljnyiye dlya rezuljtata dejstviya, no ikh iskhodyi ne uchityivayutsya po otdeljnosti, net nemedlennogo zakryitogo otkaza ili yavnogo agregirovaniya, a obsjhij status sovpadayet toljko so statusom poslednej podkomandyi. Proyavleniye voznikayet, kogda rannyaya obyazateljnaya podkomanda ne vyipolnyayetsya, a pozdnyaya uspeshnaya komanda prevrasjhayet sostavnoj vyizov v globaljnyij uspekh.

Syuda ne otnosyatsya odinochnaya komanda s dostoverno vozvrasjhyonnyim statusom, posledovateljnostj s proverkoj kazhdogo obyazateljnogo iskhoda, a takzhe zaraneye obyyavlennaya neobyazateljnaya proba, otkaz kotoroj dopustim dlya vyivoda i otdeljno ostayotsya vidimyim. Neobyyavlennyij ili neobkhodimyij dlya diagnosticheskogo vyivoda shag schitayetsya obyazateljnyim; pozdnij uspekh ne mozhet menyatj etu klassifikaciyu zadnim chislom.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                | Effekt                                                                                                                                                                                                                 | Vosstanovleniye                                                                                                                                                                                                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet odin sostavnoj vyizov: dva obyazateljnyikh `sed` soobsjhili `No such file or directory`, a posleduyusjhij uspeshnyij `rg` ostavil vsemu processu kod `0`. | Dva obyazateljnyikh istochnika ne byili prochitanyi, no vneshnyaya granica soobsjhila uspekh; polnota diagnostiki mogla byitj oshibochno prinyata bez prosmotra rannego standartnogo potoka oshibok.                                          | Oshibochnyiye puti byili zamechenyi po tekstu vyivoda i chteniye prodolzhili otdeljnyimi vyizovami. Eto vosstanovilo tekusjhuyu diagnostiku, no ne izmenilo pravilo vyichisleniya obsjhego statusa; sistemnaya mera vyinesena v FUM-STEP-0138.                                                |
| `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet sleduyusjhij vyizov: posle chteniya FUM-SBOJ-0008 `sed` ne nashyol oshibochno predpolozhennyij putj k FUM-STEP-0136, a pozdniye chteniya zaprosa i otchyota zavershili process kodom `0`. | Obyazateljnaya kartochka shaga ne byila prochitana, odnako uspeshnyiye pozdniye chteniya zamaskirovali otkaz na urovne vsego vyizova; vosstanovleniye zaviselo ot ruchnogo raspoznavaniya stroki `No such file or directory`.                 | Praviljnyij putj k FUM-STEP-0136 nashli otdeljnyim poiskom i prochitali povtorno. Tochnoye proyavleniye stanovitsya osnovaniyem FUM-STEP-0138, potomu chto vtoroj lozhnyij uspekh podtverdil povtoryayemostj mekhanizma posle uzhe nablyudavshegosya pervogo sluchaya.                          |

## Ozhidaniye i klassifikaciya

Eto oshibka ispolneniya sostavnoj diagnostiki i kontrakta yeyo obsjhego rezuljtata, a ne defekt `sed`, `rg`, shell ili instrumentaljnoj sredyi. Kazhdaya podkomanda vernula sobstvennyij dostovernyij iskhod, a obolochka shtatno vozvratila status poslednej komandyi. Oshibka sostoit v tom, chto takoj status byil ispoljzovan dlya posledovateljnosti, uspekh kotoroj treboval uspeshnogo zaversheniya vsekh obyazateljnyikh podkomand.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon obsjhij mekhanizm: obyazateljnyiye komandyi soyedinenyi posledovateljnyim ispolneniyem bez nemedlennogo zakryitogo otkaza i bez nakopleniya ikh statusov; posle rannego nenulevogo koda ispolneniye prodolzhayetsya, pozdnyaya komanda vozvrasjhayet `0`, a vneshnyaya granica vidit toljko etot poslednij kod. Tekst rannej oshibki ostayotsya v vyivode, no ne vliyayet na mashinnyij itog i poetomu trebuyet nenadyozhnogo ruchnogo raspoznavaniya.

Vremennoye sderzhivaniye — soyedinyatj obyazateljnyiye diagnosticheskiye dejstviya toljko sposobom, kotoryij prekrasjhayet posledovateljnostj ili yavno sokhranyayet ikh nenulevoj iskhod, a neobyazateljnyiye probyi zaraneye pomechatj otdeljno. Polnoye ustraneniye trebuyet podderzhannogo sostavnogo marshruta s yavnoj klassifikaciyej kazhdoj podkomandyi, pooperacionnyim uchyotom i obsjhim pravilom: lyuboj otkaz obyazateljnoj podkomandyi delayet vesj rezuljtat neuspeshnyim nezavisimo ot posleduyusjhikh uspekhov.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                                                                               | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0138 — Ograditj sostavnuyu shell-diagnostiku ot maskirovki rannego otkaza](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0138-ograditj-sostavnuyu-shell-diagnostiku-ot-maskirovki-rannego-otkaza.md)              | Vvodit yavnoye razlicheniye obyazateljnyikh i neobyazateljnyikh podkomand i agregiruyet obsjhij iskhod bez poteri rannego obyazateljnogo otkaza.                    | `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj otdeljnyikh proyavlenij, dokazannoj obsjhej granicyi i dvustoronnej svyazi s porozhdyonnyim shagom.                                     | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Dlya oboikh sokhranyonnyikh proyavlenij dokazano, chto otkaz lyuboj obyazateljnoj diagnosticheskoj podkomandyi ostayotsya otkazom obsjhego rezuljtata nezavisimo ot posleduyusjhikh uspekhov.
- Razreshyonnyij uspekh pri otkaze neobyazateljnoj probyi dokazuyemo otlichayetsya ot lozhnogo uspekha obyazateljnoj posledovateljnosti i sokhranyayet sobstvennyij iskhod probyi.
- Dokazateljstvo ustraneniya svyazano s vyipolnennoj FUM-STEP-0138 i podtverzhdayet granicu na rannem, srednem i neskoljkikh obyazateljnyikh otkazakh; zaversheniye shaga bez takogo dokazateljstva kartochku ne zakryivayet.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 01:09:33 MSK -->
<!-- content-sha256: sha256:a800e9415228199c91d836abbcd008c4c1275b6ab989d31342472bb10cc5edab -->
<!-- FUM-MD-RECENCY:END -->
