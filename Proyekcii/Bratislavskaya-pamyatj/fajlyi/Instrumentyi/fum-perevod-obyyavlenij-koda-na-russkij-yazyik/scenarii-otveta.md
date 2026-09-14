# Zakryityij format scenariyev otveta

[Inventarj obyyavlenij](SKILL.md) podderzhivayet chetyire obyichnyikh UTF-8-fajla CommonJS, sokhranyonnyikh v postavke otveta zadachi. Konechnyij nabor polnyikh putej khranitsya v `пути_сценариев` modulya [razbora](scripts/razbor_scenariya.py); [politika proyekcii](../fum-bratislavskaya-proyekciya-pamyati/kontrakt-v2.json) i yeyo skhema povtoryayut etot tochnyij nabor. Simvolicheskaya ssyilka v lyubom komponente puti, inoj registr, vlozhennyij dvojnik i sosednij fajl zakryivayut dopusk. Suffiks `.cjs` sokhranyayetsya otdeljno ot preobrazovaniya osnovyi imeni; bajtyi iskhodnika ne perevodyatsya.

Razbor potreblyayet vesj potok tokenov, vklyuchaya tela vlozhennyikh funkcij, znacheniya po umolchaniyu i obe storonyi vyirazhenij. Uchityivayutsya obyyavleniya `const` i `let`, imena funkcij, parametryi, vlozhennyiye obyyektnyiye i massivnyiye svyazyivaniya, ostatochnyiye parametryi, strelochnyiye funkcii, parametryi `catch`, peremennyiye ciklov, polya obyyektov i imenovannyiye prisvaivaniya. Zapisj soderzhit imya, rolj, klass, istochnik isklyucheniya i koordinatyi v tochnom tekste. CRLF schitayetsya odnim perevodom stroki; CR, LF i oba razdelitelya Unicode zavershayut strochnyij kommentarij.

Podyyazyik vklyuchayet bloki, uslovnyiye operatoryi, `while`, `for` s obyyavleniyem, obrabotku oshibok, vozvrat i vyibros, vyizovyi, chteniye polej i indeksov, obyichnyiye literalyi, massivyi, obyyektyi i primenyayemyiye arifmeticheskiye i logicheskiye operacii. Obyazateljnyiye tochki s zapyatoj zapisyivayutsya yavno. Avtomaticheskaya vstavka posle `return`, perevod stroki posle `async`, klassyi, generatoryi, metodyi obyyektov, metki, shablonnyiye stroki, ekranirovannyiye identifikatoryi, mnogostrochnyiye strokovyiye prodolzheniya, strokovyiye i vyichislyayemyiye klyuchi obyyektov, destrukturiruyusjhiye prisvaivaniya i ciklyi bez obyyavleniya ne podderzhanyi. Neizvestnyij token ili konstrukciya zakryivayut dopusk celogo fajla.

Vyichislyayemaya zapisj po indeksu s identifikatorom opisyivayet dinamicheskij klyuch; ona ne obyyavlyayet staticheskoye imya polya. Zapisj po literaljnomu indeksu, vklyuchaya skobki vokrug literala, zakryita. Analiz ne ispolnyayet programmu i ne dokazyivayet znacheniya dinamicheskikh klyuchej, povedeniye `require` ili vyizyivayemyikh funkcij. Eto ogranichennyij sintaksicheskij inventarj; samostoyateljnaya proverka povedeniya scenariyev sokhranyayetsya.

Vneshneye imya ne razreshayet odnoimyonnoye sobstvennoye svyazyivaniye. Dlya polej literala obyyekta isklyucheniye trebuyet polnoj formyi iz konechnogo nabora `формы_внешних_объектов`, bez povtornyikh klyuchej i nezaregistrirovannyikh razvyortok. Formyi otnosyatsya k [kontraktu otveta](../../Proyektyi/rabochij-kontekst/kontraktyi/opisaniye-otveta.json), [kontraktam sredyi i privatnogo kyesha](../fum-svyaznostj-rabochej-sessii/kompaktnyij-otvet-zadachi.md) i imenam parametrov standartnyikh API Node.js. Chteniye klyucha pri destrukturizacii otdeleno ot novogo svyazyivaniya. Isklyucheniya prisvaivanij `module.exports` i `process.exitCode` trebuyut imenno etoj polnoj cepochki ot izvestnogo kornya; odnoimyonnoye pole rezuljtata vyizova ne poluchayet isklyucheniya.

Polya `симулированный_api` i `живые_api` ostayutsya tochnyimi klyuchami uzhe opublikovannogo profilya versii 1. Ikh otdeljnyij klass `закреплённый-контракт` svyazan s materialom kommita `2e01e5dc9a130ea0fb2f6c10514d7db56817361b`; eto ne razresheniye vvoditj novyiye latinskiye sobstvennyiye imena. Reyestr form i istochnikov konechen i nakhoditsya v module razbora. Dobavleniye formyi trebuyet konkretnogo kontrakta i regressii, a neizvestnaya forma sokhranyayet polya v sobstvennom ostatke.

Vtoroj sintaksicheskij barjyer — otdeljnyij process Node.js s proverkoj CommonJS cherez standartnyij vvod. Scenarij ne ispolnyayetsya; iz okruzheniya ne nasleduyutsya parametryi zagruzki Node. Ogranicheniya vkhoda: 262 144 bajta UTF-8, 65 536 tokenov, 64 urovnya skobok, 10 sekund na proverku Node. Sboj vneshnego processa ne prevrasjhayetsya v uspeshnyij razbor. Stroki diagnostiki iskhodnogo koda naruzhu ne peredayutsya.

Pereimenovaniye podderzhivayet svyazyivaniya s yavnoj kartoj i proverennyim khyeshem. Klyuchi polej, member-dostup, stroki i kommentarii zasjhisjhenyi. Sokrasjhyonnoye svyazyivaniye sokhranyayet iskhodnyij klyuch cherez yavnyij psevdonim. Pereimenovaniye sobstvennyikh polej i sokrasjhyonnyikh vneshnikh polej otklonyayetsya do zapisi: dlya nego nyineshnij razbor ne dokazyivayet vladeljca kazhdogo upotrebleniya. Novyij rezuljtat snova prokhodit oba sintaksicheskikh barjyera.

[Adresnyiye regressii](tests/test_scenarij_otveta.py) proveryayut opasnyiye i dopustimyiye formyi. [Profilj](tests/izmeritj_scenarij_otveta.py) semj raz izmeryayet leksiku, sobstvennyij razbor, polnyij razbor s Node i klassifikaciyu proyekcii na tekh zhe chetyiryokh otkryityikh iskhodnikakh; zatem povtoryayet izmereniye toj zhe realizacii. Stadii perekryivayutsya i ne summiruyutsya. Porog odnogo polnogo obkhoda chetyiryokh fajlov — odna sekunda; profilj ne izmeryayet ispolneniye adaptera ili vsyu proyekciyu repozitoriya.

## Proiskhozhdeniye

- [Porucheniye, utochneniye chetyiryokh putej i priyomka](../../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/zapros.md).
- [Izmereniya i resheniya etapa](../../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 19:41:23 MSK -->
<!-- content-sha256: sha256:342c807684cf9d20c669c3fd0a03855f31f298158d887ed602b96850023bb888 -->
<!-- FUM-MD-RECENCY:END -->
