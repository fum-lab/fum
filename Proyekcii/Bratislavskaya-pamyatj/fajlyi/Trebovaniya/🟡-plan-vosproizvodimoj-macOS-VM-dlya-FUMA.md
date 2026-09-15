# Plan vosproizvodimoj macOS VM dlya FUMA

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0071 -->

Podgotovitj konechnyij plan profilya macOS dlya obsjhego instrumenta virtualjnyikh mashin FUMA na Apple Silicon. Pervyij planiruyemyij pilot svyazyivayet sovmestimyij zakreplyonnyij obraz, vosproizvodimuyu ustanovku, gotovnostj gostya i odin yavno nazvannyij scenarij FUMA.

Obsjhij zhiznennyij cikl mozhet ispoljzovatj prinyatyiye chasti Linux-instrumenta: proverku resursov, otdeljnoye lokaljnoye sostoyaniye, vladeniye, ogranichennyiye ozhidaniya, SSH, ostanovku i povtor. Perenosimostj kazhdoj chasti podtverzhdayetsya otdeljno; nalichiye Linux-prototipa ne dokazyivayet macOS backend.

## Kriterii proverki

- Zadan pasport pilota: tochnyiye host, SDK i Swift, proiskhozhdeniye IPSW, versiya/build/khyesh fakticheskogo obraza, minimaljnyiye resursyi i sovmestimostj. Ne vyibrannyij ili ne proverennyij obraz ostayotsya neizvestnyim; latestSupported sluzhit obnaruzheniyu kandidata.
- Razlichenyi sozdaniye konfiguracii, ustanovka, pervyij zapusk s provisioning, gotovnostj SSH, vyipolneniye scenariya, shtatnaya ostanovka i povtor. Dlya kazhdoj stadii zadanyi vkhod, rezuljtat, predel ozhidaniya, oshibka i dopustimoye vosstanovleniye.
- Ukazanyi sokhranyayemyiye pri povtore hardwareModel, machineIdentifier, auxiliaryStorage i disk; drugaya mashina poluchayet sobstvennuyu identichnostj. Neizvestnyiye susjhestvuyusjhiye diski ne peresozdayutsya pri otkaze.
- Proverenyi trebovaniya vyibrannogo sposoba provisioning i yego dostupnostj na tochnyikh versiyakh host/guest. Peredannyij issledovateljskij srez macOS 27+ Beta ne zamenyayet proverku konkretnogo okruzheniya; Linux NoCloud/VSOCK ne schitayetsya gotovyim kanalom macOS.
- Plan proverki SSH podtverzhdayet nuzhnogo gostya, arkhitekturu, build i doverennuyu identichnostj. Dostup k obsjhemu katalogu zadayotsya yavno i po umolchaniyu ogranichivayetsya chteniyem.
- Vyibran odin gostevoj scenarij FUMA iz tochnogo klona FUM s obyyavlennyimi zavisimostyami. Sborka, zapusk i poleznyij rezuljtat proveryayutsya razdeljno; primenyayetsya susjhestvuyusjhaya podgotovka macOS, FUM-STEP-0179.
- Predusmotrenyi vosproizvodimyiye fiksturyi i otdeljnaya nastoyasjhaya proverka VM; polucheniye obraza, ustanovka, pervyij zapusk, SSH, scenarij i povtor imeyut otdeljnyiye profili vremeni.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [polnoj perenosimoj oflajn-avtonomnostjyu FUM](🟡-polnaya-perenosimaya-oflajn-avtonomnostj-FUM.md) — svyazyivayet obyazateljnyiye realjnyiye bajtyi i instrumentyi s proverkoj polnogo perenosimogo komplekta bez interneta.

- **dopolnyayetsya:** [sborkoj Swift toolchain iz polnostjyu zerkaljnyikh zavisimostej](🟡-sborka-Swift-toolchain-iz-polnostjyu-zerkaljnyikh-zavisimostej.md) — svyazyivayet polnuyu postavku instrumentariya s pervyim vosproizvodimyim profilem.

## Status i granicyi

Status trebovaniya — `🟡`.

Tekusjhij rezuljtat — postanovka i plan pilota, a ne realizaciya backend ili zapusk VM. Obraz ne skachan, mashina ne sozdana, provisioning ne vyipolnen. Pered ispoljzovaniyem Apple API trebuyetsya adresnaya sverka oficialjnoj dokumentacii i konkretnogo okruzheniya. Sobstvennyiye iskhodniki posleduyusjhej realizacii ostayutsya v monorepozitorii FUM; obrazyi, diski i sekretyi — vne Git.

## Istochniki trebovanij

- [Avtonomnyij komplekt i binarnyiye obyyektyi vne Git](../Zhurnal/2026-09-11_19-12-07_MSK_prinyatj-plan-avtonomnogo-komplekta-FUM/zapros.md).

- [Postanovka zerkaljnoj sborki Swift](../Zhurnal/2026-09-11_18-47-36_MSK_prinyatj-plan-zerkaljnoj-sborki-Swift/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:45:10 MSK -->
<!-- content-sha256: sha256:2e3d96ecf9e8865817b3429cfbdd937858534917511b2655335420bb155c7921 -->
<!-- FUM-MD-RECENCY:END -->
