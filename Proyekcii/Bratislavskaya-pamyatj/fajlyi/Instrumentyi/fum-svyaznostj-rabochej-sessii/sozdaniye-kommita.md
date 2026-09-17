# Sozdatj proverennyij kommit kontroljnoj tochki

Komanda podgotavlivayet soobsjheniye iz realjnyikh poljzovateljskikh komand i nablyudayemoj istorii modeli, zatem sozdayot odin lokaljnyij kommit posle proverki indeksa i obyazateljnyikh proverok. Ona sokhranyayet email avtora i dannyiye committer, menyaya toljko `GIT_AUTHOR_NAME` na yavno naznachennuyu rolj. Podderzhanyi obyichnyij kommit i nastoyasjheye sliyaniye s dvumya uporyadochennyimi roditelyami.

Eto polnyij putj sozdaniya **kontroljnoj tochki razreshyonnoj postoyannoj zadachi**. Itogovyij rezhim poka zakryito otkazyivayet: yesjhyo trebuyetsya otdeljnoye proverennoye vklyucheniye odnokratnogo zamyikaniya proyekcii po pravilu 000188. Proverennaya kontroljnaya tochka ne oznachayet itogovuyu priyomku, zaversheniye zadachi, integraciyu v `master` ili publikaciyu. Komanda ne sozdayot zadach, raspisanij ili hooks.

## Podgotovitj vkhod

Rabotajte iz sobstvennogo fizicheskogo kornya. Peremennaya sredyi `CODEX_THREAD_ID` obyazateljna i dolzhna sovpadatj s kornevoj zadachej; otsutstviye ne zamenyayetsya znacheniyem vkhodnogo JSON. Rolj beryotsya iz dejstviteljnogo naznacheniya, naprimer `FUM Интегратор`; obyichnyij probel posle `FUM` obyazatelen. Dopustimyi sobstvennaya `refs/heads/codex/…` i yavno razreshyonnyiye postoyannyiye vetki `refs/heads/fuma` i `refs/heads/planirovaniye`. `master`, detached HEAD, nezavershyonnyiye rebase/cherry-pick/revert i boleye dvukh roditelej ne podderzhanyi.

Sokhranite JSON vne Git. Vse polya obyazateljnyi; znacheniya v uglovyikh skobkakh zamenyayutsya fakticheskimi dannyimi:

```json
{
  "схема": "fum.создание-коммита.1",
  "корень": "<абсолютный физический корень>",
  "ветка": "refs/heads/codex/<своя ветка>",
  "исходный_коммит": "<полный HEAD>",
  "родители": ["<полный HEAD>"],
  "задача": "<корневой UUID>",
  "имя_автора": "FUM Интегратор",
  "запрос": "Журнал/<папка текущего этапа>/запрос.md",
  "источник_модели": "<абсолютный native JSONL корневой задачи>",
  "кэш_модели": "<новый приватный курсор вне Git>",
  "история_модели": "Журнал/<папка текущего этапа>/материалы/история-модели.json",
  "источники": [
    {
      "путь": "<абсолютный первичный JSONL>",
      "задача": "<UUID задачи источника>",
      "экземпляры": ["<идентичность выбранного экземпляра>"]
    }
  ],
  "заголовок": "Сохранить проверенный результат",
  "описание": "Конкретное описание сделанного и оставшейся работы.",
  "сообщение": "<новый приватный файл сообщения вне Git>",
  "подготовка": "<новый приватный файл подготовки вне Git>",
  "квитанция": "<новый приватный файл результата вне Git>",
  "режим": "контрольная-точка"
}
```

Dlya sliyaniya snachala razreshite yego v svoyom dereve obyichnyim soglasovannyim sposobom. V `родители` ukazhite rovno `[L, M]`: tekusjhij HEAD i tochnyij vtoroj OID iz `MERGE_HEAD`. Komanda sama sliyaniye ne nachinayet i konfliktyi ne razreshayet.

Identichnosti `экземпляры` berutsya iz [shtatnogo chitatelya soobsjhenij](obrabotka-soobsjhenij.md), a ne iz teksta ili pozicii v spiske. Sokhranyayutsya poryadok i realjnyiye povtoryi; odin ekzemplyar neljzya vyibratj dvazhdyi. Kazhdyij istochnik dolzhen imetj podtverzhdyonnyij zavershyonnyij snimok. Pri izmenyayusjhemsya zhivom JSONL soglasujte tikhoye okno libo nezavisimo proverennyij neizmenyayemyij zavershyonnyij prefiks; avtomaticheskogo povtoreniya do sluchajnogo uspekha net. Oblastj, aktualjnostj pozdnikh ukazanij i dostatochnostj vyibrannyikh komand proveryayet korenj.

