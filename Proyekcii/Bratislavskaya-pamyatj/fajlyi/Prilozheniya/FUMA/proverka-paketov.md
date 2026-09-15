# Proverka chetyiryokh paketov FUMA

Proverka vyipolnyayetsya iz kornya chistogo klona FUM na Mac s ustanovlennyim Swift. Paketyi ispoljzuyut Swift tools 6.0 i yazyik Swift 6; v manifestakh obyyavlena macOS 14. Nablyudyonnaya priyomka vyipolnena na macOS 27 arm64 s Apple Swift 6.4. Ona podtverzhdayet etu sredu, a podderzhka drugikh platform trebuyet otdeljnoj proverki.

Sobstvennyiye zavisimosti zadanyi otnositeljnyimi putyami sosednikh paketov. U kontejnera net paketnyikh zavisimostej; snimok i statistika zavisyat ot kontejnera, arkhiv — ot snimka i kontejnera. Setevyiye SwiftPM-zavisimosti, libmpv i LinguisticKit dlya etikh chetyiryokh sborok ne nuzhnyi. Svyazi s macOS-prilozheniyem v iskhodnoj realizacii ne byilo, perenos yeyo ne dobavlyayet.

## Sborki i testyi

Iz kornya klona vyipolnite posledovateljno:

```sh
FUM_PACKAGES="$PWD/Приложения/FUMA/Packages"
for FUM_PACKAGE in КонтейнерНаблюдений СнимокАгентскойЗадачи СтатистикаВызовов АрхивныйСнимокЗадачи; do
    swift test --package-path "$FUM_PACKAGES/$FUM_PACKAGE" --build-system native --jobs 2 || exit
    swift build --package-path "$FUM_PACKAGES/$FUM_PACKAGE" --build-system native --jobs 2 -c release || exit
done
```

V proverennoj srede primenyon backend `native`; Swift 6.4 preduprezhdayet o yego ustarevanii. Otdeljnyij scratch-katalog zdesj ne zadayotsya: imeyusjhiyesya processnyiye testyi nakhodyat sobstvennyiye vspomogateljnyiye produktyi v `.build/debug` paketa. Etot katalog ignoriruyetsya Git. Kod vozvrata lyuboj komandyi dolzhen byitj nulevyim; rezuljtatyi Swift Testing i XCTest uchityivayutsya otdeljno, poetomu sluzhebnaya stroka o nule testov odnogo frejmvorka ne otmenyayet testyi drugogo.

Pri migracionnoj priyomke vse processyi dopolniteljno zapuskalisj vnutri sistemnoj pesochnicyi s zapretom chteniya prezhnego kataloga iskhodnikov. Rabotosposobnostj zapreta proverena realjnyim otkazom chteniya susjhestvuyusjhego fajla. SwiftPM poluchal `--disable-sandbox` toljko vnutri etoj vneshnej pesochnicyi. Mashinnyij profilj ogranichenij i absolyutnyiye mestopolozheniya ne yavlyayutsya vkhodami obyichnoj sborki; publichnyiye [svideteljstva klona](../../Zhurnal/2026-09-11_01-56-50_MSK_proveritj-paketyi-FUMA-iz-klona/materialyi/chistyij-klon.json) fiksiruyut rezuljtat i granicu proverki.

## Sinteticheskiye profili

Posle Release-sborki sozdajte otdeljnyij vremennyij korenj. Profili poluchayut toljko sozdannyiye imi otkryityiye sinteticheskiye dannyiye. Katalog arkhiva dolzhen otsutstvovatj pered yego zapuskom, ostaljnyiye tri kataloga sozdayutsya zaraneye.

