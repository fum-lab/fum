+++
schema_version = 1
card_id = "FUM-STEP-0045"
status = "completed"
+++
# Normalizovatj monotonnoye vremya vsekh istochnikov pervichnoj trassyi vvoda i dobavitj mezhistochnikovyiye testyi

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Normalizovatj monotonnoye vremya vsekh istochnikov pervichnoj trassyi vvoda i dobavitj mezhistochnikovyiye testyi.

## Rezuljtat

Dobavlen yedinyij normalizator: IOHID AbsoluteTime preobrazuyetsya cherez `mach_timebase_info` bez promezhutochnogo perepolneniya, CGEvent i GCKeyboard yavno ispoljzuyut nanosekundyi, NSEvent perevodit proverennyiye sekundyi. Pyatj novyikh testov pokryivayut koefficiyent `125/3`, perepolneniye i obsjhuyu shkalu istochnikov.

## Istochniki

- [iskhodnyij zapros 2026-07-20 14:24:31 MSK](../../Zhurnal/2026-07-20_14-24-31_MSK_normalizovatj-monotonnoye-vremya-istochnikov-vvoda/zapros.md), [prototip](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md), [zhurnal](../../Zhurnal/2026-07-20_14-24-31_MSK_normalizovatj-monotonnoye-vremya-istochnikov-vvoda/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ac47fcd1176d89ce0b6962f763554c1368c79985805611fba300cef5e7766af7 -->
<!-- FUM-MD-RECENCY:END -->
