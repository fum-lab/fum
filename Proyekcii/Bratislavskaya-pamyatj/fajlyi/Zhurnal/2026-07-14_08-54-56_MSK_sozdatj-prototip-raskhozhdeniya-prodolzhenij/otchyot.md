# Otchyot 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij

Rabochaya sessiya perevela ideyu tenevogo sravneniya prodolzhenij iz trebovaniya v dejstvuyusjhij issledovateljskij Swift-prototip. Chelovek redaktiruyet odin lokaljnyij tekstovyij fajl, ogranichennyij suffiksno-kontekstnyij indeks obnovlyayetsya po potoku, a obyazateljnaya lokaljnaya LLM nezavisimo prodolzhayet zamorozhennyij prefiks. Soderzhimoye modeljnoj vetvi skryito do poyavleniya fakticheskogo prodolzheniya cheloveka; zatem dve vetvi raskryivayutsya vmeste s odinakovo postroyennyimi strukturami i izmerimyim raskhozhdeniyem.

Prototip namerenno ne vyidayot predskazateljnuyu oshibku za pryamoj dostup k myishleniyu. Yego nablyudayemyij rezuljtat - raznica mezhdu tem, kak dostupnyij prefiks prodolzhila konkretnaya konfiguraciya lokaljnoj modeli, i tem, kak tot zhe prefiks prodolzhil konkretnyij chelovek. Bajtovyij gorizont, tochnyiye UTF-8-kontekstyi i otsutstviye logprobs ostayutsya vidimyimi ogranicheniyami baseline.

## Ispolnyayemyij rezuljtat

V [pasporte tenevogo redaktora](../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md) zafiksirovanyi komandyi zapuska, granicyi privatnosti i status. Swift-paket soderzhit bibliotechnoye yadro, macOS-redaktor na `NSTextView`, headless-probnik lokaljnoj LLM i avtonomnyiye testyi. Byistryij putj dopisyivaniya obnovlyayet indeks po tochnoj deljte; proizvoljnyiye pravki zapuskayut otmenyayemuyu serializovannuyu peresborku. Obe strukturyi prodolzheniya rastut po mere postupleniya bajtov, a zavershyonnaya para sravnivayetsya tekstovyimi i strukturnyimi metrikami.

Modeljnyij adapter ne ispoljzuyet shell, peredayot kontekst cherez stdin, prinuditeljno napravlyayet Ollama na loopback, predvariteljno proveryayet nalichiye modeli i ne pozvolyayet otsutstvuyusjhej modeli zagruzitjsya avtomaticheski. Audit dobavil stroguyu proverku imeni modeli i potokovuyu normalizaciyu stdout: spravka CLI, pustoj vyivod i polnoye libo usechyonnoye ekho prefiksa ne stanovyatsya lozhnyim prodolzheniyem.

Sokhraneniye JSONL-trassyi vyiklyucheno po umolchaniyu. Pri yavnom vklyuchenii sokhranyayutsya toljko metadannyiye kontroljnoj tochki, dva korotkikh prodolzheniya i metriki, no ne kontekst modeli; sluzhebnyij katalog i fajl poluchayut ogranichennyiye POSIX-prava. Udaleniye kasayetsya toljko fajla etogo prototipa.

## Proverennyij lokaljnyij kontur

Posle krasnyikh TDD-faz itogovyij nabor proshyol 30 Swift-testov i sobral oba ispolnyayemyikh produkta. Realjnyij headless-progon ispoljzoval vremenno podklyuchyonnuyu raneye zagruzhennuyu Qwen3 0.6B Q8 cherez Ollama 0.31.1 i poluchil samostoyateljnoye russkoyazyichnoye prodolzheniye; lokaljnyij runtime soobsjhil loopback i offline inference. GUI otkryil proverochnyij fajl, avtomaticheski sozdal kontroljnuyu tochku i pri nastrojke po umolchaniyu ne sozdal trassu. Vremennaya modelj i proverochnyiye materialyi posle priyomki udalenyi.

## Arkhitekturnaya granica

Eto pervyij dejstvuyusjhij vertikaljnyij srez korobochnoj stadii v tekusjhej osnovnoj linii, no ne vsya korobochnaya FUM. On ne realizuyet poisk po pamyati, obsjhij vvod namereniya, podtverzhdeniye dejstvij, avtomatizacii, Git-zaversheniye rabochej sessii ili polnyij agentskij cikl. V planirovanii vyipolnen toljko vyibor pervogo ustojchivogo primera dlya papki prototipov; shirokiye predlozheniya ob operatornoj pamyati, chistom modeljnom shage, lokaljnom uzle i yedinom prilozhenii ostayutsya aktualjnyimi.

## Prodolzheniya

- Dobavitj veroyatnostnyij lokaljnyij provider s logprobs i vosproizvodimoj identichnostjyu vesov, runtime, parametrov i seed.
- Provesti benchmark boljshikh fajlov i dliteljnyiye poljzovateljskiye sessii s proizvoljnyimi pravkami i bezopasnyim zaversheniyem nesokhranyonnogo dokumenta.
- Sravnitj serii khronologicheski razdelyonnyikh tenevyikh tochek, zatem dobavitj personalizirovannyij otdelyayemyij sloj i grafemnyiye, tokennyiye, redaktorskiye i smyislovyiye urovni.
- Otdeljno proveritj vidimoye avtodopolneniye i yego prichinnoye vliyaniye, ne smeshivaya pomosjhj cheloveku s nezavisimoj tenevoj ocenkoj.

## Proverki

- `swift test` proshyol 30 testov bez oshibok i sobral biblioteku, GUI i headless-probnik.
- Realjnyij lokaljnyij probe i zapusk GUI proshli; vyiklyuchennaya po umolchaniyu trassa ne sozdavalasj.
- Planovyij reyestr, recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian peresobranyi i proverenyi.
- `git diff --check` i `fum-session-coherence` zavershilisj uspeshno.
- Polnyij `fum-smoke-check` proshyol 14 shagov i 69 testov devyati lokaljnyikh avtomatizacij.

## Istochniki

- [iskhodnyij zapros 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij](zapros.md)
- [iskhodnyij zapros 2026-07-14 01:40:47 MSK - Sravnitj prodolzheniye LLM s naborom cheloveka](../2026-07-14_01-40-47_MSK_sravnitj-prodolzheniye-LLM-s-naborom-cheloveka/zapros.md)

## Opornyiye materialyi

- [Obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](../../Dokumentaciya/08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)
- [Vnutrenniye modeli drugikh uzlov](../../Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md)
- [Lokaljnyij agent FUM na vyidelennoj mashine](../../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Potokovaya samostrukturizaciya FUM](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md)
- [Stadiya korobochnoj realizacii FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:fa5fc2536b0db517a99b80660eaf8e3d8372993d9c6f84aaad12681ec313b318 -->
<!-- FUM-MD-RECENCY:END -->
