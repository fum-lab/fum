# Rasshireniye shablonov i sozdaniye voprosa

Avtomatizaciya ustanavlivayet opisaniye tipa i yego khranimyij shablon po tochnomu predprosmotru. Zatem ona sozdayot vopros iz yavno zapolnennyikh dannyikh. Odinakovyiye vkhodyi, zavisimosti i rezhimyi fajlov dayut odinakovyiye bajtyi plana i dokumenta; povtornoye primeneniye proverennogo rezuljtata nichego ne zapisyivayet.

Sejchas podderzhivayetsya semejstvo otkryityikh voprosov. U nego obyazateljnyi neodnoznachnostj, voprosyi dlya proyasneniya, istochniki trebovanij i razdel «Zatronutaya dokumentaciya». Novyij tip mozhet dobavlyatj smyislovyiye razdelyi mezhdu osnovnyim soderzhaniyem i istochnikami. Izmeneniye ustanovlennogo tipa trebuyet sleduyusjhej celoj versii i sokhranyayet prezhniye polya v prezhnem poryadke. Proizvoljnyiye tipyi dokumentov, izmeneniye shablonov zaprosa i otchyota i avtomaticheskaya migraciya susjhestvuyusjhej prozyi etim interfejsom ne podderzhivayutsya.

Nuzhen Python 3.10+ i obyichnyij checkout FUM. Samo rasshireniye ne vyizyivayet modelj, Git, setj, Swift ili proyekciyu. Obyichnaya repozitornaya priyomka ispoljzuyet obyyavlennyiye zavisimosti FUM otdeljno.

## Ustanovitj ili rasshiritj tip

Nachnite s [gotovogo opisaniya voprosa](primeryi/rasshireniye-voprosa.json). V nyom nakhodyatsya imya tipa, osnovaniye `вопрос`, versiya, uporyadochennyiye razdelyi s imenami polej i polnyij tekst shablona. Shablon soderzhit H1 s polem `заголовок`, vvodnoye pole `кратко`, zatem po odnomu polyu pod kazhdyim H2. Podderzhivayetsya imenno pokazannaya grammatika s pustyimi strokami i zavershayusjhim LF: skryityiye zagolovki, proizvoljnyiye karkasyi, povtornyiye ili neizvestnyiye polya otklonyayutsya.

Chtobyi dobavitj sovmestimyij tip, zadajte novoye russkoye imya v `тип` i versiyu 1. Chtobyi dobavitj razdel k susjhestvuyusjhemu tipu, uvelichjte versiyu na odin i vnesite sootvetstvuyusjhiye razdel i pole v oba mesta opisaniya. Smyisl novogo polya opredelyayet avtor opisaniya.

Iz kornya FUM vyipolnite komandyi nizhe. Perenapravlyajte plan i nablyudeniye v vyibrannyij vremennyij katalog vne Git. Vo vsekh komandakh zamenite `<временный-каталог>` na putj zaraneye sozdannogo vremennogo kataloga vne Git.

```bash
python3 -B Инструменты/fum-struktura-papok-zaprosov/scripts/расширение_шаблонов.py \
  план-расширения --корень-репозитория . \
  --вход Инструменты/fum-struktura-papok-zaprosov/примеры/расширение-вопроса.json \
  > "<временный-каталог>/план.json" 2> "<временный-каталог>/наблюдение-плана.json"
```

Plan pokazyivayet kazhduyu operaciyu: otnositeljnyij putj, prezhnij tekst, tochnyij unified diff, SHA-256 i rezhim do i posle. `результаты` okhvatyivayet takzhe neizmenyayemyiye vyikhodnyiye fajlyi; `зависимости` svyazyivayet primenimyiye pravila, fakticheski ispolnyayemyij kod, bazovyiye shablonyi, ustanovlennyij tip i prochitannyiye ssyilki. Izuchite `diff` i vkhod plana, zatem primenite **tot zhe fajl**:

```bash
python3 -B Инструменты/fum-struktura-papok-zaprosov/scripts/расширение_шаблонов.py \
  применить --корень-репозитория . --вход "<временный-каталог>/план.json" \
  > "<временный-каталог>/квитанция.json" 2> "<временный-каталог>/наблюдение-применения.json"
```

