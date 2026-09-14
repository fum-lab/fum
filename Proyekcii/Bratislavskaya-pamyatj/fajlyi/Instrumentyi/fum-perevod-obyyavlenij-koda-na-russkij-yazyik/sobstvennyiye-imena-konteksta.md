# Proveritj i perevesti sobstvennyiye imena rabochego konteksta

Konechnyij perechenj sokhranyayet vosemj sostavnyikh imyon s abbreviaturoj JSON i russkoj smyislovoj osnovoj. Kazhdaya zapisj ogranichena tochnyim putyom, yazyikom i vidom obyyavleniya; istochnik — iskhodnik v polnom Git-kommite i SHA-256 yego bajtov. Abbreviatura oboznachayet format predstavleniya. Ona ne prevrasjhayet sobstvennuyu funkciyu ili tip vo vneshnij API.

## Konechnaya oblastj isklyuchenij

V `общие/Python/поддержка_моделей.py` razreshenyi funkcii `проверить_JSON` i `разобрать_JSON`; v `порождённые/модели_ответа.py` — `из_JSON` i `в_JSON`. V `общие/Swift/ПоддержкаJSON.swift` razreshenyi tipyi `ЗначениеJSON`, `ПолеJSON`, `СтрогийРазборJSON` i funkciya `разобратьJSON`. Vse puti imeyut tochnyij prefiks `Проекты/рабочий-контекст/`.

Filjtr proveryayet [mashinnyij perechenj](abbreviaturyi-konteksta.json) posle postroyeniya obyyavlenij. Sobstvennoye razreshyonnoye imya vsyo yesjhyo dostupno obyichnoj karte pereimenovanij. Neizvestnyiye polya, povtor zapisi, nepodkhodyasjhij vid, pustaya prichina, nepodkhodyasjhij istochnik ili ssyilka v puti perechnya zakryivayut yego chteniye. Istoricheskiye Git-istochniki i khyeshi proverenyi pri sostavlenii perechnya; runtime ne izvlekayet i ne ispolnyayet istoricheskij kod. Izmeneniye oblasti trebuyet novogo soderzhateljnogo razbora.

## Soglasovannaya migraciya Swift

Komanda `scripts/перевести_имена_контекста.py` dopolnyayet obyichnuyu avtomatizaciyu odnim ogranichennyim sluchayem. Ona perevodit `допускаетNull` v `допускаетПустойМаркер`, lokaljnoye `null` v `допускПустогоМаркера`, a parametr i metku `base64` v `кодированноеОписание`. Strokovyiye klyuchi `"null"` i vneshnij `Data(base64Encoded:)` sokhranyayutsya.

Obyazateljnyi rovno chetyire puti: `СтруктурныйКонтракт.swift`, `ПорождениеМоделей.swift` vnutri `Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/`, a takzhe `общие/Swift/ПоддержкаМоделей.swift` i `проверки/ПроверкиОпераций.swift` vnutri `Проекты/рабочий-контекст/`. [Manifest prinyatogo vkhoda](../../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/materialyi/migraciya-imyon-konteksta.json) pokazyivayet skhemu `fum.миграция-имён-контекста.1` i tochnyiye iskhodnyiye khyeshi.

Dva fajla s obyyavleniyami prokhodyat obyichnyij mekhanizm kartyi. Dopolniteljnyij razbor trebuyet rovno chetyire obrasjheniya `поле.допускаетNull`, odnu metku vyizova `КонтрактМоделей(base64:)` i odin tochnyij strokovyij shablon konstruktora generatora. Stroka opredelyayetsya lekserom, poetomu kommentarij s pokhozhim tekstom ne yavlyayetsya shablonom. Ssyilki privyazanyi k pereimenovaniyu obyyavlenij togo zhe plana; sovpadeniye teksta v proizvoljnom drugom fajle ne razreshayet zapisj. Etot sposob ne yavlyayetsya universaljnyim razresheniyem vladeljcev Swift-svojstv.

