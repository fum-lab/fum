+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0014"
"статус" = "снята"
+++
# Ruchnoye vozobnovleniye zadachi posle razryiva potoka otveta

Kartochka istoricheski sokhranyayet nablyudayemuyu nepreryivnostj: khod zadachi prervalsya transportnoj oshibkoj, a rabota v toj zhe zadache prodolzhilasj toljko posle povtornyikh soobsjhenij poljzovatelya. Eto fakt ruchnogo vozobnovleniya, a ne dokazateljstvo gibernacii mashinyi, yeyo probuzhdeniya ili vosstanovleniya vsej seti. Avtomaticheskoye soobsjheniye prezhnej zadache otnosilosj k snyatomu heartbeat-dispetcheru i boljshe ne yavlyayetsya ozhidayemyim sistemnyim marshrutom.

## Nablyudayemyij sboj

Posle nablyudayemogo razryiva potoka otveta zadacha ne poluchila avtomaticheskogo signala prodolzheniya. Poljzovatelj snachala yavno potreboval umetj chuvstvovatj takoj razryiv, a zatem dvazhdyi otdeljno povtoril komandu vozobnovitj rabotu. Prezhnij dispetcherskij heartbeat ne imel marshruta, kotoryij do vyikhoda po zanyatoj FIFO ogradil byi odno soobsjheniye v tu zhe svyazannuyu zadachu.

## Granica povtoreniya

Kartochka okhvatyivayet sluchai, kogda dlya toj zhe zadachi i neterminaljnogo logicheskogo zapuska nablyudayetsya terminaljnyij neuspeshnyij host-khod s tochnoj oshibkoj razryiva potoka, a vozobnovleniye ne proiskhodit bez novogo poljzovateljskogo soobsjheniya. Obsjhaya mera predotvrasjheniya — ograzhdyonno opoznatj tochnyij host-profilj, atomarno zapisatj popyitku do host-vyizova i adresovatj rovno odno zakryitoye soobsjheniye prezhnej zadache.

Syuda ne otnosyatsya yavnaya pauza, ozhidaniye poljzovatelya, aktivnyij khod, drugoj terminaljnyij iskhod, nesvyazannaya zadacha ili zapusk bez tochnoj dolgovechnoj privyazki. Fizicheskiye son i probuzhdeniye mashinyi, poterya i vosstanovleniye seti mogut byitj vozmozhnyimi prichinami, no bez sobstvennogo avtoritetnogo signala ne vkhodyat v dokazannyij klass sboya.

## Proyavleniya

| Lokaljnyij nomer                  | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                                                                  | Effekt                                                               | Vosstanovleniye                                                                                                                            |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0014/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij zapros](../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/zapros.md#tekst-zaprosa) pobajtno sokhranyayet iskhodnoye trebovaniye i dva posledovateljnyikh ruchnyikh ukazaniya prodolzhitj; [otchyot](../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/otchyot.md) fiksiruyet sistemnuyu meru i granicu yeyo zhivoj priyomki. | Bez chelovecheskogo soobsjheniya rabota v prezhnej zadache ne vozobnovilasj. | Poljzovatelj dvazhdyi povtoril komandu vozobnovitj rabotu; ruchnoj marshrut ne zamenyayet sistemnoye ustraneniye. |

## Ozhidaniye i klassifikaciya

V prezhnem ograzhdyonnom zapuske ozhidalosj, chto planovyij heartbeat do vyikhoda po zanyatoj FIFO opoznayet uzkij nablyudayemyij profilj razryiva i odin raz obratitsya k toj zhe zadache, ne sozdavaya zamenu. Dejstvuyusjhij kontur ne delayet vosstanoviteljnyikh host-soobsjhenij: kommit razreshyon toljko posle zaraneye sozdannogo prodolzheniya, a neodnoznachnostj do kommita zakryivayet avtomaticheskij povtor i trebuyet yavnogo chelovecheskogo vosstanovleniya.

## Mekhanizm i sistemnoye ustraneniye

Prezhnij heartbeat proveryal zanyatostj FIFO do lyubogo marshruta vozobnovleniya i ne khranil otdeljnoye dolgovechnoye sostoyaniye popyitki. Poetomu on ne mog otlichitj bezopasnoye odnokratnoye obrasjheniye k prezhnej zadache ot opasnogo povtora i zakryival tik kak zanyatyij.

Istoricheskaya sistemnaya mera dobavlyala v tot zhe heartbeat rannij marshrut vosstanovleniya, strogij host-readback i obsjhuyu Git-CAS-tranzakciyu do soobsjheniya. Ona boljshe ne vkhodit v arkhitekturu prodolzheniya. Dejstvuyusjhij protokol zaraneye svyazyivayet otdeljnuyu zadachu-prodolzheniye s kommitom vetki; posle podtverzhdyonnogo handoff novyij vladelec sam zhdyot FIFO, perechityivayet `HEAD` i prodolzhayet rabotu bez recovery-soobsjheniya prezhnej zadache.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                               | Svyazj                                                                                                           | Osnovaniye                        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| [FUM-STEP-0142 — Dobavitj ograzhdyonnoye vozobnovleniye zadach posle poteri svyazi](../Planirovaniye/kartochki-shagov/🗑️-FUM-STEP-0142-dobavitj-ograzhdyonnoye-vozobnovleniye-zadach-posle-poteri-svyazi.md) | Vvodit ograzhdyonnoye odnokratnoye vozobnovleniye toj zhe zadachi i sokhranyayet zhivuyu priyomku kak granicu zakryitiya. | `FUM-СБОЙ-0014/ПРОЯВЛЕНИЕ-0001` |

## Osnovaniye snyatiya

- Periodicheskij heartbeat, avtomaticheskoye recovery-soobsjheniye i FUM-STEP-0142 snyatyi vmeste s dispetcherskim konturom.
- Kazhdyij kommityasjhij vladelec zaraneye sozdayot otdeljnuyu zadachu-prodolzheniye tochnoj Git-vetki; prezhnyaya zadacha posle kommita ne vozobnovlyayetsya.
- Poteryannyij ili neodnoznachnyij otvet `create_thread` zapresjhayet kommit i avtomaticheskij povtor, a ne zapuskayet skryitoye vosstanovleniye.
- Kartochka povtorno aktiviruyetsya toljko pri yavnom vozvrasjhenii avtomaticheskogo host-vozobnovleniya prezhnej zadachi.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-08 18:57:20 MSK — Dobavitj ograzhdyonnoye vozobnovleniye posle razryiva svyazi](../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/zapros.md)
- [otchyot 2026-08-08 18:57:20 MSK — Dobavitj ograzhdyonnoye vozobnovleniye posle razryiva svyazi](../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/otchyot.md)
- [FUM-STEP-0142 — Dobavitj ograzhdyonnoye vozobnovleniye zadach posle poteri svyazi](../Planirovaniye/kartochki-shagov/🗑️-FUM-STEP-0142-dobavitj-ograzhdyonnoye-vozobnovleniye-zadach-posle-poteri-svyazi.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:bcf7ef9dad756f1a7fac928552d5d2221654db1293694283d3e4769ddd33941c -->
<!-- FUM-MD-RECENCY:END -->