Rezuljtat ustanovki — [opisaniye tipa](tipyi/vopros.json) i [shablon voprosa](shablonyi/vopros.md.shablon). V etoj postavke oni uzhe ustanovlenyi cherez dannyij interfejs; povtor primera dast pustoj plan. Kvitanciya soderzhit khyesh primenyonnogo plana, chislo zapisannyikh fajlov i priznak povtora. Yesli vkhodyi izmenilisj, komanda soobsjhayet «plan ustarel» i trebuyet novogo predprosmotra.

## Sozdatj vopros

Skopirujte [primer dannyikh](primeryi/dannyiye-voprosa.json) v svoj vremennyij katalog i zamenite vse primernyiye znacheniya fakticheskimi. Ukazhite novyij neposredstvennyij putj `Вопросы/<имя>.md`. Primer soderzhit uslovnuyu ssyilku na `Документация/модель.md`: eto otkryitaya testovaya fikstura, takogo dokumenta ne sozdayut radi proverki.

Vse smyislovyiye polya obyazateljnyi i ne mogut sostoyatj toljko iz kommentariya, koda ili markera nezapolnennogo shablona. V `источники` nuzhna dejstvuyusjhaya ssyilka, v `документация` — khotya byi odna lokaljnaya ssyilka na susjhestvuyusjhij Markdown-fajl. Do zapuska `план-документа` podgotovjte v soglasovannoj oblasti obratnyiye ssyilki iz zatronutyikh dokumentov na budusjhij vopros. Avtomatizaciya proveryayet etu svyazj, no ne dopisyivayet chuzhuyu prozu. Ssyilki peredayutsya otnositeljno budusjhego fajla voprosa i sokhranyayutsya bukvaljno; yakorj bez fajlovogo puti ne podkhodit.

```bash
python3 -B Инструменты/fum-struktura-papok-zaprosov/scripts/расширение_шаблонов.py \
  план-документа --корень-репозитория . --вход "<временный-каталог>/данные-вопроса.json" \
  > "<временный-каталог>/план-документа.json" 2> "<временный-каталог>/наблюдение-документа.json"
python3 -B Инструменты/fum-struktura-papok-zaprosov/scripts/расширение_шаблонов.py \
  применить --корень-репозитория . --вход "<временный-каталог>/план-документа.json"
```

Na otkryitoj fiksture poluchayetsya dokument s iskhodnoj strokoj `Сохраняется ё и {{заголовок}}.`, razdelami «Neodnoznachnostj», «Voprosyi dlya proyasneniya», «Istochniki trebovanij» i «Zatronutaya dokumentaciya», a takzhe iskhodnyimi ssyilkami. Bukvaljnoye `{{заголовок}}` iz znacheniya ne vyipolnyayetsya povtorno. Polnyij ozhidayemyij tekst zadan nezavisimo ot realizacii v [predmetnyikh testakh](tests/test_rasshireniye_shablonov.py).

Posle sozdaniya vklyuchite vopros v sootvetstvuyusjhij razdel indeksa `Вопросы/README.md`, obnovite recency shtatnyimi sredstvami i proverjte sokhranyonnyiye ssyilki. Dlya novogo voprosa chuzhiye tekstyi, indeks i sluzhebnyiye metki avtomaticheski ne menyayutsya. Priyomku vyipolnyayet susjhestvuyusjhij validator voprosov; standartnyij smoke proveryayet obyazateljnyiye polya i obratnyiye ssyilki **do** generacii proyekcii. Povrezhdyonnyij ustanovlennyij shablon otklonyayetsya yesjhyo proverkoj strukturyi papok.

## Otkazyi i granicyi zapisi

Planirovaniye toljko chitayet fajlyi. Primeneniye polnostjyu pereproveryayet plan, tochnyiye rezuljtatyi, zavisimosti i razreshyonnyiye puti do zapisi. Simvolicheskiye ssyilki, vyikhod za checkout, registrovyiye kollizii, nepodderzhivayemyij tip, povrezhdyonnyij JSON, nesovmestimaya versiya i izmenyonnyij predprosmotr zavershayut komandu nenulevyim kodom. Neizmenyonnyij susjhestvuyusjhij dokument dopuskayet povtor; otlichayusjhijsya dokument poluchayet otkaz «migraciya ne podderzhivayetsya». Zakryityij Zhurnal ne yavlyayetsya razreshyonnyim naznacheniyem.