Razdel `Текст запроса` soderzhit otdeljnyiye ograzhdyonnyiye bloki `text` s vyibrannyimi komandami v tom zhe poryadke. Pered blokom dopuskayetsya yedinstvennaya tochnaya sluzhebnaya metka `<!-- FUM-INTAKE: <идентичность экземпляра> -->` shtatnogo sokhranyayemogo priyoma: yeyo identichnostj obyazana sovpadatj s sootvetstvuyusjhim pervichnyim ekzemplyarom. Chuzhaya, povrezhdyonnaya ili povtoryonnaya metka otklonyayetsya. Posle tochnogo iskhodnogo teksta pered zakryivayusjhej ogradoj dobavlyayetsya odin strukturnyij LF; sobstvennyij konechnyij LF originala sokhranyayetsya otdeljno. Neodnoznachnyij vvod, vlozheniye ili nepodderzhannyij karkas dayut otkaz. V soobsjheniye kommita vklyuchayetsya sam tekst kazhdoj komandyi, zatem nablyudayemyiye `model` i `effort` i yedinstvennyij poslednij kornevoj `Codex-Thread-ID`.

Zapusk iz kornya:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py подготовить --вход <приватный-вход.json>
```

Vyikhod podtverzhdayet toljko podgotovku. Privatnyiye fajlyi sozdayutsya s rezhimom `0600`; susjhestvuyusjhiye soobsjheniye, podgotovka ili kvitanciya ne perezapisyivayutsya. Istoriya modeli mozhet sokhranitjsya do posleduyusjhego otkaza formirovaniya soobsjheniya: otsutstviye kommita ne oznachayet otsutstviye podgotoviteljnyikh zapisej. Pri neizvestnyikh obyazateljnyikh metadannyikh komanda otkazyivayet i ne zapolnyayet ikh dogadkoj.

## Proveritj i sozdatj

Zavershite soderzhateljnyiye fajlyi i recency, prosmotrite tochnyij diff, zatem indeksirujte kanonicheskij vkhod. Posle etogo zapustite primenimyiye proverki cherez [otchyotnuyu obyortku](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) v istorii v4. Obnovite predprosmotr i indeksirujte toljko isklyuchyonnyiye iz otpechatka tekusjhiye otchyot i zapisi zapuskov. Eto sokhranyayet svyazj proverok s tem zhe Git-otpechatkom i fakticheskim soderzhimyim.

Peredajte UUID kazhdogo obyazateljnogo uspeshnogo zapuska:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py создать --подготовка <приватная-подготовка.json> --проверка <UUID-запуска> --проверка <UUID-другого-запуска>
```

Spisok ne mozhet byitj pustyim; vse vyibrannyiye zapisi dolzhnyi otnositjsya k tekusjhim dvum otpechatkam. Istoricheskiye RED-zapuski ostayutsya v zhurnale, no ne zamenyayut obyazateljnyiye uspeshnyiye rezuljtatyi. Opredeleniye primenimyikh proverok i ocenka ikh dostatochnosti ostayutsya obyazannostjyu kornya; odin UUID ne dokazyivayet polnotyi vyibrannogo kontura. Otkryityij zhurnal trebuyet tochnogo predprosmotra, bez aktivnyikh, perekhodnyikh i zakryityikh sostoyanij.

Komanda ispoljzuyet nastoyasjhuyu proverku svyaznosti bez otklyucheniya Git-sostoyaniya. Dopolniteljno ona proveryayet kazhdyij stage-0 fajl, yego syiryiye bajtyi i ispolnyayemyij rezhim, ssyilki, tochnyiye gitlink OID i otsutstviye neindeksirovannogo khvosta. `assume-unchanged`, `skip-worktree`, konfliktyi i preobrazuyusjhiye filjtryi, pri kotoryikh syiryiye rabochiye bajtyi otlichayutsya ot blob, ne obkhodyat etot dopusk. Izmenyonnaya proyekciya tozhe vklyuchayetsya v polnyij indeksnyij snimok, no yeyo itogovaya praviljnostj etim ne dokazana.

Posle povtornoj sverki vkhoda komanda poluchayet derevo cherez `git write-tree`, sokhranyayet privatnoye namereniye i vyizyivayet `git commit` s tem zhe fajlom soobsjheniya i `--cleanup=verbatim`. `write-tree` mozhet sozdatj Git-obyyektyi i obnovitj cache-tree dazhe bez uspeshnogo kommita. Proveryayutsya syiroj OID, derevo, poryadok roditelej, author/committer, fakticheskoye soobsjheniye i poslednij trailer.

## Prochitatj rezuljtat ili otkaz

Uspekh vozvrasjhayet polnyij OID, derevo, roditelej i fakticheskiye polya. Kvitanciya khranit vkhodnuyu granicu i monotonnyiye dliteljnosti stadij. Publikaciya vyipolnyayetsya otdeljno po dejstvuyusjhemu pravilu 000064, posle proverki tochnogo naznacheniya i udalyonnogo OID; novogo neyavnogo push net.

