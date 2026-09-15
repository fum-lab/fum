# Granicyi povtornogo ispoljzovaniya dlya 0165

Staticheskoye chteniye tochnyikh Git-obyyektov podtverdilo dostupnyiye interfejsyi tryokh komponentov. Eto vkhod planirovaniya; sovmestimostj pri sovmestnom ispolnenii, novyij adapter i chitayusjhaya komanda 0165 yesjhyo ne proverenyi.

## Snimok FUMA

V kommite `9c39c9b3fde83c4ce11ba101897c1298c68d436d` paket SnimokAgentskojZadachi predostavlyayet Reduktor(zadacha:), prinyatj(_:) i snimok. Dlya podderzhannyikh polej yego mozhno rassmatrivatj kak komponent obrabotki v pamyati. CLI sobratj zapisyivayet kontejner i sam po sebe ne vyipolnyayet ogranicheniye pervogo chitayusjhego sreza.

Predelyi — 256 nablyudenij i 8 istochnikov. Takt i godnoDo yavlyayutsya logicheskimi znacheniyami, a ne realjnyimi chasami ili otkalibrovannyim srokom godnosti. Otkaz delayet sootvetstvuyusjhij kanal nedostupnyim vnutri dannoj epokhi; posleduyusjhiye nablyudeniya togo zhe kanala ignoriruyutsya. Dlya novogo podtverzhdyonnogo sostoyaniya potrebuyetsya otdeljnaya epokha s novyim reduktorom i sokhraneniyem prezhnego istoricheskogo snimka. Smena epokhi sama ne dokazyivayet vosstanovleniya. Resursnyiye chisla i token_limit_reached ne vkhodyat v fiksirovannyij nabor polej snimka.

Opornyij iskhodnik: `9c39c9b3fde83c4ce11ba101897c1298c68d436d:Приложения/FUMA/Packages/СнимокАгентскойЗадачи/Sources/СнимокАгентскойЗадачи/Редуктор.swift`, stroki 3–24, 40–60 i 103–117.

## Statistika vyizovov

V tom zhe kommite predostavlenyi prochitatjPrefiks, UchyotVyizovov.prinyatj([SobyitiyeVyizova]) i otchyot(granica:). Modeli sokhranyayut iskhodnyiye pozicii i khyeshi vyizovov i rezuljtatov. Runtime-szhatiye i transportnyiye oshibki ne raspoznayutsya etim interfejsom.

Ogranichenyi razmer vkhoda i dopustimyij konec iskhodnogo sobyitiya: 268435456 bajt. Dopolniteljno ogranichenyi stroka do 4194304 bajt, chislo strok do 100000 i sobyitij do 8192. Tekusjhij sokhranyonnyij prefiks osnovnoj zadachi boljshe predela vkhoda. Narezka khvosta s perenumeraciyej ne sokhranyayet proiskhozhdeniye. Do otdeljnogo resheniya chteniye takoj statistiki ostayotsya yavno nepolnyim. Reader takzhe otklonyayet izmeneniye razmera ili vremennyikh metok fajla vo vremya prokhoda.

Opornyiye iskhodniki tochnogo kommita: `Приложения/FUMA/Packages/СтатистикаВызовов/Sources/СтатистикаВызовов/Контракт.swift`, stroki 8–17, 19–50 i 71–83; `Приложения/FUMA/Packages/СтатистикаВызовов/Sources/СтатистикаВызовов/Чтение.swift`, stroki 5–20 i 89–103.

## Chitatelj soobsjhenij 0177

V kommite `6b1860591deb1d669f5f5ae1bd03336170fb8fce` funkciya prochitatj_soobsjheniya i CLI prochitatj-soobsjheniya-zadachi.py vozvrasjhayut fum.soobsjheniya-zadachi.1. Otdeljnaya komanda obrabotatj-soobsjheniya-zadachi.py s podkomandoj ostatok vozvrasjhayet fum.ostatok-soobsjhenij.1. Eti operacii neljzya smeshivatj: samo chteniye vsekh soobsjhenij ne vyichislyayet vyipolnennostj i ne sozdayot otmetok obrabotki.

