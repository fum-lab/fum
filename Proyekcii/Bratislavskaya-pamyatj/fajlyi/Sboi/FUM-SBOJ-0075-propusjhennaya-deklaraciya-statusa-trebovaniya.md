+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0075"
"статус" = "активна"
+++
# Propusjhennaya deklaraciya statusa trebovaniya

## Nablyudayemyij sboj

Pervyij podgotovlennyij vkhod finansovogo trebovaniya 0069 ne soderzhal obyazateljnoj yavnoj stroki statusa v razdele «Status i granicyi». Identichnostj 🟡 byila v imeni fajla, no nastoyasjhij sborsjhik posle ustanovki pervoj stadii vernul `requirement body status is missing`. Priyom ostalsya negotovyim.

## Granica povtoreniya

Formirovaniye novoj kartochki trebovaniya bez obyazateljnogo predstavleniya statusa v yeyo tele. Otkaz dopustimogo vosstanovleniya uzhe ustanovlennogo chastichnogo rezuljtata otnositsya k 0059/0002 i ne schitayetsya vtoryim proyavleniyem etogo propuska. Dopusk protivorechivoj razmetki imeyet otdeljnyij mekhanizm proverki granic.

## Proyavleniya

- `FUM-СБОЙ-0075/ПРОЯВЛЕНИЕ-0001`: [iskhodnyij vkhod, otkaz i ogranichennoye vosstanovleniye](../Zhurnal/2026-09-11_13-39-59_MSK_prinyatj-napravleniye-finansirovaniya-FUM/otchyot.md), kommit 73c52866e565061b48ee67e164d5d178c5c8d8cd. Podgotovka zavershilasj kodom 2 za 29,356183417 s posle vyideleniya 0212/0069 i pervoj fajlovoj stadii. [Tochnyiye iskhodnyiye bajtyi](../Instrumentyi/fum-reyestr-planirovaniya/tests/fiksturyi/propusjhennyij-status-finansirovaniya.json) sokhranenyi. Sobyitiye vosstanovleno kanonicheskoj korrekciyej bez novyikh nomerov.

## Ozhidaniye i klassifikaciya

Eto nedorabotka podgotovlennogo smyislovogo vkhoda: kartochka dolzhna odnovremenno udovletvoryatj obyazateljnomu formatu imeni i tela. Sborsjhik praviljno otkazal; pravo otklyuchitj proverku iz oshibki vkhoda ne sleduyet.

## Mekhanizm i sistemnoye ustraneniye

Iskhodnoye telo byilo sostavleno bez obyazateljnoj deklaracii. Strogaya vstavka prezhnego 🟡 vyipolnena cherez sokhranyayemyij priyom; iskhodnaya versiya ostavlena otkryitoj fiksturoj. Sleduyusjhiye podgotovlennyiye vkhodyi Gosuslug, video i grafa uzhe soderzhat obyazateljnuyu kanonicheskuyu stroku; pered priyomom proveryayetsya ikh tochnyij rezuljtat. Mera vosstanovleniya i yeyo otricateljnaya granica trebuyut samostoyateljnoj priyomki novogo etapa.

## Svyazannyiye shagi

[STEP 0213](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0213-proveritj-ogranichennoye-vosstanovleniye-statusa-priyoma.md) proveryayet ogranichennoye vosstanovleniye po proyavleniyu `FUM-СБОЙ-0075/ПРОЯВЛЕНИЕ-0001`; iskhodnyij finansovyij predmetnyij rezuljtat ostayotsya v STEP 0212.

## Kriterii zakryitiya

Prezhneye finansovoye sobyitiye vosstanovleno sokhranyayemoj strogoj popravkoj i prinyato nastoyasjhim reyestrom s prezhnimi ID. Otkryityij regressionnyij vkhod podtverzhdayet obyazateljnostj statusa, tochnoye vosstanovleniye drugim processom i otkazyi podmenyi. Profilj i samostoyateljnaya itogovaya priyomka izmenyonnogo sposoba sokhranenyi; novyiye podgotovlennyiye kartochki soderzhat obyazateljnuyu deklaraciyu do svoyej fajlovoj stadii. Odnogo uspeshnogo povtornogo vyizova nedostatochno.

## Istochniki

- [Tekusjhij etap](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/zapros.md).
- [Tochnoye sravneniye vkhoda i korrekcij](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/svideteljstva/sravneniye-statusa.json).
- [Pravila kartochek i diagnostiki](../Pravila/agentov/planirovaniye-trebovaniya-voprosyi-i-sboi.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:10:58 MSK -->
<!-- content-sha256: sha256:f35b0d5a8a1b5765de7303750e3a835ed611434c01877fa5928df1aaf25f1bc1 -->
<!-- FUM-MD-RECENCY:END -->
