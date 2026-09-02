# Kartochka sboya

Kartochka sboya — dolgovechnaya diagnosticheskaya zapisj [pamyati FUM](pamyatj-FUM.md), kotoraya obyyedinyayet podtverzhdyonnyiye proyavleniya odnogo predpolagayemogo mekhanizma ili odnoj obsjhej granicyi predotvrasjheniya. Ona sokhranyayet nablyudayemyiye faktyi otdeljno ot gipotezyi prichinyi i svyazyivayet najdennuyu problemu s atomarnyimi [kartochkami shagov](kartochka-shaga.md), porozhdyonnyimi dlya issledovaniya, sderzhivaniya, predotvrasjheniya ili proverki.

Kartochka ne yavlyayetsya syiryim zhurnalom sobyitiya, trebovaniyem ili ispolnyayemyim planovyim zadaniyem. Odno proyavleniye ostayotsya adresuyemyim faktom v istochnike i v ryadu kartochki; sama kartochka izmenyayetsya po mere poyavleniya dokazateljstv, povtorov, shagov i mer predotvrasjheniya. Ispolneniye i dispetcherizaciya nachinayutsya toljko iz otdeljnoj kartochki shaga.

## Identichnostj i agregaciya

Kartochka poluchayet neizmenyayemyij identifikator `FUM-СБОЙ-NNNN`. Odin identifikator otnositsya ne k rabochej sessii i ne k stroke oshibki, a k klassu proyavlenij, dlya kotoryikh odna sistemnaya mera i odin regressionnyij kriterij sposobnyi predotvratitj povtoreniye. Kazhdoye proyavleniye poluchayet vnutri kartochki neizmenyayemyij nomer `FUM-СБОЙ-NNNN/ПРОЯВЛЕНИЕ-NNNN` i sokhranyayet istochnik, dokazateljstvo, effekt i sposob vosstanovleniya.

Sovpadayusjhij tekst oshibki, odin instrument ili blizkaya tema ne dokazyivayut obsjhij mekhanizm. Neopredelyonnyiye sluchai snachala khranyatsya razdeljno s yavnoj gipotezoj svyazi. Posle dokazateljstva dublikata odna kartochka poglosjhayetsya drugoj, no ne udalyayetsya; kanonicheskaya kartochka vklyuchayet ssyilki na vse yeyo proyavleniya pod iskhodnyimi lokaljnyimi nomerami. Pervoye nablyudeniye, posledneye nablyudeniye i chislo proyavlenij vyivodyatsya po tranzitivnomu obyyedineniyu kanonicheskoj i poglosjhyonnyikh kartochek bez dublikatov i ciklov. Vtoroye podtverzhdyonnoye proyavleniye uzhe yavlyayetsya povtorom; regulyarnostj vyivoditsya iz vsego ryada, a ne zamenyayetsya subyyektivnoj shkaloj chastotyi.

## Sostoyaniya

| Status      | Smyisl                                                                                                              |
| ----------- | ------------------------------------------------------------------------------------------------------------------ |
| `активна`   | Trebuyemaya sistemnaya mera i dokazateljstvo zakryitiya yesjhyo ne zavershenyi.                                               |
| `устранена` | Ustojchivaya mera predotvrasjheniya ili ogranichennogo vosstanovleniya proverena protiv tochnogo kriteriya zakryitiya.        |
| `поглощена` | Dokazan dublikat; kanonicheskaya kartochka vklyuchayet vse proyavleniya pod iskhodnyimi lokaljnyimi nomerami.                 |
| `снята`     | Nablyudeniye oprovergnuto libo primenimoye ozhidaniye formaljno utratilo silu; eto ne sposob otkazatjsya ot ispravleniya. |

Povtor posle statusa `устранена` vozvrasjhayet tu zhe kartochku v sostoyaniye `активна`. Prezhneye podtverzhdeniye ne stirayetsya i ostayotsya dokazateljstvom toljko dlya svoyej istoricheskoj granicyi.

## Soderzhaniye kartochki

