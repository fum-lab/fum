# Sozdatj proverennyij kommit kontroljnoj tochki

Komanda podgotavlivayet soobsjheniye iz realjnyikh poljzovateljskikh komand i nablyudayemoj istorii modeli, zatem sozdayot odin lokaljnyij kommit posle proverki indeksa i obyazateljnyikh proverok. Ona sokhranyayet email avtora i dannyiye committer, menyaya toljko `GIT_AUTHOR_NAME` na yavno naznachennuyu rolj. Podderzhanyi obyichnyij kommit i nastoyasjheye sliyaniye s dvumya uporyadochennyimi roditelyami.

Eto polnyij putj sozdaniya **kontroljnoj tochki razreshyonnoj postoyannoj zadachi**. Itogovyij rezhim poka zakryito otkazyivayet: yesjhyo trebuyetsya otdeljnoye proverennoye vklyucheniye odnokratnogo zamyikaniya proyekcii po pravilu 000188. Proverennaya kontroljnaya tochka ne oznachayet itogovuyu priyomku, zaversheniye zadachi, integraciyu v `master` ili publikaciyu. Komanda ne sozdayot zadach, raspisanij ili hooks.

## Podgotovitj vkhod

Rabotajte iz sobstvennogo fizicheskogo kornya. Peremennaya sredyi `CODEX_THREAD_ID` obyazateljna i dolzhna sovpadatj s kornevoj zadachej; otsutstviye ne zamenyayetsya znacheniyem vkhodnogo JSON. Rolj beryotsya iz dejstviteljnogo naznacheniya, naprimer `FUM Интегратор`; obyichnyij probel posle `FUM` obyazatelen. Dopustimyi sobstvennaya `refs/heads/codex/…` i yavno razreshyonnyiye postoyannyiye vetki `refs/heads/fuma` i `refs/heads/planirovaniye`. `master`, detached HEAD, nezavershyonnyiye rebase/cherry-pick/revert i boleye dvukh roditelej ne podderzhanyi.

Sokhranite JSON vne Git. Vse polya obyazateljnyi; znacheniya v uglovyikh skobkakh zamenyayutsya fakticheskimi dannyimi:

```json
{
  "схема": "fum.создание-коммита.2",
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
  "режим": "контрольная-точка",
  "разрешённые_цели": ["<точный относительный путь каждого разрешённого файла>"]
}
```

`разрешённые_цели` — nezavisimyij konechnyij spisok tochnyikh otnositeljnyikh putej. Perechislite iskhodniki, dokumentyi, navigaciyu, indeksyi, istoriyu modeli i vse zapisi proverok svoyego etapa. Katalogi, povtoreniya, absolyutnyiye puti, vyikhod za korenj, symlink i nevernyij registr ne dopuskayutsya. Yesjhyo ne sozdannyij fajl dopustim kak budusjhaya celj. Ne kopirujte vesj Git-status kak razresheniye: sostav zadayotsya prinyatyim obyyomom rabotyi.

Budusjhim proverkam zaraneye naznachjte UUID cherez `--идентификатор-запуска` otchyotnoj obyortki. Imya zapisi imeyet vid `<следующий-порядок>_<UUID>.json`; pri odnom posledovateljnom pisatele ono izvestno do podgotovki. Eto ne rezervirovaniye. Nepredvidennyij dopolniteljnyij zapusk menyayet poryadok i trebuyet sverennogo novogo vkhoda i novyikh privatnyikh fajlov podgotovki. Prezhnyaya podgotovka ne perepisyivayetsya.

Dlya sliyaniya snachala razreshite yego v svoyom dereve obyichnyim soglasovannyim sposobom. V `родители` ukazhite rovno `[L, M]`: tekusjhij HEAD i tochnyij vtoroj OID iz `MERGE_HEAD`. Komanda sama sliyaniye ne nachinayet i konfliktyi ne razreshayet.

V kazhdom elemente `источники` mozhno dopolniteljno ukazatj `кэш` — tochnyij putj susjhestvuyusjhego privatnogo indeksa `fum.индекс-сообщений.1`, sozdannogo shtatnyim chitatelem. Eto ne `кэш_модели`. Bez polya sokhranyayetsya polnyij razbor. Kyesh proveryayetsya chitatelem, ne obnovlyayetsya podgotovkoj i ne zamenyayet pervichnyij JSONL: pri roste vesj prezhnij prefiks khyeshiruyetsya, razbirayetsya khvost; pozdniye bajtyi, povrezhdeniye i nesovpadeniye vyibrannyikh komand po-prezhnemu dayut otkaz. Neizmennostj metadannyikh FS ostayotsya prezhnej granicej doveriya chitatelya.

