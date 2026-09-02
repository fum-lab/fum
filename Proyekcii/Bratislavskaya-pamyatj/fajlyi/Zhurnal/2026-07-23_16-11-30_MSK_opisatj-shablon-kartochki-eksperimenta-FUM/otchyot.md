# Otchyot 2026-07-23 16:11:30 MSK - Opisatj shablon kartochki eksperimenta FUM

Pamyatj FUM poluchila chelovekochitayemyij kontrakt eksperimenta, kotoryij sokhranyayet plan do zapuska, fakticheskiye otkloneniya i otricateljnyiye rezuljtatyi. Odin uspeshnyij lokaljnyij progon teperj neljzya sputatj s nezavisimyim vosproizvedeniyem ili otkryitiyem: sostoyaniye vyipolneniya, iskhod proverki gipotezyi i issledovateljskij status utverzhdeniya fiksiruyutsya razdeljno.

## Rezuljtat

[Shablon kartochki eksperimenta FUM](../../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md) versii `1` obyyedinyayet pasport, vopros, gipotezu, metod, dannyiye, sredu, zaraneye zadannyiye kriterii, povtoryayemyij blok zapuska, rezuljtat, ogranicheniya, status i odin sleduyusjhij shag. Odna kartochka sootvetstvuyet odnoj versii protokola odnoj gipotezyi; izmeneniye voprosa, dannyikh, metoda, sredyi ili kriteriya vyipuskayet novuyu versiyu, a ne perepisyivayet proiskhozhdeniye prezhnego rezuljtata.

Shablon sokhranyayet otricateljnyij i neodnoznachnyij iskhodyi i otdelyayet nablyudeniye ot interpretacii. Dlya kazhdogo zapuska zapisyivayutsya tochnyiye vkhodyi, sreda, komanda ili dejstviya, otkloneniya i svideteljstva. Sleduyusjhij shag ostayotsya predlozheniyem s predusloviyami i ne oznachayet avtomaticheskogo zapuska.

Svyazannyiye [nauchnyiye issledovaniya FUM i otkryitiya](../../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md), termin [eksperimenta FUM](../../Glossarij/eksperiment-FUM.md), [napravleniye issledovanij i otkryitij](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md) i [dorozhnaya karta](../../Planirovaniye/dorozhnaya-karta.md) teperj vedut k prinyatomu prakticheskomu kontejneru.

## Proverochnyij primer

Zapolnennyij primer zadayot vopros o dvukh slovaryakh s odinakovyimi parami klyuchej i znachenij, no raznyim poryadkom vstavki. Python `3.14.6` serializoval oba znacheniya s `sort_keys=True` v stroku `{"a":1,"b":2}` i vyichislil odinakovyij SHA-256 `43258cff783fe7036d8a43033f830adfc60ec037382473548ac742b888292777`.

Primer vyipolnyayetsya odnoj lokaljnoj komandoj bez seti, sekretov i zapisi. Rezuljtat podderzhivayet gipotezu toljko dlya dvukh vkhodov, tochnyikh parametrov i zafiksirovannoj sredyi. Drugiye tipyi dannyikh, versii i realizacii ne proverenyi; nezavisimyij FUM-uzel ne uchastvoval, poetomu primer ne obyyavlen vosproizvedyonnyim rezuljtatom ili otkryitiyem.

## Granica primenimosti

Shablon versii `1` yavlyayetsya deklarativnyim Markdown-kontraktom dokumentacionnogo prototipa. On ne yavlyayetsya mashinnoj skhemoj, laboratornyim runtime, avtomaticheskim ocensjhikom istinnosti, razresheniyem dostupa ili dokazateljstvom vosproizvodimosti. Mashinnaya skhema otlozhena do nakopleniya realjnyikh kartochek i proverki ustojchivosti polej.

Kartochka ne razreshayet setj, publikacionnoye ili socialjnoye vozdejstviye, izmeneniye vneshnej cifrovoj sistemyi libo fizicheskoye dejstviye. Takiye effektyi trebuyut otdeljnogo trebovaniya, dostupa, proverki riska i podtverzhdeniya; nereshyonnaya chastj ostayotsya v [voprose o granicakh issledovateljskoj avtonomii FUM](../../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md).

