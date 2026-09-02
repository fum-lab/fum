# Nablyudayemyij vkhodnoj signal

Nablyudayemyij vkhodnoj signal — sobyitiye, dejstviye ili soobsjheniye, kotoroye postupayet v [FUM](FUM.md), vliyayet na yego [pamyatj](pamyatj-FUM.md), [agentskij cikl](agentskij-cikl.md) ili poljzovateljskij interfejs i dostupno agentu v forme, prigodnoj dlya obrabotki.

K nablyudayemyim vkhodnyim signalam otnosyatsya [iskhodnyiye zaprosyi](iskhodnyij-zapros.md), [navigaciya po pamyati FUM](navigaciya-po-pamyati-FUM.md), dejstviya v interfejse, sobyitiya instrumentov, audiovvod i drugiye kanalyi vzaimodejstviya, yesli oni mogut izmenitj sostoyaniye rabotyi ili smyislovoj kontekst.

V [dokumentacionnom prototipe FUM](dokumentacionnyij-prototip-FUM.md) chelovecheskij vvod obyichno dostigayet agenta kak diskretnoye soobsjheniye-zadacha. [Korobochnaya realizaciya FUM](korobochnaya-realizaciya-FUM.md) dolzhna umetj nablyudatj razreshyonnyij vvod vo vremya aktivnogo cikla kak uporyadochennyij potok sobyitij i primenyatj znachimoye izmeneniye na bezopasnoj kontroljnoj tochke. Razlichiye otnositsya k granulyarnosti i vremeni nablyudeniya: kazhdoye sobyitiye po-prezhnemu ostayotsya otdeljnyim strukturirovannyim signalom.

Nablyudeniye sobyitiya ne trebuyet otdeljnogo vyizova LLM i ne oznachayet yego avtomaticheskogo dolgovremennogo sokhraneniya. Syiroj zakhvat, normalizovannyij signal i poluchennaya iz nego svodka imeyut raznyiye identichnosti i roli proiskhozhdeniya. Organ vospriyatiya ili drugoj proveryayemyij sloj mozhet filjtrovatj, obyyedinyatj i szhimatj sobyitiya toljko v ramkakh yavnyikh prav, sokhranyaya svyazj preobrazovanij i zhurnal izvestnyikh poterj; skryityij globaljnyij sbor poljzovateljskogo vvoda iz etogo trebovaniya ne sleduyet.

Yesli [lichnyij FUM-agent](lichnyij-FUM-agent.md) na odnoj mashine yavno prinyal sensornyij signal v dolgovremennuyu pamyatj i imeyet byudzhet khranitj yego, [upravlyayemoye zabyivaniye FUM](upravlyayemoye-zabyivaniye-FUM.md) ne dolzhno avtomaticheski stiratj etu pervichnuyu zapisj radi osvobozhdeniya mesta dlya proizvodnyikh II-struktur. Yeyo mozhno vyivesti iz aktivnogo konteksta i khranitj kholodno s proiskhozhdeniyem, menyaya klass khraneniya i prioritet izvlecheniya, a ne aktivnyij ves mekhanizma. Izvlecheniye takoj zapisi iz arkhiva ne yavlyayetsya vspominaniyem. Resheniye o pervonachaljnom sbore, sroke khraneniya i udalenii podchinyayetsya primenimyim polnomochiyam, soglasiyu subyyektov dannyikh, dostupu, privatnosti i bezopasnosti.

Yesli vneshnij potok slishkom shirok dlya polnogo pryamogo sokhraneniya, [avtomaticheskij organ vospriyatiya FUM](avtomaticheskij-organ-vospriyatiya-FUM.md) mozhet po zaraneye obyyavlennomu pravilu prinyatj kompaktnoye opisaniye kak yedinstvennuyu kanonicheskuyu pervichnuyu zapisj. Ona zasjhisjhayetsya po svoyej roli osnovaniya, khotya tekhnicheski poluchena preobrazovaniyem, i ne vyidayotsya za sokhranyonnyij syiroj potok: proiskhozhdeniye perechislyayet filjtryi, ogranicheniya i poteri. Yesli syiroj zakhvat uzhe byil prinyat kak pervichnaya zapisj, posleduyusjhaya zamena yego svodkoj yavlyayetsya otdeljnyim neobratimyim udaleniyem, a ne obyichnyim szhatiyem ili zabyivaniyem.

Vnutri kompjyutera nablyudayemyij vkhodnoj signal obyichno susjhestvuyet ne kak absolyutno besstrukturnaya massa, a kak cifrovaya zapisj s nekotoryimi granicami i nositelyami strukturyi: fajl, soobsjheniye, kodirovka, razmetka, iskhodnyij kod, TeX-istochnik, log ili sobyitiye interfejsa. [FUM](FUM.md) dolzhen sokhranyatj etu chastichnuyu strukturu kak chastj proiskhozhdeniya signala i ispoljzovatj yeyo kak material dlya [potokovoj samostrukturizacii](potokovaya-samostrukturizaciya-FUM.md).

Dlya vosstanovleniya nepreryivnosti nablyudayemyij fakt vsegda otdelyayetsya ot gipotezyi o yego prichine. Uspeshnyij strogij `read_thread` posle terminaljnogo khoda `failed` s exact-oshibkoj `stream disconnected before completion: error sending request for url (https://chatgpt.com/backend-api/codex/responses)` obrazuyet sostavnoj signal: predyidusjhij host-khod zavershilsya oshibkoj razryiva potoka, a host-putj chteniya dostupen sejchas. Signal ne dokazyivayet, chto mashina byila v gibernacii, chto ona prosnulasj ili chto vsya setj dostupna. Dlya takikh utverzhdenij nuzhnyi otdeljnyiye versionnyiye OS- i setevoj adapteryi; ikh sostav i prava ostayutsya otkryitoj granicej.

Terminaljnostj host-khoda i logicheskaya nepreryivnostj Git-vetki — raznyiye faktyi. V dejstvuyusjhej ruchnoj skheme zaversheniye odnoj pishusjhej sessii ne sozdayot preyemnika: sleduyusjhuyu sessiyu zapuskayet poljzovatelj. Oshibka istoricheskoj [zadachi-prodolzheniya](obyazateljnoye-prodolzheniye-vetki.md) ne dayot polnomochij slepo povtoritj sozdaniye ili vozobnovitj yeyo cherez snyatyij dispetcher; neodnoznachnoye staroye sostoyaniye trebuyet otdeljnogo yavnogo chelovecheskogo vosstanovleniya.

## Svyazannyiye dokumentyi

- [Dostup k vnutrennim sostoyaniyam](../Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Potokovaya samostrukturizaciya FUM](../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md)
- [Mekhanizm sna FUM](mekhanizm-sna-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-08 18:57:20 MSK — Dobavitj ograzhdyonnoye vozobnovleniye posle razryiva svyazi](../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/zapros.md)
- [iskhodnyij zapros 2026-07-31 12:25:42 MSK - Utochnitj sokhraneniye vkhodnoj sensornoj informacii](../Zhurnal/2026-07-31_12-25-42_MSK_utochnitj-sokhraneniye-vkhodnoj-sensornoj-informacii/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK - Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:8ab2041f91219d0d496ae9327e16ef640acc3aa8145485c854c0a6ff2f9d788b -->
<!-- FUM-MD-RECENCY:END -->
