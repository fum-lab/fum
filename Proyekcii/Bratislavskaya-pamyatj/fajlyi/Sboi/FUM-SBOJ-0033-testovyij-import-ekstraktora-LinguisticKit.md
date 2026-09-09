+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0033"
"статус" = "устранена"
+++
# Ekstraktor LinguisticKit trebuyet testovyij import v Release

Granica ustraneniya — sborka i zapusk produkta LinguisticKitBuildTool v proverennoj dochernej vetke. Obnovleniye zavisimosti FUM i prinyatiye upstream PR vyipolnyayutsya otdeljno.

## Nablyudayemyij sboj

Pri sborke vsekh produktov v Release kompilyator otvergayet @testable import LinguisticKit: optimizirovannaya biblioteka ne sobrana dlya testirovaniya. Ispravleniye Sendable samo po sebe etot otkaz ne ustranyayet.

## Granica povtoreniya

Standartnaya optimizirovannaya sborka ispolnyayemogo ekstraktora bez flaga enable-testing. Eto kontrakt dostupa mezhdu celyami paketa, a ne gonka tablic.

## Proyavleniya

| Lokaljnyij nomer               | Istochnik i dokazateljstvo                                                                                  | Effekt                                          | Vosstanovleniye                                                        |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------- |
| FUM-SBOJ-0033/PROYAVLENIYE-0001 | [Pryamoj zapusk 9](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/otchyot.md) | Release-sborka ekstraktora zavershilasj otkazom. | Obyichnyij import i uzkaya vidimostj package dlya ispoljzuyemyikh opisatelej. |

## Mekhanizm i ogranichennoye vosstanovleniye

V ispolnyayemoj celi ostavlen obyichnyij import LinguisticKit. Perechenj chuvstviteljnyikh k registru pisjmennostej i tipyi opisaniya kontekstov dostupnyi sosednej celi cherez package. Publichnyij API biblioteki radi ekstraktora ne rasshiren, flagi proverki ne oslablenyi.

## Kriterii zakryitiya

- Vse produktyi sobirayutsya v Release bez enable-testing.
- Ekstraktor zapuskayetsya i sokhranyayet tochnyiye bajtyi vsekh JSON v Extracted.
- Ispolnyayemyij putj izmeren, usloviya sravneniya s iskhodnikom nazvanyi yavno.

## Podtverzhdeniye ustraneniya

[Kommit biblioteki b868465](https://github.com/fum-lab/LinguisticKit/commit/b8684654b2a16b04852b5b4cb0ec29e23c354939) proshyol Release-sborku; [otchyot](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/otchyot.md) i profilj ekstraktora sokhranyayut rezuljtat vyipolneniya i otsutstviye diff Extracted. Iskhodnomu sravneniyu ponadobilisj yavno oboznachennyiye rezhim Swift 5 i enable-testing; novyij variant obkhodov ne trebuyet. Perenositj vyichisleniya ili dobavlyatj keshi radi etogo izmeneniya ne trebuyetsya.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/zapros.md).
- [Otchyot s RED/GREEN](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/otchyot.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 23:05:31 MSK -->
<!-- content-sha256: sha256:b327fa07c158baf03df1f7651c3ae204a9b1c77c04add63c5d8238f1aa69982d -->
<!-- FUM-MD-RECENCY:END -->
