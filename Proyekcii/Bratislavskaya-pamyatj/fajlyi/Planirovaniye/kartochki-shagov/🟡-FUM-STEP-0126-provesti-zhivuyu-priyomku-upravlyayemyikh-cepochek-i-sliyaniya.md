+++
schema_version = 1
card_id = "FUM-STEP-0126"
status = "active"
+++
# Provesti zhivuyu priyomku upravlyayemyikh cepochek i sliyaniya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Posle otdeljnogo yavnogo razresheniya provesti ogranichennyij zhivoj progon realjnogo pula universaljnyikh fork-poduzlov cherez odin ekzemplyar Codex Desktop. Odin roditeljskij vetvevoj fork dolzhen poroditj ot proverennogo obsjhego iskhodnogo sostoyaniya dvukh detej, peredatj im konechnyiye cepochki v raznyiye refs i sozdatj toljko nachaljnuyu [sessiyu shaga FUM](../../Glossarij/sessiya-shaga-FUM.md) kazhdoj cepochki; kazhdyij kommityasjhij vladelec obyazan zaraneye sozdatj sleduyusjhuyu sessiyu kak prodolzheniye togo zhe zhivogo klona i ref. Roditeljskaya sessiya osvobozhdayet vladeniye, a otdeljnaya sessiya togo zhe logicheskogo fork vosstanavlivayet moderatora, sravnivayet obe zakreplyonnyiye vershinyi i vyibirayet libo obyyedinyayet ikh. Progon dolzhen perezhitj mezhsessionnoye vozobnovleniye, provesti rezuljtatyi po sobstvennomu dochernemu, proyektnomu i obsjhemu core-marshrutam, poluchitj realjnyij pull request rebyonka v sovmestimyij core, vyipolnitj otdeljnoye revjyu i integrirovatj prinyatyiye vershinyi. Odin [perenosimyij navyik FUM](../../Glossarij/perenosimyij-navyik-FUM.md) dolzhen projti cherez core k zaraneye zaregistrirovannomu celevomu agentu-poluchatelyu s korrektnoj sinkhronizaciyej fork i posleduyusjhim obnovleniyem gitlink.

## Pochemu sejchas

Avtonomnyij poddeljnyij host ne podtverzhdayet fakticheskuyu privyazku Codex-zadach k otdeljnyim checkout, zhivuyu modelj, remote-publikaciyu ili vosstanovleniye vneshnej topologii. Eti effektyi neljzya vklyuchatj bez otdeljnoj attestacii i razresheniya.

## Kriterii zaversheniya

