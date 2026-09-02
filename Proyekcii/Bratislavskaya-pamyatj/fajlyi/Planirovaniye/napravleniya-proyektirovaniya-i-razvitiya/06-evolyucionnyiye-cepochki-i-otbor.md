# 06. Evolyucionnyiye cepochki i otbor

## Naznacheniye

Eto napravleniye svyazyivayet razvitiye [FUM](../../Glossarij/FUM.md) s [evolyucionnyimi cepochkami FUM](../../Glossarij/evolyucionnaya-cepochka-FUM.md). Vetki rabotyi, proverki, revjyu, kommityi, sliyaniya i peredacha rezuljtatov dolzhnyi stanovitjsya nositelem nasledovaniya i otbora, a ne toljko tekhnicheskoj istoriyej Git.

## Proyektnyiye voprosyi

- Chto dolzhno vkhoditj v pasport [peredavayemogo rezuljtata FUM](../../Glossarij/peredavayemyij-rezuljtat-FUM.md)?
- Kak fiksirovatj vnutrennij otbor agenta i vneshnij otbor cherez poljzovatelya, testyi, benchmark, revjyu ili sredu?
- Kak [reyestr proiskhozhdeniya FUM](../../Glossarij/reyestr-proiskhozhdeniya-FUM.md) svyazyivayet rezuljtat, predkov, avtora, stoimostj, proverku i status?
- Kak vyichislyatj [ves agenta FUM](../../Glossarij/ves-agenta-FUM.md) i [ves svyazi FUM](../../Glossarij/ves-svyazi-FUM.md) bez prevrasjheniya vesa v vlastj?

## Liniya razvitiya

[Minimaljnyij pasport peredavayemogo rezuljtata FUM](../../Dokumentaciya/39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md) versii `1` zakreplyayet pervoye mashinno chitayemoye zveno napravleniya. Sleduyusjhim lokaljnyim sloyem mozhet statj malenjkij reyestr proiskhozhdeniya dlya rezuljtatov rabochikh sessij: kakoj zapros byil vkhodom, kakiye fajlyi izmenenyi, kakiye proverki projdenyi, kakoj rezuljtat peredan daljshe i s kakoj uverennostjyu.

V daljnem sloye eto napravleniye dolzhno podderzhatj [darvinovskij planirovsjhik FUM](../../Glossarij/darvinovskij-planirovsjhik-FUM.md): planirovaniye sleduyusjhikh rabot uchityivayet ne toljko namereniye, no i istoriyu togo, kakiye cepochki realjno davali proveryayemyiye poleznyiye rezuljtatyi.

[Kartochki sootvetstviya FUM](../../Glossarij/kartochka-sootvetstviya-FUM.md) rasshiryayut eto napravleniye za predelyi Git. Oni pozvolyayut sravnivatj raznyiye nositeli otbora - vetki, avtomatizacii, interfejsyi, apparatnyiye sloi i fizicheskiye analogii - s odnoj [obsjhej skhemoj FUM](../../Glossarij/obsjhaya-skhema-FUM.md), sokhranyaya razlichiye mezhdu zakreplyonnyim inzhenernyim patternom i issledovateljskoj gipotezoj.

## Proveryayemyij artefakt

Tekusjhij artefakt - [minimaljnyij pasport peredavayemogo rezuljtata FUM](../../Dokumentaciya/39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md): istochniki, proverka, stoimostj, uverennostj, adresatyi, ogranicheniya i status peredachi sleduyusjhej cepochke.

[Zapolnennyij primer](../../Dokumentaciya/39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/primer-pasporta-FUM-STEP-0025.json) svyazyivayet odin rezuljtat rabochej sessii s iskhodnyim zaprosom, osnovnyimi artefaktami i manifestom izmenyonnyikh fajlov, proverkami, tochnyim kommitom, stoimostjyu i ponyatnoj granicej peredachi. Strukturnyij i semanticheskij validatoryi proveryayut etot kontrakt lokaljno.

## Proveryayemyiye rezuljtatyi

- Pasport rezuljtata soderzhit istochniki, proverku, stoimostj, uverennostj, adresatov, ogranicheniya i otdeljnyij status kazhdogo marshruta peredachi.
- Reyestr proiskhozhdeniya svyazyivayet rezuljtat s zaprosom, kommitom, proverkami, agentom i predkami.
- Vetka rabotyi mozhet obyyasnitj, pochemu yeyo rezuljtat prinyat, otklonyon ili trebuyet dorabotki.
- Metriki otbora ispoljzuyutsya kak podskazka marshrutizacii, a ne kak absolyutnoye pravo upravleniya.

## Granicyi

Otbor ne dolzhen skryivatj chelovecheskoye resheniye i ne dolzhen prevrasjhatjsya v rejting radi rejtinga. Yesli rezuljtat zatragivayet privatnyiye dannyiye, urovni dostupa ili socialjno znachimyiye dejstviya, yego peredacha ogranichivayetsya pravilami dostupa, a ne toljko tekhnicheskoj uspeshnostjyu proverki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 12:53:46 MSK - Opisatj minimaljnyij pasport peredavayemogo rezuljtata FUM](../../Zhurnal/2026-07-23_12-53-46_MSK_opisatj-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)

## Opornyiye materialyi

- [Git-infrastruktura evolyucionnyikh cepochek FUM](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Reyestr kartochek sootvetstviya FUM](../../Dokumentaciya/28-reyestr-kartochek-sootvetstviya-FUM/README.md)
- [Paralleljnaya rabota i sliyaniye](../../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [Arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [Dorozhnaya karta FUM](../dorozhnaya-karta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:fd875df09c75857860bae40b2a7d0caaee0dcf24717e4e0356c4ae0a8d1c31b3 -->
<!-- FUM-MD-RECENCY:END -->
