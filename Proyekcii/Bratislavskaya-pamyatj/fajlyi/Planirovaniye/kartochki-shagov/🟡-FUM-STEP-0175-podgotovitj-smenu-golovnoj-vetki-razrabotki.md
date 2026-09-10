+++
schema_version = 1
card_id = "FUM-STEP-0175"
status = "active"
+++
# Podgotovitj smenu golovnoj vetki razrabotki

## Zadacha

Podgotovitj perekhod k vyibrannoj golovnoj linii razrabotki, kotoruyu mozhno menyatj po neobkhodimosti. Nezavisimyiye dorabotki vyipolnyayutsya v otdeljnyikh vetkakh i rabochikh derevjyakh; v master periodicheski postupayet sovmestno proverennyij rezuljtat.

## Pochemu sejchas

Poljzovatelj ukazal, chto nuzhnoye paralleljnoye povedeniye uzhe razrabotano v sokhranyonnoj vetke, i predlozhil ispoljzovatj aktualjnuyu golovnuyu liniyu do perenosa obsjhego rezuljtata v master. Povtornoye izobreteniye etoj politiki vmesto yeyo proverki teryayet podgotovlennuyu rabotu.

## Sokhranyonnaya osnova

Vetka `codex/планирование-наблюдения-macos-01a07d3d`, vershina `ef0b528c8c117f7cfddb83d1699aa333d9c486a5`, soderzhit sentyabrjskij perekhod posle ruchnogo rezhima:

- `a521c41df61f7f8d3411c8782a74dfae5eed22b5` — `isolated-per-task-v1`, otdeljnyiye worktree, vetki i promezhutochnyiye kommityi.
- `39c40194655fbe27e851abfea17c5c432dca5a9f` — otdeljnyiye derevjya pishusjhikh detej i prodolzheniye posle kommita.
- `9b9c456e0be6ce409f21f4653b6caa09d132f3d7` — celesoobraznoye paralleljnoye vyideleniye soglasovannoj nezavisimoj rabotyi.
- `008f27dcc34d6991b437109ddfc8166f25be9e28` — vidimyiye nezavisimyiye zadachi Codex Desktop po zaprosu poljzovatelya.

Osnovnyiye puti v etikh Git-obyyektakh: `AGENTS.md` i `Правила/агентов/проверки-коммит-и-публикация.md`. Oni rassmatrivayutsya kak istochniki perekhoda; nalichiye istoricheskogo pravila samo po sebe ne vklyuchayet staryiye ocheredi, hooks ili publikaciyu. Na moment nablyudeniya master `ef6b936be7ac4ac518e0c5b5f5792263a686fab7` i sokhranyonnaya vetka imeyut 5 i 33 sobstvennyikh kommita ot obsjhej bazyi `a3bde39c84528848b13b0b2b415a7e6fd033b9a1`; gotovnostj avtomaticheskogo merge ne dokazana.

## Podgotovlennaya granica i prodolzheniye

Poljzovatelj utochnil napravleniye v [sleduyusjhem etape](../../Zhurnal/2026-09-10_14-26-58_MSK_proveryatj-sliyaniye-master-v-vedusjhuyu-vetku/zapros.md): iskhodnyij master M vlivayetsya v gotovuyu vedusjhuyu vetku L; posle proverki master prodvigayetsya do togo zhe C s roditelyami `[L, M]`. Vedusjhej osnovoj vyibrana `codex/планирование-наблюдения-macos-01a07d3d` na `ef0b528c8c117f7cfddb83d1699aa333d9c486a5`. Osnovnoj prioritet — yeyo polnocennoye obyyedineniye s sokhraneniyem rezuljtatov master. Podgotovka kandidata otdelena ot razresheniya yego prodvizheniya.

