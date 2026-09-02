# Mekhanizm sna FUM

Mekhanizm sna FUM — ogranichennaya faza [agentskogo cikla](agentskij-cikl.md) i evolyucionnogo otbora, v kotoroj ot tochnogo neizmenyayemogo snimka v strogo modeljnom konture dopuskayutsya boleye shirokiye i variativnyiye preobrazovaniya, chem v sopostavimom obyichnom rezhime. Eta faza nuzhna dlya dvukh simmetrichnyikh zadach: dyoshevo poluchitj otricateljnyiye svideteljstva protiv yavno neperspektivnyikh napravlenij obucheniya i sokhranitj shans obnaruzhitj nestandartnyiye napravleniya, kotoryiye obyichnyij poisk ne porodil byi.

Slovo «son» oboznachayet arkhitekturnyij rezhim FUM, a ne zavershyonnuyu teoriyu biologicheskogo sna cheloveka. «Gruboye dejstviye» v etom rezhime oznachayet shirokoye, priblizhyonnoye ili ponizhennoye po tochnosti preobrazovaniye toljko vnutri [modeljnoj sredyi](modeljnaya-sreda.md); ono ne oznachayet oslableniye bezopasnosti, polnomochij, pravil dostupa, kriteriyev priyomki ili politiki khraneniya. Tochnyij operacionnyij profilj grubosti i povyishennoj izmenchivosti poka ne vyibran: on dolzhen byitj versionno zadan otnositeljno nazvannogo bazovogo rezhima cherez dostupnyiye operatoryi, shirinu vetvleniya, distanciyu izmeneniya, tochnostj modeli i byudzhet.

Son, gibernaciya i probuzhdeniye fizicheskoj mashinyi ne yavlyayutsya fazami etogo mekhanizma. Tak zhe poterya i vosstanovleniye seti — vneshniye operacionnyiye sobyitiya, a ne «zasyipaniye» i «probuzhdeniye» FUM v issledovateljskom smyisle. Tekusjhij dokumentacionnyij prototip mozhet zafiksirovatj tochnyij razryiv potoka otveta i tekusjhuyu dostupnostj host-puti chteniya, no ne vyivodit iz etogo fizicheskuyu prichinu. Avtoritetnoye nablyudeniye OS-sobyitij sna i probuzhdeniya, smenyi setevoj dostupnosti i perezapuska runtime ostayotsya otkryitoj granicej budusjhego versionirovannogo adaptera, a ne skryitoj sposobnostjyu mekhanizma sna FUM.

Vo sne vneshnij [gorizont agenta](gorizont-agenta-FUM.md) zakryit. Ispolnitelj poluchayet tochnyij snimok predka i karantinnuyu oblastj, no ne poluchayet adapteryi vneshnego dejstviya, uchyotnyiye dannyiye, proizvoljnyij dostup k fajlam, seti, obsjhej izmenyayemoj kanonicheskoj pamyati, publikacii, soobsjheniyam ili platezham. Odin [chistyij modeljnyij shag](chistyij-modeljnyij-shag.md) yavlyayetsya podkhodyasjhim primitivom, no ne dokazyivayet izolyaciyu vsego mnogoshagovogo epizoda: ogranicheniye dolzhno okhvatyivatj takzhe vneshnij runtime, provajdera, khraneniye i perenos rezuljtata.

Bukvaljnoye otsutstviye dejstvij v realjnoj srede nedostizhimo, potomu chto vyichisleniye, energiya i sokhraneniye trassyi sami yavlyayutsya realjnyimi effektami. Proveryayemaya granica sna poetomu formuliruyetsya polozhiteljno: dopustimyi toljko zaraneye razreshyonnyiye vyichisleniye, ogranichennyij zhurnal, kandidatnyij rezuljtat i bezopasnaya kontroljnaya tochka; lyuboj effekt vne etogo vyichisliteljno-khranilisjhnogo konverta zavershayet epizod otkazom. Udalyonnyij provajder dobavlyayet setevuyu peredachu, raskryitiye dannyikh i vozmozhnuyu stoimostj, poetomu trebuyet otdeljnogo dopuska i ne schitayetsya strogim snom bez vneshnego effekta.

Povyishennaya izmenchivostj primenyayetsya k gipotezam, marshrutam, predstavleniyam i parametram kandidatnyikh modeljnyikh vetvej, no ne k zasjhitnyim ogranicheniyam. Kazhdaya vetvj sokhranyayet tochnogo predka, otlichiya, profilj izmenchivosti, byudzhet, proverki, rezuljtat i prichinu statusa. Son imeyet konechnyiye limityi vetvej, shagov, vremeni, vyichislenij, deneg i khraneniya, vneshnij mekhanizm otmenyi i vosproizvodimuyu kontroljnuyu tochku.

