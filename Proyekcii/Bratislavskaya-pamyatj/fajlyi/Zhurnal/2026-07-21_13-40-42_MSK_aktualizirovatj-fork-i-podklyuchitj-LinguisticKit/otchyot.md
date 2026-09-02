# Otchyot 2026-07-21 13:40:42 MSK - Aktualizirovatj fork i podklyuchitj LinguisticKit

LinguisticKit podklyuchyon k FUM kak pervaya polnostjyu oformlennaya vneshnyaya Git-zavisimostj: postoyannyij fork nakhoditsya ryadom s aktualjnyim repozitoriyem FUM, lokaljnaya kopiya khranitsya kak submodule, a vyibrannaya reviziya i vsya Git-topologiya proveryayutsya avtonomno.

## Fork i zakreplyonnaya reviziya

Publichnyij fork `fum-lab/LinguisticKit` podtverzhdyon kak pryamoj fork `Roman-Kerimov/LinguisticKit` i bezopasno sinkhronizirovan s originalom bez prinuditeljnoj perezapisi. Obe vetki `master` ukazyivayut na `f26d46c99367bb1eef37c50906d2691ef36ca4d2`.

Proyekt ne sleduyet vershine forka avtomaticheski. Gitlink zakreplyayet reviziyu `837e2ce107b97ee7b9d3344c9fe99142281fe393`, uzhe proverennuyu so Swift `6.4`; ona dostizhima i cherez fork, i cherez original. Takoj vyibor razdelyayet obsluzhivaniye zerkala i osoznannoye obnovleniye zavisimosti. Licenziya zavisimosti — `CC0-1.0`.

## Postoyannyij kontrakt Git-zavisimostej

Pravilo boljshe ne privyazano k odnoj organizacii. Dlya kazhdogo klona FUM vladelec forka opredelyayetsya po GitHub-vladeljcu tekusjhego `origin`: v iskhodnom repozitorii eto `fum-lab`, a v organizacionnom ili lichnom klone — sootvetstvuyusjhaya organizaciya ili poljzovatelj. Neodnoznachnyij origin ili nedokazannyij fork zakryivayet dobavleniye.

V `.gitmodules` sokhranyayutsya adres forka i otdeljnyij `fumUpstream`. V rabochej kopii zavisimosti `origin` ukazyivayet na fork, a `upstream` — na original. Submodule nakhoditsya v chistom detached HEAD, ne yavlyayetsya shallow-klonom i tochno sovpadayet s gitlink roditeljskogo repozitoriya.

## Proveryayemaya avtomatizaciya

Novaya avtomatizaciya `fum-proverka-git-zavisimostej` sozdana cherez krasno-zelyonyij cikl i pokryita pyatnadcatjyu avtonomnyimi testami na lokaljnyikh bare-repozitoriyakh. Rezhim `add` snachala proveryayet udalyonnyiye repozitorii vo vremennom kataloge i toljko zatem menyayet proyekt; rezhim `check` ne obrasjhayetsya k seti i proveryayet polnyij kontrakt tekusjhej rabochej kopii. Regressionnyiye scenarii otklonyayut ekvivalentnyiye URL odnogo repozitoriya, sovpadayusjhikh vladeljcev forka i upstream, uchyotnyiye dannyiye v URL, nevernyiye fetch- ili push-adresa i popyitku zakhvatitj prezhnyuyu pravku `.gitmodules`.

Zhivoj validator imyon teperj chitayet LinguisticKit iz submodule i khranit otdeljno adresa forka i originala. Obsjhij smoke-check zapuskayet obe proverki, poetomu otsutstviye submodule, nevernyij remote, nedostizhimaya iz lokaljno poluchennyikh refs forka reviziya ili raskhozhdeniye gitlink obnaruzhivayutsya do kommita. Zhivaya publikaciya revizii proverena otdeljno cherez GitHub.

## Proverki

- GitHub API podtverdil pryamoye proiskhozhdeniye forka i sovpadeniye `master` forka i originala.
- Vse `32` testa zakreplyonnoj revizii LinguisticKit proshli so Swift `6.4`.
- Avtonomnyiye naboryi proverki Git-zavisimostej, nazvanij i smoke-runner proshli `15`, `20` i `14` testov sootvetstvenno.
- Zhivoj validator proveril `19` imyon cherez materializovannyij LinguisticKit.
- Polnyij avtonomnyij smoke-check bez vlozhennogo session-coherence, otdeljnaya svyaznostj s dokumentirovannyim propuskom obsjhego Git-status, recency, graf Obsidian i sleduyusjhij shag vetki proverenyi pered kommitom; puti paralleljnoj sessii prototipa ne vklyuchenyi v tekusjhij indeks.

## Zatronutyiye materialyi

- [opisaniye zavisimostej](../../Zavisimosti/README.md)
- [pravila repozitoriya](../../AGENTS.md)
- [proverka Git-zavisimostej](../../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md)
- [proverka nazvanij avtomatizacij](../../Instrumentyi/fum-proverka-nazvanij-avtomatizacij/SKILL.md)
- [obsjhij smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [sleduyusjhij shag vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros 2026-07-21 13:40:42 MSK](zapros.md)
- [iskhodnyij zapros o forkakh Git-zavisimostej](../2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/zapros.md)
- [iskhodnyij zapros o klonirovanii vneshnikh repozitoriyev](../2026-07-21_11-06-43_MSK_zakrepitj-klonirovaniye-vneshnikh-repozitoriyev/zapros.md)
- [sokhranyonnyij snimok iskhodnogo repozitoriya LinguisticKit](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [sokhranyonnyij snimok vyibrannoj revizii](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:cdd38435b55d72dcbaa573212b2b05e71619881e06cd937fe4ad228afee96ff4 -->
<!-- FUM-MD-RECENCY:END -->