Do dorogogo chteniya istochnika podgotovka proveryayet nepustuyu istoriyu zapuskov: trebuyetsya v4. Otsutstvuyusjhij katalog oznachayet novuyu sessiyu; susjhestvuyusjhij katalog chitayetsya strogo, vklyuchaya otkaz pri povrezhdenii ili ssyilke. Pustaya istoriya dopuskayet podgotovku soobsjheniya, no yeyo pervyij zapusk neobkhodimo yavno nachatj s `--приёмочные-раунды`; sozdaniye bez v4 vsyo ravno zapresjheno. Avtomaticheskoj migracii v3 net.

Identichnosti `экземпляры` berutsya iz [shtatnogo chitatelya soobsjhenij](obrabotka-soobsjhenij.md), a ne iz teksta ili pozicii v spiske. Sokhranyayutsya poryadok i realjnyiye povtoryi; odin ekzemplyar neljzya vyibratj dvazhdyi. Kazhdyij istochnik dolzhen imetj podtverzhdyonnyij zavershyonnyij snimok. Pri izmenyayusjhemsya zhivom JSONL soglasujte tikhoye okno libo nezavisimo proverennyij neizmenyayemyij zavershyonnyij prefiks; avtomaticheskogo povtoreniya do sluchajnogo uspekha net. Oblastj, aktualjnostj pozdnikh ukazanij i dostatochnostj vyibrannyikh komand proveryayet korenj.

Razdel `Текст запроса` soderzhit otdeljnyiye ograzhdyonnyiye bloki `text` s vyibrannyimi komandami v tom zhe poryadke. Pered blokom dopuskayetsya yedinstvennaya tochnaya sluzhebnaya metka `<!-- FUM-INTAKE: <идентичность экземпляра> -->` shtatnogo sokhranyayemogo priyoma: yeyo identichnostj obyazana sovpadatj s sootvetstvuyusjhim pervichnyim ekzemplyarom. Chuzhaya, povrezhdyonnaya ili povtoryonnaya metka otklonyayetsya. Posle tochnogo iskhodnogo teksta pered zakryivayusjhej ogradoj dobavlyayetsya odin strukturnyij LF; sobstvennyij konechnyij LF originala sokhranyayetsya otdeljno. Neodnoznachnyij vvod, vlozheniye ili nepodderzhannyij karkas dayut otkaz. V soobsjheniye kommita vklyuchayetsya sam tekst kazhdoj komandyi, zatem nablyudayemyiye `model` i `effort` i yedinstvennyij poslednij kornevoj `Codex-Thread-ID`.

Zapusk iz kornya:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py подготовить --вход <приватный-вход.json>
```

Vyikhod podtverzhdayet toljko podgotovku. Privatnyiye fajlyi sozdayutsya s rezhimom `0600`; susjhestvuyusjhiye soobsjheniye, podgotovka ili kvitanciya ne perezapisyivayutsya. Istoriya modeli mozhet sokhranitjsya do posleduyusjhego otkaza formirovaniya soobsjheniya: otsutstviye kommita ne oznachayet otsutstviye podgotoviteljnyikh zapisej. Pri neizvestnyikh obyazateljnyikh metadannyikh komanda otkazyivayet i ne zapolnyayet ikh dogadkoj.

## Povtoritj podgotovku bez izmeneniya istorii modeli

Yesli nuzhno utochnitj konechnyij sostav razreshyonnyikh fajlov ili podgotovitj novoye soobsjheniye, a novyiye nablyudeniya modeli ne poyavilisj, dostupen yavnyij rezhim:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py подготовить-повтор --вход <новый-приватный-вход.json>
```

Vkhod ostayotsya v2; soobsjheniye, podgotovka i kvitanciya dolzhnyi imetj novyiye privatnyiye puti. Istoriya i yeyo prezhnij kursor dolzhnyi susjhestvovatj i sovpadatj; ikh avtomaticheskogo vosstanovleniya net. Svezhij JSONL chitayetsya shtatnyim importyorom bez zapisi. Obyichnyij korrektnyij khvost bez novyikh turn_context dopustim. Novoye nablyudeniye dazhe s prezhnimi model/effort, propusk, nepolnyij khvost, izmeneniye starogo prefiksa ili rassoglasovannyij kursor dayut otkaz. Togda otdeljno sveryayut istochnik i vyipolnyayut obyichnuyu podgotovku do staging i proverok.

Podgotovka sokhranyayet SHA neizmennyikh kanonicheskikh bajtov istorii. Dopolniteljnoye pole rezuljtata CLI `сверка_истории` soderzhit svezhuyu chitayusjhuyu sverku: yeyo `история_sha256` otnositsya k rasschitannomu obyyektu istorii, a ne k sokhranyonnomu fajlu i ne k samomu JSONL. Sokhranite etot rezuljtat privatno kak svideteljstvo proverki khvosta. Staryiye podgotovka, soobsjheniye, istoriya i kursor ne perezapisyivayutsya; obyichnyij import sokhranyayet prezhnyuyu semantiku.

