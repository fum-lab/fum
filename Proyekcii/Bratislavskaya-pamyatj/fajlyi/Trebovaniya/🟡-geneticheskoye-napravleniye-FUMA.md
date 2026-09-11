# Geneticheskoye napravleniye FUMA

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0058 -->

FUMA dolzhna podderzhivatj vosproizvodimyij analiz geneticheskikh dannyikh i modelej nasledovaniya, sokhranyaya proiskhozhdeniye dannyikh, sistemu oboznachenij, predposyilki modeli, neopredelyonnostj i granicyi biologicheskoj interpretacii.

Geneticheskij analiz yavlyayetsya predmetnyim issledovaniyem. Arkhitekturnyiye analogii nasledovaniya i evolyucii FUM sami po sebe ne podtverzhdayut rabotu s geneticheskimi dannyimi ili praviljnostj biologicheskogo vyivoda.

V geneticheskom napravlenii predusmotreno vyichisliteljnoye perekodirovaniye DNK v predstavleniye belkovoj posledovateljnosti s primeneniyem strukturiruyusjhikh operatorov FUM. Tochnoye znacheniye vkhoda i rezuljtata, etapyi preobrazovaniya i oblastj modeli opredelyayutsya do realizacii. Podgotovlennyij plan i vyipolnennoye preobrazovaniye razlichayutsya: zaversheniye planovogo shaga ne schitayetsya realizaciyej. Pervoye vosproizvedeniye nasledovaniya sinteticheskogo lokusa po FUM-STEP-0192 sokhranyayet samostoyateljnyiye kriterii.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Dlya issledovaniya opredelenyi obyyekt, yedinica nablyudeniya, proiskhozhdeniye dannyikh i razreshyonnyiye sposobyi ikh ispoljzovaniya.
- Allelj, genotip, izmerennyij priznak i vyivod modeli razlichayutsya. Svyazj mezhdu nimi trebuyet otdeljnogo osnovaniya.
- Preobrazovaniya dannyikh i metodyi analiza vosproizvodimyi. Propuski, oshibki, neodnoznachnyiye oboznacheniya i ogranicheniya vkhodnogo nabora yavno otrazhenyi v rezuljtate.
- Proverka ispoljzuyet zaraneye zadannyij etalon, nezavisimyij sposob raschyota ili podkhodyasjhij kontrolj, pozvolyayusjhij obnaruzhitj nevernyij vyivod.
- Rezuljtat sinteticheskoj modeli ne pripisyivayetsya realjnoj populyacii, otdeljnomu cheloveku ili organizmu. Oblastj biologicheskogo vyivoda opredelyayetsya svideteljstvom.
- Sobstvennyiye raschyotyi, otkryityiye fiksturyi i instrukcii nakhodyatsya v FUM. Dlya vyichisliteljnyikh realizacij vyipolnyayutsya primenimyiye testyi, profilj i resheniye ob optimizacii.
- Chuvstviteljnyiye geneticheskiye svedeniya ne trebuyutsya dlya pervogo scenariya. Rabota s realjnyimi obrazcami, medicinskaya interpretaciya i izmeneniye organizmov imeyut otdeljnyiye postanovku i usloviya proverki.

- Dlya perekodirovaniya DNK v belkovoye predstavleniye primenyayetsya soglasovannaya oblastj strukturiruyusjhikh operatorov. Budusjhaya realizaciya imeyet proveryayemyiye vkhod, vyikhod, nezavisimyij etalon, povedeniye na nekorrektnom i neodnoznachnom vkhode, vosproizvodimyiye RED/GREEN i profilj. Planovyij dokument sam po sebe etot kriterij ne vyipolnyayet.

## Status i granicyi

Status — `🟡`: prinyato i zaplanirovano. [Pervyij shag](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0192-vosproizvesti-modelj-nasledovaniya-sinteticheskogo-lokusa.md) dolzhen zavershitjsya vyipolnennyim vyichisliteljnyim eksperimentom s sinteticheskimi dannyimi: pryamyim raschyotom raspredelenij, modeljnyimi povtorami i otchyotom ob ikh sravnenii. Pasport yavlyayetsya predvariteljnoj chastjyu togo zhe shaga. Na tekusjhem etape sokhranyayetsya plan: vyichisliteljnaya realizaciya i eksperiment yesjhyo ne vyipolnenyi, biologicheskiye rezuljtatyi ne podtverzhdenyi.

Nachaljnyij kandidat — nasledovaniye odnogo sinteticheskogo lokusa s dvumya uslovnyimi allelyami. On prednaznachen dlya proverki vosproizvodimosti i razlicheniya modeli s yeyo interpretaciyej; vsyo geneticheskoye napravleniye etim primerom ne ogranichivayetsya. Obsjhiye usloviya ostayutsya svyazanyi s [voprosom ob issledovateljskoj avtonomii](../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md).

Podgotovka perekodirovaniya DNK v belki vyidelena v [otdeljnyij planovyij shag](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0210-sostavitj-plan-perekodirovaniya-DNK-v-belki.md). Posle yego zaversheniya vyichisliteljnaya realizaciya ostayotsya nezavershyonnoj do svoikh proveryayemyikh svideteljstv; sokhranyonnyij opyit FUM-STEP-0192 yeyo ne zamenyayet.

## Istochniki trebovanij

- [Komanda o primenenii strukturiruyusjhikh operatorov k perekodirovaniyu DNK v belki](../Zhurnal/2026-09-11_09-20-07_MSK_zavershitj-priyom-primera-DNK/zapros.md).


- [Iskhodnaya komanda o genetike i soderzhateljnyij otvet](../Zhurnal/2026-09-11_01-41-15_MSK_zaplanirovatj-geneticheskoye-napravleniye/zapros.md).
- [Nauchnyiye issledovaniya FUM i otkryitiya](../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md).
- [Napravleniye issledovanij i otkryitij](../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md).
- [Shablon kartochki eksperimenta](../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:59:08 MSK -->
<!-- content-sha256: sha256:c89536bf40429797e4c31117ae8f2324b81d0061d29f3997dd333bc2aa1a71bf -->
<!-- FUM-MD-RECENCY:END -->
