+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0007"
"статус" = "активна"
+++
# Propusk opornoj datyi grafa posle perekhoda cherez polnochj MSK

Kartochka sokhranyayet nepolnyij inventarj zatronutyikh fajlov rabochej sessii posle perekhoda cherez kalendarnuyu granicu MSK. Finaljnoye obnovleniye teplovoj kartyi izmenilo vtoroj kanonicheskij vyikhod generatora — `.obsidian/fum-recency-reference-date`, no tekusjhij zapros perechislyal toljko `.obsidian/graph.json`, poetomu zamyikayusjhaya proverka svyaznosti zakryito otkazala.

## Nablyudayemyij sboj

Do polnogo smoke-check opornaya data grafa ostavalasj `2026-08-06`, a fajl ne vkhodil v Git diff. Smoke-check dlilsya okolo 27 minut i peresyok polnochj MSK. Posle zakryitiya mashinnogo zhurnala shtatnoye zamyikayusjheye obnovleniye grafa zamenilo datu na `2026-08-07`; proverka svyaznosti soobsjhila `unexpected Git status path: .obsidian/fum-recency-reference-date`, potomu chto razdel `Повлиял на файлы` tekusjhego zaprosa yesjhyo nazyival toljko teplovuyu kartu `graph.json`.

## Granica povtoreniya

Kartochka okhvatyivayet rabochuyu sessiyu, kotoraya vyizyivayet generator svezhesti grafa Obsidian, zavershayet soderzhateljnyij inventarj do poslednego zapuska generatora i peresekayet kalendarnuyu granicu MSK tak, chto raneye chistyij sidecar opornoj datyi stanovitsya izmenyonnyim toljko v zamyikayusjhem khode.

Syuda ne otnosyatsya proizvoljnyiye izmeneniya nastroyek Obsidian, ruchnoye redaktirovaniye sidecar, nevernaya data s drugoj dokazannoj prichinoj i sam zakryityij otkaz svyaznosti: proverka praviljno obnaruzhila nepokryityij putj. Obsjhaya mera dolzhna uchityivatj polnyij obyyavlennyij nabor vyikhodov generatora do dinamicheskogo izmeneniya Git-statusa.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                                                             | Effekt                                                                                                                                             | Vosstanovleniye                                                                                                                                                                                                                               |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0007/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet perekhod `2026-08-06` → `2026-08-07`, vyizov generatora i tochnyij otkaz svyaznosti; [tekusjhij zapros](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md) pokazyivayet vosstanovlennyij polnyij inventarj. | Zakryityij snimok prishlosj vozobnovitj, soderzhateljnuyu rabotu i priyomku prodolzhitj; bez proverki sidecar ostalsya byi nezayavlennyim izmeneniyem kommita. | V razdel zatronutyikh fajlov dobavlen tochnyij sidecar, a svyaznostj budet povtorena posle obnovleniya recency i grafa. Eto vosstanavlivayet tekusjhuyu sessiyu, no ne preduprezhdayet tot zhe perekhod v budusjhem; sistemnaya mera vyinesena v FUM-STEP-0135. |

## Ozhidaniye i klassifikaciya

Eto oshibka ispolneniya inventarnogo kontrakta sessii, a ne defekt generatora ili proverki svyaznosti. Navyik generatora yavno obyyavlyayet oba kanonicheskikh vyikhoda, generator korrektno obnovil kalendarnyij yakorj, a svyaznostj praviljno otvergla neozhidannyij Git-putj. Oshibka sostoyala v tom, chto inventarj byil sostavlen po nablyudayemomu do polunochi diff, a ne po polnomu naboru potencialjno izmenyayemyikh vyikhodov fakticheski ispoljzuyemogo generatora.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon vremennoj mekhanizm: mezhdu predfinaljnyim i zamyikayusjhim zapuskami izmenilasj data MSK, poetomu raneye chistyij sidecar stal vyikhodom tekusjhej sessii. Ruchnoj razdel `Повлиял на файлы` ne byil povtorno soglasovan s polnyim kontraktom vyikhodov do pervoj zamyikayusjhej svyaznosti.

Vremennoye sderzhivaniye — pri ispoljzovanii generatora grafa zaraneye perechislyatj oba yego kanonicheskikh vyikhoda nezavisimo ot iskhodnogo Git diff i povtorno sveryatj status posle zamyikayusjhego zapuska. Polnoye ustraneniye trebuyet mashinno dostupnogo perechnya vyikhodov generatora i proverki, chto sessionnyij inventarj pokryivayet vesj etot perechenj do zakryitiya, vklyuchaya fiksturu perekhoda cherez polnochj MSK.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                              | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0135 — Uchityivatj polnyij nabor vyikhodov generatora grafa v inventare sessii](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0135-uchityivatj-polnyij-nabor-vyikhodov-generatora-grafa-v-inventare-sessii.md)         | Svyazyivayet obyyavlennyiye vyikhodyi generatora s razdelom zatronutyikh fajlov i proveryayet perekhod datyi MSK. | `FUM-СБОЙ-0007/ПРОЯВЛЕНИЕ-0001` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj proyavleniya, dopustimogo iskhoda i dvustoronnej svyazi s shagom.                 | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Krasnaya integracionnaya fikstura zapuskayet generator do i posle perekhoda datyi MSK, poluchayet novyij sidecar toljko vo vtorom khode i vosproizvodit nepolnyij inventarj s odnoj teplovoj kartoj.
- Generator predostavlyayet mashinno chitayemyij tochnyij spisok oboikh kanonicheskikh vyikhodov: `.obsidian/graph.json` i `.obsidian/fum-recency-reference-date`.
- Rabochaya sessiya, kotoraya fakticheski ispoljzuyet generator, do zakryitiya pokryivayet v razdele zatronutyikh fajlov vesj obyyavlennyij nabor vyikhodov nezavisimo ot togo, kakoj iz nikh uzhe prisutstvuyet v Git diff.
- Neizmenivshijsya, no obyyavlennyij vyikhod dopuskayetsya v inventare i ne sozdayot fiktivnogo trebovaniya perepisatj yego; neizvestnyij, registronevernyij ili otsutstvuyusjhij obyyavlennyij putj zakryito otklonyayetsya.
- Perekhod cherez polnochj MSK mezhdu predfinaljnyim smoke-check i zamyikayusjhim obnovleniyem ne sozdayot neozhidannogo puti i prokhodit svyaznostj bez ruchnogo obnaruzheniya.
- Avtonomnyiye testyi svezhesti grafa i svyaznosti sessii, regressionnaya fikstura FUM-SBOJ-0007 i obsjhij smoke-check prokhodyat, a FUM-STEP-0135 zavershena s dokazateljstvom primenimyikh kriteriyev etoj kartochki.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya svezhesti grafa Obsidian](../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md)
- [avtomatizaciya svyaznosti rabochej sessii](../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 00:19:54 MSK -->
<!-- content-sha256: sha256:44a7837e7e4ecd8e97fe407cc502bccd3d915f69d5ff3e8b99c7d45075eb2449 -->
<!-- FUM-MD-RECENCY:END -->
