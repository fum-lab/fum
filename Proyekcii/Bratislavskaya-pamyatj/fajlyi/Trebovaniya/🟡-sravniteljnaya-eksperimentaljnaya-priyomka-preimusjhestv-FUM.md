# Sravniteljnaya eksperimentaljnaya priyomka preimusjhestv FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0030 -->

Utverzhdeniye, chto FUM povyishayet kachestvo agenta ili samouluchshayetsya, dolzhno prokhoditj sravniteljnuyu eksperimentaljnuyu priyomku na vneshnikh ili skryityikh zadachakh. Chislo kommitov, dokumentov, kartochek i zavershyonnyikh shagov ne zamenyayet izmereniye vneshnej sposobnosti.

[Predregistraciya versii `1`](../Planirovaniye/kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md) fiksiruyet do izmerenij shestj prichinno razdelyonnyikh variantov, odinakovyiye agregatnyiye ogranicheniya, vneshnij kriterij uspekha, `50` osnovnyikh zadach, tri povtora, politiku ostanovki, obyazateljnyiye metriki i zasjhitu skryityikh kriteriyev. Protokol ne yavlyayetsya rezuljtatom serii i ne podtverzhdayet preimusjhestvo FUM.

## Semanticheskiye svyazi

- **zavisit ot:** [skvoznogo proveryayemogo odnoagentnogo epizoda FUM](✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md) — bazovyij variant FUM dolzhen byitj ispolnyayemyim do sravneniya s boleye prostyim konturom.

## Kriterii proverki

- protokol, gipoteza, vyibor zadach, metriki, povtoryi, politika ostanovki i kriterij uspekha predregistriruyutsya do pervogo izmeryayemogo progona;
- variantyi ispoljzuyut odinakovuyu bazovuyu modelj, sopostavimyiye instrumentyi, vyichisliteljnyij i tokennyij byudzhetyi, politiku povtorov i odin vneshnij kriterij zaversheniya;
- bazovaya lestnica otdeljno izmeryayet obyichnyij agentskij cikl, kontrolj s tochkami vosstanovleniya i odnoagentnyij FUM s proveryayemoj pamyatjyu i rabochimi paketami;
- vliyaniye otdeljnogo proveryayusjhego i vliyaniye mnozhestva poduzlov izmeryayutsya raznyimi variantami i ne smeshivayutsya v odno vozdejstviye;
- zadachi vklyuchayut neodnoznachnyiye vneshniye repozitorii ili ekvivalentnyiye zakryityiye scenarii, skryityiye testyi, prinuditeljnyiye preryivaniya, konfliktyi i povrezhdyonnuyu pamyatj; utechka kriteriyev v kontekst ispolnitelya predotvrasjhayetsya;
- metriki vklyuchayut uspekh po vneshnemu kriteriyu, lozhnoye zaversheniye, vosstanovleniye posle sboya, sokhrannostj podtverzhdyonnogo sostoyaniya, vmeshateljstva cheloveka, stoimostj, tokenyi, vremya, dublirovaniye rabotyi, konfliktyi i regressii;
- otchyot ne povyishayet lokaljnyij uspekh do universaljnogo preimusjhestva i sokhranyayet otricateljnyiye i neopredelyonnyiye rezuljtatyi.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: eksperimentaljnaya granica prinyata i protokol versii `1` predzaregistrirovan, no task-manifest, evaluator, polnomochiya i serii progonov yesjhyo ne podgotovlenyi i ne vyipolnenyi. Realjnyiye setevyiye ili platnyiye eksperimentyi, izmeneniye chuzhikh repozitoriyev i publikaciya ikh rezuljtatov trebuyut otdeljnogo razresheniya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-02 23:09:10 MSK — Predzaregistrirovatj sravniteljnuyu priyomku preimusjhestv FUM](../Zhurnal/2026-08-02_23-09-10_MSK_predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:57dcdcfabb699fd2d7269f5774e18f2f384d9000047cc3be528d69bfceb08e01 -->
<!-- FUM-MD-RECENCY:END -->
