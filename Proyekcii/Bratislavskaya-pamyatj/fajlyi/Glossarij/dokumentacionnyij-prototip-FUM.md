# Dokumentacionnyij prototip FUM

Dokumentacionnyij prototip FUM - stadiya razvitiya [FUM](FUM.md), v kotoroj tekusjhij repozitorij yesjhyo ne yavlyayetsya polnocennoj programmnoj sistemoj, no uzhe pokazyivayet formu budusjhej rabotyi [korobochnoj realizacii FUM](korobochnaya-realizaciya-FUM.md): vkhodnyiye signalyi sokhranyayutsya kak [iskhodnyiye zaprosyi](iskhodnyij-zapros.md), trebovaniya perekhodyat v [proizvodnuyu dokumentaciyu](proizvodnaya-dokumentaciya.md), terminyi zakreplyayutsya v glossarii, proverki i [avtomatizacii](avtomatizaciya-FUM.md) stanovyatsya chastjyu [pamyati](pamyatj-FUM.md), a rezuljtat fiksiruyetsya v zhurnale i Git-istorii.

Na masshtabe diskretnyikh zadach etot kontur yavlyayetsya povedencheskim prototipom [agentskogo cikla](agentskij-cikl.md). V dejstvuyusjhej ruchnoj skheme poljzovatelj zapuskayet odnu zadachu Codex v pervichnom checkout `refs/heads/master`; ona vyipolnyayet odin soderzhateljnyij zapros, sozdayot ne boleye odnogo lokaljnogo kommita i zavershayetsya. Prezhnij vozobnovlyayemyij profilj s [obyazateljnyim prodolzheniyem vetki](obyazateljnoye-prodolzheniye-vetki.md), FIFO i avtomaticheskim [sleduyusjhim shagom vetki](sleduyusjhij-shag-vetki.md) sokhranyon kak otlozhennaya narabotka, a ne ekspluatacionnyij marshrut. Poljzovateljskaya zadacha mozhet izmenitj pamyatj, trebovaniya i ogranicheniya, no sleduyusjhuyu pishusjhuyu sessiyu zapuskayet toljko poljzovatelj.

Yego preobladayusjhij smyislovoj i chelovekochitayemyij sloj - tekst dvukh razlichimyikh tipov proiskhozhdeniya. Chelovek porozhdayet iskhodnyiye formulirovki, namereniya, ogranicheniya i podtverzhdeniya; LLM v agentskoj sessii Codex v osnovnom porozhdayet i pererabatyivayet proizvodnyiye tekstyi. Prilozheniye ChatGPT pri etom yavlyayetsya nablyudayemoj poverkhnostjyu tekusjhej sessii, a ne obsjhim imenem modeli, agenta, runtime i instrumentov.

Takaya redukciya opisyivayet smyislovoye yadro tekusjhej praktiki, no ne vsyu [pamyatj FUM](pamyatj-FUM.md). Skriptyi, testyi, strukturirovannyiye dannyiye, vneshniye istochniki, vlozheniya, metadannyiye i Git-istoriya ostayutsya samostoyateljnyimi formami i sloyami pamyati. Vneshnyaya sessiya i host-orkestraciya Codex takzhe ne schitayutsya uzhe realizovannyim sobstvennyim runtime [agentskogo cikla](agentskij-cikl.md) FUM. Read-only-nablyudeniye mozhet sosusjhestvovatj s ruchnoj pishusjhej sessiyej, no ne poluchayet ot etogo prava zapisi.

Takoj prototip ne schitayetsya gotovyim produktom. Yego zadacha - na zhivom primere [pamyati FUM](pamyatj-FUM.md) vyidelyatj perenosimyiye trebovaniya, dannyiye, proverki, interfejsyi i ogranicheniya, kotoryiye pozzhe dolzhnyi perejti v korobochnuyu realizaciyu bez privyazki k sluchajnyim osobennostyam pervoj rabochej sredyi.

## Svyazannyiye dokumentyi

- [Obzor proyekta FUM](../Dokumentaciya/00-obzor-proyekta.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Gibridnyiye uzlyi i socialjnaya fraktaljnostj](../Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md)
- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-06-29 10:59:18 MSK](../Zhurnal/2026-06-29_10-59-18_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-14 00:36:30 MSK - Utochnitj tekstovyij sostav pamyati dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-14_00-36-30_MSK_utochnitj-tekstovyij-sostav-pamyati-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK - Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:d3a8f26bd5bb3cf4c531231792daf9f8476901054136d11c7a1fc52d04b9e256 -->
<!-- FUM-MD-RECENCY:END -->
