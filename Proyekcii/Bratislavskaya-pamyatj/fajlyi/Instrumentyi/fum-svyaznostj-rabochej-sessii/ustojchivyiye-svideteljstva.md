# Ustojchivyiye svideteljstva obrabotki

[Postanovka](https://github.com/fum-lab/fum/blob/b74e49b2b1a7a2a424e1d3445eb5a87ff57d9905/Журнал/2026-09-15_17-14-42_MSK_создать-устойчивые-свидетельства/запрос.md) trebuyet videtj avtomaticheskiye dejstviya i nastraivatj ikh cherez opisaniya strukturiruyusjhikh operatorov. Etot postavlyayemyij blok realizuyet nablyudayemyij Python-plan i yego primeneniye. Podklyucheniye dejstviya k [susjhestvuyusjhemu yazyiku](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Sources/FUMStructuringOperatorMemory/OpredeleniyeOperatora.swift) yesjhyo ne vyipolneno; pole `оператор` ne oznachayet takogo podklyucheniya.

## Opisaniye i plan

CLI `scripts/подготовить-свидетельства.py` imeyet obsjhiye parametryi `--корень-репозитория`, `--исходник`, `--codex-thread-id`. Komanda `план --описание <приватный JSON>` vozvrasjhayet obyyekt s `план` i `sha256`. Sam obyyekt `план` sokhranyayetsya otdeljno dlya `применить --план <приватный JSON> --ожидаемый-sha256 <хэш> --кэш <приватный путь>`.

Opisaniye soderzhit `каталог` vida `Журнал/<запрос>/материалы/<область>` i nepustoj uporyadochennyij spisok `решения`. Kazhdoye resheniye yavno zadayot `экземпляр`, `решение`, `актуальность`, `поздние`, `ответ`, `основание`, `допустимые_части_sha256`. Semantika znachenij i iskhodnyikh bajtovyikh svidetelej sootvetstvuyet [shtatnoj obrabotke](obrabotka-soobsjhenij.md). Posledneye pole — SHA-256 kanonicheskikh polnyikh iskhodnyikh chastej, vyichislennyikh susjhestvuyusjhim serializatorom chitatelya; peredacha oznachayet yavnyij vyibor publikacionno dopustimogo materiala agentom. Khyesh ne raspoznayot sekretyi i ne udostoveryayet avtora. Nedopustimyij original ne vyibirayetsya; yego redaktirovaniye ne yavlyayetsya polnyim svideteljstvom. Vlozheniya ne zagruzhayutsya.

Plan pokazyivayet poryadok dejstvij, polnyiye budusjhiye fajlyi s soderzhimyim i SHA-256, sformirovannyiye zapisi obrabotki, iskhodnyij prefiks istorii, rassmotrennuyu granicu istochnika, tochnyiye HEAD/ref/fizicheskij korenj i UUID zadachi. On nichego ne zapisyivayet. Opisaniye, plan, nativnyij istochnik, kyesh i polnyij instrumentaljnyij vyivod ostayutsya privatnyimi vne vsekh Git-predkov. Vyivod plana soderzhit vyibrannyij tekst: dlya boljshogo vyivoda ispoljzuyetsya susjhestvuyusjhij zakhvat, a ne perenos vsego JSON v kontekst modeli. Ozhidayemyij khyesh beryotsya iz rezuljtata planirovaniya, ne vyichislyayetsya zanovo iz nedoverennogo izmenyonnogo plana pered primeneniyem.

## Primeneniye i povtor

Ispolnitelj pered pervoj zapisjyu vosproizvodit plan iz istochnika i yavnyikh reshenij, proveryayet polnyij chelovecheskij kontekst, istoriyu i dopusk. Polnyiye iskhodnyiye chasti sokhranyayutsya v `команда.json`, vyibrannyiye bajtyi otveta i osnovaniya — v otdeljnyikh tekstovyikh fajlakh. Svideteli avtomaticheski okhvatyivayut eti fajlyi celikom. Povtornyiye odinakovyiye komandyi imeyut raznyiye identichnosti ekzemplyarov. Drugoye resheniye poluchayet otdeljnoye pokoleniye; susjhestvuyusjhiye nesovpadayusjhiye bajtyi ne perezapisyivayutsya.

Pole `поздние` sokhranyayet ssyilki na tochnyiye ekzemplyaryi nativnogo JSONL. Yesli pozdneye soobsjheniye ne vyibrano otdeljnyim resheniyem, yego iskhodnyiye chasti avtomaticheski ne kopiruyutsya i ono ne schitayetsya obrabotannyim. Dlya ustojchivoj kopii pozdnego originala agent otdeljno vyibirayet i dopuskayet etot ekzemplyar.

Zatem zapisi posledovateljno peredayutsya `сохранить_обработку` s iskhodnyim SHA istorii i vozvrasjhayemyimi SHA prefiksov. Paket ne yavlyayetsya obsjhej tranzakciyej. Rezuljtat soderzhit podtverzhdyonnyiye materialyi, rezuljtatyi otdeljnyikh sokhranenij, chislo raneye najdennyikh sobyitij, oshibku i priznak polnogo primeneniya. Utrata otveta ili prinuditeljnoye zaversheniye processa trebuyut povtornogo primeneniya togo zhe plana: sostoyaniye vosstanavlivayetsya iz fajlov i shtatnoj istorii, novyiye sobyitiya vmesto prezhnikh ne sochinyayutsya. Sovpavshij material povtorno sinkhroniziruyetsya; iskhodnyij izmenyayemyij otchyot posle sokhraneniya uzhe ne nuzhen dlya yego svideteljstva.

Chuzhoj khvost istorii, pozdnij chelovecheskij vvod, povrezhdeniye materiala, smena HEAD/ref ili fizicheskogo kornya zakryivayut primeneniye. Posle perekhoda na drugoj kommit trebuyetsya novoye osmyislennoye planirovaniye. V konce yesjhyo raz proveryayutsya vkhodyi i polnyij khvost paketa. Pri chastichnom otkaze spisok rezuljtatov — podtverzhdyonnyij prefiks, a ne dokazateljstvo otsutstviya sleduyusjhego effekta: zapisj mogla ustanovitjsya do utratyi otveta. Povtor utochnyayet fakticheskoye sostoyaniye.

Ispolnitelj predpolagayet doverennyij process i yedinstvennogo pisatelya dopusjhennogo dereva; proverka putej i khyeshej ne zasjhisjhayet ot vrazhdebnoj konkurentnoj podmenyi. Katalogi i fajlyi ustanavlivayutsya shtatnyim atomarnyim mekhanizmom. Kodyi CLI: `0` — plan postroyen libo paket primenyon, `3` — nablyudayemyij otkaz posle nachala primeneniya, `2` — oshibka vkhoda ili predvariteljnoj proverki. Pole `завершение_задачи_доказано` vsegda `false`; smyisl reshenij, dejstviteljnostj vyipolneniya poruchenij i zakryitiye obyazateljstv ostayutsya otdeljnyimi proverkami.

## Proverka i profilj

Adresnyij nabor: `python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_устойчивые_свидетельства.py`. On proveryayet CLI, otsutstviye zapisi pri planirovanii, vyibor ekzemplyarov, polnyiye chasti, navigaciyu, redakturu otchyota, smenu istorii i HEAD, pozdnij vvod, povrezhdeniye, chastichnoye primeneniye i poteryu otveta posle atomarnoj zapisi.

Otkryityij profilj: `python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/измерить-устойчивые-свидетельства.py`. Dva odinakovyikh soobsjheniya poluchayut ekvivalentnyiye smyislovyiye resheniya vruchnuyu i avtomaticheski. Izmeryayutsya vremya i vyizovyi chitatelya; sokrasjheniye mekhanicheskikh dejstvij rasschityivayetsya po yavno ukazannomu scenariyu, ne vyidayotsya za izmereniye chelovecheskogo vremeni ili tokenov. Avtomaticheskij putj vyipolnyayet dopolniteljnyiye proverki i sinkhronizaciyu, poetomu uskoreniye ispolneniya ne predpolagayetsya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 17:49:52 MSK -->
<!-- content-sha256: sha256:3a64739ee4355333c10efef9a0fd7c43d8d6217e0f3e3e5709ab8da41990a1f3 -->
<!-- FUM-MD-RECENCY:END -->