Podstanovka i fajlovaya tranzakciya pereispoljzuyut susjhestvuyusjhij `request_folder_layout.py`. Pri obyichnom isklyuchenii ustanovki vosstanavlivayutsya prezhniye bajtyi i rezhimyi, udalyayutsya novyiye fajlyi i pustyiye sozdannyiye katalogi. Eto ne obesjhaniye atomarnosti neskoljkikh fajlov pri otklyuchenii pitaniya, SIGKILL, postoyannoj neispravnosti fajlovoj sistemyi ili vrazhdebnoj konkurentnoj podmene putej. Rabochij kontrakt predpolagayet odnogo pisatelya dereva. SHA-256 obnaruzhivayet rassoglasovaniye, no ne udostoveryayet avtora soglasovanno perepisannogo plana. Plan soderzhit iskhodnoye soderzhaniye: pered publikaciyej proveryajte yego naravne s dokumentom.

## Nablyudeniye i vosproizvedeniye

stdout soderzhit toljko plan ili kvitanciyu. stderr soderzhit diagnosticheskiye soobsjheniya i otdeljnyij JSON nablyudeniya: kalendarnyiye UTC-granicyi, monotonnyiye dliteljnosti, iskhodyi i roditeljskiye nomera etapov. CPU otnositsya k tekusjhemu processu; vlozhennyiye intervalyi ne skladyivayutsya povtorno. RSS, I/O i nakladnyiye raskhodyi bez otdeljnogo izmereniya oboznachenyi `unknown`, a ne nulyom. Nablyudeniye ne vkhodit v proveryayemyiye bajtyi plana. Nedostupnyij stderr ne menyayet iskhod samoj komandyi; sokhrannostj nablyudeniya v takom sluchaye ne podtverzhdayetsya.

Predmetnyiye proverki i profilj zapuskayutsya cherez otchyotnuyu obyortku svoyej rabochej sessii. Vlozhennyiye komandyi:

```bash
python3 -B -m unittest discover -s Инструменты/fum-struktura-papok-zaprosov/tests -p test_расширение_шаблонов.py
python3 -B Инструменты/fum-struktura-papok-zaprosov/tests/профиль_расширения.py --повторы 10
```

Profilj sokhranyayet tochnyiye khyeshi realizacii i fiksturyi, versiyu Python, arkhitekturu, usloviya kyesha, vse povtoryi s otkazami i otdeljnyij pik RSS processa. Na pervom izmerenii maksimumyi uspeshnyikh operacij ne prevyisili 7,7 ms pri zaraneye zadannoj granice 100 ms na maloj fiksture. Resheniye — sokhranitj algoritm; uskoreniye ne zayavlyayetsya. Etot rezuljtat ne rasprostranyayetsya na massovuyu migraciyu, kotoroj zdesj net. Perenos proverki voprosov pered proyekciyej isklyuchayet yeyo nenuzhnyij zapusk pri rannem otkaze; stoimostj samoj proyekcii dannyim profilem ne izmeryayetsya.

## Istochniki i svideteljstva

- [Iskhodnaya postanovka](../../Zhurnal/2026-09-11_10-20-32_MSK_sokhranitj-postanovku-integracii-i-nablyudeniya/zapros.md), commit `10dc3b2149d2121c1d02926ca409c1299f2b4b5c`.
- [Zapros realizacii](../../Zhurnal/2026-09-11_10-36-27_MSK_avtomatizirovatj-rasshireniye-shablonov/zapros.md).
- [Otkryityiye plan, primeneniye, nablyudeniya i profilj](../../Zhurnal/2026-09-11_10-36-27_MSK_avtomatizirovatj-rasshireniye-shablonov/materialyi/).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:39:29 MSK -->
<!-- content-sha256: sha256:db916ea84a2080db71a3ba6a8b90f7094a8c8ea67f36dff0a998191dd46d4941 -->
<!-- FUM-MD-RECENCY:END -->
