+++
schema_version = 1
card_id = "FUM-STEP-0098"
status = "completed"
+++
# Sokhranitj kanonicheskiye sobyitiya i dokazatj vosproizvedeniye

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj v `MemoryGeneration` neizmenyayemyij kanonicheskij zhurnal polnyikh tel prinyatyikh sobyitij libo samodostatochnyiye ssyilki na ikh adresuyemyij nositelj. Validator dolzhen iz seed i etogo zhurnala povtorno primenitj tochnuyu versiyu politiki, pereschitatj snimok, trassu i proyekciyu i otklonitj vnutrenne soglasovannoye, no ne vyivodimoye pokoleniye.

## Rezuljtat

`MemoryGeneration` perevedyon na skhemu `2` s yavnyim versionirovannyim pustyim seed, polnyim kumulyativnyim zhurnalom kanonicheskikh tel prinyatyikh sobyitij i otdeljnyimi SHA-256 seed, zhurnala i kanonicheskoj programmyi tekusjhego perekhoda. Prodolzheniye sokhranyayet tochnyij prefiks zhurnala i trassyi, neizmennostj prezhnikh zapisej i samodostatochno nesyot vsyu istoriyu ot seed.

Validator svyazyivayet sobyitiya s trassoj i proiskhozhdeniyem, povtorno ispolnyayet tochnuyu versiyu politiki `remember` i `compose` i sravnivayet vyivedennyiye snimok, trassu, proiskhozhdeniye zapisej i proyekciyu s sokhranyonnyimi artefaktami. Vnutrenne khyesh-soglasovannyiye poddelki obeikh operacij i nesvyazannyij khyesh tekusjhego perekhoda otklonyayutsya. Kumulyativnyij zhurnal boljshe transportnogo limita odnogo vkhoda prokhodit serializaciyu, podtverzhdeniye, vosstanovleniye i replay bez vneshnej fiksturyi, prezhnego chata ili novogo modeljnogo vyizova.

Zamorozhennyiye bajtyi realjnogo pokoleniya skhemyi `1` zakreplenyi izvestnyim SHA-256. Khranilisjhe yavno otklonyayet ikh do dekodirovaniya skhemyi `2` i ne izmenyayet ni istoricheskij fajl, ni `CURRENT`; molchalivaya migraciya isklyuchena. Zhurnal otklonyonnyikh kandidatov, mezhprocessnyij CAS, avarijnaya durability i yazyikonejtraljnyij bajtovyij profilj ostayutsya otdeljnyimi sleduyusjhimi shagami.

## Istochniki

- [iskhodnyij zapros o kanonicheskikh sobyitiyakh i samodostatochnom vosproizvedenii](../../Zhurnal/2026-07-27_22-17-40_MSK_sokhranitj-kanonicheskiye-sobyitiya-i-dokazatj-vosproizvedeniye/zapros.md)
- [iskhodnyij zapros ob integracii kriticheskogo analiza](../../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [Swift-prototip vosproizvodimogo popolneniya pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:36759892f2abb5e6c3fd473039ea7810a99e56f38d5b2d562ef14c3afdf274f0 -->
<!-- FUM-MD-RECENCY:END -->
