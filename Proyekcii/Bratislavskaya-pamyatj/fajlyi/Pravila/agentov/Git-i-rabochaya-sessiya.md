# Git i rabochaya sessiya

Eti pravila polnostjyu chitayutsya do izmeneniya Git-sostoyaniya, podgotovki kommita i lyuboj pishusjhej rabotyi posle vyibora marshruta.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000063 -->
- Dlya agentskogo kommita `Author Name` imeyet tochnyij format `FUM <Название роли с большой буквы>` i otrazhayet fakticheskuyu rolj tekusjhej sessii, naprimer `FUM Писатель`, `FUM Запросы`, `FUM Ревью` ili `FUM Интегратор`. Eto pravilo ne menyayet email i dannyiye committer; rolj neljzya pridumyivatj vmesto fakticheski naznachennoj ili yavno prinyatoj v ruchnoj skheme.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000201 -->
- Soobsjheniye kommita pishetsya na russkom yazyike i vklyuchayet tochnyij tekst iskhodnogo poljzovateljskogo zaprosa, opisaniye sdelannogo i poslednij Git trailer `Codex-Thread-ID: <UUID>` v tele soobsjheniya. Znacheniye trailer dolzhno sovpadatj s razdelom `## Идентификатор сеанса Codex` fajla zaprosa i otnositjsya k kornevoj poljzovateljskoj zadache Codex, a ne k dochernemu subagentu.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000202 -->
- Ssyilkoj na fajl iskhodnogo zaprosa neljzya zamenyatj sam tekst zaprosa v soobsjhenii kommita; ssyilka mozhet byitj dobavlena toljko kak dopolniteljnaya spravka.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000008 -->
- Vneshnij agent bez dopusjhennogo lokaljnogo checkout peredayot toljko nedoverennoye predlozheniye izmeneniya s tochnyimi bazoj, manifestom i khyeshem i ne stanovitsya pisatelem `master`. Proverka takogo paketa ne primenyayet yego i ne oznachayet prinyatiye: toljko dejstvuyusjhaya lokaljnaya kornevaya sessiya v sobstvennom rabochem dereve dejstvuyusjhej skhemyi vprave vyibratj soderzhateljnyiye stroki, sformirovatj lokaljnyiye `Журнал/`, recency, indeksyi i `Proyekcii/**`, vyipolnitj proverki i sozdatj lokaljnyij kommit po dejstvuyusjhemu dopusku. Publikaciyu prinyatogo kommita reguliruyet pravilo `FUM-ПРАВИЛО-000064` kornevogo yadra.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

## Istochnik utochneniya postoyannoj zadachi

- [Ustranitj ostanovku postoyannoj zadachi i vesti paralleljnyiye docherniye rabotyi](../../Zhurnal/2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/zapros.md).
- [Sozdavatj celesoobraznyiye paralleljnyiye rabotyi i opisatj dejstvuyusjhij poryadok](../../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 16:38:28 MSK -->
<!-- content-sha256: sha256:cdc0865ac635f31b09ae7f3e816e4a3ef230fad9df7a3635d77dc6118d943690 -->
<!-- FUM-MD-RECENCY:END -->
