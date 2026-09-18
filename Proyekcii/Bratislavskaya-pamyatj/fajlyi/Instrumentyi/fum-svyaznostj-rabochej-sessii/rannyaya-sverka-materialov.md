# Rannyaya sverka materialov etapa

Pered dorogoj priyomkoj komanda [sverki](scripts/sveritj-materialyi-etapa.py) obyyasnyayet propuski razdela «Povliyal na fajlyi» po polnomu tekusjhemu Git-perechnyu. Ona vyizyivayet susjhestvuyusjhiye `affected_files_from_request` i `validate_git_status`, proveryayet pryamyiye ssyilki na tekusjhiye zapros i otchyot i ne obkhodit Markdown vsego repozitoriya. Samostoyateljnoj zapisi, staging i rasshireniya oblasti ne vyipolnyayet.

## Podgotovitj vkhod i prochitatj rezuljtat

Iz sobstvennogo checkout podgotovjte vne Git JSON-massiv tochnyikh razreshyonnyikh otnositeljnyikh imyon fajlov. Vklyuchite soglasovannyiye iskhodniki, tekusjhuyu paru Zhurnala, mashinnyiye materialyi, navigaciyu, proizvodnyij indeks i fakticheskiye rezuljtatyi generatorov. Dlya udaleniya ukazyivayetsya prezhneye imya; dlya pereimenovaniya — oba imeni. Katalog, korenj, povtor ili putj za checkout ne razreshayutsya. Perechenj dolzhen otrazhatj prinyatoye resheniye ob oblasti: slepoye kopirovaniye vsego Git-statusa ne dokazyivayet razresheniya.

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/сверить-материалы-этапа.py --корень-репозитория . --запрос Журнал/<этап>/запрос.md --разрешённые-цели <приватный-перечень.json> --профиль
```

JSON v stdout soderzhit vse fakticheskiye puti, konkretnyiye oshibki i snimok `fum.ранний-охват.1`. Kod 0 oznachayet pokryitiye tekusjhego sostava, kod 1 — otkaz. Profilj v stderr izmeryayet monotonnuyu dliteljnostj sverki i ne menyayet JSON. Sokhranite stdout vne checkout: fajl rezuljtata vnutri proveryayemoj oblasti sam izmenit yeyo. Dlya povtornoj proverki pered dorogim zapuskom peredajte tot zhe perechenj i `--снимок <сохранённый-JSON>`.

Snimok svyazyivayet khyesh fizicheskogo kornya, polnyij ref i HEAD, vesj Git-index, polnyij porcelain-status, imena i bajtyi razresheniya, rezhimyi i SHA-256 fajlov, sostav razreshayusjhikh katalogov i zagruzhennyiye proyektnyiye moduli. Proveryayutsya iskhodnyiye razobrannyiye bajtyi zaprosa i povtornoye nablyudeniye vkhodov do vyidachi. Izmeneniye posle sverki trebuyet novogo rezuljtata; staryij ne stanovitsya dopuskom novogo pokoleniya. Posle generacii proyekcii i poslednej zapisi vyipolnite sverku zanovo.

## Ispravitj otkaz

Dobavjte v tekusjhij razdel toljko obosnovannyiye tochnyiye Markdown-ssyilki ili susjhestvuyusjhiye markeryi udaleniya, zatem povtorite sverku. Ssyilka v drugom razdele ne dayot pokryitiya; ssyilka na katalog ne zamenyayet pryamyiye ssyilki na tekusjhuyu paru. Korenj repozitoriya zapresjhyon. Katalog pokryivayet toljko svoikh potomkov po prezhnemu validatoru, no nezavisimyij perechenj razreshayet toljko konechnyiye imena. Pokhozhiye prefiksyi, sosedniye materialyi i postoronniye fajlyi ostayutsya oshibkami.

Doslovnyiye bloki i zakryityiye otchyotyi ne izmenyayutsya. Simvolicheskiye ssyilki v iskhodnyikh komponentakh Markdown-celi zapresjhenyi do svorachivaniya `..`; URL-kodirovaniye, query i fragment razbirayutsya v tom zhe poryadke, chto u shtatnogo resolver. Pereimenovaniya uchityivayut iskhodnoye imya otdeljno. Imena s perevodom stroki ili bukvaljnoj ` -> ` poka zakryito otklonyayutsya iz-za postrochnogo kontrakta susjhestvuyusjhego validatora.

## Granica rezuljtata

Eto yavnyij deshyovyij vkhod, a ne zamena svyaznosti, publikacionnoj proverki, polnogo dopuska ili proverki smyisla razreshenij. Komanda ne podklyuchena k hooks ili avtomaticheskim prodolzheniyam. Proveryayetsya nablyudayemaya stabiljnostj v rezhime odnogo pisatelya, ne atomarnaya tranzakciya protiv proizvoljnogo konkurentnogo processa. Soglasovannaya podmena snimka ne predotvrasjhayetsya kriptograficheskoj podpisjyu.

Avtomaticheskoye izvlecheniye prinyatogo dochernego sostava iz proverennogo manifesta perenosa i podgotovka budusjhego pokoleniya ostayutsya za predelami etogo ogranichennogo sreza. Ikh tochnyiye rezuljtatyi peredayutsya susjhestvuyusjhim konechnyim perechnem posle nezavisimoj proverki proiskhozhdeniya; sam spisok ne obyyavlyayetsya proverennyim manifestom perenosa. Poetomu vsya kartochka STEP-0225 i sistemnyij sboj zdesj ne zakryivayutsya.

Adresnyiye regressii: `python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_ранний_охват.py`. Profilj: `python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_раннего_охвата.py`. Oba zapuska vyipolnyayutsya cherez otchyotnuyu obyortku sobstvennoj sessii. Profilj sozdayot 1002 fajla, isklyuchayet podgotovku i trizhdyi izmeryayet CLI s odinakovyimi vkhodami; kyesh OS ne ochisjhayetsya. Sokrasjheniye povtornyikh polnyikh obkhodov i uskoreniye smoke-check etim scenariyem ne izmeryayutsya.

## Polya paryi pered dorogim zapuskom

Obsjhij smoke-check s proverkoj sessii teperj pervyim ispolnyayemyim shagom vyizyivayet susjhestvuyusjhij `проверить-поля-журнала.py`. Rannij vkhod proveryayet obyazateljnyiye polya, profilj i pryamyiye ssyilki na obe roli imenno v «Povliyal na fajlyi»; ssyilka na katalog, kommentarij, primer koda ili drugoj razdel ikh ne zamenyayet. Eto drugaya granica, chem perechisleniye vsekh izmenyonnyikh fajlov: komandyi dopolnyayut drug druga.

Otdeljnyij vyizov: `python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-поля-журнала.py --корень . --запрос Журнал/<stem>/запрос.md`. Ispoljzujte otchyotnuyu obyortku svoyej sessii. Kod 0 podtverzhdayet toljko polya, 1 oznachayet najdennyiye oshibki, 2 — nekorrektnyij vkhod. Ispravjte perechislennyiye polya i obnovite predprosmotr. Zakryityij otchyot ne otkryivayetsya etim instrumentom.

## Istochniki

- [Porucheniye i utochneniya](../../Zhurnal/2026-09-18_11-55-00_MSK_sveryatj-materialyi-etapa-do-priyomki/zapros.md).
- [Soglasovannaya kartochka](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0225-sveryatj-polnyij-sostav-materialov-etapa.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 01:06:21 MSK -->
<!-- content-sha256: sha256:a302e9601daebf33efff87b9a967aa693bdc3b0ad1c169ca27da65111272cfcb -->
<!-- FUM-MD-RECENCY:END -->
