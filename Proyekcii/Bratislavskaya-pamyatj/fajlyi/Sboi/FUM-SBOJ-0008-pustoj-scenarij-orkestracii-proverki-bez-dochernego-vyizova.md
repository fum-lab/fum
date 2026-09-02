+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0008"
"статус" = "активна"
+++
# Pustoj scenarij orkestracii proverki bez dochernego vyizova

Kartochka sokhranyayet lozhnoye zaversheniye instrumentaljnogo khoda, kotoryij dolzhen byil zapustitj obyyavlennyij dochernij effekt. Svobodnyij JavaScript-scenarij `functions.exec` mozhet zavershitjsya bez ozhidayemogo vlozhennogo instrumenta libo sozdatj yego Promise bez obyazateljnogo `await`; vneshnyaya granica togda vyiglyadit zavershyonnoj, khotya zaplanirovannyij process ili host-vyizov mog voobsjhe ne nachatjsya.

## Nablyudayemyij sboj

Posle dobavleniya FUM-SBOJ-0007 kornevoj agent nachal sobiratj vyizov obnovleniya grafa v `functions.exec`, obyyavil `путьЗапроса` i nepolnyij massiv `команда`, no zakonchil scenarij bez `await tools.exec_command(...)` i bez `text(...)`. Instrumentaljnyij khod vernul pustoye uspeshnoye zaversheniye. Generator grafa i obyortka uchyota proverok ne zapuskalisj, novoj mashinnoj zapisi ne poyavilosj.

Pyatiminutnyij dispetcher proshyol ranniye proverki, obsjhuyu rezervaciyu, specializirovannuyu pretenziyu i dolgovechnuyu komandu `начать-вызов-среды`, no yego prompt ne treboval `await` dlya nested `create_thread` i raspolagal postroyeniye dochernego zaprosa uzhe posle granicyi. Novaya zadacha ne nablyudalasj v posleduyusjhem obyyedinyonnom host-snimke, a obsjhaya rezervaciya i pretenziya ostalisj v faze ograzhdyonnoj neopredelyonnosti.

## Granica povtoreniya

Kartochka okhvatyivayet zayavlennyij cherez `functions.exec` proverochnyij, generatornyij ili host-khod, v kotorom svobodnyij JavaScript zavershayetsya bez yedinstvennogo ozhidayemogo vlozhennogo vyizova, bez obyazateljnogo `await`, bez proveryayemogo rezuljtata i bez yavnogo otkaza. Dlya vneshnego effekta syuda takzhe otnositsya perekhod dolgovechnoj pre-effect-granicyi do polnoj podgotovki vkhoda i ozhidayemogo nested-vyizova.

Syuda ne otnosyatsya namerennyij chistyij raschyot bez vneshnego dejstviya, scenarij s realjno vyipolnennyim vlozhennyim instrumentom i pustyim standartnyim vyivodom, otkaz vlozhennogo instrumenta i nezapusjhennaya komanda iz-za dokazannogo preflight-otkaza. Obsjhaya mera dolzhna razlichatj klass ozhidayemogo effekta do ispolneniya, a ne zapresjhatj vse pustyiye vyichisleniya sredyi.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                             | Effekt                                                                                                                                            | Vosstanovleniye                                                                                                                                                                                                                                            |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet sostav nepolnogo scenariya, pustoj iskhod i otsutstviye novoj zapisi v mashinnom zhurnale mezhdu sosednimi poryadkovyimi nomerami.                                            | Zaplanirovannoye obnovleniye grafa ne proizoshlo, a vneshnij uspekh JavaScript-vyichisleniya mog byitj oshibochno prinyat za uspekh dochernej proverki.         | Sleduyusjhij khod yavno vyizyivayet i ozhidayet `tools.exec_command`, vyivodit yego rezuljtat i sveryayet poyavleniye terminaljnoj mashinnoj zapisi. Eto vosstanavlivayet tekusjhij khod, no ne ograzhdayet budusjhij pustoj scenarij; sistemnaya mera vyinesena v FUM-STEP-0136.    |
| `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0002` | [Otchyot pochinki avtozapuska](../Zhurnal/2026-08-11_13-03-53_MSK_pochinitj-avtozapusk-FUM/otchyot.md) fiksiruyet uspeshnyiye ranniye gate, rezervaciyu, claim i `начать-вызов-среды`, otsutstviye obyazateljnogo `await` u nested `create_thread` i otsutstviye novoj zadachi v posleduyusjhem ogranichennom host-snimke. | Isolate mog zavershitjsya do fakticheskogo host-vyizova; rezervaciya i claim ostalisj v ograzhdyonnoj neopredelyonnosti i zablokirovali posleduyusjhiye tiki. | Povtor i release posle granicyi zapresjhenyi. Tekusjhaya pochinka gotovit dochernij prompt zaraneye i v odnom orchestration-vyizove yavno ozhidayet granicu i rovno odin nested `create_thread`; zhivoye podtverzhdeniye polnogo idle-marshruta ostayotsya otdeljnoj priyomkoj. |

## Ozhidaniye i klassifikaciya

