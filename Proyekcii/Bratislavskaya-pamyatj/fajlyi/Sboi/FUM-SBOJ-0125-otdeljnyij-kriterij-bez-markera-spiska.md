+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0125"
"статус" = "активна"
+++
# Otdeljnyij kriterij zapisan bez markera spiska

## Nablyudayemyij sboj

Polnaya priyomka obyyedinyonnoj postavki ostanovilasj na pervom testovom nabore: istoricheskij chitatelj kriteriyev otverg samostoyateljnyij abzac STEP0182 bez markera spiska. Kanonicheskij reyestr prisoyedinyal etot abzac k predyidusjhemu punktu i sokhranyal vosemj kriteriyev.

## Granica povtoreniya

Samostoyateljnoye trebovaniye vnutri razdela kriteriyev zapisano bez markera otdeljnogo punkta. Podderzhannoye prodolzheniye susjhestvuyusjhego punkta i ustarevsheye ozhidaniye versii ruchnogo rezhima otnosyatsya k inyim granicam. Celj vosstanovleniya — devyatj otdeljnyikh kriteriyev0182 s polnyim sokhraneniyem iskhodnyikh slov.

## Proyavleniya

### FUM-SBOJ-0125/PROYAVLENIYE-0001

[Polnaya popyitkac2ab6a7a](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/23_c2ab6a7a-0333-431a-80a8-e6d1b47cbdfd.json) zavershilasj kodom1 za602.053971459s na shage16 iz87: v189testakh odna oshibka,34propusjhenyi. Predyidusjhiye15proverok uspeshnyi. [Lokalizaciya](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-otkaza-kriteriyev.json) na tom zhe otpechatke prochitala204kartochki, uspeshno razobrala203 i vyiyavila yedinstvennyij otkaz0182. Dliteljnostj polnoj popyitki otnositsya ko vsemu processu, a ne k odnomu kriteriyu.

## Ozhidaniye i klassifikaciya

Kazhdyij otdeljnyij kriterij imeyet sobstvennyij marker spiska. Ispravlyayetsya oformleniye dokumenta, a ne oslablyayetsya parser. Nomer naznachen obsjhim raspredelitelem po sobyitiyu `context-step0182-list-01a0930d-c2ab6a7a`; iskhodnaya komanda sokhranena v zaprose.

## Mekhanizm i sistemnoye ustraneniye

[Shtatnyij paket](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/kvitanciya-kriteriya-0182.json) dobavil toljko dva simvola markera pered prezhnim abzacem. Vse slova i vosemj prezhnikh punktov sokhranenyi; abzac stal devyatyim kriteriyem. Predlagayetsya rannyaya proverka odinakovogo razdeleniya kriteriyev kanonicheskim reyestrom i primenimyim istoricheskim chitatelem. Eta obsjhaya mera yesjhyo ne realizovana i ne otkryivayet novoye napravleniye tekusjhej priyomki.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) sokhranyayet rannyuyu proverku formatnoj granicyi po osnovaniyu FUM-SBOJ-0125/PROYAVLENIYE-0001.

## Kriterii zakryitiya

Oba chitatelya vyidelyayut devyatj samostoyateljnyikh kriteriyev0182 s sokhranyonnyim soderzhaniyem. Rannyaya proverka otlichayet poteryannyij marker novogo kriteriya ot dopustimogo prodolzheniya punkta i obnaruzhivayet raskhozhdeniye do dorogoj proyekcii. Uspekh lokaljnogo ispravleniya sam po sebe ne dokazyivayet etu obsjhuyu meru.

## Nablyudayemoye vosstanovleniye

Adresnyij povtor25 proshyol chteniye kartochek i otkryil otdeljnoye ustarevsheye ozhidaniye versii; ono ne vklyucheno v dannoye proyavleniye. Posle yego nezavisimogo ispravleniya [prezhnij test v povtore26](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/26_5ef8de0d-1c24-455d-a869-8318c6d2cf82.json) zavershilsya kodom0 za1.449292750s. Polnaya priyomka ostayotsya otdeljnoj nezavershyonnoj rabotoj.

## Istochniki

- [Komanda raspredeleniya i iskhodnyij zapros](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).
- [Otchyot](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/otchyot.md).
- [Ispravlennaya kartochka0182](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:05:57 MSK -->
<!-- content-sha256: sha256:5b67889a20b89e7ed75ddb0b8acbf2f9ba4fad5b1704f3a9aa061d2202b28953 -->
<!-- FUM-MD-RECENCY:END -->
