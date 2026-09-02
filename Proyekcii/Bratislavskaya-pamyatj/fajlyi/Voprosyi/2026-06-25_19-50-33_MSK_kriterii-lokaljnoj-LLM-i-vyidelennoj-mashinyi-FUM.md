# [Otkryityij vopros](../Glossarij/otkryityij-vopros.md): kriterii lokaljnoj LLM i vyidelennoj mashinyi [FUM](../Glossarij/FUM.md)

## Neodnoznachnostj

[Iskhodnyij zapros](../Glossarij/iskhodnyij-zapros.md) fiksiruyet vazhnuyu celevuyu vekhu: lokaljnyij agent [FUM](../Glossarij/FUM.md) na vyidelennoj mashine s lokaljno zapuskayemoj topovoj LLM, kotoraya mozhet rabotatj na etoj mashine. V kachestve predvariteljnogo apparatnogo obraza nazvan Mac Studio s pamyatjyu klassa 512 GB.

Pri etom poka ne opredeleno, chto imenno schitayetsya "topovoj" lokaljnoj LLM dlya zadach [FUM](../Glossarij/FUM.md): obsjhij benchmark-rejting, kachestvo programmirovaniya, sposobnostj rabotatj s dlinnyim kontekstom, instrumentaljnaya disciplina, skorostj lokaljnogo vyivoda, licenzionnaya sovmestimostj, privatnostj, stoimostj ekspluatacii ili sochetaniye etikh kriteriyev.

Takzhe ne opredeleno, kak vyibiratj vyidelennuyu mashinu: dostatochno li maksimaljnoj obyyedinyonnoj pamyati, kakiye trebovaniya predyyavlyayutsya k uskoritelyam, nakopitelyam, otkazoustojchivosti, energopotrebleniyu, obnovlyayemosti modeli, rezhimu rezervnogo kopirovaniya i granicam dostupa k lichnoj [pamyati FUM](../Glossarij/pamyatj-FUM.md).

Otdeljnaya, no svyazannaya razvilka zafiksirovana v voprose o [gipersetevom prototipe i agentskom cikle FUM](2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md): dlya vlozheniya ciklov drug v druga mozhet potrebovatjsya ne toljko vyibratj lokaljnuyu modelj i mashinu, no i poluchitj upravlyayemyij chistyij LLM-provajder, kotoryij ne podmenyayet soboj vesj agentskij cikl.

[Tenevoj redaktor prodolzhenij](../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md) chastichno proyasnyayet minimaljnyij nizhnij porog: zaraneye ustanovlennuyu lokaljnuyu modelj mozhno vyizyivatj kak ogranichennyij modeljnyij shag cherez loopback, bez oblachnogo fallback i bez peredachi teksta v argumentakh shell. Realjnyij progon podtverzhdayet rabotosposobnostj takogo kontura dlya korotkogo tekstovogo prodolzheniya, no ne opredelyayet prigodnostj modeli dlya osnovnogo agentskogo cikla, trebuyemuyu zaderzhku interaktivnogo nabora, ustojchivyij obyyom konteksta, versionirovaniye vesov i runtime, vyibor kvantovaniya ili apparatnyij profilj vyidelennoj mashinyi.

## Voprosyi dlya proyasneniya

- Kakiye zadachi [FUM](../Glossarij/FUM.md) dolzhnyi vkhoditj v benchmark-profilj lokaljnoj LLM: rabota s kodom, dokumentaciyej, glossariyem, planirovaniyem, instrumentami, dlinnyim kontekstom i proverkami?
- Kakiye minimaljnyiye trebovaniya k kachestvu, skorosti, obyyomu konteksta i instrumentaljnomu povedeniyu delayut modelj prigodnoj dlya osnovnogo lokaljnogo [agentskogo cikla](../Glossarij/agentskij-cikl.md)?
- Kakiye vneshniye modeli dopustimyi kak fallback, i kak ikh ispoljzovaniye dolzhno pomechatjsya v [pamyati FUM](../Glossarij/pamyatj-FUM.md)?
- Kakiye apparatnyiye parametryi vyidelennoj mashinyi yavlyayutsya obyazateljnyimi, a kakiye ostayutsya optimizaciyej: pamyatj, uskoriteli, nakopitelj, rezervnoye kopirovaniye, energopotrebleniye, shum, remontoprigodnostj i srok obnovleniya?
- Kak chasto nuzhno peresmatrivatj vyibor modeli i mashinyi, chtobyi vekha ostavalasj aktualjnoj, no ne razrushala vosproizvodimostj staryikh rezuljtatov?
- Kakiye chasti lokaljnoj sredyi mogut byitj opublikovanyi pod CC0, a kakiye otnosyatsya k lichnoj pamyati, sekretam ili nepublikuyemomu sostoyaniyu?
- Kakiye porogi zaderzhki pervogo bajta, skorosti prodolzheniya, otmenyi, kontekstnogo okna i vosproizvodimosti konfiguracii dostatochnyi dlya interaktivnogo tenevogo rezhima i otdeljno dlya osnovnogo agentskogo cikla?

## Svyazannyiye voprosyi

- [Razvilka giperseti i agentskogo cikla FUM](2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-25 19:50:33 MSK](../Zhurnal/2026-06-25_19-50-33_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla](../Zhurnal/2026-07-03_15-36-48_MSK_utochnitj-razvilku-giperseti-i-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij](../Zhurnal/2026-07-14_08-54-56_MSK_sozdatj-prototip-raskhozhdeniya-prodolzhenij/zapros.md)

## Zatronutaya dokumentaciya

- [Dokumentaciya/00-obzor-proyekta.md](../Dokumentaciya/00-obzor-proyekta.md)
- [Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md](../Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md](../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Dokumentaciya/22-arkhitektura-FUM.md](../Dokumentaciya/22-arkhitektura-FUM.md)
- [Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md](../Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)
- [Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md](../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Planirovaniye/dorozhnaya-karta.md](../Planirovaniye/dorozhnaya-karta.md)
- [Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md](../Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0db26328bc190d75f76ca8a3b5fa3e6027db23ac4f3484db5eb90377b55fa71d -->
<!-- FUM-MD-RECENCY:END -->
