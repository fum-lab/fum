# [FUM](Glossarij/FUM.md)

FUM — [fraktaljnyij uzel myishleniya](Glossarij/fraktaljnyij-uzel-myishleniya.md). Proyekt pomogayet vesti svyaznuyu pamyatj: sokhranyatj voprosyi, resheniya, iskhodnyiye materialyi i rezuljtatyi rabotyi tak, chtobyi k nim mozhno byilo vernutjsya i prodolzhitj razvitiye.

Sejchas rabotatj s FUM mozhno cherez Codex Desktop i lokaljnuyu kopiyu etogo repozitoriya. Vyi formuliruyete zadachu obyichnyimi slovami, Codex pomogayet razobratjsya, podgotovitj izmeneniya i sokhranitj proverennyij rezuljtat. Fajlyi mozhno chitatj v lyubom redaktore; Obsidian udoben dlya perekhoda po svyazyam. Sobstvennoye otdeljnoye prilozheniye FUM yesjhyo razrabatyivayetsya.

## Kak ispoljzovatj FUM sejchas

### 1. Otkrojte proyekt

Otkrojte korenj svoyej lokaljnoj kopii FUM kak proyekt v Codex Desktop. Yesli kopii yesjhyo net, nachnite s [podgotovki proyekta](Dokumentaciya/52-tekusjhij-poryadok-rabotyi.md#podgotovitj-lokaljnuyu-kopiyu). Znatj vnutrenneye ustrojstvo pamyati FUM dlya pervogo zaprosa ne trebuyetsya.

### 2. Skazhite, kakoj rezuljtat vam nuzhen

Napishite, chto khotite ponyatj, izmenitj ili sokhranitj. Naprimer:

> Obyyasni tekusjhuyu arkhitekturu FUM prostyimi slovami. Poka nichego ne menyaj.

> Sostavj plan uskoreniya peresborki proyekcii i sokhrani yego v pamyati proyekta.

> Ispravj etu oshibku: [chto proizoshlo i chto ozhidalosj]. Proverj ispravleniye i sokhrani rezuljtat lokaljno.

Mozhno pisatj po-russki, v tom chisle translitom. Prilozhite vazhnyiye materialyi i ogranicheniya: naprimer, «toljko izuchitj», «snachala podgotovitj plan» ili «prodolzhaj realizaciyu soglasovannogo plana». Yesli praviljnoye resheniye zavisit ot nedostayusjhikh dannyikh, zadacha zaprosit utochneniye.

Dlya dliteljnoj rabotyi oboznachjte eto pryamo:

> Vedi etu zadachu postoyanno: vyipolnyaj soglasovannyiye etapyi, sokhranyaj kontroljnyiye tochki i prodolzhaj nezavershyonnuyu rabotu.

### 3. Sledite za soderzhateljnyimi obnovleniyami

V otvetakh zadachi budut poyavlyatjsya najdennyiye prichinyi, prinyatyiye resheniya, rezuljtatyi proverok i ostavshayasya rabota. Kogda nezavisimyiye chasti polezno vyipolnyatj paralleljno, oni mogut byitj poruchenyi dochernim ispolnitelyam. Pishusjhiye ispolniteli rabotayut v otdeljnyikh rabochikh kopiyakh i vetkakh; rezuljtat vozvrasjhayetsya v osnovnuyu zadachu dlya soglasovaniya.

Vnutrenniye docherniye rabotyi pomogayut vyipolnitj vash zapros. Yesli khotite otdeljnuyu zadachu Codex so svoim dialogom, poprosite sozdatj yeyo yavno.

### 4. Posmotrite, chto poluchilosj i gde eto sokhraneno

Otvet zadachi soderzhit ssyilki na izmenyonnyiye dokumentyi ili kod, svedeniya o proverkakh i izvestnyiye ogranicheniya. Dlya podrobnostej otkrojte yeyo papku v [Zhurnale](Zhurnal/README.md): `запрос.md` sokhranyayet iskhodnyiye komandyi, a `отчёт.md` obyyasnyayet rezuljtat i yego proverku.

Yesli zadacha rabotayet v otdeljnoj kopii, pervonachaljno otkryityij katalog mozhet yesjhyo soderzhatj prezhniye fajlyi. Poprosite: «Pokazhi rabochuyu kopiyu etoj zadachi i otkroj yeyo rezuljtat i Zhurnal». Dlya chteniya v Obsidian otkrojte imenno etu kopiyu. Kogda rezuljtat prinyat, mozhno poprositj obyyedinitj yego s osnovnoj kopiyej; zadacha proverit, chto drugoj ispolnitelj sejchas ne pishet v neyo.

Lokaljnyij Git-kommit sokhranyayet opredelyonnoye sostoyaniye fajlov. Sveryajte nazvannyiye v otvete vetku i kommit: rabota v otdeljnoj vetke sama po sebe ne menyayet `master`. Kontroljnaya tochka sokhranyayet promezhutochnyij rezuljtat. V postoyannoj zadache posle neyo prodolzhayetsya uzhe soglasovannaya nezavershyonnaya rabota.

### 5. Utochnyajte, prodolzhajte ili ostanavlivajte rabotu v tom zhe dialoge

Obyichnogo soobsjheniya dostatochno:

> Utochni vtoroj punkt plana: vazhno sokhranitj sovmestimostj so staryimi dannyimi.

> Prodolzhi soglasovannyij plan s pervogo nezavershyonnogo etapa.

> Pokazhi, chto uzhe provereno, a chto poka ostayotsya predpolozheniyem.

> Ostanovi daljnejshuyu rabotu i sokhrani tekusjhij status.

Yesli rabota prervalasj, poprosite vosstanovitj sostoyaniye po Zhurnalu i prodolzhitj soglasovannyij etap. Sokhranyonnyiye materialyi pomogayut vosstanovleniyu; dostupnostj sredyi i ispolnitelya vsyo ravno vliyayet na vozmozhnostj prodolzhatj.

Ostanovka daljnejshej rabotyi ne otmenyayet uzhe sokhranyonnyiye izmeneniya. Yesli nuzhen otkat, ukazhite zhelayemyij rezuljtat otdeljno.

### 6. Razlichajte dostavku vetki i prinyatiye rezuljtata

Posle kommita svoyej rabochej vetki agent avtomaticheski otpravlyayet yeyo v repozitorij `origin`; vetka `master` isklyuchena. Vetka mozhet soderzhatj proverennuyu kontroljnuyu tochku s yesjhyo nezavershyonnoj rabotoj. Poprosite pokazatj ssyilku na dostavlennyij kommit i ostavshiyesya etapyi.

Obyyedineniye s osnovnoj vetkoj, yeyo publikaciya i sozdaniye PR vyipolnyayutsya po otdeljnomu zaprosu. Yesli otpravka ne udalasj, zadacha soobsjhayet ob etom: lokaljno sokhranyonnyij rezuljtat ostayotsya dostupen, no yesjhyo ne dostavlen.

## Gde chitatj daljshe

- [Kak sejchas rabotatj s FUM](Dokumentaciya/52-tekusjhij-poryadok-rabotyi.md) — podgotovka kopii, ustrojstvo sovmestnoj rabotyi, sokhraneniye pamyati i tekusjhiye granicyi.
- [Polnyij indeks dokumentacii](Dokumentaciya/README.md) — karta tem proyekta.
- [Obzor FUM](Dokumentaciya/00-obzor-proyekta.md) i [istoriya vedeniya svyaznoj pamyati](Dokumentaciya/31-poljzovateljskiye-istorii-FUM/vesti-svyaznuyu-pamyatj-FUM.md) — naznacheniye proyekta na primere.
- [Proveryayemyij priyom vneshnego vklada](Dokumentaciya/51-proveryayemyij-priyom-vneshnego-vklada.md) — kak peredatj issledovaniye iz vneshnego dialoga v lokaljnuyu rabotu.
- [Dorozhnaya karta](Planirovaniye/dorozhnaya-karta.md) i [kartochki shagov](Planirovaniye/kartochki-shagov/README.md) — chto zaplanirovano i chto uzhe vyipolneno.
- [Glossarij](Glossarij/glossarij-proyekta.md) — znacheniya terminov.

## Licenziya

Proyekt publikuyetsya pod [CC0 1.0 Universal](LICENZIYA.md). Kanonicheskij publichnyij repozitorij — [fum-lab/fum](https://github.com/fum-lab/fum).

## Istochniki trebovanij

- [Opisatj aktualjnyij sposob rabotyi s uporom na ponyatnostj cheloveku](Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/zapros.md).
- [Postoyannaya rabota, sokhraneniye dialoga, profilirovaniye i kontroljnyiye kommityi](Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [Sdelatj README instrukciyej ispoljzovaniya FUM](Zhurnal/2026-08-06_15-14-50_MSK_sdelatj-README-instrukciyej-ispoljzovaniya-FUM/zapros.md).
- [Razreshitj nachaljnuyu formu FUM bez sobstvennogo GUI cherez Codex](Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 22:46:18 MSK -->
<!-- content-sha256: sha256:698a7174c64daca53949e754e9c97c106196a3f8024060c091fa6884c8822079 -->
<!-- FUM-MD-RECENCY:END -->
