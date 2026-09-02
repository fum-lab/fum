+++
schema_version = 1
card_id = "FUM-STEP-0146"
status = "completed"
+++

# Svyazatj sleduyusjhiye shagi s dorozhnoj kartoj

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet zavershyonnuyu rabotu po prevrasjheniyu dorozhnoj kartyi v proveryayemoye predstavleniye planovoj ocheredi.

## Zadacha

Svyazatj [sleduyusjhiye shagi](../../Glossarij/sleduyusjhij-shag-vetki.md) s [dorozhnoj kartoj](../dorozhnaya-karta.md), chtobyi dlya kazhdoj stadii i kazhdogo etapa byili vidnyi otnosyasjhiyesya k nim kartochki, ikh pribliziteljnaya ocheredj libo gorizont ispolneniya, a izmeneniye prioritetov i pereuporyadochivaniye planov obyazateljno otrazhalisj v toj zhe karte.

## Rezuljtat

Dorozhnaya karta poluchila proveryayemuyu proyekciyu 12 prioritetnyikh prodolzhenij `master` s ustojchivyimi pokoleniyami, kategoriyami ogranichenij, zavisimostyami, stadiyami, gorizontami i pribliziteljnyimi diapazonami. Proyekciya ne pretenduyet na polnyij katalog aktivnyikh kartochek. Otdeljnaya tablica polnostjyu pokryivayet obe stadii i gorizontyi `0`–`8`, a otsutstviye naznacheniya fiksiruyet tochnyim markerom. Reyestr planirovaniya skhemyi `9` sveryayet proyekciyu s mashinochitayemoj planovoj vyiborkoj i aktualjnyimi kartochkami; avtonomnyiye TDD-fiksturyi obnaruzhivayut propusk kontura ili kandidata, nesusjhestvuyusjhuyu stadiyu, bituyu libo snyatuyu kartochku, nestrogiye metadannyiye, pustoj diapazon i nesinkhronnuyu perestanovku zapisej libo smenu pokoleniya, rezhima ili zavisimostej. Pri `manual-sequential-v1` karta ne zapuskayet selector: pribliziteljnyij chastichnyij poryadok pomogayet poljzovatelyu vyibratj otdeljnyij sleduyusjhij zapros i ne obesjhayet kalendarnyikh dat.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-13_13-14-24_MSK_svyazatj-sleduyusjhiye-shagi-s-dorozhnoj-kartoj/zapros.md)
- [otchyot o paralleljnom vyipolnenii shaga](../../Zhurnal/2026-08-14_18-24-50_MSK_zapustitj-daljnij-paralleljnyij-shag/otchyot.md)
- [dorozhnaya karta](../dorozhnaya-karta.md)
- [stadii proyekta](../stadii/README.md)
- [indeks kartochek shagov](README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 09:23:52 MSK -->
<!-- content-sha256: sha256:206c3fbbf1d563256b0678264d940ae9d8eef489159e4feeeb75ab69fa2fc746 -->
<!-- FUM-MD-RECENCY:END -->
