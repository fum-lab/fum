+++
schema_version = 1
card_id = "FUM-STEP-0228"
status = "active"
+++
# Kontrolirovatj dostavku v postoyannuyu vetku

## Zadacha

Realizovatj nablyudayemyij kontrolj svoyevremennoj dostavki prinyatogo rezuljtata postoyannoj vetke FUMA. Naznacheniye svyazyivayet kornevoj UUID, tochnyij ref postoyannoj vetki, yeyo fizicheskij korenj, naznachennogo pisatelya, iskhodnyij kommit i podtverzhdyonnuyu granicu priyomki. Posle kommita i pered vyiborom sleduyusjhego etapa avtomatizaciya sravnivayet eto naznacheniye s fakticheskim Git i sostoyaniyem vladeljca.

## Pochemu sejchas

[FUM-SBOJ-0144/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0144-zaderzhka-dostavki-v-postoyannuyu-vetku.md) pokazalo otstavaniye postoyannoj vetki na 50 kommitov pri otsutstvii raskhodyasjhejsya istorii i nesokhranyonnyikh izmenenij prezhnego pisatelya. Poljzovatelj podtverdil: integraciya prioritetna, povedeniye trebuyetsya zakrepitj v plane realizacii. Razovyij fast-forward 51 kommita do `19765643195f0fb87dce58c7aba7fd1b50301531` vosstanavlivayet tekusjhuyu dostavku, no ne zamenyayet mekhanizm.

## Plan realizacii

1. Pereispoljzovatj prinyatyij ogranichennyij mekhanizm obratnoj dostavki: tochnyij plan, sostoyaniya, kvitancii i sovmestimostj so shtatnoj otchyotnoj obyortkoj. Prinyatyij srez svyazyivatj s iskhodnyim OID i granicej proverki; publichnyij checkpoint ne zamenyayet priyomku istochnika.
2. Ispoljzovatj prinyatoye tochnoye naznacheniye fuma s kornevyim UUID, polnyim ref, fizicheskim derevom i vladeljcem. Sokhranyatj proverku dejstviteljnogo naznacheniya i otkaz prezhnemu otsoyedinyonnomu derevu; dopusk inyikh postoyannyikh vetok ne vyivoditj iz podderzhki fuma.
3. Vyichislyatj kompaktnyij signal: nedostavlennyij prinyatyij srez, yego vozrast v kommitakh/nablyudyonnom vremeni, otvetstvennyij, prichina ozhidaniya i svezhestj vkhodov. Chislovoj porog nastraivayetsya; granicyi vyivodyatsya iz istochnika i ne schitayutsya universaljnyimi.
4. Vklyuchitj signal v vyibor sleduyusjhej razreshyonnoj rabotyi: gotovaya dostavka prioritetneye neobyazateljnogo rasshireniya infrastrukturyi. Nedostupnostj pisatelya libo priyomki sokhranyayetsya kak yavnoye prepyatstviye s nezavisimoj dostupnoj rabotoj.
5. Primenyatj dostavku vladeljcem i sokhranyatj tochnuyu kvitanciyu lokaljnogo i udalyonnogo rezuljtata. Proveritj realjnyiye vyizovyi koordinatora/poluchatelya; prostoj JSON-plan ne obyyavlyatj podklyuchyonnyim runtime.
6. Posle gotovnosti infrastrukturyi vyirazhatj politiku vyibora i kompoziciyu dejstvij cherez strukturiruyusjhiye operatoryi; Swift i Git-adapteryi ispolnyayut neobkhodimyiye primitivyi. Ne perepisyivatj gotovyij mekhanizm bez neobkhodimosti.

Ogranichennyiye postavki mekhanizma i naznacheniya prinyatyi v fuma i vkhodyat v `d76d9d87faedf2cfe8de5bf4c5b2ae4ed724ff7b`. Kompaktnoye nablyudeniye pokazyivayet Git-sostoyaniye, nedostavku i svezhestj, no ne podtverzhdayet polucheniye, nachalo ozhidaniya ili dostupnostj pisatelya. Podklyucheniye signala k realjnomu vyiboru rabotyi, svoyevremennostj i polnyij kriterij FUM-STEP-0228 ostayutsya nezavershyonnyimi. Dopusk planirovaniye susjhestvuyusjhim ispolnitelem ne podtverzhdyon.

## Kriterii zaversheniya

- TDD vosproizvodit iskhodnuyu zaderzhku, oshibochnuyu privyazku dereva posle vosstanovleniya, peredachu vladeljca, uzhe dostavlennyij OID, novyij chelovecheskij prioritet, dirty i ustarevshij plan.
- Detektor vyidayot tochnoye proiskhozhdeniye i priznayot neizvestnostj; otsutstviye source v predkakh ne yavlyayetsya yedinstvennyim dokazateljstvom neobkhodimosti perenosa posle vyiborochnoj integracii.
- Proverki i otchyotnyij deljta prinimayutsya shtatno, lokaljnyiye tracked/untracked/ignored i neizmennyiye zavisimosti sokhranyayutsya. Konflikt i nezavershyonnaya operaciya ne skryivayutsya.
- Povtor vosstanavlivayet stadiyu bez novogo effekta; uspeshnyij push podtverzhdyon udalyonnyim OID. Master obnovlyayetsya otdeljno po svoim pravilam.
- Izmerenyi stoimostj obnaruzheniya, obyyom konteksta i vliyaniye na vremya dostavki na otkryitom vosproizvodimom scenarii. Proveren realjnyij styik rabochego cikla; fonovoye raspisaniye bez otdeljnogo razresheniya ne vklyuchayetsya.

## Istochniki

- [Prinyatyiye ogranichennyiye rezuljtatyi i naznacheniya](../../Zhurnal/2026-09-15_19-02-24_MSK_podklyuchitj-dopusk-postoyannoj-vetki/otchyot.md).

- [FUM-SBOJ-0144/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0144-zaderzhka-dostavki-v-postoyannuyu-vetku.md) — osnovaniye i granica sistemnoj meryi.
- [Komandyi i registraciya](../../Zhurnal/2026-09-15_17-55-33_MSK_vernutj-dostavku-v-postoyannuyu-vetku/zapros.md).
- [Iskhodnaya postanovka dostavki](../../Zhurnal/2026-09-15_16-58-55_MSK_zapustitj-prioritetnyiye-paralleljnyiye-rabotyi/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 20:02:40 MSK -->
<!-- content-sha256: sha256:3f8ebae6e3a897183c795cb4d3715fbc7ffe635fdbff9dc70e291d1e9b80e8ef -->
<!-- FUM-MD-RECENCY:END -->
