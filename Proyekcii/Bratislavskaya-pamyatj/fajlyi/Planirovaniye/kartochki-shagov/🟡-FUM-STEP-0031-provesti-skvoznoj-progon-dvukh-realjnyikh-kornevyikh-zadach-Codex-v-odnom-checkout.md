+++
schema_version = 1
card_id = "FUM-STEP-0031"
status = "active"
+++
# Provesti skvoznoj progon dvukh realjnyikh kornevyikh zadach Codex v odnom checkout

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Provesti skvoznoj progon zavershayusjhejsya kommitom kornevoj zadachi Codex i sozdannoj yeyu zadachi-prodolzheniya v odnom checkout. Roditelj dolzhen zaraneye sozdatj rovno odno prodolzheniye dlya togo zhe polnogo ref, dozhdatjsya yego tochnogo ozhidayusjhego FIFO-bileta na iskhodnom `HEAD` i atomarno peredatj vetku vmeste s kommitom; prodolzheniye dolzhno perechitatj novyij `HEAD`, vyipolnitj `ack-head`, poluchitj dopusk i neposredstvenno vyizvatj vetochnyij selector.

## Pochemu sejchas

Avtonomnyiye testyi uzhe proveryayut konkurentnyiye `join`, zapret obkhoda, obyazateljnyij `reload_required`/`ack-head`, atomarnyij commit+handoff, SHA-1/SHA-256 i Unicode-vetku. Zhivoj progon nuzhen kak proverka svyazi tochnogo host-otveta sozdaniya s ozhidayusjhim biletom, vetkoj i posleduyusjhim pryamyim vyiborom shaga dvumya nezavisimyimi zadachami, a ne dlya odobreniya hooks ili ruchnogo dopuska. Neodnoznachnyij otvet sozdaniya dolzhen ostanovitj roditelya do kommita bez avtomaticheskogo povtora.

## Kriterii zaversheniya

- Rezuljtat, opisannyij v razdele «Zadacha», sozdan i sokhranyon v pamyati FUM s yavnoj granicej primenimosti; periodicheskij heartbeat, dispatcher-reservation i kartochochnyij claim ne uchastvuyut v zapuske prodolzheniya.
- Proverki, nazvannyiye v zadache i opornyikh materialakh, vyipolnenyi, a ikh rezuljtat zafiksirovan v svyazannom zaprose ili zhurnale.
- Status kartochki obnovlyon po fakticheskomu iskhodu; vetochnyij vyibor ne dubliruyet soderzhaniye kartochki.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-21 18:31:35 MSK](../../Zhurnal/2026-07-21_18-31-35_MSK_vvesti-posledovateljnuyu-ocheredj-sessij-bez-hooks/zapros.md), [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [paralleljnaya rabota i sliyaniye](../../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:7f9033707b50671aea00343303daea698a2fbd8ccba19f48c18012523c2eb686 -->
<!-- FUM-MD-RECENCY:END -->
