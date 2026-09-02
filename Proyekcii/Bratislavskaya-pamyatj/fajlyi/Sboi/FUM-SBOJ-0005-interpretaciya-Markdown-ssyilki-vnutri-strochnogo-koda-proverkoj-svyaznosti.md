+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0005"
"статус" = "активна"
+++
# Interpretaciya Markdown-ssyilki vnutri strochnogo koda proverkoj svyaznosti

Kartochka sokhranyayet lozhnyij otkaz proverki svyaznosti rabochej sessii na ssyilkopodobnom primere, celikom zaklyuchyonnom v strochnyij Markdown-kod. CommonMark ne delayet takuyu posledovateljnostj aktivnoj ssyilkoj, no dejstvuyusjhij skaner popyitalsya razreshitj yeyo adres i soobsjhil o vyikhode za korenj repozitoriya.

## Nablyudayemyij sboj

V opisanii FUM-SBOJ-0004 polnyij primer ssyilki byil zaklyuchyon v odinarnyiye obratnyiye kavyichki kak bukvaljnyij strochnyij kod:

```text
[правила раздела вопросов и ответов](<../../Вопросы и ответы/README.md>)
```

Predfinaljnaya proverka svyaznosti vsyo ravno interpretirovala vnutrennyuyu posledovateljnostj kak aktivnuyu lokaljnuyu ssyilku i zavershilasj s soobsjheniyem `local Markdown link escapes the repository` dlya tochnoj stroki kartochki.

## Granica povtoreniya

Kartochka okhvatyivayet izvlecheniye aktivnyikh Markdown-ssyilok proverkoj svyaznosti iz posledovateljnosti, kotoraya celikom nakhoditsya vnutri korrektnogo strochnogo koda s obratnyimi kavyichkami.

Syuda ne otnosyatsya nastoyasjhiye aktivnyiye ssyilki vne strochnogo koda, nezakryityij ili sintaksicheski povrezhdyonnyij kodovyij interval, soderzhimoye fenced-blokov, uzhe isklyuchayemoye proverkoj, i oshibki razresheniya korrektno izvlechyonnoj aktivnoj ssyilki. Obsjhaya mera dolzhna sokhranyatj proverku nastoyasjhikh ssyilok, a ne isklyuchatj vesj fajl ili stroku.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                                                                     | Effekt                                                                                                                                     | Vosstanovleniye                                                                                                                                                                    |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0005/ПРОЯВЛЕНИЕ-0001` | [Mashinnaya zapisj neuspeshnoj proverki](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/materialyi/zapuski-proverok/23_b037ef13-c6c4-4561-9c0e-1af6ff1611ec.json) sokhranyayet kod `1`, a [otchyot tekusjhej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) — tochnyij kontekst i diagnosticheskoye soobsjheniye. | Validnyij proizvodnyij Markdown ne prokhodit predkommitnuyu svyaznostj; avtor vyinuzhden menyatj bukvaljnyij primer libo ne mozhet zavershitj sessiyu. | Polnyij ssyilkopodobnyij primer zamenyon bezopasnyim razdeljnyim opisaniyem podpisi i celi. Eto snimayet tekusjhij otkaz, no ne ispravlyayet skaner; sistemnaya mera vyinesena v FUM-STEP-0133. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka lokaljnoj proverki: aktivnyij kontrakt svyaznosti trebuyet proveryatj realjnyiye Markdown-ssyilki, a strochnyij kod yavlyayetsya bukvaljnyim soderzhimyim i ne sozdayot ssyilku. Zakryitaya proverka dolzhna prodolzhatj otklonyatj tot zhe adres vne kodovogo intervala, no ne dolzhna vyivoditj rebro grafa iz koda.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdeno, chto dejstvuyusjhij putj izvlecheniya ssyilok ne isklyuchil korrektnyij strochnyij kod do raspoznavaniya ssyilochnogo sintaksisa. Tochnaya vnutrennyaya operaciya i polnota podderzhivayemyikh variantov obratnyikh kavyichek ostayutsya predmetom krasnoj fiksturyi.

Vremennoye sderzhivaniye — ne pomesjhatj polnuyu ssyilkopodobnuyu posledovateljnostj v strochnyij kod i sokhranyatj takiye primeryi vo fenced-bloke libo razdeljnyim opisaniyem. Polnoye ustraneniye trebuyet CommonMark-osoznanno isklyuchatj korrektnyiye kodovyiye intervalyi do izvlecheniya ssyilok i dokazatj, chto aktivnyiye ssyilki ryadom s nimi ne teryayutsya.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                     | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0133 — Isklyuchitj strochnyij kod iz proverki Markdown-ssyilok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0133-isklyuchitj-strochnyij-kod-iz-proverki-Markdown-ssyilok.md)                                         | Vosproizvodit lozhnyij otkaz i delayet izvlecheniye ssyilok osvedomlyonnyim o kodovyikh intervalakh. | `FUM-СБОЙ-0005/ПРОЯВЛЕНИЕ-0001` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj proyavleniya, dopustimogo iskhoda i dvustoronnej svyazi s shagom.        | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Krasnaya fikstura vosproizvodit tochnyij ssyilkopodobnyij primer vnutri odinarnogo kodovogo intervala i nyineshnij lozhnyij otkaz o vyikhode ssyilki za korenj.
- Proverka ne izvlekayet ssyilki iz korrektnyikh strochnyikh kodovyikh intervalov s primenimyimi dlinami ogranichitelya i pravilami vklyucheniya obratnyikh kavyichek.
- Ta zhe posledovateljnostj vne strochnogo koda ostayotsya aktivnoj ssyilkoj i zakryito otklonyayetsya pri vyikhode za korenj, otsutstvuyusjhej celi ili nevernom registre.
- Aktivnyiye ssyilki do i posle kodovogo intervala po-prezhnemu izvlekayutsya, razreshayutsya i proveryayutsya bez poteri.
- Nezakryityij ili sintaksicheski neodnoznachnyij kodovyij interval obrabatyivayetsya determinirovanno i ne stanovitsya sposobom skryitj nastoyasjhuyu ssyilku bez yavno zakreplyonnogo pravila.
- Avtonomnyiye testyi svyaznosti i obsjhij smoke-check prokhodyat, a FUM-STEP-0133 zavershena s dokazateljstvom primenimyikh kriteriyev etoj kartochki.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [neuspeshnyij zapusk proverki svyaznosti](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/materialyi/zapuski-proverok/23_b037ef13-c6c4-4561-9c0e-1af6ff1611ec.json)
- [avtomatizaciya svyaznosti rabochej sessii](../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:28:57 MSK -->
<!-- content-sha256: sha256:d772e7b9ff3706b121d48f7f744278977e4143efadb61c28499d82861d7098cc -->
<!-- FUM-MD-RECENCY:END -->
