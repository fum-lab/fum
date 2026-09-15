# Otchyot 2026-09-11 01:56:50 MSK - Proveritj paketyi FUMA iz klona

Opublikovannyij kommit paketov poluchen v chistyij klon. Podtverzhdenyi chistota do sborki, otsutstviye prezhnikh putej v iskhodnikakh i otkaz chteniya prezhnego kataloga vnutri vneshnej pesochnicyi. Vse 133 testa, chetyire Release-sborki i pyatj sinteticheskikh profilej zavershilisj uspeshno. Ispolnyayemyiye bajtyi paketov ne izmenyalisj.

## Profilj vremeni vyipolneniya

| Stadiya                | Dliteljnostj | Granicyi i sposob izmereniya                         |
| --------------------- | ------------ | -------------------------------------------------- |
| Klonirovaniye          | sm. nizhe     | Pryamoj uchtyonnyij zapusk Git                         |
| Sborki i testyi        | sm. nizhe     | Kazhdyij zapusk uchtyon; time izmeryayet process i RSS   |
| Sinteticheskiye profili | 1,34 s       | Summa time real; otkryityiye dannyiye vne Git            |

Granica profilya: tekusjhij etap 2026-09-11; ne vklyuchayet predyidusjhij import, ozhidaniye otveta, finaljnuyu peredachu. Vlozhennyiye vremena ne summiruyutsya povtorno. FIFO ne primenyalsya. Znacheniya time okruglenyi samim sistemnyim instrumentom; verkhneurovnevaya obyortka sokhranyayet nanosekundyi otdeljno.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                 | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj 0176] Poluchitj opublikovannyiye iskhodniki paketov v chistyij klon                 | 8,654 s      | uspeshno   |
| [Korenj 0176] Proveritj chistyij opublikovannyij klon i zapret staryikh katalogov          | 0,878 s      | uspeshno   |
| [Korenj 0176] Testyi KontejnerNablyudenij v izolirovannom chistom klone                  | 11,903 s     | uspeshno   |
| [Korenj 0176] Release-sborka KontejnerNablyudenij v izolirovannom chistom klone         | 6,278 s      | uspeshno   |
| [Korenj 0176] Testyi SnimokAgentskojZadachi v izolirovannom chistom klone                | 18,698 s     | uspeshno   |
| [Korenj 0176] Release-sborka SnimokAgentskojZadachi v izolirovannom chistom klone       | 10,019 s     | uspeshno   |
| [Korenj 0176] Testyi StatistikaVyizovov v izolirovannom chistom klone                    | 21,209 s     | uspeshno   |
| [Korenj 0176] Release-sborka StatistikaVyizovov v izolirovannom chistom klone           | 9,622 s      | uspeshno   |
| [Korenj 0176] Testyi ArkhivnyijSnimokZadachi v izolirovannom chistom klone                 | 23,633 s     | uspeshno   |
| [Korenj 0176] Release-sborka ArkhivnyijSnimokZadachi v izolirovannom chistom klone        | 12,314 s     | uspeshno   |
| [Korenj 0176] Sinteticheskij Release-profilj kontejner-zapisj iz chistogo klona         | 0,453 s      | uspeshno   |
| [Korenj 0176] Sinteticheskij Release-profilj kontejner-vosstanovleniye iz chistogo klona | 0,022 s      | uspeshno   |
| [Korenj 0176] Sinteticheskij Release-profilj snimok iz chistogo klona                   | 0,323 s      | uspeshno   |
| [Korenj 0176] Sinteticheskij Release-profilj statistika iz chistogo klona               | 0,281 s      | uspeshno   |
| [Korenj 0176] Sinteticheskij Release-profilj arkhiv-obolochek iz chistogo klona           | 0,322 s      | uspeshno   |
| [Korenj 0176] Sveritj rezuljtatyi profilej, binarniki i neizmennostj klona             | 0,178 s      | uspeshno   |
| [Korenj 0176] Sveritj kontroljnuyu tochku vosproizvodimosti paketov                     | 39,62 s      | neuspeshno |
| [Korenj 0176] Svyaznostj i publikacionnaya chistota posle predprosmotra otchyota           | 38,456 s     | neuspeshno |
| [Korenj 0176] Proveritj publikacionnyiye puti po shtatnomu CLI repo-root                 | 23,197 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 226,06 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Rezuljtat paketov

