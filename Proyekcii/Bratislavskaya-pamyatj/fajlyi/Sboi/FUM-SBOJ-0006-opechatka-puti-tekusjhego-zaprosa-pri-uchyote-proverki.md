+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0006"
"статус" = "активна"
+++
# Opechatka puti tekusjhego zaprosa pri uchyote proverki

Kartochka sokhranyayet otkaz zapuska proverki iz-za ruchnogo povtoreniya dlinnogo kirillicheskogo puti tekusjhego zaprosa. Obyortka uchyota zakryito otvergla otsutstvuyusjhij fajl do zapuska dochernego processa, no oshibochnaya popyitka ne mogla svyazatj sebya s nastoyasjhej sessiyej i poetomu ne voshla v yeyo mashinnyij zhurnal avtomaticheski.

## Nablyudayemyij sboj

Pri predfinaljnom obnovlenii grafa v parametre `--запрос` kanonicheskij komponent `для-порождения-шагов` byil vruchnuyu nabran kak `для-порожденния-шагов`. Obyortka soobsjhila, chto zapros dolzhen byitj obyichnyim fajlom, zavershilasj do zapuska generatora grafa i ne sozdala zapisj v kataloge nastoyasjhego zaprosa.

## Granica povtoreniya

Kartochka okhvatyivayet pryamyiye vyizovyi obyortki uchyota proverok tekusjhej kornevoj sessii, v kotoryikh polnyij putj `Журнал/<папка>/запрос.md` kazhdyij raz vruchnuyu povtoryayetsya i iz-za opechatki, normalizacii libo vyibora sosednej papki ne sovpadayet s uzhe ustanovlennoj identichnostjyu sessii.

Syuda ne otnosyatsya yavnaya proverka drugoj istoricheskoj sessii, nevernyij putj, namerenno podannyij avtonomnoj fiksturoj, i sam zakryityij otkaz obyortki: otkaz srabotal praviljno i predotvratil zapusk bez vladeljca. Obsjhaya mera dolzhna ubratj ruchnoye povtoreniye puti iz shtatnogo marshruta, sokhraniv yavnyij interfejs dlya testov i istorii.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                       | Effekt                                                                                                                                                | Vosstanovleniye                                                                                                                                                                                                                 |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0006/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) sokhranyayet tochnyiye razlichayusjhiyesya komponentyi puti, otkaz do dochernego zapuska i otsutstviye mashinnoj zapisi iskhodnoj popyitki. | Generator grafa ne zapusjhen, predfinaljnyij kontur prervan, a iskhodnaya neuspeshnaya popyitka ne voshla v mashinnuyu summu iz-za nevernoj identichnosti sessii. | Kanonicheskij putj povtorno sveryayetsya s susjhestvuyusjhim `запрос.md`, a posleduyusjhiye vyizovyi ispoljzuyut tochnuyu stroku. Eto vosstanavlivayet tekusjhij khod, no ne ustranyayet ruchnoye dublirovaniye; sistemnaya mera vyinesena v FUM-STEP-0134. |
| `FUM-СБОЙ-0006/ПРОЯВЛЕНИЕ-0002` | [Otchyot perekhoda k Windows](../Zhurnal/2026-09-11_00-58-07_MSK_zaplanirovatj-podgotovku-Windows/otchyot.md) i terminaljnyiye zapisi 4–6 predyidusjhego etapa podtverzhdayut vyibor ustarevshej privyazki.                                                     | Posle otkaza podgotovki tri proverki zapisanyi v prezhnij otkryityij otchyot vmesto novogo etapa.                                                           | Zapisi sokhranenyi; novyij etap sozdan otdeljno, zavisimyij zapusk trebuyet yavnogo uspekha podgotovki. Sistemnoye predotvrasjheniye — FUM-STEP-0134.                                                                                     |

## Ozhidaniye i klassifikaciya

Eto oshibka ispolneniya, a ne defekt dejstvuyusjhego kontrakta obyortki: parametr `--запрос` yavlyayetsya mashinno proveryayemoj privyazkoj vladeljca, i otkaz otsutstvuyusjhego fajla srabotal praviljno. Ruchnaya opechatka razoshlasj s namereniyem zapustitj i uchestj proverku dlya ustanovlennoj sessii i prervala rabochij khod. Povtoreniye dlinnogo puti v kazhdom shtatnom vyizove sokhranyayetsya kak nablyudayemaya neudobnaya granica i vyibrannaya oblastj sistemnogo predotvrasjheniya, a ne kak raneye obesjhannaya, no otsutstvuyusjhaya funkciya.

## Mekhanizm i sistemnoye ustraneniye

