# Otchyot 2026-09-19 03:26:05 MSK - Sokratitj zapuski Git pri sravnenii derevjyev

Predyidusjhaya kontroljnaya tochka 509d68aff1bef437dc4721188d5d9cf39d64e71c opublikovana v fuma; OID podtverzhdyon. Realjnyij putj sozdaniya vyipolnil ranniye sverki za 0,561 i 0,566 s, chteniye komand za 8,304 s, polnuyu svyaznostj za 38,794 s. Prodolzheniye ostayotsya otkryityim, D22 na pauze.

V sokhranyonnom cProfile J25 funkciya otnosheniya vyizvana 123 raza, yeyo vlozhennoye vremya 11,029 s; pryamyiye vyizovyi Git iz neyo — 488. Eto verkhnyaya granica 123 ustranyayemyikh processov sredi 34 646, a ne izmerennaya ekonomiya vsego nabora. Boljshogo uskoreniya ot etogo uzkogo izmeneniya ne ozhidayetsya.

Dva chteniya derevjyev zamenenyi odnim s proverkoj chisla i formata otvetov. Proverki predka, patchej, sliyanij i vladeljcev sokhranenyi. Celj proveryayetsya na polnuyu shestnadcaterichnuyu formu do proverki predka; tip commit po-prezhnemu podtverzhdayet vyizyivayusjhij snimok.

## Profilj vremeni vyipolneniya

| Stadiya                | Dliteljnostj          | Granicyi i sposob izmereniya                |
| --------------------- | --------------------- | ----------------------------------------- |
| Nablyudeniye do         | 0,648472 s            | Mediana tryokh otkryityikh nezavisimyikh fikstur |
| Nablyudeniye posle      | 0,635116 s            | Tot zhe profilj so schyotchikom vyizovov       |
| Primeneniye do / posle | 1,827871 / 1,827904 s | Medianyi; razlichiya prakticheski otsutstvuyut |
| Novyiye regressii GREEN | 1,934 s               | 6 testov unittest                         |
Granica profilya: [do](materialyi/profilj-do.json) i [posle](materialyi/profilj-posle.json) poluchenyi odnoj instrumentirovannoj proceduroj na tryokh nezavisimyikh otkryityikh repozitoriyakh. Podgotovka isklyuchena, kyesh tyoplyij; vlozhennyiye stadii ne summiruyutsya povtorno. Chteniya derevjyev cherez modulj plana umenjshilisj s 9 do 6 v kazhdom povtore. Ustojchivoye uskoreniye polnogo cikla tremya povtorami ne dokazano.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:c3c5ee636513c3e6abb3d1ad85ecfcad8b9070168a3379acf6df5d58eab74e92 -->

| Vyizov                                                    | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------- | ------------ | --------- |
| [korenj] RED paketnogo sravneniya derevjyev J27            | 2,101 s      | neuspeshno |
| [korenj] Profilj do obyyedineniya chtenij derevjyev J27      | 8,315 s      | uspeshno   |
| [korenj] GREEN paketnogo sravneniya derevjyev J27          | 2,038 s      | uspeshno   |
| [korenj] Profilj posle obyyedineniya chtenij derevjyev J27   | 8,29 s       | uspeshno   |
| [korenj] Regressii obratnoj dostavki J27                 | 69,194 s     | uspeshno   |
| [korenj] Polya Zhurnala J27                                | 0,088 s      | uspeshno   |
| [korenj] Publikacionnaya chistota J27                      | 34,028 s     | uspeshno   |
| [korenj] Standartnaya priyomka nakoplennyikh optimizacij J27 | 1587,633 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1711,687 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

RED: 6 testov za 1,979 s, devyatj otkazov s uchyotom subTest. Posle izmeneniya GREEN: 6/6 za 1,934 s. Oba profilya zavershilisj uspeshno. Prezhniye regressii obratnoj dostavki: 29/29 za 61.694 s. Polnaya priyomka i novaya proyekciya poka ne vyipolnyalisj.

## Resheniya i ogranicheniya

Nezavisimyij analiz podtverdil granicu polnyikh OID v dvukh vyizyivayusjhikh putyakh i neobkhodimostj proverki formyi celi. Analiz toljko chital iskhodniki. Schyotchik ne sokhranyayet realjnyiye argumentyi i puti; prezhnij subprocess-nablyudatelj ne ispoljzovan, poskoljku yego razbor ne uchityivayet nachaljnyij flag no-replace-objects.

## Istochniki

- [iskhodnyij zapros](zapros.md).
- [profilj polnogo nabora J25](../2026-09-19_02-44-26_MSK_izmeritj-polnyij-nabor-proverok-reyestra/otchyot.md).

Povtornyij nezavisimyij prosmotr tryokh izmenyonnyikh Python-fajlov blokerov ne vyiyavil. Schyotchik vklyuchayet chteniye dereva pri proverke istochnika cherez modulj plana; on ne yavlyayetsya schyotchikom vsekh Git-processov.

Sozdaniye kontroljnoj tochki ostanovilosj do namereniya Git za 12,197 s: etap oshibochno nachat bez flaga priyomochnyikh raundov i sokhranil v3. Novyij ispolnitelj kontroljnyikh tochek trebuyet v4. Dve ranniye sverki proshli (0,600 i 0,548 s); iskhodniki, indeks i mashinnyiye zapisi sokhranenyi. Oshibochno zaproshennyij otdeljnyij fajl instrukcii otsutstvoval; primenimyij kontrakt najden v kanonicheskom SKILL.md.

Perekhod v3→v4 zdesj ne imeyet osnovaniya izmeneniya otchyotnoj obyortki; istoriya ne perepisyivayetsya. Vyibran dejstvuyusjhij putj itogovoj priyomki v3 po pravilam 000178/000188: standartnyij dokumentacionnyij smoke, proveritj-plan, zakryitiye, odnokratnoye zamyikaniye proyekcii. Novyij ispolnitelj kontroljnyikh tochek sam pryamo ne podderzhivayet itogovyij rezhim. Priyomka okhvatyivayet nakoplennyij kanonicheskij snimok; staryiye kontroljnyiye tochki ne obyyavlyayutsya otdeljnyimi zakryityimi otchyotami. Polnyij Swift-profilj ne vyibran: izmeneniya nakhodyatsya v dvukh Python-naborakh standartnogo kontura.

Svyazannaya dokumentaciya obnovlena: instrukciya sozdaniya kommita i instrukciya obratnoj dostavki. Poljzovateljskij zapusk FUMA i kornevoj README ne menyalisj; novyikh poljzovateljskikh komand prilozheniya etot etap ne vvodit.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 03:35:46 MSK -->
<!-- content-sha256: sha256:a978692b702519f5e872b52cd18886f3b17ef79c997dcec4f7b6d3eb74834278 -->
<!-- FUM-MD-RECENCY:END -->
