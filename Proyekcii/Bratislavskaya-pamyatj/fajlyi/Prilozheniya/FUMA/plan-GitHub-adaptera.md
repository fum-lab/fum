# GitHub v FUMA

GitHub FUM vedyotsya cherez vosproizvodimuyu avtomatizaciyu: svedeniya o repozitoriyakh, kommitakh, zadachakh, PR, proverkakh Actions i relizakh svyazyivayutsya s pamyatjyu proyekta. [Porucheniya](../../Zhurnal/2026-09-15_22-18-05_MSK_prinyatj-dopusk-postoyannyikh-vetok/zapros.md) zadayut napravleniye; adapter yesjhyo ne realizovan.

Pervyij srez chitayet sostoyaniye yavno vyibrannogo repozitoriya i formiruyet nablyudeniya obsjhego API strukturiruyusjhikh operatorov. Istochnik, vremya, versiya otveta, paginaciya i priznaki ustarevaniya sokhranyayutsya. Sleduyusjhij srez dobavlyayet otdeljnyiye komandyi razreshyonnyikh izmenenij s proveryayemyim iskhodom. Neizvestnyij rezuljtat setevoj operacii ne privodit k slepomu povtoru sozdaniya obyyekta.

Uchyotnyiye dannyiye peredayutsya adapteru cherez privatnoye okruzheniye ispolneniya; Zhurnal soderzhit dopustimyiye identifikatoryi i rezuljtatyi. Konkretnyij sposob avtorizacii, razresheniya, REST/GraphQL i sobyitiya vyibirayutsya pri podgotovke pervogo tekhnicheskogo kontrakta po oficialjnoj dokumentacii. Eta postanovka ne vyidayot otsutstviye otveta za uspekh i ne zayavlyayet nastrojki vneshnej uchyotnoj zapisi.

Kod razmesjhayetsya v obsjhem pakete FUMA po naznacheniyu komponentov. Dlya povtoryayusjhejsya rabotyi gotovyatsya komandyi, fiksturyi, instrukcii, TDD i profilj; ruchnyiye isklyucheniya oboznachayutsya. Upravleniye Git cherez lokaljnyiye proverennyiye komandyi i nablyudeniye cherez GitHub API svyazyivayutsya obsjhimi commit OID, no ne podmenyayut drug druga.

Tekusjhiye prioritetyi — integraciya prinyatogo rezuljtata v master i zapusk Torrent-napravleniya. Podgotovka etogo plana ne aktiviruyet vse prezhniye priostanovlennyiye rabotyi.

## Issues, PR i Actions

Po [yavnomu porucheniyu](../../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/zapros.md) GitHub ispoljzuyetsya dlya publikacii Issues, sozdaniya i recenzirovaniya PR i prinyatiya proverennyikh rezuljtatov. V pamyati FUM dubliruyutsya tochnyiye otpravlennyiye tekstyi i vlozheniya, identifikatoryi, ssyilki, otvetyi servisa i daljnejshiye redakcii. Sekretyi i vremennyiye kodyi avtorizacii ne publikuyutsya.

Pervyij realjnyij rezuljtat — [Issue №1](https://github.com/fum-lab/fum/issues/1) i [chernovoj PR №2](https://github.com/fum-lab/fum/pull/2). PR zakreplyayet osnovu 01ca988635628b48024ae64c290d3c4912aff060 v otdeljnoj vetke dlya revjyu. Na moment sozdaniya workflows i zapuskov Actions yesjhyo net; ikh nalichiye i uspekh ne zayavlyayutsya.

Pervyij workflow dolzhen pereispoljzovatj proveryayusjhij kontur doverennogo master i svyazyivatj tochnyiye iskhodnyiye kommityi s proverennyim rezuljtatom. Tekusjhij marshrut priyomki prinimayet kandidat s roditelyami [L, M] i prodvigayet master do togo zhe kommita. Obyichnyij merge GitHub sozdayot sobstvennyij kommit i sam etu proceduru ne vyipolnyayet. Perenos ispolneniya v CI otdelyayetsya ot izmeneniya kontrakta priyomki.

Ogranichennyij proveryayemyij [scenarij arkhivirovaniya rolevyikh forkov](../../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/udaleniye-forkov/README.md) sokhranyayet Git i nablyudeniya GitHub. On yavlyayetsya otdeljnoj narabotkoj na GitHub CLI, a ne gotovyim Swift-adapterom FUMA. Posle otkaza dostupa k udaleniyu poljzovatelj vzyal udaleniye na sebya; avtomaticheskoye udaleniye ostanovleno.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:34:45 MSK -->
<!-- content-sha256: sha256:6d716a08d08035d31a5f34e0143a83d12136ed15a302df39b804c85712a4b81f -->
<!-- FUM-MD-RECENCY:END -->
