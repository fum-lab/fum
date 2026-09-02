+++
schema_version = 1
card_id = "FUM-STEP-0145"
status = "completed"
+++

# Zakrepitj pasport dereva vetvevyikh fork i reshenij moderatora

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj v proveryayemyij mnogoagentnyij prototip zakryityij versionirovannyij kontrakt odnogo pokoleniya [vetvevogo fork FUM](../../Glossarij/vetvevoj-fork-FUM.md), chistyij reduktor sostoyanij i validator resheniya roditeljskogo moderatora. Pervaya versiya dolzhna opisyivatj rovno dvukh detej ot proverennogo obsjhego iskhodnogo sostoyaniya, odnoznachnoye sootvetstviye kazhdogo fork odnoj pare repozitoriya i polnogo rabochego ref i zhivomu checkout, predel odnoj dopusjhennoj sessii-vladeljca, neaktivnuyu podgotovku obeikh host-privyazok, linejnoye prodolzheniye vnutri rebyonka, zamorozhennyiye rezuljtatyi i otdeljnoye resheniye togo zhe logicheskogo roditelya bez realjnyikh host-, Git- ili setevyikh effektov.

## Rezuljtat

Dobavlenyi tri zakryityiye skhemyi versii `1`: [pasport dereva](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/DerevoVetvevyikhForkov/skhema-pasporta-dereva-vetvevyikh-forkov-v1.json), [sostoyaniye pokoleniya](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/DerevoVetvevyikhForkov/skhema-sostoyaniya-pokoleniya-vetvevogo-forka-v1.json) i [neizmenyayemoye resheniye moderatora](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/DerevoVetvevyikhForkov/skhema-resheniya-moderatora-v1.json). Oni zakreplyayut odin logicheskij roditeljskij fork i togo zhe moderatora, otdeljnuyu popyitku moderacii, rovno dvukh detej ot dokazanno ekvivalentnoj bazyi, raznyiye polnyiye rabochiye refs i zhivyiye checkout, obsjhij format Git-obyyektov, khyeshi naznachenij i kriteriyev, konechnuyu glubinu, resursyi i polnomochiya bez mashinno-lokaljnyikh putej. Pasport do zapuska detej neizmenyayemo khranit toljko derevo proiskhozhdeniya; otdeljnyij integracionnyij graf prinadlezhit uzhe resheniyu i potomu ne perepisyivayet predaktivacionnyij pasport posle polucheniya rezuljtatov.

[Semanticheskij validator](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/KontraktDerevaVetvevyikhForkov.swift) tochno sveryayet tekusjheye pokoleniye s neizmenyayemyimi uzlami i rebrom sokhranyonnogo dereva. On zapresjhayet povtor paryi repozitoriya i ref, obsjhij checkout, vtoroj korenj, nekornevoj uzel bez yedinstvennogo roditelya, obsjhego rebyonka, povtornuyu razvilku, neizvestnyij konec rebra i cikl. Dopuski svyazanyi s tochnyimi repo/ref i vzaimoisklyuchayusjhimi pishusjhej i moderiruyusjhej rolyami; dochernij zhurnal trebuyet nepreryivnogo poryadka, odnoroditeljskikh perekhodov i odnogo prodolzheniya na kommit.

[Chistyij reduktor](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/ReduktorPokoleniyaVetvevyikhForkov.swift) provodit linejnoye ispolneniye cherez podgotovku paryi, sokhranyonnuyu globaljnuyu predaktivaciyu, yedinuyu aktivaciyu, osvobozhdeniye roditeljskoj sessii i FIFO, linejnoye ispolneniye detej, ozhidaniye i vosstanovlennuyu moderaciyu. Chastichnyij ili neizvestnyij otvet sokhranyayet tochnyiye identifikator i khyesh komandyi prezhnej popyitki i zapresjhayet novyij vyizov sozdaniya. Vozobnovleniye prinimayet toljko dokazateljstvo avtoritetnogo chteniya toj zhe popyitki libo yavnogo resheniya cheloveka; tochnyij povtor idempotenten, a izmenyonnyij povtor ili drugaya popyitka otklonyayutsya.

Opublikovannaya skhema sostoyaniya i tryokhdokumentnyij validator zakreplyayut terminaljnyij proverochnyij snimok s fazoj `разрешён` libo `неопределён`. Promezhutochnyiye fazyi susjhestvuyut kak neserializuyemaya value-modelj chistogo reduktora i ne proveryayutsya v versii `1` kak samostoyateljnyiye JSON-snimki; host-privyazki s priznakom neaktivnosti v terminaljnom snimke yavlyayutsya istoricheskimi svideteljstvami predaktivacii.

