# Otchyot 2026-07-17 09:18:01 MSK - Dobavitj kartochku syiroj zapisi sobyitij vvoda

V [reyestr trebovanij FUM](../../Trebovaniya/README.md) dobavlena kartochka o maksimaljno tochnom i maksimaljno syirom sokhranenii sobyitij klaviaturyi, trekpada, myishi, stilusa, graficheskogo plansheta i drugikh graficheskikh ustrojstv vvoda. Trebovaniye otdelyayet neizmenyayemuyu iskhodnuyu trassu ot proizvodnyikh zhestov, komand i smyislovyikh interpretacij, trebuyet fiksirovatj proiskhozhdeniye, vremennoj poryadok i izvestnyiye poteri.

Gipoteza o `GCController` utochnena po modeli Apple API: klaviatura i myishj predstavlenyi otdeljnyimi tipami `GCKeyboard` i `GCMouse` vnutri frejmvorka Game Controller. Etot stek ostayotsya glavnyim kandidatom na obsjhij perenosimyij sloj, no ne vyibran zaraneye. V kartochke sopostavlenyi takzhe `NSEvent`, `CGEventTap`, `IOHIDManager` i platformennyiye UI API; dopustima gibridnaya arkhitektura s obsjhim perenosimyim yadrom i boleye syiryimi platformennyimi adapterami.

## Resheniye po avtomatizacii

Sleduyusjhim shagom nuzhen vosproizvodimyij Swift-prototip sravneniya. On dolzhen zapisyivatj odinakovyiye fizicheskiye scenarii v yedinuyu versionirovannuyu skhemu i avtomaticheski pokazyivatj polnotu polej, zaderzhku, vremennoye razresheniye, propuski, obyyedineniye sobyitij i platformennyiye ogranicheniya. V tekusjhej sessii prototip ne sozdavalsya: dlya chestnoj proverki nuzhnyi otdeljnaya realizacionnaya rabota, fizicheskiye ustrojstva i matrica platform.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [maksimaljno syiraya zapisj sobyitij ustrojstv vvoda](../../Trebovaniya/🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md)
- [indeks trebovanij](../../Trebovaniya/README.md)
- [polnoekrannoye prilozheniye bez sistemnoj obolochki](../../Trebovaniya/🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Variantyi API sverenyi s pervichnoj dokumentaciyej Apple Developer.
- Dvunapravlennaya semanticheskaya svyazj kartochek proverena vruchnuyu.
- Planovyij reyestr, recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian peresobranyi.
- `git diff --check`, `fum-session-coherence` i polnyij `fum-smoke-check` zavershilisj uspeshno.

## Istochniki

- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](zapros.md)
- [Game Controller](https://developer.apple.com/documentation/gamecontroller)
- [`NSEvent`](https://developer.apple.com/documentation/appkit/nsevent)
- [`CGEvent`](https://developer.apple.com/documentation/coregraphics/cgevent)
- [`IOHIDManager`](https://developer.apple.com/documentation/iokit/iohidmanager_h)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a7014677d03a00e7b4cbc91d4b48a7089b629ac9c50c1cd7c06f45af290bf2cb -->
<!-- FUM-MD-RECENCY:END -->
