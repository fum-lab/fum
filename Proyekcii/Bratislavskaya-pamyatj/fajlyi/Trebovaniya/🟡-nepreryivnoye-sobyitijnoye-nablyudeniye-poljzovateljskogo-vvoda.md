# Nepreryivnoye sobyitijnoye nablyudeniye poljzovateljskogo vvoda

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0018 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna vo vremya rabotyi prinimatj razreshyonnyij chelovecheskij vvod kak uporyadochennyij potok [nablyudayemyikh vkhodnyikh signalov](../Glossarij/nablyudayemyij-vkhodnoj-signal.md), ne ozhidaya toljko otpravki otdeljnogo soobsjheniya-zadachi. Soobsjheniye ostayotsya odnoj vyisokourovnevoj agregirovannoj formoj vkhoda, no ne minimaljnoj yedinicej vzaimodejstviya: razreshyonnyiye sobyitiya interfejsa i podderzhivayemyikh ustrojstv dolzhnyi stanovitjsya dostupnyimi konturu po mere vozniknoveniya i peredavatj relevantnoye izmeneniye v [poljzovateljski perenapravlyayemyij agentskij cikl](🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md).

Nepreryivnostj vkhodnogo kontura ne oznachayet otdeljnyij vyizov LLM na kazhdoye fizicheskoye sobyitiye. Organ vospriyatiya mozhet filjtrovatj i agregirovatj potok, yesli poryadok, zaderzhka, poteri, granica agregacii i svyazj s dostupnyim iskhodnyim sloyem ostayutsya nablyudayemyimi. Samo nablyudeniye ne yavlyayetsya razresheniyem dolgovremenno khranitj, ispoljzovatj dlya obucheniya, eksportirovatj ili publikovatj vesj chuvstviteljnyij potok.

## Semanticheskiye svyazi

- **usilivayet:** [poljzovateljskoye perenapravleniye nepreryivnogo agentskogo cikla](🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) — pozvolyayet menyatj prodolzheniye po vkhodu, voznikshemu vnutri tekusjhej rabotyi, a ne toljko po granicam soobsjhenij-zadach.
- **dopolnyayet:** [versionirovannuyu pervichnuyu trassu sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — ispoljzuyet sobyitijnyij potok dlya operativnogo nablyudeniya, ne podmenyaya otdeljnyij kontrakt yego dolgovremennogo pervichnogo khraneniya.
- **zavisit ot:** [zasjhisjhyonnogo sbora chuvstviteljnogo vvoda](🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md) — nablyudeniye dopustimo toljko v yavno vklyuchyonnoj oblasti, s minimaljnyimi pravami, vidimyim sostoyaniyem i otzyivom razresheniya.

## Kriterii proverki

- determinirovannaya fikstura vvodit razreshyonnoye sobyitiye vo vremya dejstvuyusjhego cikla bez otpravki novogo soobsjheniya-zadachi, i sobyitiye postupayet v kontur s nablyudayemyimi poryadkom, vremenem, kanalom i proiskhozhdeniyem;
- relevantnoye sobyitiye libo agregirovannyij signal peredayotsya mekhanizmu perenapravleniya, a nerelevantnoye sobyitiye ne vyizyivayet bessoderzhateljnoj perestrojki plana;
- obyyedineniye, zaderzhka, dublikatyi, poterya, perepolneniye i protivodavleniye predstavlenyi yavno; agregirovannoye opisaniye sokhranyayet proveryayemuyu svyazj s dostupnyim iskhodnyim sloyem;
- chastyiye sobyitiya ne sozdayut bezuslovnyij modeljnyij vyizov na kazhdoye sobyitiye: politika filjtracii i agregacii imeyet nablyudayemyiye granicyi i vosproizvodimuyu proverku;
- vyiklyuchennyij, otozvannyij, zasjhisjhyonnyij ili ne otnosyasjhijsya k razreshyonnoj oblasti vvod ne popadayet v rabochij kontekst, a prekrasjheniye nablyudeniya ostavlyayet diagnostiruyemuyu, no ne soderzhateljnuyu granicu;
- otdeljnyiye razresheniya na operativnoye nablyudeniye, dolgovremennoye khraneniye, obucheniye, eksport i publikaciyu proveryayutsya razdeljno;
- diskretnyiye soobsjheniya tekusjhego Git + Codex-kontura i pervichnaya trassa klaviaturnogo prototipa sami po sebe ne zaschityivayutsya integrirovannyim sobyitijnyim vkhodom korobochnogo runtime.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano. Tekusjhij dokumentacionnyij prototip vidit chelovecheskij vvod preimusjhestvenno posle otpravki soobsjheniya-zadachi, a prototip fizicheskikh sostoyanij klavish otdeljno podtverzhdayet chastj pervichnogo sobyitijnogo potoka. Produktovyij most, kotoryij vo vremya dejstvuyusjhego cikla bezopasno prevrasjhayet razreshyonnyiye sobyitiya v yego nablyudeniya, yesjhyo ne realizovan.

Kartochka ne razreshayet skryityij globaljnyij perekhvat, obkhod sistemnoj zasjhityi, zapisj zasjhisjhyonnyikh polej, nablyudeniye drugikh lyudej bez polnomochij vladeljca ili nachalo korobochnoj stadii. Podderzhivayemyiye kanalyi, dopustimaya zaderzhka, politika agregacii i zhiznennyij cikl kazhdogo vida dannyikh opredelyayutsya otdeljnyimi realizaciyami i proverkami.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:84060272e72f708f6c0415caac60d2114eac0d7b26c881e79777c7d70a8f7471 -->
<!-- FUM-MD-RECENCY:END -->
