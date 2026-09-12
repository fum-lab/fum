+++
schema_version = 1
card_id = "FUM-STEP-0184"
status = "active"
+++
# Opredelitj adapteryi messendzherov

## Zadacha

Opredelitj rasshiryayemyiye integracii FUMA s Telegram, MAX, decentralizovannyimi i drugimi messendzherami, s proveryayemyimi scenariyami i proiskhozhdeniyem soobsjhenij.

## Pochemu sejchas

Poljzovatelj poruchil predusmotretj podderzhku messendzherov i otdeljno dobavil decentralizovannyiye. Obsjhij setevoj adapter ne podtverzhdayet rabotu besed, uchyotnyikh zapisej i dostavki soobsjhenij.

## Utochneniye pervogo Telegram-adaptera

Dlya Telegram uzhe vyibran kliyent poljzovateljskoj uchyotnoj zapisi na TDLib, vklyuchaya vedeniye kanalov FUM. [Otdeljnyij shag realizacii](🟡-FUM-STEP-0222-realizovatj-Swift-kliyent-TDLib-i-sinteticheskij-kontur-kanalov-FUM.md) postavlyayet realjnuyu sborku/zagruzku tdjson bez akkaunta i sinteticheskuyu proverku vyibrannyikh kanaljnyikh operacij. Etot vyibor snimayet vopros bot ili poljzovatelj toljko dlya pervogo Telegram-sreza; MAX i decentralizovannyiye sistemyi sokhranyayut sobstvennyij vyibor i kriterii obsjhej matricyi. Priyomka odnogo adaptera ne zavershayet nastoyasjhij STEP0184.

## Kriterii zaversheniya

- Sostavlena matrica Telegram, MAX i vyibrannyikh pervyikh decentralizovannyikh protokolov. Ukazanyi oficialjnyiye sposobyi dostupa, versii, roli uchyotnyikh zapisej i dostupnyiye dejstviya.
- Dlya pervogo Telegram-adaptera sokhranyon vyibor poljzovateljskoj uchyotnoj zapisi, TDLib i kanalov FUM. Dlya ostaljnyikh servisov do realizacii utochnenyi vliyayusjhiye na rezuljtat rezhimyi uchyotnyikh zapisej, pervyiye decentralizovannyiye sistemyi i poleznyiye scenarii vzaimodejstviya s FUMA.
- Kontrakt sokhranyayet identichnostj, proiskhozhdeniye, dostupnyij poryadok, povtoryi, istoriyu i izmeneniya. Otdeljno opredelenyi polnomochiya vkhodyasjhikh komand i razresheniye iskhodyasjhikh soobsjhenij.
- Dlya federativnogo i pryamogo obmena opisanyi sinkhronizaciya, klyuchi, dostupnostj i vosstanovleniye. Svojstva konfidencialjnosti zayavlyayutsya toljko v proverennoj granice.
- Podgotovlenyi avtonomnyiye fiksturyi i scenarii otkaza, povtornoj dostavki, neodnoznachnogo iskhoda otpravki i otzyiva dostupa. Realjnyiye uchyotnyiye dannyiye ostayutsya vne repozitoriya.
- Dlya kazhdogo pervogo adaptera vyidelen ogranichennyij shag realizacii s RED/GREEN, razreshyonnyim skvoznyim scenariyem, profilem i kriteriyem priyomki. Chelovek poluchayet ponyatnuyu instrukciyu podklyucheniya i diagnostiki; nepodderzhivayemyiye dejstviya oboznachenyi.

## Svyazannyiye rabotyi

- [Trebovaniye integracij messendzherov](../../Trebovaniya/🟡-integracii-FUMA-s-messendzherami.md).
- [Setevyiye adapteryi](🟡-FUM-STEP-0183-opredelitj-adapteryi-decentralizovannyikh-setej.md).
- [Platformennyiye sborki FUMA](🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).
- [Proiskhozhdeniye i obrabotka poljzovateljskikh soobsjhenij](✅-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md).

## Istochniki

- [Vyibor poljzovateljskogo Telegram-kliyenta, kanalov FUM i licenzij](../../Zhurnal/2026-09-11_19-46-28_MSK_podgotovitj-realizaciyu-Telegram-TDLib/zapros.md).

- [Iskhodnyiye komandyi i soderzhateljnyiye otvetyi](../../Zhurnal/2026-09-11_01-15-58_MSK_zaplanirovatj-integracii-messendzherov/zapros.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:52:55 MSK -->
<!-- content-sha256: sha256:33329784a91ba5fc6c4feb2abe13c7a08c3cc23046c13c63851ffdabde7c0333 -->
<!-- FUM-MD-RECENCY:END -->
