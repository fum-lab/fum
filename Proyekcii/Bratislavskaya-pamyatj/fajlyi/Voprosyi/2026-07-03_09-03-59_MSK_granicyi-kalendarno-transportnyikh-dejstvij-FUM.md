# Vopros: granicyi kalendarno-transportnyikh dejstvij [FUM](../Glossarij/FUM.md)

## Status

Vopros chastichno proyasnyon. [Pasport kalendarno-transportnogo servisnogo kontura](../Dokumentaciya/42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md) zadayot konservativnuyu modeljnuyu versiyu: razdeljnyiye klassyi effekta, dostup i operacionnyiye polnomochiya, yavnoye podtverzhdeniye tochnogo snimka, ochisjhennoye proiskhozhdeniye, oshibki, otmenyi, sinteticheskiye fiksturyi i simulyator bez vneshnego dejstviya. On ne opredelyayet dopustimostj realjnyikh adapterov i zaraneye zadannoj politiki avtonomii.

## Formulirovka

Ne opredeleno, kakiye kalendarnyiye, poyezdochnyiye i transportnyiye dejstviya FUM mozhet vyipolnyatj avtonomno, kakiye trebuyut otdeljnogo podtverzhdeniya poljzovatelya, a kakiye dolzhnyi ostavatjsya toljko rekomendaciyami ili podgotovlennyimi chernovikami. Neyasnostj osobenno vazhna dlya dejstvij, kotoryiye zatragivayut privatnoye raspisaniye, geolokaciyu, kontaktyi, oplatu, bronirovaniye, peredachu dannyikh vneshnim servisam i fizicheskoye peremesjheniye cheloveka.

## Chto nuzhno proyasnitj

- Kakiye operacii otnosyatsya k bezopasnomu chteniyu i modelirovaniyu: prosmotr kalendarya, poisk okna, raschyot vremeni dorogi, podgotovka marshruta ili chernovik sobyitiya?
- Kakiye dejstviya vsegda trebuyut yavnogo podtverzhdeniya: zapisj sobyitiya, izmeneniye chuzhogo raspisaniya, vyizov taksi, pokupka bileta, bronirovaniye, oplata, otmena poyezdki ili peredacha mestopolozheniya?
- Mozhno li zadavatj zaraneye razreshyonnyiye politiki avtonomii dlya povtoryayusjhikhsya poyezdok, i kak ogranichivatj ikh po summe, vremeni, mestu, servisu, uchastnikam i risku?
- Kakiye dannyiye kalendarya, kontaktov, mestopolozheniya, platezhej i istorii poyezdok dopustimo sokhranyatj v [pamyati FUM](../Glossarij/pamyatj-FUM.md), a kakiye dolzhnyi ostavatjsya vo vneshnem servise ili lokaljnom zasjhisjhyonnom khranilisjhe?
- Kak FUM dolzhen dejstvovatj pri konflikte raspisanij, oshibke servisa taksi, otmene poyezdki, nedostupnosti seti, izmenenii cenyi ili opasnom marshrute?
- Kakiye fiksturyi, simulyatoryi i testovyiye adapteryi nuzhnyi, chtobyi proveryatj scenarij bez realjnogo zakaza taksi, platezhej i peredachi privatnoj geolokacii?
- Kak svyazyivatj rezuljtat dejstviya s iskhodnyim namereniyem, podtverzhdeniyem, servisnyim adapterom, oshibkami i posleduyusjhej narabotkoj, ne raskryivaya sekretyi i privatnyiye detali?

## Chastichnoye proyasneniye

[Pasport versii 1](../Dokumentaciya/42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md) razreshayet toljko lokaljnoye chteniye sinteticheskikh dannyikh, modelirovaniye i proveryayemyiye fiksturnyiye otvetyi pri neizmennom nulevom vneshnem effekte. Lyubaya vneshnyaya zapisj, raskryitiye chuvstviteljnyikh kategorij, platnoye, dogovornoye ili fizicheski znachimoye dejstviye trebuyet yavnogo podtverzhdeniya, svyazannogo s tochnyimi operaciyej, sostoyaniyem, usloviyami, cenoj i dannyimi. Izmeneniye snimka ili istecheniye sroka annuliruyet podtverzhdeniye.

Dostup k svedeniyam otdelyon ot prava raskryivatj ikh i ot polnomochiya dejstvovatj. Publichnaya trassa khranit bezopasnyiye identifikatoryi, kodyi i zasjhisjhyonnyiye ssyilki vmesto nazvanij sobyitij, mest, uchastnikov, kontaktov, platyozhnyikh dannyikh i identifikatorov zakazov. Privatnyij konflikt v fiksture raskryivayetsya toljko kak `busy`.

Vopros ostayotsya chastichno proyasnyonnyim: ne vyibranyi realjnyiye postavsjhiki i adapteryi, granulyarnostj `free/busy`, sroki khraneniya i kriptograficheskij mekhanizm zasjhisjhyonnyikh ssyilok, pravila soglasiya drugikh uchastnikov, otraslevyiye i pravovyiye osnovaniya, a takzhe usloviya, pri kotoryikh zaraneye zadannaya politika avtonomii mozhet zamenitj otdeljnoye podtverzhdeniye.

## Zatronutaya dokumentaciya

- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Poljzovateljskaya istoriya kalendarya, raspisaniya i poyezdok cherez FUM](../Dokumentaciya/31-poljzovateljskiye-istorii-FUM/vesti-kalendari-i-planirovatj-poyezdki.md)
- [Pasport kalendarno-transportnogo servisnogo kontura lichnogo FUM-agenta](../Dokumentaciya/42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md)
- [Planovoye napravleniye interfejsa i servisnyikh adapterov](../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md)

## Istochniki trebovanij

- [iskhodnyij zapros o podgotovke pasporta kalendarno-transportnogo servisnogo kontura](../Zhurnal/2026-07-24_09-17-50_MSK_podgotovitj-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta/zapros.md)
- [iskhodnyij zapros 2026-07-03 09:03:59 MSK - Opisatj kalendarno transportnyiye dejstviya FUM](../Zhurnal/2026-07-03_09-03-59_MSK_opisatj-kalendarno-transportnyiye-dejstviya-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c3932896df20a90359597df8d451e855caae1fd17d6e82d534803e105a4dc624 -->
<!-- FUM-MD-RECENCY:END -->
