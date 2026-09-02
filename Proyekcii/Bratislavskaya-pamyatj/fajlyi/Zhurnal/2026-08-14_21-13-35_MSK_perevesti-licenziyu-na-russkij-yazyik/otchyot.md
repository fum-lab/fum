# Otchyot 2026-08-14 21:13:35 MSK - Perevesti licenziyu na russkij yazyik

V korne pamyati FUM sozdan fajl `ЛИЦЕНЗИЯ` s polnyim russkim perevodom yuridicheskogo teksta Creative Commons CC0 1.0 Universal. Imya fajla i perevod napisanyi kirillicej; obyazateljnyiye vneshniye oboznacheniya `Creative Commons`, `CC0`, `LICENSE` i URL sokhranenyi bez izmeneniya. Anglijskij `LICENSE` ne menyalsya i pryamo ukazan kak yedinstvennyij yuridicheski opredelyayusjhij tekst pri raskhozhdeniyakh.

`LICENSE.md` teperj vedyot kak k mashinoraspoznavayemomu anglijskomu originalu, tak i k spravochnomu russkomu perevodu. Ruchnaya bratislavskaya kopiya ne sozdavalasj: kanonicheskim izmeneniyem ostayotsya kirillicheskij fajl, a proizvodnaya proyekciya otnositsya k otdeljnoj avtomatizacii FUM.

Terminologiya sverena s anglijskim `LICENSE` i opublikovannyim Creative Commons spravochnyim russkim perevodom. Poslednij sokhranyon v kanonicheskoj URL-papke vmeste s syiryim HTML, ochisjhennyimi HTTP-zagolovkami, izvlechyonnyim tekstom i otchyotom. Yego tekst ne kopirovalsya bukvaljno: anglijskij original ispoljzovan kak postatejnaya osnova, v tom chisle dlya ispravleniya opechatok i logicheskoj inversii usloviya rezervnoj licenzii v starom spravochnom perevode.

Poljzovateljskiye izmeneniya chetyiryokh parametrov grafa Obsidian, vremenno sokhranyonnyiye cherez stash radi obyazateljnoj marshrutizacii, vozvrasjhenyi v osnovnoj checkout i perenesenyi v rezuljtat bez izmeneniya znachenij. Avtomatizaciya svezhesti grafa sokhranyayet eti parametryi i peresobirayet toljko upravlyayemyiye cvetovyiye gruppyi.

Pervyij polnyij smoke-check vyiyavil infrastrukturnuyu nesovmestimostj, ne svyazannuyu s perevodom: staryij live-test selektora zhyostko ozhidal dannyiye `master`, khotya novyij worktree-pul zapuskayet proverki v sluzhebnoj vetke `refs/heads/codex/подузлы/*`, kotoraya ne yavlyayetsya otdeljnoj planovoj liniyej. Test poluchil uzkoye usloviye propuska toljko dlya vetok etogo pula; vse drugiye imenovannyiye vetki po-prezhnemu obyazanyi imetj tochnuyu planovuyu zapisj i proveryayutsya bez oslableniya.

## Profilj vremeni vyipolneniya

| Stadiya                      | Dliteljnostj | Granicyi i sposob izmereniya                                                                 |
| --------------------------- | ------------ | ------------------------------------------------------------------------------------------ |
| Marshrutizaciya i dopusk      | ne izmereno  | Vyipolnenyi do kanonicheskoj vremennoj metki otchyota; vklyuchali stash i vyideleniye otdeljnogo slota |
| Issledovaniye i perevod      | ne izmereno  | Ot metki 21:13:35 MSK do nachala celevyikh proverok; arkhivirovaniye istochnika i vyiverka teksta |
| Celevyiye proverki            | po tablice   | Monotonnyiye dliteljnosti otdeljnyikh vyizovov sokhranenyi mashinnoj obyortkoj nizhe                 |
| Polnyij smoke-check          | 3258,994 s   | Povtornyij yedinyij lokaljnyij progon zavershil uspeshno vse 77 etapov                           |
| Terminaljnaya fiksaciya       | vne profilya  | Zamorozka rezuljtata vyipolnyayetsya posle zakryitiya otchyota i proverok zamyikaniya                |

Granica profilya: ot kanonicheskoj metki 2026-08-14 21:13:35 MSK do zakryitiya mashinnogo snimka proverok; ozhidaniye rannego marshruta i posleduyusjhaya terminaljnaya fiksaciya nakhodyatsya vne izmerennoj granicyi, a dliteljnosti pryamyikh proverok pri vozmozhnom perekryitii ne skladyivayutsya so stadijnyim vremenem.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:c2908b872ae06d8156274cc48e1369b9c11f911fd582e37089be9715b630d3ae -->

