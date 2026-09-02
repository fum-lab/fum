# FUM-MAP-SESSION-01: Rabochaya sessiya chelovek - Codex - repozitorij

Eta kartochka fiksiruyet rabochuyu sessiyu kak malyij dokumentacionnyij prototip cikla FUM. V nej chelovek zadayot vkhodnoj signal, Codex dejstvuyet kak agent rabochej sredyi, repozitorij khranit pamyatj, a proverki i commit prevrasjhayut rezuljtat v nasleduyemoye sostoyaniye.

## Kartochka

- Identifikator: `FUM-MAP-SESSION-01`.
- Obyyekt sopostavleniya: rabochaya sessiya chelovek - Codex - repozitorij.
- Sloj: dokumentacionnyij prototip.
- Nablyudatelj: poljzovatelj, agent rabochej sessii, budusjhij proveryayusjhij agent i chitatelj istorii [pamyati FUM](../../Glossarij/pamyatj-FUM.md).
- Sootvetstviye obsjhej skheme: [iskhodnyij zapros](../../Glossarij/iskhodnyij-zapros.md) zadayot vozdejstviye, proizvodnaya dokumentaciya zakreplyayet obnovlyonnuyu modelj, zhurnal dayot chelovekochitayemuyu trassu, proverki vyipolnyayut otbor, commit delayet rezuljtat nasleduyemyim.
- Sokhranyayemyiye invariantyi: trebovaniye ne rastvoryayetsya v perepiske, izmeneniye svyazano s istochnikom, proverki otdelenyi ot rassuzhdeniya, rezuljtat vozvrasjhayetsya v obsjhuyu pamyatj.
- Poteri nablyudayemosti: sessiya ne khranit vse promezhutochnyiye sostoyaniya modeli, mozhet szhimatj kontekst v zhurnale i zavisit ot dostupnosti instrumentov sredyi.
- Perekhod k istochniku: pravila rabochej sessii zakreplenyi v [AGENTS.md](../../AGENTS.md), a konkretnyiye sessii raskryivayutsya cherez [papki zaprosov](../../Glossarij/papka-zaprosa.md) v `Журнал/` i Git-istoriyu.
- Granicyi analogii: kartochka primenima k sessiyam, vliyayusjhim na proyekt; byitovyiye otvetyi bez izmeneniya pamyati ne trebuyut polnogo cikla.
- Proverka: lokaljnaya avtomatizaciya `fum-svyaznostj-rabochej-sessii` dolzhna videtj navigaciyu zaprosa, zhurnal, razdel ispoljzovannyikh instrumentov, ssyilki na zatronutyiye fajlyi i chistoye sootvetstviye Git-sostoyaniyu.
- Status uverennosti: rabochaya praktika zakreplena pravilami repozitoriya; nuzhen budusjhij mashinno proveryayemyij pasport kartochki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:33:38 MSK](../../Zhurnal/2026-07-02_11-33-38_MSK/zapros.md)

## Opornyiye dokumentyi

- [AGENTS.md](../../AGENTS.md)
- [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md)
- [Publichnyij upstream i forki pamyati FUM](../27-publichnyij-upstream-i-forki-pamyati.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3db1237c0d56995e844182cf470c6307a697c12418a31a22d31fa4319951e9fb -->
<!-- FUM-MD-RECENCY:END -->
