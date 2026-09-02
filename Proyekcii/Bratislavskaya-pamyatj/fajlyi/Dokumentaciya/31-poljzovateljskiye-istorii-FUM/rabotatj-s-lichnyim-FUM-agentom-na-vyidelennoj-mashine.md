# Istoriya: rabotatj s lichnyim FUM-agentom na vyidelennoj mashine

Cheloveku nuzhen [lichnyij FUM-agent](../../Glossarij/lichnyij-FUM-agent.md), osnovnoj rabochij cikl kotorogo vyipolnyayetsya v upravlyayemoj lokaljnoj srede: s lokaljnoj pamyatjyu, modeljnyim runtime, instrumentami, proverkami i nablyudayemoj trassoj. Poljzovatelj dolzhen ponimatj, kakiye vyichisleniya dejstviteljno proshli na vyidelennoj mashine, a kakiye potrebovali vneshnej modeli ili servisa.

Cennostj lokaljnogo kontura sostoit v upravlyayemosti lichnoj pamyati, vosproizvodimosti rabochej sredyi i yavnoj granice vneshnikh zavisimostej. Odna lokaljno zapusjhennaya LLM ne ravna vsemu FUM: ustojchivyij agent dopolniteljno svyazyivayet modelj s pamyatjyu, identichnostjyu, pravami, instrumentami, proverkami i vozmozhnostjyu vosstanovleniya.

## Poljzovateljskaya istoriya

Kak vladelec lichnogo FUM-agenta, ya khochu datj yemu ogranichennuyu zadachu na vyidelennoj mashine i poluchitj proverennyij rezuljtat s lokaljno sokhranyonnoj pamyatjyu i trassoj, chtobyi osnovnoj cikl ne zavisel skryito ot oblachnogo provajdera i ostavalsya pod moim kontrolem.

## Osnovnoj scenarij

1. Poljzovatelj formuliruyet celj, razreshyonnuyu oblastj pamyati, dopustimyiye instrumentyi i dejstviya, trebuyusjhiye podtverzhdeniya.
2. Lokaljnyij uzel pokazyivayet apparatnyij profilj, modelj, runtime, konfiguraciyu konteksta i dostupnyiye vneshniye rasshireniya.
3. Agent chitayet razreshyonnuyu lokaljnuyu pamyatj, stroit plan i otdelyayet lokaljnyiye operacii ot vozmozhnyikh vneshnikh vyizovov.
4. Pered neobratimyim, platnyim, privatnyim ili vneshnim dejstviyem agent pokazyivayet ozhidayemyij effekt i poluchayet primenimoye podtverzhdeniye.
5. Agent vyipolnyayet lokaljnyij modeljnyij i instrumentaljnyij cikl, zapuskayet proverki i sokhranyayet vkhodyi, versii, dejstviya, oshibki i rezuljtat.
6. Pri novom razreshyonnom poljzovateljskom vvode bezopasnaya kontroljnaya tochka sokhranyayet prezhneye prodolzheniye libo nablyudayemo menyayet celj, prioritet ili plan.
7. Posle zaversheniya poljzovatelj poluchayet rezuljtat i mozhet vosstanovitj sessiyu iz lokaljnoj pamyati; obrasjheniya k vneshnim komponentam ostayutsya yavno otmechennyimi.

## Aljternativyi i otkazyi

- Yesli podkhodyasjhaya lokaljnaya modelj, runtime ili apparatnyij resurs otsutstvuyut, agent soobsjhayet nedostupnuyu chastj scenariya i ne vyidayot zaglushku libo oblachnyij vyizov za lokaljnoye vyipolneniye.
- Vneshnij fallback ispoljzuyetsya toljko v predelakh otdeljnogo razresheniya; peredavayemyiye dannyiye, provajder i nevosproizvodimaya chastj rezuljtata vidimyi poljzovatelyu.
- Nedostatochnyiye prava na fajl, instrument ili servis zakryivayut dejstviye bez skryitogo rasshireniya polnomochij.
- Sboj modeli ili instrumenta sokhranyayet proveryayemuyu oshibku i bezopasnuyu tochku vozobnovleniya; chastichnyij vneshnij effekt otdeljno sveryayetsya pered povtorom.
- Fonovaya rabota dopuskayetsya toljko iz zaraneye razreshyonnogo pula, s byudzhetom i ustupkoj poljzovateljskomu vvodu na bezopasnoj kontroljnoj tochke.

## Kriterii priyomki

- Ogranichennaya rabochaya sessiya prokhodit cepochku `прочитать память → предложить изменение → подтвердить эффект → выполнить → проверить → сохранить результат` v lokaljnom konture.
- Trassa nazyivayet fakticheski ispoljzovannyiye apparatnyij profilj, modelj, runtime, instrumentyi, parametryi i ogranicheniya.
- Osnovnoj scenarij ne trebuyet vneshnego API; kazhdyij fakticheskij vneshnij vyizov vyidelen i ne maskiruyetsya formulirovkoj o polnoj lokaljnosti.
- Prava chteniya, izmeneniya, publikacii i vneshnego dejstviya razlichayutsya, a trebuyemyiye podtverzhdeniya nablyudayemyi.
- Posle sboya libo ostanovki agent vozobnovlyayetsya iz sokhranyonnogo sostoyaniya bez obyazateljnogo prezhnego chata.
- Razreshyonnyij testovyij vvod vo vremya aktivnogo cikla privodit na bezopasnoj kontroljnoj tochke k obyyasnimomu sokhraneniyu ili izmeneniyu prodolzheniya.

## Granica primenimosti

Istoriya zadayot celevuyu vekhu, a ne podtverzhdyonnuyu gotovnostj tekusjhego produkta ili zakupochnuyu rekomendaciyu. Konkretnyiye mashina, lokaljnaya LLM, runtime, skorostj, energopotrebleniye i vneshnij fallback yesjhyo dolzhnyi byitj vyibranyi po proveryayemyim kriteriyam. Tekusjhij kontur Codex i Obsidian sluzhit povedencheskim proobrazom, no ne dokazyivayet sobstvennyij lokaljnyij agentskij runtime i ne razreshayet fizicheskuyu avtonomiyu.

## Status

Tekusjhij status: dokumentaciya i vneshnij kontur Codex zadayut povedencheskij proobraz, no ne podtverzhdayut sobstvennyij lokaljnyij agentskij runtime FUM.

Celevoj status: ogranichennaya rabochaya sessiya prokhodit na proverennoj vyidelennoj mashine s vyibrannyimi modeljyu i runtime; kriterii ikh vyibora ostayutsya v [otkryitom voprose](../../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md).

## Istochniki trebovanij

- [iskhodnyij zapros o napolnenii poljzovateljskikh istorij FUM](../../Zhurnal/2026-07-28_10-56-30_MSK_napolnitj-poljzovateljskiye-istorii-FUM/zapros.md)

## Opornyiye dokumentyi

- [Lokaljnyij agent FUM na vyidelennoj mashine](../24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Arkhitektura FUM](../22-arkhitektura-FUM.md)
- [Interfejs FUM-uzla](../25-interfejs-FUM-uzla.md)
- [Virtualizovannyiye sredyi FUM i dolgovremennaya pamyatj](../23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:168e444c014249e264c7b1ea4551dbfd076e29c16ece83e40648104c66d5a497 -->
<!-- FUM-MD-RECENCY:END -->
