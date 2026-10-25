# Tekstovaya sreda FUMA po modeli Canon Cat

Poljzovatelj vyibral [knigu Dzhefa Raskina](../../Zhurnal/2026-09-15_21-35-28_MSK_zakrepitj-modelj-tekstovogo-interfejsa-FUMA/materialyi/istochniki/Knigi/Raskin-Interfejs/README.md) kak istochnik modeli tekstovogo interfejsa. [Komandyi tekusjhego etapa](../../Zhurnal/2026-09-15_21-35-28_MSK_zakrepitj-modelj-tekstovogo-interfejsa-FUMA/zapros.md) utochnyayut Command kak LEAP, sostavnoj kursor, strukturiruyusjhiye operatoryi, Metal/Vulkan i OTF/TTF. Eto plan realizacii; rabotayusjhij interfejs etim dokumentom ne obyyavlyayetsya.

## Soderzhimoye i dejstviye

Tekstovaya sreda dayot dostup k soderzhimomu cherez poisk, peremesjheniye i vyideleniye. Imya fajla i katalog khraneniya ne dolzhnyi byitj predvariteljnyim usloviyem obyichnogo vzaimodejstviya. Dannyiye i komandyi nad vyibrannyimi dannyimi svyazyivayutsya v obsjhej srede. Probuzhdayusjheye dejstviye sokhranyayet naznacheniye; vvod ne teryayetsya iz-za smenyi sostoyaniya prilozheniya.

LEAP rabotayet kak uderzhivayemoye sostoyaniye: nazhatiye klavishi nachinayet poisk, vvod posledovateljno utochnyayet shablon, otpuskaniye zavershayet perekhod. Ispravleniye shablona vosstanavlivayet sootvetstvuyusjheye najdennoye polozheniye. Povtor poiska ispoljzuyet prezhnij shablon i napravleniye; neuspekh pokazyivayetsya bez modaljnogo dialoga.

Obe Command naznachenyi poljzovatelem klavishami LEAP. Prinyatoye proyektnoye sootvetstviye — levaya Command nazad, pravaya vperyod. Fizicheskoye razlichiye klavish i prinyatyiye sobyitiya sokhranyayutsya; logicheskiye dejstviya LEAP ne zavisyat ot nalichiya Command na kazhdoj podderzhivayemoj platforme.

Sistemnyiye sochetaniya ne zadayut semantiku FUMA pri aktivnom razreshyonnom perekhvate. Vmeste s tem polnota perekhvata — proveryayemaya vozmozhnostj platformennogo adaptera: prilozheniye uchityivayet otkaz dostupa, otklyucheniye perekhvatchika i propusk sobyitij. Neizvestnoye sobyitiye ne vosstanavlivayetsya dogadkoj; povedeniye posle poteri perekhvata yavno opredeleno.

## Sostavnoj kursor

Po risunkam 5.8–5.9 i razdelu 5.6 knigi kursor otdeljno pokazyivayet mesto vstavki i obyyekt udaleniya. Obyyekt udaleniya vyidelen pryamougoljnoj podsvetkoj, simvol ostayotsya chitayemyim; vstavlyayusjhaya chastj imeyet otdeljnyij tonkij marker. Posle LEAP obe chasti otnosyatsya k vyibrannomu simvolu, posle vstavki ili udaleniya pokazyivayut sootvetstvuyusjhiye posledovateljnyiye pozicii.

Nash render sokhranyayet eti smyislovyiye chasti nezavisimo ot ikh vizualjnogo sosedstva. Pri RTL, vertikaljnom pisjme, perenose stroki i bustrofedone geometriya sleduyet napravleniyu i logicheskoj posledovateljnosti. Neljzya prosto zerkaljno perenesti ekrannyij pryamougoljnik i izmenitj smyisl udaleniya. Miganiye vstavlyayusjhej chasti zadayotsya nablyudayemyim vremenem libo yavnoj fazoj v prinyatom sostoyanii, chtobyi replay ne zavisel ot skryityikh chasov.

