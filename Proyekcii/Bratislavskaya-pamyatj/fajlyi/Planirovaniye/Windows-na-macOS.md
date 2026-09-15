# Avtomatizirovatj Windows VM na macOS

Sokhranyonnaya planovaya postanovka zadachi «Planirovaniye FUMA» iz kommita `8d89a695d6f099091a13d3ce60c924c7098105f2`. Issledovaniya i predlozhennyij Windows backend nizhe otnosyatsya k iskhodnomu planovomu etapu; ikh perenos ne podtverzhdayet novuyu aktualjnostj vneshnikh API ili gotovuyu realizaciyu. Novoye ogranichennoye naznacheniye 0181 podgotavlivayet matricu nativnogo Windows/WSL i kontrakt gotovnosti, bez ustanovki, zapuska VM ili realizacii ustanovsjhika. Istoricheskaya Linux-postanovka ryadom zadayot svyazj planov; obsjhij ispolnyayemyij lifecycle beryotsya toljko iz otdeljno prinyatogo tochnogo rezuljtata dejstvuyusjhego vladeljca Linux.

Sozdatj povtorno vyizyivayemuyu avtomatizaciyu FUM dlya podgotovki Windows VM na Mac, proverki gostevogo okruzheniya i daljnejshego upravleniya im. Konkretnaya ustanovlennaya VM sluzhit ispyitaniyem etogo sposoba. Rezuljtat razrabotki vklyuchayet sobstvennyiye iskhodniki, otkryityiye fiksturyi, profilj i ponyatnoye rukovodstvo v monorepozitorii.

Eto postanovka rasshireniya [FUM-STEP-0181](kartochki-shagov/🟡-FUM-STEP-0181-avtomatizirovatj-podgotovku-repozitoriya-na-Windows.md), a ne vyipolnennaya ustanovka. Ona pereispoljzuyet obsjhij cikl [Linux VM na macOS](Linux-na-macOS.md). Po soobsjheniyu koordinatora Linux-realizaciya toljko nachata; gotovaya obsjhaya Swift-biblioteka yesjhyo ne prinyata. V etom etape Windows ne ustanavlivayetsya, licenzii ne pokupayutsya, realizaciya ne nachinayetsya.

## Pervyij profilj i proverka realizuyemosti

Pervyij predlagayemyij profilj: Mac s Apple silicon, pervonachaljnoye ispyitaniye na M1 Max; Windows 11 Pro ARM64 odnogo zakreplyonnogo vyipuska; UTM s QEMU/HVF pod upravleniyem sobstvennogo Swift-instrumenta FUM. Eto predlozhennyij variant, a ne ispyitannyij Windows-backend. Variant Apple Virtualization.framework, vyibrannyij dlya Linux, syuda ne perenositsya: issledovannyiye Apple/UTM Apple Boot opisyivayut macOS i Linux.

**Pervoye reshayusjheye ispyitaniye:** iz pustogo sobstvennogo kataloga avtomatizaciya sozdayot svezhuyu versionirovannuyu konfiguraciyu .utm, kotoruyu UTM prinimayet, i pri probnoj zagruzke podtverzhdayet UEFI, TPM 2.0 i Secure Boot. Novyiye identichnosti VM i sobstvennoye sostoyaniye EFI/TPM sozdayutsya vosproizvodimo. Polya konfiguracii i uspeshnyij import bez proverki fakticheskikh vozmozhnostej nedostatochnyi. Ruchnoye sozdaniye iskhodnoj VM, kopirovaniye chuzhoj ustanovlennoj mashinyi i povtornoye klikanjye ne zamenyayut etot rezuljtat.

