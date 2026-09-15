# Otchyot 2026-09-15 00:46:36 MSK - Proveryatj polya zhurnala do polnoj svyaznosti

Podgotovlen otdeljnyij rannij vkhod proverki obyazateljnyikh polej zaprosa i otchyota. On ispoljzuyet funkcii dejstvuyusjhej svyaznosti i chitayet soderzhimoye toljko dvukh dokumentov. Polnaya svyaznostj i pravila ne izmenenyi. Uspekh malogo vkhoda ne yavlyayetsya dopuskom kommita.

## Proverki

Pervyij RED podtverdil otsutstviye modulya; posle realizacii proshli vosemj testov. Nezavisimyij obzor vyiyavil lozhnyij otkaz dlya markera v doslovnoj komande, zaschityivaniye skryitoj ssyilki i propusk podmenyi roditeljskoj papki. Zamechaniya vosproizvedenyi otricateljnyimi testami; posle ispravleniya proshli vse 11 testov. Pervonachaljnyij i povtornyij profili sokhranenyi otdeljno. Adresnyij skaner dopolniteljno obnaruzhil novoye imya `setUp`; podgotovka fiksturyi sdelana yavnoj russkoj funkciyej bez pereopredeleniya etogo metoda. Povtornyiye 11 testov i proverka shesti novyikh Python-fajlov proshli, novyikh latinskikh obyyavlenij net. Pervyij zapusk na svoyej pare obnaruzhil ostavlennyij marker v upravlyayemom bloke; vyipolnen shtatnyij predprosmotr pered povtorom.

Nachalo etapa snachala byilo otkloneno do zapisi: zagolovok soderzhal propisnuyu bukvu v slove «Zhurnal», togda kak iz zadannoj metki vyivoditsya «zhurnala». Peredan tochnyij zagolovok avtomatizacii s prezhnim vremennyim prefiksom; fajlyi sozdanyi shtatno.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Rannij funkcionaljnyij vkhod posle revjyu | Medianyi 2,23–2,27 ms | Pyatj par zapuskov na kazhdom iz tryokh odinakovyikh sinteticheskikh vkhodov |
| Polnyij obkhod na tom zhe vkhode | Medianyi 300,48–307,36 ms | Sravnivayutsya oshibki profilya; dopolniteljnyiye oshibki nepolnoj sinteticheskoj sessii sokhranenyi |
| Podgotovka i koordinaciya | Ne izmereno | Obsjhij monotonnyij interval ne vosstanavlivalsya |

Granica profilya: izmerenyi funkcii posle importa; podgotovka 1000 fonovyikh dokumentov isklyuchena. Eto vremya processa, ne tokenyi LLM i ne uskoreniye vsej priyomki. Vlozhennyiye intervalyi ne skladyivayutsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                              | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj FUMA] Zafiksirovatj otsutstviye rannego vkhoda proverki polej                | 0,14 s       | neuspeshno |
| [Korenj FUMA] Proveritj rannij vkhod na izvestnyikh propuskakh i granicakh chteniya       | 0,373 s      | uspeshno   |
| [Korenj FUMA] Izmeritj ranniye polya i polnyij obkhod na odinakovyikh dokumentakh         | 4,735 s      | uspeshno   |
| [Korenj FUMA] Vosproizvesti zamechaniya o citate i skryitoj ssyilke                    | 0,365 s      | neuspeshno |
| [Korenj FUMA] Vosproizvesti podmenu roditeljskoj papki mezhdu chteniyami              | 0,431 s      | neuspeshno |
| [Korenj FUMA] Podtverditj ispravleniye citat skryityikh ssyilok i podmenyi papki         | 0,417 s      | uspeshno   |
| [Korenj FUMA] Povtoritj profilj posle ustraneniya zamechanij                         | 4,989 s      | uspeshno   |
| [Korenj FUMA] Proveritj novyiye obyyavleniya i neizmennostj polnogo dopuska            | 0,204 s      | neuspeshno |
| [Korenj FUMA] Proveritj yavnuyu podgotovku fiksturyi bez novogo latinskogo obyyavleniya | 0,379 s      | uspeshno   |
| [Korenj FUMA] Podtverditj otsutstviye novyikh latinskikh obyyavlenij v shesti fajlakh     | 0,207 s      | uspeshno   |
| [Korenj FUMA] Proveritj polya tekusjhej paryi novyim komandnyim vkhodom                   | 0,146 s      | neuspeshno |
| [Korenj FUMA] Podtverditj polya sobstvennoj paryi posle shtatnogo predprosmotra       | 0,151 s      | uspeshno   |
| [Korenj FUMA] Proveritj reyestr posle sokhraneniya rannego vkhoda 0174                 | 0,45 s       | uspeshno   |
| [Korenj FUMA] Proveritj publikacionnuyu chistotu rannej proverki i yeyo svideteljstv   | 23,937 s     | neuspeshno |
| [Korenj FUMA] Zafiksirovatj otsutstviye publikacionnogo predstavleniya profilya       | 0,085 s      | neuspeshno |
| [Korenj FUMA] Proveritj ranniye polya i publikacionnoye predstavleniye profilya         | 0,443 s      | uspeshno   |
| [Korenj FUMA] Proveritj vosproizvodimyij eksport profilya bez vremennogo kornya       | 4,898 s      | uspeshno   |
| [Korenj FUMA] Proveritj publikaciyu posle vosproizvodimoj ochistki vremennogo kornya  | 24,865 s     | uspeshno   |
| [Korenj FUMA] Proveritj zavershyonnyij sostav rannego vkhoda i publichnyikh svideteljstv  | 24,961 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 92,176 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Resheniya i ogranicheniya

