# Git i rabochaya sessiya

Eti pravila polnostjyu chitayutsya do izmeneniya Git-sostoyaniya, podgotovki kommita i lyuboj pishusjhej rabotyi posle vyibora marshruta.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000063 -->
- Dlya agentskogo kommita `Author Name` imeyet tochnyij format `FUM <Название роли с большой буквы>` i otrazhayet fakticheskuyu rolj tekusjhej sessii, naprimer `FUM Писатель`, `FUM Запросы`, `FUM Ревью` ili `FUM Интегратор`. Eto pravilo ne menyayet email i dannyiye committer; rolj neljzya pridumyivatj vmesto fakticheski naznachennoj ili yavno prinyatoj v ruchnoj skheme.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000201 -->
- Soobsjheniye kommita pishetsya na russkom yazyike i vklyuchayet tochnyij tekst iskhodnogo poljzovateljskogo zaprosa, opisaniye sdelannogo i poslednij Git trailer `Codex-Thread-ID: <UUID>` v tele soobsjheniya. Znacheniye trailer dolzhno sovpadatj s razdelom `## Идентификатор сеанса Codex` fajla zaprosa i otnositjsya k kornevoj poljzovateljskoj zadache Codex, a ne k dochernemu subagentu.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000202 -->
- Ssyilkoj na fajl iskhodnogo zaprosa neljzya zamenyatj sam tekst zaprosa v soobsjhenii kommita; ssyilka mozhet byitj dobavlena toljko kak dopolniteljnaya spravka.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000008 -->
- Vneshnij agent bez dopusjhennogo lokaljnogo checkout peredayot toljko nedoverennoye predlozheniye izmeneniya s tochnyimi bazoj, manifestom i khyeshem i ne stanovitsya pisatelem `master`. Proverka takogo paketa ne primenyayet yego i ne oznachayet prinyatiye: toljko dejstvuyusjhaya lokaljnaya kornevaya sessiya v sobstvennom rabochem dereve dejstvuyusjhej ruchnoj skhemyi vprave vyibratj soderzhateljnyiye stroki, sformirovatj lokaljnyiye `Журнал/`, recency, indeksyi i `Proyekcii/**`, vyipolnitj proverki i sozdatj lokaljnyij kommit po dejstvuyusjhemu dopusku; push po-prezhnemu trebuyet otdeljnogo yavnogo zaprosa poljzovatelya.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 00:57:55 MSK -->
<!-- content-sha256: sha256:a52f5d5dfbe05ce26389c0c5514dafe1529aa078518f64081c228d06becfc0ae -->
<!-- FUM-MD-RECENCY:END -->
