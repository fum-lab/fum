# Inventarizaciya obyyavlenij koda

Susjhestvuyusjhij programmnyij sloj FUM neljzya bezopasno perevesti odnoj globaljnoj tekstovoj zamenoj. Audit razdelyayet sobstvennyiye obyyavleniya, vneshniye yazyikovyiye i sistemnyiye kontraktyi, doslovnyiye istochniki i sobstvennyiye mashinnyiye formatyi, kotoryim trebuyetsya otdeljnaya versionirovannaya migraciya. Tochnyij vremennyij ostatok posle poyavleniya avtomatizacii khranitsya v yeyo mashinochitayemom snimke; privedyonnyiye nizhe chisla fiksiruyut nezavisimyij iskhodnyij srez i obyyasnyayut dekompoziciyu.

## Svodka iskhodnogo sreza

| Oblastj                       | Sobstvennyij obyyom                                             | Nablyudayemyij latinskij ostatok                                                                                      | Granica                                                                                         |
| ----------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| Swift                         | 160 fajlov, 93 272 stroki                                     | ne meneye 23 908 yavno napisannyikh obyyavlenij; kirillicheskikh imyon ne najdeno                                          | 83 fajla vneshnego submodule LinguisticKit ne otnosyatsya k kornevoj migracii                      |
| Python                        | 67 fajlov, 56 988 strok                                       | 16 655 latinskikh obyyavlenij i privyazok iz 16 703; 4 927 razlichnyikh latinskikh imyon                                   | vneshniye API, specialjnyiye metodyi, khuki i stabiljnyiye CLI ili wire-imena sokhranyayutsya kak kontraktyi |
| Markdown fenced-bloki         | 1 120 fajlov, 1 333 zakryityikh bloka                            | 469 latinskikh leksicheskikh kandidatov Mermaid v 48 blokakh; yesjhyo 13 smyislovyikh blokov formul ili psevdokoda            | doslovnyiye zaprosyi, vneshniye istochniki, citatyi i istoricheskiye snimki ne perepisyivayutsya            |
| Markdown vstroyennyiye fragmentyi | 11 455 vkhozhdenij s latinicej vne osnovnyikh zasjhisjhyonnyikh oblastej | 7 147 pokhozhikh na odinochnyiye identifikatoryi v 420 fajlakh; eto shirokij nabor kandidatov, a ne dokazannoye chislo oshibok | komandyi, puti, vneshniye API i mashinnyiye polya trebuyut klassifikacii po yavnoj karte                 |

Swift-srez dopolniteljno vklyuchayet okolo 4 071 publichnogo obyyavleniya, 473 tipa s `Codable`, 282 specialjnyikh perechisleniya `CodingKeys`, 398 perechislenij so strokovyim bazovyim znacheniyem i 1 489 yavno zadannyikh strokovyikh variantov. Poetomu perevod svojstv i variantov bez staryikh wire-znachenij izmenil byi kanonicheskiye JSON-bajtyi i khyeshi.

Python-srez vklyuchayet 135 klassov, 1 917 funkcij, 3 178 parametrov, 11 381 privyazku peremennyikh, 92 prisvaivayemyikh atributa, 67 `dataclass` i 264 ikh polya. Globaljnaya zamena zadela byi 3 968 imenovannyikh argumentov, dinamicheskiye `getattr`, importnyiye granicyi, `argparse` i 568 nablyudayemyikh ASCII-klyuchej slovarej.

## Vosproizvodimaya mashinnaya granica

Lokaljnaya avtomatizaciya stroit polnyij kanonicheskij inventarj i khranit v [snimke ostatka](../../../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json) yego SHA-256, obsjheye chislo i svodku. Na moment fiksacii granica sostavlyayet 43 362 nablyudayemyikh obyyavleniya: 16 359 Python, 26 534 Swift i 469 Mermaid; otpechatok — `sha256:8e1f5c863b16a62313a2f5287a23f77ee5b0cf0c1eac69a0ea5926960f2855f9`.

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py инвентаризировать --корень-репозитория .
~~~

Eta mashinnaya granica poka okhvatyivayet Python, Swift i Mermaid, a ne vesj repozitorij. Otdeljnyij srez vne katalogov zavisimostej i istochnikov nashyol takzhe 11 fajlov shell, 5 JSONL, 4 YAML, 2 HTML i 1 MLIR; mashinnyiye JSON- i drugiye skhemyi trebuyut otdeljnoj klassifikacii kontraktov. Polnota pravila dlya ostaljnyikh formatov ne zayavlyayetsya do TDD-rasshireniya inventarya.

## Zasjhisjhyonnyiye oblasti Markdown

- 235 tekstovyikh blokov v 203 fajlakh `Журнал/**/запрос.md` sokhranyayut doslovnoye proiskhozhdeniye.
- 818 blokov v 11 fajlakh `Источники/URL/**` sokhranyayut vneshniye snimki.
- Chetyire doslovnyikh voprosa v `Вопросы и ответы/` i 22 istoricheskikh Git-snimka v zhurnaljnyikh revjyu ne yavlyayutsya redaktiruyemyimi primerami.
- Sobstvennyiye JSON- i TOML-skhemyi perevodyatsya toljko vmeste s parserami, pisatelyami, fiksturami i novyim pokoleniyem formata.

## Resheniye po migracii

Pervaya postavka zakreplyayet pravilo i rabotayusjhuyu lokaljnuyu TDD-avtomatizaciyu. Avtomatizaciya stroit tochnyij ostatok, zapresjhayet yego nezametnoye uvelicheniye ili zamenu i primenyayet toljko yavnyiye kartyi imyon pri sovpavshem khyeshe vkhoda. Sam snimok ne yavlyayetsya postoyannyim isklyucheniyem: kartochki prodolzheniya otdeljno dovodyat Markdown, Python, Swift i ostaljnyiye sobstvennyiye formatyi do nulevogo neobosnovannogo ostatka, sokhranyaya vneshniye i versionirovannyiye granicyi.

Paralleljnyiye audityi vyipolnenyi odnoj modeljnoj semjyoj raznyimi metodami: Swift-kompilyatorom i leksicheskim srezom, Python AST i strukturnyim razborom Markdown. Ikh soglasiye ne schitayetsya nezavisimyim vneshnim podtverzhdeniyem; resheniye osnovano na nablyudayemom inventare fajlov, yazyikovyikh kontraktakh i vosproizvodimoj avtomaticheskoj proverke.

## Istochniki

- [tekusjhij iskhodnyij zapros](../../zapros.md)
- [pravila yazyika obyyavlyayemogo koda](../../../../AGENTS.md)
- [avtomatizaciya perevoda obyyavlenij koda](../../../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md)
- [kartochki prodolzheniya](../../../../Planirovaniye/kartochki-shagov/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 14:04:20 MSK -->
<!-- content-sha256: sha256:26c96a6be94ad914f2f4fa8099ed9b76c474084e4e7340ef74c0d39f41bda18d -->
<!-- FUM-MD-RECENCY:END -->
