# Pervyij segment kontejnera nablyudenij

Avtonomnyij SwiftPM-paket dlya macOS 14+, ne podklyuchyonnyij k prilozheniyu ili datchikam FUM. Odin yavno peredannyij katalog soderzhit odin fajl segment.fumobs. Korenj dolzhen susjhestvovatj, prinadlezhatj tekusjhemu poljzovatelyu, ne razreshatj zapisj gruppe/ostaljnyim i imetj fizicheskij absolyutnyij putj bez simvolicheskikh ssyilok. Dannyiye po umolchaniyu niotkuda ne chitayutsya.

## Podtverzhdeniye i vosstanovleniye

Nablyudeniye sostoit iz stabiljnogo identifikatora, tipa, versii tipa, istochnika, vremeni, neprozrachnoj specifikacii i syiryikh bajtov. Neizvestnyij tip sokhranyayetsya bez interpretacii. SHA-256 obnaruzhivayet sluchajnoye povrezhdeniye, no ne yavlyayetsya autentifikaciyej.

Gruppa begin → data* → commit podtverzhdayetsya toljko posle polnogo write i uspeshnyikh fsync fajla i kataloga. EINTR povtoryayetsya, korotkij write dopisyivayetsya, nulevoj write schitayetsya oshibkoj. Otkaz vvoda-vyivoda blokiruyet daljnejsheye ispoljzovaniye ekzemplyara; trebuyetsya zakryitiye i novoye otkryitiye.

Povtor identifikatora sravnivayet vse metadannyiye, dlinu i SHA-256 soderzhimogo. Sovpadeniye vozvrasjhayet tu zhe kvitanciyu bez dopisyivaniya fajla, no toljko posle novoj uspeshnoj sinkhronizacii. Vidimyij commit posle oshibochnogo fsync sam po sebe ne dayot prava podtverditj povtor. Konflikt identifikatora otklonyayetsya.

Chitatelj ne menyayet fajl i pokazyivayet toljko gruppyi s proverennyim commit. Chastichnyij kadr ili polnyiye begin/data bez commit schitayutsya nezavershyonnyim khvostom. Pisatelj ne dopisyivayet poverkh khvosta. Yavnyij vosstanovitelj zanovo proveryayet vesj fajl, obrezayet toljko nezavershyonnyij khvost do poslednej polnoj gruppyi i sinkhroniziruyet. Povrezhdyonnyij polnyij kadr/zafiksirovannyij prefiks otklonyayetsya bez obrezki. Susjhestvuyusjhij pustoj libo povrezhdyonnyij fajl ne pereinicializiruyetsya; otsutstvuyusjhij fajl vosstanovitelj ne sozdayot.

## Format versii 1

Signatura fajla — vosemj bajtov FUMOBS01. Kazhdyij kadr:

| Pole | Razmer |
| --- | --- |
| OBS1, vid (1 begin / 2 data / 3 commit), tri nulevyikh bajta | 8 bajt |
| Dlina JSON, dlina payload, poryadkovyij nomer; unsigned big-endian | 4 + 4 + 8 bajt |
| SHA-256 predyidusjhikh 24 bajtov | 32 bajta |
| Kanonicheskij JSON-zagolovok, zatem syiryiye binarnyiye bajtyi | Po dlinam |
| SHA-256 predyidusjhego chain hash + prefiksa 24 bajta + JSON + payload | 32 bajta |

Pervyij chain hash — SHA-256 vosjmi bajtov signaturyi FUMOBS01. JSON imeyet otsortirovannyiye klyuchi, bez escaping slash; dekodirovaniye trebuyet tochnogo ravenstva povtorno zakodirovannyim bajtam, poetomu lishniye/povtornyiye polya otklonyayutsya. Specifikaciya Data kodiruyetsya standartnyim Codable vnutri JSON, sam payload ne kodiruyetsya v JSON/base64. Commit khranit razmer, chislo fragmentov i SHA-256 celogo obyyekta. Nomer kadra nepreryiven ot 0; nomer i smesjheniye data-fragmenta nachinayutsya s 0 v kazhdoj gruppe. Pustoye nablyudeniye imeyet begin i commit bez data.

## Ogranicheniya i vladeniye

Predelyi proveryayutsya do sootvetstvuyusjhikh vyidelenij pamyati i chteniya: JSON 128 KiB, specifikaciya 64 KiB, data-fragment 1 MiB, obyyekt 64 MiB, segment 256 MiB, 4096 nablyudenij i 16384 fragmenta. API prinimayet i vozvrasjhayet Data celogo ogranichennogo obyyekta; eto ne potokovyij API s pamyatjyu toljko v odin fragment. Skaner khranit ogranichennyij indeks metadannyikh i raspolozhenij fragmentov.

Neblokiruyusjhij advisory flock zakhvatyivayetsya snachala na otkryitom korne, zatem na segmente. Writer/recovery ispoljzuyut exclusive lock, reader — shared. Kornevoj zamok predshestvuyet sozdaniyu fajla, zakryivaya gonku dvukh sozdatelej. Ne podderzhivayusjhaya directory flock fajlovaya sistema otklonyayetsya bez obkhoda blokirovki. Zamki yavno osvobozhdayutsya v obratnom poryadke pri zakryitii. Odin ekzemplyar sinkhronnyij, ne Sendable, ne ispoljzuyetsya konkurentno ili cherez fork.