Adresnoye chteniye 11 sentyabrya 2026 goda podtverdilo ogranicheniye: [scripting-kontrakt UTM](https://docs.getutm.app/scripting/reference/) soderzhit make, import, start, stop, status i gostevoye vyipolneniye cherez QEMU Guest Agent; v opublikovannyikh polyakh yestj UEFI, no net TPM. Issledovaniye koordinatora takzhe otmechayet nepolnotu utmctl. V prochitannom [iskhodnike UTM](https://github.com/utmapp/UTM/blob/main/Configuration/UTMQemuConfigurationQEMU.swift) TPM po umolchaniyu vyiklyuchen, flag predvariteljnoj ustanovki Secure Boot keys ne serializuyetsya vmeste s obyichnyimi polyami, a sozdaniye EFI vyibirayet otdeljnyij shablon. Poetomu vozmozhnostj polnostjyu podgotovitj nuzhnuyu VM odnoj komandoj utmctl ne predpolagayetsya.

Do etogo ispyitaniya zakreplyayutsya versiya UTM, postavlyayemogo QEMU, format konfiguracii i nuzhnyiye firmware/drajveryi; chteniye izmenyayemoj upstream-vetki ne schitayetsya proverkoj ustanovlennogo vyipuska. Yesli avtomaticheskoye sozdaniye ili neobkhodimyiye vozmozhnosti ne podtverzhdayutsya, sokhranyayetsya konkretnoye prepyatstviye i obosnovannyij vyibor daljnejshego backend. Trebovaniya Windows ne obkhodyatsya.

## Obsjhij cikl i otdeljnyij Windows-adapter

Obsjhaya chastj rasshiryayet uzhe opredelyonnyiye operacii Linux-postanovki, a pri poyavlenii prinyatoj realizacii ispoljzuyet yeyo tochnyij OID i interfejsyi. Ne trebuyetsya snachala sozdavatj universaljnuyu biblioteku; povtoryayemyij mekhanizm vyidelyayetsya po proverennomu obsjhemu povedeniyu.

| Obsjhaya operaciya         | Sokhranyayemyij rezuljtat                                                    | Osobennostj Windows                                                 |
| ---------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| Proveritj i plan       | Sostoyaniye khosta, resursyi, zavisimosti, plan bez zapisi                   | Versii UTM/QEMU/HVF i vozmozhnostj celevoj konfiguracii              |
| Podgotovitj            | Proverennyiye artefaktyi, vladeniye katalogom, ustojchivoye sostoyaniye operacii | ISO, .utm, EFI/TPM, yedinyij fajl otvetov, drajveryi                   |
| Zapustitj i sostoyaniye  | Ogranichennyiye ozhidaniya, yavnyiye perekhodyi, diagnostika                       | Ustanovsjhik, perezagruzki, ustanovlennaya OS i gotovnostj razlichayutsya |
| Dostup i gotovnostj    | Podtverzhdyonnyij gostj i tochnyij nabor proverok                             | PowerShell i ispyitannyij kanal upravleniya                            |
| Ostanovitj i povtoritj | Shtatnaya ostanovka, sokhraneniye dannyikh, prodolzheniye posle preryivaniya       | Sokhranyayutsya identichnostj VM, disk i EFI/TPM                         |
| Profilj i zhurnal       | Monotonnyiye etapyi, iskhodyi i statistika bez dvojnogo uchyota                 | Razdeljnyiye izmereniya ustanovki, perezagruzok i gostevoj nastrojki   |

V Windows-adaptere otdeljno opredelyayutsya backend, EFI/TPM, nositeli, drajveryi, gostevyiye komandyi i dostup. NoCloud, VZEFIVariableStore i Linux VSOCK/socat ne obyyavlyayutsya perenosimyim Windows-mekhanizmom. Obsjhaya diagnostika i sostoyaniye operacij otdelenyi ot platformennyikh sposobov ikh vyipolneniya.

## Ustanovochnyij nositelj i nastrojka gostya

[Microsoft publikuyet ARM64 ISO](https://www.microsoft.com/en-us/software-download/windows11arm64); pri chtenii stranica ukazyivala vyipusk 25H2 i tablicu SHA-256 po yazyikam. Eto pervyij kandidat vyipuska. Pered podgotovkoj dolzhnyi byitj zakreplenyi redakciya Pro, arkhitektura ARM64, yazyik, polnyij nomer sborki i SHA-256 konkretnogo ISO. Yazyik, sborka i khyesh vyibrannogo fajla zdesj yesjhyo ne utverzhdenyi: ISO ne poluchen. Vremennaya ssyilka srokom do 24 chasov ne yavlyayetsya identichnostjyu obraza; povtor svyazyivayetsya s zakreplyonnyimi bajtami. Nesovpadeniye khyesha prekrasjhayet ispoljzovaniye fajla bez avtomaticheskoj podmenyi vyipuska.

Dejstviteljnaya licenziya Windows — otdeljnyij vkhod budusjhej ustanovki; dostupnostj ISO ne podtverzhdayet nalichiye licenzii. Yeyo vvod i proverka ne raskryivayut klyuchi v Git ili zhurnalakh. Pokupka ne yavlyayetsya dejstviyem etoj postanovki.

Windows-adapter formiruyet odin Autounattend.xml iz versionirovannyikh otkryityikh parametrov i chastnyikh vkhodov. Na ustanovochnyikh nositelyakh ne dolzhno byitj konkuriruyusjhikh fajlov otvetov. Podgotovka vklyuchayet nuzhnyiye ARM64-drajveryi zagruzki i seti, gostevyiye instrumentyi i PowerShell-nastrojku. Istochniki, versii, podpisi ili khyeshi etikh zavisimostej obyyavlyayutsya i proveryayutsya. Pervichnaya ustanovka i perezagruzki dolzhnyi vyipolnyatjsya avtomatizaciyej; obyazateljnyij shag cheloveka, yesli on obnaruzhen, yavno pokazyivayet nezavershyonnostj.

Kanal upravleniya vyibirayetsya i ispyityivayetsya vmeste s gostem. Predlagayemyij pervyij putj — QEMU Guest Agent i UTM guest execution posle ustanovki agenta; nalichiye ustanovochnogo paketa ne dokazyivayet rabotayusjhij kanal. Avtomatizaciya podtverzhdayet prinadlezhnostj gostya, vyipolneniye komandyi i polucheniye yeyo rezuljtata s ogranichennyim ozhidaniyem. Otkaz upravlyayusjhego kanala i otkaz gostevoj seti razlichayutsya.

## Sostoyaniye, resursyi i profilj FUM

Proverka khosta pokazyivayet fakticheskiye versii macOS, arkhitekturu, dostupnyiye CPU, RAM, disk i nuzhnyiye razresheniya. Resursyi vyibrannoj VM i mesto dlya ISO, drajverov, ustanovki i rabochego diska yavno rasschityivayutsya; nepodderzhannyij khost ili nedostatok resursov obnaruzhivayutsya do zapisi.

Lichnyiye diski, klyuchi, EFI/TPM, konfiguracii s chastnyimi dannyimi i zhurnalyi gostya nakhodyatsya vne Git. Otkryityij shablon i opisaniye profilya khranyatsya v FUM. Sobstvennaya VM imeyet proveryayemuyu prinadlezhnostj i zasjhitu ot vtorogo pisatelya. Povtor sokhranyayet yeyo identichnostj i dannyiye; novaya VM sozdayot novoye sostoyaniye. Susjhestvuyusjhiye VM, poljzovateljskiye nastrojki, nezakommichennyiye izmeneniya i chuzhiye worktree ne prisvaivayutsya i ne perezapisyivayutsya.

Dlya gostya opredelyayetsya konechnyij nativnyij Windows-profilj STEP0181: neobkhodimyiye instrumentyi, podderzhivayemyiye versii, scenarii FUM i tochnyiye komandyi proverki. Rabochij klon vnutri gostevoj fajlovoj sistemyi privyazan k OID FUM; obsjhij katalog khosta podklyuchayetsya toljko yavno, chuzhoj checkout ostayotsya dostupnyim dlya chteniya. Vesj reyestr instrumentov bezuslovno ne ustanavlivayetsya. Podderzhka POSIX-avtomatizacij, Swift-paketov ili komponentov macOS ne vyivoditsya iz nalichiya Windows libo emulyacii processora; nepodderzhannyiye chasti perechislyayutsya otdeljno.

WSL2, vlozhennaya virtualizaciya, igryi, GPU-scenarii i vsya perenosimostj FUMA ne vkhodyat v pervyij srez. Boleye shirokij STEP0181 sokhranyayet razlicheniye nativnogo Windows i WSL; dannaya VM-postanovka ne zakryivayet yego celikom.

## Priyomka budusjhej realizacii

- Iz chistogo klona FUM vosproizvodyatsya sborka avtomatizacii i ranneye ispyitaniye svezhej .utm-konfiguracii; daleye cherez neyo vyipolnyayetsya chistaya ustanovka Windows ARM64 bez ruchnoj podgotovki iskhodnoj VM. Proverenyi redakciya, sborka, ustrojstva, UEFI/TPM/Secure Boot, dostup i konechnyij profilj FUM.
- Plan ne pishet sostoyaniye. Povtor na podgotovlennom khoste i goste ne dubliruyet ustanovki; izmeneniye vkhodov snachala pokazyivayet novyij plan. Proverenyi shtatnaya ostanovka, povtornyij zapusk s sokhranyonnyimi dannyimi i vosstanovleniye posle preryivaniya podgotovki, ustanovki i gostevoj nastrojki.
- Lokaljnyiye RED/GREEN na otkryityikh fiksturakh pokryivayut plan, vladeniye katalogom, nesootvetstviye artefakta, nedostatok resursov, izmeneniye konfiguracii, preryivaniye i povtor. Realjnyiye VM-ispyitaniya otdelenyi ot avtonomnyikh testov; ogranicheniya i otkazyi ne zamenyayutsya obsjhim uspeshnyim statusom.
- Rukovodstvo soderzhit proverennyiye komandyi, neobkhodimyiye vkhodyi, ozhidayemyiye sostoyaniya, gostevoj dostup, diagnostiku, ostanovku, povtor i vosstanovleniye. Sostoyaniye started ne ravno gotovnosti Windows ili profilya FUM.
- Profilj otdeljno izmeryayet podgotovku artefaktov, sozdaniye konfiguracii, ustanovku, perezagruzki, gostevuyu nastrojku, proverki i povtor pri obyyavlennyikh CPU/RAM, usloviyakh seti i kyeshej. Sokhranyayutsya monotonnyiye intervalyi, disk, iskhodyi i resheniye ob optimizacii po sravnimyim izmereniyam.
- Pryamyiye i vlozhennyiye vyizovyi imeyut proiskhozhdeniye i ne schitayutsya dvazhdyi. Neizvestnyiye polya oboznachenyi, povtornyij import ne uvelichivayet schyotchiki. Sbor statistiki ne podmenyayet vyipolneniye scenariya.

Parallels ostayotsya znachimoj aljternativoj pri vyibore i podkhodyasjhej licenzii: [Microsoft opisyivayet konkretnyiye avtorizovannyiye versii dlya Windows 11 Pro/Enterprise ARM na M1/M2/M3](https://support.microsoft.com/en-us/windows/experience/platform-variants/options-for-using-windows-11-with-mac-computers-with-apple-m1-m2-and-m3-chips). Po issledovaniyu koordinatora prlctl trebuyet Pro/Business/Enterprise; pered vyiborom sveryayutsya fakticheskiye versiya, redakciya i dostupnyij CLI. Eta aljternativa ne vvodit obyazateljnuyu pokupku v tekusjhij etap.

Postanovka peredayotsya otdeljnyim kommitom posle Linux-postanovki 4dd5a7f33913b17f705e512be1826314da89a4c4. Zakreplyonnyij vkhod tekusjhej integracii vosjmi postavok 186b0360a31b97184773757634976257d0f86495 sokhranyayetsya; etot etap ne menyayet chuzhoj snimok.

## Istochniki i svyazj s planom

- [Tri komandyi, otvetyi i proiskhozhdeniye](https://github.com/fum-lab/fum/blob/8d89a695d6f099091a13d3ce60c924c7098105f2/Журнал/2026-09-11_13-30-58_MSK_подготовить-постановку-Windows-VM-на-macOS/запрос.md); [issledovaniye i granicyi porucheniya koordinatora](https://github.com/fum-lab/fum/blob/8d89a695d6f099091a13d3ce60c924c7098105f2/Журнал/2026-09-11_13-30-58_MSK_подготовить-постановку-Windows-VM-на-macOS/материалы/поручение-координатора.json). Boljshoye issledovaniye polucheno ot koordinatora; zdesj adresno prochitanyi UTM scripting, ukazannyij iskhodnik UTM, Microsoft ARM64 ISO, Windows Setup i material Microsoft o Parallels.
- [Obsjhij cikl Linux VM](Linux-na-macOS.md), [podgotovka khosta STEP0179](kartochki-shagov/🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md), [gostevoj Windows STEP0181](kartochki-shagov/🟡-FUM-STEP-0181-avtomatizirovatj-podgotovku-repozitoriya-na-Windows.md).
- [Avtomatizaciya Windows Setup](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/automate-windows-setup?view=windows-11), [dobavleniye drajverov](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-device-drivers-to-windows-during-windows-setup?view=windows-11), [gostevaya podderzhka UTM](https://docs.getutm.app/guest-support/windows/).
- [UTM Apple Boot](https://docs.getutm.app/settings-apple/boot/), [QEMU ARM virt](https://www.qemu.org/docs/master/system/arm/virt.html), [dokumentaciya CLI Parallels](https://docs.parallels.com/landing/parallels-desktop-developers-guide/command-line-interface-utility/manage-virtual-machines-from-cli/general-virtual-machine-management/create-a-virtual-machine) — adresnyiye oporyi issledovaniya koordinatora dlya posleduyusjhej realizacii.


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 01:09:27 MSK -->
<!-- content-sha256: sha256:bfa0b38d586e10398b4168c7c37b072d0d211ca5d3056a48544214c7ff852cce -->
<!-- FUM-MD-RECENCY:END -->
