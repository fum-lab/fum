+++
schema_version = 1
card_id = "FUM-STEP-0222"
status = "active"
+++
# Realizovatj Swift-kliyent TDLib i sinteticheskij kontur kanalov FUM

## Zadacha

Realizovatj pervyij poljzovateljskij Telegram-kliyent FUMA na Swift 6 i TDLib: neboljshoj C-most k tdjson, uporyadochennyij priyom obnovlenij, modelj avtorizacii i soobsjhenij, mestnyiye draft/preview i proveryayemyij kontur vedeniya kanalov FUM. Pervyij rezuljtat realjno sobirayet i zagruzhayet zakreplyonnuyu TDLib bez akkaunta; prikladnoye povedeniye vosproizvoditsya na sinteticheskikh sostoyaniyakh i soobsjheniyakh cherez tot zhe adapter i kod razreshyonnyikh operacij.

Vyibran odin sborochnyij profilj macOS arm64; tochnyiye macOS, Xcode/SDK, Swift 6, CMake, kompilyator C++ i zavisimosti zakreplyayutsya v otkryitom pasporte realizacii. Podderzhka ostaljnyikh platform ne vyivoditsya iz etogo profilya. Setevyim stekom Telegram upravlyayet TDLib; vnedreniye SwiftNIO v MTProto ne vkhodit v rabotu.

## Pochemu sejchas

Chelovek pryamo zapustil realizaciyu Telegram API, vyibral poljzovateljskuyu uchyotnuyu zapisj, dobavil vedeniye kanalov FUM i potreboval zerkalo TDLib v fum-lab. Obsjhaya REQ0049 i STEP0184 uzhe sokhranyayut messendzheryi i granicyi polnomochij, no ne postavlyayut ispolnyayemyij Telegram-kliyent. Koordinator sozdal publichnyij fork TDLib; clone/gitlink i avtonomnaya sborka yesjhyo ne vyipolnenyi.

## Kriterii zaversheniya