V svoyom razreshyonnom checkout snachala podgotovjte plan i prochitajte budusjhiye khyeshi i chislo zamen:

```text
python3 -B Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести_имена_контекста.py план --корень-репозитория . --вход <манифест.json>
python3 -B Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести_имена_контекста.py применить --корень-репозитория . --вход <тот-же-манифест.json>
```

Nevernyij SHA, nepolnyij nabor, nepodtverzhdyonnaya rolj, inoye chislo ssyilok ili kolliziya zakryivayut podgotovku do zapisi. Primeneniye yesjhyo raz sveryayet vse iskhodnyiye khyeshi i ispoljzuyet atomarnuyu zamenu kazhdogo fajla obyichnoj avtomatizacii. Obsjhaya fajlovaya tranzakciya ne obesjhayetsya. Uzhe migrirovannyiye iskhodniki ne podkhodyat prezhnemu manifestu; pri preryivanii snachala sveryayut sokhranyonnyij plan i fakticheskiye bajtyi.

Posle primeneniya peresobirayut ispolnitelj strukturiruyusjhikh operatorov i vyizyivayut `Проекты/рабочий-контекст/породить-ответ.py`. Porozhdyonnyiye modeli vruchnuyu ne menyayutsya. Migraciya obnovlyayet sobstvennyij iskhodnyij interfejs konstruktora i yego izvestnyikh potrebitelej; vneshnyaya JSON-skhema otveta sokhranyayetsya. Polnyij snimok ostatka obnovlyayetsya otdeljno posle obsjhej klassifikacii.

## Proverki i vosproizvodimyij profilj

Adresnyiye testyi `test_аббревиатуры_контекста.py`, `test_роли_свифт.py` i `test_миграция_контекста.py` zapuskayutsya cherez obyazateljnuyu obyortku svoyej sessii. Oni proveryayut granicyi isklyuchenij, nastoyasjhiye obyyavleniya i lozhnyiye obrasjheniya, sovmestnuyu migraciyu, sokhrannostj strok i otkaz pri podmene vkhoda.

Profilj izmeryayet otdeljno polnyij plan chetyiryokh fajlov, leksiku i sbor obyyavlenij. Vlozhennyiye stadii ne skladyivayutsya s planom. Semj iskhodnyikh i semj povtornyikh izmerenij ispoljzuyut odinakovyiye vkhodnyiye i vyikhodnyiye khyeshi; kyeshirovaniye ne dobavlyalosj. Posle migracii prezhniye bajtyi vosproizvodyatsya v privatnoj vremennoj fiksture bez izmeneniya checkout:

```text
python3 -B Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/tests/измерить_имена_контекста.py --корень . --исходный-коммит c93b0fbca8c5d676eecec7023bc6df1a19c25b91 --манифест Журнал/2026-09-14_20-03-08_MSK_уточнить-собственные-имена-поставки/материалы/миграция-имён-контекста.json --выход <профиль.json>
```

Izvlecheniye istoricheskikh bajtov, import modulej i zapisj otchyota isklyuchenyi iz izmerenij. Ispoljzuyetsya tekusjhaya kanonicheskaya avtomatizaciya, istoricheskij ispolnyayemyij kod ne zapuskayetsya. Kriterij — mediana plana nizhe sekundyi pri ravnom rezuljtate i neizmennyikh vkhodakh. Zameryi okolo 25 ms obosnovali sokhraneniye prostogo algoritma; povtor bez izmeneniya algoritma ne obyyavlyayetsya uskoreniyem.

## Istochniki

- [Zapros i granica priyomki](../../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/zapros.md).
- [Pravila yazyika](../../Pravila/agentov/yazyik-i-kod.md).
- [Modelj otveta i porozhdeniye](../../Proyektyi/rabochij-kontekst/operatornyiye-modeli-otveta.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 21:05:29 MSK -->
<!-- content-sha256: sha256:adfec8ed3af62ce28cb02d7be932744bcb078ff34bf8dc02c5d3db1dee9b948b -->
<!-- FUM-MD-RECENCY:END -->
