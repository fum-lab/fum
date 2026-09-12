# Integracii FUMA s messendzherami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0049 -->

FUMA dolzhna podderzhivatj integracii s Telegram, MAX, decentralizovannyimi i drugimi messendzherami cherez rasshiryayemyij nabor adapterov. Vozmozhnosti kazhdoj integracii i rezhima uchyotnoj zapisi podtverzhdayutsya otdeljno.

Dlya decentralizovannyikh sistem uchityivayutsya osobennosti federacii ili pryamogo obmena mezhdu uchastnikami. Tochnyiye pervyiye protokolyi i servisyi vyibirayutsya pered ikh realizaciyej. Nalichiye adaptera drugogo servisa ne dokazyivayet sovmestimostj.

## Vyibrannyij Telegram-scenarij

Dlya pervoj realizacii Telegram chelovek vyibral kliyentskij API poljzovateljskoj uchyotnoj zapisi i otdeljno poruchil vedeniye kanalov FUM. Ispoljzuyetsya TDLib cherez sobstvennyij neboljshoj Swift 6 most k tdjson. Bot i Bot API etim vyiborom ne podmenyayut poljzovateljskij rezhim; obsjhaya matrica MAX i decentralizovannyikh messendzherov sokhranyayetsya.

Pervyij ispolnyayemyij rezuljtat — vosproizvodimaya sborka i zagruzka zakreplyonnoj TDLib bez akkaunta, Swift-most i avtonomnyij kontur sostoyanij, soobsjhenij i kanaljnyikh operacij na sinteticheskikh dannyikh. Otkryityiye fiksturyi vklyuchayut tekst, vlozheniya i aljbomyi, editText/Caption/Media, proverku prav i perekhodyi otpravki. Kanaljnaya operaciya imeyet lokaljnyij draft/preview i otdeljnyij sokhranyonnyij intent; vyipolneniye ne sleduyet iz polucheniya vkhodyasjhego teksta. Sozdaniye i udaleniye kanalov ne vkhodyat v pervyij rezuljtat.

Dlya kanala proveryayutsya status sobstvennoj uchyotnoj zapisi i can_post_messages; redaktirovaniye otdeljno proveryayet svojstva soobsjheniya can_be_edited/can_edit_media. Tipyi topic_id/MessageTopic berutsya iz zakreplyonnoj skhemyi. Izmeneniye ili udaleniye vkhodyasjhikh soobsjhenij sokhranyayetsya s razlichiyem ochistki kyesha i okonchateljnogo udaleniya. Podgotovka chernovika lokaljna: setChatDraftMessage ne ispoljzuyetsya kak mestnoye khraneniye.

Polnyij nuzhnyij nabor iskhodnikov TDLib i yeyo sborochnyikh zavisimostej zakreplyayetsya zerkalami, tochnyimi OID, licenziyami i vosproizvodimyim profilem. Zerkalo fum-lab/TDLib uzhe sozdano koordinatorom; eto ne dokazyivayet nalichiye clone/gitlink, zamyikaniya OpenSSL/zlib/gperf ili avtonomnoj sborki. Svojstva MTProto obespechivayet TDLib; SwiftNIO ne vnedryayetsya v yeyo setevoj stek.

Avtorizaciya realjnogo akkaunta, podklyucheniye realjnogo kanala i kazhdaya proverochnaya publikaciya ostayutsya otdeljnoj konkretnoj priyomkoj posle vyibora akkaunta, razreshyonnyikh dejstvij i dannyikh. Telefon, kodyi, api_hash, 2FA, klyuch bazyi i perepiska ne vkhodyat v otkryityiye artefaktyi. Vkhodyasjhiye tekstyi ne poluchayut polnomochiya vladeljca avtomaticheski; peredacha chuzhoj perepiski v AI trebuyet otdeljnogo dopuska i soglasiya zatronutyikh lic.

[Pervyij ispolnyayemyij Telegram-kliyent TDLib](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0222-realizovatj-Swift-kliyent-TDLib-i-sinteticheskij-kontur-kanalov-FUM.md) konkretiziruyet eto utochneniye, sokhranyaya obsjheye trebovaniye messendzherov.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Dlya kazhdogo servisa ili protokola ukazanyi oficialjnyiye interfejsyi, versii i rezhim: bot, poljzovateljskaya uchyotnaya zapisj libo drugoj podtverzhdyonnyij sposob dostupa.
- Matrica yavno pokazyivayet podderzhivayemyiye dejstviya: polucheniye soobsjhenij i istorii, vlozheniya, podgotovka i otpravka otveta, izmeneniya, udaleniye i statusyi dostavki. Otsutstvuyusjhiye funkcii oboznachenyi.
- Sokhranyayetsya identichnostj servisa, uchyotnoj zapisi, besedyi i soobsjheniya. Povtornaya dostavka ne sozdayot dublikatyi; raznyiye soobsjheniya s odinakovyim tekstom ostayutsya raznyimi. Poryadok, vremena i izmeneniya sokhranyayutsya v predelakh dostupnogo protokoljnogo svideteljstva.
- Vkhodyasjheye soobsjheniye poluchayet proiskhozhdeniye i polnomochiya otpravitelya. Ono ne stanovitsya komandoj vladeljca FUMA toljko po nalichiyu teksta.
- Polucheniye, podgotovka otveta i otpravka razdelenyi. Dlya otpravki izvestnyi adresat, soderzhaniye i osnovaniye razresheniya; neodnoznachnyij setevoj iskhod ne vyizyivayet slepuyu povtornuyu otpravku.
- Decentralizovannyiye scenarii uchityivayut identichnostj uchastnikov i uzlov, sinkhronizaciyu istorii, dostupnostj, shifrovaniye i zhiznennyij cikl klyuchej. Skryityiye osobennosti protokola ne zamenyayutsya predpolozheniyem o centraljnom servere.
- Proverenyi otzyiv dostupa, preryivaniye, povtor, ogranicheniya servisa i vosstanovleniye. Privatnaya perepiska i klyuchi ne popadayut v publichnyiye fiksturyi ili zhurnalyi.
- Iskhodniki, otkryityiye testyi i instrukcii nakhodyatsya v FUM. Avtonomnyiye proverki i otdeljnyiye razreshyonnyiye skvoznyiye scenarii soprovozhdayutsya profilem, resheniyem ob optimizacii i ponyatnyim itogom dlya cheloveka.

## Status i granicyi

Status — `🟡`: prinyato i zaplanirovano. [Pervyij shag](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0184-opredelitj-adapteryi-messendzherov.md) opredelyayet matricu, scenarii i granicyi adapterov. Podklyucheniye uchyotnyikh zapisej i otpravka soobsjhenij ne vyipolnyalisj.

## Istochniki trebovanij

- [Vyibor poljzovateljskogo Telegram-kliyenta, kanalov FUM i licenzij](../Zhurnal/2026-09-11_19-46-28_MSK_podgotovitj-realizaciyu-Telegram-TDLib/zapros.md).

- [Telegram, MAX, drugiye messendzheryi i otdeljnoye utochneniye o decentralizovannyikh](../Zhurnal/2026-09-11_01-15-58_MSK_zaplanirovatj-integracii-messendzherov/zapros.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:52:55 MSK -->
<!-- content-sha256: sha256:6ea493e7869c2e605de133338f0aaf58b06209bff62edefe618445e932cb8554 -->
<!-- FUM-MD-RECENCY:END -->
