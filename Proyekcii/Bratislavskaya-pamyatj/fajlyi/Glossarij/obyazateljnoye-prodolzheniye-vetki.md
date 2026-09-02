# Obyazateljnoye prodolzheniye vetki

## Status

Eto istoricheskij i otlozhennyij protokol. Posle perekhoda na ruchnuyu posledovateljnuyu skhemu on ne yavlyayetsya dejstvuyusjhim marshrutom: poljzovatelj sam zapuskayet sleduyusjhuyu pishusjhuyu sessiyu, a kommit ne sozdayot continuation i ne peredayot FIFO. Sokhranyonnyiye nizhe opredeleniya, refs i kvitancii nuzhnyi dlya proiskhozhdeniya, regressionnyikh testov i vozmozhnogo budusjhego pereproyektirovaniya.

V prezhnej skheme obyazateljnoye prodolzheniye vetki svyazyivalo kazhdyij obyichnyij promezhutochnyij kommit [rabochej sessii](rabochaya-sessiya.md) s odnoj tochnoj uzhe zaregistrirovannoj zadachej Codex. Svyazj zakreplyala identichnostj linii, polnyij lokaljnyij Git-ref, fizicheskij worktree, yego FIFO, fakticheskij `threadId` i neizmenyayemuyu kvitanciyu prodolzheniya; podtverzhdyonnyij `hostId` dopolniteljno trebovalsya toljko dlya zadachi, sozdannoj cherez host.

Do kommita worktree-linii susjhestvuyet rovno odin pervyij FIFO-bilet: samostoyateljno otkryityij chat mozhet vyibratj exact aktivnuyu liniyu iz svezhego ograzhdyonnogo snimka, i atomarnoye prisoyedineniye samo sozdast intent i kvitanciyu; yesli takogo bileta net, vladelec sozdayot odnu zadachu s ekvivalentnoj svyazjyu. Handoff vyipolnyayetsya komandoj pula po khyeshu intent, a dostigsheye golovyi prodolzheniye perechityivayet zakreplyonnyij `protocol_oid`, podtverzhdayet tochnuyu vershinu linii i posledovateljno ispoljzuyet te zhe slot, ref i worktree bez vtorogo checkout.

Obyichnaya branch FIFO, vklyuchaya `master`, ispoljzuyet drugoj profilj: vladelec vsegda sozdayot prodolzheniye do kommita, rebyonok predyyavlyayet exact-kvitanciyu i vyipolnyayet obyichnyij `join`, a `commit` poluchayet yego identifikator. Dostignuv golovyi, rebyonok perechityivayet fakticheskij `HEAD`, vyipolnyayet `ack-head` i vyibirayet [sleduyusjhij shag vetki](sleduyusjhij-shag-vetki.md); `master` ostayotsya v pervichnom checkout. Posle registracii otsutstvuyusjhaya, ispoljzovannaya, stale libo nesovpavshaya kvitanciya lyubogo profilya zakryivayet marshrut i ne sozdayot rezervnyij nezavisimyij slot.

Eto unarnyij perekhod vnutri odnogo [vetvevogo fork FUM](vetvevoj-fork-FUM.md): odin obyichnyij kommit linii — odno prodolzheniye tekh zhe ref i worktree. `finish-clean`, `done` i `not_ready` zavershayut cepochku bez rebyonka. Terminaljnyiye commits rezuljtata pisatelya, revjyu i integracionnogo kandidata lokaljnogo pula zavershayut otdeljnyiye naznacheniya sobstvennyimi kvitanciyami i obyazateljnyim prodolzheniyem ne okhvatyivayutsya. Read-only-zadacha ne poluchayet pisateljskij slot, a nezavisimyij pisatelj bez kvitancii prodolzheniya nachinayet novuyu liniyu v otdeljnom pereispoljzuyemom slote `Подузлы/`.

Kogda profilj trebuyet `create_thread`, yego neodnoznachnyij rezuljtat zakryivayet perekhod otkazom: roditelj ne kommitit i avtomaticheski ne povtoryayet host-vyizov, potomu chto zadacha mogla fakticheski poyavitjsya. Git-perekhod samostoyateljno prisoyedinivshegosya worktree-prodolzheniya vmesto etogo vosstanavlivayetsya iz prezhnikh intent i FIFO po exact `task_id`. Dokumentarnyij i etalonnyij prototip proveryayet exact slot `repo-root` soderzhateljnyikh komand, no Codex Desktop poka ne dayot perenosa workspace na urovne host s mashinnyim ACK. Poetomu worktree ne yavlyayetsya nativnoj izolyaciyej host i ne dokazyivayet otsutstviya chtenij pervichnogo checkout. Protokol takzhe ne obesjhayet atomarnostj Codex-host s Git, exactly-once sozdaniya ili bezuslovnuyu zhivuchestj; ischeznuvshij ispolnitelj ne obkhoditsya tajmerom libo dispetcherom.

## Svyazannyiye dokumentyi

- [Obyazateljnoye prodolzheniye Git-vetki posle kommita](../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [Istoricheskij dispetcher avtomatizacij FUM](dispetcher-avtomatizacij-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 11:56:54 MSK -->
<!-- content-sha256: sha256:b4bf69b4cfa9a5280a833df500daa9ece3da4f27d62ba6c563a80f6f056649a3 -->
<!-- FUM-MD-RECENCY:END -->
