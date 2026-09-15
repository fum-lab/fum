+++
schema_version = 1
card_id = "FUM-STEP-0173"
status = "active"
+++
# Razobratj drejf snimka obyyavlenij

## Zadacha

Sopostavitj ostatok obyyavlenij s reviziyej sokhranyonnogo snimka i vosstanovitj dokazuyemuyu granicu kontrolya bez prinyatiya neobyyasnyonnyikh latinskikh imyon.

## Pochemu sejchas

Dopolniteljnaya proverka vyiyavila raskhozhdeniye, susjhestvuyusjheye i bez novyikh iskhodnikov adaptera. Uzkaya proverka poslednego etapa pokazyivayet toljko obyazateljnyij vneshnij metod `unittest.TestCase.setUp`. Osnovaniye — `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0001`.

Povtor `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0002` v FUM-STEP-0207 podtverzhdayet drejf uzhe v osnove `1aab4c016f726452861f42963b59b6ba66483437`: 43606 nablyudayemyikh obyyavlenij protiv 43163 sokhranyonnyikh, pri nulevoj deljte sobstvennyikh izmenenij perenosa. Razbor dolzhen obyyasnitj takzhe eti 443 Python-zapisi; obnovleniye khyesha bez proiskhozhdeniya ne yavlyayetsya ispravleniyem.

## Kriterii zaversheniya

- Poluchen vosproizvodimyij spisok dobavlenij, udalenij i peremesjhenij otnositeljno revizii snimka, s proiskhozhdeniyem po Git.
- Obyyasnenyi prezhniye 13 dopolniteljnyikh zapisej i izmeneniya pozicij; obyazateljnyiye vneshniye obyyavleniya otlichenyi ot sobstvennyikh proveryayemyim kontraktom.
- Nepravomernyiye novyiye imena ustranenyi; snimok obnovlyon toljko posle razbora i podtverzhdyon proverkoj.
- Izmeneniya ispolnyayemogo kontrolya prokhodyat RED/GREEN, profilj i optimizaciyu bez oslableniya granicyi.

## Ogranichennaya postanovka dlya priyomki konteksta

Otdeljnyij ispolnitelj 0173 v svoyom worktree ustranyayet toljko unasledovannuyu deljtu posle zakreplyonnogo snimka 43163 obyyavleniya. Tochnaya reviziya etogo snimka — `436909208424595f7151f6febca75f89018c0bcb`; iskhodnyiye polnyij inventarj 43800 i sravneniye imyon uzhe postroyenyi v priyomke 0165. Trebuyetsya ustanovitj proiskhozhdeniye kazhdogo unasledovannogo dobavleniya, otlichitj obyazateljnyiye vneshniye API, lozhnyiye srabatyivaniya i istoricheskiye bajtyi, bezopasno avtomatizirovatj toljko obosnovannyiye pereimenovaniya. Istoricheskij `продвижение-до-оптимизации.py` sokhranyayet tochnyiye iskhodnyiye bajtyi.

Sobstvennaya deljta 0165 v rabochem kontekste, novyikh russkikh Swift-fajlakh ispolnitelya i yego testakh, a takzhe chetyire CJS-scenariya i ikh prinimayusjhij kontur ostayutsya u kornya 0165. Ikh massovyij perevod ispolnitelyu 0173 ne poruchayetsya. Sovmestnyiye poverkhnosti inventarizatora trebuyut soglasovannoj proverki do integracii; otdeljnaya vetka sama ne ustranyayet konfliktov.

Polnyij snimok obnovlyayetsya toljko posle sovmestnogo dokazannogo razbora obeikh chastej. Polnaya priyomka ispolnyayemyikh izmenenij 0165 trebuyet CLI-profilya «polnyij»; klass obyortki «polnaya» ne vyibirayet yego avtomaticheski. Novyij ispolnitelj startuyet ot opublikovannoj kontroljnoj tochki postanovki, tochnyij OID peredayotsya koordinatorom posle proverki. Drugiye napravleniya ostayutsya na pauze, publikaciya master i integraciya etoj kartochkoj ne razreshayutsya.

