# Profilj i resheniye ob ogranichennoj optimizacii

Do izmeneniya algoritma sokhranenyi [syiryiye zameryi](profilj-do.json) i [iskhodniki](iskhodniki-profilya.json). Kazhdyij profilj: 256 nablyudenij, 512 bajt iskhodnogo fakta na nablyudeniye, 297121 bajt vkhoda, 597922 bajta kontejnera. Tretij iskhodnyij diagnosticheskij progon mog peresechjsya s kompilyaciyej novogo testa i isklyuchyon iz sravniteljnogo diapazona.

Gipoteza po profilyu i chteniyu koda: dorogo povtornoye kodirovaniye rastusjhego snimka pri vyichislenii SHA-256 do i posle kazhdogo perekhoda; chistaya redukciya zanimayet meneye 2% vremeni replay. Eto ne izolirovannaya prichinnaya ocenka. Proverennyij minimaljnyij eksperiment povtorno ispoljzuyet toljko uzhe vyichislennyij i proverennyij khyesh predyidusjhego snimka kak khyesh do sleduyusjhego perekhoda. Khyesh posle kazhdogo novogo perekhoda vyichislyayetsya zanovo; vkhod, I/O, fsync i prinyatyij kontejner ne menyayutsya. Kyesh obnovlyayetsya lishj posle uspeshnogo novogo append; povtor starogo sobyitiya ne otkatyivayet yego.

| Interval | Do: dva chistyikh progona | Posle: tri chistyikh progona | Finaljnyij podtverzhdayusjhij progon |
| --- | --- | --- | --- |
| Chistaya sborka | 20,207–20,661 ms | 21,135–21,396 ms | 21,933 ms |
| Sozdaniye i zapisj s preflight/fsync | 1111,012–1143,114 ms | 648,604–650,941 ms | 640,598 ms |
| Novyij ekzemplyar, replay i sverka | 1055,704–1093,429 ms | 580,234–587,899 ms | 576,585 ms |
| 32 povtora s fsync | 3,158–3,164 ms | 3,503–3,550 ms | 3,715 ms |
| Prirost khraneniya pri povtorakh | 0 bajt | 0 bajt | 0 bajt |

[Zameryi posle](profilj-posle.json) otnosyatsya k [manifestu posle optimizacii](iskhodniki-posle-profilya.json), [itogovyij profilj](profilj-itoga.json) — k [finaljnomu manifestu](iskhodniki-itoga.json). Po medianam lokaljnaya zapisj byistreye primerno na 42%, replay — na 46%. Neboljshoye udorozhaniye chistoj sborki i povtorov ne skryivayetsya. Resursnyiye proverki normalizovannoj identichnosti i diagnosticheskogo chteniya takzhe izmenilisj; vremya/diskovyij kyesh sredyi ne izolirovanyi. Poetomu procentyi opisyivayut nablyudyonnyiye variantyi, a ne garantirovannyij chistyij effekt yedinstvennogo izmeneniya ili SLA.

Vse izmerennyiye variantyi dali tochnyiye odinakovyiye SHA-256:

- Kontejner: `596db8e0a06e4826ce8b4bbe28a9fb1a1bc8f58d493f01682b7d87b99f824632`.
- Snimok: `083bae11a7571f6c9c436bae40cc5d92c8944f1c491bc86bcb1573dbb67ee448`.

Dopolniteljnyij test A,B,A,C sravnivayet kazhduyu sokhranyonnuyu zapisj s nezavisimyim nekyeshirovannyim orakulom: staryij povtor mezhdu novyimi sobyitiyami ne portit cepochku perekhodov. Iskhodnyiye UTF-8 payload i NFC/NFD klyucha proverenyi razdeljno. Itogovyij zapusk v4 №39: 35 GREEN, XCTest 0,565 s.

Resheniye: ostavitj uzkoye kyeshirovaniye proverennogo before-hash, konechnyiye byudzhetyi i ogranichennoye diagnosticheskoye chteniye; ne menyatj kontejner i ne dobavlyatj kyesh neproverennyikh svideteljstv. Finaljnyij profilj soderzhit monotonnyiye metki stadii, iskhoda i vlozhennosti; interval vsego profilya 1,257 s ne summiruyetsya povtorno so svoimi vlozhennyimi stadiyami. RSS i energopotrebleniye etogo novogo paketa ne izmeryalisj.

Osnovaniye: [iskhodnyij zapros](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 14:43:06 MSK -->
<!-- content-sha256: sha256:fc0459caaefaffa58e128aca1b974785cb26863db7e4d437f89f3ee934ebfb3d -->
<!-- FUM-MD-RECENCY:END -->
