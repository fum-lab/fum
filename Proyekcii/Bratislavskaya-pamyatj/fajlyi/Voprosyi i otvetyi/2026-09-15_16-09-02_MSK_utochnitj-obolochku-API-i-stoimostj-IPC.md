# Yedinyij runtime FUMA i stoimostj IPC

## Vopros

````text
U nas gde-to zaplanirovano obyyedineniye vsekh zavisimostej rantajma FUMA v funkcii yedinogo ispolnyayemogo binarnika?

````

## Otvet

Prochitannaya postanovka FUM-STEP-0176 opredelyayet dostavku sobstvennyikh iskhodnikov i vosproizvodimostj sborki; obyyedineniye zavisimostej v odin runtime-process ona ne podtverzhdayet. Novoye utochneniye zakreplyayet celj minimizirovatj IPC. Goryachij putj sleduyet issledovatj cherez pryamyiye funkcii i obsjhiye buferyi v odnom processe, sravniv yego s iskhodnyim variantom. Biblioteka v tom zhe processe tozhe ne trebuyet IPC dlya lokaljnogo vyizova; odin fajl postavki ne garantiruyet odnogo processa.

Obyyedineniye poka ne realizovano. Pered vyiborom sostava nuzhnyi izmereniya perekhodov, serializacii, kopirovaniya, zaderzhek i pamyati, a takzhe proverka vozmozhnosti vstraivaniya kazhdogo komponenta. Sistemnyiye frameworks i SDK ne obesjhanyi chastjyu sobstvennogo binarnika.

## Istochniki trebovanij

- [Original voprosa i utochneniye celi](../Zhurnal/2026-09-15_16-09-02_MSK_utochnitj-obolochku-API-i-stoimostj-IPC/zapros.md).

## Opornyiye materialyi

- [Operatornyij interfejs i kriterii IPC](../Planirovaniye/operatornyij-interfejs-FUMA.md).
- [FUM-STEP-0176](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:49:35 MSK -->
<!-- content-sha256: sha256:fd8fe68d13d831386e29176c414ee9b870b7c9ee489dbb7161e6a7a009e59cb3 -->
<!-- FUM-MD-RECENCY:END -->