Kartochka versii `1` soderzhit russkoyazyichnyiye polya metadannyikh `версия_схемы`, `идентификатор_сбоя` i `статус`, a posle soderzhateljnogo zagolovka — razdelyi:

- `Наблюдаемый сбой` — toljko ustanovlennyij fakt i vliyaniye bez vyimyishlennoj prichinyi;
- `Граница повторения` — kakiye proyavleniya otnosyatsya k kartochke i kakiye pokhozhiye sluchai iz neyo isklyuchenyi;
- `Проявления` — numerovannyij ryad istochnikov, dokazateljstv, effektov i vosstanovlenij;
- `Ожидание и классификация` — primenimoye ozhidaniye i dokazannaya klassifikaciya kak nedorabotki, vneshnego sboya libo poka neopredelyonnogo sluchaya;
- `Механизм и системное устранение` — urovenj podtverzhdeniya mekhanizma, vremennoye sderzhivaniye i trebuyemaya ustojchivaya mera;
- `Связанные шаги` — dvustoronniye svyazi s kartochkami shagov, rolj kazhdoj svyazi i tochnyiye proyavleniya, kotoryiye yeyo porodili ili aktualizirovali;
- `Критерии закрытия` — proveryayemaya granica, posle kotoroj dopustim status `устранена`;
- `Источники` — spravochnyij blok proiskhozhdeniya vnizu dokumenta.

Dlya statusa `устранена` dobavlyayetsya razdel `Подтверждение устранения`, dlya `поглощена` — `Поглощение`, dlya `снята` — `Причина снятия`. Kartochka ne kopiruyet kriterii vyipolneniya svyazannyikh shagov i ne zakryivayetsya avtomaticheski pri ikh zavershenii.

## Svyazj s nedorabotkami i shagami

Nedorabotka yavlyayetsya zakreplyonnoj v [pravilakh rabochikh sessij](../AGENTS.md) normativnoj klassifikaciyej nablyudayemogo narusheniya uzhe dejstvuyusjhego ozhidaniya. Ne kazhdyij vneshnij sboj yavlyayetsya nedorabotkoj, a nedorabotka mozhet proyavitjsya propuskom bez runtime-oshibki. Gipoteticheskij risk bez nablyudayemogo proyavleniya ostayotsya trebovaniyem, predlozheniyem shaga ili [otkryityim voprosom](otkryityij-vopros.md).

Aktivnaya nedorabotka, ne ustranyonnaya s proveryayemyim podtverzhdeniyem v toj zhe rabochej sessii, svyazyivayetsya khotya byi s odnoj aktualjnoj kartochkoj shaga. Neizvestnaya prichina mozhet snachala poroditj issledovateljskij shag. Vtoroye podtverzhdyonnoye proyavleniye vsegda porozhdayet libo aktualiziruyet shag: yego lokaljnyij nomer zapisyivayetsya kak osnovaniye svyazi v kartochke sboya i kak istochnik kartochki shaga, poetomu prezhnyaya neizmenyonnaya ssyilka ne vyidayotsya za obnovleniye. Svyazi dopustimyi mnogiye-ko-mnogim: odin sboj mozhet trebovatj neskoljkikh atomarnyikh mer, a odna sistemnaya mera mozhet pokryivatj neskoljko kartochek.

Razovaya korrekciya, uspeshnyij povtor, otsutstviye novyikh proyavlenij i zaversheniye odnogo shaga nedostatochnyi dlya zakryitiya. Nuzhnyi ustojchivaya mera, vyipolnennyiye neobkhodimyiye shagi i proveryayemoye dokazateljstvo protiv kriteriya kartochki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-06 22:29:49 MSK — Vvesti kartochki sboyev dlya porozhdeniya shagov](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [pravila rabochikh sessij](../AGENTS.md)
- [kartochka FUM-STEP-0114](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:14:11 MSK -->
<!-- content-sha256: sha256:662279d4ce0d0254f9d8907dc9f0c7872c39f7b225fc863a490baf37fe656023 -->
<!-- FUM-MD-RECENCY:END -->
