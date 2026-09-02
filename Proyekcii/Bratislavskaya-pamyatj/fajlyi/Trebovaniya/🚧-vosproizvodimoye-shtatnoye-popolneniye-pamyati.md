# Vosproizvodimoye shtatnoye popolneniye pamyati

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0020 -->

Korobochnyij prototip dolzhen prinimatj versionirovannyiye sobyitiya cherez [shtatnoye popolneniye pamyati FUM](../Glossarij/shtatnoye-popolneniye-pamyati-FUM.md) i sokhranyatj polnyiye kanonicheskiye tela prinyatyikh i otklonyonnyikh sobyitij libo ikh neizmenyayemyiye adresuyemyiye nositeli. Snimok, proiskhozhdeniye i nablyudayemaya trassa dolzhnyi povtorno vyivoditjsya iz seed i sobyitij po tochnyim versiyam politiki i reduktorov; odnikh khyeshej i identifikatorov dlya etoj garantii nedostatochno.

## Semanticheskiye svyazi

- **zavisit ot:** [bezokonnogo Swift-kontura pervogo korobochnogo prototipa](✅-bezokonnyij-Swift-kontur-pervogo-korobochnogo-prototipa.md) — perekhodam pamyati nuzhen minimaljnyij sobstvennyij ispolnyayemyij nositelj.
- **trebuyetsya dlya:** [GUI kak proyekcii vnutrennej pamyati i ispolneniya](🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md) — predstavleniye neljzya vosproizvodimo vyivesti bez kanonicheskogo sostoyaniya i proiskhozhdeniya perekhodov.
- **trebuyetsya dlya:** [skvoznogo proveryayemogo odnoagentnogo epizoda FUM](✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md) — prervannyij cikl dolzhen vozobnovlyatjsya iz samodostatochnogo podtverzhdyonnogo sostoyaniya.
- **dopolnyayetsya:** [paralleljnoj bratislavskoj proyekciyej pamyati FUM](✅-paralleljnaya-bratislavskaya-proyekciya-pamyati-FUM.md) — otdeljnaya vosproizvodimaya yazyikovaya proyekciya okhvatyivayet repozitornoye soderzhimoye i polnyij putj, ne izmenyaya kanonicheskiye bajtyi produktovyikh sobyitij i snimkov.

## Kriterii proverki

- seed, sobyitiya i politika imeyut yavnyiye versii i stabiljnyiye identifikatoryi;
- gotovyij ozhidayemyij snimok ne ispoljzuyetsya kak sposob napolneniya pamyati;
- prinyatyiye i otklonyonnyiye sobyitiya nablyudayemyi vmeste s proiskhozhdeniyem i prichinoj iskhoda;
- podtverzhdyonnoye pokoleniye khranit polnyiye kanonicheskiye tela prinyatyikh sobyitij ili proveryayemo adresuyet ikh neizmenyayemyij nositelj; khyesh ne zamenyayet telo sobyitiya;
- [vosproizvedeniye prinyatogo epizoda FUM](../Glossarij/vosproizvedeniye-prinyatogo-epizoda-FUM.md) iz seed i sokhranyonnogo zhurnala bez vneshnej fiksturyi i novogo modeljnogo vyizova povtorno vyichislyayet snimok, trassu i proyekciyu i sravnivayet ikh s sokhranyonnyimi proizvodnyimi artefaktami;
- vosstanovleniye ot podtverzhdyonnogo pokoleniya i polnoye vosproizvedeniye skhodyatsya k odnomu kanonicheskomu rezuljtatu;
- dva konkuriruyusjhikh processa ot odnogo roditelya publikuyut novyij ukazatelj cherez linearizuyemyij compare-and-swap: rovno odin uspevayet, a vtoroj poluchayet konflikt bez poteri pervogo rezuljtata;
- urovenj garantii otdelyayet logicheskuyu atomarnostj, avariyu processa i poteryu pitaniya; power-loss durability zayavlyayetsya toljko posle yavnogo protokola sinkhronizacii i sootvetstvuyusjhej avarijnoj priyomki;
- kanonicheskiye bajtyi zadanyi versionnyim yazyikonejtraljnyim profilem, etalonnyimi vektorami i ne meneye chem dvumya soglasovannyimi realizaciyami;
- povrezhdyonnoye ili nesovmestimoye pokoleniye otklonyayetsya bez molchalivoj poteri uzhe podtverzhdyonnoj pamyati.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: [SwiftPM-prototip](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) sokhranyayet v pokolenii yavnyij seed i polnyij zhurnal prinyatyikh sobyitij, samodostatochno povtorno ispolnyayet `remember` i `compose`, sravnivayet snimok, trassu, proiskhozhdeniye i proyekciyu. On linearizuyet publikaciyu `CURRENT` mezhdu sotrudnichayusjhimi processami i podtverzhdayet process-crash consistency na vosjmi `SIGKILL`-tochkakh tekusjhego lokaljnogo macOS-stenda. [Profilj `fum.memory.canonical-json.v1`](../Dokumentaciya/47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md), obsjhiye golden vectors i soglasovannyiye Swift- i Python-realizacii zakreplyayut yazyikonejtraljnyiye bajtyi i SHA-256. Zhurnal otklonyonnyikh kandidatov, power-loss durability i chteniye ili preobrazovaniye prezhnikh skhem yesjhyo ne podtverzhdenyi, poetomu trebovaniye ostayotsya nezavershyonnyim.

## Istochniki trebovanij

- [iskhodnyij zapros o yazyikonejtraljnom kanonicheskom protokole pamyati](../Zhurnal/2026-07-28_08-47-18_MSK_zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati/zapros.md)
- [iskhodnyij zapros ob avarijnoj soglasovannosti khranilisjha pamyati](../Zhurnal/2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- [iskhodnyij zapros o mezhprocessnom CAS ukazatelya pamyati](../Zhurnal/2026-07-28_00-54-15_MSK_dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati/zapros.md)
- [iskhodnyij zapros o kanonicheskikh sobyitiyakh i samodostatochnom vosproizvedenii](../Zhurnal/2026-07-27_22-17-40_MSK_sokhranitj-kanonicheskiye-sobyitiya-i-dokazatj-vosproizvedeniye/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [pasport nachaljnogo korobochnogo prototipa FUM](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:113fb53616634137330ff59ab356c94def1ee5811e2d9bcd9be29097f4ce30bb -->
<!-- FUM-MD-RECENCY:END -->
