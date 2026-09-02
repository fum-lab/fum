# Shablon zaprosa vneshnemu agentu Web ChatGPT

Skopiruj tekst nizhe v Web ChatGPT, zameni znacheniya v uglovyikh skobkakh i dobavj predmetnuyu zadachu. Vneshnij agent dolzhen vernutj predlozheniye, a ne imitirovatj lokaljnuyu sessiyu FUM.

---

Rabotaj kak vneshnij proizvoditelj nedoverennogo predlozheniya izmeneniya dlya publichnogo repozitoriya `<HTTPS-URL-РЕПОЗИТОРИЯ>` na tochnom opublikovannom commit `<40-СИМВОЛЬНЫЙ-BASE-COMMIT>`.

Predmetnaya zadacha:

`<ОПИШИ ОЖИДАЕМОЕ СОДЕРЖАТЕЛЬНОЕ ИЗМЕНЕНИЕ>`

Izuchi repozitorij i yego dejstvuyusjhiye pravila v ukazannom snimke; ne pyitajsya pisatj v `master` cherez shtatnoye GitHub-podklyucheniye ChatGPT; ne obyyavlyaj commit, push, branch, pull request, `git am` ili lokaljnyiye proverki uspeshnyimi bez nablyudayemogo rezuljtata sootvetstvuyusjhego instrumenta; ne sozdavaj `Codex-Thread-ID`: eto pole mozhet poluchitj toljko realjnaya lokaljnaya kornevaya zadacha Codex; ne ispoljzuj `sandbox:/...` kak yedinstvennyij nositelj rezuljtata i ne podmenyaj polnyij payload perechnem fajlov ili opisaniyem.

Podgotovj publikacionno chistoye predlozheniye toljko dlya soderzhateljnyikh putej. Ne vklyuchaj `.git*`, `.codex/**`, `.github/**`, `.obsidian/**`, lyuboj `AGENTS.md`, `Правила/агентов/**`, `Инструменты/**`, `Журнал/**`, `Источники/**`, `Proyekcii/**` i `Зависимости/**`. Ne vklyuchaj sekretyi, cookie, tokenyi, privatnyiye URL i mashinno-lokaljnyiye puti.

V poslednem obyichnom tekstovom soobsjhenii vyivedi rovno odin polnyij JSON-obyyekt vnutri odnoj ogradyi `fum-внешний-вклад-v1`. Obyyekt obyazan sootvetstvovatj `fum.пакет-внешнего-вклада.v1` iz `Инструменты/fum-priyom-vneshnego-vklada/схемы/пакет-внешнего-вклада-v1.schema.json` i soderzhatj:

- kanonicheskij sluchajnyij UUID v4 v `идентификатор_предложения`;
- tochnyiye `репозиторий.адрес` i `репозиторий.базовый_коммит`;
- nepustyiye `утверждение`, `критерии_приёмки` i `ограничения`;
- otsortirovannyij po UTF-8 manifest operacij `добавить`, `изменить` i `удалить`;
- yedinyij patch: snachala postavj kazhdyij novyij nepustoj putj v intent-to-add komandoj `git add -N -- <НОВЫЕ-ПУТИ>`, zatem postroj tochnyiye bajtyi komandoj `git -c core.quotePath=false diff --binary --full-index --no-renames --no-color --src-prefix=a/ --dst-prefix=b/ --no-ext-diff --no-textconv`; posle sokhraneniya patcha intent-to-add mozhno ubratj cherez `git reset -q -- <НОВЫЕ-ПУТИ>`; patch dolzhen byitj ne boleye 256 KiB do Base64 i soprovozhdatjsya iskhodnyim razmerom, lowercase SHA-256 i Base64 bez izmeneniya bajtov; kazhdyij putj dolzhen menyatj soderzhimoye obyichnyim hunk libo tochnoj paroj forward/reverse binary-fragments, a pustoj fajl bez hunk i chistaya smena rezhima v versiyu 1 ne vkhodyat;
- chestnyiye `заявленные_проверки`: statusyi `пройдена` i `неуспешна` toljko so `свидетельством`, `не_запускалась` i `неопределённо` toljko s `причиной`.

Forma finaljnogo bloka:

````text
```fum-внешний-вклад-v1
{
  "схема": "fum.пакет-внешнего-вклада.v1",
  "идентификатор_предложения": "<UUID-V4>",
  "репозиторий": {
    "адрес": "<HTTPS-URL-РЕПОЗИТОРИЯ>",
    "базовый_коммит": "<40-СИМВОЛЬНЫЙ-BASE-COMMIT>"
  },
  "утверждение": "<ПРОВЕРЯЕМОЕ УТВЕРЖДЕНИЕ>",
  "критерии_приёмки": ["<КРИТЕРИЙ>"],
  "манифест": [{"путь": "<ПУТЬ>", "операция": "<добавить|изменить|удалить>"}],
  "патч": {
    "формат": "полный-бинарный-патч-git-v1",
    "кодировка": "base64",
    "размер_в_байтах": 1,
    "хэш_sha256": "<64 LOWERCASE HEX>",
    "данные": "<BASE64>"
  },
  "заявленные_проверки": [{
    "название": "<НАЗВАНИЕ>",
    "статус": "не_запускалась",
    "свидетельство": null,
    "причина": "<ПОЧЕМУ НЕ ЗАПУЩЕНО>"
  }],
  "ограничения": ["Предложение не является commit, push или квитанцией принятия."]
}
```
````

Pered otvetom sam dekodiruj Base64, povtorno vyichisli razmer i SHA-256 i sverj manifest s kazhdyim `diff --git`. Yesli polnyij paket nevozmozhno sformirovatj ili on ne pomesjhayetsya v odno soobsjheniye, pryamo soobsjhi o nedostavlennom rezuljtate i predlozhi ispoljzovatj Codex web/cloud s otdeljnyim fork i draft pull request; ne vyidavaj chastichnyij libo poteryannyij payload za dostavlennyij.

---

Lokaljnaya zadacha vsyo ravno rassmatrivayet paket kak nedoverennyij kandidat, arkhiviruyet share i vyipolnyayet sobstvennyiye proverki FUM.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 10:28:38 MSK -->
<!-- content-sha256: sha256:64f02d20230ee805165b764dc42ea1691f54ddf4d256cfc5a60a1e4f7fe3ec46 -->
<!-- FUM-MD-RECENCY:END -->
