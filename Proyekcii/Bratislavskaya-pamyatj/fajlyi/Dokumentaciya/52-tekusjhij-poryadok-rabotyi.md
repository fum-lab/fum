# Kak sejchas rabotatj s FUM

Segodnya vkhod v FUM — eto dialog s zadachej Codex, otkryitoj v lokaljnom proyekte. Vyi opisyivayete ozhidayemyij rezuljtat, a zadacha ispoljzuyet fajlyi pamyati, gotovit izmeneniya i sokhranyayet svideteljstva ikh proverki. [Kratkij marshrut v README](../README.md#kak-ispoljzovatj-fum-sejchas) podkhodit dlya pervogo zaprosa; zdesj podrobneye obyyasnyayetsya, chego ozhidatj vo vremya rabotyi.

## Ot zaprosa k rezuljtatu

Nachnite s togo, chto khotite poluchitj: obyyasneniye, plan, ispravleniye, issledovaniye ili sokhranyonnoye resheniye. Dobavjte iskhodnyiye materialyi i vazhnyiye ogranicheniya. Formulirovka «sostavj plan» zadayot rezuljtat planirovaniya; ona sama po sebe ne oznachayet prosjbu realizovatj vse perechislennyiye v plane izmeneniya. Kogda nuzhna realizaciya, skazhite ob etom pryamo.

Mozhno utochnyatj zadachu po khodu rabotyi. Novoye soobsjheniye dopolnyayet tekusjhij zapros, yesli vyi ne otmenili yego ili ne zamenili drugim. Soderzhateljnyiye otvetyi pokazyivayut, chto ustanovleno, kakoye resheniye prinyato i chto yesjhyo predstoit. Utochneniye trebuyetsya tam, gde otsutstvuyusjhiye dannyiye dejstviteljno menyayut resheniye.

Dlya kratkoj rabotyi dostatochno odnogo ogranichennogo zaprosa. Dlya postoyannoj zadachi oboznachjte soglasovannyij obyyom i poprosite prodolzhatj nezavershyonnyiye etapyi. Eto pomogayet otlichitj zaversheniye otdeljnogo etapa ot zaversheniya vsej rabotyi.

## Kak ustroyena paralleljnaya rabota

Nezavisimuyu chastj mozhno poruchitj dochernemu ispolnitelyu, kogda eto uskoryayet rabotu ili pozvolyayet otdeljno proveritj resheniye. Naprimer, odin ispolnitelj izuchayet prichinu zamedleniya, vtoroj razbirayet susjhestvuyusjhiye proverki, a osnovnaya zadacha soglasuyet vyivodyi i izmeneniya. Razdeleniye polezno, yesli ispolniteli imeyut ponyatnyiye granicyi i mogut rabotatj bez postoyannogo ozhidaniya drug druga.

Pishusjhiye ispolniteli ispoljzuyut otdeljnyiye Git worktree — rabochiye kopii s sobstvennyimi fajlami i vetkami. V chuzhom aktivnom dereve vyipolnyayetsya toljko chteniye. Eto pozvolyayet gotovitj izmeneniya paralleljno, odnako pered obyyedineniyem vsyo ravno nuzhno soglasovatj obsjhiye dokumentyi i proveritj obsjhij rezuljtat. Raskhod mesta i dliteljnostj sborok takzhe ogranichivayut poleznuyu paralleljnostj.

Rolj opisyivayet vklad ispolnitelya: naprimer, proyektirovaniye, realizaciyu ili proverku. Ona pomogayet raspredelitj rabotu i ponyatj proiskhozhdeniye rezuljtata; sama po sebe rolj ne dayot dopolniteljnyikh razreshenij.

U vnutrennej dochernej rabotyi i otdeljnoj zadachi Codex raznoye naznacheniye. Dochernyaya rabota obsluzhivayet tekusjhij zapros i peredayot rezuljtat osnovnoj zadache. Otdeljnaya zadacha imeyet sobstvennyij dialog, kotoryim vyi mozhete upravlyatj samostoyateljno; yeyo sozdayut po yavnoj prosjbe. Soobsjheniye o podgotovke takoj zadachi yesjhyo ne podtverzhdayet, chto ispolnitelj uzhe zapusjhen.

## Chto sokhranyayetsya v pamyati

Iskhodnyiye upravlyayusjhiye soobsjheniya i soderzhateljnyiye otvetyi chitayutsya iz fakticheskogo JSONL dialoga. Etot istochnik pozvolyayet vosstanovitj formulirovki posle sokrasjheniya rabochego konteksta. Kanonicheskij [Zhurnal](../Zhurnal/README.md) svyazyivayet komandyi s planom, izmenyonnyimi materialami, resheniyami i proverkami.

V papke etapa nakhodyatsya `запрос.md`, `отчёт.md` i neobkhodimyiye materialyi. Doslovnaya formulirovka zaprosa sokhranyayet proiskhozhdeniye resheniya; proizvodnaya dokumentaciya vedyotsya po-russki kirillicej. Pri chtenii rezuljtata polezno razlichatj iskhodnoye pozhelaniye, prinyatoye resheniye, nablyudeniye i predpolozheniye.

Polnyij sluzhebnyij JSONL sredyi i opublikovannyij Zhurnal — raznyiye sloi khraneniya. V otkryityij repozitorij vkhodyat otnosyasjhiyesya k rabote materialyi s soblyudeniyem publikacionnoj chistotyi; lokaljnyiye sekretyi i sluzhebnyij musor tuda ne perenosyatsya.

Fakticheskiye zapuski proverok imeyut otdeljnyiye syiryiye zapisi. Postoyannaya sessiya ispoljzuyet priyomochnyiye raundyi formata v4, kotoryiye sokhranyayut istoriyu proverennogo soderzhimogo i ne pozvolyayut predstavitj povtor toj zhe polnoj popyitki kak novyij nezavisimyij rezuljtat. Obyichnyiye zapuski vne etogo rezhima po umolchaniyu sokhranyayut prezhnij format v3; daljnejshaya istoriya posle perekhoda na v4 prodolzhayetsya v v4. Chelovekochitayemyij otchyot obyyasnyayet zapisi, sokhranyaya otkazyi i ogranicheniya, a ne zamenyaya ikh itogovoj ocenkoj.

## Kak ponimatj kommit i prodolzheniye

Kontroljnyij kommit — eto sokhranyonnyij etap. Yego otchyot mozhet chestno ostavatjsya otkryityim: chastj rabotyi uzhe proverena i zafiksirovana, sleduyusjhaya yesjhyo predstoit. Priyomka zavershyonnogo etapa otnositsya k opredelyonnomu sostoyaniyu fajlov; pozdnejshiye utochneniya i izmeneniya obrazuyut sleduyusjhij etap.

V postoyannoj zadache kommit ne oznachayet prosjbu ostanovitjsya. Posle nego vyipolnyayetsya sleduyusjhij uzhe soglasovannyij poleznyij shag. Yesli vsyo soglasovannoye vyipolneno, nuzhno otsutstvuyusjheye resheniye poljzovatelya ili voznikla nastoyasjhaya blokirovka sredyi, zadacha soobsjhayet sootvetstvuyusjhij status.

Dlya podderzhki etogo poryadka imeyetsya proverka obyyavlennogo spiska rabot posle kommita. Ona obnaruzhivayet ostavshiyesya obyazateljnyiye dejstviya, no ne perekhvatyivayet lyuboj sposob zavershitj otvet v Codex i ne upravlyayet dostupnostjyu vneshnej sredyi. Poetomu sokhranyonnyij plan i Zhurnal vazhnyi i pri vosstanovlenii posle obryiva.

Proveryaya rezuljtat, smotrite na nazvannyiye rabochuyu vetku i kommit. Oni identificiruyut sokhranyonnyij etap; osnovnaya vetka menyayetsya toljko posle sootvetstvuyusjhego obyyedineniya. Posle kommita svoyej rabochej vetki agent sam otpravlyayet yeyo v proverennyij `origin` i podtverzhdayet udalyonnyij kommit. Tochnaya vetka `master` iz avtomaticheskoj otpravki isklyuchena. Obyyedineniye s osnovnoj vetkoj, yeyo publikaciya i sozdaniye PR trebuyut otdeljnogo zaprosa; neuspeshnaya otpravka yavno otmechayetsya.

Rezuljtat otdeljnogo rabochego dereva snachala nakhoditsya v yego kataloge. Poprosite: «Pokazhi rabochuyu kopiyu etoj zadachi i otkroj yeyo Zhurnal». V pervonachaljnoj kopii i otkryitom iz neyo Obsidian izmeneniya mogut yesjhyo otsutstvovatj. Dlya perenosa prinyatogo rezuljtata v osnovnuyu kopiyu poprosite obyyedinitj izmeneniya; zapisj nachnyotsya posle proverki, chto eta kopiya svobodna ot drugogo pisatelya.

## Kak ocenivatj proverki i proizvoditeljnostj

Dlya izmenenij ispolnyayemogo koda primenyayetsya cikl TDD: snachala vosproizvoditsya trebuyemoye povedeniye ili otkaz, zatem vnositsya ispravleniye i proveryayetsya rezuljtat. Obyazateljnyij etap vklyuchayet profilirovaniye i resheniye ob optimizacii. Yesli izmeneniye uzhe dostatochno effektivno, resheniye ostavitj yego opirayetsya na izmereniye i obyyasneniye; uluchsheniye skorosti ne predpolagayetsya bez svideteljstva.

V otchyote mozhno poprositj pokazatj, kakoj scenarij proveren, na kakikh dannyikh provedeno izmereniye i kakiye ogranicheniya ostalisj. Prokhozhdeniye konechnogo nabora proverok podtverzhdayet eti scenarii, a ne lyubuyu vozmozhnuyu rabotu sistemyi. Dlya izmeneniya obyichnogo teksta podbirayutsya proverki dokumentacii; ispyitaniya ispolnyayemogo koda radi formaljnosti ne dobavlyayutsya.

Latinskaya oblastj `Proyekcii/` avtomaticheski vyivoditsya iz kanonicheskoj pamyati. Pri yeyo podgotovke ispoljzuyetsya uskorennyij preobrazovatelj, a nezavisimaya proverka rezuljtata sokhranena. [Izmereniye uskoreniya na polnom vkhode](../Zhurnal/2026-09-08_17-18-45_MSK_uskoritj-peresborku-proyekcii/materialyi/profili/sravneniye-polnogo-vkhoda.json) otnositsya k zafiksirovannomu scenariyu; dliteljnostj vashej peresborki zavisit ot vkhodnyikh dannyikh i sredyi.

## Kak prodolzhitj ili ostanovitj

Utochneniye, zapros statusa i prodolzheniye mozhno pisatj v tom zhe dialoge. Naprimer: «Prodolzhi soglasovannyij plan s pervogo nezavershyonnogo etapa» ili «Pokazhi poslednyuyu proverennuyu kontroljnuyu tochku i ostavshuyusya rabotu». Pri vosstanovlenii posle obryiva zadacha sveryayet sokhranyonnyij plan, Zhurnal i fakticheskoye sostoyaniye svoyej vetki.

Prosjba «Ostanovi daljnejshuyu rabotu i sokhrani tekusjhij status» otnositsya k sleduyusjhim dejstviyam. Ona ne otmenyayet uzhe vyipolnennyiye izmeneniya. Dlya otmenyi rezuljtata nazovite, kakoye sostoyaniye nuzhno vosstanovitj; eto otdeljnaya zadacha, osobenno yesli izmeneniya uzhe obyyedinenyi ili opublikovanyi.

## Chto poka ostayotsya proyektom

Samostoyateljnoye prilozheniye FUM s sobstvennyim GUI i avtonomnyim ispolneniyem yesjhyo razrabatyivayetsya. Tekusjhij process ispoljzuyet Codex i dostupnyiye yemu instrumentyi.

[Kontrakt snimkov Git-indeksa](../Zhurnal/2026-09-08_19-07-59_MSK_utochnitj-kontrakt-snimkov-indeksa/materialyi/planyi/kontrakt-snimkov-indeksa.md) opisyivayet budusjhij konvejyer: prinimatj zafiksirovannyij snimok i otdeljno sokhranyatj pozdniye komandyi. Dokument opredelyayet granicyi i budusjhiye proverki; sootvetstvuyusjhij ispolnitelj poka ne realizovan. Na dliteljnoj priyomke tekusjhego processa novyiye dannyiye mogut vremenno sokhranyatjsya v izolirovannom chernovike i perenositjsya v sleduyusjhij zhurnaljnyij etap.

Staryiye FIFO, CAS i avtomaticheskiye peredachi zadach opisanyi v [istorii konvejyera](45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md). Nalichiye etikh narabotok ne oznachayet, chto oni upravlyayut tekusjhej rabotoj.

## Podgotovitj lokaljnuyu kopiyu

Yesli proyekt uzhe otkryit v Codex, etot razdel mozhno propustitj.

Dlya chteniya pamyati dostatochno redaktora ili Obsidian. Dlya izmeneniya i proverki proyekta poprosite Codex snachala proveritj gotovnostj sredyi: Git, Python s podderzhkoj `tomllib` (Python 3.11 ili noveye) i podkhodyasjhij Swift toolchain. Tekusjhij rabochij kontur proveryayetsya na macOS. Klonirovaniye samo po sebe ne ustanavlivayet eti instrumentyi; rezuljtat predvariteljnoj proverki dolzhen nazvatj nedostayusjhiye komponentyi do zapuska dliteljnoj sborki.

Dlya svoyej rabotyi sozdajte fork publichnogo repozitoriya FUM. Zamenite `USERNAME` imenem svoyej uchyotnoj zapisi GitHub i klonirujte kopiyu:

```bash
git clone https://github.com/USERNAME/fum.git FUM
cd FUM
git remote add upstream https://github.com/fum-lab/fum.git
```

Posle svezhego klonirovaniya inicializirujte zakreplyonnuyu zavisimostj LinguisticKit shtatnyim instrumentom proyekta:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init \
  --repo-root . \
  --path Зависимости/LinguisticKit
```

Otkrojte katalog `FUM` kak lokaljnyij proyekt v Codex Desktop. Dlya chteniya i navigacii mozhno otkryitj tot zhe katalog kak khranilisjhe Obsidian. Yego lokaljnyiye nastrojki grafa ostayutsya poljzovateljskimi dannyimi.

Yesli material podgotovlen vo vneshnem dialoge, vospoljzujtesj [poryadkom priyoma vneshnego vklada](51-proveryayemyij-priyom-vneshnego-vklada.md). On opisyivayet peredachu predlozheniya v lokaljnuyu rabotu i yego proverku pered prinyatiyem.

## Istochniki

- [Opisatj aktualjnyij sposob rabotyi s uporom na ponyatnostj cheloveku](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/zapros.md).
- [Postoyannaya zadacha, sokhraneniye dialoga, profilirovaniye i kontroljnyiye kommityi](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [Ustraneniye ostanovki postoyannoj zadachi](../Zhurnal/2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/otchyot.md).
- [Uskoreniye peresborki proyekcii](../Zhurnal/2026-09-08_17-18-45_MSK_uskoritj-peresborku-proyekcii/otchyot.md).
- [Proyekt kontrakta snimkov indeksa](../Zhurnal/2026-09-08_19-07-59_MSK_utochnitj-kontrakt-snimkov-indeksa/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 22:46:18 MSK -->
<!-- content-sha256: sha256:438dc14f8a5aa3856ac66641130ed5f3b21ee5b4e2b980fa45c2a2ff47be8954 -->
<!-- FUM-MD-RECENCY:END -->
