# Trebovaniya FUM

Etot katalog khranit atomarnyiye [kartochki trebovanij FUM](../Glossarij/kartochka-trebovaniya-FUM.md). Odna kartochka formuliruyet odno trebovaniye, dayot kriterii yego proverki i sokhranyayet putj k iskhodnomu zaprosu i materialu, iz kotorogo ono vyivedeno.

## Dejstvuyusjhij ekspluatacionnyij status

Tekusjhuyu zapisj repozitoriya reguliruyet ruchnaya posledovateljnaya skhema iz `AGENTS.md`: poljzovatelj sam zapuskayet odnu pishusjhuyu sessiyu v pervichnom checkout `refs/heads/master`, a posle yeyo yedinstvennogo itogovogo kommita sleduyusjhaya zadacha avtomaticheski ne sozdayotsya. Simvol sostoyaniya v imeni kartochki prodolzhayet pokazyivatj dostignutuyu zrelostj ili prezhnyuyu realizaciyu trebovaniya, no sam po sebe ne aktiviruyet runtime-marshrut.

Kartochki continuation, FIFO, vetochnogo selector, paralleljnyikh pisatelej, reviewer/integrator/candidate/CAS i sbrosa ikh runtime-sostoyaniya sokhranenyi kak otlozhennaya arkhitekturnaya narabotka. Ikh imperativnyij tekst chitayetsya toljko vnutri etoj istoricheskoj ili celevoj granicyi i ne dayot obyichnoj zadache polnomochij zapuskatj konvejyer, sozdavatj prodolzheniye, menyatj pool/refs libo publikovatj rezuljtat. Vozobnovleniye lyubogo takogo trebovaniya trebuyet otdeljnogo poljzovateljskogo zaprosa i novogo soglasovannogo perekhoda pravil.

Kazhdaya kartochka imeyet odin neizmenyayemyij identifikator `FUM-REQ-NNNN` v mashinnom markere `FUM-REQUIREMENT-ID` srazu posle zagolovka. Identifikator naznachayetsya odin raz, ne vyivoditsya iz polozheniya v indekse, zagolovka, imeni fajla ili statusa i ne menyayetsya pri posleduyusjhem `git mv`. Osvobodivshiyesya nomera povtorno ne ispoljzuyutsya.

[Semanticheskiye svyazi trebovanij FUM](../Glossarij/semanticheskaya-svyazj-trebovanij-FUM.md) oformlyayutsya obyichnyimi lokaljnyimi Markdown-ssyilkami v razdele `Семантические связи` kazhdoj kartochki. Odna svyazj zapisyivayetsya s obeikh storon soglasovannoj paroj otnoshenij; eto pozvolyayet chitatj graf v lyubom napravlenii i avtomaticheski proveryatj yego celostnostj. Obsjhaya tema ili obsjhij istochnik sami po sebe nedostatochnyi dlya svyazi.

Ispoljzuyetsya minimaljnyij rasshiryayemyij slovarj otnoshenij:

| Pryamoye otnosheniye  | Obratnoye otnosheniye | Kogda primenyayetsya                                                               |
| ----------------- | ------------------ | ------------------------------------------------------------------------------- |
| `зависит от`      | `требуется для`    | pervoye trebovaniye nevozmozhno ili bessmyislenno vyipolnitj bez vtorogo             |
| `является частью` | `состоит из`       | pervoye trebovaniye yavlyayetsya sostavnoj chastjyu boleye krupnogo trebovaniya           |
| `дополняет`       | `дополняется`      | trebovaniya dayut sovmestnyij rezuljtat, no kazhdoye sokhranyayet samostoyateljnyij smyisl |
| `усиливает`       | `усиливается`      | pervoye trebovaniye dobavlyayet boleye stroguyu garantiyu, ne podmenyaya bazovoye         |

Novyij tip dobavlyayetsya toljko vmeste s pervyim soderzhateljnyim primerom, opredeleniyem oblasti primeneniya i obratnyim tipom. V kartochke odna stroka opisyivayet odnu svyazj: zhirnaya metka otnosheniya, lokaljnaya ssyilka na trebovaniye i kratkoye osnovaniye posle tire. Inline-ssyilki v formulirovke i kriteriyakh mogut poyasnyatj tekst, no ne zamenyayut tipizirovannuyu zapisj.

Pervyij emodzi imeni fajla pokazyivayet [status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md):

- `⚪` — chernovik: formulirovka yesjhyo trebuyet resheniya;
- `🟡` — prinyato i zaplanirovano: trebovaniye zafiksirovano, no proverennaya realizaciya ne zavershena;
- `🚧` — realizuyetsya;
- `✅` — realizovano i podtverzhdeno ukazannoj v kartochke proverkoj;
- `⛔` — zablokirovano;
- `🗑️` — snyato s sokhraneniyem istorii i osnovaniya.