## Proverki

- Lokaljnyij primer zavershilsya s kodom `0`; versiya Python, obe serializacii i oba SHA-256 sokhranenyi v shablone.
- Planovyij reyestr validen dlya `71` kartochki; fenced show podtverdil yedinstvennyij `ready` `FUM-STEP-0028`, a `FUM-STEP-0035` sokhranilsya kak `blocked` s prezhnim usloviyem vozobnovleniya.
- Proverki Markdown-ssyilok, `14` aktivnyikh voprosov i `87` zayavlennyikh celej, recency, grafa Obsidian, svyaznosti rabochej sessii i `git diff --check` proshli.
- Predvariteljnyij smoke-check byil ostanovlen na shage `9/39`, kogda finaljnoye soderzhateljnoye revjyu vyiyavilo tri nesoglasovannosti. Posle ispravlenij svezhij polnyij smoke-check proshyol `39/39` shagov za `197,1` sekundyi.

## Prodolzheniye

`FUM-STEP-0027` zavershena po fakticheskomu rezuljtatu. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0028` yedinstvennyim `ready`. Sleduyusjhij shag opisyivayet kartu ogranichitelej fizicheskogo dejstviya FUM po uzhe sokhranyonnyim voprosam i ostayotsya dokumentacionnyim: on ne razreshayet fizicheskoye dejstviye.

## Profilj vremeni vyipolneniya

| Stadiya                                      | Dliteljnostj                   | Granicyi i sposob izmereniya                                                                                                                                                |
| ------------------------------------------- | -----------------------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO                       |                          0,4 s | Wall-clock uspeshnogo `join`; zadacha srazu poluchila `admitted`, dolgozhivusjhego ozhidaniya ne byilo.                                                                            |
| Soderzhateljnaya rabota, proverki i revjyu     | 4216,5 s (1 ch 10 min 16,5 s)   | Ot mashinnogo `admitted_at` do nachala finaljnyikh celevyikh proverok; vklyuchayet perekryivayusjhiyesya read-only-analizyi, pervyij nabor proverok, prervannyij smoke-check i ispravleniya. |
| Finaljnyiye celevyiye proverki i podgotovka     |                         29,7 s | Ot nachala povtornoj sborki reyestra do zapuska svezhego polnogo smoke-check; sobstvenno celevyiye proverki zanyali `17,7` sekundyi.                                             |
| Predfinaljnyij polnyij smoke-check            |    197,1 s (3 min 17,1 s)      | Svezhij polnyij progon `39/39` posle ispravlenij revjyu; wall-clock izmeren monotonnyim tajmerom vokrug komandyi na tekusjhej mashine.                                            |

Granica profilya: ot uspeshnogo FIFO-dopuska do zaversheniya predfinaljnogo polnogo smoke-check — `4443,2` sekundyi (`1 ч 14 мин 3,2 с`); dliteljnostj dopuska FIFO pokazana otdeljno. Zapisj rezuljtata, povtornyiye recency, svyaznostj, `git diff --check`, staging i atomarnyij commit+handoff nakhodyatsya posle etoj granicyi.

## Zatronutyiye materialyi

- [shablon kartochki eksperimenta FUM](../../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md)
- [nauchnyiye issledovaniya FUM i otkryitiya](../../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md)
- [eksperiment FUM](../../Glossarij/eksperiment-FUM.md)
- [napravleniye issledovanij i otkryitij](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md)
- [dorozhnaya karta FUM](../../Planirovaniye/dorozhnaya-karta.md)
- [vopros o granicakh issledovateljskoj avtonomii FUM](../../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md)
- [zavershyonnaya kartochka FUM-STEP-0027](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0027-opisatj-shablon-kartochki-eksperimenta-FUM.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [napravleniye issledovanij i otkryitij](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md)
- [nauchnyiye issledovaniya FUM i otkryitiya](../../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:782d97c89fcfffac8afabe447ac4fed6098b347468f9d7da18cf55840803e0ee -->
<!-- FUM-MD-RECENCY:END -->
