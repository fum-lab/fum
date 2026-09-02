# Kandidatnyij kommit FUM

Kandidatnyij kommit FUM — neizmenyayemyij Git-obyyekt, kotoryij [pishusjhij poduzel FUM](pishusjhij-poduzel-FUM.md) sozdal v izolirovannoj vetke kak proveryayemyij vklad. On svyazan s tochnyimi identichnostjyu repozitoriya, `base_oid`, polnyim OID, `result_ref`, istochnikami, dopustimoj oblastjyu, proverkami, dostupom i statusom peredachi.

Kandidatnyij kommit sokhranyayetsya pod dolgovechnyim `result_ref` nezavisimo ot togo, prinyat li on v celevuyu vetku. Sokhraneniye delayet vosstanavlivayemyimi kak poleznyiye, tak i otklonyonnyiye variantyi, no ne vyidayot ikh za proverennuyu obsjhuyu [pamyatj FUM](pamyatj-FUM.md). Detached `HEAD`, reflog i nezakreplyonnyij obyyekt ne schitayutsya dolgovechnyim khraneniyem.

Perepisyivaniye rabochej vetki cherez rebase ili force-push ne zamenyayet sokhraneniya. Yesli integraciya sozdala drugoj OID, reyestr proiskhozhdeniya sokhranyayet yavnuyu svyazj mezhdu iskhodnyim i prinyatyim kommitami.

## Svyazannyiye dokumentyi

- [Paralleljnaya rabota i sliyaniye](../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [Peredavayemyij rezuljtat FUM](peredavayemyij-rezuljtat-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:db3fdd7c4010e5a868656b6333bbe481f229152d811ebd9ce7b0727a4f18e5cd -->
<!-- FUM-MD-RECENCY:END -->
