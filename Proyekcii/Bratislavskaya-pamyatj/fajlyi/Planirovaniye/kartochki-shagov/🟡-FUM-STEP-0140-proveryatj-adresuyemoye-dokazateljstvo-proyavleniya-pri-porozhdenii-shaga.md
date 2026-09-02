+++
schema_version = 1
card_id = "FUM-STEP-0140"
status = "active"
+++
# Proveryatj adresuyemoye dokazateljstvo proyavleniya pri porozhdenii shaga

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj v proveryayemyij kontur kartochek sboyev tipizirovannyij kontrakt dokazateljstv, kotoryij razlichayet pryamuyu mashinnuyu zapisj, tochnuyu otchyotnuyu fiksaciyu i obobsjhyonnoye svideteljstvo, razreshayet adres kazhdogo osnovaniya i ne pozvolyayet usilivatj yego utverzhdeniya pri oformlenii proyavleniya ili porozhdenii kartochki shaga.

## Pochemu sejchas

V osnovanii `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0001` obobsjhyonnyij razdel otchyota byil usilen do tochnoj operacionnoj trassyi, kotoruyu FUM-STEP-0137 unasledovala kak krasnuyu fiksturu. Posle ruchnoj korrekcii `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0002` povtorilo problemu s izmenivshimisya zhivyimi strokami, `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0003` — s poterej tochnogo nomera aktualizacii na odnoj storone svyazi, `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0004` — s metkoj tochnogo snimka dlya tematicheskogo rezyume, `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0005` — s propuskom tretjyego proyavleniya v obeikh storonakh svyazi FUM-SBOJ-0009 i FUM-STEP-0137, a `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0006` — s ustarevshej ruchnoj schyotnoj formulirovkoj. Eti proyavleniya aktualiziruyut shag neizmenyayemoj identichnostjyu, zerkaljnostjyu polnogo ryada nomerov, vyivodimyim okhvatom i yavnyim predelom silyi dokazateljstva.

## Kriterii zaversheniya

- Krasnaya avtonomnaya fikstura vosproizvodit `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0001`: obobsjhyonnoye otchyotnoye svideteljstvo prokhodit kak istochnik tochnoj operacionnoj trassyi v proyavlenii, a zatem kak «tochnoye osnovaniye» kriteriya shaga.
- Versionirovannyij kontrakt zadayot konechnyiye razlichimyiye tipyi «pryamaya mashinnaya zapisj», «tochnaya otchyotnaya fiksaciya» i «obobsjhyonnoye svideteljstvo», ikh obyazateljnyiye adresnyiye polya i dopustimyij predel proizvodnyikh utverzhdenij.
- Pryamaya mashinnaya zapisj adresuyet ustojchivuyu fakticheskuyu zapisj ili gruppu zapisej i pozvolyayet zayavlyatj toljko sokhranyonnyiye argumentyi, iskhodyi, vyivod, prinadlezhnostj i poryadok; nedostayusjhaya detalj ne dostraivayetsya iz pamyati agenta.
- Tochnaya otchyotnaya fiksaciya adresuyet odnoznachnyij fragment i podderzhivayet toljko yavno soderzhasjhiyesya v nyom detali; obobsjhyonnoye svideteljstvo ne podderzhivayet tochnoye chislo, poryadok, komandu, bukvaljnyij vyivod, status ili prichinnuyu svyazj.
- Validator razreshayet kazhdyij adres, proveryayet tip i neizmennostj adresuyemogo soderzhaniya i sopostavlyayet zayavlennuyu silu proyavleniya s dokazateljstvom; otsutstvuyusjhaya, neodnoznachnaya, ustarevshaya ili boleye slabaya opora dayot yavnyij otkaz.
- Adres istoricheskogo proyavleniya zakreplyayet khyesh ili inoj proveryayemyij neizmenyayemyij snimok soderzhaniya na moment nablyudeniya; posleduyusjhaya pravka zhivogo dokumenta ne podmenyayet prezhneye dokazateljstvo i trebuyet yavnoj novoj oporyi.
- Porozhdeniye ili aktualizaciya shaga perenosit tochnyij lokaljnyij nomer proyavleniya, adresa dokazateljstv i ikh predelyi. Formulirovka zadachi, prichinyi i kriteriyev ne mozhet dobavitj boleye siljnuyu detalj bez novogo dostatochnogo dokazateljstva.
- Kazhdyij nomer proyavleniya, porodivshego ili aktualizirovavshego shag, zerkaljno prisutstvuyet v osnovanii svyazi kartochki sboya i v istochnikakh shaga; nalichiye obsjhej ssyilki libo nomera toljko na odnoj storone dayot yavnyij otkaz.
- Obobsjhyonnoye tematicheskoye sopostavleniye mozhet poroditj yavno sinteticheskuyu regressiyu, no nazyivayetsya tochnyim snimkom toljko pri sokhranyonnom soderzhimom, proveryayemom otpechatke ili ekvivalentnoj neizmenyayemoj opore.
- Zayavlennyij okhvat «vse proyavleniya», pervoye, posledneye i chislo sluchayev vyivodyatsya iz proveryayemogo ryada; vruchnuyu zapisannoye kolichestvo, raskhodyasjheyesya s nim posle aktualizacii, dayot yavnyij otkaz.
- Yavno pomechennyij vyivod ostayotsya otlichim ot nablyudyonnogo fakta i ne povyishayet urovenj dokazateljstva; dopustimyi suzheniye formulirovki i dobavleniye boleye siljnoj oporyi, no ne molchalivoye usileniye pri pereskaze.
- Proverka FUM-STEP-0114 vklyuchayet novyij kontrakt v dopustimostj aktivnoj kartochki sboya i yeyo dvustoronnej svyazi so shagom; prostaya Markdown-ssyilka bez proveryayemogo urovnya i adresa ne schitayetsya dostatochnyim dokazateljstvom proyavleniya.
- Ruchnaya korrekciya FUM-SBOJ-0009 i FUM-STEP-0137 podtverzhdayet toljko sderzhivaniye tekusjhego sluchaya; regressiya ostayotsya krasnoj do vklyucheniya obsjhej proverki v kontur.
- Avtonomnyiye fiksturyi pokryivayut tri urovnya, tochnuyu i obobsjhyonnuyu otchyotnuyu fiksaciyu, mashinnuyu gruppu zapisej, otsutstvuyusjhij i izmenyonnyij adres, dopustimoye suzheniye, zapresjhyonnoye usileniye i perenos kartochka → shag.
- Avtonomnyiye testyi kontrakta, primenimyiye proverki kontura kartochek sboyev i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0012 — Pereobesjhannoye adresuyemoye dokazateljstvo proyavleniya](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md) — tochnoye osnovaniye `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0001`
- [vtoroye proyavleniye FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0002`
- [tretjye proyavleniye FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0003`
- [chetvyortoye proyavleniye FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0004`
- [pyatoye proyavleniye FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0005`
- [shestoye proyavleniye FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0006`
- [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) — obsjhij kontur proverki kartochek sboyev
- [FUM-SBOJ-0009 — Ruchnoye ugadyivaniye lokaljnyikh putej pered vyizovom](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md)
- [FUM-STEP-0137 — Razreshatj tochnyiye lokaljnyiye puti po inventaryu pered vyizovom](🟡-FUM-STEP-0137-razreshatj-tochnyiye-lokaljnyiye-puti-po-inventaryu-pered-vyizovom.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 01:09:33 MSK -->
<!-- content-sha256: sha256:ad0975379b2cba9321accd175fc270523ae022d630af11765e1de15d578cd0e3 -->
<!-- FUM-MD-RECENCY:END -->
