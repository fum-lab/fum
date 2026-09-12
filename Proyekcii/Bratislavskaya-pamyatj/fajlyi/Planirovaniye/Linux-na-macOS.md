# Avtomatizirovatj Linux VM na macOS

Istoricheskaya planovaya zavisimostj Windows-postanovki, sokhranyonnaya iz kommita `8d89a695d6f099091a13d3ce60c924c7098105f2` zadachi «Planirovaniye FUMA». Eto opisaniye pervonachaljnogo Linux VM obyyoma, a ne perenos nyineshnego koda, nezavershyonnogo rezuljtata ili polnomochij dejstvuyusjhej zadachi `01a08fe2-d0c2-7ef3-b980-6bb5f8edbe97`. Formulirovki o budusjhej peredache i yesjhyo ne vyipolnennyikh ispyitaniyakh nizhe prinadlezhat iskhodnoj postanovke. Novaya Linux-zadacha etim dokumentom ne sozdayotsya; Windows/macOS ispoljzuyut toljko otdeljno prinyatyiye tochnyiye postavki obsjhego povedeniya i sokhranyayut sobstvennyiye platformennyiye granicyi.

Sozdatj sobstvennyij instrument na Swift, kotoryij podgotavlivayet polnocennuyu Linux VM na Mac, zapuskayet yeyo i podtverzhdayet gotovnostj vyibrannoj perenosimoj chasti FUM vnutri gostya. Chelovek poluchayet ponyatnoye sostoyaniye, dostup po SSH i vosproizvodimuyu komandu povtornoj proverki.

Eto konkretnaya postanovka otdeljnoj zadachi realizacii. Sam instrument, proverka obraza, zagruzka VM i gostevyiye ispyitaniya yesjhyo ne vyipolnenyi. Odna VM i odin zakreplyonnyij obraz sostavlyayut pervyij konechnyij obyyom.

## Pervyij profilj i osnovaniye vyibora

Pervyij celevoj khost — Mac s Apple silicon, gostevaya arkhitektura arm64. Po chteniyu koordinatora dostupnyij khost imeyet M1 Max i macOS 27; eto nablyudeniye iskhodnoj sredyi, a ne obesjhaniye podderzhki vsekh versij macOS. Pri realizacii zakreplyayutsya ispyitannyiye versiya i sborka macOS, Swift i SDK, nuzhnyiye vozmozhnosti Virtualization.framework i podpisj s entitlement virtualizacii; nepodderzhannyij khost otklonyayetsya do izmenenij.

