+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0030"
"статус" = "активна"
+++
# Lishnyaya pustaya stroka narushayet razbor trailer

## Nablyudayemyij sboj

V diagnostike 101 proverka svyaznosti otklonila podgotovlennoye soobsjheniye s yedinstvennyim praviljnyim Codex-Thread-ID v konce. Mezhdu poslednej komandoj i trailer nakhodilisj tri perevoda stroki: odin zavershal doslovnuyu komandu, dva dobavlyalisj pri sborke soobsjheniya.

## Granica povtoreniya

Dopolniteljnaya pustaya stroka pered konechnyim trailer-blokom ostavlyayet pustuyu pervuyu stroku v rezuljtate tekusjhego razbiyeniya abzacev. Kartochka ne okhvatyivayet otsutstvuyusjhij, povtornyij ili nevernyij identifikator i tekst posle trailer.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0030/ПРОЯВЛЕНИЕ-0001` | [Diagnostika 101 i razbor prichinyi](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/otchyot.md) | Svyaznostj otklonyayet konechnyij praviljnyij identifikator iz-za razdelitelya. | V podgotovlennom fajle normalizovatj toljko razdelitelj do odnoj pustoj stroki; sokhranitj doslovnyiye komandyi. |

## Ozhidaniye i klassifikaciya

Dejstvuyusjhiye pravila trebuyut praviljnyij konechnyij Git trailer, no ne predpisyivayut rovno odnu pustuyu stroku pered nim. Eto nedorabotka raspoznavaniya razdelitelej v validatore; normalizaciya vkhoda ne ustranyayet yeyo.

## Mekhanizm i sistemnoye ustraneniye

Funkciya commit_body_trailer_values razbivayet abzacyi po param perevodov stroki. Pri tryokh perevodakh neperekryivayusjheyesya razbiyeniye ostavlyayet vedusjhuyu pustuyu stroku v poslednem bloke; postrochnaya proverka schitayet yeyo ne-trailer i vozvrasjhayet otkaz. Mekhanizm podtverzhdyon chteniyem fakticheskogo fajla i funkcii; susjhestvuyusjhiye testyi etogo razdelitelya ne pokryivayut. Podgotovlennoye soobsjheniye normalizovano, diagnosticheskij vyivod sokhranyon vne checkout, nablyudavshijsya razdelitelj opisan vyishe. Trebuyetsya ispravitj parser s sokhraneniyem strogoj proverki identichnosti.

## Svyazannyiye shagi

| Shag | Rolj | Osnovaniye |
| --- | --- | --- |
| [FUM-STEP-0157](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0157-ispravitj-razbor-razdelitelya-pered-trailer.md) | Ustranitj zavisimostj raspoznavaniya ot chisla pustyikh strok. | `FUM-СБОЙ-0030/ПРОЯВЛЕНИЕ-0001` |

## Kriterii zakryitiya

Praviljnyij konechnyij trailer raspoznayotsya pri dopustimyikh pustyikh razdelitelyakh, pri etom lishnij tekst, dublikat i nevernyij identifikator ostayutsya otkazami. Dokazateljstvo dolzhno otnositjsya k ispravlennomu parser, a ne toljko k normalizovannomu vkhodu.

## Istochniki

- [Iskhodnyiye komandyi](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [Otchyot](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/otchyot.md).
- [Validator svyaznosti](../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 15:25:40 MSK -->
<!-- content-sha256: sha256:7dd1547bacde5b2a060a4d3f8d69ed6ceab1bcb82e6cca35217b0c122bc3cc28 -->
<!-- FUM-MD-RECENCY:END -->
