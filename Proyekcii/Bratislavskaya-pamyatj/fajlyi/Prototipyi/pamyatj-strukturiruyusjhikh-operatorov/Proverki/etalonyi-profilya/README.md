# Etalonyi serializacii dlya profilya

Dva patcha vosstanavlivayut tochnyiye iskhodniki izmerenij [do](../../../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/materialyi/profilj-do.json) i [posle](../../../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/materialyi/profilj-posle.json) optimizacii iz itogovogo paketa FUM-STEP-0208. Eto istoricheskiye proverochnyiye materialyi odnogo ispolnitelya, ne vtoroj dvizhok i ne aljternativnaya tochka vkhoda produkta.

Patchi sokhranyayut shestj iskhodnyikh Swift-fajlov do pozdnego formatirovaniya i iskhodnuyu versiyu profiljnogo skripta. Otlichiye dvukh izmerennyikh variantov — pryamoye kodirovaniye tipizirovannyikh znachenij i yedinyij bufer bajtov skalyarov. Staryiye stroki nanosekund zagruzki/razbora sokhranenyi kak chastj tochnogo etalona; okonchateljnyij produkt ispoljzuyet chisla dlya vsekh stadij. Chetyire ostaljnyikh Swift-fajla, Package.swift i opredeleniya berutsya iz itogovogo kommita. Vse desyatj SHA-256 iskhodnikov i khyesh skripta sovpadayut s sootvetstvuyusjhim istoricheskim profilem.

## Vosproizvedeniye iz chistogo klona

Nuzhnyi Swift 6.0+, macOS 14+, Python 3 i Git. Iskhodnyiye izmereniya vyipolnenyi Swift 6.4 i Python 3.14.7; vremena i khyesh sobrannogo binarnika zavisyat ot sredyi. Khyeshi iskhodnikov, vkhodov i nablyudenij pozvolyayut sravnitj smyisl i tochnyiye bajtyi rezuljtata nezavisimo ot dliteljnosti.

1. Skopirovatj celikom `Прототипы/память-структурирующих-операторов` iz itogovogo kommita v novyij vneshnij katalog, ne kopiruya susjhestvuyusjhuyu `.build`. Kanonicheskij checkout ostayotsya iskhodnikom dlya obeikh kopij.
2. V korne pervoj vneshnej kopii primenitj `git apply --no-index Проверки/эталоны-профиля/профиль-до.patch.txt`. V drugoj svezhej kopii primenitj `профиль-после.patch.txt` toj zhe komandoj. Patchi ne posledovateljnyiye: kazhdyij primenyayetsya k itogovomu paketu. Do sborki sveritj kazhdyij fajl s `исходники_sha256` i profiljnyij skript s `сценарий_sha256` sootvetstvuyusjhego otchyota.
3. V kazhdoj kopii sobratj `swift build -c release --product FUMStructuringOperatorMemoryProbe`. Komanda `swift build -c release --show-bin-path` vozvrasjhayet katalog gotovogo binarnika. Kopii i ikh `.build` nakhodyatsya vne checkout FUM.
4. V kazhdoj kopii vyipolnitj `python3 -B Проверки/проверить-и-измерить.py --бинарник <путь-к-бинарнику> --выход <внешний-путь-отчёта.json>`. Skript soderzhit shestj otkryityikh vkhodov, opredeleniya i nezavisimyij kodek proverki; delayet po pyatj povtorov kazhdogo scenariya.
5. Sveritj `наблюдение_sha256` po vsem shesti scenariyam mezhdu otchyotami i s istoricheskoj seriyej. Sravnivatj medianyi sootvetstvuyusjhikh stadij pri odnoj srede i rezhime sborki. Prezhniye chislennyiye dliteljnosti ne yavlyayutsya pobitno vosproizvodimyim obesjhaniyem.

Dlya proverki okonchateljnogo produkta ispoljzuyetsya tekusjhij skript iz kanonicheskogo paketa bez patchej; [okonchateljnyij profilj](../../../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/materialyi/profilj-okonchateljnyij.json) otdeljno svyazyivayet ispravlennyij format dliteljnostej s iskhodnikami.

## Proiskhozhdeniye

- [Zapros realizacii](../../../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/zapros.md).
- [Otchyot i adresnaya proverka primeneniya patchej](../../../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/otchyot.md).
- Tochnyiye iskhodnyiye bajtyi vosstanovlenyi iz sobstvennyikh instrumentaljnyikh zapisej sozdaniya i izmeneniya etikh fajlov i sverenyi s uzhe sokhranyonnyimi khyeshami. Pervichnyij JSONL, skryityiye rassuzhdeniya i sluzhebnoye sostoyaniye v materialyi ne vklyuchenyi.

## Pervonachaljnyij proveryayusjhij sravneniya UTF-8

[Proveryayusjhij do usileniya](proveryayusjhij-do-usileniya.py) sokhranyon toljko kak tochnyij istochnik pervonachaljnogo profilya etapa sravneniya: SHA-256 `16c41fa56645aa73f45dcb765c901e8281a82b4e6ab99d74cd8bcaa0aedd4779`. U nego ne zakryityi pustoj sostav proiskhozhdeniya i povtor itogov. Aktualjnaya proverka ispoljzuyet [usilennyij fajl](../proveritj-sravneniye.py). Chtobyi povtoritj pervonachaljnyij profilj, snachala vosstanovite izmerennyij snimok po [osnovnomu receptu sravneniya](../../sravneniye-dekodirovaniya.md): skopirujte vesj prototip vo vneshnij katalog i obyazateljno vernite [prezhniye bajtyi Swift-testa](test-sravneniya-do-pereimenovaniya.swift.txt) na mesto `Tests/FUMStructuringOperatorMemoryTests/ПроверкиСравненияДекодирования.swift`. Zatem v etoj zhe kopii podstavjte sokhranyonnyij proveryayusjhij na mesto `Проверки/проверить-сравнение.py`; iskhodnaya upakovka dannyikh i runner sokhranyayutsya. Odnoj zamenyi proveryayusjhego nedostatochno: sovremennoye imya testa menyayet yego iskhodnyij khyesh. Etot material ne yavlyayetsya aljternativnyim priyomochnyim proveryayusjhim.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 13:31:04 MSK -->
<!-- content-sha256: sha256:e5735b5bddfff100fcc67d0e315ae8c1f357b4132ca0210a0349b5b0185e2eef -->
<!-- FUM-MD-RECENCY:END -->