Vyibran Ubuntu Server 24.04 LTS arm64, vyipusk cloud image `release-20260826`, fajl `ubuntu-24.04-server-cloudimg-arm64.img`. Oficialjnyiye [katalog vyipuska](https://cloud-images.ubuntu.com/releases/noble/release-20260826/) i [tablica SHA256SUMS](https://cloud-images.ubuntu.com/releases/noble/release-20260826/SHA256SUMS) prochitanyi 11 sentyabrya 2026 goda. Tablica soderzhit SHA-256 `afa139bac6f2629c1e1f2f8f34215f3a9ad9779801bcb945521ba1a45016743f` dlya vyibrannogo fajla. Podpisj tablicyi i bajtyi skachannogo obraza yesjhyo ne proverenyi; realizaciya obyazana proveritj oba do ispoljzovaniya, s obyyavlennyim istochnikom klyucha i zakreplyonnyim otpechatkom.

VM upravlyayetsya cherez Virtualization.framework. Predlagayemaya skhema: EFI s postoyannyim khranilisjhem peremennyikh, disk RAW posle proveryayemoj konvertacii QCOW posredstvom obyyavlennoj zavisimosti qemu-img, otdeljnyij seed NoCloud s metkoj CIDATA i stabiljnyim instance-id, iskhodyasjhaya setj NAT. SSH cherez VSOCK i gostevoj socat predpolagayetsya ispoljzovatj dlya dostupa bez poiska adresa DHCP. Eto kompoziciya dokumentirovannyikh mekhanizmov; yeyo sovmestnaya rabotosposobnostj ostayotsya predmetom realjnogo ispyitaniya. qemu-img sluzhit konvertacii obraza; zapusk VM vyipolnyayet sobstvennyij Swift-instrument.

Intel/amd64, drugiye distributivyi i vyipuski, kontejneryi, vlozhennaya virtualizaciya, GUI Linux i polnaya perenosimostj FUMA v pervyij obyyom ne vkhodyat. Rasshireniye matricyi trebuyet otdeljnogo dokazateljstva. Yesli zakreplyonnyij obraz nedostupen, izmenilsya libo skhema dostupa ne rabotayet, instrument soobsjhayet konkretnoye prepyatstviye; avtomaticheskaya podmena obraza ili oslableniye proverki ne dopuskayutsya.

## Poljzovateljskij putj

Nazvaniya nizhe oboznachayut trebuyemyiye operacii; tochnyij sintaksis CLI poyavitsya vmeste s realizaciyej i proverennyim rukovodstvom.

1. **Proveritj.** Opredelitj arkhitekturu i versiyu khosta, virtualizaciyu, SDK/toolchain, fakticheskiye zavisimosti i versii, prava i dostupnyiye CPU, RAM i disk. Rasschitatj mesto dlya skachivaniya, konvertacii i rabochego diska, pokazatj vyibrannyiye limityi VM. Uchestj sostoyaniye celevogo kataloga i FUM.
2. **Plan.** Pokazatj uzhe gotovyiye komponentyi, nedostayusjhiye zavisimosti i ikh proveryayemyiye istochniki, budusjhiye zapisi i zatratyi resursov. Izmenenij VM pri prosmotre plana net; vse zavisimosti ne ustanavlivayutsya bezuslovno iz obsjhego reyestra.
3. **Podgotovitj.** Proveritj tablicu i obraz, bezopasno zavershitj ili prodolzhitj skachivaniye i konvertaciyu, sozdatj prinadlezhasjheye instrumentu lichnoye sostoyaniye VM vne Git. Sformirovatj seed, postoyannyiye identifikatoryi i klyuchi dostupa. Susjhestvuyusjhij neizvestnyij katalog ili disk ne prisvaivayetsya instrumentu.
4. **Zapustitj i sostoyaniye.** Zagruzitj VM, razlichatj podgotovlennyij disk, rabotayusjhij process, vyipolnyayusjhijsya cloud-init i gotovuyu sredu. Diagnostika imeyet ponyatnuyu prichinu otkaza, ogranichennoye ozhidaniye i dejstviye dlya prodolzheniya.
5. **SSH i gotovnostj.** Podtverditj vkhod v nuzhnogo gostya, yego arkhitekturu, zaversheniye cloud-init, DNS i iskhodyasjhuyu setj, versii ustanovlennyikh instrumentov i tochnyij nabor gostevyikh proverok FUM. Setevoj i upravlyayusjhij kanalyi proveryayutsya razdeljno. Klyuch khosta SSH privyazan k sobstvennoj VM; proverka podlinnosti ne otklyuchayetsya globaljno.
6. **Ostanovitj i povtoritj.** Proveritj shtatnuyu ostanovku, povtornyij zapusk toj zhe VM i sokhraneniye gostevyikh dannyikh. Preryivaniye podgotovki, zapuska ili nastrojki ostavlyayet diagnostiruyemoye sostoyaniye i dopuskayet prodolzheniye bez skryitogo peresozdaniya diska. Izmenyonnyij profilj trebuyet novogo plana i ponyatnogo resheniya ob obnovlenii.

## Granica sostoyaniya i perenosimyij profilj FUM

Iskhodniki Swift, otkryityiye fiksturyi, opisaniye profilya i rukovodstvo khranyatsya obyichnyimi otslezhivayemyimi fajlami tematicheskikh katalogov monorepozitoriya FUM. Obrazyi, diski, EFI state, seed s chastnyimi dannyimi, SSH-klyuchi, zhurnalyi gostya i kyeshi nakhodyatsya vne Git. Zapisj ogranichena yavno vyibrannoj sobstvennoj VM; yeyo prinadlezhnostj i isklyucheniye odnovremenno rabotayusjhikh pisatelej proveryayutsya. Susjhestvuyusjhiye VM, poljzovateljskiye konfigi, gryaznyiye checkout i chuzhiye rabochiye derevjya sokhranyayutsya.

Rabochij klon FUM sozdayotsya vnutri gostevoj fajlovoj sistemyi i privyazan k tochnomu OID. Obsjhij katalog khosta dopustim toljko pri yavnom vyibore; chuzhoye derevo dostupno dlya chteniya. Puti s kirillicej, yo, probelami i raznyim registrom vkhodyat v proveryayemyiye sluchai.

Profilj perechislyayet toljko neobkhodimyiye Git, Python, Swift i prochiye zavisimosti konkretnyikh scenariyev s versiyami, istochnikami i komandami proverki. Podgotovka khosta otnositsya k [FUM-STEP-0179](kartochki-shagov/🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md), gostya — k [FUM-STEP-0180](kartochki-shagov/🟡-FUM-STEP-0180-avtomatizirovatj-podgotovku-repozitoriya-na-Linux.md); primenyayetsya obsjhaya modelj profilej, bez nezavisimogo dublirovaniya spiskov.

Nabor perenosimyikh proverok vyibirayetsya po fakticheski dostupnyim iskhodnikam i vyipolnyayetsya v goste. Uzhe susjhestvuyusjhij dokumentacionnyij smoke soderzhit zavisimostj ot Swift/LinguisticKit; yego nazvaniye samo po sebe ne dokazyivayet gotovnostj k Linux. Gotovogo otdeljnogo Linux-profilya tekusjhij runner ne obyyavlyayet. Pri neobkhodimosti realizacii nuzhen yavno ogranichennyij profilj s otkryityim perechnem vklyuchyonnyikh i nepodderzhannyikh proverok. Yego uspekh podtverzhdayet toljko etot perechenj; otsutstviye API macOS ne maskiruyetsya obsjhim zelyonyim statusom. Dostavka sobstvennogo komponenta po STEP0176 otdeljno sveryayetsya s vyibrannyim OID pered vklyucheniyem yego v gostevoj scenarij.

## Priyomka realizacii

- Iz chistogo klona FUM po rukovodstvu vosproizvodyatsya sborka sobstvennogo instrumenta, neobkhodimyiye zavisimosti, podgotovka vyibrannoj VM, yeyo zapusk, podtverzhdyonnyij SSH i podderzhannyij scenarij FUM v goste. Sokhranenyi tochnyiye komandyi, versii, OID, konfiguraciya VM i realjnyiye rezuljtatyi.
- Obyichnyiye lokaljnyiye RED/GREEN na otkryityikh fiksturakh pokryivayut plan bez zapisi, nevernyij obraz ili podpisj, nedostatok resursov, preryivaniye i povtor, izmeneniye vkhodov, zanyatyij katalog i sokhrannostj susjhestvuyusjhikh dannyikh. Setevaya i VM-priyomka otdelenyi ot avtonomnogo nabora.
- Realjnoye ispyitaniye vyibrannogo sochetaniya podtverzhdayet pervichnyij putj, povtor posle ostanovki i vosstanovleniye posle preryivaniya. Neuspeshnyiye ili nepodderzhannyiye sluchai zavershayutsya ponyatnyim statusom; uspeshnoye nachalo zagruzki ne schitayetsya gotovnostjyu gostya.
- Profilj monotonnogo vremeni otdeljno izmeryayet polucheniye i konvertaciyu obraza, podgotovku, zagruzku, cloud-init, gostevoj scenarij i povtor; fiksiruyutsya obyyom diska, usloviya seti, kyeshej i resursyi. Vlozhennyiye intervalyi ne summiruyutsya povtorno. Resheniye ob optimizacii opirayetsya na sravnimyiye izmereniya.
- Statistika sokhranyayet pryamyiye i vlozhennyiye vyizovyi s proiskhozhdeniyem, iskhodami i izvestnoj oblastjyu okhvata. Neizvestnyiye polya oboznachenyi; povtornyij import ne uvelichivayet schyotchiki.
- Rukovodstvo soderzhit neobkhodimyiye vkhodyi, obyichnyiye proverennyiye komandyi, ozhidayemoye sostoyaniye, sposob vkhoda v gostya, ostanovku, povtor, diagnostiku i granicyi matricyi. Instrument ne obyyavlyayet vsyu podgotovku macOS ili Linux zavershyonnoj po uspekhu odnoj VM.

## Peredacha v realizaciyu

[Postanovka Windows VM](Windows-na-macOS.md) pereispoljzuyet opisannyij obsjhij cikl, vladeniye sostoyaniyem, proverki artefaktov, metriki i zhurnal cherez otdeljnyij Windows-adapter. Gotovaya obsjhaya Swift-realizaciya etoj ssyilkoj ne obyyavlyayetsya prinyatoj; Linux NoCloud, VZEFIVariableStore i VSOCK/socat ne perenosyatsya v Windows avtomaticheski.

Koordinator sozdayot otdeljnuyu vidimuyu zadachu ot tochnogo opublikovannogo kommita etoj postanovki. V yeyo pervom etape fiksiruyutsya konkretnyiye SDK/toolchain, resursyi i sostav perenosimogo profilya; zatem realizuyetsya i ispyityivayetsya vesj opisannyij poljzovateljskij putj. Eto ogranichennoye porucheniye ne sozdayot novyij globaljnyij STEP-ID i ne zakryivayet 0179/0180.

Kommit postanovki yavlyayetsya potomkom 186b0360a31b97184773757634976257d0f86495. Etot raneye zakreplyonnyij OID ostayotsya vkhodom uzhe vyipolnyayusjhejsya integracii vosjmi postavok; novaya postanovka peredayotsya otdeljno bez izmeneniya starogo obyyekta i chuzhogo snimka.

## Istochniki

- [Komanda, vyibor poljzovatelya i proiskhozhdeniye](https://github.com/fum-lab/fum/blob/8d89a695d6f099091a13d3ce60c924c7098105f2/Журнал/2026-09-11_12-40-18_MSK_подготовить-постановку-Linux-VM-на-macOS/запрос.md).
- [Issledovaniye i granicyi porucheniya koordinatora](https://github.com/fum-lab/fum/blob/8d89a695d6f099091a13d3ce60c924c7098105f2/Журнал/2026-09-11_12-40-18_MSK_подготовить-постановку-Linux-VM-на-macOS/материалы/поручения-координатора.json). Apple-mekhanizmyi i nablyudeniye khosta vzyatyi iz etogo issledovaniya; realjnyiye ispyitaniya ne zayavlenyi.
- Apple: [zapusk Linux](https://developer.apple.com/documentation/virtualization/running-linux-in-a-virtual-machine), [diskovyij obraz](https://developer.apple.com/documentation/virtualization/vzdiskimagestoragedeviceattachment), [NAT](https://developer.apple.com/documentation/virtualization/vznatnetworkdeviceattachment), [VSOCK](https://developer.apple.com/documentation/virtualization/vzvirtiosocketdevice).
- [NoCloud](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html): podtverzhdayet lokaljnyiye user-data i meta-data, instance-id i nositelj CIDATA; sovmestimostj versii cloud-init vyibrannogo obraza proveryayetsya pri realizacii.
- [socat v Ubuntu Noble](https://manpages.ubuntu.com/manpages/noble/man1/socat.1.html), [Swift na Linux](https://www.swift.org/install/linux/).
- [Reyestr instrumentov FUM](../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md), [tekusjhij runner smoke](../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 01:09:27 MSK -->
<!-- content-sha256: sha256:de30fb60fef712dcecb2be1e830d28f5e51ed7bde311f8e4e4a2f7f6e6964965 -->
<!-- FUM-MD-RECENCY:END -->
