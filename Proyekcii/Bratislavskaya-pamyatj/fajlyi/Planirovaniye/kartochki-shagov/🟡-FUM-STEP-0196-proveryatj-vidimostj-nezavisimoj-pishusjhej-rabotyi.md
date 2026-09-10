+++
schema_version = 1
card_id = "FUM-STEP-0196"
status = "active"
+++
# Proveryatj vidimostj nezavisimoj pishusjhej rabotyi

## Zadacha

Podgotovitj i proveritj konechnyij vosproizvodimyij scenarij primeneniya sokhranyonnogo zaprosa vidimyikh zadach Codex Desktop pri nezavisimom pishusjhem naznachenii i vosstanovlenii konteksta. Oblastj ogranichena podtverzhdeniyem naznacheniya i zapuska; produktovyij snimok runtime i avtomaticheskoye prodolzheniye syuda ne vkhodyat.

## Pochemu sejchas

`FUM-СБОЙ-0049/ПРОЯВЛЕНИЕ-0001` podtverdilo povtornoye neispolneniye uzhe sokhranyonnogo ukazaniya. Tekusjhaya peredacha vosstanovlena i normyi utochnenyi; odnoj polozhiteljnoj peredachi nedostatochno dlya dokazateljstva ustojchivoj meryi.

## Kriterii zaversheniya

- Otkryityiye fiksturyi razlichayut prinyatoye sozdaniye, podgotovku s clientThreadId i podtverzhdyonnyij zapusk s realjnyim task ID, adresnyim otvetom, worktree/ref/HEAD i yedinstvennyim pisatelem.
- Sokhranyonnoye ukazaniye primenyayetsya pri sleduyusjhem naznachenii i posle vosstanovleniya konteksta bez novogo razresheniya.
- Nepolnyij obsjhij spisok ne vyizyivayet dublikat; neizvestnaya libo otlichayusjhayasya fakticheskaya modelj ne podmenyayetsya zaproshennoj.
- Publikacionno chistyiye vkhodyi, komanda, ozhidayemyij rezuljtat i otricateljnyiye sluchai pozvolyayut povtoritj scenarij; syiryiye JSONL, puti khosta i sekretyi isklyuchenyi.
- Realjnoye adresnoye nablyudeniye sopostavleno so scenariyem. Pri dobavlenii ispolnyayemogo koda vyipolnenyi TDD, profilj, resheniye ob optimizacii i primenimaya priyomka.

## Istochniki

- [FUM-SBOJ-0049/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0049-propusk-vidimoj-zadachi-pishusjhej-rabotyi.md).
- [Tekusjhij ogranichennyij etap](../../Zhurnal/2026-09-11_01-26-17_MSK_podtverzhdatj-vidimyiye-zadachi-nezavisimyikh-rabot/zapros.md).
- [Pervonachaljnoye ukazaniye](../../Zhurnal/2026-09-09_11-39-26_MSK_predotvratitj-poteryu-obyazateljstv-postoyannoj-zadachi/zapros.md).
- [Dejstvuyusjhaya procedura](../../Pravila/agentov/lokaljnyiye-navyiki-i-instrumentyi.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:40:19 MSK -->
<!-- content-sha256: sha256:8b4b5d5aeb9c3ecbd611f5f78f9b441a559b1cd3d2e7a74ab54ab6f729c4b61c -->
<!-- FUM-MD-RECENCY:END -->