«Nerelevantnostj» vsegda otnositsya k yavnoj celi, snimku pamyati, oblasti primenimosti modeli i razlichayusjhej proverke. Vnutrennyaya uverennostj ili modeljnaya neudacha ne delayut napravleniye zavedomo lozhnyim. Otbrositj napravleniye po umolchaniyu oznachayet ponizitj yego ves, isklyuchitj iz obyichnogo poiska ili pomestitj v obratimyij arkhiv s proiskhozhdeniyem; eto ne razreshayet fizicheski udalitj pervichnyij istochnik, prinyatuyu istoriyu ili minimaljnoye osnovaniye dlya [vspominaniya FUM](vspominaniye-FUM.md). Yesli razlichayusjhej proverki net, korrektnyij iskhod — sokhranitj neopredelyonnostj.

Obratnaya funkciya sna zasjhisjhayet produktivnoye raznoobraziye. Chastj byudzheta rezerviruyetsya dlya neobyichnyikh vetvej, a novizna ocenivayetsya otdeljno ot kachestva, istinnosti i bezopasnosti. Neobyichnyij rezuljtat sokhranyayetsya kak kandidatnaya [gipoteza FUM](gipoteza-FUM.md) s oblastjyu primenimosti, dazhe yesli tekusjhaya modelj schitayet yego maloveroyatnyim; odna novizna takzhe ne dayot yemu preimusjhestva bez proverki.

Probuzhdeniye ne sovmesjhayetsya s ispolneniyem ili obuchayusjhim obnovleniyem. Vneshnij upravlyayusjhij kontur zavershayet son po signalu, politike, ischerpaniyu byudzheta ili narusheniyu granicyi i perevodit rezuljtatyi v otdeljnyij razbor. Otklonyonnaya vetvj, sokhranyonnaya aljternativa i nestandartnaya gipoteza ostayutsya kandidatami; prinyatiye v rabochuyu ili dolgovremennuyu pamyatj, izmeneniye indeksa, vesov, koda, marshruta libo politiki obucheniya trebuyet obyichnoj priyomki, sravneniya s bazovoj versiyej, proverki aktualjnosti i, gde primenimo, podtverzhdeniya, avtorizacii, preflight i vozmozhnosti otkata.

Tekusjhaya pamyatj FUM zakreplyayet etot mekhanizm kak konceptualjnyij profilj, a ne kak realizovannuyu sposobnostj. Otkryityi usloviya vkhoda i probuzhdeniya, tochnaya mera povyishennoj izmenchivosti, kriterii predvariteljnoj nerelevantnosti i noviznyi, dopustimaya chastota lozhnogo otseva, srok khraneniya vetvej, kalibrovka modeljnoj sredyi i nezavisimaya priyomka uchebnogo obnovleniya. Eti parametryi vkhodyat v [vopros o granicakh issledovateljskoj avtonomii FUM](../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md).

## Svyazannyiye dokumentyi

- [Evolyuciya i myishleniye](../Dokumentaciya/03-evolyuciya-i-myishleniye.md)
- [Sreda dlya vnutrennikh FUM](../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md)
- [Karta ogranichitelej fizicheskogo dejstviya FUM](../Dokumentaciya/40-karta-ogranichitelej-fizicheskogo-dejstviya-FUM.md)
- [Kontroliruyemaya nejroplastichnostj FUM](kontroliruyemaya-nejroplastichnostj-FUM.md)
- [Upravlyayemoye zabyivaniye FUM](upravlyayemoye-zabyivaniye-FUM.md)
- [Nablyudayemyij vkhodnoj signal](nablyudayemyij-vkhodnoj-signal.md)
- [Dispetcher avtomatizacij FUM](dispetcher-avtomatizacij-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-08 18:57:20 MSK — Dobavitj ograzhdyonnoye vozobnovleniye posle razryiva svyazi](../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/zapros.md)
- [iskhodnyij zapros 2026-07-31 13:23:13 MSK - Utochnitj issledovateljskuyu funkciyu mekhanizma sna FUM](../Zhurnal/2026-07-31_13-23-13_MSK_utochnitj-issledovateljskuyu-funkciyu-mekhanizma-sna-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-31 13:17:46 MSK - Zakrepitj mekhanizm sna FUM](../Zhurnal/2026-07-31_13-17-46_MSK_zakrepitj-mekhanizm-sna-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-08 20:11:56 MSK -->
<!-- content-sha256: sha256:e22e30652101be988294ed4871a5a9ff98955dcd2e12ab9b33f47534b61b2004 -->
<!-- FUM-MD-RECENCY:END -->
