# Otchyot 2026-07-24 16:26:31 MSK - Sozdatj obobsjhyonnyij instrument pereimenovaniya fajla

Pamyatj FUM poluchila obsjhij lokaljnyij instrument dlya pereimenovaniya odnogo otslezhivayemogo fajla vmeste s dokazuyemyim obnovleniyem podderzhannyikh Markdown-ssyilok. Operaciya razdelena na read-only-plan i primeneniye, poetomu chelovek ili agent snachala vidit polnyij nabor izmenenij, a zatem vyipolnyayet tot zhe preflight pered zapisjyu.

## Razresheniye i pereschyot ssyilok

Scenarij razreshayet lokaljnuyu celj kazhdoj podderzhannoj ssyilki otnositeljno soderzhasjhego yeyo Markdown-fajla. Blagodarya etomu on izmenyayet toljko ssyilki na fakticheski perenosimyij fajl, sokhranyayet pokhozhiye imena i prozu, uchityivayet percent-encoding, query, fragment, zagolovki i reference-style-opredeleniya. Yesli perenositsya sam Markdown-dokument, yego iskhodyasjhiye otnositeljnyiye ssyilki pereschityivayutsya ot novogo kataloga, vklyuchaya yavnyiye ssyilki na sebya.

## Bezopasnostj primeneniya

Do zapisi proveryayutsya Git-identichnostj i chistota istochnika, normalizovannyiye puti, otsutstviye simvolicheskikh komponentov, perenosimyikh kollizij i susjhestvuyusjhego naznacheniya, chitayemostj proyektnyikh Markdown-fajlov, podderzhannostj znachimyikh ssyilok i susjhestvovaniye iskhodyasjhikh celej. Syiryiye materialyi `Источники/` i doslovnyiye bloki zaprosov ostayutsya neizmenyayemyimi; neobkhodimostj ispravitj zhivuyu ssyilku v nikh blokiruyet operaciyu. Dlya kartochek shagov obsjhaya komanda vyidayot tochnoye napravleniye k specializirovannomu `rename-step-card.py`.

Primeneniye ispoljzuyet `git mv`, sokhranyayet bajtyi perevodov strok i fajlovyij rezhim, a podgotovlennyiye sosedniye vremennyiye fajlyi ustanavlivayet atomarnoj zamenoj. Pri perekhvatyivayemoj oshibke posle nachala zapisi ono vosstanavlivayet fajlyi i Git-pereimenovaniye; chistota istochnika pozvolyayet vernutj iskhodnyij indeks, a sboj samogo otkata yavno trebuyet ruchnogo vosstanovleniya iz sokhranyonnoj rezervnoj kopii.

## Integraciya v pamyatj

Pravilo ispoljzovaniya avtomatizacii zakrepleno v [AGENTS.md](../../AGENTS.md), a komandyi `plan`, `apply` i avtonomnyikh testov — v [indekse instrumentov](../../Instrumentyi/README.md). Kanonicheskoye russkoye imya, transliteraciya i slug zaregistrirovanyi bez legacy-isklyuchenij. Gotovaya kartochka sleduyusjhego produktovogo shaga vetki ne ispolnyalasj i ne izmenyalasj etoj sluzhebnoj sessiyej.

## Proverki

Novaya avtomatizaciya proshla `17` avtonomnyikh testov. Matrica okhvatyivayet read-only-plan, odno- i mnogostrochnyiye inline- i reference-adresa, izobrazheniya, perenos iskhodyasjhikh ssyilok, non-Markdown-istochnik, CRLF i rezhim fajla, zasjhisjhyonnyiye zonyi, kontejnernyiye bloki koda, wiki-kandidatyi, perenosimyiye kollizii, symlink-celi, bukvaljnyiye pathspec, ochisjheniye `GIT_*`, exact-index-fence, konkurentnoye izmeneniye inventarya i polnyij otkat.

Realjnyij `plan` po tekusjhej pamyati nashyol dve vkhodyasjhiye ssyilki na vyibrannyij proverochnyij Python-fajl i ne izmenil dajdzhest `git status`. Reyestr podtverdil `22` imeni avtomatizacij; vetochnyij rabochij nabor validen dlya `74` kartochek i sokhranil `FUM-STEP-0074` yedinstvennyim `ready`. Polnyij smoke-check uspeshno zavershil vse `58` etapov za `205,40 с`, vklyuchaya recency Markdown, graf Obsidian, sessionnuyu svyaznostj i proverku mashinno-lokaljnyikh putej.

## Profilj vremeni vyipolneniya

| Stadiya                            |       Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                                                         |
| --------------------------------- | -----------------: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i dopusk FIFO         | 5 ch 03 min 8,209 s | Ot atomarnoj registracii bileta `seq=42` do sostoyaniya `admitted`; raznostj sokhranyonnyikh UTC-metok `08:21:10,332` i `13:24:18,541`.                                                  |
| Realizaciya i smyislovaya integraciya |        ne izmereno | Rabota prodolzhena posle vosstanovleniya svyazi v tom zhe FIFO-pokolenii; tochnaya aktivnaya dliteljnostj nedostupnogo intervala ne nablyudalasj, a paralleljnyiye intervalyi ne summiruyutsya. |
| Posledniye celevyiye proverki        |           20,262 s | Stenovoye vremya svyazannogo progona `17` testov, realjnogo read-only-plana, reyestra imyon, vetochnogo validator i `git diff --check`; vlozhennyiye komandyi otdeljno ne summiruyutsya.       |
| Polnyij smoke-check                |           205,40 s | Stenovoye vremya predfinaljnogo polnogo progona iz `58` etapov s zaprosom, soobsjheniyem kommita i kornevyim `Codex-Thread-ID`; vlozhennyiye komandyi otdeljno ne summiruyutsya.               |

Granica profilya: ot atomarnoj registracii FIFO-bileta do finaljnoj peredachi ocheredi; ozhidaniye vklyucheno i otdeleno ot soderzhateljnoj rabotyi, paralleljnyiye intervalyi ne skladyivayutsya, a nedostupnoye vo vremya razryiva svyazi aktivnoye vremya ne ocenivayetsya zadnim chislom.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [kontrakt pereimenovaniya fajla s obnovleniyem ssyilok](../../Instrumentyi/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a79ed1dc8015b845ab0b6ff1ee062e7970af741bbbb9e440d1cff18502c001a7 -->
<!-- FUM-MD-RECENCY:END -->
