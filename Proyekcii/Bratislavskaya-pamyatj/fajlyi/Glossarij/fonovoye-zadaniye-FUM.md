# Fonovoye zadaniye FUM

Fonovoye zadaniye FUM - zaraneye razreshyonnaya yedinica rabotyi nizkogo prioriteta, kotoruyu runtime [korobochnoj realizacii FUM](korobochnaya-realizaciya-FUM.md) mozhet peredatj LLM, agentu ili drugomu [FUM-uzlu](FUM-uzel.md), toljko poka net neobrabotannogo poljzovateljskogo vvoda i gotovyikh k ispolneniyu zadach boleye vyisokogo prioriteta. Ocheryodnostj, byudzhet i vyitesneniye takogo zadaniya opredelyayet [darvinovskij planirovsjhik FUM](darvinovskij-planirovsjhik-FUM.md), a ispolneniye vkhodit v nablyudayemyij [agentskij cikl](agentskij-cikl.md).

Fonovoye zadaniye dolzhno imetj celj, proiskhozhdeniye, prioritet, razreshyonnyiye dejstviya, byudzhet vremeni i vyichisliteljnyikh resursov, kriterij ostanovki, trassu i bezopasnuyu kontroljnuyu tochku. Novyij poljzovateljskij vvod ili boleye prioritetnaya zadacha priostanavlivayut libo zavershayut yego po yavnoj politike. Fonovyij status ne rasshiryayet [urovenj dostupa](urovenj-dostupa.md) i [granicu vlasti FUM](granica-vlasti-FUM.md), poetomu vneshniye, neobratimyiye i inyiye nerazreshyonnyiye effektyi ostayutsya zapresjhyonnyimi.

Odnim iz fonovyikh zadanij mozhet byitj postroyeniye ili obnovleniye yavnogo opisaniya modeli mira i yazyikovogo prostranstva konkretnoj LLM. Takoj rezuljtat sokhranyayetsya v [pamyati FUM](pamyatj-FUM.md) kak versioniruyemyij artefakt [modeljnoj sredyi](modeljnaya-sreda.md) s privyazkoj k modeli, runtime, dostupnoj pamyati, kontekstnoj konfiguracii i nablyudayemomu povedeniyu. Nablyudeniya, vyivodyi, otdeljnyiye [gipotezyi FUM](gipoteza-FUM.md) i neizvestnoye razlichayutsya vnutri nego; vesj artefakt ne schitayetsya pryamyim chteniyem vesov, skryityikh sostoyanij ili dokazannyim faktom o mire.

## Svyazannyiye dokumentyi

- [Git-infrastruktura evolyucionnyikh cepochek FUM](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Lokaljnyij agent FUM na vyidelennoj mashine](../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Yestestvennyij yazyik i sinkhronizaciya znanij FUM](../Dokumentaciya/34-yestestvennyij-yazyik-i-sinkhronizaciya-znanij-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-14 03:18:36 MSK - Zakrepitj fonovyiye zadaniya dlya prostoya LLM](../Zhurnal/2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d5db6052366b977e1cb6d5a71462cc5fca099c760c444926c631bb1a80653e83 -->
<!-- FUM-MD-RECENCY:END -->