Eto oshibka ispolneniya i nedostatochno siljnaya granica orkestracionnogo rezuljtata, a ne otkaz dochernej proverki libo host-instrumenta: v podtverzhdyonnyikh proyavleniyakh oni ne poluchili dokazannogo ozhidayemogo vyizova. Dlya khoda, zaraneye obyyavlennogo kak zapusk proverki ili host-effekta, uspeshnoye vyichisleniye svobodnogo JavaScript bez ozhidayemogo vlozhennogo effekta ne dolzhno schitatjsya uspeshnyim vyipolneniyem dejstviya.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdenyi dva varianta odnogo mekhanizma: scenarij libo voobsjhe ne soderzhit operacii zapuska, libo sozdayot Promise vlozhennogo instrumenta bez `await`, posle chego JavaScript-isolate vprave zavershitjsya i otbrositj nezavershyonnyij vyizov. Sreda korrektno vyichislyayet dopustimyij JavaScript, no ne znayet, chto khod obesjhal dochernij effekt.

Vremennoye sderzhivaniye — polnostjyu gotovitj vkhod do dolgovechnoj pre-effect-granicyi, a zatem v odnom orchestration-vyizove yavno ozhidatj granicu i yedinstvennyij vlozhennyij effekt bez promezhutochnogo zaversheniya modeli. Polnoye ustraneniye trebuyet strukturirovannogo orkestracionnogo interfejsa ili proveryayemogo konverta namereniya, kotoryij ne mozhet zavershitjsya bez ozhidayemogo vlozhennogo vyizova i sootvetstvuyusjhego tipu effekta svideteljstva.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                                         | Osnovaniye                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [FUM-STEP-0136 — Ograditj proverochnyij khod ot pustogo scenariya orkestracii](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0136-ograditj-proverochnyij-khod-ot-pustogo-scenariya-orkestracii.md)                             | Vvodit proveryayemyij klass ozhidayemogo effekta i zapresjhayet uspekh bez dochernego vyizova i mashinnogo svideteljstva. | `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0001`, `FUM-СБОЙ-0008/ПРОЯВЛЕНИЕ-0002` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj proyavleniya, dopustimogo iskhoda i dvustoronnej svyazi s shagom.                            | Kontur kartochek sboyev                                            |

## Kriterii zakryitiya

- Krasnaya host-fikstura obyyavlyayet khod kak uchtyonnyij zapusk proverki, ispolnyayet tochnyij pustoj scenarij proyavleniya i vosproizvodit nyineshnij uspeshnyij vozvrat bez vlozhennogo vyizova i mashinnoj zapisi.
- Strukturirovannyij interfejs do ispolneniya zakreplyayet ozhidayemyij klass effekta, tochnuyu sessiyu i dochernyuyu komandu otdeljno ot svobodnogo JavaScript-teksta.
- Obyyavlennyij host- ili orkestratoru proverochnyij khod obyazan vkhoditj v etot interfejs: syiroj `functions.exec` ryadom s nim ne mozhet podtverditj zaversheniye, a otsutstviye vkhoda ostavlyayet namereniye nezavershyonnyim i dayot yavnyij otkaz.
- Khod klassa «uchtyonnaya proverka» ne mozhet zavershitjsya uspeshno, poka ne podtverzhdenyi rovno odin vlozhennyij zapusk, prinadlezhasjhaya tochnoj sessii mashinnaya zapisj i yeyo terminaljnoye sostoyaniye.
- Pustoj scenarij, chastichno sobrannaya komanda, zabyityij `await`, otsutstviye publikacii rezuljtata i zaversheniye izolyata do vlozhennogo vyizova dayut yavnyij otkaz, a ne pustoj uspekh.
- Host-fikstura s dolgovechnoj pre-effect-granicej dokazyivayet, chto polnyij vkhod podgotovlen zaraneye, a granica i rovno odin nested host-vyizov yavno ozhidayutsya v odnom orchestration-vyizove bez promezhutochnogo vyikhoda.
- Namerennyij chistyij raschyot i read-only-kompoziciya bez zayavlennogo vneshnego effekta sokhranyayut otdeljnyij dopustimyij marshrut i ne trebuyut fiktivnogo dochernego processa.
- Poterya otveta posle fakticheskogo zapuska vosstanavlivayet tu zhe mashinnuyu zapisj i ne sozdayot povtornuyu proverku.
- Avtonomnaya poddeljnaya host-fikstura, proverka uchyota zapuskov i obsjhij smoke-check prokhodyat, a FUM-STEP-0136 zavershena s dokazateljstvom primenimyikh kriteriyev etoj kartochki.

## Istochniki

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya uchyota proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)
- [iskhodnyij zapros o pochinke avtozapuska](../Zhurnal/2026-08-11_13-03-53_MSK_pochinitj-avtozapusk-FUM/zapros.md)
- [otchyot o pochinke avtozapuska](../Zhurnal/2026-08-11_13-03-53_MSK_pochinitj-avtozapusk-FUM/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-11 14:05:39 MSK -->
<!-- content-sha256: sha256:8734a46b637590ea14c241ff36b7b84a4a74c7c9c792984dab6874df8d01e09c -->
<!-- FUM-MD-RECENCY:END -->
