+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0010"
"статус" = "активна"
+++
# Maskirovka rannego otkaza sostavnoj shell-diagnostiki

Kartochka sokhranyayet tri sluchaya lozhnogo uspekha posledovateljnoj shell-diagnostiki. Rannyaya obyazateljnaya podkomanda ne vyipolnila trebuyemoye dejstviye, no poslednyaya podkomanda zavershilasj uspeshno, poetomu sostavnoj instrumentaljnyij vyizov vernul kod `0` i skryil nepolnotu rezuljtata na svoyej vneshnej granice.

## Nablyudayemyij sboj

V pervom vyizove dva obyazateljnyikh chteniya cherez `sed` zavershilisj soobsjheniyami `sed: No such file or directory`, posle chego uspeshnyij `rg` opredelil itogovyij kod vsego processa kak `0`. Vo vtorom vyizove chteniye kartochki FUM-SBOJ-0008 sostoyalosj, a sleduyusjhij `sed` poluchil oshibochno predpolozhennyij putj k FUM-STEP-0136 i zavershilsya tem zhe rannim otkazom; posleduyusjhiye chteniya tekusjhikh zaprosa i otchyota proshli, i posledneye iz nikh snova sdelalo itogovyij kod sostavnogo vyizova ravnyim `0`.

V tretjyem sluchaye obyazateljnyij build planovogo reyestra soobsjhil `malformed semantic relation` dlya iskhodnoj REQ-0058. V toj zhe posledovateljnoj shell-komande bez proverki promezhutochnogo iskhoda zatem vyipolnilasj recency: `md recency updated: 16 file(s) changed`. Vneshnyaya granica processa vernula `exit_code: 0`, chunk `ca4864`. Chislovoj kod otdeljnogo build v pervichnoj zapisi ne sokhranyon; obsjhij nolj ne podtverzhdayet uspekh etoj obyazateljnoj podkomandyi.

## Granica povtoreniya

Kartochka okhvatyivayet odin posledovateljnyij shell-vyizov iz neskoljkikh diagnosticheskikh podkomand, v kotorom do ispolneniya yestj obyazateljnyiye dlya rezuljtata dejstviya, no ikh iskhodyi ne uchityivayutsya po otdeljnosti, net nemedlennogo zakryitogo otkaza ili yavnogo agregirovaniya, a obsjhij status sovpadayet toljko so statusom poslednej podkomandyi. Proyavleniye voznikayet, kogda rannyaya obyazateljnaya podkomanda ne vyipolnyayetsya, a pozdnyaya uspeshnaya komanda prevrasjhayet sostavnoj vyizov v globaljnyij uspekh.