Kontejner proshyol 28 testov Swift Testing; snimok, statistika i arkhiv — po 35 XCTest, vsego 133 bez otkazov. Chetyire Release-sborki uspeshnyi. Vosemj zapuskov zanyali 113,59 s po `time real`, maksimum RSS — 599 212 032 bajta; znacheniya vklyuchayut kompilyator. Pyatj Release-profilej zanyali 1,34 s, maksimum RSS — 12 451 840 bajt. Metriki funkcii i processa imeyut raznuyu granicu i ne summiruyutsya drug s drugom.

Profilj kontejnera zapisal i vosstanovil 524 288 bajt s sovpavshimi khyeshami; snimok obrabotal 32 nablyudeniya i sokhranil nulevoj prirost posle povtorov; statistika uchla 32 vyizova; arkhiv na 1 000 000 bajt sluzhebnyikh obolochek poluchil odinakovyij snimok v chetyiryokh rezhimakh, vklyuchaya otsutstviye istochnika. Fajlovyij kyesh ne ochisjhalsya. Resheniye ob optimizacii: ispolnyayemyiye bajtyi sokhranenyi, novuyu optimizaciyu v migraciyu ne vvoditj; eto neboljshiye vosproizvodimyiye vkhodyi, bez utverzhdeniya o predeljnoj nagruzke.

[Komandyi vosproizvedeniya](../../Prilozheniya/FUMA/proverka-paketov.md) ispoljzuyut toljko tekusjhij FUM i ustanovlennyij Swift. [Materialyi](materialyi/) soderzhat chistuyu granicu klona, rezuljtatyi kazhdogo zapuska, metriki i SHA-256 Release-produktov. Binarniki i syiryiye logi ne dobavlenyi v Git. Iskhodniki v chistom klone ostalisj neizmennyimi posle proverok. Koordinator prinyal eti rezuljtatyi kak vosproizvodimostj chetyiryokh paketov na nablyudyonnoj platforme i predostavil sleduyusjheye otdeljnoye okno prilozheniya.

## Proverki

Rezuljtatyi kazhdogo processa sokhranyayutsya v mashinnyikh materialakh. V konsoljnom vyivode pervyikh testov Swift obnaruzhilasj nevalidnaya posledovateljnostj UTF-8; Python-sborsjhik metrik ostanovilsya uzhe posle uspeshnogo uchtyonnogo testa. Iskhodniki i testyi ne povtoryalisj: metriki izvlechenyi iz sokhranyonnogo vyivoda s zamenoj oshibochnyikh kodovyikh yedinic toljko dlya otobrazheniya, uspeshnyij kod podtverzhdyon iskhodnoj zapisjyu obyortki. Eto oshibka chteniya diagnosticheskogo vyivoda, a ne padeniye Swift-testov.

Podgotovka dopuska snachala vyizvala svyaznostj do shtatnogo predprosmotra upravlyayemogo bloka; zasjhita praviljno otklonila ostavshijsya shablon. Zatem skaneru putej oshibochno peredan flag drugogo instrumenta; fakticheskij kontrakt `--repo-root` vosstanovlen, korrektnyij uchtyonnyij zapusk uspeshen. Eti otkazyi ne yavlyayutsya defektami validatorov i ne menyayut rezuljtatyi Swift. Koordinator poruchil sokhranitj adresnyiye faktyi do obsjhej registracii cherez budusjhij allocator; novyiye nomera sboyev ne naznachalisj. Raneye sokhranyonnyij pryamoj vyizov planovogo generatora vne obyortki ostayotsya kandidatom novogo proyavleniya susjhestvuyusjhego 0025; povtornyij uchyot ne sozdayot zadnim chislom kvitanciyu pervogo zapuska.

## Resheniya i ogranicheniya

- Paketnyiye sborki vyipolnyayutsya iz publichnogo chistogo klona v yavnoj pesochnice; zapusk kompilyatora ne zavisit ot prezhnego rabochego repozitoriya.
- Podderzhka drugikh OS i staryikh macOS ne dokazana tekusjhim Mac. libmpv otnositsya k otdeljnoj priyomke prilozheniya.
- Dlya prilozheniya prinyat manifest iskhodnyikh i kanonicheskikh khyeshej bez syirogo publichnogo kommita chastnyikh rabochikh putej; originalyi sokhranyayutsya.
- Obsjhij dokumentacionnyij dopusk bez lokaljnogo graph.json ostayotsya zadachej 0203 i ne podmenyayetsya uspeshnyimi paketnyimi testami.

## Istochniki

- [Iskhodnyiye komandyi i utochneniya](zapros.md).
- [Rezuljtat perenosa](../2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:12:30 MSK -->
<!-- content-sha256: sha256:240fd0b348b39879e764fc1ceb24837ef4af468c5612f3e287fdfa92030e94d5 -->
<!-- FUM-MD-RECENCY:END -->