- Iskhodniki sobstvennogo Swift 6 mosta, kliyentskogo yadra, avtonomnogo zapuska, testov, otkryityikh fikstur i profilya nakhodyatsya v FUM. Chelovek vosproizvodit sborku i sinteticheskij scenarij po instrukcii iz chistogo checkout s obyyavlennyim komplektom zavisimostej. Uspeshnyij zapusk ne trebuyet Telegram-akkaunta, telefonnogo nomera, api_id/api_hash, bot-token ili seti Telegram.
- TDLib zakreplena tochnyim opublikovannyim commit d1085f9cebc5a62379991ae1652673954f229c1f iz forka fum-lab/TDLib s proiskhozhdeniyem tdlib/td i BSL-1.0. Versiya proyekta 1.8.67 iz CMakeLists.txt ne vyidayotsya za release tag i ne smeshivayetsya s minimumom CMake 3.10. Dlya vyibrannoj sborki perechislenyi C++17, OpenSSL, zlib, gperf, neobkhodimyiye instrumentyi i ikh tranzitivnoye zamyikaniye; PHP vklyuchayetsya toljko pri vyibrannom scenarii, kotoromu on trebuyetsya. Vse neobkhodimyiye novyiye iskhodnyiye zavisimosti poluchayut zerkala i tochnyiye opublikovannyiye OID shtatnyim mekhanizmom FUM, bez plavayusjhego master. Iskhodnaya baza forka i fakt nalichiya odnogo zerkala ne obyyavlyayutsya polnyim avtonomnyim komplektom.
- Otkryityij manifest soderzhit mode/gitlink/OID, licenzii, tochnyiye khyeshi td_api.tl, td_json_client.h i sborochnogo profilya, versii instrumentov, parametryi linkovki i realjnyiye vkhodyi SDK/bootstrap. Avtonomnyij povtor sborki vyipolnyayetsya na zayavlennom polnom komplekte bez skryitogo fetch/download; nedostupnyiye neobkhodimyiye bajtyi ili prava dostavki oboznachayutsya konkretnyim prepyatstviyem, a ne isklyuchayutsya iz zamyikaniya.
- Sborochnyij smoke dejstviteljno zagruzhayet biblioteku i ispoljzuyet sovremennyiye td_create_client_id/td_send/td_receive dlya vyibrannogo po zakreplyonnoj skheme neavtorizacionnogo zaprosa ili sostoyaniya. Pustoj Swift-mok ne schitayetsya etim rezuljtatom. Legacy td_json_client_* ne ispoljzuyetsya; akkaunt i otpravka v Telegram dlya smoke ne nuzhnyi.
- Vo vsyom processe rabotayet odin vyidelennyij receive-potok dlya vsekh kliyentov s polozhiteljnyim konechnyim timeout. Vozvrasjhyonnyiye C-bajtyi kopiruyutsya do daljnejshego ispoljzovaniya API; zatem peredayutsya v Swift actor s sokhraneniyem poryadka. @client_id razdelyayet kliyentov, @extra svyazyivayet zapros i otvet, no ne dayot idempotentnosti. Ogranichennaya ocheredj imeyet proveryayemoye obratnoye davleniye; uzhe prinyatyiye sobyitiya ne vyibrasyivayutsya molcha, peregruzka imeyet yavnyij iskhod i sokhranyayet nezavershyonnoye sostoyaniye. Bezdejstviye ne sozdayot busy loop.
- Avtorizaciya realizovana kak konechnaya modelj updateAuthorizationState: parametryi TDLib, telefon i kod, email i kod, 2FA, QR, Ready, zakryitiye i otzyiv dostupa. WaitRegistration i WaitPremiumPurchase trebuyut otdeljnogo dejstviya i ne prokhodyat avtomaticheski. Prikladnyiye operacii razreshayutsya toljko v Ready. api_id/api_hash prilozheniya, telefon, odnorazovyiye kodyi i klyuch bazyi imeyut razdeljnyiye privatnyiye vkhodyi; bot-token ne primenyayetsya. Baza i fajlyi imeyut nepustyiye privatnyiye katalogi i zasjhisjhyonnyij klyuch. Obyichnyij vyikhod — close s ozhidaniyem Closed, ne logOut/destroy.
- Realizovanyi loadChats s obnovleniyami i chteniye istorii stranicami ne boleye 100, vklyuchaya only_local. Identichnostj soobsjheniya zadayotsya servisom, akkauntom, chat_id i message_id; sovpadeniye teksta ne obyyedinyayet raznyiye soobsjheniya. Povtornyiye obnovleniya, dostupnyij poryadok, pravki i udaleniya sokhranyayutsya; ochistka kyesha otdelena ot okonchateljnogo udaleniya.
- Lokaljnyiye draft/preview sokhranyayut tochnogo adresata, tekst, dannyiye vlozhenij ili aljboma, celj i osnovaniye razresheniya. Podgotovka ne vyizyivayet setChatDraftMessage i ne otpravlyayet zapros. Konechnaya sinteticheskaya matrica cherez produkcionnyij serializator okhvatyivayet sendMessage s tekstom i vlozheniyem, aljbom, editText, editCaption i editMedia; dlya kazhdogo predusmotrenyi dopustimyiye i otkaznyiye prava, pustyiye/nevernyiye dannyiye i ozhidayemyij tipizirovannyij zapros libo otkaz do otpravki.
- Dlya kanala proveryayutsya status sobstvennoj uchyotnoj zapisi i can_post_messages; pered redaktirovaniyem ispoljzuyutsya getMessageProperties, can_be_edited i can_edit_media v primenimoj operacii. Nevernyij akkaunt/kanal, otzyiv prav i nesovmestimoye dejstviye otklonyayutsya. topic_id i MessageTopic proveryayutsya po zakreplyonnoj td_api.tl; nalichiye etikh polej ne razreshayet sozdaniye temyi, kanala ili naznacheniye prav. Zakrepleniye soobsjhenij i dejstviya nad temami, ne obyyavlennyiye v matrice pervogo sreza, vozvrasjhayut yavnyij unsupported, bez syirogo universaljnogo escape-hatch.
- Do send sokhranyon dolgovechnyij intent s identichnostjyu akkaunta/kanala, tochnyim soderzhimyim, vlozheniyami, razresheniyem i sobstvennoj identichnostjyu popyitki. Sokhranyayetsya perekhod temporary id → updateMessageSendSucceeded s old_id/new_id libo updateMessageSendFailed; nezavershyonnyij iskhod ne obyyavlyayetsya dostavlennyim. sending_id i @extra ne schitayutsya ustojchivyim klyuchom idempotentnosti. Posle perezapuska sostoyaniye TDLib i istoriya ispoljzuyutsya dlya sverki; yesli iskhod ne dokazan, sozdayotsya yavnaya neobkhodimostj razbora bez novogo slepogo send. Exactly-once ne obesjhayetsya.
- Avtonomnyiye RED/GREEN proveryayut poryadok i kopirovaniye C-bajtov, neskoljkikh kliyentov, korrelyaciyu, vse obyyavlennyiye sostoyaniya avtorizacii, otzyiv dostupa, ocheredj, otmenu, povtoryi, pravki/udaleniya, prava kanala, vse shestj grupp iskhodyasjhikh operacij, pending/success/failure, razryiv mezhdu otpravkoj i sokhraneniyem rezuljtata, restart i close→Closed. Uspekh mock-provajdera ne zamenyayet realjnuyu sborku/zagruzku biblioteki; obe granicyi imeyut otdeljnyiye svideteljstva.
- Profilj izmeryayet idle CPU i RSS realjnogo mosta bez akkaunta, razmer/pik ocheredi i pamyatj, p50/p95 sinteticheskoj obrabotki i otmenyi, povtor posle sokhraneniya sostoyaniya. Zapisanyi obyyom fikstur, versii, khyeshi, granicyi izmerenij i resheniye ob optimizacii. Setevaya zaderzhka Telegram i povedeniye zhivogo akkaunta etim profilem ne podtverzhdayutsya.
- Instrukciya razlichayet polnostjyu proverennyiye avtonomnyiye vozmozhnosti i posleduyusjhuyu realjnuyu priyomku. Live-podklyucheniye trebuyet konkretnogo akkaunta, app api_id/api_hash, zasjhisjhyonnogo khraneniya, vyibrannogo kanala i proverennyikh prav. Do kazhdoj vneshnej proverki chelovek zadayot tochnoye dejstviye, adresata i soderzhaniye, vklyuchaya vlozheniya; realizaciya obsjhego kliyenta ne yavlyayetsya razresheniyem proizvoljnoj publikacii. Perepiska i sekretyi ne popadayut v Git, publichnyiye profili ili fiksturyi.
- Sleduyusjhij ogranichennyij skvoznoj etap proveryayet na otdeljno razreshyonnom akkaunte i kanale chteniye, tekstovuyu otpravku, vlozheniye, aljbom i editText/Caption/Media s nablyudayemoj dostavkoj, pravami i vosstanovleniyem. Do etogo vse eti operacii pomechenyi proverennyimi toljko sinteticheski. Trebovaniya Telegram k read-state, sponsored messages i obrabotke poljzovateljskogo kontenta fiksiruyutsya kak usloviya budusjhego polnogo kliyenta; pervaya tekhnicheskaya postavka ne obyyavlyayet ikh vse vyipolnennyimi. Peredacha chuzhoj perepiski modeli ne proiskhodit avtomaticheski i trebuyet otdeljnogo dopuska i soglasiya zatronutyikh lic.

