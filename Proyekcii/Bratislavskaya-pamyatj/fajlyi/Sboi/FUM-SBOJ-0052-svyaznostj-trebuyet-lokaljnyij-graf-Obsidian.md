+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0052"
"статус" = "устранена"
+++
# Svyaznostj trebuyet lokaljnyij graf Obsidian

Proverka Markdown-ssyilok zavisit ot fizicheskogo nalichiya `.obsidian/graph.json`, khotya fajl yavlyayetsya neobyazateljnyim lokaljnyim sostoyaniyem poljzovatelya i ignoriruyetsya Git. Novyij worktree libo chistyij klon poetomu poluchayet sotni otkazov po istoricheskim ssyilkam do proverki soderzhateljnogo rezuljtata.

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0052/ПРОЯВЛЕНИЕ-0001`: zadacha perenosa 0176 `01a08d6d-e706-7e70-9f70-fdfa5a6826c2` na baze `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`; pervaya svyaznostj novogo worktree zavershilasj otkazom po istoricheskim ssyilkam na otsutstvuyusjhij graf. [Mashinnyiye zapisi](../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/materialyi/zapuski-proverok/) sokhranyayut zapusk «Proverka strukturyi, ssyilok i publikacionnoj chistotyi kontroljnoj tochki»; [otchyot](../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/otchyot.md) opisyivayet rezuljtat.
- `FUM-СБОЙ-0052/ПРОЯВЛЕНИЕ-0002`: koordinator podtverdil tu zhe granicu v zadache posledovateljnoj istorii FUMA `01a08d69-b088-7820-838e-dd4e97033753`: 282 istoricheskiye ssyilki, `actual_case_path` trebuyet fizicheskij fajl. Podtverzhdeniye koordinatora i ogranichennoye vosstanovleniye zafiksirovanyi v tom zhe otchyote; syiroj vyivod drugoj zadachi zdesj ne vosproizvodilsya.

Obsjhij mekhanizm — proverka obyazateljnogo susjhestvovaniya ignoriruyemoj lokaljnoj celi. Istoricheskiye FUM-SBOJ-0007 (opornaya data) i FUM-SBOJ-0017 (gryaznoye derevo) imeyut drugiye regressionnyiye granicyi i etim sluchayem ne poglosjhayutsya.

## Vosstanovleniye i sistemnaya mera

V oboikh novyikh derevjyakh vosstanovlena toljko raneye otsutstvovavshaya lokaljnaya kopiya grafa iz susjhestvuyusjhego dereva, bez izmeneniya iskhodnika i bez dobavleniya v Git. Dlya vtorogo proyavleniya koordinator soobsjhil razmer 574 bajta. Eto lokaljnaya podgotovka, ne ustraneniye zavisimosti obsjhego dopuska ot chastnogo sostoyaniya.

Pervonachaljno kod svyaznosti v perenose ne menyalsya. Zatem otdeljnyij ispolnitelj 0203 dostavil uzkoye ispravleniye `28f51c58fa8df4d20d33ef2f05dab758cb7a6f83`, kotoroye prinyato v 0176. Regressii podtverzhdayut sokhrannostj poljzovateljskogo grafa i otkazyi bityikh, registronevernyikh i simvolicheskikh obkhodov isklyucheniya.

Kriterij zakryitiya podtverzhdyon [proverkoj vsekh 1598 kanonicheskikh Markdown-fajlov publichnogo chistogo klona](../Zhurnal/2026-09-11_02-51-49_MSK_proveritj-postavku-FUMA-iz-klona/materialyi/ssyilki-chistogo-klona.json): oshibok net, graf otsutstvuyet do i posle, derevo chisto. Proveryayusjhij kod i vkhodnoj kommit ukazanyi razdeljno. Eto ustojchivoye isklyucheniye tochnoj neobyazateljnoj celi, ne import chastnogo sostoyaniya.

## Svyazannyiye shagi

- [FUM-STEP-0203](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0203-otvyazatj-svyaznostj-ot-lokaljnogo-grafa-Obsidian.md); osnovaniye — povtor `FUM-СБОЙ-0052/ПРОЯВЛЕНИЕ-0002`.

## Kriterij zakryitiya

Svezhij klon prokhodit primenimyij ssyilochnyij dopusk bez sozdaniya ili importa privatnogo graph.json; realjno bityiye i registronevernyiye ssyilki prodolzhayut otklonyatjsya. Proverka ne menyayet susjhestvuyusjheye sostoyaniye poljzovatelya. Tochnyiye regressii i vosproizvedeniye iz chistogo klona podtverzhdayut etu granicu.

## Istochniki

- [Zapros perenosa i proiskhozhdeniye porucheniya koordinatora](../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/zapros.md).
- [Dejstvuyusjhaya granica lokaljnogo sostoyaniya](../AGENTS.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:54182ceda473df0af812e41f2892b941ecf7ffd42e119bffcaa95a3ed11e73da -->
<!-- FUM-MD-RECENCY:END -->
