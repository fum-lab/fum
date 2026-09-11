# Integracii FUMA s messendzherami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0049 -->

FUMA dolzhna podderzhivatj integracii s Telegram, MAX, decentralizovannyimi i drugimi messendzherami cherez rasshiryayemyij nabor adapterov. Vozmozhnosti kazhdoj integracii i rezhima uchyotnoj zapisi podtverzhdayutsya otdeljno.

Dlya decentralizovannyikh sistem uchityivayutsya osobennosti federacii ili pryamogo obmena mezhdu uchastnikami. Tochnyiye pervyiye protokolyi i servisyi vyibirayutsya pered ikh realizaciyej. Nalichiye adaptera drugogo servisa ne dokazyivayet sovmestimostj.

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

- [Telegram, MAX, drugiye messendzheryi i otdeljnoye utochneniye o decentralizovannyikh](../Zhurnal/2026-09-11_01-15-58_MSK_zaplanirovatj-integracii-messendzherov/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:16:22 MSK -->
<!-- content-sha256: sha256:bf515800d5652c794d299b31c6f527fa68b4b370fd8987db23fa544d4339c842 -->
<!-- FUM-MD-RECENCY:END -->