Publikacionnaya proverka obnaruzhila shestj vremennyikh putej v dvukh profilyakh. Sokhranenyi privatnyiye originalyi; publichnyiye fajlyi poluchenyi novyim vosproizvodimyim preobrazovatelem s tochnyimi iskhodnyimi SHA i sokhraneniyem vsekh chislovyikh izmerenij i vkhodnyikh khyeshej. Regressiya eksporta i posleduyusjhij novyij profilj proshli; obsjhij nabor teperj soderzhit 12 testov. Povtornaya publikacionnaya proverka uspeshna. Ogranichennoye vosstanovleniye zaregistrirovano v FUM-SBOJ-0129.

Tri funkcii rannego vkhoda razdelenyi po naznacheniyu: chteniye i proverka paryi, proverka puti, komandnaya obolochka. Privatnyij iskhodnyij JSONL ne vkhodit v fiksturyi. Soderzhimoye vneshnikh celej ssyilok ne chitayetsya. Vyikhod sokhranyayet SHA vkhodnyikh bajtov i vsegda soderzhit `полная_приёмка: false`.

Otdeljnyij rannij vkhod yesjhyo ne vklyuchyon avtomaticheski v obsjhij smoke. Zakryitiye FUM-STEP-0174 i polnaya priyomka novogo instrumenta ne zayavlenyi. Sleduyusjhiye shagi — shtatnyij dopusk i vklyucheniye rannego kontrolya pered dorogimi etapami; prioritetnoye obyyedineniye 0165 vyipolnyayetsya v otdeljnom dereve.

Sokhraneno prezhneye pokoleniye proyekcii prinyatogo master `e95d7f5d1ef6387454b7825932cfbd737e600473`: derevo `1381bb164ce2efa4a93722b3ddba2e400e418b50`, SHA manifesta `19a11ee2a3ebfc9720926768141ec100d2aa2bb60db0489edee4976c2addd976`, iskhodnyij inventarj `fc22006a6107369dd1735a909aa87fecb60001b4898e19fbe17897fdc3b981a6`. Otstavaniye ot novyikh fajlov sokhranyayetsya yavno; finaljnoj peresborki etogo etapa ne byilo.

## Istochniki

- [Ispravleniye eksporta vremennogo kornya](../../Sboi/FUM-SBOJ-0129-vremennyij-korenj-v-publikuyemom-profile.md).
- [Publichnyij profilj](materialyi/profilj-polej-publichnyij.json).
- [Sokhraneniye staryikh izmerenij](materialyi/proiskhozhdeniye-publichnyikh-profilej.json).

- [Doslovnyiye posleduyusjhiye otvetyi kornya](materialyi/otvetyi-kornya.jsonl).

- [Iskhodnyij zapros](zapros.md).
- [Opisaniye rannej proverki](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/rannyaya-proverka-paryi.md).
- [Pervoye izmereniye](materialyi/profilj-polej.json).
- [Povtor posle revjyu](materialyi/profilj-polej-posle-revjyu.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:14:49 MSK -->
<!-- content-sha256: sha256:ac7bf368761909a2bf62243f38a73cb91e5208ed90c42a89e94883871a046690 -->
<!-- FUM-MD-RECENCY:END -->