Status menyayetsya pereimenovaniyem fajla cherez `git mv`. Emodzi ne zamenyayet soderzhateljnoye osnovaniye: kartochka so statusom `✅` obyazana ssyilatjsya na proverku, a `⛔` i `🗑️` — obyyasnyatj blokirovku ili snyatiye.

## Polnostjyu kastomnyij interfejs poverkh macOS

- `FUM-REQ-0001` — [🟡 Polnoekrannoye prilozheniye bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md)
- `FUM-REQ-0002` — [🟡 Otrisovka interfejsa cherez Metal](🟡-otrisovka-interfejsa-cherez-Metal.md)
- `FUM-REQ-0003` — [🟡 Skryitiye Dock i stroki menyu](🟡-skryitiye-Dock-i-stroki-menyu.md)
- `FUM-REQ-0004` — [🟡 Avtomaticheskij vkhod v vyidelennuyu uchyotnuyu zapisj](🟡-avtomaticheskij-vkhod-v-vyidelennuyu-uchyotnuyu-zapisj.md)
- `FUM-REQ-0005` — [🟡 Avtozapusk interfejsa](🟡-avtozapusk-interfejsa.md)
- `FUM-REQ-0006` — [🟡 Fonovyij servis vyichislenij i vosstanovleniya interfejsa](🟡-fonovyij-servis-vyichislenij-i-vosstanovleniya-interfejsa.md)
- `FUM-REQ-0007` — [🟡 Upravlyayemyij zhyostkij kiosk-rezhim](🟡-upravlyayemyij-zhyostkij-kiosk-rezhim.md)

## Sobyitiya ustrojstv vvoda

- `FUM-REQ-0008` — [🚧 Maksimaljno syiraya zapisj sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md)
- `FUM-REQ-0009` — [🚧 Versionirovannaya pervichnaya trassa sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md)
- `FUM-REQ-0010` — [🚧 Fizicheskiye perekhodyi klavish](🚧-fizicheskiye-perekhodyi-klavish.md)
- `FUM-REQ-0011` — [🟡 Maksimaljno syiraya zapisj sobyitij myishi](🟡-maksimaljno-syiraya-zapisj-sobyitij-myishi.md)
- `FUM-REQ-0012` — [🟡 Maksimaljno syiraya zapisj sobyitij kontaktnyikh poverkhnostej](🟡-maksimaljno-syiraya-zapisj-sobyitij-kontaktnyikh-poverkhnostej.md)
- `FUM-REQ-0013` — [🟡 Maksimaljno syiraya zapisj sobyitij perjyevyikh ustrojstv](🟡-maksimaljno-syiraya-zapisj-sobyitij-perjyevyikh-ustrojstv.md)
- `FUM-REQ-0014` — [🟡 Zasjhisjhyonnyij sbor chuvstviteljnogo vvoda](🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md)

## Agentskij cikl i poljzovateljskij vvod

- `FUM-REQ-0017` — [🟡 Poljzovateljskoye perenapravleniye nepreryivnogo agentskogo cikla](🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md)
- `FUM-REQ-0018` — [🟡 Nepreryivnoye sobyitijnoye nablyudeniye poljzovateljskogo vvoda](🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md)
- `FUM-REQ-0029` — [✅ Skvoznoj proveryayemyij odnoagentnyij epizod FUM](✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md)
- `FUM-REQ-0035` — [🟡 Avtonomnoye modeljnoye prodolzheniye pri ozhidanii podtverzhdeniya](🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)

## Nachaljnyij korobochnyij Swift-kontur

