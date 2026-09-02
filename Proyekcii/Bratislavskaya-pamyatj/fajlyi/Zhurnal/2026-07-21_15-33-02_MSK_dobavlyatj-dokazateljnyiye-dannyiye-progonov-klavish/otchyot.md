# Otchyot 2026-07-21 15:33:02 MSK - Dobavlyatj dokazateljnyiye dannyiye progonov klavish

Bazovoye isklyucheniye lokaljnyikh klaviaturnyikh progonov sokhraneno, no perestalo byitj osnovaniyem dlya otdeleniya susjhestvennyikh vyivodov ot iskhodnyikh svideteljstv. Publikacionno chistyij zavershyonnyij seans, podderzhivayusjhij takoj vyivod, dolzhen vojti v tot zhe kommit po tochnomu puti.

## Resheniye

Pravilo zakrepleno odnovremenno v pravilakh repozitoriya, kommentarii `.gitignore` i pasporte prototipa fizicheskikh sostoyanij klavish. Znachimyim schitayetsya vyivod, vliyayusjhij na trebovaniya, dokumentaciyu, vyibor steka, arkhitekturu, status ili priyomku. Dlya nego v kommit adresno dobavlyayetsya minimaljno polnyij katalog zavershyonnogo seansa s `manifest.json` i `events.jsonl`, a material s vyivodom poluchayet ssyilku na etot katalog.

Bazovoye isklyucheniye vsego `Локальные-данные-прогонов/` ostayotsya bez oslableniya. Ono predotvrasjhayet sluchajnoye popadaniye obyichnyikh, chuvstviteljnyikh ili yesjhyo ne proverennyikh progonov v publichnyij repozitorij; obkhod razreshyon toljko tochnoj komandoj `git add -f -- <путь-сеанса>` posle publikacionnoj proverki.

## Granica

Nezavershyonnyiye `.incomplete-*`, vesj katalog progonov celikom i naboryi, ne proshedshiye publikacionnuyu proverku, ne stanovyatsya dokazateljnyimi materialami. Yesli iskhodnyij nabor neljzya bezopasno opublikovatj, susjhestvennyij vyivod otkladyivayetsya do publikacionno chistogo vosproizvodimogo progona.

V tekusjhej rabochej kopii zavershyonnyikh dannyikh fizicheskogo progona net, poetomu eta sessiya izmenyayet toljko kontrakt budusjhej fiksacii dannyikh.

## Prodolzheniye

Novogo samostoyateljnogo proyektnogo shaga pravilo ne sozdayot. Gotovyij shag `master` po podgotovke pasporta pervogo korobochnogo sreza sokhranyon s novyim `step_id`; pri budusjhej fizicheskoj serii klaviaturnogo prototipa dokazateljnyiye seansyi nuzhno vklyuchatj vmeste s osnovannyimi na nikh vyivodami.

## Zatronutyiye materialyi

- [pravila repozitoriya](../../AGENTS.md)
- [bazovoye isklyucheniye lokaljnyikh progonov](../../.gitignore)
- [pasport prototipa fizicheskikh sostoyanij klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [sleduyusjhij shag vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- `git check-ignore -v` podtverdil sokhraneniye bazovogo isklyucheniya dlya tochnogo puti budusjhego seansa.
- `fum-branch-next-step` prinyal zapisj `master` so svezhim `step_id`; mashinnyij planovyij reyestr peresobran i proshyol validaciyu.
- Polnyij smoke-check proshyol `36` shagov, vklyuchaya lokaljnyiye avtomatizacii, oba SwiftPM-paketa, reyestryi, ssyilki, recency, graf Obsidian i svyaznostj rabochej sessii.

## Istochniki

- [iskhodnyij zapros 2026-07-21 15:33:02 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2016c14e6b7e46437d699ceca5b6fdca2e42d963803310663b76d71917dbdfab -->
<!-- FUM-MD-RECENCY:END -->