- Pered progonom zafiksirovanyi tochnyiye modeli i postavsjhiki, host-zadachi, repozitorii i refs, razreshyonnyiye dannyiye, instrumentyi, setj, byudzhetyi, publikaciya, glubina rekursii i usloviye ostanovki.
- Ne meneye dvukh realjnyikh ispolnitelej rabotayut v raznyikh zhivyikh klonakh i sozdayut po neskoljku proveryayemyikh commit; ispolniteli ne razdelyayut checkout, indeks ili refs.
- Oba ispolnitelya prinadlezhat odnomu podtverzhdyonnomu pokoleniyu razvilki s proverennyim obsjhim iskhodnyim sostoyaniyem, raznyimi fork, parami repozitoriya i ref i checkout; kazhdyij imeyet ne boleye odnoj dopusjhennoj pishusjhej sessii-vladeljca, a neodnoznachnostj lyuboj nachaljnoj host-zadachi ostavlyayet oboikh bez prava zapisi, ne dopuskayet ikh v FIFO do yedinoj aktivacii i ne povtoryayet sozdaniye avtomaticheski.
- Kazhdyij shag imeyet otdeljnyiye Desktop-zadachu i `CODEX_THREAD_ID`; zadachi odnoj cepochki ispoljzuyut tot zhe fizicheskij checkout i polnyij ref, identifikator ne pereispoljzuyetsya, a poteryannaya granica sozdaniya ne porozhdayet dvojnuyu sessiyu. Yedinstvennostj fizicheskogo Desktop-kontrollera obyyavlyayetsya dokazannoj toljko pri ustojchivoj host-identichnosti i avtoritetnom readback.
- Novyij process vosstanavlivayet khotya byi odnu nezavershyonnuyu cepochku bez skryitogo chata, a poteryannaya host-granica ne sozdayot dvojnogo vladeljca.
- Novaya ograzhdyonnaya sessiya togo zhe logicheskogo fork vosstanavlivayet roditeljskogo moderatora bez prezhnego chata, proveryayet obe zamorozhennyiye vershinyi i sokhranyayet tipizirovannoye resheniye; roditeljskaya sessiya ne uderzhivayet FIFO v techeniye dochernego ispolneniya.
- Otdeljnoye revjyu zakreplyayet tochnyiye vershinyi, marshrutyi i korrelyacii; korenj integriruyet toljko prinyatyiye diapazonyi. Sobstvennyij dochernij rezuljtat obnovlyayet gitlink lishj posle prinyatiya v rebyonke, proyektnyij rezuljtat sleduyet kontraktu celevogo proyekta, a publikacionno chistyij obsjhij vklad sokhranyayetsya v rodoslovnoj core bez squash.
- Realjnyij pull request rebyonka v sovmestimyij core zakreplyayet postavsjhika, iskhodnyij i celevoj repozitorii, polnyiye refs, identifikator PR, pokoleniye naznacheniya, tochnyiye base/head, diapazon i publikacionnyij pasport. Avtoritetnyij readback ne dopuskayet dublikat posle poteryannogo otveta; dvizheniye base/head, force-push, zakryitiye, povtornoye otkryitiye i neizvestnyij host-iskhod tipizirovanyi i annuliruyut prezhneye prinyatiye tam, gde menyayetsya proverennyij diapazon.
- Khotya byi odin perenosimyij navyik obyyavlyayet svoj tochnyij tip i poyavlyayetsya v core. Uzhe zaregistrirovannyij v `FUM-STEP-0125` celevoj agent-poluchatelj sinkhroniziruyet zerkaljnyij `master` s etim pokoleniyem, sozdayot rolevuyu vetku, obnaruzhivayet navyik i vosproizvodit obyyavlennuyu proverku yego primeneniya; dlya formyi `SKILL.md` dopolniteljno proveryayutsya putj `Инструменты/<имя>/SKILL.md`, nakhozhdeniye realpath vnutri checkout i chteniye svyazannyikh resursov.
- Gitlink celevogo agenta obnovlyayetsya toljko na proverennyij dochernij commit posle sinkhronizacii s core, a ne na PR-head obsjhego vklada; tot zhe CAS-kommit assembly obnovlyayet core-gitlink libo dokazyivayet yego tochnoye sovpadeniye s prinyatyim core OID. Promezhutochnoye sostoyaniye `принято_в_ядре_синхронизация_ребёнка_ожидается` perezhivayet vozobnovleniye.
- `fum-yadro` vyipolnyayet khotya byi odin korobochnyij shag i odin yavno naznachennyij shag inoj roli; `fum-optimizator` vyidayot pasport kandidata algoritmizacii, a `fum-pisatelj` stroit tekhnicheskoye samoopisaniye FUM v yavno vyibrannoj forme kanonicheskoj proizvodnoj dokumentacii libo opisaniya dlya adresata, ne prevrasjhaya rezuljtat v istochnik trebovanij.
- Svezhiye klonyi celevogo repozitoriya i assembly vosstanavlivayut tochnyiye prinyatyiye vershinyi, a otchyot razlichayet dokazannyij mekhanizm, nablyudayemuyu korrelyaciyu i ne dokazannuyu nezavisimostj modelej.
- Lyuboj nerazreshyonnyij vneshnij effekt, konflikt, prevyisheniye byudzheta ili proigrannyij CAS zavershayet progon tipizirovanno bez neuchtyonnoj publikacii; dokazannyij uspekh CAS celevogo ref integracii pri nezavershyonnom gitlink sokhranyayetsya kak otdeljnoye vozobnovlyayemoye sostoyaniye.

## Istochniki

- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0125 — realjnyij pul poduzlov v kompozicionnoj sborke](🟡-FUM-STEP-0125-podklyuchitj-realjnyij-pul-poduzlov-v-kompozicionnoj-sborke.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 03:53:39 MSK -->
<!-- content-sha256: sha256:3b0fd0419e0b0a87d5aa04e3a1be99917f6c5a6d5389127cd4beab33e903b180 -->
<!-- FUM-MD-RECENCY:END -->