## Proverennaya promezhutochnaya postavka Python

[Vtoroj etap 0173](../../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/otchyot.md) sokhranyayet ispravlennoye yadro, khyeshirovannuyu kartu i tochnyij plan 15 fajlov. V gruppe 19 unasledovannyikh instrumentaljnyikh putej mashinnaya sverka ostavlyayet toljko desyatj vneshnikh metodov i dva povtornyikh prisvaivaniya staryikh privyazok. Neobosnovannyiye novyiye sobstvennyiye zapisi etoj gruppyi perevedenyi; obsjhij istoricheskij ostatok etim ne prinyat.

[Sleduyusjhij etap](../../Zhurnal/2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/otchyot.md) perevyol 45 sobstvennyikh zapisej dvukh razreshyonnyikh zhivyikh izmeritelej i obyyasnil globaljnyij effekt Python-skanera: 312 dobavlenij imeyut tochnoye istoricheskoye proiskhozhdeniye, 26 udalenij prinadlezhat vneshnim AST API. V soglasovannoj Python-gruppe neobosnovannyij novyij ostatok raven nulyu. Do zakryitiya ostayutsya obyyedineniye s klassifikaciyej 0165 i obsjhij snimok s polnoj priyomkoj. Istoricheskij before sokhranyayetsya po tochnomu khyeshu. Kartochka ostayotsya aktivnoj; kontroljnaya tochka ne zavershayet shag i ne yavlyayetsya integraciyej.

## Rannyaya granica imyon yavnogo CLI-profilya

`FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0004` vyiyavilo novoye sobstvennoye smeshannoye imya metadannyikh pri podklyuchenii profilya. Proverka do dorogoj priyomki otdelyayet yego ot vneshnikh wire-polej, sokhranyayet pervichnyiye otkazyi i privyazyivayet ispravleniye k tochnyim iskhodnyim SHA. V tekusjhem sreze imya ispravleno i pyatj izmenyonnyikh iskhodnikov vernuli 0 → 0; obsjhij snimok ne obnovlyalsya. Dlya povtoryayemoj meryi nuzhnyi rannyaya proverka sobstvennogo izmenyonnogo nabora i proveryayemaya svyazj pereimenovanij vne vremennoj granicyi s istoricheskimi izmereniyami. Uspekh tekusjhej ruchnoj lokalizacii ne zakryivayet etot obsjhij kriterij.

## Istochniki

- [FUM-SBOJ-0045/PROYAVLENIYE-0004](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md) — novoye sobstvennoye imya v CLI-profile; [rannyaya proverka i vosstanovleniye](../../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/otchyot.md).

- [Sovmestnaya klassifikaciya i vosstanovleniye istoricheskogo massiva](../../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/sovmestnaya-klassifikaciya.md) — poelementno obyyasnenyi43163→43800→43164→43091; novyij neobosnovannyij ostatok soglasovannogo obyyoma ravennulyu. Snimok obnovlyon shtatno; okonchateljnaya polnaya priyomka ostayotsya obyazateljnoj granicej zakryitiya.

- [FUM-SBOJ-0045/PROYAVLENIYE-0003](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md) — povtor priyomki 0165 i osnovaniye tekusjhej ogranichennoj postanovki.
- [Iskhodnaya komanda postanovki](../../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/zapros.md) — prezhneye utochneniye 0002 sokhraneno iz tochnogo `775128491a1b9f9b130bd6946ad2d33fd04dbe51`.

- [FUM-SBOJ-0045/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md).
- [FUM-SBOJ-0045/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md) i [sverka s osnovoj](https://github.com/fum-lab/fum/blob/775128491a1b9f9b130bd6946ad2d33fd04dbe51/Журнал/2026-09-11_07-17-34_MSK_реализовать-перенос-рабочих-деревьев/материалы/профиль/дельта-объявлений.json).
- [Nablyudeniye v etape adaptacii](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 03:14:24 MSK -->
<!-- content-sha256: sha256:fa49683eb4bb63e0b975c2048275ef9594642e20a1b1ebabe3fceb6a2cb77237 -->
<!-- FUM-MD-RECENCY:END -->
