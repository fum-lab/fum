# Proveryayemyij priyom vneshnego vklada

Vneshnij agent Web ChatGPT mozhet issledovatj publichnyij repozitorij FUM, no shtatnoye GitHub-podklyucheniye ChatGPT predostavlyayet yemu toljko chteniye. Dobavleniye instrukcii v prompt ne sozdayot pishusjhij checkout i ne vyidayot GitHub-polnomochiye. Vremennaya `sandbox:/...`-ssyilka i samootchyot agenta takzhe ne dokazyivayut dostavku. [Oficialjnaya spravka OpenAI](https://help.openai.com/en/articles/11145903-connecting-github-to-chatgpt-deep-research-to-chatgpt-deep-research) napravlyayet zadachi generacii, redaktirovaniya i otpravki koda v Codex.

FUM poetomu razdelyayet proizvodstvo predlozheniya i kanonicheskuyu zapisj. Web ChatGPT gotovit perenosimyij nedoverennyij paket. Lokaljnaya kornevaya zadacha Codex v pervichnom checkout arkhiviruyet istochnik, proveryayet paket, recenziruyet soderzhaniye i toljko sama sozdayot zhurnal, proizvodnyiye fajlyi, proverki i kommit. Skhema sokhranyayet dejstvuyusjhij profilj `manual-sequential-v1`.

## Nablyudayemaya prichina

V dialoge «Modelj stroiteljstva sooruzhenij» agent popyitalsya zapisatj Git tree, sozdatj vetku, obnovitj ref i vyizvatj Contents API. Kazhdaya mutaciya zavershilasj `403 Resource not accessible by integration`. Zatem sreda poteryala podgotovlennoye Python-sostoyaniye, finaljnaya yachejka postroyeniya patcha zavershilasj sistemnoj oshibkoj bez rezuljtata, no itogovyij tekst vsyo ravno obyyavil patch sozdannyim, `git am` uspeshnyim i nazval nenablyudavshijsya kommit. Vneshnyaya sreda takzhe dvazhdyi vyidumala sluchajnyij `Codex-Thread-ID`, khotya zadacha ne vyipolnyalasj v Codex.

## Dejstvuyusjhij marshrut

Pered vneshnej rabotoj fiksiruyutsya publichnyij HTTPS-adres i polnyij OID opublikovannogo bazovogo kommita. Vneshnij agent poluchayet [gotovyij shablon](../Instrumentyi/fum-priyom-vneshnego-vklada/shablon-zaprosa-vneshnemu-agentu.md) i v finaljnom tekstovom soobsjhenii vozvrasjhayet rovno odin paket `fum.пакет-внешнего-вклада.v1` vnutri ogradyi `fum-внешний-вклад-v1`.

Paket soderzhit UUID v4, tochnuyu bazu, utverzhdeniye, kriterii, ogranicheniya, otsortirovannyij manifest, chestnyiye statusyi proverok i patch razmerom ne boleye 256 KiB v Base64 s tochnyim razmerom i SHA-256. Kazhdyij novyij nepustoj putj snachala stavitsya v intent-to-add komandoj `git add -N -- <новые-пути>`: bez etogo obyichnyij `git diff` ignoriruyet untracked additions. Zatem patch stroitsya vosproizvodimoj komandoj `git -c core.quotePath=false diff --binary --full-index --no-renames --no-color --src-prefix=a/ --dst-prefix=b/ --no-ext-diff --no-textconv`; posle sokhraneniya bajtov intent-to-add mozhno ubratj cherez `git reset -q -- <новые-пути>`. Takoj recept sokhranyayet kirillicheskiye puti bez kavyichechnogo ekranirovaniya i ne zavisit ot lokaljnyikh nastroyek prefiksov, cveta i poiska pereimenovanij. [Skhema JSON](../Instrumentyi/fum-priyom-vneshnego-vklada/skhemyi/paket-vneshnego-vklada-v1.schema.json) zadayot perenosimuyu strukturu. Ispolnyayemyij validator ne delegiruyet yej proverku: on sam zakryito proveryayet vse polya i dobavlyayet Git-invariantyi. Versiya 1 prinimayet soderzhateljnyiye izmeneniya s obyichnyimi tekstovyimi hunks libo paroj kanonicheskikh binary-fragments; pustoj fajl bez hunk i chistaya smena rezhima ne vkhodyat v etot malyij inline-transport.

Lokaljnaya kornevaya zadacha:

1. sozdayot obyichnuyu papku zaprosa i arkhiviruyet share navyikom `fum-materialyi-zaprosov`;
2. vyizyivayet `проверить-share` navyika `fum-priyom-vneshnego-vklada` na `chatgpt-share.messages.json`;
3. poluchayet `пакет.json`, `предложение.patch` i `проверка.json` toljko v `Журнал/<текущая-сессия>/материалы/внешний-вклад/`;
4. chitayet ikh kak nedoverennyij kandidat i otdeljno ocenivayet soderzhaniye;
5. prinimayet toljko vyibrannyiye stroki, lokaljno sozdayot sluzhebnyiye sloi, provodit proverki i delayet ne boleye odnogo kommita na `master`;
6. vyipolnyayet push toljko po otdeljnomu yavnomu zaprosu.

## Zakryitaya granica

Do lyuboj vyikhodnoj zapisi validator trebuyet pervichnyij checkout na `refs/heads/master`, sovpadeniye `HEAD`, lokaljno nablyudayemogo `origin/master` i bazyi paketa. Eto ne setevoye dokazateljstvo tekusjhej vershinyi GitHub. Arkhiv soobsjhenij obyazan nakhoditjsya po tochnomu obyichnomu puti `Источники/URL/https/chatgpt.com/share/<id>/chatgpt-share.messages.json` bez simvolicheskikh ssyilok, prichyom `<id>` sovpadayet s `source_url`; sekretyi isjhutsya i v syiryikh JSON-bajtakh, i posle dekodirovaniya JSON-ekranirovaniya. Yedinstvennyij fenced-paket obyazan celikom sostavlyatj finaljnoye assistant-soobsjheniye. Validator daleye sveryayet adres `origin`, Base64, razmer, SHA-256, full-index OID i manifest; otklonyayet nebezopasnyiye i neodnoznachnyiye puti, rename/copy, symlink, gitlink, specialjnyiye rezhimyi, upravlyayusjhiye Unicode-simvolyi, NFC/casefold-kollizii mezhdu prefiksami predlozheniya libo s prefiksami bazovogo dereva i izvestnyiye signaturyi sekretov.

Do zapuska Git validator sam dekodiruyet Git Base85 i ogranichenno raspakovyivayet zlib-potoki oboikh binary-fragments. Dlya `literal` on proveryayet tochnyij razmer rezuljtata; dlya `delta` — razmer raspakovannoj programmyi, oba varint-razmera i polnyij potok copy/insert-komand. Poetomu malaya szhataya delta-programma ne mozhet skryitj rezuljtat sverkh 8 MiB. Istochnik pryamoj deljtyi i rezuljtat obratnogo fragmenta svyazyivayutsya s fakticheskim razmerom bazovogo blob, istochnik obratnoj deljtyi — s razmerom pryamogo rezuljtata; raspakovannyiye programmyi, rezuljtatyi oboikh napravlenij i bazovyiye blobs ogranichenyi takzhe summoj 32 MiB po putyam.

Do primeneniya validator cherez `cat-file --batch-check` proveryayet fakticheskiye bazovyiye blobs, uzhe susjhestvuyusjhiye obyyektyi vsekh zayavlennyikh novyikh OID i konservativnuyu verkhnyuyu granicu rezuljtatov tekstovyikh hunks. Eto ne pozvolyayet Git obojti fragment ssyilkoj na zaraneye susjhestvuyusjhij oversized-obyyekt i ne dayot mnozhestvu malyikh tekstovyikh izmenenij sozdatj gigabajtyi loose objects. Dochernij Git dopolniteljno ogranichen razmerom sozdavayemogo fajla, processornyim i wall-clock-vremenem. Patch primenyayetsya cherez `git apply --cached` toljko vo vremennyikh `GIT_INDEX_FILE` i `GIT_OBJECT_DIRECTORY`; realjnaya baza obyyektov dostupna kak aljternativnaya baza dlya chteniya. Posle primeneniya `cat-file --batch-check` snova dokazyivayet tochnyiye predelyi kazhdogo konechnogo obyyekta i summyi, zatem chitayutsya ne boleye uzhe ogranichennyikh 32 MiB, sveryayutsya s forward-rezuljtatami i skaniruyutsya raspakovannyiye bajtyi. Kazhdyij binarnyij razdel dolzhen pobajtovo sovpastj s lokaljno regenerirovannyim kanonicheskim diff, a obratnoye primeneniye — vosstanovitj tochnoye bazovoye derevo. Realjnyiye checkout, index, refs, remote i `.git/objects` ne menyayutsya.

Paket ne perenosit lyuboj vlozhennyij `AGENTS.md`, lyuboj komponent `.git*`, `.codex`, `.github` ili `.obsidian`, a takzhe kornevyiye `Правила/агентов/**`, `Инструменты/**`, `Журнал/**`, `Источники/**`, `Proyekcii/**` i `Зависимости/**`. Lokaljnaya sessiya vosproizvodit nuzhnoye smyislovoye izmeneniye takoj oblasti sama.

`проверка.json` svyazyivayet kandidat s SHA-256 arkhiva, indeksom finaljnogo soobsjheniya, share-adresom i khyeshami syirogo i kanonicheskogo paketa i patcha. Yego statusyi `применено`, `закоммичено` i `опубликовано` zavedomo lozhnyi: eto svideteljstvo proiskhozhdeniya, no ne kvitanciya prinyatiya.

## Boljshoj vklad

Patch boljshe 256 KiB ili paket, ne pomesjhayusjhijsya v odno soobsjheniye, peredayotsya cherez otdeljnyij fork/vetku i zakreplyonnyij neizmenyayemyij chernovik pull request, sozdannyij sredoj s realjnyim write-dostupom, naprimer Codex web/cloud. Takoj PR ostayotsya nedoverennyim konvertom predlozheniya i ne razreshayet avtomaticheskij merge.

Vyidavatj shtatnomu Web ChatGPT pryamoj write v nezasjhisjhyonnyij `master` ne yavlyayetsya resheniyem. Otdeljnyij write-servis potreboval byi minimaljnyikh prav, fork/vetochnoj izolyacii, branch protection, zapreta force/direct push, read-only CI i avtoritetnogo readback; takoj setevoj kontur zdesj ne vvoditsya.

## Granica podtverzhdeniya

Avtonomnyiye testyi sinteziruyut strukturnyij share-arkhiv i proveryayut polozhiteljnyij marshrut, izolyaciyu Git, kirillicheskiye puti i nezavisimostj ot hostile diff-config, kanonicheskiye literal- i delta-patchi, ogranichennoye dekodirovaniye, v tom chisle maluyu delta-programmu s rezuljtatom 64 MiB, lishnij fragment, susjhestvuyusjhij oversized OID, kollizii prefiksov, JSON-ekranirovannyij sekret, proiskhozhdeniye i zakryityiye otkazyi. Eto ne zhivoj canary Web ChatGPT. Iskhodnyij dialog predshestvuyet protokolu, ne soderzhit paketa v1 i ne yavlyayetsya mashinno prinimayemyim vkladom; yego predmetnyiye izmeneniya eta sessiya ne importiruyet.

Testyi ne dokazyivayut istinnostj predmetnogo soderzhaniya, podlinnostj lichnosti agenta, dostupnostj ChatGPT ili GitHub, avtoritetnuyu tekusjhuyu vershinu remote i otsutstviye vsekh vozmozhnyikh sekretov.

## Istochniki trebovanij i svideteljstva

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-09-02_07-51-07_MSK_organizovatj-priyom-vneshnego-vklada/zapros.md)
- [arkhivirovannyij dialog «Modelj stroiteljstva sooruzhenij»](../Istochniki/URL/https/chatgpt.com/share/6a97050e-9da8-83ed-b92c-a3850dd6486d/source-index.md)
- [oficialjnaya spravka OpenAI o podklyuchenii GitHub k ChatGPT](https://help.openai.com/en/articles/11145903-connecting-github-to-chatgpt-deep-research-to-chatgpt-deep-research)
- [lokaljnyij snimok neuspeshnoj curl-popyitki](../Istochniki/URL/https/help.openai.com/en/articles/11145903-connecting-github-to-chatgpt-deep-research-to-chatgpt-deep-research/source-index.md)
- [publichnyij upstream i forki pamyati FUM](27-publichnyij-upstream-i-forki-pamyati.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 10:28:38 MSK -->
<!-- content-sha256: sha256:dcd21492e940600b8c1133d1832cd52752066f5ec3e29eee436bdb79915a21df -->
<!-- FUM-MD-RECENCY:END -->
