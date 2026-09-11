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

- [Komanda otmenyi Windows Holographic s sosednimi otvetami](https://github.com/fum-lab/fum/blob/5c9806560fb9b52112ff8a7bc11888a1bb71f7aa/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_02-34-29_MSK_%D0%B2%D0%BE%D1%81%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%B8%D1%82%D1%8C-%D0%BA%D0%BE%D0%BD%D1%82%D0%B5%D0%BA%D1%81%D1%82-%D0%BF%D0%BB%D0%B0%D1%82%D1%84%D0%BE%D1%80%D0%BC%D0%B5%D0%BD%D0%BD%D0%BE%D0%B3%D0%BE-%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D1%8F-%D0%B8-SwiftNIO/%D0%BC%D0%B0%D1%82%D0%B5%D1%80%D0%B8%D0%B0%D0%BB%D1%8B/%D0%B8%D1%81%D1%82%D0%BE%D1%87%D0%BD%D0%B8%D0%BA%D0%B8/%D0%BA%D0%BE%D0%BD%D1%82%D0%B5%D0%BA%D1%81%D1%82-%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B9/%D0%BA%D0%BE%D0%BD%D1%82%D0%B5%D0%BA%D1%81%D1%82-%D0%BE%D1%82%D0%BC%D0%B5%D0%BD%D1%8B-Windows-Holographic.md).

- [Perechenj platform i posleduyusjheye dobavleniye PlayStation i Xbox](https://github.com/fum-lab/fum/blob/5c9806560fb9b52112ff8a7bc11888a1bb71f7aa/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_01-03-38_MSK_%D0%B7%D0%B0%D0%BF%D0%BB%D0%B0%D0%BD%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%BF%D0%BB%D0%B0%D1%82%D1%84%D0%BE%D1%80%D0%BC%D1%8B-%D0%B8-%D0%B3%D1%80%D0%B0%D1%84%D0%B8%D0%BA%D1%83-FUMA/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:58:13 MSK -->
<!-- content-sha256: sha256:58b2d4ce7d56e87ad2f3c89b0d4c6dc425bcfb68429c2620322cc05ce8175598 -->
<!-- FUM-MD-RECENCY:END -->
