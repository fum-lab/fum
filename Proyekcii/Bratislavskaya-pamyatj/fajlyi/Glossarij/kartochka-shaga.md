# Kartochka shaga

Kartochka shaga ostayotsya planovoj pamyatjyu, no yeyo avtomaticheskij vyibor selector, zapusk cherez FIFO/dispatcher i ispolneniye worktree-pulom yavlyayutsya otlozhennyim konturom. V tekusjhej ruchnoj skheme kartochka sama po sebe ne dayot prava zapisi i ne zapuskayet zadachu; poljzovatelj otdeljno formuliruyet i zapuskayet soderzhateljnyij zapros.

Kartochka shaga — atomarnaya planovaya zapisj [pamyati FUM](pamyatj-FUM.md), kotoraya sokhranyayet odin vozmozhnyij ili uzhe zavershyonnyij prakticheskij shag nezavisimo ot yego mesta v obsjhem spiske i vyibora konkretnoj vetkoj. Kartochka imeyet neizmenyayemyij identifikator `FUM-STEP-NNNN`, opisateljnoye imya fajla, status, zadachu, istochniki i libo prichinu aktualjnosti s kriteriyami zaversheniya, libo istoricheskij rezuljtat.

Atomarnostj otnositsya i k rabochemu byudzhetu. Kartochka, attestovannaya vetkoj kak `dispatch=automatic`, zadayot odin samostoyateljno proveryayemyij rezuljtat, konechnyij nabor obyazateljnyikh vkhodov, yavnyiye granicyi izmenenij i isklyuchenij, konechnyiye proverki i formu peredachi. Polnaya sessiya — ot obyazateljnogo chteniya do proverok i atomarnoj peredachi — dolzhna s vyisokoj veroyatnostjyu pomesjhatjsya v odno svezheye kontekstnoye okno. Neizvestnyij tokenovyij byudzhet ne vyidumyivayetsya: shirokoye issledovaniye, vyibor resheniya i realizaciya razdelyayutsya, a dolgaya istoriya peredayotsya po adresnyim ssyilkam na pamyatj, a ne kopiruyetsya v novyij prompt.

Imya imeyet vid `<эмодзи>-FUM-STEP-NNNN-<краткое-название>.md`. V nyom `🟡` oznachayet `active`, `✅` — `completed`, `🧩` — `absorbed`, a `🗑️` — `withdrawn`. Identifikator v imeni tochno sovpadayet s `card_id`, a nepustoye kratkoye nazvaniye opisyivayet shag sochetaniyem bukv i cifr, razdelyonnyikh odinochnyimi defisami. Nazvaniye pomogayet cheloveku oriyentirovatjsya, no ne zadayot identichnostj kartochki. Yego utochneniye i smena statusnogo emodzi vyipolnyayutsya lokaljnoj komandoj planovogo reyestra: ona sokhranyayet perenos kak `git mv` i perevodit zhivyiye tekstovyiye ssyilki na novyij putj, ne perepisyivaya pervichnyiye istochniki. Polnoye imya dolzhno pomesjhatjsya v perenosimyij predel 255 bajt UTF-8, poetomu kratkoye nazvaniye ne obyazano doslovno povtoryatj zagolovok. Katalog kartochek ploskij; tochnyij kornevoj `README.md` yavlyayetsya yedinstvennyim Markdown-fajlom v nyom, kotoryij ne prokhodit kartochnyij kontrakt.

Statusyi `active`, `completed`, `absorbed` i `withdrawn` opisyivayut zhiznennyij cikl samoj kartochki. Oni ne ravnyi rezhimam kandidatnoj zapisi [sleduyusjhego shaga vetki](sleduyusjhij-shag-vetki.md) `automatic`, `paused` i `blocked` i vyichislennomu runtime-statusu `ready` ili `paused`. Odna aktualjnaya kartochka mozhet ostavatjsya vne whitelist, byitj avtomaticheski rassmatrivayemoj pri vyipolnenii zavisimostej libo nakhoditjsya na yavnoj pauze ili blokirovke. Sostoyaniye vetochnogo nabora `done` voobsjhe ne yavlyayetsya statusom kartochki i oznachayet otsutstviye kandidatov. Pri smene zhiznennogo statusa emodzi v imeni menyayetsya tem zhe avtomatizirovannyim `git mv`; vyichislennyij status zapuska na emodzi celevoj kartochki ne vliyayet. Yesli kartochka vyibrana vetkoj, yeyo novyij putj trebuyet novogo `step_id`, poetomu staroye pokoleniye neljzya obnovlyatj prostoj zamenoj.

