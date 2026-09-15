# Git i rabochaya sessiya

Eti pravila polnostjyu chitayutsya do izmeneniya Git-sostoyaniya, podgotovki kommita i lyuboj pishusjhej rabotyi posle vyibora marshruta.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000018 -->
- Postoyannaya vetka `refs/heads/planirovaniye` prednaznachena dlya soglasovannyikh poljzovatelem planov FUM/FUMA i neobkhodimyikh soprovoditeljnyikh materialov. Yeyo tochnoye imya vyibrano poljzovatelem kak isklyucheniye iz obyichnogo prefiksa `codex/`. Rabota vedyotsya v otdeljnom izolirovannom Git worktree s odnim pisatelem dereva i ref. Soglasovannyiye etapyi fiksiruyutsya posledovateljnyimi proveryayemyimi kommitami po `FUM-ПРАВИЛО-000062`, kazhdyij kommit publikuyetsya po `FUM-ПРАВИЛО-000064`. Priyomka dlya posleduyusjhego sliyaniya i integraciya v `master` vyipolnyayutsya pozdneye po otdeljnomu yavnomu zaprosu poljzovatelya i pravilam prinimayusjhego `master`. Do prinyatoj integracii nastoyasjhaya norma dejstvuyet toljko v `refs/heads/planirovaniye` i ne schitayetsya dejstvuyusjhej v `master`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000063 -->
- Dlya agentskogo kommita `Author Name` imeyet tochnyij format `FUM <Название роли с большой буквы>` i otrazhayet fakticheskuyu rolj tekusjhej sessii, naprimer `FUM Писатель`, `FUM Запросы`, `FUM Ревью` ili `FUM Интегратор`. Eto pravilo ne menyayet email i dannyiye committer; rolj neljzya pridumyivatj vmesto fakticheski naznachennoj ili yavno prinyatoj v ruchnoj skheme.

Dlya vyibora roli menyaj toljko `GIT_AUTHOR_NAME`; pered kommitom sravnivaj `git var GIT_AUTHOR_IDENT` i `git var GIT_COMMITTER_IDENT` s iskhodnyimi dannyimi, posle nego proveryaj fakticheskiye polya commit. Pereopredeleniye obsjhego `user.name` radi roli zatragivayet takzhe committer i ne sootvetstvuyet etoj norme. [Nablyudayemaya oshibka i proverennoye vosstanovleniye](../../Sboi/FUM-SBOJ-0047-podmena-committer-pri-vyibore-roli-avtora.md).

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

## Istochnik postoyannoj vetki planirovaniya

- [Porucheniye o posledovateljnoj serii i postoyannoj vetke](../../Zhurnal/2026-09-11_01-49-43_MSK_zakrepitj-postoyannuyu-vetku-planirovaniya/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:47:30 MSK -->
<!-- content-sha256: sha256:ee132fcc41f03b7fdec4539d5145de15b68120e8c266b3ec3613c009dd0781b0 -->
<!-- FUM-MD-RECENCY:END -->