Vyizov chitatelya s python3 -B i --bez-zapisi isklyuchayet sobstvennuyu zapisj bajtkoda, kyesha i zamkov. Bez rezhima --bez-zapisi CLI mozhet pisatj. Polnota i kod zaversheniya otnosyatsya k vyibrannomu snimku i proiskhozhdeniyu soobsjhenij, a ne k tekusjhemu sostoyaniyu vsej zadachi; kod 3 ne raven pustomu uspeshnomu rezuljtatu, kod 2 oznachayet otkaz.

Reader vozvrasjhayet user response_item s proiskhozhdeniyem, poziciyami i dublyami. Assistant, API i runtime-sobyitiya v etot rezuljtat ne vkhodyat. Syiroj_obyyekt soderzhit payload; vneshnyaya vremennaya metka JSONL ne perenositsya, poetomu dlya neyo nuzhen otdeljnyij razbor po podtverzhdyonnoj pozicii. Predel stroki — 64 MiB; obsjhego predela 256 MiB v chitatele net. Dopisj posle otkryitiya otrazhayetsya kak pozdnij khvost ogranichennogo snimka. Eto inoj kontrakt, chem otkaz Swift-reader pri izmenenii istochnika. Boljshoj payload so vlozheniyem ne peredayotsya modeli celikom: rabochemu srezu nuzhnyi vyibrannyiye polya i tochnyiye ukazateli.

Opornyij iskhodnik: `6b1860591deb1d669f5f5ae1bd03336170fb8fce:Инструменты/fum-svyaznostj-rabochej-sessii/scripts/сообщения_задачи.py`, stroki 22–28, 132–161, 187–199, 213–243 i 256–321. Vmeste s nim zakreplyayetsya zavisimostj `Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py` iz togo zhe kommita.

## Minimaljnaya granica budusjhego soyedineniya

Planiruyemyij adapter ispoljzuyet susjhestvuyusjhij JSON-vyivod 0177, otdeljno prinimayet vyibrannyiye API/runtime-svideteljstva i formiruyet novuyu epokhu snimka toljko dlya podderzhannyikh polej. Realjnyiye vremena i resursnyiye faktyi sokhranyayutsya kak otdeljnyiye dokazateljstva. Gotovyij otchyot statistiki vklyuchayetsya lishj s dejstviteljnoj oblastjyu okhvata; boljshoj nepodderzhannyij istochnik ostayotsya pomechennyim kak nepolnyij. Universaljnaya promezhutochnaya skhema i perepisyivaniye Python-reader na Swift dlya etogo ne trebuyutsya.

Do soyedineniya proveryayutsya identichnostj zadachi i zavershyonnaya granica, povtor i dopisj, razlichiye vremeni sobyitiya i polucheniya, dva raznyikh otkaza s odinakovyim tekstom, vosstanovleniye toljko sootvetstvuyusjhego kanala i otsutstviye vyidumannyikh vremyon i pozicij u izobrazheniya. Zatem nuzhnyi RED/GREEN i profilj pri ravnoj polnote obyazateljstv. Staticheskoye chteniye koda ne zamenyayet eti rezuljtatyi.

## Istochniki

- [Zapros etapa](../zapros.md), [otchyot](../otchyot.md), [chastnyiye istochniki i ikh versii](istochniki/nablyudayemostj/source-index.md).
- [Plan pervoj realizacii](../../../Planirovaniye/rabochij-kontekst-zadachi/README.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 04:25:12 MSK -->
<!-- content-sha256: sha256:a94fdbf68a69f4be309f25bdb98866ffcdcd054b6ff32a86e468085e9f6f60ba -->
<!-- FUM-MD-RECENCY:END -->