| Vyizov                                                                           | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Sverka polnotyi russkogo perevoda CC0                           | 0,078 s      | neuspeshno |
| [kornevoj agent] Diagnostika strukturyi perevoda CC0                             | 0,035 s      | uspeshno   |
| [kornevoj agent] Sverka polnotyi russkogo perevoda CC0 — ispravlennyij scenarij   | 0,041 s      | uspeshno   |
| [kornevoj agent] Proverka neizmennosti anglijskogo LICENSE                      | 0,02 s       | uspeshno   |
| [kornevoj agent] Proverka strukturyi papok zaprosov                              | 0,036 s      | neuspeshno |
| [kornevoj agent] Proverka strukturyi papok zaprosov — ispravlennyij putj          | 10,808 s     | uspeshno   |
| [kornevoj agent] Proverka chistotyi patcha Git                                     | 0,04 s       | uspeshno   |
| [kornevoj agent] Proverka svezhesti Markdown                                     | 0,722 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti grafa Obsidian                               | 0,454 s      | uspeshno   |
| [kornevoj agent] Polnyij kompleksnyij smoke-check repozitoriya                     | 275,926 s    | neuspeshno |
| [kornevoj agent] Diagnostika planovoj zapisi master iz poduzla                  | 0,12 s       | neuspeshno |
| [kornevoj agent] Regressiya sleduyusjhego shaga vetki v worktree-poduzle             | 179,458 s    | uspeshno   |
| [kornevoj agent] Povtornaya proverka chistotyi patcha posle infrastrukturnoj pravki | 0,041 s      | uspeshno   |
| [kornevoj agent] Proverka ostatka obyyavlenij posle infrastrukturnoj pravki      | 5,147 s      | neuspeshno |
| [kornevoj agent] Povtornaya proverka ostatka obyyavlenij bez sdviga strok         | 5,34 s       | neuspeshno |
| [kornevoj agent] Proverka ostatka obyyavlenij posle sokhraneniya pozicij           | 5,13 s       | uspeshno   |
| [kornevoj agent] Predfinaljnaya proverka chistotyi patcha Git                       | 0,069 s      | uspeshno   |
| [kornevoj agent] Povtornyij polnyij kompleksnyij smoke-check repozitoriya           | 3259,078 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3742,543 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Struktura chetyiryokh razdelov, semi podpunktov Avtorskikh i Smezhnyikh Prav i chetyiryokh ogranichenij sopostavlyayetsya mezhdu `LICENSE` i `ЛИЦЕНЗИЯ` otdeljnoj celevoj proverkoj.
- Publikacionnaya i strukturnaya gotovnostj podtverzhdayetsya lokaljnyimi validatorami, `git diff --check`, recency, svyaznostjyu rabochej sessii i polnyim smoke-check.
- Posle obnaruzhennoj nesovmestimosti adresnyij nabor `fum-sleduyusjhij-shag-vetki` proshyol 186 testov, a povtornyij polnyij smoke-check — vse 77 etapov za 3258,994 s; pervyij neuspeshnyij polnyij progon ostayotsya v mashinnom zhurnale.
- Vse pryamyiye vyizovyi, vklyuchaya povtoryi i vozmozhnyiye neuspekhi, sokhranyayutsya v zakryitom mashinnom snimke nizhe.

## Resheniya i ogranicheniya

- `ЛИЦЕНЗИЯ` yavno nazvana spravochnyim perevodom proyekta FUM, a ne oficialjnyim yuridicheskim tekstom Creative Commons.
- `LICENSE` ostayotsya bez izmenenij radi GitHub-obnaruzheniya, SPDX-sovmestimosti i yuridicheskoj opredelyonnosti.
- Bratislavskaya proizvodnaya oblastj vruchnuyu ne sozdayotsya i ne redaktiruyetsya.
- Spravochnyij russkij istochnik Creative Commons ispoljzovan dlya terminologii, no kazhdyij punkt zanovo sveren s anglijskim originalom; obnaruzhennyiye opechatki i smyislovyiye oshibki istochnika ne perenesenyi.
- Usloviye propuska live-testa ogranicheno tochnyim prostranstvom sluzhebnyikh refs worktree-pula i ne rasprostranyayetsya na proizvoljnyiye vetki, chtobyi ne skryivatj otsutstviye ikh planovyikh selektorov.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [anglijskij yuridicheskij tekst CC0](../../LICENSE)
- [kratkaya pamyatka o licenzii](../../LICENSE.md)
- [sokhranyonnyij spravochnyij russkij perevod Creative Commons](../../Istochniki/URL/https/wiki.creativecommons.org/wiki/Publicdomain/zero/1.0/LegalText_-Russian-35eacbaf5d6489ab/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 22:44:56 MSK -->
<!-- content-sha256: sha256:d7dfe91e42bc2b6f15654aee7d4e6342d705284441e9e8f4dcbb1caa38fbcc03 -->
<!-- FUM-MD-RECENCY:END -->