Status `active` sam po sebe ne razreshayet prodolzheniye vetki. Dlya etogo vetochnaya zapisj dolzhna posle otdeljnogo preflight vklyuchitj kartochku kak individualjno dopustimogo kandidata `automatic`, zakrepitj khyesh yeyo soderzhaniya, otdeljnyij `step_id` i tochnyij massiv `requires_completed_card_ids`. Vetochnyij selektor vyichislyayet `ready` toljko pri literal-`completed` u vsekh obyazateljnyikh kartochek; `active`, `absorbed` i `withdrawn` usloviye ne vyipolnyayut. Zapisi `paused` i `blocked` sokhranyayut aktualjnuyu kartochku i yavnoye usloviye vozobnovleniya, no avtomaticheski ne otkryivayutsya i ne meshayut nezavisimomu runtime-`ready`. Zadacha i kriterii ne kopiruyutsya v vetochnuyu zapisj.

Posle FIFO-dopuska [zadacha-prodolzheniye](obyazateljnoye-prodolzheniye-vetki.md) neposredstvenno vyizyivayet vetochnyij selektor. On snachala vyichislyayet gotovnostj po tochnyim kartochechnyim zavisimostyam i toljko zatem sopostavlyayet normalizovannyiye lokaljnyiye ssyilki iz razdela `Источники` gotovyikh kartochek s ogranichennoj first-parent-istoriyej tochnogo `HEAD`. Takaya svyazannostj pomogayet derzhatj soderzhateljno blizkiye kommityi ryadom, no ostayotsya myagkim pravilom poryadka i ne prevrasjhayet zhiznennyij status kartochki v razresheniye, ne obkhodit zavisimosti, bezopasnostj, polnomochiya, vyibor poljzovatelya ili kontekstnuyu posiljnostj. Svobodnyij tekst kartochki i `resume_condition` ne yavlyayutsya mashinnyim predikatom.

Kartochki i ikh polnyij indeks khranyatsya v [Planirovaniye/kartochki-shagov](../Planirovaniye/kartochki-shagov/README.md). [Predlozheniye o sleduyusjhem shage](predlozheniye-o-sleduyusjhem-shage.md) poluchayet kanonicheskoye predstavleniye kak aktualjnaya kartochka, no ne stanovitsya trebovaniyem i ne obesjhayet realizaciyu.

## Svyazannyiye dokumentyi

- [Predlozheniya o sleduyusjhikh shagakh FUM](../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Sleduyusjhiye shagi vetok](../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)
- [Planirovaniye FUM](../Planirovaniye/README.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-29 09:04:03 MSK — Rasshiritj dinamicheskij vyibor sleduyusjhego shaga](../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [iskhodnyij zapros 2026-07-27 18:28:42 MSK — Vyibiratj sleduyusjhij shag pri zapuske s uchyotom istorii kommitov](../Zhurnal/2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-23 10:44:00 MSK - Avtomatizirovatj obnovleniye ssyilok pri smene statusa kartochki](../Zhurnal/2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK - Dekompozirovatj predlozheniya na kartochki shagov](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK - Zafiksirovatj poshagovyij otbor realizacii](../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK - Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-22 03:38:35 MSK - Razreshitj vyipolneniye dostupnyikh kartochek shagov](../Zhurnal/2026-07-22_03-38-35_MSK_razreshitj-vyipolneniye-dostupnyikh-kartochek-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-22 11:48:49 MSK — Oformitj kartochki shagov opisateljnyimi imenami i emodzi statusami](../Zhurnal/2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:90c5828af956acd332d3a1b9892f70eba70ae5d60400a7a289a79448f1482133 -->
<!-- FUM-MD-RECENCY:END -->
