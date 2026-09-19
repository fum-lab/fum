# Otchyot 2026-09-19 03:08:13 MSK - Podklyuchitj rannij sostav k sozdaniyu kommita

Predyidusjhij profilj opublikovan v de34beea6a063321b47f5578b04f8a6371c62114; udalyonnyij OID podtverzhdyon. Posle nego guard vernul kod 3, rabota prodolzhayetsya; D22 ostayotsya na pauze.

Celj etapa — podklyuchitj uzhe integrirovannuyu sverku materialov do chteniya JSONL i dorogoj svyaznosti. Novaya podgotovka dolzhna khranitj yavnyij konechnyij perechenj razreshyonnyikh putej; staryiye kvitancii sokhranyayut putj vosstanovleniya. Novoye sozdaniye po prezhnej podgotovke bez spiska zakryito otkazyivayet. Realizaciya podklyuchena i adresno proverena; polnaya priyomka yesjhyo ne vyipolnena.

## Profilj vremeni vyipolneniya

| Stadiya                           | Dliteljnostj | Granicyi i sposob izmereniya                                                          |
| -------------------------------- | ------------ | ----------------------------------------------------------------------------------- |
| Prezhnyaya rannyaya sverka J25        | 0,548 s      | Sobstvennyij monotonnyij interval uzhe susjhestvuyusjhego CLI                               |
| Obyichnaya kontroljnaya tochka        | 1,771 s      | Otkryitaya fikstura, sozdaniye i povtornoye chteniye; podgotovka fiksturyi isklyuchena       |
| Sliyaniye                          | 1,707 s      | Otkryitaya fikstura s dvumya roditelyami; podgotovka fiksturyi isklyuchena                 |
| Nepolnyij sostav                  | 0,231 s      | Vesj otkaz sozdaniya; rannyaya sverka vnutri nego 0,144 s, pervichnyij JSONL ne chitayetsya |
| Dve ranniye sverki uspeshnogo puti | 0,304 s      | Vlozhennaya summa dvukh posledovateljnyikh stadij obyichnogo kommita                       |

Granica profilya: [otkryityij profilj](materialyi/profilj-sozdaniya.json) ispoljzuyet monotonnyiye tajmeryi i cProfile.runcall. Vlozhennyiye stadii ne pribavlyayutsya ko vsemu scenariyu. Eto odin zapusk kazhdogo scenariya, a ne statisticheskoye sravneniye do/posle. Nakladnyiye raskhodyi uspeshnogo puti sokhranenyi yavno; uskoreniye polnogo nabora ne zayavlyayetsya. Syiroj cProfile ostayotsya vne Git.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                 | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------- | ------------ | --------- |
| [korenj] RED rannego sostava pered sozdaniyem kommita                  | 3,465 s      | neuspeshno |
| [korenj] GREEN rannego sostava pered sozdaniyem kommita                | 3,989 s      | uspeshno   |
| [korenj] Susjhestvuyusjhiye proverki sozdaniya kommita posle rannego sostava | 31,526 s     | uspeshno   |
| [korenj] Regressii rannego okhvata J26                                 | 7,654 s      | uspeshno   |
| [korenj] Profilj sozdaniya i rannego otkaza J26                        | 4,572 s      | uspeshno   |
| [korenj] Polya Zhurnala J26                                             | 0,088 s      | uspeshno   |
| [korenj] Publikacionnaya chistota J26                                   | 34,691 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 85,985 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:49561e3aea883e70344cba4f74e64935a3e5818f81c60e3aee1593adfeb0b8f8.
Kontekst soderzhimogo: sha256:f1a3e3d6d92bffe3d38c13876a1d4536ca093fcb77d0daea1654e3f2ef731e25.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

RED: 5 testov za 3,323 s, chetyire ozhidayemyikh otkaza pokazyivayut pozdneye obnaruzheniye nepolnogo sostava i drejfa, otsutstviye obyazateljnogo spiska i dopusk staroj podgotovki bez kvitancii. Posle izmeneniya GREEN: 5/5 za 3,855 s. Prezhniye testyi sozdaniya: 27/27 za 31,396 s. Otdeljnyiye regressii rannego okhvata: 16/16 za 7,566 s. Vse iskhodyi sokhranenyi otchyotnoj obyortkoj.

Nezavisimyij analiz iskhodnikov blokerov ne vyiyavil; on ne podmenyayet zapusk testov. Proverenyi poryadok rannikh sverok, vosstanovleniye prezhnikh kvitancij i sokhraneniye polnoj svyaznosti. Pervyij apply_patch ne sovpal s kontekstom stroki i otkazal do izmeneniya fajlov; ispravlennyij tochnyij patch primenilsya.

Posle vosstanovleniya konteksta shtatnyij chitatelj vnovj prochital ostatok iskhodnogo JSONL bez zapisi. Istochnik polnyij, nepolnogo i neproverennogo khvosta net; vesj istoricheskij ostatok obrabotannyim ne obyyavlyayetsya.

## Resheniya i ogranicheniya

Obyortka podderzhivayet zaraneye zadannyij identifikator zapuska; budusjhiye imena zapisej mozhno perechislitj do podgotovki. Nepredvidennyij zapusk menyayet poryadkovyij nomer i trebuyet novoj podgotovki, a ne avtomaticheskogo razresheniya vsego status. Rannij snimok pereproveryayetsya posle chteniya istochnika; polnyij priyomochnyij kontur ne oslablyayetsya.

## Istochniki

- [iskhodnyij zapros](zapros.md).
- [profilj J25](../2026-09-19_02-44-26_MSK_izmeritj-polnyij-nabor-proverok-reyestra/otchyot.md).

Novaya podgotovka v2 trebuyet yavnogo perechnya konechnyikh fajlov. Prezhniye v1-kvitancii vosstanavlivayutsya; v1 bez kvitancii trebuyet novoj podgotovki. Dve sverki ne yavlyayutsya atomarnoj zasjhitoj ot postoronnego pisatelya: sokhranyayutsya vladeniye derevom i zaklyuchiteljnyiye proverki. Kontroljnaya tochka ne oznachayet polnuyu priyomku ili integraciyu v master.

Pervaya podgotovka otkazala za 8,793 s iz-za nepodtverzhdyonnogo polnogo pervichnogo snimka; Git ne vyizyivalsya. Otdeljnoye chteniye zatem podtverdilo polnyij istochnik: nepolnyij khvost 0, dopisano posle snimka 0. Dlya novoj podgotovki naznachenyi novyiye privatnyiye fajlyi. Pri diagnostike oshibochno zaprosheno nesusjhestvuyusjheye imya modulya; tochnoye imya najdeno adresnyim poiskom.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 03:22:24 MSK -->
<!-- content-sha256: sha256:4938a909593a8eba87b1a0905d1ec358e5b82f60b2ec26dea20b0715670f0006 -->
<!-- FUM-MD-RECENCY:END -->
