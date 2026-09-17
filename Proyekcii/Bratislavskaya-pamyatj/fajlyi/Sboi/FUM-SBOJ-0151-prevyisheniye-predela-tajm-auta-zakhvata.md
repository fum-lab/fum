+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0151"
"статус" = "активна"
+++
# Prevyisheniye dopustimogo tajm-auta zakhvata

## Nablyudayemyij sboj

Podgotovlennyij vyizov zakhvata polnogo dopuska peredal vneshnij tajm-aut3700s pri maksimume3600s. Zakhvat otkazal do sozdaniya svoyego kataloga i zapuska smoke; novoj zapisi proverochnogo zapuska ne poyavilosj. Eto oshibka parametra vyizova, a ne vyipolnennyij povtor polnogo nabora.

## Granica povtoreniya

Chislovoj predel v podgotovlennom vyizove vyikhodit za dopustimyij kontrakt zakhvata. Zdesj net ustanovlennoj poteri uzhe proizvedyonnogo vyivoda0141 ili pustoj orkestracii0008: posledneye otdeljno isklyuchayet dokazannyij predvariteljnyij otkaz. Nesovmestimyij rezhim svyaznosti0134 imeyet druguyu prichinu.

## Proyavleniya

### FUM-SBOJ-0151/PROYAVLENIYE-0001

[Pervichnoye svideteljstvo](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/nablyudeniye-rannego-otkaza-zakhvata.json) svyazyivayet dve paryi iskhodnyikh zapisej: vyizov13:57:51.841Z i otkaz13:57:52.791Z, zatem adresnuyu proverku otsutstviya kataloga i novoj zapisi13:58:09.803Z–13:58:09.942Z. Chetyire raw-diapazona iSHA proverenyi po JSONL. Komanda zakhvata vernula2 s bezopasnyim `capture-or-representation-failed`; oshibka ne sozdala kvitanciyu smoke. Sobstvennaya dliteljnostj capture ne izmerena otdeljno ot drugikh dejstvij vneshnego vyizova.

Vneshnij predel ispravlen na3600s pri vnutrennem3500s. Posleduyusjhiye fakticheskiye polnyiye progonyi uchityivayutsya otdeljno; ikh sobstvennyiye otkazyi ne otnosyatsya k etoj kartochke. Pri pervom adresnom poiske syiraya para ne byila najdena; pozdneye koordinator vosstanovil praviljnyiye zapisi, i oni sverenyi. Neizvestnyij rezuljtat ne zamenyalsya vyimyishlennoj kvitanciyej.

## Ozhidaniye i klassifikaciya

Podgotovka vyizova dolzhna vyibiratj dopustimyiye parametryi po opisaniyu instrumenta. Realizaciya korrektno otkazyivayet na nevernom predele do fajlovogo effekta; defekt zakhvata ili vyipolnennogo smoke ne ustanovlen. Eto otdeljnaya nedorabotka podgotovki vyizova.

## Mekhanizm i sistemnoye ustraneniye

Proverka parametrov obnaruzhila prevyisheniye verkhnego predela. Minimaljnaya sistemnaya mera — yavnoye opisaniye diapazona i proveryayemyij primer soglasovaniya vneshnego tajm-auta zakhvata s vnutrennim predelom komandyi. Sokhranyayutsya rannij otkaz, otsutstviye kataloga/zapuska i zapret avtomaticheskogo povtora pri neizvestnom iskhode. Izmeneniye proveryayusjhego koda zdesj ne vyipolnyalosj.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — ponyatnyiye usloviya i proveryayemyij primer parametrov po proyavleniyu0001.

## Kriterii zakryitiya

Opisaniye i vosproizvodimyij primer zadayut dopustimyij diapazon i soglasovannyiye predelyi. Proverenyi rannij otkaz prevyisheniya do kataloga/processa i dopustimyij vyizov; otkaz podgotovki ne schitayetsya proshedshim polnyim progonom. Chastnoye ispravleniye chisla bez sistemnogo podtverzhdeniya ne zakryivayet kartochku.

## Istochniki

- [Diagnosticheskoye porucheniye i granicyi](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/zapros.md).
- [Naznacheniye0151](../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/materialyi/naznacheniye-0151.json) byilo sokhraneno do polucheniya pozdnego pervichnogo izvlecheniya; yego istoricheskoye osnovaniye ne perepisano.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 17:48:33 MSK -->
<!-- content-sha256: sha256:cb46dce0c3ce3b144563870e1f747b20dff60eb6aa311e630c85182f546c0449 -->
<!-- FUM-MD-RECENCY:END -->
