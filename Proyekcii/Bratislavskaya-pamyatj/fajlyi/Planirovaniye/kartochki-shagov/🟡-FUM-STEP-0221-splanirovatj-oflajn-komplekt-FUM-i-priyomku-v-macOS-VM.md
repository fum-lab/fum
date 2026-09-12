+++
schema_version = 1
card_id = "FUM-STEP-0221"
status = "active"
+++
# Splanirovatj oflajn-komplekt FUM i priyomku v macOS VM

## Zadacha

Podgotovitj konechnyij plan perenosimogo oflajn-komplekta FUM i yego pervoj skvoznoj priyomki v macOS VM s otklyuchyonnyim internetom. Rezuljtat — matrica funkcij, manifest vsekh neobkhodimyikh bajtov i vkhodov, programma proverki v goste i ogranichennaya sleduyusjhaya ispolnyayemaya postanovka.

## Pochemu sejchas

Poljzovatelj potreboval polnostjyu avtonomnuyu rabotu repozitoriya FUM bez interneta i ukazal budusjheye okruzheniye macOS VM. Otdeljnyiye avtonomnyiye testyi, lokaljnyiye operatoryi i gitlink zavisimostej uzhe poleznyi, no ne dokazyivayut perenosimostj vsego komplekta s interfejsom, sborkoj, dannyimi i modeljnyimi funkciyami.

## Kriterii zaversheniya

- Dlya vyibrannoj revizii kazhdogo vneshnego komponenta i vsekh nuzhnyikh tranzitivnyikh vkhodov prochitanyi realjnyiye LICENSE/NOTICE, otrazhenyi obyazannosti sokhraneniya uvedomlenij, usloviya sborki i rasprostraneniya iskhodnikov/binarnikov. Sobstvennyij kod FUM pod CC0 ne izmenyayet vneshnyuyu licenziyu. Konkretnaya Torrent-biblioteka vyibirayetsya po oficialjnyim istochnikam otdeljno; do zaversheniya vyibora nazvaniye ne vyidayotsya za prinyatoye resheniye.
- Dlya neprigodnyikh Git binarnyikh obyyektov sproyektirovanyi khraneniye v fajlovoj sisteme vne Git i rasprostraneniye cherez Torrent: ustojchivyij opisatelj, versiya, razmer, khyesh polnogo fajla, svyazj chastej, proiskhozhdeniye, dopustimostj rasprostraneniya i proverka poluchennyikh bajtov. Razdeljno fiksiruyutsya dostupnostj razdachi, lokaljnaya polnota i fakticheskoye vklyucheniye v oflajn-komplekt. Predusmotrenyi nepolnyij obyyekt, povrezhdyonnaya chastj, smena versii, nedostupnaya razdacha i povtor posle preryivaniya. Privatnyiye runtime-dannyiye i klyuchi ne stanovyatsya razdachej; ogranichennyiye licenziyej neobkhodimyiye obyyektyi poluchayut yavnyij dopustimyij marshrut libo prepyatstviye. Sam Torrent-kliyent i razdachi v etom planovom etape ne zapuskayutsya.
- Vyibran pervyij tochnyij profilj host/guest, arkhitekturyi, FUM OID, resursov i poleznogo scenariya. Dlya kazhdogo komponenta pamyati, Zhurnala, interpretatora, interfejsa, sborki i proverok zafiksirovanyi fakticheskaya gotovnostj i nezavisimyiye vkhodyi. Otsutstvuyusjhaya funkciya ne zamenyayetsya pustyim interfejsom ili sokhranyonnyim chuzhim vyivodom.
- Sostavlen konechnyij manifest perenosimyikh materialov i vsekh pryamyikh/tranzitivnyikh zavisimostej s realjnyimi bajtami, versiyami, khyeshami, razmerom, licenziyej, sposobom dostavki i potrebitelyami. Nepoluchennyiye elementyi otmechenyi yavno; URLs/gitlinks ne schitayutsya dostavkoj. Bootstrap/SDK i ogranichennyiye po rasprostraneniyu materialyi ostayutsya obyazateljnyimi strokami s resheniyem libo prepyatstviyem.
- Dlya modeljnyikh funkcij opredelenyi lokaljnyij ispolnitelj, neobkhodimyiye parametryi i dannyiye, resursyi i nablyudayemyij scenarij; novyiye modeli i zavisimosti ne vyibirayutsya bez obosnovaniya. Dlya determinirovannyikh operatorov LLM ne vvoditsya kak iskusstvennaya predposyilka. Otkryityiye model-only/remote profili ne vyidayutsya za dostupnyij oflajn runtime.
- Podgotovka komplekta onlajn otdelena ot avtonomnogo perenosa, ustanovki i rabotyi. Sostavlena proveryayemaya karta setevyikh perekhodov, instrumentov rezolyucii i kyeshej; runtime ne obrasjhayetsya k istochnikam za nedostayusjhimi bajtami. Razreshyonnaya lokaljnaya proverka zavisimostej pereispoljzuyetsya; setevoj init ne popadayet v oflajn-stadiyu.
- Po susjhestvuyusjhej postanovke macOS VM i podgotovke macOS opredelyon bezopasnyij gostevoj stend: izolyaciya toljko VM, tochnaya identichnostj gostya, ogranichennyij kanal perenosa i otsutstviye dostupa k neuchtyonnyim host-dannyim. Zhiznennyij cikl VM ne realizuyetsya vtoryim dvizhkom; poka backend ne gotov, eto otkryitaya zavisimostj sleduyusjhego ispolneniya.
- Programma budusjhej priyomki vyipolnyayet v goste chteniye/izmeneniye sobstvennoj pamyati i Zhurnala, interfejsnyij scenarij, operatornoye ispolneniye, zayavlennuyu lokaljnuyu modeljnuyu funkciyu, sborku i proverki. Podtverzhdayutsya sokhraneniye rezuljtata, preryivaniye i prodolzheniye drugim processom; setevyiye funkcii dayut ponyatnuyu nedostupnostj i sokhranyayut nezavershyonnoye namereniye.
- Predusmotrenyi RED/GREEN dlya otsutstvuyusjhego i podmenyonnogo fajla/zavisimosti/modeli, skryitogo fetch, nedostayusjhego SDK, neuchtyonnogo kyesha i prevyisheniya byudzheta. Povtor na chistom gostevom sostoyanii ne opirayetsya na predyidusjhiye setevyiye zagruzki. Profili perenosa, ustanovki, rabotyi, sborki/proverok i vosstanovleniya imeyut otdeljnyiye granicyi vremeni, pamyati i diska.
- Itogovyij dokument soderzhit konechnyij sleduyusjhij srez, vse otkryityiye usloviya s ozhidayemyimi svideteljstvami i otdeljnyiye statusyi podgotovki, perenosa i nastoyasjhej oflajn-priyomki. Otsutstviye dostupnogo SDK/modeli ne prevrasjhayetsya v molchalivoye isklyucheniye. Tekusjhaya postavka — plan, bez sozdaniya VM, otklyucheniya seti khosta, clone/build/native i rasshireniya dvukh detektorov vnimaniya.

## Istochniki

- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_19-12-07_MSK_prinyatj-plan-avtonomnogo-komplekta-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:45:10 MSK -->
<!-- content-sha256: sha256:fa092f618933a84b1064a047d5cc549bcdeb47d4e1a43f6ff84e83c7b793c741 -->
<!-- FUM-MD-RECENCY:END -->
