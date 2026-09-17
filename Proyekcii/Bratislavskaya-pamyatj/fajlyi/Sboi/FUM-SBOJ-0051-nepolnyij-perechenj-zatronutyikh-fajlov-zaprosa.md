+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0051"
"статус" = "активна"
+++
# Nepolnyij perechenj zatronutyikh fajlov zaprosa

## Nablyudayemyij sboj

Shablon stroiteljnogo etapa dobavil soderzhateljnoye izmeneniye napravleniya 08, no razdel «Povliyal na fajlyi» perechislil kartochki, trebovaniya i reyestr bez samogo napravleniya. Korrektnaya proverka svyaznosti ostanovila kommit soobsjheniyem `unexpected Git status path: Планирование/направления-проектирования-и-развития/08-физические-и-дальние-контуры.md`.

## Proyavleniya

| Nomer                           | Svideteljstvo                                                                                                                                                                                                 | Effekt                                                 | Vosstanovleniye                                                                                                                                                                             |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0001` | [Polnaya adresnaya sverka iskhodnogo i vosstanovlennogo spiska](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_01-27-07_MSK_запланировать-строительное-направление/материалы/запуски-проверок/6_7977a3a9-4582-479e-91bc-3888bf67af03.json) | Podgotovlennaya kontroljnaya tochka otklonena do kommita. | Poluchitj polnyij fakticheskij Git-perechenj, sopostavitj s naznachennoj oblastjyu i razdelom zaprosa, dobavitj propusjhennyij razreshyonnyij katalog napravlenij, povtoritj proverku polnogo perechnya. |
| `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0002` | [Zaklyuchiteljnaya diagnostika etapa Linux VM](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_18-28-10_MSK_связать-измерения-с-запросом-и-восстановлением/отчёт.md) | Desyatj materialov ne pokryivalisj razdelom zaprosa: nazvaniye kataloga byilo tekstom bez Markdown-ssyilki. | Dobavlena tochnaya ssyilka na svoj katalog materialov, povtorena zaklyuchiteljnaya svyaznostj; iskhodniki i testyi ne menyalisj. |
| `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0003` | [Diagnostika pered d4ee](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_19-51-31_MSK_подключить-экспорт-и-повтор-гостевых-измерений/отчёт.md) | Ssyilki na dva dochernikh zaprosa ne pokryivali 29 materialov i otchyotov. | Polnyij fakticheskij Git-perechenj sveren s razreshyonnyim perenosom, dobavlenyi ssyilki na dve tochnyiye papki; povtornaya read-only svyaznostj proshla. |
| `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0004` | [Pervichnyij otkaz etapa ispravleniya plana](https://github.com/fum-lab/fum/blob/f5716675472a9807d004e95144b98c621855bfc2/Журнал/2026-09-11_23-32-06_MSK_исправить-основания-плана-продолжения/отчёт.md) | Susjhestvuyusjhiye katalogi sokhranyonnoj proyekcii i tekusjhikh mashinnyikh zapisej ne pokryivalisj razdelom zaprosa; zaklyuchiteljnaya svyaznostj vernula kod 1. | Polnyij fakticheskij Git-perechenj sopostavlen s naznachennoj oblastjyu, dobavlenyi dve tochnyiye ssyilki; svyaznostj prinyala kontroljnuyu tochku 0c1a992a5f9adb197cfe0c87031cab34426e640f. |
| `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0005` | [Otkaz kontroljnoj svyaznosti arkhivnogo sliyaniya](../Zhurnal/2026-09-12_05-27-53_MSK_obyyedinitj-arkhiv-fuma-s-kornevoj-rabotoj/otchyot.md) i [tochnoye svideteljstvo](../Zhurnal/2026-09-12_05-27-53_MSK_obyyedinitj-arkhiv-fuma-s-kornevoj-rabotoj/materialyi/vosstanovleniye-oblasti-zaprosa.json) | Ssyilka na vesj Zhurnal ne zamenila obyazateljnyiye otdeljnyiye ssyilki tekusjhego zaprosa i sosednego otchyota; odin vyizov dal dve diagnostiki i kod 1 za 145,531281542 s. | Dobavlenyi obe pryamyiye ssyilki; adresno podtverzhdenyi iskhodnoye otsutstviye, ispravlennaya para i pokryitiye vsego fakticheskogo Git-sostoyaniya. Povtornyij zaklyuchiteljnyij dopusk uchityivayetsya otdeljno. |

### FUM-SBOJ-0051/PROYAVLENIYE-0007

[Pervichnyij read-only-otkaz kontroljnoj tochki](../Zhurnal/2026-09-14_22-03-16_MSK_prinyatj-sovmestnuyu-klassifikaciyu-ostatka/materialyi/nablyudeniye-nepolnogo-okhvata.json) imeyet kod 1: razdel «Povliyal na fajlyi» ne perechislyal dva JSON tekusjhikh proverok i indeks svezhesti Markdown. Dliteljnostj ne izmerena; vyimyishlennaya pozdnyaya zapisj ne sozdayotsya. Dobavlenyi tochnyiye ssyilki na materialyi etapa i indeks; povtornyij dopusk vyipolnyayetsya posle polnogo oformleniya. Soderzhateljnyiye Python/Swift-testyi radi etogo ne povtoryalisj.

V etoj versii vklyuchenyi desyatj proyavlenij: 0001–0005 i 0007–0011. Nomer 0006 zanyat otdeljnoj nezavershyonnoj rabotoj i ne pereispoljzuyetsya; yeyo dannyiye ne importirovanyi i priyomka ne zayavlyayetsya. Nomer 0007 naznachen koordinatorom posle sverki dostupnyikh refs i rabochikh fajlov.

### FUM-SBOJ-0051/PROYAVLENIYE-0008

[Predvariteljnaya svyaznostj7a916e50](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/18_7a916e50-a509-40ce-af4d-1607372dcd07.json) do povtornogo polnogo progona obnaruzhila odin propusjhennyij putj: izmenyonnyij proizvodnyij indeks svezhesti Markdown. Kod1 i43.194442792s sokhranenyi; [nablyudeniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-povtornogo-propuska-okhvata.json) svyazyivayet tochnyij SHA zapisi i vyivoda. V zapros dobavlena tochnaya ssyilka na indeks. Polnyij povtor yesjhyo ne zapuskalsya, poetomu otkaz ne povlyok novuyu doroguyu proyekciyu. Koordinator vyidelil0008 posle chteniya16versij v dostupnyikh zaregistrirovannyikh worktrees; odin worktree i chastnyiye chuzhiye rezervyi ne okhvachenyi.0006i0007 sokhranenyi za prezhnimi granicami.

### FUM-SBOJ-0051/PROYAVLENIYE-0009

[Otkaz predposyilki master](../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/pervyij-otkaz-svyaznosti-predposyilki.json) v processe 9434 vernul kod 1: ne perechislen predyidusjhij zapros s izmenyonnoj navigaciyej. Svideteljstvo prochitano iz `5b64d4a6bff7d555fe4219ac42357a9ee66a9e83`, yego SHA zakreplyon v [registracii](../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/povtoryi-oformleniya.json). Lokaljnoye ispravleniye ssyilki ne zakryivayet rannyuyu avtomatizirovannuyu podgotovku polnogo sostava.

### FUM-SBOJ-0051/PROYAVLENIYE-0010

[Otkaz tekusjhego arkhiva](../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/otkaz-okhvata-istochnikov.txt) otklonil 49 fajlov semi HTML-snimkov. Arkhivator dobavil ssyilki v «Prikreplyayemyiye materialyi», no dejstvuyusjhij okhvat proveryayetsya v «Povliyal na fajlyi». Korenj dobavil tochnyiye ssyilki na semj katalogov v trebuyemyij razdel, sokhraniv syiryiye materialyi. Proverka korrektno ostanovila kommit; izmenyatj validator ili rasshiryatj razresheniye do vsego checkout ne trebuyetsya.

### FUM-SBOJ-0051/PROYAVLENIYE-0011

[Terminaljnaya zapisj kornevogo J6](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/iskhodnaya-zapisj-4_a8047c54-dc3d-46e0-a658-9e120c7d4e16.json) zavershena kodom 1 za 568,460521583 s. Posle ispravleniya otdeljnoj aktivnoj ssyilki vne pokoleniya polnyij dopusk doshyol do shaga11: [polnyij zakhvat i adresnyiye vyiderzhki](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/nablyudeniye-otkaza-4.json) soderzhat 97 soobsjhenij `unexpected Git status path`: 96 susjhestvuyusjhikh putej proyekcii i proizvodnyij reyestr planirovaniya. Otsutstvuyusjhikh putej sredi etogo nabora ne obnaruzheno koordinatorom; eto ta zhe granica susjhestvuyusjhego sostava, chto u0004, a ne isklyuchyonnaya ssyilka pervogo otkaza.

Razdel zaprosa dopolnen integratorom razreshyonnyimi katalogom proyekcii i reyestrom. Eto mestnoye vosstanovleniye oblasti; sistemnoye ranneye predotvrasjheniye i itogovaya priyomka etim ne dokazanyi. Nomer0011 [naznachen koordinatorom](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/naznacheniye-0051-0011.json) posle sverki207 dostupnyikh local/origin refs,7 unikaljnyikh Git-versij i32 rabochikh fajlov;36 zaregistrirovannyikh derevjyev bez kartochki, setj i nezaregistrirovannyiye rezervyi vne sverki. V iskhodnom snimke `e1da02ba71776a4f4452bb760a906fea1e809e4d` tekstyi proyavlenij 0009 i 0010 otsutstvovali. V obyyedinyonnoj kartochke oni sokhranenyi iz `ebdbb6211548e0dc5533fea4f287ce291a5b355a` pod prezhnimi nomerami. Nomer 0006 ostayotsya zanyatyim.

## Granica povtoreniya

Iskhodnaya prichina — nepolnyij perechenj oblasti v shablone zaprosa pri perekhode ot otdeljnyikh kartochek k svodnomu napravleniyu. Posleduyusjhiye proyavleniya podtverzhdayut tu zhe granicu susjhestvuyusjhikh razreshyonnyikh fajlov: perechisleniye chasti obyyektov ili tekstovoye imya kataloga ne dayot polnogo pokryitiya. Obsjhaya mera — sverka vsego fakticheskogo Git-perechnya i razreshyonnyikh celej ssyilok, s sokhraneniyem otkaza dlya postoronnikh putej. Oshibka svyaznosti ili vyikhod izmeneniya za soglasovannyij obyyom ne ustanovlenyi. Eta granica otlichayetsya ot FUM-SBOJ-0035: tam otsutstvuyusjhij udalyonnyij putj treboval specialjnogo markera; zdesj propusjhen susjhestvuyusjhij izmenyonnyij dokument.

## Ozhidaniye i klassifikaciya

Razdel zatronutyikh fajlov dolzhen pokryivatj fakticheskij razreshyonnyij sostav svoyego etapa. Zasjhita praviljno otklonyayet nepolnyij perechenj; oshibka validatora ne ustanovlena.

## Mekhanizm i sistemnoye ustraneniye

1. Poluchitj polnyij tekusjhij perechenj komandoj `git -c core.quotepath=false status --short` v tochnom korne zadachi; ne vyivoditj yego iz zaraneye perechislennyikh shablonom katalogov.
2. Sopostavitj kazhdoye soderzhateljnoye izmeneniye s iskhodnoj komandoj i razdelom «Povliyal na fajlyi». Ispoljzovatj `affected_files_from_request` i `validate_git_status` susjhestvuyusjhej proverki svyaznosti; poslednemu peredatj `None` tretjim argumentom dlya chteniya vsego tekusjhego Git-sostoyaniya.
3. Dlya namerennogo izmeneniya napravleniya dobavitj tochnuyu ssyilku na dokument libo susjhestvuyusjhij tematicheskij katalog. Ne rasshiryatj oblastj do vsego checkout i ne obyyavlyatj postoronniye izmeneniya razreshyonnyimi.
4. Povtoritj proverku vsego fakticheskogo perechnya, zatem svezhestj, indeks i nezavisimuyu svyaznostj kontroljnoj tochki. Izmenyonnyij posle sverki snimok proveryatj zanovo.

Adresnyij zapusk vosproizvyol yedinstvennyij iskhodnyij otkaz polnogo perechnya, proveril tochnuyu dobavku v pamyati i otsutstviye neobyyavlennyikh izmenenij posle neyo. Dve susjhestvuyusjhiye regressii podtverdili prinyatiye susjhestvuyusjhikh potomkov i otkloneniye sosednego puti, pokhozhego prefiksa i neukazannogo udaleniya. Proverochnyij kod ne izmenyalsya.

## Istoricheskoye ogranichennoye vosstanovleniye i povtor

Prezhnij status `устранена` oznachal proveryayemoye ogranichennoye vosstanovleniye nepolnogo spiska cherez polnyij Git-perechenj i sokhranyonnuyu otricateljnuyu granicu. On ne obesjhal nevozmozhnosti novogo propuska agentom i ne yavlyalsya strogoj priyomkoj vsej vetki. Razovyij uspeshnyij povtor bez opisannoj sverki etogo kriteriya ne vyipolnyayet.

Novoye podtverzhdyonnoye proyavleniye posle zakryitiya vozvrasjhayet kartochku v sostoyaniye `активна`. Uspekh ogranichennogo vosstanovleniya ostayotsya istoricheskim dokazateljstvom; ustojchivoye predotvrasjheniye povtornogo nepolnogo perechnya yesjhyo ne realizovano.

## Svyazannyiye shagi

[FUM-STEP-0225](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0225-sveryatj-polnyij-sostav-materialov-etapa.md) aktualiziruyet rabotu po osnovaniyam `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0002` i `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0003`. Zakryitiye trebuyet dokazannogo avtomatizirovannogo vyiyavleniya polnogo nabora materialov do zaklyuchiteljnoj svyaznosti na etoj granice s sokhraneniyem otkazov dlya postoronnego puti. Povtornyij uspeshnyij kommit sam po sebe etogo ne dokazyivayet.

Osnovaniye aktualizacii susjhestvuyusjhego STEP0225 v tekusjhem etape — `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0004`. Prezhniye osnovaniya 0002 i 0003 i obsjhij kriterij zakryitiya sokhranyayutsya; mestnoye ispravleniye perechnya ne vyipolnyayet avtomatizirovannuyu meru.

`FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0005` dopolniteljno trebuyet dvukh obyazateljnyikh otdeljnyikh ssyilok tekusjhej paryi, dazhe kogda katalog pokryivayet yeyo Git-puti. Eto osnovaniye otrazheno v STEP0225; avtomaticheskoye predotvrasjheniye ostayotsya otkryityim.

Dopolniteljnoye osnovaniye FUM-STEP-0225 — `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0007`: polnyij perechenj sobstvennyikh materialov proverok i indeksa svezhesti do zaklyuchiteljnogo dopuska.

Povtornoye osnovaniye FUM-STEP-0225 — `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0008`: proizvodnyij indeks vkhodit v polnyij fakticheskij sostav kazhdogo novogo etapa, dazhe yesli predyidusjhaya papka uzhe ispravlyalasj. Uspekh tekusjhej svyaznosti ne dokazyivayet avtomaticheskoye predotvrasjheniye.

Dopolniteljnyiye osnovaniya STEP0225 — `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0009` i `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0010`: navigacionnyij fajl prezhnego etapa i tochnyiye katalogi novyikh snimkov dolzhnyi popastj v dejstvuyusjhij razdel okhvata do zaklyuchiteljnoj svyaznosti.

Osnovaniye novogo utochneniya STEP0225 — `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0011`: polnyij fakticheskij sostav proizvodnoj proyekcii i reyestra proveryayetsya do dorogogo dopuska.

## Kriterii zakryitiya

Avtomatizirovannaya podgotovka vyiyavlyayet polnyij sostav materialov do zaklyuchiteljnoj svyaznosti, sokhranyayet otkaz dlya postoronnego puti i trebuyet otdeljnyiye ssyilki tekusjhej paryi. Prezhniye kriterii vsekh vklyuchyonnyikh proyavlenij sokhranenyi; lokaljnoye ispravleniye spiska ikh ne zakryivayet.

## Istochniki

- [Registraciya proyavleniya 0004](https://github.com/fum-lab/fum/blob/f5716675472a9807d004e95144b98c621855bfc2/Журнал/2026-09-12_00-44-07_MSK_зарегистрировать-диагностику-продолжения/запрос.md).
- Polnaya iskhodnaya istoriya prinyata iz `fe3de05afba64554c9f5801f0f2583c43c67705a`; SHA-256 iskhodnogo fajla `681db6060d02c9297da7b2fd464ab5f38fa530c96fae81d0169e9cce4dddd34e`. Istoricheskiye istochniki, otsutstvuyusjhiye v etom dereve, privyazanyi k tomu zhe kommitu.

- [Novyiye proyavleniya i soglasovannyij rezerv shaga](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_20-38-32_MSK_подключить-наблюдение-к-гостю-и-обмену/запрос.md).
- [Tekusjhij zapros](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_01-27-07_MSK_запланировать-строительное-направление/запрос.md).
- [Otchyot vosstanovleniya](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_01-27-07_MSK_запланировать-строительное-направление/отчёт.md).
- [Kontrakt svyaznosti](../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md).
- [Inaya granica otsutstvuyusjhego udalyonnogo puti](FUM-SBOJ-0035-propusk-udalyonnogo-puti-proyekcii-v-zaprose.md).

- [Registraciya proyavleniya0007](../Zhurnal/2026-09-14_22-03-16_MSK_prinyatj-sovmestnuyu-klassifikaciyu-ostatka/zapros.md).
- Istoriya0001–0005 perenesena iz `775128491a1b9f9b130bd6946ad2d33fd04dbe51`, SHA-256 `b34bb722f87b505ff82cbd56afce485a7dadf73b1f0b590436be64d6e9cf4c83`; smyisl i iskhodnyiye nomera sokhranenyi, razdelyi privedenyi k dejstvuyusjhemu formatu kartochki.
- [Naznacheniye0008 i tekusjhij zapros](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).

- [Registraciya0011 i granicyi perenosa](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-17 22:16:46 MSK -->
<!-- content-sha256: sha256:f6444b192047c1792e586eacf000c7307b090423011812e33551e73b0aada0df -->
<!-- FUM-MD-RECENCY:END -->