```sh
FUM_PROFILE_ROOT="$(mktemp -d)"
FUM_PROFILE_ROOT="$(cd "$FUM_PROFILE_ROOT" && pwd -P)"
mkdir "$FUM_PROFILE_ROOT/container" "$FUM_PROFILE_ROOT/snapshot" "$FUM_PROFILE_ROOT/statistics"

"$FUM_PACKAGES/КонтейнерНаблюдений/.build/release/профиль-контейнера" записать "$FUM_PROFILE_ROOT/container" 8 65536
"$FUM_PACKAGES/КонтейнерНаблюдений/.build/release/профиль-контейнера" восстановить "$FUM_PROFILE_ROOT/container"
"$FUM_PACKAGES/СнимокАгентскойЗадачи/.build/release/снимок-задачи" профиль "$FUM_PROFILE_ROOT/snapshot" 32
"$FUM_PACKAGES/СтатистикаВызовов/.build/release/статистика-вызовов" профиль --выход "$FUM_PROFILE_ROOT/statistics" --размер малый
"$FUM_PACKAGES/АрхивныйСнимокЗадачи/.build/release/профиль-архивного-снимка" "$FUM_PROFILE_ROOT/archive" 1000000 --служебные-оболочки
```

Zapuskajte kazhdyij sleduyusjhij profilj toljko posle nulevogo koda predyidusjhego. Profilj arkhiva namerenno udalyayet sobstvennyij sinteticheskij vkhod pered vosstanovleniyem bez istochnika. On ne prednaznachen dlya peredannogo realjnogo poljzovateljskogo zhurnala. Profilj snimka nazyivayet stadiyu postroyeniya snimka v pamyati «chistaya-sborka»; eto ne kompilyaciya Swift.

Vyivod soderzhit dliteljnosti i kontroljnyiye pokazateli. Dlya kontejnera sravnivayutsya khyeshi do i posle vosstanovleniya; snimok podtverzhdayet nulevoj prirost khraneniya pri povtorakh; arkhiv sravnivayet rezuljtat pervogo importa, dvukh povtorov i vosstanovleniya bez istochnika. Vremennyiye rezuljtatyi ostayutsya vne Git. Povtor profilya vyipolnyayetsya s novyim kornem.

## Nablyudyonnyij rezuljtat

Na publichnom kommite `aeae18cb146a34563ff39c84d9bc5ef59fffab91` proshli 133 testa: kontejner — 28, snimok — 35, statistika — 35, arkhiv — 35. Vse chetyire Release-sborki uspeshnyi. Vosemj zapuskov zanyali 113,59 s po sistemnomu `time`; naiboljshij maksimaljnyij RSS sostavil 599 212 032 bajta. V eti znacheniya vkhodit rabota sborsjhika, poetomu oni ne opisyivayut pamyatj rabotayusjhej biblioteki.

Pyatj neboljshikh profilej pokazali maksimaljnyij RSS processov ot 7 372 800 do 12 451 840 bajt. Vkhod kontejnera — 512 KiB, snimka — 32 nablyudeniya, statistiki — 32 vyizova, arkhiva — 1 MB sluzhebnyikh obolochek. Eto otdeljnyiye nablyudeniya s tyoplyim fajlovyim kyeshem, bez zayavleniya o predeljnoj nagruzke ili statisticheskoj ustojchivosti vremeni. Perenos ne menyal ispolnyayemyiye bajtyi paketov; novaya optimizaciya im ne trebovalasj.

Polnyiye znacheniya i ogranicheniya sokhranenyi v [otchyote proverki](../../Zhurnal/2026-09-11_01-56-50_MSK_proveritj-paketyi-FUMA-iz-klona/otchyot.md), [rezuljtatakh sborok i testov](../../Zhurnal/2026-09-11_01-56-50_MSK_proveritj-paketyi-FUMA-iz-klona/materialyi/proverki-paketov.json) i [metrikakh profilej](../../Zhurnal/2026-09-11_01-56-50_MSK_proveritj-paketyi-FUMA-iz-klona/materialyi/metriki-rabotyi-paketov.json). Binarniki ostayutsya vne Git; ikh khyeshi oboznachayut proverennyiye produktyi, a ne obesjhaniye determinirovannoj pobajtnoj sborki na drugoj mashine.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:06:43 MSK -->
<!-- content-sha256: sha256:b5201711b9b088f66b43ca879d49985f4c324fba6f2cac810a74f281bda54d7c -->
<!-- FUM-MD-RECENCY:END -->
