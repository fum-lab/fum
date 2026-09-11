# Zapusk FUMA na celevyikh platformakh

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0046 -->

Proyekt FUMA dolzhen predostavlyatj zapuskayemoye prilozheniye na macOS, Linux, Windows, iOS, Android, Tizen, watchOS, Wear OS, tvOS, Android TV, visionOS, Meta Horizon OS, Android XR, PlayStation i Xbox, a takzhe veb-versiyu dlya Safari, Chrome i Firefox.

Eto trebovaniye k postavlyayemomu produktu. Podgotovlennoye okruzheniye razrabotki, sborka obsjhego paketa ili prilozheniye na sosednej platforme sami po sebe ne podtverzhdayut zapusk FUMA na celevoj platforme. Perechenj sokhranyayetsya polnostjyu; pokoleniya ustrojstv, versii OS i obyyom pervogo rabochego scenariya utochnyayutsya v matrice sovmestimosti.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [graficheskimi interfejsami FUMA](🟡-graficheskiye-interfejsyi-FUMA.md) — utochnyayut graficheskiye puti prilozheniya.

## Kriterii proverki

- Dlya kazhdoj iz 15 platform ili semejstv i kazhdogo iz tryokh brauzerov ukazan tochnyij profilj: ustrojstvo ili emulyator, pokoleniye, OS, arkhitektura, sreda sborki, sposob ustanovki i zapuska.
- FUMA vyipolnyayet soglasovannyij poleznyij scenarij. Pustoj ekran i zaglushka ne schitayutsya yego vyipolneniyem; dopustimostj prilozheniya-kompanjona ili udalyonnogo ispolneniya opredelyayetsya yavno.
- Razdeljno podtverzhdayutsya sborka, ustanovka, zapusk, prokhozhdeniye scenariya i publichnaya postavka. Proverka na simulyatore ne pripisyivayetsya fizicheskomu ustrojstvu.
- Sobstvennyiye iskhodniki, konfiguracii, otkryityiye testyi, profili i instrukcii vosproizvedeniya nakhodyatsya v tematicheskoj oblasti monorepozitoriya FUM. Vneshniye zavisimosti i nedostupnyiye publichno SDK oboznachenyi otdeljno.
- Dlya kazhdoj platformyi otrazhenyi vozmozhnosti, razresheniya i ogranicheniya, vklyuchaya fonovyiye processyi, khraneniye i nablyudeniye sredyi. Otsutstvuyusjhaya vozmozhnostj vidna cheloveku.
- Avtomatizaciya iz chistogo klona gotovit primenimoye okruzheniye, vyipolnyayet sborku i proverki i sokhranyayet svideteljstva tochnogo kommita i platformyi. Neobkhodimyiye vneshniye prava ili oborudovaniye imeyut yavnyij status.
- Obsjhij kod i platformennyiye adapteryi prokhodyat primenimyiye testyi, profilj i resheniye ob optimizacii. Sovmestimostj formatov dannyikh proveryayetsya mezhdu platformami.

Dlya Web otdeljno fiksiruyutsya OS, versiya brauzera, sposob razmesjheniya prilozheniya i ogranicheniya sredyi. Rabota v odnom brauzere ne podtverzhdayet ostaljnyiye; proveryayemyij rezuljtat — poleznyij scenarij FUMA v brauzere.

## Status i granicyi

Trebovaniye ne rasshiryayet avtomaticheski specialjnyiye vozmozhnosti macOS na ostaljnyiye platformyi.

Status — `🟡`: trebovaniye prinyato i zaplanirovano. Polnaya realizaciya yesjhyo ne podtverzhdena. Pervyij shag — [opredelitj platformennyiye sborki i pervyij scenarij FUMA](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).

Swift sokhranyayetsya kak iskhodnoye tekhnologicheskoye napravleniye. Prigodnostj konkretnyikh paketov, interfejsnyikh tekhnologij i sposobov upakovki proveryayetsya po platformam; yedinaya tekhnologiya interfejsa zaraneye ne obyyavlyayetsya dostupnoj vezde. Nedostupnyij SDK, ogranicheniye postavki ili zaversheniye podderzhki fiksiruyutsya s osnovaniyem i predlagayemyim resheniyem, bez molchalivogo udaleniya celi.

Microsoft Windows Holographic isklyuchena iz celej podderzhki po posleduyusjhemu pryamomu resheniyu poljzovatelya. Iskhodnyij perechenj i utochneniye sokhranenyi v Zhurnale.

## Istochniki trebovanij

- [Komanda otmenyi Windows Holographic s sosednimi otvetami](../Zhurnal/2026-09-11_02-34-29_MSK_vosstanovitj-kontekst-platformennogo-resheniya-i-SwiftNIO/materialyi/istochniki/kontekst-reshenij/kontekst-otmenyi-Windows-Holographic.md).

- [Perechenj platform i posleduyusjheye dobavleniye PlayStation i Xbox](../Zhurnal/2026-09-11_01-03-38_MSK_zaplanirovatj-platformyi-i-grafiku-FUMA/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:37:53 MSK -->
<!-- content-sha256: sha256:7f71d74574a83810eef0785b9bc0fb703d4e92164c702db7b8dec2aa394cc9a2 -->
<!-- FUM-MD-RECENCY:END -->
