+++
schema_version = 1
card_id = "FUM-STEP-0078"
status = "completed"
+++
# Zafiksirovatj proiskhozhdeniye i ogranichennuyu nezavisimostj vkladov poduzlov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj obsjhuyu pamyatj raspredelyonnogo epizoda proveryayemyim proiskhozhdeniyem kazhdogo vklada i nablyudayemoj ocenkoj yego ogranichennoj nezavisimosti. Prototip dolzhen sokhranyatj ispolnitelya, rolj, rabochij paket, modelj i postavsjhika pri ikh nablyudayemosti, khyeshi zadachi, vkhodov i roditelya, a kazhduyu obsjhuyu modelj, shablon, iskhodnyij material ili proizvodnyij otvet otrazhatj otdeljnoj gruppoj libo rebrom korrelyacii. Odin vklad mozhet odnovremenno vkhoditj v neskoljko peresekayusjhikhsya grupp. Instrumentaljnyiye nablyudeniya dolzhnyi sokhranyatj polnomochiye istochnika i khyeshi vyizova i rezuljtata otdeljno ot pereskazov modeli.

## Pochemu sejchas

Vosstanavlivayemaya obsjhaya pamyatj FUM-STEP-0077 delayet vkladyi dostupnyimi drugim sessiyam, no odinakovo sokhranyonnyiye otvetyi yesjhyo mogut byitj kopiyami ili sledstviyami odnogo obsjhego istochnika. Proiskhozhdeniye i gruppyi korrelyacii nuzhnyi do otdeljnoj proverki, chtobyi posleduyusjhaya priyomka ne prevratila povtoreniye odnoj modeli v lozhnoye nezavisimoye podtverzhdeniye.

## Kriterii zaversheniya

- Kazhdyij vklad khranit identifikatoryi ispolnitelya, roli i rabochego paketa, nablyudayemyiye modelj i postavsjhika, khyeshi zadachi, lokaljnyikh vkhodov, roditeljskogo pokoleniya i rezuljtata.
- Obsjhaya modelj, sistemnyij shablon, iskhodnyij material, roditeljskij rezuljtat ili kopirovaniye otrazhayutsya naborom identifikatorov grupp libo yavnyimi ryobrami korrelyacii; odin vklad mozhet imetj neskoljko takikh svyazej, a svyazannoye imi mnozhestvo ne uvelichivayet chislo nezavisimyikh podtverzhdenij.
- Instrumentaljnoye nablyudeniye sokhranyayet vid polnomochiya istochnika, identichnostj vyizova, khyeshi vkhoda i rezuljtata i vremya nablyudeniya; pereskaz takogo rezuljtata modeljyu ostayotsya proizvodnyim utverzhdeniyem.
- Validator razlichayet nezavisimyij po nablyudayemyim priznakam vklad, korrelirovannyij vklad, kopiyu i vklad s nepodtverzhdyonnyim proiskhozhdeniyem i ne utverzhdayet, chto semanticheskaya nezavisimostj dokazana.
- Avtonomnyiye testyi pokryivayut raznyiye istochniki, odnu modelj i obsjhij shablon, perekryivayusjhiyesya gruppyi po modeli i istochniku, pryamuyu kopiyu, pereskaz instrumentaljnogo rezuljtata i nepolnoye proiskhozhdeniye.
- Kanonicheskaya serializaciya i vosstanovleniye pokolenij sokhranyayut proiskhozhdeniye i gruppyi korrelyacii bez poterj.

## Rezuljtat

Obsjhaya pamyatj perevedena na skhemu i reducer versii 2. Kazhdyij vklad kanonicheski sokhranyayet ispolnitelya, rolj, rabochij paket, nablyudayemyiye modelj i postavsjhika, khyeshi zadachi, vkhodov, roditelya i rezuljtata. Ispolnitelj svyazan s avtorom sobyitiya, a rolj, paket, vkhodyi, rezuljtat i instrumentaljnyiye nablyudeniya sveryayutsya s pasportom i vstroyennyimi artefaktami.

Peresekayusjhiyesya gruppyi, napravlennyiye ryobra, obsjhij ispolnitelj i tochnyij povtor instrumentaljnogo vyizova obyyedinyayut vkladyi v odin ogranichennyij komponent podtverzhdeniya. Validator razlichayet nezavisimyij po nablyudayemyim priznakam vklad, korrelirovannyij vklad, kopiyu i nepodtverzhdyonnoye proiskhozhdeniye; kanonicheskoye pole o semanticheskoj nezavisimosti vsegda lozhno. Desyatj testov proiskhozhdeniya i vosemnadcatj integracionnyikh testov obsjhej pamyati zakreplyayut kanonicheskoye vosstanovleniye, chetyire statusa i fail-closed-granicyi. Eto strukturnaya, a ne kriptograficheskaya attestaciya i ne dokazateljstvo semanticheskoj nezavisimosti.

## Istochniki

- [iskhodnyij zapros 2026-08-02 01:12:32 MSK — Zafiksirovatj proiskhozhdeniye i ogranichennuyu nezavisimostj vkladov poduzlov](../../Zhurnal/2026-08-02_01-12-32_MSK_zafiksirovatj-proiskhozhdeniye-i-ogranichennuyu-nezavisimostj-vkladov-poduzlov/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [proveryayemyij mnogoagentnyij kontur FUM](../../Glossarij/proveryayemyij-mnogoagentnyij-kontur-FUM.md)
- [arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [FUM-STEP-0077 — vosstanavlivayemaya obsjhaya pamyatj raspredelyonnogo epizoda](✅-FUM-STEP-0077-dobavitj-vosstanavlivayemuyu-obsjhuyu-pamyatj-raspredelyonnogo-epizoda.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ca1ed6f31428b980c2f012d45cdd893850bc7c4343ba600547e0003aec866d81 -->
<!-- FUM-MD-RECENCY:END -->