Zasjhita kornya i segmenta ispoljzuyet posledovateljnyij openat s O_NOFOLLOW. Dlya yavno peredannyikh vkhodnyikh fajlov CLI zapresjhena simvolicheskaya ssyilka poslednego komponenta, no roditeljskiye simvolicheskiye ssyilki dopuskayutsya. Fajl dolzhen byitj obyichnyim, prinadlezhasjhim tekusjhemu poljzovatelyu, s odnoj zhyostkoj ssyilkoj i bez obsjhej zapisi. Protokol ne zasjhisjhayet ot zlonamerennogo processa togo zhe poljzovatelya, kotoryij ignoriruyet advisory lock ili pereimenovyivayet katalog. Avariya sozdatelya do polnoj signaturyi ostavlyayet otklonyayemyij fajl; avtomaticheskogo udaleniya takogo fajla net.

## Sborka i CLI

Iz kornya etogo repozitoriya:

```sh
swift test --package-path Packages/КонтейнерНаблюдений --build-system native --jobs 2
swift build --package-path Packages/КонтейнерНаблюдений --build-system native --jobs 2 -c release
```

Native backend primenyon iz-za otkaza codesign u default backend na kirillicheskom XCTest bundle v ispoljzovannom Swift 6.4. Native pomechen SwiftPM ustarevayusjhim; eto ogranicheniye proverennoj sredyi, ne ispravleniye obsjhego toolchain.

Ispolnyayemyiye fajlyi nakhodyatsya v .build/release vnutri paketa:

```text
писатель-контейнера добавить <абсолютный корень> <ID> <тип> <абсолютный файл байтов> [абсолютный файл спецификации]
читатель-контейнера извлечь <абсолютный корень> <ID>
восстановитель-контейнера <абсолютный корень>
профиль-контейнера записать <новый синтетический корень> 64 524288
профиль-контейнера восстановить <тот же корень>
```

Writer vyidayot JSON-kvitanciyu toljko posle podtverzhdeniya; reader vyidayot tochnyiye binarnyiye bajtyi v stdout. Oshibki idut v stderr s nenulevyim exit status. CLI ispoljzuyet sinteticheskiye znacheniya istochnika/vremeni po umolchaniyu; polnyiye metadannyiye dostupnyi v bibliotechnom API. Komanda writer «uderzhivatj» prednaznachena dlya testa blokirovki: vyivodit gotovnostj i derzhit zamki do bajta stdin/EOF.

## Proverki i profilj

Testyi pokryivayut proizvoljnyiye bajtyi/neizvestnyij tip, vse metadannyiye, srez Data, pustoj obyyekt, korotkiye/nulevyiye write, EINTR, ENOSPC, oshibku fsync fajla i kataloga, povtor posle neopredelyonnogo iskhoda, kazhdyij bajt usecheniya vtoroj gruppyi i povrezhdeniya polnogo fajla, nevernyiye kadryi s praviljnyimi khyeshami, limityi, nebezopasnyiye puti, dva processa, SIGKILL vladeljca lock i vosstanovleniye otdeljnyim processom.

Profilj vyidayot JSON fum.metriki-kontejnera.1: dliteljnostj, kazhduyu zaderzhku podtverzhdeniya, vlozhennyiye etapyi i Darwin peak RSS v bajtakh. Vkhod determinirovan: byte[i] = (i × 131) mod 256. Izmereniye zapisi isklyuchayet sozdaniye fajla i generaciyu vkhoda. Vosstanovleniye izmeryayet otkryitiye/skanirovaniye + povtornuyu proverku/sync chistogo fajla; SHA-256 do/posle isklyuchyon iz vremeni, no vkhodit v RSS i progrevayet kyesh. Eto ne kholodnoye chteniye i ne izmereniye remonta khvosta. Roditeljskij etap vklyuchayet docherniye: skladyivatj ikh kak nezavisimyiye neljzya.

## Granica rezuljtata

Eto odin ogranichennyij segment, a ne zaversheniye FUM-STEP-0156. Rotaciya, indeksyi neskoljkikh segmentov, migraciya staroj pamyati i integraciya datchikov ne realizovanyi. Ubijstvo testovogo vladeljca lock ne modeliruyet avariyu v seredine write: vosstanovleniye usechyonnoj gruppyi proveryayetsya otdeljnyim processom na sinteticheskoj fiksture.

Perezapusk OS, avariya yadra i otklyucheniye pitaniya ne proveryalisj. Zdesj ispoljzuyetsya fsync, ne F_FULLFSYNC; uspeshnyij fsync ne dokazyivayet fizicheskuyu sokhrannostj pri potere pitaniya. Sm. [opisaniye Apple fsync(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/fsync.2.html) i [advisory flock(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/flock.2.html).

Proiskhozhdeniye: porucheniye FUMA 01a07d3d-d376-7ad2-aafc-67e4c25a67eb, Zhurnal FUM ot 2026-09-09 11:48:04 MSK. Proveryalisj toljko sobstvennyiye sinteticheskiye katalogi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:36:01 MSK -->
<!-- content-sha256: sha256:43cdb3657234ea5afb720ef40e856aed8765c82f9eb3b8bfb0d475f7f03df6d5 -->
<!-- FUM-MD-RECENCY:END -->