Sostoyaniye teksta, vyiborki i kursora postupayet v graf strukturiruyusjhikh operatorov. Operatoryi vyichislyayut geometriyu i vizualjnyiye priznaki, zatem porozhdayut komandyi Metal/Vulkan. Semantika i opisaniye formyi obsjhiye, platformennyij graficheskij adapter ispolnyayet rezuljtat. CoreText dlya sobstvennogo tekstovogo i shriftovogo rendera ne ispoljzuyetsya.

## Shriftovyiye vkhodyi

OTF i TTF prinyatyi kak planiruyemyiye vkhodnyiye formatyi razbora strukturiruyusjhimi operatorami. Susjhestvuyusjhiye [FUM-REQ-0073](../../Trebovaniya/🟡-plan-razbora-shriftov-strukturiruyusjhimi-operatorami.md) i [FUM-STEP-0219](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0219-splanirovatj-pervyij-shriftovoj-profilj-obsjhego-interpretatora.md) sokhranyayut identichnostj; novyiye nomera ne vyidayutsya.

Osnovaniya formatov: [struktura OpenType](../../Istochniki/URL/https/learn.microsoft.com/en-us/typography/opentype/spec/otff/source-index.md) i [tipyi konturov](../../Istochniki/URL/https/learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison/source-index.md).

Snachala planiruyetsya kontejner sfnt i tablicyi, zatem ogranichennyiye profili konturov TrueType i CFF; CFF2 i variacii prinimayutsya otdeljno. Format opredelyayetsya soderzhimyim, a ne odnim rasshireniyem. Otobrazheniye Unicode-kodov v nomera glifov, podstanovki/pozicionirovaniye, khinting i rastrirovaniye — raznyiye proveryayemyiye etapyi.

Izvlechyonnyiye polya, konturyi i metriki sokhranyayut pozicii v iskhodnyikh bajtakh. Dannyiye shrifta ne poluchayut polnomochij vyipolnyatj proizvoljnyij sistemnyij kod. Nepodderzhannyij profilj, usecheniye, perepolneniye, nevernaya ssyilka i prevyisheniye byudzheta privodyat k yavnoj diagnostike.

## Pervyij ogranichennyij srez

1. Obsjhij tekstovyij bufer, prinyatyiye sobyitiya vvoda, vyiborka i dvukhchastnoye sostoyaniye kursora.
2. LEAP v dvukh napravleniyakh, ispravleniye i povtor shablona, odna komanda nad vyideleniyem.
3. Geometriya kursora iz operatorov na otkryitoj scene, pervyij nablyudayemyij kadr cherez vyibrannyij graficheskij adapter.
4. Pervyij shriftovoj profilj na sinteticheskikh i razreshyonnyikh otkryityikh dannyikh s nezavisimyimi ozhidayemyimi polyami i konturami.

Odinakovyiye prinyatyiye vkhodyi vosstanavlivayut to zhe logicheskoye sostoyaniye i trassu. Kontroljnyiye scenarii vklyuchayut posledovateljnostj slat: vyibor l, udaleniye → sat libo vstavka p → splat, a takzhe Unicode, RTL, vertikaljnyij tekst i bustrofedon. Pikseljnaya vosproizvodimostj svyazyivayetsya s tochnyim profilem rastrirovaniya i GPU; odinakovostj raznyikh ustrojstv bez proverki ne obesjhayetsya.

Ispolnyayemyiye izmeneniya prokhodyat TDD, profilj i resheniye ob optimizacii. Razdeljno izmeryayutsya poisk, raschyot geometrii, razbor tablic, kadr i sokhraneniye; iskhodnyiye ozhidaniya testa ne peredayutsya ispolnitelyu kak podskazka.

Kod razmesjhayetsya v obsjhem Swift-pakete FUMA s platformennyimi usloviyami v komponentakh. Otdeljnyiye katalogi iskhodnogo koda po OS ne sozdayutsya. Podgotovka etogo plana ne vozobnovlyayet vse prezhniye priostanovlennyiye napravleniya; aktualizaciya susjhestvuyusjhikh kartochek vyipolnyayetsya sokhranyayemoj avtomatizaciyej priyoma.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:53:36 MSK -->
<!-- content-sha256: sha256:debd068a475d0ae15e3f2c22bc017be5404100ae98820fdca3c96f524924347c -->
<!-- FUM-MD-RECENCY:END -->
