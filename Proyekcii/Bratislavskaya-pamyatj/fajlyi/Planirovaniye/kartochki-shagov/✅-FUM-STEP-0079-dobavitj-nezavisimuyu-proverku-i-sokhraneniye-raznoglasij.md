+++
schema_version = 1
card_id = "FUM-STEP-0079"
status = "completed"
+++
# Dobavitj nezavisimuyu proverku i sokhraneniye raznoglasij

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj k raspredelyonnomu myisliteljnomu epizodu otdeljnuyu proverku utverzhdenij i neizmenyayemoye sokhraneniye raznoglasij. Proveryayusjhij vklad dolzhen ssyilatjsya na zaraneye obyyavlennyiye kriterii, proveryayemyiye utverzhdeniya i vneshniye dokazateljstva, imetj proiskhozhdeniye i ne sovpadatj s proizvoditelem proveryayemogo rezuljtata v predelakh zayavlennoj roli. Itog proverki dolzhen byitj odnim iz `passed`, `failed` ili `inconclusive`, a vozrazheniya, konfliktyi i prichinyi otkloneniya dolzhnyi ostavatjsya v obsjhej pamyati posle vyibora.

## Pochemu sejchas

Proiskhozhdeniye FUM-STEP-0078 pokazyivayet korrelyaciyu vkladov, no samo po sebe ne proveryayet istinnostj utverzhdenij. Otdeljnaya proverka i sokhranyonnoye nesoglasiye nuzhnyi do realizacii vyibora: bez nikh sistema mogla byi prinyatj odinakovyiye neproverennyiye otvetyi za konsensus i poteryatj otricateljnyij rezuljtat.

## Kriterii zaversheniya

- Proverka soderzhit otdeljnyiye identifikatoryi proveryayusjhego i yego roli, obyyavlennyiye kriterii, proveryayemyiye utverzhdeniya, ssyilki na dokazateljstva i odin iz iskhodov `passed`, `failed` ili `inconclusive`.
- Proizvoditelj rezuljtata ne mozhet svoim zhe vkladom prisvoitj yemu status vneshne proverennogo; sovpadeniye ispolnitelya, roli ili zapresjhyonnoj gruppyi korrelyacii zakryivayetsya otkazom libo sokhranyayetsya toljko kak samoproverka bez povyishennogo vesa.
- Neskoljko odinakovyikh neproverennyikh otvetov ne stanovyatsya konsensusom, a otsutstviye dostatochnogo dokazateljstva dayot `inconclusive`, ne `passed`.
- Konfliktyi utverzhdenij, vozrazheniya, otricateljnyiye rezuljtatyi i prichinyi otkloneniya sokhranyayutsya v posleduyusjhikh pokoleniyakh i ostayutsya dostupnyi posle resheniya vyibora.
- Avtonomnyiye testyi pokryivayut nezavisimuyu proverku, samoproverku, korrelirovannuyu proverku, lozhnyij konsensus, nedostatochnoye dokazateljstvo i sokhraneniye raznoglasiya posle vosstanovleniya.
- README razlichayet proverku formyi, instrumentaljno podtverzhdyonnyij fakt i semanticheskuyu ocenku i ne zayavlyayet absolyutnuyu nezavisimostj proveryayusjhego.

## Rezuljtat

Obsjhaya pamyatj perevedena na skhemu zhurnala, sostoyaniya, pokoleniya i reducer versii 3. Zaraneye obyyavlennyiye kriterii i plan proverki vstroyenyi v seed i svyazanyi s pasportom tochnyimi SHA-256; kazhdaya dopisyivayemaya zapisj proverki zakreplyayet otdeljnyiye identifikatoryi proveryayusjhego i roli, proveryayemyij vklad i yego rezuljtat, instrumentaljnoye nablyudeniye, proiskhozhdeniye i odin iz iskhodov `passed`, `failed` ili `inconclusive`.

Iskhod otdelyon ot vyivodimogo statusa `external_by_observed_features`, `self_verification`, `correlated_verification` ili `unconfirmed_provenance`. Sovpadeniye ispolnitelya sokhranyayetsya kak samoproverka, pasportno nedopustimaya rolj zakryivayetsya otkazom, a obsjhaya zapresjhyonnaya gruppa — kak korrelirovannaya proverka; toljko vneshnij po nablyudayemyim priznakam `passed` poluchayet yedinichnyij ogranichennyij ves. Odinakovyiye neproverennyiye otvetyi ne obrazuyut soglasiye, nedostatochnoye svideteljstvo ne mozhet byitj obyyavleno `passed`, a absolyutnaya nezavisimostj i semanticheskaya istina vsegda ostayutsya nedokazannyimi.

Tipizirovannyiye konfliktyi utverzhdenij, vozrazheniya, otricateljnyiye rezuljtatyi i prichinyi otkloneniya sokhranyayutsya kumulyativno vmeste so vsemi proverkami. Vosemj avtonomnyikh scenariyev podtverzhdayut nezavisimuyu proverku, samoproverku, korrelirovannuyu proverku i yeyo tranzitivnostj, lozhnoye soglasiye, nedostatochnoye dokazateljstvo, polnotu korrelyacij i tochnoye vosstanovleniye raznoglasij posle posleduyusjhego pokoleniya i novogo processa. Ispolnyayemyij vyibor, byudzhetyi i ostanovka ostayutsya granicej FUM-STEP-0080.

## Istochniki

- [iskhodnyij zapros 2026-08-02 05:03:04 MSK — Dobavitj nezavisimuyu proverku i sokhraneniye raznoglasij](../../Zhurnal/2026-08-02_05-03-04_MSK_dobavitj-nezavisimuyu-proverku-i-sokhraneniye-raznoglasij/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [trebovaniye o proveryayemom mnogoagentnom konture FUM](../../Trebovaniya/🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md)
- [FUM-STEP-0078 — proiskhozhdeniye i ogranichennaya nezavisimostj vkladov](✅-FUM-STEP-0078-zafiksirovatj-proiskhozhdeniye-i-ogranichennuyu-nezavisimostj-vkladov-poduzlov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:159fd78b2de192afc2915e895ccbd1686d1a0c6f8b62588024dcdc15eebd465d -->
<!-- FUM-MD-RECENCY:END -->