Vo vtorom proyavlenii prichinoj vyibora sosednego vladeljca stala ustarevshaya privatnaya privyazka posle otkaza podgotovki sleduyusjhego etapa. Obsjhaya granica s pervyim proyavleniyem — nesovpadeniye peredannogo vladeljca s fakticheski nachatyim etapom. Sessionnyij interfejs dolzhen proveryatj i UUID, i granicu etapa/iskhodnogo HEAD; odin susjhestvuyusjhij putj ne dokazyivayet aktualjnosti.

Podtverzhdyon neposredstvennyij mekhanizm proyavleniya: odin komponent kanonicheskogo puti byil povtorno nabran s lishnej bukvoj, a obyortka korrektno ostanovila vyizov. Otdeljnyij shtatnyij sessionnyij marshrut rassmatrivayetsya kak mera predotvrasjheniya povtornogo ruchnogo vvoda; yego otsutstviye samo po sebe ne obyyavlyayetsya narusheniyem dejstvuyusjhego kontrakta.

Vremennoye sderzhivaniye — kopirovatj uzhe proverennyij putj bez ruchnoj pravki i do zapuska podtverzhdatj susjhestvovaniye tochnogo `запрос.md`. Polnoye ustraneniye trebuyet sessionnogo interfejsa, kotoryij po tochnomu kornevomu `CODEX_THREAD_ID` libo raneye proverennomu neprozrachnomu identifikatoru odnoznachno nakhodit zapros, svyazyivayet vse zapisi s nim i ne prinimayet raskhodyasjhuyusya ruchnuyu podstanovku v obyichnom khode.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                            | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | ------------------------------- |
| [FUM-STEP-0134 — Svyazatj zapuski proverok s tekusjhim zaprosom bez povtoreniya puti](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0134-svyazatj-zapuski-proverok-s-tekusjhim-zaprosom-bez-povtoreniya-puti.md)               | Ubirayet svobodnyij dlinnyij putj iz shtatnogo marshruta i sokhranyayet fail-closed-identichnostj sessii. | `FUM-СБОЙ-0006/ПРОЯВЛЕНИЕ-0001` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj proyavleniya, dopustimogo iskhoda i dvustoronnej svyazi s shagom.               | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Regressiya vtorogo proyavleniya otklonyayet ustarevshuyu privyazku posle kommita ili otkaza nachala sleduyusjhego etapa do dochernego processa i zapisi v prezhnij otchyot.

- Krasnaya fikstura vosproizvodit odnobukvennoye raskhozhdeniye dlinnogo kirillicheskogo puti i nyineshnyuyu nevozmozhnostj svyazatj iskhodnuyu popyitku s mashinnyim zhurnalom nastoyasjhej sessii.
- Shtatnyij zapusk proverki prinimayet tochnyij kornevoj `CODEX_THREAD_ID` libo raneye proverennyij neprozrachnyij identifikator i odnoznachno vyivodit susjhestvuyusjhij kanonicheskij `Журнал/<папка>/запрос.md` bez povtornogo svobodnogo puti.
- Otsutstvuyusjhaya i mnozhestvennaya privyazka identifikatora zakryito otklonyayutsya do dochernego zapuska i ne vyibirayut blizhajshuyu po imeni papku.
- Yavnyij putj sokhranyayetsya toljko dlya ograzhdyonnyikh avtonomnyikh testov i istoricheskikh operacij; obyichnaya tekusjhaya sessiya ne mozhet sluchajno peredatj raskhodyasjhijsya putj.
- Sozdannaya mashinnaya zapisj khranit vyivedennyij kanonicheskij putj, a vosstanovleniye posle preryivaniya prodolzhayet tot zhe sbor bez vtorogo vladeljca.
- Avtonomnyiye testyi obyortki, svyaznostj tekusjhej sessii i obsjhij smoke-check prokhodyat, a FUM-STEP-0134 zavershena s dokazateljstvom primenimyikh kriteriyev etoj kartochki.

## Istochniki

- [Povtor v postoyannoj zadache planirovaniya](../Zhurnal/2026-09-11_00-58-07_MSK_zaplanirovatj-podgotovku-Windows/zapros.md) — `FUM-СБОЙ-0006/ПРОЯВЛЕНИЕ-0002`.

- [iskhodnyij zapros o kartochkakh sboyev](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya uchyota proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 00:59:28 MSK -->
<!-- content-sha256: sha256:5bd4760c529dd887aa00f649cba4bb3992b699bf0980b1bfc24eb3a05ef64fa3 -->
<!-- FUM-MD-RECENCY:END -->
