# Yazyikovyiye operatoryi v pamyati FUM

Po soobsjheniyam 246–248 [tekusjhego zaprosa](../zapros.md) otkryivayetsya napravleniye analoga LinguisticKit na strukturiruyusjhikh operatorakh. Pervoye ogranichennoye primeneniye — transliteraciya ru iz Cyrl v Latn, kotoraya uzhe nuzhna preobrazovatelyu imyon i bratislavskoj proyekcii. Plan peredan dejstvuyusjhej avtomatizacii priyoma napravlenij; nomer novogo shaga i zapusk ispolnitelya zdesj ne podmenyayutsya predpolozheniyem.

## Fakticheskaya osnova

Tochnyij gitlink LinguisticKit — `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Preobrazovatelj FUM vyizyivayet `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)`. Tablica zavisimosti `Extracted/ScriptTables/ru.json` soderzhit 53 uporyadochennyiye stroki. Algoritm vyipolnyayet NFD, vyibirayet naiboleye dlinnoye sovpadeniye skalyarov s usloviyami sosedstva, vosstanavlivayet registr i zavershayet NFC; neizvestnyij skalyar sokhranyayetsya. Eto ne posledovateljnostj nezavisimyikh zamen.

Opredeleniya i russkiye sootvetstviya sokhranyayutsya dannyimi pamyati. Obsjhij ispolnitelj predostavlyayet normalizaciyu, sopostavleniye posledovateljnostej s yavnyim prioritetom i kontekstom, porozhdeniye rezuljtata i obrabotku registra. Zamena opredeleniya dolzhna menyatj rezuljtat bez izmeneniya koda ispolnitelya. Neprozrachnyij vyizov LinguisticKit vnutri novogo operatora ne schitayetsya realizaciyej analoga.

Ispoljzuyetsya susjhestvuyusjhij AutomationExecutor iz STEP-0208. Yego nyineshnij bajtovyij kontrakt s 32 pravilami i zapretom prefiksnyikh peresechenij sokhranyayetsya; dlya tekstovyikh kontekstnyikh tablic nuzhna otdeljnaya sovmestimaya versiya. V opredelenii i trasse sokhranyayutsya versiya, istochnik tablicyi, OID, khyesh, primenyonnyiye pravila i versiya Unicode. Zavisimostj normalizacii i registra ot runtime ukazyivayetsya yavno.

## Proveryayemyij pervyij srez

- Nezavisimoye ozhidayemoye preobrazovaniye: «imyon» → «imyon». Zatem sokhranyonnyiye etalonnyiye vektoryi, vse stroki i kontekstyi tablicyi, smeshannyij registr, yo i ye s kombiniruyemoj dierezoj, j, hj, hy, neizvestnyiye simvolyi, pustoj i predeljnyij vvod.
- Pobajtovoye differencialjnoye sravneniye s zakreplyonnyim LinguisticKit na otkryitom korpuse. Etalon ispoljzuyetsya v proverke; ispolnitelj vyichislyayet rezuljtat sam.
- Neizmenyayemostj tablic i paralleljnyiye vyizovyi s uchyotom raneye obnaruzhennoj gonki kyesha. Byudzhetyi i granicyi trassyi ostayutsya chastjyu obsjhego kontrakta.
- Profilj Release na odnikh vkhodakh: podgotovka tablic, pervyij i povtornyiye vyizovyi, preobrazovaniye, trassa i khyeshirovaniye, pamyatj i skvoznoye vremya. Uskoreniye zaraneye ne zayavlyayetsya.

Iskhodnaya zavisimostj licenzirovana CC0 1.0. Pri perenose pokryityikh licenziyej iskhodnikov i tablic sokhranyayetsya proveryayemoye proiskhozhdeniye. Polnyij nabor pisjmennostej i API LinguisticKit — daljnejshij obyyom. Obratimostj ne obesjhayetsya: normalizaciya izmenyayet iskhodnyiye bajtyi, a smeshannyiye pisjmennosti mogut davatj kollizii. Zamena rabochego preobrazovatelya proyekcii trebuyet otdeljnoj proverennoj migracii; poka zakreplyonnyij LinguisticKit ostayotsya dejstvuyusjhej zavisimostjyu i etalonom.

## Primer soglasovaniya v interfejse

Soobsjheniye 247 utochneno izobrazheniyem 248: interfejs Codex Desktop pokazal sistemnuyu podpisj «Audit integration readiness obnovilsya(-lisj)» dlya odnogo agenta. Trebuyemaya forma — «obnovilsya», dlya neskoljkikh agentov — «obnovilisj», bez shablonnogo suffiksa v skobkakh. Podpisj otnositsya k interfejsu Desktop; yeyo ispravleniye v samom prilozhenii zdesj ne vyipolneno.

Etot primer sokhranyayetsya dlya sleduyusjhego profilya morfologicheskogo soglasovaniya. Chislo, a pri neobkhodimosti rod i rolj podlezhasjhego, dolzhnyi yavno uchastvovatj vo vkhodnom kontekste. On ne rasshiryayet nezametno pervyij srez transliteracii. Original poljzovateljskogo snimka ot 11 sentyabrya 2026 goda, 21:57:21 khranitsya vne publichnogo checkout; SHA-256: `6e5ade384238e50ee9fba9f5725b5b70e2440b43d2fa8f42bf0b45dbdd8e649e`. Opisaniye izobrazheniya yavlyayetsya nablyudeniyem, a ne dopolniteljnoj komandoj, izvlechyonnoj iz yego teksta.

## Svyazj s otrisovkoj teksta i shriftov

Utochneniye 249 zadayot napravlennuyu cepochku: tekst i shriftyi → strukturiruyusjhiye operatoryi → glifyi i raskladka → komandyi otrisovki → Metal. Preobrazovaniya vyirazhayutsya operatorami; platformennyij adapter ispolnyayet proizvedyonnyiye komandyi. Otdeljnyiye stadii opisyivayut vyibor glifov, ligaturyi, napravleniye pisjma i pozicionirovaniye. Korrektnyij razbor UTF-8 i tablic shrifta sam po sebe yesjhyo ne dokazyivayet korrektnuyu otrisovku.

Postanovka svyazyivayetsya s susjhestvuyusjhim napravleniyem parsinga shriftov REQ0073/STEP0219 i sloyami operatorov vvoda i Metal. Pervyij proveryayemyij rezuljtat — determinirovannyij plan glifov i komand na zakreplyonnyikh vkhodakh; proverka sootvetstvuyusjhego izobrazheniya vyipolnyayetsya otdeljno dlya obyyavlennogo graficheskogo profilya. Tochnoye pobajtovoye sovpadeniye GPU-rezuljtata mezhdu raznyimi ustrojstvami zaraneye ne zayavlyayetsya.

## Istochniki

- [Preobrazovatelj imyon](../../../Instrumentyi/fum-proverka-nazvanij-avtomatizacij/Sources/preobrazovatj-nazvaniya/main.swift).
- [Tablica ru](../../../../../../Зависимости/LinguisticKit/Extracted/ScriptTables/ru.json) i [iskhodnyij algoritm](../../../../../../Зависимости/LinguisticKit/Sources/LinguisticKit/StringProtocol.swift) na ukazannom gitlink.
- [Obsjhij ispolnitelj](../../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Sources/FUMStructuringOperatorMemory/IspolneniyeOperatorov.swift), [procedura proverki i profilya](../../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/Proverki/proveritj-i-izmeritj.py).
- [Licenziya LinguisticKit](../../../../../../Зависимости/LinguisticKit/LICENSE).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 22:03:48 MSK -->
<!-- content-sha256: sha256:a0b5a1ec26930a850b67e381dde27deded392d162dbac58d2caa6de1ef9910ff -->
<!-- FUM-MD-RECENCY:END -->
