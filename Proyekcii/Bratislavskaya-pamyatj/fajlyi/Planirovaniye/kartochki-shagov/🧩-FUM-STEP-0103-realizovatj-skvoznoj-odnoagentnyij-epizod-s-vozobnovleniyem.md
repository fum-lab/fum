+++
schema_version = 1
card_id = "FUM-STEP-0103"
status = "absorbed"
+++
# Realizovatj skvoznoj odnoagentnyij epizod s vozobnovleniyem

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sobratj v sobstvennom bezokonnom runtime FUM odin uzkij skvoznoj odnoagentnyij scenarij: vneshnyaya zadacha, realjnyij model-only-vyizov, razreshyonnyiye lokaljnyiye instrumentyi, izolirovannaya rabochaya kopiya, proverki, kandidatnyij kommit, otdeljnaya priyomka i terminaljnyij iskhod. Pered podtverzhdayemyim povyisheniyem kandidatnogo sostoyaniya runtime dolzhen priparkovatj vneshnij perekhod, prodolzhitj ogranichennuyu modeljnuyu proverku variantov i sokhranitj vnutrennij vyibor otdeljno ot dopuska. Prinuditeljno prervatj epizod v zadannoj kontroljnoj tochke i zavershitj yego novyim processom toljko iz podtverzhdyonnoj pamyati.

## Rezuljtat

Kontekstnyij preflight pokazal, chto iskhodnyij vertikaljnyij srez neljzya chestno realizovatj i prinyatj za odno svezheye kontekstnoye okno. Dejstvuyusjhij obsjhij smoke-check zapresjhayet lyubyiye zavisimosti mezhdu SwiftPM-prototipami, zhivoj LM Studio process-adapter ne zakreplyayet ispolnimyij limit vyikhodnyikh tokenov, a skhema nablyudayemoj trassyi versii `3` opisyivayet lokaljnuyu fiksturu, no ne pasport, kandidatnyij kommit, otdeljnuyu priyomku i podtverzhdyonnoye mezhprocessnoye vozobnovleniye zhivogo epizoda. Monolitnaya realizaciya skryila byi eti nezavisimyiye kontraktyi libo vyidala byi chastichnyij stend za vyipolneniye kriteriyev.

Kartochka poglosjhena ustojchivoj posledovateljnostjyu atomarnyikh shagov:

1. [FUM-STEP-0107 — razreshitj proveryayemyiye lokaljnyiye SwiftPM-zavisimosti prototipov](✅-FUM-STEP-0107-razreshitj-proveryayemyiye-lokaljnyiye-SwiftPM-zavisimosti-prototipov.md);
2. [FUM-STEP-0108 — zakrepitj ispolnimyij token-byudzhet model-only-profilya](✅-FUM-STEP-0108-zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya.md);
3. [FUM-STEP-0109 — vvesti skhemu sobyitij zhivogo odnoagentnogo epizoda](✅-FUM-STEP-0109-vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda.md);
4. [FUM-STEP-0110 — realizovatj podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](✅-FUM-STEP-0110-realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda.md);
5. [FUM-STEP-0111 — realizovatj izolirovannyij kandidatnyij kommit i otdeljnuyu priyomku](✅-FUM-STEP-0111-realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku.md);
6. [FUM-STEP-0112 — zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md).

Pervyim avtomaticheskim prodolzheniyem stanovitsya toljko FUM-STEP-0107, proshedshaya tot zhe preflight kak bezopasnaya, polnomochnaya i kontekstno ogranichennaya. Ostaljnyiye docherniye kartochki sokhranyayut poryadok proiskhozhdeniya i ne vklyuchayutsya v rabochij whitelist zaraneye. Iskhodnaya zadacha, yeyo devyatj kriteriyev i chestnoye ogranicheniye odnim scenariyem zavershayutsya toljko sovokupnyim rezuljtatom FUM-STEP-0112; eta sessiya realizacii runtime ne vyipolnyala.

## Istochniki

- [trebovaniye ob avtonomnom modeljnom prodolzhenii pri ozhidanii podtverzhdeniya](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [trebovaniye o skvoznom proveryayemom odnoagentnom epizode](../../Trebovaniya/✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md)
- [MVP-kandidat ispolnyayemogo agentskogo cikla](../MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [FUM-STEP-0102 — realjnyij model-only-adapter](✅-FUM-STEP-0102-podklyuchitj-proveryayemyij-realjnyij-model-only-adapter.md)
- [FUM-STEP-0106 — neblokiruyusjheye modeljnoye vetvleniye pri ozhidanii podtverzhdeniya](✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md)
- [iskhodnyij dispetcherskij zapros o vyipolnenii FUM-STEP-0103](../../Zhurnal/2026-07-30_11-42-13_MSK_dekompozirovatj-realizaciyu-skvoznogo-odnoagentnogo-epizoda/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c8fbf19a8c995f5a91ca03be61243c70d2f32f9a2f2e58a15ab827867275868d -->
<!-- FUM-MD-RECENCY:END -->