[Karta sokhraneniya rezuljtatov](../../Zhurnal/2026-09-10_14-26-58_MSK_proveryatj-sliyaniye-master-v-vedusjhuyu-vetku/materialyi/karta-obyyedineniya.md) podtverzhdayet: Git-mekhanika sliyaniya, vosstanovleniya, proverki roditelej i CAS uzhe yestj v oboikh derevjyakh pobajtno. Yeyo povtornaya realizaciya isklyuchena iz plana. Kyesh, v4-raundyi, vkhod snimka indeksa i zasjhita prodolzheniya berutsya iz podgotovlennoj vetki. Soglasovaniyu podlezhat sokhraneniye fajlov Finder, raznyiye pokoleniya reyestra obyazateljstv i priyomochnyikh svideteljstv, a takzhe yavno vyibrannyiye pravila rabotyi.

Snachala gotovitsya konkretnyij kandidat i razreshayutsya eti razlichiya. Toljko nedostayusjhiye dlya yego priyomki proverki dorabatyivayutsya otdeljno. Novyij chitatelj svyazi otchyota so sliyaniyem poka ostayotsya chastnyim chernovikom vne checkout: on ne nuzhen dlya sostavleniya samogo kandidata. Istochnik doverennogo proverochnogo koda M i predkommitnyij HEAD L razlichayutsya. Tekusjhaya obyortka i smoke yesjhyo smeshivayut istochnik proverok s celevyim kornem; eto ogranicheniye ne skryivayetsya uspeshnyimi proverkami drugogo sostava.

## Kriterii zaversheniya

- Sopostavlenyi podgotovlennaya politika i prinyatyiye izmeneniya master, sokhranenyi proverennyiye v3-svideteljstva i proiskhozhdeniye obeikh linij.
- Opredelenyi vyibrannaya golovnaya liniya, yeyo osnovaniye i poryadok bezopasnoj smenyi s sokhraneniyem nezavershyonnyikh zadach.
- Razdelenyi nezavisimyiye rabochiye derevjya i mesto sovmestnoj priyomki; obnovlyon obyazateljnyij nabor pravil bez neyavnogo vklyucheniya istoricheskikh polnomochij.
- Rezuljtat integracii proveryayetsya do popadaniya v master; kontroljnyij kommit s planom ne vyidayotsya za prinyatuyu realizaciyu.
- Podderzhana priyomka nastoyasjhikh merge-kommitov: tekusjhij adapter ogranichen odnim roditelem. Integracionnaya vetka v otdeljnom dereve stroitsya ot vedusjhej L, prinimayet master M i sokhranyayet C s roditelyami [L, M]; posle proverki master prodvigayetsya do togo zhe C pri sokhranenii M i soglasovannosti osnovnogo checkout.
- Izmeneniya pravil samoj integriruyemoj linii ne mogut nezametno oslabitj yeyo priyomku; susjhestvennyiye ogranicheniya i vozrazheniya soobsjhayutsya poljzovatelyu.
- Priyomka vyipolnyayetsya po pravilam zafiksirovannogo iskhodnogo master. Predlagayemyiye novyiye pravila ocenivayutsya vnutri kandidata i nachinayut dejstvovatj posle prinyatiya; proveryayusjhaya storona ne podmenyayetsya kandidatnoj realizaciyej.
- Utochnena granica rannego sokhraneniya nablyudenij: vetka opravdana samostoyateljnyim rezuljtatom i pervyim shagom, a dannyiye sokhranyayutsya nezavisimo ot sozdaniya vetki.

## Istochniki

- [Pryamyiye komandyi i soderzhateljnyiye otvetyi](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/zapros.md).
- [Podgotovka proveryayemogo perenosa soderzhimogo vetok](../../Zhurnal/2026-09-10_02-01-28_MSK_proveryatj-zakryityiye-otchyotyi-iz-kommitov/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 14:37:13 MSK -->
<!-- content-sha256: sha256:41306367388eadba55fc1175b3ec47ea678abd4272b986fa1906a790b4cc5858 -->
<!-- FUM-MD-RECENCY:END -->