- `FUM-REQ-0019` — [✅ Bezokonnyij Swift-kontur pervogo korobochnogo prototipa](✅-bezokonnyij-Swift-kontur-pervogo-korobochnogo-prototipa.md)
- `FUM-REQ-0020` — [🚧 Vosproizvodimoye shtatnoye popolneniye pamyati](🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- `FUM-REQ-0021` — [🟡 GUI kak proyekciya vnutrennej pamyati i ispolneniya](🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md)
- `FUM-REQ-0038` — [🟡 Prototipyi kak testyi realizacii kornevogo yadra FUM](🟡-prototipyi-kak-testyi-realizacii-kornevogo-yadra-FUM.md)

## Pamyatj i yazyikovyiye proyekcii

- `FUM-REQ-0037` — [✅ Paralleljnaya bratislavskaya proyekciya pamyati FUM](✅-paralleljnaya-bratislavskaya-proyekciya-pamyati-FUM.md)

## Pervyij produktovyij URL-srez

- `FUM-REQ-0031` — [🟡 Bezopasnyij priyom publichnogo HTML-URL](🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md)
- `FUM-REQ-0032` — [🟡 Privyazannoye podtverzhdeniye i minimaljnyiye prava priyoma istochnika](🟡-privyazannoye-podtverzhdeniye-i-minimaljnyiye-prava-priyoma-istochnika.md)
- `FUM-REQ-0033` — [🟡 Produktovoye proiskhozhdeniye prinyatogo istochnika](🟡-produktovoye-proiskhozhdeniye-prinyatogo-istochnika.md)
- `FUM-REQ-0034` — [🟡 Atomarnoye prinyatiye snimka i proiskhozhdeniya istochnika](🟡-atomarnoye-prinyatiye-snimka-i-proiskhozhdeniya-istochnika.md)

## Mnogoagentnoye myishleniye

- `FUM-REQ-0022` — [🚧 Proveryayemyij mnogoagentnyij kontur FUM](🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md)
- `FUM-REQ-0024` — [✅ Kommitiruyemyiye vkladyi pishusjhikh poduzlov FUM](✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md)
- `FUM-REQ-0025` — [✅ Izolirovannoye paralleljnoye ispolneniye i proveryayemaya integraciya](✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md)
- `FUM-REQ-0026` — [✅ Ogranichennoye avtomaticheskoye razresheniye Git-konfliktov](✅-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md)
- `FUM-REQ-0027` — [✅ Repozitornaya kompoziciya dolgovechnyikh poduzlov i proyektov](✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- `FUM-REQ-0036` — [🟡 Upravlyayemoye ispolneniye cepochek universaljnyimi fork-poduzlami](🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- `FUM-REQ-0043` — [🟡 Derevo vetvevyikh fork i roditeljskaya moderaciya](🟡-derevo-vetvevyikh-fork-i-roditeljskaya-moderaciya.md)

## Planirovaniye i otbor

- `FUM-REQ-0015` — [✅ Atomarnyiye kartochki planovyikh shagov](✅-atomarnyiye-kartochki-planovyikh-shagov.md)
- `FUM-REQ-0016` — [✅ Vyibor sleduyusjhego shaga vetki iz kartochek shagov](✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md)
- `FUM-REQ-0023` — [🚧 Kontekstno posiljnyiye ispolnyayemyiye shagi](🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md)
- `FUM-REQ-0028` — [🗑️ Universaljnaya dispetcherizaciya periodicheskikh avtomatizacij](🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- `FUM-REQ-0030` — [🟡 Sravniteljnaya eksperimentaljnaya priyomka preimusjhestv FUM](🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md)
- `FUM-REQ-0039` — [🚧 Shtatnyij sbros FIFO-ocheredi i rabochej kopii](🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)
- `FUM-REQ-0040` — [🚧 Vetochnyiye cepochki shagov i zaversheniye smoke-check kommitom](🚧-vetochnyiye-cepochki-shagov-i-zaversheniye-smoke-check-kommitom.md)
- `FUM-REQ-0041` — [✅ Podtverzhdayemyij ruchnoj sbros FIFO k tekusjhemu HEAD](✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md)
- `FUM-REQ-0042` — [✅ Obyazateljnoye prodolzheniye Git-vetki posle kommita](✅-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-10 10:19:59 MSK — Dobavitj prostoj sbros FIFO k tekusjhemu HEAD](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-08-07 20:34:22 MSK — Dobavitj shtatnyij sbros ocheredi](../Zhurnal/2026-08-07_20-34-22_MSK_dobavitj-shtatnyij-sbros-ocheredi/zapros.md)
- [iskhodnyij zapros 2026-08-05 20:01:32 MSK — Zakrepitj prototipyi kak testyi i sozdatj kartochku ozhidaniya ocheredi](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/zapros.md)
- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-28 20:06:05 MSK — Dorabotatj pasport korobochnoj stadii i pervogo URL-sreza po auditu](../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:10:35 MSK — Razreshitj nachaljnuyu korobochnuyu FUM bez GUI cherez Codex](../Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK](../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-14 20:33:47 MSK](../Zhurnal/2026-07-14_20-33-47_MSK_sozdatj-kartochki-trebovanij-k-interfejsu/zapros.md)
- [iskhodnyij zapros 2026-07-16 16:01:58 MSK](../Zhurnal/2026-07-16_16-01-58_MSK_dobavitj-semanticheskiye-ssyilki-v-kartochki-trebovanij/zapros.md)
- [iskhodnyij zapros 2026-07-16 21:49:27 MSK](../Zhurnal/2026-07-16_21-49-27_MSK_tipizirovatj-semanticheskiye-svyazi-trebovanij/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:41:27 MSK](../Zhurnal/2026-07-17_09-41-27_MSK_utochnitj-razlicheniye-nazhatiya-i-otpuskaniya-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:07:09 MSK](../Zhurnal/2026-07-17_10-07-09_MSK_razlichatj-fazyi-modifikatorov-i-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:40:21 MSK](../Zhurnal/2026-07-17_10-40-21_MSK_sozdatj-prototip-fizicheskikh-sostoyanij-klavish/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-20 21:22:17 MSK](../Zhurnal/2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [arkhivirovannyij dialog «Zapusk kastomnogo interfejsa»](../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:07a989a8eeb3037bc6259b69d5171e78cae8d1c26944a8a50068d4c61d1594ba -->
<!-- FUM-MD-RECENCY:END -->
