+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0028"
"статус" = "устранена"
+++
# Ekranirovaniye fiksturyi raspoznano kak mashinnyij putj

Granica ustraneniya — generator testovogo smoke priyomochnyikh raundov. Skaner mashinnyikh putej i yego politika isklyuchenij sokhranenyi; obsjhij vopros leksicheskogo raspoznavaniya proizvoljnyikh Python-strok etim ispravleniyem ne reshyon.

## Nablyudayemyij sboj

Polnaya priyomka 92 zavershilasj na shage 6 posle uspeshnyikh primeneniya proyekcii i nezavisimoj proverki manifesta. Adresnaya lokalizaciya 93 na tekh zhe otpechatkakh obnaruzhila rovno dve kategorii error.windows-unc v strokakh 687 i 689 testovogo generatora. Obe stroki predstavlyali perevod stroki dlya sozdavayemogo Python-koda, a ne mashinnyij putj.

## Granica povtoreniya

Dvojnoye ekranirovaniye perevoda stroki v sozdavayemom iskhodnike obrazuyet v kanonicheskom Python-fajle leksemu, kotoruyu skaner schitayet UNC-formoj. Proveryayetsya konkretnaya podgotovka testovogo smoke; otsutstviye realjnogo setevogo adresa ne otmenyayet obyazateljnyij otkaz skanera.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0028/ПРОЯВЛЕНИЕ-0001` | [Progonyi 92–93 i lokalizaciya](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/otchyot.md) | Priyomka ostanovilasj posle 2835,866678959 s vneshnego zapuska; snimok ne prinyat. | Zamenitj predstavleniye LF na chr(10) v generiruyemom kode i proveritj tochnyiye vyikhodyi bez rasshireniya isklyuchenij. |

## Mekhanizm i ogranichennoye vosstanovleniye

Obe operacii teperj yavno dobavlyayut simvol s kodom 10 v generiruyemom Python. V oblasti fiksturyi chr ne pereopredelyayetsya. Ubrana neodnoznachnaya dlya skanera zapisj; fakticheskoye soderzhimoye JSON nablyudenij i otchyota sokhranyayet te zhe bajtyi. Eto lokaljnaya proveryayemaya mera na tochnoj granice generacii.

## Kriterii zakryitiya

- Adresnyij skaner prinimayet tekusjhiye fajlyi bez izmeneniya politiki dopustimyikh putej.
- Sgenerirovannyij process vyipolnyayetsya; JSON i otchyot zakanchivayutsya prezhnim LF i sovpadayut s iskhodnyimi bajtami.
- Regressii priyomochnyikh raundov prokhodyat.
- Stoimostj izmeneniya izmerena; neproverennoye uskoreniye ne zayavlyayetsya.

## Podtverzhdeniye ustraneniya

Progon 97 skanera zavershilsya uspeshno; progon 96 vyipolnil 48 testov za 9,455 s. V profilyakh 94–95 kazhdyij iz semi sgenerirovannyikh processov byil ispolnen, JSON i otchyot proverenyi po znacheniyam i tochnyim bajtam; khyeshi oboikh vyikhodov sovpali do i posle izmeneniya. Mediana generacii sostavila 0,291667 ms do i 0,298709 ms posle. Dopolniteljnaya optimizaciya ne opravdana etoj stoimostjyu. Polnaya priyomka vsego novogo snimka ostayotsya otdeljnoj nezavershyonnoj rabotoj.

## Istochniki

- [Doslovnyiye komandyi tekusjhej zadachi](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [Otchyot i mashinnyiye zapisi zapuskov](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/otchyot.md).
- [Generator testovoj fiksturyi](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/tests/test_priyomochnyiye_raundyi.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 13:49:48 MSK -->
<!-- content-sha256: sha256:41c8b37580527bdac62dfc8661fc932d4759cfac3bbe9dd105568ce7d0e53cd3 -->
<!-- FUM-MD-RECENCY:END -->