Dva rezuljtata zamorazhivayut tochnyiye fork, repozitorij, bazu, vershinu, diapazon, naznacheniye, kriterii, proverki, byudzhet i otdeljnyiye refs i sveryayutsya s vneshnimi khyesh-yakoryami. Resheniye okhvatyivayet oba tochnyikh rezuljtata i tipiziruyet shestj iskhodov: levyij, pravyij, sovmestimoye obyyedineniye, dorabotka v novom pokolenii naznacheniya, otkloneniye oboikh i neopredelyonnostj. Toljko otdeljnyij integrator pri sovpavshej faze, celi, ozhidayemoj baze i predispolniteljnom sostoyanii sravneniya poluchayet deklarativnoye razresheniye sravnitj i zamenitj. Dokument resheniya soderzhit rovno odno mnogoroditeljskoye rebro otdeljnogo integracionnogo grafa toljko dlya sovmestimogo obyyedineniya i ne soderzhit takogo rebra dlya ostaljnyikh iskhodov; vlozhennyij rezuljtat podnimayetsya k sleduyusjhemu moderatoru otdeljnyim khyeshirovannyim svideteljstvom.

[Avtonomnyiye TDD-fiksturyi i testyi](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Tests/FUMVerifiableMultiAgentContourTests/TestyiDerevaVetvevyikhForkov.swift) pokryivayut zakryitostj skhem, neizvestnyiye polya, nevernyiye tipyi i celyiye chisla, povtornyij klyuch, NFC, lokaljnyij putj, ref i OID, identichnosti i bazyi, vse narusheniya dvoichnogo dereva, resursnyiye granicyi, dopuski, prezhdevremennuyu ili chastichnuyu aktivaciyu, tochnoye vosstanovleniye, linejnostj detej, neizmenyayemostj rezuljtatov i resheniya, vse shestj iskhodov, otdeljnuyu integraciyu, proigrannoye sravneniye i kanonicheskij polozhiteljnyij prokhod.

## Granica rezuljtata

Skhemyi, reduktor, validator i fiksturyi rabotayut toljko nad peredannyimi znacheniyami. Oni ne vyizyivayut `create_thread`, ne sozdayut klonyi ili ocheredi, ne chitayut zhivoj host, ne vyipolnyayut Git-kommityi, `finish-clean`, setevoj vyizov, push, publikaciyu libo CAS-zapisj. Poetomu rezuljtat dokazyivayet zamknutyij determinirovannyij kontrakt pokoleniya, no ne fakticheskuyu mezhklonovuyu aktivaciyu i integraciyu.

Avtoritetnyij kornevoj reyestr uzlov, refs, checkout, vladeljcev i popyitok, realjnyiye host-privyazki, resursnyij dopusk, materializaciya rezuljtatov, ograzhdyonnyij ispolnitelj sravneniya i zamenyi, nezavisimoye revjyu i zhivaya priyomka ostayutsya posleduyusjhimi shagami. Trebovaniye o dereve vetvevyikh fork sokhranyayet status `🟡` do dokazateljstva etikh effektnyikh granic.

## Istochniki

- [iskhodnyij zapros 2026-08-12 18:43:09 MSK — Zakrepitj pasport dereva vetvevyikh fork i reshenij moderatora](../../Zhurnal/2026-08-12_18-43-09_MSK_zakrepitj-pasport-dereva-vetvevyikh-fork-i-reshenij-moderatora/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [trebovaniye o dereve vetvevyikh fork i roditeljskoj moderacii](../../Trebovaniya/🟡-derevo-vetvevyikh-fork-i-roditeljskaya-moderaciya.md)
- [FUM-STEP-0120 — pasport linejnoj cepochki](✅-FUM-STEP-0120-zakrepitj-pasport-delegirovaniya-konechnoj-cepochki-kartochek.md)
- [FUM-STEP-0121 — vozobnovlyayemoye ispolneniye dochernej cepochki](✅-FUM-STEP-0121-realizovatj-vozobnovlyayemoye-ispolneniye-cepochki-v-universaljnom-fork-poduzle.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 21:29:15 MSK -->
<!-- content-sha256: sha256:43452a3eeff9ed008580a26ec70a607542c5f762c68fbf9795e35c795f13aa55 -->
<!-- FUM-MD-RECENCY:END -->
