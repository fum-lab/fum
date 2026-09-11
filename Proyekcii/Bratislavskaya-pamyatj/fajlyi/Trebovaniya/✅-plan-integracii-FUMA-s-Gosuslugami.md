# Plan integracii FUMA s Gosuslugami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0070 -->

Podgotovitj proveryayemyij plan integracii FUM/FUMA s infrastrukturoj Gosuslug dlya odnogo konkretnogo poljzovateljskogo scenariya.

Plan razlichayet vkhod cherez YESIA i polucheniye razreshyonnyikh atributov, vzaimodejstviye s konkretnyim servisom YEPGU i obmen opredelyonnyimi vidami svedenij cherez SMYEV. Dlya vyibrannogo scenariya ustanavlivayutsya sistema podklyucheniya, operator informacionnoj sistemyi, usloviya uchastiya, neobkhodimyiye dannyiye i polnomochiya; yedinyij universaljnyij publichnyij API ne predpolagayetsya.

## Kriterii proverki

- Vyibran i obosnovan odin scenarij s ponyatnyimi uchastnikami, dejstviyem i ozhidayemyim rezuljtatom; on yavlyayetsya predlozheniyem pervogo etapa, a ne razresheniyem dejstvuyusjhego podklyucheniya.
- Zapolnena matrica «scenarij → sistema → operator IS → dopusk → dannyiye i polnomochiya → testovaya sreda → priyomka».
- Dlya susjhestvennyikh uslovij ukazanyi oficialjnyiye dokumentyi, dostupnyiye versii i granica podtverzhdeniya. Nedostupnoye soderzhaniye i istoricheskiye versii otdelenyi ot podtverzhdyonnyikh tekusjhikh uslovij.
- Ukazanyi predpolagayemyij operator, neobkhodimyij status zayavitelya i osnovaniya uchastiya. Neizvestnyiye operator, usluga, soglasiye ili dopusk sokhranenyi kak konkretnyiye voprosyi.
- Podgotovlen konechnyij plan lokaljnogo adaptera ili simulyatora na sinteticheskikh dannyikh, zatem proverki v oficialjnoj testovoj srede pri podtverzhdyonnom dostupe.
- Kriterii priyomki razlichayut praviljnostj lokaljnoj modeli, podtverzhdeniye oficialjnogo protokola i pravo na ekspluatacionnoye podklyucheniye.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Status i granicyi

Status trebovaniya — `✅`.

Prinyato planirovaniye integracii. Pervyij rezuljtat ogranichen analiticheskim dokumentom i postanovkoj daljnejshikh rabot. Realizaciya, registraciya podklyucheniya, polucheniye uchyotnyikh dannyikh i rabota s realjnyimi personaljnyimi dannyimi ne vkhodyat v etot rezuljtat. NKO i CC0 sami po sebe ne schitayutsya dokazateljstvom oficialjnogo dopuska.

## Podgotovlennyij rezuljtat

[Analiticheskij plan pervogo scenariya](../Planirovaniye/integracii/Gosuslugi.md) podgotovlen 11.09.2026; [usloviya podklyucheniya](../Voprosyi/2026-09-11_16-18-37_MSK_usloviya-podklyucheniya-FUMA-k-YESIA.md) ostayutsya otkryityimi. Plan predmetno prinyat koordinatorom i zadachej priyoma po kriteriyam analiticheskogo rezuljtata. Status otnositsya k podgotovke plana; realizaciya i oficialjnyij dopusk podklyucheniya ne zayavlenyi.

## Podtverzhdeniye

[Predmetnaya priyomka](../Zhurnal/2026-09-11_17-00-29_MSK_utochnitj-svideteljstvo-reglamenta-YESIA/zapros.md) svyazyivayet vosemj kriteriyev s tochnyim analiticheskim rezuljtatom. [Otchyot itogovogo dopuska](../Zhurnal/2026-09-11_18-23-55_MSK_zavershitj-dopusk-plana-Gosuslug/otchyot.md) sokhranyayet mashinnyij iskhod proverki snimka.

## Istochniki trebovanij

- [Itogovyij dopusk analiticheskogo plana](../Zhurnal/2026-09-11_18-23-55_MSK_zavershitj-dopusk-plana-Gosuslug/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_15-48-40_MSK_prinyatj-planirovaniye-Gosuslug/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 18:28:31 MSK -->
<!-- content-sha256: sha256:074e3fe83c9ddebb58949405b12a5d656533d22cc6071aa64948268dab335769 -->
<!-- FUM-MD-RECENCY:END -->