Syuda ne otnosyatsya odinochnaya komanda s dostoverno vozvrasjhyonnyim statusom, posledovateljnostj s proverkoj kazhdogo obyazateljnogo iskhoda, a takzhe zaraneye obyyavlennaya neobyazateljnaya proba, otkaz kotoroj dopustim dlya vyivoda i otdeljno ostayotsya vidimyim. Neobyyavlennyij ili neobkhodimyij dlya diagnosticheskogo vyivoda shag schitayetsya obyazateljnyim; pozdnij uspekh ne mozhet menyatj etu klassifikaciyu zadnim chislom.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                | Effekt                                                                                                                                                                                                                 | Vosstanovleniye                                                                                                                                                                                                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet odin sostavnoj vyizov: dva obyazateljnyikh `sed` soobsjhili `No such file or directory`, a posleduyusjhij uspeshnyij `rg` ostavil vsemu processu kod `0`. | Dva obyazateljnyikh istochnika ne byili prochitanyi, no vneshnyaya granica soobsjhila uspekh; polnota diagnostiki mogla byitj oshibochno prinyata bez prosmotra rannego standartnogo potoka oshibok.                                          | Oshibochnyiye puti byili zamechenyi po tekstu vyivoda i chteniye prodolzhili otdeljnyimi vyizovami. Eto vosstanovilo tekusjhuyu diagnostiku, no ne izmenilo pravilo vyichisleniya obsjhego statusa; sistemnaya mera vyinesena v FUM-STEP-0138.                                                |
| `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet sleduyusjhij vyizov: posle chteniya FUM-SBOJ-0008 `sed` ne nashyol oshibochno predpolozhennyij putj k FUM-STEP-0136, a pozdniye chteniya zaprosa i otchyota zavershili process kodom `0`. | Obyazateljnaya kartochka shaga ne byila prochitana, odnako uspeshnyiye pozdniye chteniya zamaskirovali otkaz na urovne vsego vyizova; vosstanovleniye zaviselo ot ruchnogo raspoznavaniya stroki `No such file or directory`.                 | Praviljnyij putj k FUM-STEP-0136 nashli otdeljnyim poiskom i prochitali povtorno. Tochnoye proyavleniye stanovitsya osnovaniyem FUM-STEP-0138, potomu chto vtoroj lozhnyij uspekh podtverdil povtoryayemostj mekhanizma posle uzhe nablyudavshegosya pervogo sluchaya.                          |
| `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0003` | [Pervichnyiye vyizov i rezuljtat tekusjhego etapa](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md): `call_xdeARQMhCl3K1VtYplvjkstv`, 2026-09-11 05:58:13.711 UTC; `ca4864` sokhranyayet `malformed semantic relation`, uspeshnuyu recency i obsjhij kod `0`. | Obyazateljnyij build ne zavershil trebuyemoye postroyeniye, no sostavnoj vyizov obyyavil obsjhij uspekh. Otdeljnyij chislovoj kod build i yego dliteljnostj neizvestnyi. | Korenj raspoznal otkaz po tekstu, ne prinyal obsjhij nolj za uspeshnyij build i prodolzhil adresnoye ispravleniye zavisimosti. Pozdnij uspeshnyij build podtverzhdayet vosstanovleniye vkhoda, no ne predotvrasjheniye maskirovki; 0010 i 0138 ostayutsya aktivnyimi. |

## Ozhidaniye i klassifikaciya

Eto oshibka ispolneniya sostavnoj diagnostiki i kontrakta yeyo obsjhego rezuljtata, a ne defekt `sed`, `rg`, shell ili instrumentaljnoj sredyi. Kazhdaya podkomanda vernula sobstvennyij dostovernyij iskhod, a obolochka shtatno vozvratila status poslednej komandyi. Oshibka sostoit v tom, chto takoj status byil ispoljzovan dlya posledovateljnosti, uspekh kotoroj treboval uspeshnogo zaversheniya vsekh obyazateljnyikh podkomand.

Tretjye proyavleniye narushayet tot zhe kontrakt obsjhego rezuljtata: obe podkomandyi byili obyazateljnyimi, no obyichnyij perevod stroki mezhdu nimi ne sokhranyal otkaz pervoj. Prichina otkloneniya vkhoda REQ-0058 otnositsya k nepolnoj postavke 0037; otsutstviye otchyotnoj obyortki u pryamyikh build otnositsya k 0025. Eti otdeljnyiye granicyi ne obyyedinyayutsya s 0010. Dve posleduyusjhiye probyi, uzhe vernuvshiye obsjhij kod `1`, ne yavlyayutsya novyimi proyavleniyami maskirovki.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon obsjhij mekhanizm: obyazateljnyiye komandyi soyedinenyi posledovateljnyim ispolneniyem bez nemedlennogo zakryitogo otkaza i bez nakopleniya ikh statusov; posle rannego nenulevogo koda ispolneniye prodolzhayetsya, pozdnyaya komanda vozvrasjhayet `0`, a vneshnyaya granica vidit toljko etot poslednij kod. Tekst rannej oshibki ostayotsya v vyivode, no ne vliyayet na mashinnyij itog i poetomu trebuyet nenadyozhnogo ruchnogo raspoznavaniya.

Vremennoye sderzhivaniye — soyedinyatj obyazateljnyiye diagnosticheskiye dejstviya toljko sposobom, kotoryij prekrasjhayet posledovateljnostj ili yavno sokhranyayet ikh nenulevoj iskhod, a neobyazateljnyiye probyi zaraneye pomechatj otdeljno. Polnoye ustraneniye trebuyet podderzhannogo sostavnogo marshruta s yavnoj klassifikaciyej kazhdoj podkomandyi, pooperacionnyim uchyotom i obsjhim pravilom: lyuboj otkaz obyazateljnoj podkomandyi delayet vesj rezuljtat neuspeshnyim nezavisimo ot posleduyusjhikh uspekhov.

Dlya proyavleniya `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0003` vyipolneno toljko ogranichennoye vosstanovleniye predmetnogo vkhoda. Pervyij otkaz i lozhnyij obsjhij uspekh sokhranenyi; novyij vosproizvodimyij sostavnoj marshrut v etom epizode ne sozdan. Uspekh pozdnego build ne zakryivayet dejstvuyusjhuyu sistemnuyu granicu kartochki.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                                                                               | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0138 — Ograditj sostavnuyu shell-diagnostiku ot maskirovki rannego otkaza](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0138-ograditj-sostavnuyu-shell-diagnostiku-ot-maskirovki-rannego-otkaza.md)              | Vvodit yavnoye razlicheniye obyazateljnyikh i neobyazateljnyikh podkomand i agregiruyet obsjhij iskhod bez poteri rannego obyazateljnogo otkaza.                    | `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj otdeljnyikh proyavlenij, dokazannoj obsjhej granicyi i dvustoronnej svyazi s porozhdyonnyim shagom.                                     | Kontur kartochek sboyev           |

Svyazj s FUM-STEP-0138 dopolnena tochnyim osnovaniyem `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0003`: pozdnij uspekh recency posle obyazateljnogo otkaza build. Prezhniye osnovaniya 0001 i 0002 sokhranyayutsya.

## Kriterii zakryitiya

- Dlya vsekh tryokh sokhranyonnyikh proyavlenij dokazano, chto otkaz lyuboj obyazateljnoj diagnosticheskoj podkomandyi ostayotsya otkazom obsjhego rezuljtata nezavisimo ot posleduyusjhikh uspekhov.
- Razreshyonnyij uspekh pri otkaze neobyazateljnoj probyi dokazuyemo otlichayetsya ot lozhnogo uspekha obyazateljnoj posledovateljnosti i sokhranyayet sobstvennyij iskhod probyi.
- Dokazateljstvo ustraneniya svyazano s vyipolnennoj FUM-STEP-0138 i podtverzhdayet granicu na rannem, srednem i neskoljkikh obyazateljnyikh otkazakh; zaversheniye shaga bez takogo dokazateljstva kartochku ne zakryivayet.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [Tekusjhaya registraciya povtornogo proyavleniya](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).
- [Adresnyiye pervichnyiye svideteljstva proyavleniya 0003](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md): posledovateljnyij vyizov build i recency, vyivod `ca4864`, iskhodnaya stroka JSONL i yeyo tochnyij khyesh sokhranenyi otdeljno ot publikuyemogo teksta.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:32dd081bc92675bd890b396f0eaaf25c7175cf4522a335da1fbc49ad0417ff0e -->
<!-- FUM-MD-RECENCY:END -->
