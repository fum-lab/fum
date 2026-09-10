+++
schema_version = 1
card_id = "FUM-STEP-0162"
status = "active"
+++
# Proveryatj polnotu dochernej postavki

## Zadacha

Avtomatizirovatj proverku tochnogo manifesta integriruyemoj dochernej postavki do pervoj zapisi: polnyij soglasovannyij nabor koda, testov i fikstur, iskhodnyij commit, otnositeljnyiye puti i SHA. Povtornoye ruchnoye perechisleniye fajlov zamenyayetsya proveryayemyim vkhodom.

## Pochemu sejchas

[FUM-SBOJ-0037/PROYAVLENIYE-0001 i 0002](../../Sboi/FUM-SBOJ-0037-nepolnaya-integraciya-dochernikh-fajlov.md) pokazali propusk scenariya profilya i bezrezuljtatnoye dopolneniye iz ekranirovannogo tekstovogo spiska Git. Kornevyiye testyi obnaruzhili oba sluchaya do kommita; ruchnoye vosstanovleniye ne zakryivayet povtoryayemyij mekhanizm.

## Kriterii zaversheniya

- Manifest poluchen iz tochnogo Git-snimka cherez NUL-razdelyonnyij spisok; kirillica, probelyi i specialjnyiye simvolyi ne teryayutsya.
- Soglasovan polnyij nabor fajlov; pustaya libo nepolnaya vyiborka, nedostupnyij obyyekt i nevernyij SHA ostanavlivayut rabotu do zapisi.
- Soglasovannaya predmetnaya granica otlichayetsya ot sluchajnogo propuska. Polnyij iskhodnyij manifest sokhranyayetsya otdeljno ot vyibrannogo sostava; isklyuchyonnyiye fajlyi i zavisimosti mezhdu razlichnyimi bazami imeyut yavnoye resheniye. Soderzhateljnyiye dokumentyi mogut prinimatjsya otdeljno ot sluzhebnoj istorii iskhodnoj vetvi; eto ne obyyavlyayetsya perenosom vsej istorii.
- Pri adaptacii proizvodnyikh ssyilok i navigacii sokhranyayutsya iskhodnyij i itogovyij SHA, a doslovnyiye komandyi i mashinnyiye zapisi ostayutsya neizmennyimi. Istoricheskiye identifikatoryi sboyev ne zamenyayutsya novyimi toljko iz-za otsutstviya ikh kartochek v prinimayusjhej baze.
- Sokhranyayetsya granica chuzhogo checkout i zapret importa chuzhikh instrukcij navyika; sobstvennyiye izmeneniya v celi ne perezapisyivayutsya.
- RED/GREEN pokryivayet oba nablyudayemyikh proyavleniya, konflikt celi, povtornyij import i otkaz chastichnoj postavki.
- Profilj i sravneniye s prezhnim sposobom pokazyivayut nakladnyiye raskhodyi i chislo ustranyonnyikh ruchnyikh vyizovov pri ravnom rezuljtate.

## Istochniki

- [Proyavleniya sboya 0037](../../Sboi/FUM-SBOJ-0037-nepolnaya-integraciya-dochernikh-fajlov.md).
- [Iskhodnyij zapros o sleduyusjhem urovne avtomatizacii](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).
- [Soglasovannaya granica postavki vselennoj i yeyo iskhodnyij sostav](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/materialyi/postavki/vselennaya-iskhodnyij-manifest.json): 67 predmetnyikh fajlov iz 77; sluzhebnyiye zavisimosti iskhodnoj vetvi trebuyut otdeljnoj integracii.


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 17:24:00 MSK -->
<!-- content-sha256: sha256:35125cb87514d38ce35bcf79aaa967f15d18de161a250a334b2d89c95623db68 -->
<!-- FUM-MD-RECENCY:END -->
