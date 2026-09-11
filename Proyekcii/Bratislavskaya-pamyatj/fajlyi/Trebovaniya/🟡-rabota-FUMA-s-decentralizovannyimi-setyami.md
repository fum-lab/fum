# Rabota FUMA s decentralizovannyimi setyami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0048 -->

FUMA dolzhna predusmatrivatj rabotu s Torrent, Tor, I2P, Bitcoin i podklyucheniye drugikh setej cherez rasshiryayemyiye adapteryi. Vozmozhnosti i rezuljtat kazhdoj integracii proveryayutsya otdeljno.

Seti ne schitayutsya vzaimozamenyayemyimi: obsjhij interfejs sokhranyayet osobennosti peredachi dannyikh, svyazi i operacij s reyestrom. Slovo «drugiye» trebuyet rasshiryayemosti, no ne podtverzhdayet podderzhku proizvoljnoj seti zaraneye. Dlya oboznacheniya Torrent iskhodnyim kandidatom yavlyayetsya BitTorrent; tochnyij protokol i scenarij zakreplyayutsya do realizacii.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Dlya kazhdoj nazvannoj seti opredelenyi konkretnyiye operacii, protokol i versii, rezhim ispoljzovaniya susjhestvuyusjhego uzla libo upravlyayemogo processa, sovmestimostj s platformami FUMA.
- Adapter soobsjhayet vozmozhnosti, sostoyaniye, rezuljtat, oshibki i ogranicheniya. Povtor, otmena i vosstanovleniye imeyut proverennyij kontrakt.
- Priyom dannyikh, publikaciya ili razdacha, upravleniye uzlom, podpisaniye i otpravka tranzakcij razlichayutsya. Operaciya ispoljzuyet naznachennyiye prava; samo podklyucheniye ne razreshayet publikaciyu privatnoj pamyati ili rasporyazheniye sredstvami.
- Vneshniye dannyiye proveryayutsya pered vklyucheniyem v pamyatj. Proiskhozhdeniye i rezuljtat operacii sokhranyayutsya v Zhurnale bez sekretov.
- Proverenyi nedostupnostj uzlov, povrezhdyonnyiye dannyiye, razryiv svyazi, povtor, vosstanovleniye i ogranicheniya resursov. Zayavlennyiye svojstva privatnosti proveryayutsya otdeljno.
- Realizaciya i otkryityiye fiksturyi nakhodyatsya v FUM. Adresnyiye testyi rabotayut bez vneshnej seti po umolchaniyu; zhivaya sovmestimostj podtverzhdayetsya otdeljnyim scenariyem, profilem i resheniyem ob optimizacii.
- Podklyucheniye novogo adaptera ne trebuyet podmenyatj semantiku uzhe podderzhivayemyikh setej; chelovek vidit podderzhivayemyiye dejstviya i sposobyi zapuska.

## Status i granicyi

Status — `🟡`: prinyato i zaplanirovano. Pervoye dejstviye — [opredelitj adapteryi i scenarii](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0183-opredelitj-adapteryi-decentralizovannyikh-setej.md). Rabota integracij poka ne podtverzhdena. Dlya Bitcoin obyyom operacij zadayotsya yavno; finansovyiye dejstviya ne vyivodyatsya iz obsjhego trebovaniya sovmestimosti.

## Istochniki trebovanij

- [Porucheniye predusmotretj decentralizovannyiye seti](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:14:07 MSK -->
<!-- content-sha256: sha256:007940abc8193e3811c76bf91eb30060fd7e27d479c74fd4097e0a4011531b02 -->
<!-- FUM-MD-RECENCY:END -->
