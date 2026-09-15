# Karta perenosa sovmestimosti

Iskhodnyij M — `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`. Neizmennyij L — `a728283474931eda71cd581ca5429121124ba3f6`, derevo `bc258a41133107198602c60d003555898d4cfad2`. Itogovyij diff vyichislyayetsya otnositeljno M; dannyij etap ne yavlyayetsya kandidatom sliyaniya.

1. `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95`: khunki formatov proyektora, kontrakt i skhema plana, prezhnij kontrakt, 13 regressij i fikstura perekhoda. Sokhranyonnyij prezhnij kontrakt pobajtovo raven M; iskhodnyiye blobs proyektora, kontrakta, skhemyi i testa sovpali s roditelem istochnika.
2. `32cac61b3e90023ccfb854b5311fc0e4c37865d4`: konechnaya grammatika obyyavlenij, 17 testov i profilj. `8609003af7fdb6ef5dddf21c51cd6607ddb34088`: yedinstvennyij putj adaptera v kontrakte i proyektore, zavisimostj ot proverki obyyavlenij, vosemj testov. Obsjhij most staroj politiki vklyuchyon odin raz vmeste s formatami. Sam ispolnyayemyij `адаптер-codex.js` iz L ne perenositsya: prinimayusjhij kontur proveryayet yego kak dannyiye kandidata. Proizvoljnyiye JS, MJS i CJS ne dopuskayutsya.
3. `0246844fe15ba51e48327005b33bc78b668f813a`: dva izmeneniya parsera tochnogo markera otsutstviya svyazej i shestj regressij. Iskhodnyij blob parsera M sovpal s roditelem istochnika.
4. `c14b2dee156a5a07d22addf187f06980c1f501bc`: vyizov prinimayusjhej proverki i zavisimostj `расширение_шаблонов.py`, 19 iskhodnyikh testov i profilj. Opisaniye rezuljtata `acab107170a4a1243b76cba4f25b0b408e735603` — proiskhozhdeniye. Dopolniteljno ispravlen podtverzhdyonnyij [probel predkov puti](../../../Sboi/FUM-SBOJ-0076-propusk-proverki-predkov-kataloga-tipov.md), dobavlenyi vosemj adresnyikh testov. Ustanovka novyikh tipov, generator nachala sessii i tranzakcionnyij priyom napravlenij ne perenosilisj.
5. `28f51c58fa8df4d20d33ef2f05dab758cb7a6f83`: predikat i primeneniye v svyaznosti, chetyire testa i profilj; iskhodnyij blob sovpal s M. `7acc2de8ca1dcbefd82c16faecd1c31bdfa6e648`: toljko pyatj zavisimyikh khunkov grafa v proyektore, semj testov i profilj. Polnyij proyektor L poverkh M ne kopirovalsya. Tochnyij ignored `.obsidian/graph.json` v svoyom dereve otsutstvuyet; poljzovateljskoye sostoyaniye ne sozdavalosj i ne menyalosj.
6. Tochnaya obyichnaya politika L sluzhit kandidatnoj: 419 zapisej, SHA-256 `4a73ad60ca3c8eee704aecff2a33481c642a4633ea3a9622adb23a5fb4ef8cb0`. Prezhniye 350 sokhranenyi doslovno; 69 dobavlenij sopostavlyayutsya s L po polyam i fakticheskim nakhodkam scanner. Promezhutochnyiye lishniye dve zapisi ne perenosilisj. V obyichnoj politike M prezhniye 350 dopolnenyi toljko `0176-projection-foreign-fixture`, pereschitannoj shtatnyim `obnovitj-policy.py`.

Vyisokij kontur sliyaniya, svideteljstvo ispolneniya, zakryityij chitatelj, prodvizheniye, standartnyij profilj, strogij scanner i gitlink LinguisticKit ostavlenyi iskhodnyimi. Novyiye ispolnyayemyiye zavisimosti ostayutsya vnutri rekursivno sveryayemoj oblasti `Инструменты`; proveryayusjhij istochnik i dannyiye kandidata razlichayutsya. Ni odna prezhnyaya priyomka L ili otdeljnogo paketa ne podmenyayet proverku etogo diff.

Sobstvennyiye izmereniya i ogranicheniya perechislenyi v [otchyote](../otchyot.md), iskhodnyiye komandyi — v [zaprose](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:19:56 MSK -->
<!-- content-sha256: sha256:6c09a7033e940735c6a7634c14965366841154dba17ddae5a9e19d9e24a1987e -->
<!-- FUM-MD-RECENCY:END -->
