+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0152"
"статус" = "устранена"
+++
# Zhyostkij sistemnyij putj nulevogo ustrojstva

## Nablyudayemyij sboj

Predvariteljnyij skan finansovogo obyyedineniya otklonil zhyostkij sistemnyij putj v nastrojke Git hooks realizacii mediapaketa i yeyo testovogo helper. Tochnyij vyizov dolzhen poluchatj sistemnoye znacheniye sredyi vyipolneniya.

## Granica povtoreniya

Toljko podgotovka core.hooksPath lokaljnogo Git-vyizova mediapaketa. Otricateljnyij absolyutnyij putj sinteticheskogo testa otdeljno deklarirovan i ne schitayetsya etim defektom.

## Proyavleniya

### FUM-SBOJ-0152/PROYAVLENIYE-0001

[Svideteljstvo](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/materialyi/vosstanovleniye-putej.json) sokhranyayet otkaz skanera, oshibku pervoj testovoj zagotovki, posleduyusjhij soderzhateljnyij RED i GREEN vsekh 40 regressij. Pervonachaljnyij SyntaxError testa ne podmenyayet RED povedeniya.

## Ozhidaniye i klassifikaciya

Sistemnoye nulevoye ustrojstvo beryotsya iz os.devnull; zhyostkij POSIX-literal ne yavlyayetsya perenosimyim kontraktom. Skaner praviljno otklonil iskhodnik, yego kod ne oslablyalsya.

## Mekhanizm i sistemnoye ustraneniye

Ispolnyayemyij argument i testovyij helper ispoljzuyut os.devnull. Regressiya podstavlyayet otlichimoye znacheniye i proveryayet fakticheskiye argv i GIT_CONFIG_GLOBAL, poetomu vozvrat prezhnego literala snova otklonyayetsya. Ostaljnyiye ogranicheniya Git sokhranenyi.

## Svyazannyiye shagi

Ogranichennaya pravka vyipolnena v [priyomochnom etape](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/zapros.md); otdeljnogo nezavershyonnogo shaga u etogo ispravleniya net. Polnaya priyomka obyyedinyonnogo snimka ostayotsya otdeljnoj granicej.

## Kriterii zakryitiya

Regressiya padayet na prezhnem literale, prokhodit na sistemnom znachenii; ostaljnyiye testyi i publikacionnyij skan uspeshnyi, vyikhod profilya pobajtno prezhnij.

## Podtverzhdeniye ustraneniya

Soderzhateljnyij RED i GREEN 40/40 sokhranenyi v svideteljstve; povtornyij skan imeyet kod 0. Mediana profilya 54,075 ms, nizhe obyyavlennogo poroga 500 ms. Obsjhaya perenosimostj vsekh platform i uskoreniye ne zayavlyayutsya.

## Istochniki

- [Zapros](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/zapros.md) i [otchyot](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-18 00:15:27 MSK -->
<!-- content-sha256: sha256:9b15a96b0b4b7f546c5e14ac86a975b491c0da350c6574605338205fbca2af17 -->
<!-- FUM-MD-RECENCY:END -->
