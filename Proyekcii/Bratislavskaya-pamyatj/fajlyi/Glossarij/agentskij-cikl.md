# Agentskij cikl

Agentskij cikl v FUM - povtoryayemyij kontur rabotyi, v kotorom agent prinimayet celj i sostoyaniye, vyibirayet dejstviye, poluchayet nablyudeniye ili [nablyudayemyij vkhodnoj signal](nablyudayemyij-vkhodnoj-signal.md), obnovlyayet pamyatj i reshayet, prodolzhatj li rabotu, zavershitj yeyo, perejti v druguyu vetku ili peredatj zadachu drugomu agentu.

Operacionnaya nepreryivnostj cikla ne trebuyet odnogo nepreryivayemogo processa ili modeljnogo vyizova. Kontur mozhet zavershitj ogranichennuyu zadachu, sokhranitj sostoyaniye, vyibratj sleduyusjheye prodolzheniye ili sozdatj kontroljnuyu tochku ozhidaniya. Samo otsutstviye poljzovateljskogo podtverzhdeniya ostanavlivayet svyazannyij s nim vneshnij perekhod, no ne vesj cikl, poka ostayutsya bezopasnaya produktivnaya modeljnaya rabota i konechnyij razreshyonnyij byudzhet. V tekusjhem [dokumentacionnom prototipe FUM](dokumentacionnyij-prototip-FUM.md) poljzovatelj vruchnuyu zapuskayet kazhduyu otdeljnuyu pishusjhuyu sessiyu; prezhnij Git- i Codex-profilj s [obyazateljnyim prodolzheniyem vetki](obyazateljnoye-prodolzheniye-vetki.md), [sleduyusjhim shagom](sleduyusjhij-shag-vetki.md), FIFO i `commit+handoff` sokhranyon kak otlozhennyij povedencheskij eksperiment, a ne dejstvuyusjhij runtime.

Dlya [FUM](FUM.md) agentskij cikl yavlyayetsya ne toljko mekhanizmom ispolneniya, no i istochnikom materiala dlya [pamyati FUM](pamyatj-FUM.md): sledyi nablyudenij i dejstvij dolzhnyi stanovitjsya osnovoj dlya poiska [patternov pamyati](pattern-pamyati.md).

V celevoj arkhitekture agentskij cikl dolzhen byitj voplosjheniyem [obobsjhyonnogo darvinovskogo algoritma](obobsjhyonnyij-darvinovskij-algoritm.md): agentyi porozhdayut cepochki rassuzhdenij, reshenij, dejstvij i proverok, a otbor sravnivayet ikh po sposobnosti sozdavatj dlinnyiye, poleznyiye i produktivnyiye prodolzheniya bez chrezmernoj cenyi, riska i poteri proveryayemosti.

Pri soderzhateljnoj neodnoznachnosti cikl mozhet poroditj dve ili boleye modeljnyiye vetvi ot obsjhego tochnogo predka, vyidelitj kazhdoj konechnyij byudzhet, otdeljno proveritj variantyi i vyibratj daljnejshuyu modeljnuyu prorabotku. Takoj vnutrennij otbor ne yavlyayetsya poljzovateljskim podtverzhdeniyem, avtorizaciyej ili faktom vneshnego ispolneniya; eti sostoyaniya sokhranyayutsya nezavisimo.

V rezhime [nejronnoj giperseti FUM](nejronnaya-gipersetj-FUM.md) agentskij cikl mozhet ponimatjsya kak peremesjheniye agenta po setevoj srede. Agent ne toljko poluchayet vkhod i vyidayot dejstviye, no i vyibirayet marshrut interpretacii uzlov i svyazej; yego nastrojki mogut nasledovatjsya, mutirovatj i otbiratjsya uzhe vo vremya ispolneniya, bez obyazateljnogo izmeneniya bazovoj modeli.

[Avtomaticheskij organ dejstviya FUM](avtomaticheskij-organ-dejstviya-FUM.md) mozhet zanimatj v cikle mesto mezhdu vyiborom dejstviya i ispolnitelem: on perevodit vyisokourovnevoye opisaniye dejstviya v nizkourovnevyiye komandyi fizicheskoj ili programmnoj sredyi.

Istochnikom celi mozhet byitj zaraneye razreshyonnaya ocheredj [fonovyikh zadanij FUM](fonovoye-zadaniye-FUM.md), no toljko kogda net neobrabotannogo poljzovateljskogo vvoda i gotovyikh zadach boleye vyisokogo prioriteta. Novyij vkhod ili boleye prioritetnaya rabota perevodyat takoj cikl k bezopasnoj kontroljnoj tochke, sokhraneniyu trassyi i priostanovke libo zaversheniyu po yavnoj politike zadaniya.

V korobochnom runtime razreshyonnyij poljzovateljskij vvod mozhet nablyudatjsya na urovne sobyitij vo vremya aktivnogo cikla. Sobyitiya mozhno otfiljtrovatj, obyyedinitj i sootnesti s proiskhozhdeniyem do primeneniya; otdeljnyij vyizov LLM dlya kazhdogo sobyitiya ne trebuyetsya. Izmeneniye trayektorii oznachayet nablyudayemoye izmeneniye celi, prioriteta, vetki, dejstvij, proverok i posleduyusjhego sostoyaniya, a ne raskryitiye ili zapisj skryityikh rassuzhdenij modeli.

## Svyazannyiye dokumentyi

- [Obzor aktualjnyikh realizacij agentskikh ciklov](../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK - Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-14 03:18:36 MSK - Zakrepitj fonovyiye zadaniya dlya prostoya LLM](../Zhurnal/2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK - Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:5628420b6cda146c6ec7fbf96f951264cbf66ba33f57c00402825ce7357a6d0a -->
<!-- FUM-MD-RECENCY:END -->