Povtor `создать` s toj zhe podgotovkoj i susjhestvuyusjhej kvitanciyej vyipolnyayet toljko adresnoye chteniye rezuljtata. On ne vyizyivayet vtoroj `git commit`. Yesli Git otkazal do peredvizheniya HEAD, libo iskhod neizvesten, sokhranyonnaya popyitka zapresjhayet avtomaticheskij povtor. Yesli kommit poyavilsya, no polya, soobsjheniye, derevo ili roditeli raskhodyatsya, kvitanciya sokhranyayet nablyudyonnyij OID i otkaz posle sozdaniya. Yavnyiye datyi avtora i committer sokhranyayutsya pri podgotovke, povtorno sveryayutsya i proveryayutsya v sozdannom obyyekte; yestestvennoye vremya bez yavnogo naznacheniya ostayotsya nablyudeniyem. Zavershyonnyij otkaz Git i tajmaut sokhranyayutsya v kvitancii s kodom processa i profilem. Pri tajmaute, `SIGINT`, `SIGTERM` i `KeyboardInterrupt` sobstvennaya gruppa Git i hooks zavershayetsya do chteniya rezuljtata. Lokaljnyij obrabotchik toljko zapominayet signalyi vo vremya zapuska, ozhidaniya i ochistki; osnovnoj potok proveryayet ikh mezhdu ozhidaniyami do 0,1 s i posle zaversheniya processa. Obsjhij monotonnyij predel Git ostayotsya 120 s. Povtornyiye signalyi ne preryivayut ostanovku gruppyi; neizvestnoye zaversheniye zapresjhayet uspekh. Dazhe pri praviljnom sozdannom obyyekte otkaz processa trebuyet razbirateljstva i ne vozvrasjhayet uspeshnoye sozdaniye. Komanda ne delayet reset, amend, force push i ne skryivayet uzhe sozdannyij obyyekt.

Nepolnaya kvitanciya bez podtverzhdyonnogo zaversheniya processa sokhranyayet `исход-процесса-неизвестен`; odin nablyudyonnyij HEAD ne dokazyivayet ostanovku pozdnikh pisatelej. Ne udalyajte kvitanciyu dlya obkhoda otkaza. Snachala ustanovite fakticheskoye sostoyaniye i sokhranite osnovaniye novoj popyitki. Privatnyij zamok serializuyet toljko vyizovyi s odnoj kvitanciyej; eto kooperativnyij kontrakt yedinstvennogo naznachennogo pisatelya, a ne zasjhita ot proizvoljnoj konkurentnoj zapisi na mashine.

Otkazyi podgotovki i dopuska do Git takzhe soderzhat nablyudayemuyu dliteljnostj i profilj: v atributakh isklyucheniya API i JSON oshibki CLI, vklyuchaya otsutstvuyusjhij ili povrezhdyonnyij vkhod. Vyizyivayusjhaya storona sokhranyayet etot vyivod vne Git shtatnyim zakhvatom; eto ne kvitanciya sozdannogo kommita. Neperekhvatyivayemoye zaversheniye, naprimer `SIGKILL`, mozhet ostavitj nepolnoye namereniye i trebuyet otdeljnoj sverki. Avtomaticheskoye udaleniye Git-lock fajlov ne vyipolnyayetsya.

## Proverka kontrakta

Adresnyiye testyi ispoljzuyut realjnyij vremennyij Git, sinteticheskij pervichnyij JSONL i realjnuyu otchyotnuyu obyortku. Oni ne podmenyayut polozhiteljnyij dopusk zaglushkoj:

```text
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_создание_коммита.py
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_допуск_автора.py
```

Eti pryamyiye testovyiye processyi v rabochej sessii takzhe zapuskayutsya cherez otchyotnuyu obyortku. Fiksturyi ne dokazyivayut polnogo smoke-check FUM ili gotovnosti itogovogo rezhima.

Vosproizvodimyij profilj dvukh polozhiteljnyikh scenariyev i rannego otkaza bez native UUID, takzhe cherez otchyotnuyu obyortku:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_создания_коммита.py --выход <профиль.json> --подробный-профиль <приватный-файл-cProfile>
```

Publichnyij JSON soderzhit stadii i khyesh instrumenta. Podrobnyij profilj s lokaljnyimi putyami ostayotsya vne Git. Podgotovka vremennogo repozitoriya isklyuchena; podgotovka soobsjheniya, proverki, sozdaniye i chteniye rezuljtata vklyuchenyi.

## Istochnik

- [Ispravleniya dopuska, signalov, metki priyoma i profilya otkazov](../../Zhurnal/2026-09-16_00-10-13_MSK_sokhranitj-postanovku-chipovogo-napravleniya/otchyot.md).

- [Iskhodnyiye komandyi, proyavleniya oshibki avtora i granica tekusjhego rezuljtata](../../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 00:40:41 MSK -->
<!-- content-sha256: sha256:e8415f3612a41fa2d3a027d21a8d36a3a1b5217e3ad27764b7507202f2f69861 -->
<!-- FUM-MD-RECENCY:END -->
