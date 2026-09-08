# Plan konvejyera vnutri odnoj postoyannoj zadachi

Status: napravleniye prinyato soobsjheniyami 34–35; nizhe zafiksirovan plan izmeneniya protokola. Priyomka iz dereva indeksa yesjhyo ne realizovana. Dejstvuyusjhiye run-v4 i report-v3 proveryayut zhivoye sochetaniye HEAD, indeksa i rabochikh fajlov. Ikh neljzya zadnim chislom obyyavlyatj proverkoj opisannogo zdesj rezhima.

## Naznacheniye

Odna kornevaya zadacha v sobstvennom worktree vedyot Zhurnal, gotovit ocherednoj snimok, proveryayet yego i sokhranyayet lokaljnyim kommitom. Poka snimok proveryayetsya, postupayusjhiye komandyi i soderzhateljnyiye otvetyi dopolnyayut rabochiye fajlyi. Nakopivshijsya khvost stanovitsya vkhodom sleduyusjhego raunda v etoj zhe zadache. Kommit zavershayet raund, a prodolzheniye ostayotsya v raneye razreshyonnom obyyome. Novaya zadacha Codex, dispetcher i istoricheskij avtokonvejyer dlya etogo ne trebuyutsya.

## Granica snimka

Indeks Git soderzhit podgotovlennyiye versii fajlov i sam mozhet izmenyatjsya. Poetomu priyomka zakreplyayet identifikator dereva, iskhodnyij HEAD i ref, identifikator raunda, tochnuyu granicu vklyuchyonnyikh upravlyayusjhikh soobsjhenij i polnyij sostav zavisimostej. Sokhranyonnyij obyyekt dereva, a ne posleduyusjheye sostoyaniye indeksa, opredelyayet proveryayemyij vkhod. Obyyektyi i zakreplyonnyiye zavisimosti sokhranyayutsya do vosproizvodimoj proverki i fiksacii rezuljtata. [Dokumentaciya git-write-tree](https://git-scm.com/docs/git-write-tree).

Iz etogo dereva materializuyetsya otdeljnyij katalog proverki. Vse pravila, instrumentyi i generatoryi chitayutsya iz nego s yavnyim kornem. Nuzhno proveritj rezhimyi fajlov, simvolicheskiye ssyilki, atributyi i filjtryi Git, podmoduli, konfiguraciyu i vspomogateljnyiye resursyi: eksport ne dolzhen nezametno podmeshatj bajtyi zhivogo checkout ili vneshnego dereva. Konkretnyij sposob materializacii vyibirayetsya posle adresnyikh testov; nazvaniye komandyi eksporta samo po sebe ne dokazyivayet tochnostj.

## Prokhozhdeniye raunda

1. Sokhranitj komandyi i otvetyi, zakonchitj neobkhodimyiye izmeneniya i proizvodnyiye indeksyi, sformirovatj derevo vkhoda i granicu Zhurnala. Proveritj yedinstvennoye vladeniye svoim derevom i ref.
2. Vyipolnitj adresnyiye proverki i obyazateljnyij dlya izmenenij koda cikl TDD, profilirovaniya i resheniya ob optimizacii. Materializovatj tochnyij prinimayemyij snimok i zapustitj vyibrannyij finaljnyij profilj na nyom.
3. Sokhranyatj novyiye soobsjheniya v zhivom Zhurnale. Novaya otmena, ogranicheniye ili izmeneniye polnomochij dejstvuyet srazu; granica snimka ne razreshayet ignorirovatj upravleniye poljzovatelya. Obyichnoye utochneniye dlya sleduyusjhego raunda ne menyayet uzhe izmeryayemyiye bajtyi.
4. Posle uspeshnoj proverki zakryitj otdeljnyij snimok otchyota raunda v kataloge proverki, zatem sformirovatj i nezavisimo proveritj finaljnuyu proyekciyu tam zhe.
5. Poluchitj derevo budusjhego kommita. Ono otlichayetsya ot dereva vkhoda toljko tochnyim perechnem rezuljtatov proverki i zakryitiya. Otchyot, mashinnyiye zapisi, proyekciya i dopustimyiye proizvodnyiye izmeneniya dolzhnyi imetj proveryayemuyu svyazj s iskhodnyim derevom; recency i indeksyi ne poluchayut neogranichennogo isklyucheniya.
6. Ustanovitj proverennyiye rezuljtatyi v indeks iz izvestnyikh blob-obyyektov, sveritj ozhidayemyiye HEAD/ref i polnoye derevo indeksa. Soobsjheniye kommita soderzhit pervichnyij zapros i tochnuyu vklyuchyonnuyu granicu komand; svyaznostj chitayet zapros iz itogovogo dereva.
7. Sozdatj obyichnyij lokaljnyij kommit i proveritj, chto yego derevo ravno prinyatomu. Sokhranitj pozdnij khvost rabochikh fajlov i prodolzhitj sleduyusjhij neobkhodimyij etap v toj zhe zadache.

## Pozdniye zapisi v tekh zhe fajlakh

Rabochiye versii zapros.md i otchyot.md mogut uzhe soderzhatj novyiye stroki, kogda indeks khranit ikh prinyatuyu predyidusjhuyu versiyu. Kopirovaniye starogo otchyota poverkh rabochikh fajlov poteryayet pozdniye soobsjheniya. Povtornoye dobavleniye celogo izmenyonnogo fajla v indeks vklyuchit neproverennyiye stroki v kommit. Poetomu ustanovka rezuljtata ispoljzuyet tochnyiye proverennyiye obyyektyi.

Yesli rabocheye predstavleniye otchyota tozhe trebuyetsya obnovitj, primenyayetsya tryokhstoronneye soglasovaniye otnositeljno iskhodnyikh bajtov. Konflikt sokhranyayetsya yavno; pozdnij tekst ne udalyayetsya molcha. Posle kommita nezakommichennyij khvost ostayotsya vidimyim i sveryayetsya s tochnyimi pervichnyimi soobsjheniyami JSONL.

## Versionirovaniye zakryitij

Susjhestvuyusjhij yedinstvennyij snimok.json zakryivayet istoriyu zadachi, a vozobnovleniye report-v3 zapresjheno. Konvejyeru nuzhnyi otdeljnyiye neizmenyayemyiye zakryitiya raundov s iskhodnyim derevom, itogovyim derevom, granicej komand i svyazjyu s predyidusjhim raundom. Eto novyij versionirovannyij kontrakt. Staryiye zapisi i report-v1/v2/v3 ne perepisyivayutsya, ne udalyayutsya i vosproizvodyatsya po prezhnim pravilam. Vosstanovleniye posle preryivaniya ispoljzuyet sokhranyonnyij kontekst konkretnogo zakryitiya.

## Chasti realizacii i proveryayemyiye granicyi

- Snachala razrabotatj chistyij kontrakt dereva i granicyi komand. Zatem RED/GREEN-scenarii materializacii: nezakommichennaya pozdnyaya stroka, izmeneniye indeksa posle snimka, dvizheniye HEAD/ref, rezhimyi fajlov, podmodulj, ssyilki i filjtryi.
- Podklyuchitj otchyotnuyu obyortku, proverku svyaznosti i proyekciyu k yavnomu kornyu snimka. Test dolzhen obnaruzhivatj chteniye izmenivshegosya zhivogo checkout.
- Realizovatj versionirovannyiye neizmenyayemyiye zakryitiya i vosstanovleniye posle avarii mezhdu zapisjyu rezuljtata, staging i kommitom.
- Proveritj sokhraneniye pozdnikh izmenenij odnogo i togo zhe zaprosa i otchyota, tochnostj dereva sozdannogo kommita i neprinyatiye chuzhogo staging. Otmena poljzovatelya dolzhna prekrasjhatj utrativshij polnomochiya raund.
- Obnovitj yedinyij nabor pravil: AGENTS, pravilo 000188, NEW000006, pravilo 000121, inventarj i primenimyiye validatoryi. Realizovannyij dopusk vvoditsya toljko soglasovannyim perekhodom.
- Dlya kazhdogo izmeneniya ispolnyayemogo koda izmeritj podgotovku i khraneniye snimka, materializaciyu, raskhod pamyati i diska, ustanovku rezuljtatov i vosstanovleniye na vosproizvodimyikh vkhodakh. Sravnitj s tekusjhej stoimostjyu; optimizaciya ne umenjshayet proveryayemyij sostav dannyikh.

## Granica tekusjhego rezuljtata

Progon 92 otnosilsya k prezhnemu protokolu i snimku s 31 upravlyayusjhim soobsjheniyem. On zavershilsya otkazom na proverke mashinno-lokaljnyikh putej posle uspeshnogo primeneniya i nezavisimoj proverki proyekcii. Soobsjheniya 32–35 postupili vo vremya progona, sokhranenyi vne checkout i perenosyatsya v Zhurnal posle yego zaversheniya. Novoye opisaniye konvejyera ne menyayet zadnim chislom iskhod ili predmet etogo progona.

## Istochniki

- [Doslovnyiye soobsjheniya 34–35](../../zapros.md).
- [Soderzhateljnyiye otvetyi i iskhodyi proverok](../../otchyot.md).
- [Plan uskoreniya i dejstvuyusjhiye priyomochnyiye raundyi](plan.md).
- [Pravila proverki i zakryitiya](../../../../Pravila/agentov/proverki-kommit-i-publikaciya.md).
- [Pravila Zhurnala](../../../../Pravila/agentov/zhurnal-i-proiskhozhdeniye.md).
- [git-write-tree](https://git-scm.com/docs/git-write-tree), [git-commit](https://git-scm.com/docs/git-commit), [git-checkout-index](https://git-scm.com/docs/git-checkout-index) — vneshniye interfejsyi Git; vyibrannyij sposob eksporta yesjhyo predstoit proveritj.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 13:49:48 MSK -->
<!-- content-sha256: sha256:ba0eeb2a0b8c692712d6639f44c08dcc9450eed275ec243b0adc73a1085f2cdc -->
<!-- FUM-MD-RECENCY:END -->