## Svyazannyiye rabotyi

- [Integracii FUMA s messendzherami](../../Trebovaniya/🟡-integracii-FUMA-s-messendzherami.md) — susjhestvuyusjhaya REQ0049, rasshiryayemyij obsjhij kontrakt.
- [Matrica adapterov messendzherov](🟡-FUM-STEP-0184-opredelitj-adapteryi-messendzherov.md) — susjhestvuyusjhij obsjhij plan; novaya realizaciya ne podmenyayet ostaljnyiye servisyi.
- [Proiskhozhdeniye i obrabotka soobsjhenij](✅-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md) — opora dlya razdeleniya identichnosti otpravitelya i polnomochij; Telegram-tekst ne stanovitsya chelovecheskoj komandoj vladeljca po odnomu sovpadeniyu soderzhimogo.

## Licenzii i proiskhozhdeniye polnogo komplekta

Pozdnyaya komanda o licenziyakh trebuyet prochitatj realjnyiye LICENSE/NOTICE zakreplyonnoj TDLib i kazhdogo elementa neobkhodimogo sborochnogo i runtime-zamyikaniya. Pasport svyazyivayet tochnyiye OID i khyeshi licenzionnyikh fajlov, avtorstvo, obyazateljnyiye uvedomleniya i usloviya peredachi iskhodnikov libo binarnyikh rezuljtatov. Otsutstvuyusjhij NOTICE otmechayetsya kak proverennoye otsutstviye, a ne zamenyayetsya vyimyishlennyim fajlom. CC0 sobstvennogo koda FUM ne menyayet licenzii TDLib i drugikh vneshnikh komponentov. Licenzionnoye ogranicheniye ne obkhoditsya isklyucheniyem nuzhnoj zavisimosti iz polnogo komplekta.

## Istochniki

- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_19-46-28_MSK_podgotovitj-realizaciyu-Telegram-TDLib/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:52:55 MSK -->
<!-- content-sha256: sha256:37e8997e7e46994db83c90120eb0ca62ff4e8ea4c2aa95208cb2aa5e93c3ddd0 -->
<!-- FUM-MD-RECENCY:END -->
