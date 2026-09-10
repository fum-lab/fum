# Statistika vyizovov dlya razvitiya avtomatizacij

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0045 -->

FUM dolzhen dolgovechno sokhranyatj i nakaplivatj nablyudeniya o vyizovakh instrumentov i avtomatizacij vmeste s proiskhozhdeniyem. Iz etikh sobyitij vosproizvodimo stroitsya statistika dlya vyiyavleniya potrebnosti v sleduyusjhem urovne avtomatizacii i proverki yeyo poljzyi.

Yedinica nablyudeniya razlichayet pryamoye obrasjheniye modeli, operaciyu runtime, zapusk avtomatizacii i yeyo vlozhennyij shag. Sokhranyayutsya dostupnyiye identichnostj zadachi i vyizova, instrument i nablyudyonnaya versiya, iniciator, dokazannyij roditelj, vremya s metodom izmereniya, rezuljtat i tochnaya ssyilka na istochnik. Otsutstvuyusjhiye polya ostayutsya neizvestnyimi. Svyazj po vremeni yavlyayetsya gipotezoj i ne prevrasjhayetsya v dokazannoye proiskhozhdeniye.

Neizmenyayemoye sobyitiye i proizvodnaya svodka imeyut raznyiye zhiznennyiye ciklyi. Povtornoye chteniye, perezapusk i kopiya togo zhe zhurnala ne dobavlyayut vyizov; otdeljnyij nastoyasjhij zapusk s temi zhe argumentami ostayotsya otdeljnyim. Nesovpavshiye bajtyi odnogo klyucha trebuyut yavnogo razbora sostoyaniya ili konflikta. Zakryityiye pervichnyiye zapisi ne perepisyivayutsya dlya zapolneniya otsutstvovavshikh polej.

## Semanticheskiye svyazi

- **dopolnyayet:** [nablyudayemoye sostoyaniye agentskogo runtime i interfejsa](🟡-nablyudayemoye-sostoyaniye-agentskogo-runtime-i-interfejsa.md) — dobavlyayet istoriyu ispoljzovaniya instrumentov i izmereniye povtoryayemoj rabotyi.

## Kriterii proverki

- Povtornyij import zavershyonnogo prefiksa i vosstanovleniye posle preryivaniya dayut te zhe sobyitiya i schyotchiki; nedopisannyij khvost ne prinimayetsya. Izmenivshijsya uzhe prinyatyij istochnik obnaruzhivayetsya.
- Dva zapuska s odinakovyim nazvaniyem schitayutsya otdeljno; povtornyiye predstavleniya odnogo zapuska svyazyivayutsya toljko po podtverzhdyonnoj identichnosti. Neskoljko rezuljtatov i oprosyi ne sozdayut novyiye iskhodnyiye vyizovyi.
- Dlya stroki otchyota dostupnyi iskhodnyiye sobyitiya, versiya metoda raschyota, period i oblastj okhvata; chislo neizvestnyikh i isklyuchyonnyikh sobyitij vidno.
- Dliteljnostj vlozhennyikh shagov ne pribavlyayetsya k vremeni roditeljskogo zapuska kak nezavisimoye vremya. Zaderzhka mezhdu zapisyami JSONL ne vyidayotsya za izmereniye ispolneniya. Neizvestnyij iskhod ne schitayetsya uspekhom.
- Sravneniye pokazyivayet chastotu pryamyikh modeljnyikh vyizovov i povtoryayemyikh posledovateljnostej na sopostavimyij epizod, vremya, neozhidannyiye otkazyi, povtornuyu rabotu i polnotu proiskhozhdeniya. Ozhidayemyij RED i shtatnoye ozhidaniye otdelyayutsya ot oshibki i retry.
- Kazhdaya evristika khranit osnovaniye, znamenatelj, oblastj primeneniya, vyibrannyij porog pri yego nalichii i kriterij proverki. Perechenj rasshiryayem; odnogo universaljnogo poroga net.
- Kandidat sleduyusjhej avtomatizacii svyazyivayetsya s nablyudayemyimi epizodami. Sravneniye do/posle podtverzhdayet poleznostj pri ravnom proverennom rezuljtate, vklyuchaya nakladnyiye raskhodyi sbora.
- Lokaljnyiye pervichnyiye dannyiye i publichnaya statistika razdelenyi. Normalizaciya ne eksportiruyet skryityiye rassuzhdeniya, sekretyi ili polnyiye argumentyi i rezuljtatyi instrumentov po umolchaniyu.

## Status i granicyi

Status — `🟡`: trebovaniye prinyato; [pervyij importyor JSONL](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0160-nakaplivatj-statistiku-vyizovov.md) realizuyetsya otdeljnyim ogranichennyim etapom. Imeyusjhiyesya JSONL i v4 dayut chastichnuyu nablyudayemostj; ikh nalichiye ne oznachayet podklyuchyonnyij obsjhij sborsjhik. Sam otchyot ne razreshayet avtomaticheski izmenyatj polnomochiya, kod ili vneshneye sostoyaniye.

## Istochniki trebovanij

- [Komanda o nakoplenii statistiki i proiskhozhdenii vyizovov](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).
- [Nakoplennyiye rezuljtatyi pervichnogo audita](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/otchyot.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:20:29 MSK -->
<!-- content-sha256: sha256:c6eb6009308df808310597d7a8a17987355147f2cbe92020978da41a735028c4 -->
<!-- FUM-MD-RECENCY:END -->