Rezhim predotvrasjhayet invalidirovaniye proverok toljko iz-za perepisyivaniya istorii pri roste sluzhebnogo JSONL. On ne razreshayet ispoljzovatj proverki drugogo canonical diff ili indeksa, ne sozdayot kommit i ne povtoryayet otkaz avtomaticheski. [Parnyij profilj](tests/profilj_povtornoj_podgotovki.py) s `--выход <новый JSON>` sravnivayet obe podgotovki na khvoste 1 MiB cherez shtatnuyu otchyotnuyu obyortku.

## Sovmestimostj podgotovki

Novaya komanda podgotavlivayet `fum.подготовленный-коммит.2`. Spisok razreshyonnyikh celej vkhodit v neizmenyayemyiye bajtyi podgotovki i svyazyivayetsya s kvitanciyej ikh SHA. Staroye predstavleniye v1 dopuskayetsya toljko dlya vosstanovleniya uzhe susjhestvuyusjhej kvitancii, posle proverki yeyo svyazi s iskhodnoj podgotovkoj. Bez kvitancii sozdaniye po v1 zakryito otkazyivayet: trebuyetsya novaya podgotovka v2. Ne dopolnyajte staryiye fajlyi na meste. Skhema kvitancii ostayotsya v1; eta sovmestimostj ne razreshayet povtor neizvestnogo Git-vyizova.

## Proveritj i sozdatj

Zavershite soderzhateljnyiye fajlyi i recency, prosmotrite tochnyij diff, zatem indeksirujte kanonicheskij vkhod. Posle etogo zapustite primenimyiye proverki cherez [otchyotnuyu obyortku](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) v istorii v4. Obnovite predprosmotr i indeksirujte toljko isklyuchyonnyiye iz otpechatka tekusjhiye otchyot i zapisi zapuskov. Eto sokhranyayet svyazj proverok s tem zhe Git-otpechatkom i fakticheskim soderzhimyim.

Peredajte UUID kazhdogo obyazateljnogo uspeshnogo zapuska:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py создать --подготовка <приватная-подготовка.json> --проверка <UUID-запуска> --проверка <UUID-другого-запуска>
```

Pered chteniyem pervichnyikh JSONL vyipolnyayetsya gotovaya rannyaya sverka materialov: ona sopostavlyayet razdel «Povliyal na fajlyi», polnyij Git-status i nezavisimyij razreshyonnyij spisok. Posle chteniya istochnikov i metadannyikh snimok sveryayetsya povtorno do dorogoj proverki indeksa. Nepolnyij sostav, lishnij fajl ili drejf ostanavlivayut sozdaniye do zapisi namereniya Git. Polnaya svyaznostj, obyazateljnyiye proverki i zaklyuchiteljnaya sverka indeksa sokhranyayutsya.

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
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_ранний_состав_коммита.py
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_ранний_охват.py
```

Eti pryamyiye testovyiye processyi v rabochej sessii takzhe zapuskayutsya cherez otchyotnuyu obyortku. Fiksturyi ne dokazyivayut polnogo smoke-check FUM ili gotovnosti itogovogo rezhima.

Vosproizvodimyij profilj dvukh polozhiteljnyikh scenariyev i dvukh rannikh otkazov: bez native UUID i pri nepolnom sostave do chteniya pervichnogo JSONL, takzhe cherez otchyotnuyu obyortku:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_создания_коммита.py --выход <профиль.json> --подробный-профиль <приватный-файл-cProfile>
```

Publichnyij JSON soderzhit stadii i khyesh instrumenta. Podrobnyij profilj s lokaljnyimi putyami ostayotsya vne Git. Podgotovka vremennogo repozitoriya isklyuchena; podgotovka soobsjheniya, proverki, sozdaniye i chteniye rezuljtata vklyuchenyi.

## Profilj kyesha pervichnyikh komand

[Otkryityij izmeritelj](tests/profilj_kyesha_komand.py) sozdayot odinakovyij sinteticheskij JSONL i sravnivayet tri chteniya. Parametr `--с-кэшем` vklyuchayet indeks, `--с-хвостом` dopisyivayet stroku posle yego podgotovki. Vyikhod `--выход <профиль.json>` soderzhit SHA vkhoda, rezuljtata i iskhodnikov. Vse variantyi vyizyivayutsya cherez otchyotnuyu obyortku. Podgotovka indeksa isklyuchena; vremya polnogo sozdaniya kommita i raskhod tokenov etim ne izmeryayutsya.

## Istochnik

- [Ispravleniya dopuska, signalov, metki priyoma i profilya otkazov](../../Zhurnal/2026-09-16_00-10-13_MSK_sokhranitj-postanovku-chipovogo-napravleniya/otchyot.md).

- [Iskhodnyiye komandyi, proyavleniya oshibki avtora i granica tekusjhego rezuljtata](../../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 06:16:45 MSK -->
<!-- content-sha256: sha256:49c13354c9d3786662ee6b6551c36902106bef407f6daab5602f169488a9e660 -->
<!-- FUM-MD-RECENCY:END -->
