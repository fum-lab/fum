+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0086"
"статус" = "активна"
+++
# Nepolnoye svideteljstvo utverzhdeniya o vneshnem istochnike

Kartochka sokhranyayet razryiv mezhdu utverzhdeniyem metadannyikh vneshnego istochnika i otdeljno dostupnyim podtverzhdayusjhim fragmentom.

## Nablyudayemyij sboj

V kommite `6d933f9d5085e2ec8541883231ad762df46ef2c8` stroka 7 kartochki istoricheskogo reglamenta YESIA utverzhdala: «Dokument soderzhit ogranicheniye kruga operatorov IS; prinadlezhnostj FUMA k nemu ne dokazana». Sokhranyonnyij fajl izvlecheniya soderzhit titul, oglavleniye i opredeleniye operatora YESIA, no ne ogranicheniye operatorov IS. Eto nablyudeniye ne dokazyivayet otsutstviya ogranicheniya v dokumente ili otsutstviya yego chteniya agentom; ono ustanavlivayet nepolnotu adresuyemogo svideteljstva.

## Granica povtoreniya

Utverzhdeniye o soderzhanii vneshnego dokumenta prevyishayet otdeljno sokhranyonnyij syiroj fragment, i polnoye soderzhimoye nedostupno dlya proverki. Metadannyiye nedostupnoj versii s yavno ukazannoj neizvestnostjyu syuda ne otnosyatsya. Svyazj s FUM-SBOJ-0012 vozmozhna po sile svideteljstva, no yego ustanovlennaya granica otnositsya k diagnosticheskim kartochkam i porozhdeniyu shagov; obyyedineniye mekhanizmov poka ne dokazano.

## Proyavleniya

- `FUM-СБОЙ-0086/ПРОЯВЛЕНИЕ-0001`: [zamechaniye koordinatora i otvet](../Zhurnal/2026-09-11_17-00-29_MSK_utochnitj-svideteljstvo-reglamenta-YESIA/zapros.md) k tochnomu kommitu `6d933f9d5085e2ec8541883231ad762df46ef2c8`; [kartochka istochnika](../Istochniki/URL/https/socium.gov35.ru/deyatelnost/gosudarstvennye-uslugi/.files/ReglamentESIA_2_42.pdf/source-index.md) i sosedneye izvlecheniye. Effekt — chitatelj ne mozhet proveritj odnu frazu po sokhranyonnomu materialu. Vosstanovleniye — utverzhdeniye zameneno yavnoj neproverennostjyu do polnogo aktualjnogo reglamenta; predmetnoye resheniye ne rasshireno.

## Ozhidaniye i klassifikaciya

Pravilo FUM-PRAVILO-000166 trebuyet sokhraneniya dostupnogo syirogo materiala i izvlecheniya. Podtverzhdena nedorabotka dostatochnosti sokhranyonnogo svideteljstva; istinnostj konkretnogo pravovogo ogranicheniya ne ustanovlena.

## Mekhanizm i sistemnoye ustraneniye

Gipoteza — pri sokrasjhenii usechyonnogo izvlecheniya v arkhive ne sopostavleno kazhdoye susjhestvennoye proizvodnoye utverzhdeniye s sokhranyonnyim fragmentom. Tochechnaya korrekciya sderzhivayet etot sluchaj. Ustojchivaya mera dolzhna proveryatj takuyu svyazj libo trebovatj yavnoj nepodtverzhdyonnosti; realizaciya i proveryayemaya regressiya v etom analiticheskom etape ne vyipolnyayutsya.

## Svyazannyiye shagi

- [FUM-STEP-0114](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) sokhranyayet etu granicu v obsjhem konture nedorabotok; osnovaniye — `FUM-СБОЙ-0086/ПРОЯВЛЕНИЕ-0001`.

## Kriterii zakryitiya

V vosproizvodimom scenarii metadannyiye s utverzhdeniyem bez podderzhivayusjhego fragmenta poluchayut yavnuyu nepodtverzhdyonnostj libo otkaz; utverzhdeniye s dostatochnyim sokhranyonnyim svideteljstvom prokhodit. Ogranichennaya ruchnaya korrekciya tekusjhego istochnika etogo kriteriya ne zakryivayet.

## Istochniki

- [Tekusjhaya komanda i pervichnoye sopostavleniye](../Zhurnal/2026-09-11_17-00-29_MSK_utochnitj-svideteljstvo-reglamenta-YESIA/zapros.md).
- [Sokhranyonnyij sloj istochnika](../Istochniki/URL/https/socium.gov35.ru/deyatelnost/gosudarstvennye-uslugi/.files/ReglamentESIA_2_42.pdf/source-index.md).
- [Smezhnaya diagnosticheskaya granica](FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 17:07:34 MSK -->
<!-- content-sha256: sha256:7934fffd25468fb30247ad3a891ed3ff35a7e3b4c9090ae6da695973a555b503 -->
<!-- FUM-MD-RECENCY:END -->
