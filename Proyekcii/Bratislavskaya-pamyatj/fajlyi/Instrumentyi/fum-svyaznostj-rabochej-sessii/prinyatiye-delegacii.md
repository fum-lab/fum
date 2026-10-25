# Yavnoye prinyatiye porucheniya koordinatora

[Priyom](scripts/priyom_delegacii.py) sokhranyayet odin otdeljnyij akt prinyatiya v `Планирование/задачи/<UUID-исполнителя>/принятие-делегации.json`. [Dopusk](scripts/proveritj-prodolzheniye-zadachi.py) proveryayet yego pokryitiye rabotoj susjhestvuyusjhego sobstvennogo plana v1. Nulevoj ostatok chelovecheskikh soobsjhenij ne skryivayet prinyatoye porucheniye bez rabotyi.

Do prinyatiya vyizyivayusjhij nezavisimo vyibirayet JSON s polyami `координатор`, `исполнитель`, `коммит`, `путь`, `sha256`. Polnyij OID vyibirayet neizmenyayemyij kommit koordinatora, putj — obyichnyij fajl porucheniya v nyom, SHA-256 — yego polnyiye iskhodnyiye bajtyi. Etot nabor peredayotsya kak `--доверенное-поручение '<JSON>'`; yego neljzya izvlekatj iz proveryayemoj zapisi prinyatiya. Guard takzhe podderzhivayet `FUM_DELEGATION_TRUST`: latinskoye imya nuzhno dlya perenosimogo naznacheniya peremennoj okruzheniya POSIX shell. Yavnyij CLI imeyet prioritet. XML, proizvoljnyij vyivod instrumenta i razgovornoye «prinyato» ne vyibirayut doverennyij istochnik.

Koordinatorskij fajl imeyet skhemu `fum.поручение-координатора.1` i polya `координатор`, `исполнитель`, `работа`, `поручение`. Posledneye soderzhit nepustoye `действие` i spisok strok `ограничения`. Proverka chitayet polnyij DAG vyibrannogo kommita cherez prezhnij chitatelj v3 i yego nezavisimo zakreplyonnyij genezis. Kornevaya rabota dolzhna byitj dostupna v vyibrannom snimke. Rabocheye derevo koordinatora ne chitayetsya; vyibrannyij kommit ne obyazan byitj predkom HEAD ispolnitelya. Eto podderzhka odnogo zakreplyonnogo koordinatora, a ne proizvoljnyikh kornej.

Otdeljnyij yavnyij akt imeyet skhemu `fum.принятие-делегации.1` i rovno sleduyusjhiye polya:

- `выбранное_поручение` — tochnaya kopiya nezavisimo peredannogo nabora, proveryayemaya po nemu;
- `корневая_работа`, `корневое_основание` — susjhestvuyusjhaya rabota i yeyo proverennoye chelovecheskoye osnovaniye iz vyibrannogo reyestra;
- `план` — tochnyij otnositeljnyij putj sobstvennogo plana v1;
- `работа` — sobstvennyiye `идентификатор`, `действие`, `основание`. Dejstviye sovpadayet s porucheniyem ispolnitelyu. Osnovaniye sokhranyayet nastoyasjhij sobstvennyij UUID i doslovnyij zapros; chuzhoye kornevoye osnovaniye khranitsya otdeljno.

Poryadok zapuska:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/приём_делегации.py --корень-репозитория . --codex-thread-id <UUID-исполнителя> --доверенное-поручение '<независимо выбранный JSON>' --запись <подготовленный-акт.json>
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py --корень-репозитория . --codex-thread-id <UUID-исполнителя> --доверенное-поручение '<тот же независимо выбранный JSON>' --план <план.json> --исходник <собственный-JSONL> --перед-завершением --профиль
```

Priyom vyipolnyayet sozdaniye pri ozhidayemom otsutstvii libo idempotentnyij povtor tochnyikh bajtov, ispoljzuya privatnyij Git-zamok, povtornuyu sverku vkhodov, atomarnuyu zamenu i sinkhronizaciyu katalogov. Drugoye prinyatiye poverkh susjhestvuyusjhego zapresjheno. Operaciya ne registriruyet chelovecheskoye soobsjheniye i ne menyayet plan. Posle neyo obyichnyim izmeneniyem sobstvennogo plana registriruyetsya rabota s temi zhe tremya neizmenyayemyimi polyami, sostoyaniyem `доступна` i `свидетельство: null`.

Do registracii rabotyi guard vozvrasjhayet kod 2 s ukazaniyem nepokryitogo prinyatiya. Pri dostupnoj rabote on vozvrasjhayet kod 3 i yeyo identifikator po obyichnomu poryadku plana. Podmena opredeleniya, drugoj plan, otsutstviye nezavisimogo vkhoda pri susjhestvuyusjhem prinyatii, udaleniye libo izmeneniye prinyatiya na lyubom roditeljskom rebre dostizhimogo DAG dayut otkaz. Pered vyivodom povtorno sveryayutsya istochnik porucheniya, lokaljnyiye vkhodyi i HEAD. Proverennyij neizmenyayemyij koordinatorskij DAG vtoroj raz ne obkhoditsya. Eto nablyudayemaya stabiljnostj, a ne tranzakciya protiv proizvoljnogo vneshnego pisatelya.

Nezavisimo vyibrannoye porucheniye trebuyet susjhestvuyusjhej zapisi prinyatiya: bez neyo kod 2, v tom chisle posle udaleniya yesjhyo ne zakommichennogo fajla. Vyizyivayusjhij sokhranyayet vyibrannyij nabor vo vsekh posleduyusjhikh vyizovakh. Do pervogo kommita odnovremenno utrachennyiye fajl i vneshnij vkhod neotlichimyi ot otsutstviya delegacii; eto okno ne zakryito odnim fsync fajla. Komanda priyoma podtverzhdayet zapisj na disk, no ne zakrepleniye Git-istorii ili nativnoj konfiguracii. Posle kommita udaleniye zapisi obnaruzhivayetsya i bez peredannogo vyibrannogo vkhoda.

Polnota ogranichena sokhranyonnyim proveryayemyim prinyatiyem. Nesokhranyonnyiye razgovornyiye prinyatiya avtomaticheski ne obnaruzhivayutsya. Sostoyaniye rabotyi ostayotsya toljko v v1: yego svobodnoye svideteljstvo zaversheniya ne stanovitsya zakryitoj priyomkoj koordinatora. Reyestr v3 i kornevaya priyomka ne izmenyayutsya. Podderzhka neskoljkikh prinyatij, ikh migracii i snyatiya v etot kontrakt ne vkhodit. Podtverzhdyonnaya chelovecheskaya ostanovka sokhranyayet prioritet.

Adresnyiye scenarii vosproizvodyatsya cherez otchyotnuyu obyortku komandoj `python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_приём_делегации.py`. [Izmereniye realjnogo vkhoda](../../Zhurnal/2026-09-16_16-25-45_MSK_svyazatj-prinyatiye-delegacii-s-rabotoj/otchyot.md) pokazalo 3,318 s posle optimizacii: byudzhet Stop 3 s ne podtverzhdyon. Nativnoye podklyucheniye i Trust etim rezuljtatom ne dokazyivayutsya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 16:55:43 MSK -->
<!-- content-sha256: sha256:1abd980c28441e3497d3f315fd052d21f311d08034f1bbff38498e578204e137 -->
<!-- FUM-MD-RECENCY:END -->
