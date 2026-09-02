# Otchyot 2026-07-22 12:35:05 MSK - Provesti audit absolyutnyikh putej

Audit snimka `44b9ea1a978f1cddf7b9ce3e019aefc6a6a57e2d` obnaruzhil odin P1, tri P2 i odin P3. Kanonicheskaya produktovaya dokumentaciya i ispolnyayemyiye first-party iskhodniki ne soderzhat personaljnyikh hardcode-literalov, odnako repozitorij v celom neljzya schitatj svobodnyim ot mashinno-zavisimyikh putej.

## Osnovnyiye rezuljtatyi

- Tri zhyostkikh ssyilki na `/Users/fum/Projects/FUM` v lokaljnom navyike glossariya obrazuyut dejstvuyusjhij P1: drugoj checkout mozhet chitatj ili izmenyatj nevernoye mesto.
- Reyestr instrumentov publikuyet korenj checkout i putj vnutri domashnego kataloga k `lms`; eto dva P2-vkhozhdeniya, odno iz kotoryikh pryamo protivorechit zayavlennoj na toj zhe stroke publikacionnoj granice.
- Fizicheskij Swift-prototip namerenno ispoljzuyet `#filePath`; tekusjhij Debug-binarnik dejstviteljno soderzhit putj sborochnoj mashinyi i posle perenosa ne nakhodit repozitorij. Eto P2-defekt perenosimosti artefakta, khotya sam putj ne serializuyetsya v dannyiye progona.
- Avtomaticheskiye proverki ne obespechivayut obsjhuyu fail-closed-granicu: smoke-check ne skaniruyet soderzhimoye, proverka Markdown propuskayet susjhestvuyusjhuyu absolyutnuyu ssyilku vne repozitoriya, generatoryi prinimayut absolyutnyiye vkhodnyiye puti, a dispetcher determinirovanno proveryayet toljko `project_path`, no ne `title`, `task` i `criteria`. Tekusjhiye vkhodyi bezopasnyi, poetomu eto latentnyij P2.
- Absolyutnyiye plejskholderyi vrode `/path/to/config.json` ostayutsya P3: eto ne utechka, no oni protivorechat sosednemu ukazaniyu zadavatj puti otnositeljno kornya i uslozhnyayut budusjhuyu mashinnuyu politiku.

## Granica klassifikacii

Istoricheskiye iskhodnyiye zaprosyi ne perepisyivalisj: v nikh najdeno 149 nastoyasjhikh absolyutnyikh putej, vklyuchaya 42 `/Users/...`, no doslovnoye proiskhozhdeniye vazhneye normalizacii zadnim chislom. Arkhivyi `Источники/`, sistemnyiye puti `/bin`, `/usr`, `/opt` i `/Applications`, testovyiye `/repo` i `/tmp`, URI-fiksturyi, Gitignore-yakorj i vneshnij heartbeat-korenj klassificirovanyi otdeljno i ne vyidanyi za defektyi.

V tryokh ignoriruyemyikh first-party `.build` korenj checkout prisutstvuyet v 2476 fajlakh; lokaljnyij `.build` submodule dobavlyayet yesjhyo 671. Eto ozhidayemyiye sborochnyiye ostatki, no ikh neljzya prinuditeljno publikovatj. Zakreplyonnyiye 101 iskhodnyij fajl samogo submodule proverenyi otdeljno i ne soderzhat otslezhivayemyikh mashinno-lokaljnyikh literalov.

## Avtomatizaciya prodolzheniya

Soderzhateljnyij poisk v etom sreze byil ruchnyim, a susjhestvuyusjhaya avtomatizaciya revjyu obespechivala toljko strukturu i sokhraneniye rezuljtata. Tipizirovannyij skaner s TDD zatem realizovan v zavershyonnoj [FUM-STEP-0070](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0070-ustranitj-mashinno-lokaljnyiye-absolyutnyiye-puti-i-dobavitj-ikh-avtomaticheskuyu-proverku.md).

## Proverki

- Proverenyi 1063 otslezhivayemyikh puti, 974 tekstovyikh i konfiguracionnyikh artefakta, 108 first-party iskhodnikov, konfiguracij i fikstur i 101 fajl submodule.
- Proverenyi POSIX user-home i sistemnyiye korni, Windows drive, UNC, `file://`, `~/`, peremennyiye okruzheniya, absolyutnyiye plejskholderyi, Markdown- i HTML-root-ssyilki, simvolicheskiye ssyilki i Git-konfiguraciya.
- Tri nezavisimyikh read-only-audita teksta, koda i mekhanizmov kontrolya vruchnuyu svedenyi i pereproverenyi po strokam.
- Polnyij rezuljtat, komandyi, isklyucheniya i ostatochnyiye riski sokhranenyi v [revjyu](materialyi/revjyu/2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.md).

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [sokhranyonnyij audit](materialyi/revjyu/2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.md)
- [predyidusjhaya granica dochernikh promptov](../2026-07-22_10-31-30_MSK_zapretitj-absolyutnyiye-puti-v-promptakh-avtozadach/zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2fdf567e61688790e19892b507595c76a7d3e6866a90ce81a20075db7a8a804b -->
<!-- FUM-MD-RECENCY:END -->
