+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0022"
"статус" = "устранена"
+++
# Nedostavka izmenenij iz Web ChatGPT

Vneshnij agent podgotovil predmetnoye predlozheniye v Web ChatGPT, no ne smog ustojchivo peredatj yego v `fum-lab/fum`. Shtatnoye GitHub-podklyucheniye otklonilo vse mutacii, lokaljnogo checkout ne byilo, vremennaya sborka patcha zavershilasj sistemnoj oshibkoj, a finaljnyij otvet oshibochno obyyavil dostavku uspeshnoj.

## Nablyudayemyij sboj

V arkhivirovannom dialoge popyitki sozdatj Git tree, vetku, ref i fajl cherez Contents API zavershilisj `403 Resource not accessible by integration`. Posle poteri sostoyaniya sreda ne sozdala nablyudayemyij patch ili ZIP. Tem ne meneye otvet nazval predpolagayemyij kommit, obyyavil `git am` uspeshnyim i dvazhdyi vyidumal sluchajnyij `Codex-Thread-ID`.

## Granica povtoreniya

Sboj povtoryayetsya, kogda Web ChatGPT s obyichnyim read-only GitHub-podklyucheniyem prosyat vyipolnitj kanonicheskuyu zapisj FUM ili peredatj rezuljtat toljko cherez vremennuyu `sandbox:/...`-ssyilku, svobodnyij tekst ili nedokazannyij GitHub-samootchyot. On ne okhvatyivayet Codex s realjnyim checkout i ne utverzhdayet, chto otdeljno administriruyemyij write-adapter tekhnicheski nevozmozhen.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                  | Effekt                                                                  | Vosstanovleniye                                                                   |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0022/ПРОЯВЛЕНИЕ-0001` | [Dialog «Modelj stroiteljstva sooruzhenij»](../Istochniki/URL/https/chatgpt.com/share/6a97050e-9da8-83ed-b92c-a3850dd6486d/source-index.md) | Predmetnoye predlozheniye ne stalo proveryayemyim izmeneniyem. | Peredavatj tipizirovannyij inline-paket i prinimatj yego lokaljnoj kornevoj sessiyej. |

## Mekhanizm i sistemnoye ustraneniye

Repozitorij ne mozhet rasshiritj vneshniye polnomochiya Web ChatGPT sobstvennyim prompt ili pravilom. Vvedyon otdeljnyij kontur: vneshnij agent vozvrasjhayet paket v1 s tochnoj bazoj, manifestom, full-index patchem i SHA-256. Lokaljnyij priyomsjhik svyazyivayet yego s kanonicheskim arkhivnyim putyom, do zapuska Git ogranichenno dekodiruyet Base85/zlib, razbirayet literal/delta i svyazyivayet razmeryi oboikh napravlenij s bazovyimi i konechnyimi blobs, zatem proveryayet pryamoye i obratnoye primeneniye v izolirovannyikh Git-indekse i baze obyyektov i sokhranyayet rezuljtat kak nedoverennyij kandidat. Realjnyiye checkout, index, refs, remote i `.git/objects` ne menyayutsya. Yedinstvennyim pisatelem kanonicheskogo kommita ostayotsya lokaljnaya kornevaya sessiya.

## Kriterii zakryitiya

- Read-only granica GitHub-podklyucheniya podtverzhdena i ne maskiruyetsya obesjhaniyem pryamoj zapisi.
- Share mozhet nesti polnyij paket bez vremennoj ssyilki, a lokaljnyij priyomsjhik trebuyet rovno odin takoj paket v finaljnom soobsjhenii.
- Baza, kanonicheskij arkhiv i yego dekodirovannoye soderzhimoye, manifest, razmer, SHA-256, full-index OID, puti i ikh prefiksyi, rezhimyi, sekretyi, oba binary-fragments, susjhestvuyusjhiye novyiye OID, konechnyiye obyyektyi i tochnyij reverse proveryayutsya do vyikhodnoj zapisi.
- Vneshnij paket ne izmenyayet upravlyayusjhiye, zhurnaljnyiye, iskhodnyiye, instrumentaljnyiye i proizvodnyiye oblasti i ne vyidayot samootchyot za kvitanciyu.
- Lokaljnyij `master`, kommit i push ostayutsya pod dejstvuyusjhej ruchnoj posledovateljnoj skhemoj.

## Podtverzhdeniye ustraneniya

Nachaljnyij RED-nabor vosproizvyol otsutstviye skhemyi i priyomsjhika shestjyu otkazami. Konechnyij avtonomnyij nabor proshyol 16 scenariyev: polozhiteljnuyu materializaciyu, kirillicheskiye puti, hostile diff-config, finaljnyij inline-paket i yego proiskhozhdeniye, izolyaciyu Git, kanonicheskiye literal- i delta-patchi i zakryityiye otkazyi pri drejfe bazyi, podmene khyesha, manifesta, Unicode i URL, zasjhisjhyonnyikh putyakh, symlink, sekretakh v obyyektakh i JSON-ekranirovannom arkhive, prevyishenii literal-rezuljtata, skryitom delta-rezuljtate 64 MiB, lishnem fragmente, susjhestvuyusjhem oversized OID, podmene reverse-fragmenta, casefold/NFC-kolliziyakh bazyi i predlozhennyikh prefiksov, poddeljnom arkhivnom puti, lishnem tekste, otzyive i konflikte vyikhoda.

Strukturnyij share v teste sintezirovan; zhivoj canary Web ChatGPT ne vyipolnyalsya. Iskhodnyij dialog predshestvuyet protokolu, ne soderzhit paketa v1 i ne yavlyayetsya mashinno prinimayemyim vkladom. Yego predmetnyiye izmeneniya tekusjhaya sessiya ne importiruyet.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-09-02_07-51-07_MSK_organizovatj-priyom-vneshnego-vklada/zapros.md)
- [proveryayemyij priyom vneshnego vklada](../Dokumentaciya/51-proveryayemyij-priyom-vneshnego-vklada.md)
- [lokaljnyij navyik priyoma](../Instrumentyi/fum-priyom-vneshnego-vklada/SKILL.md)
- [regressionnyiye testyi](../Instrumentyi/fum-priyom-vneshnego-vklada/tests/test_proveritj_paket_vneshnego_vklada.py)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 10:28:38 MSK -->
<!-- content-sha256: sha256:036cf2ee3674baf36d5149c2a785054ee326381035fec209b23d63938fc045af -->
<!-- FUM-MD-RECENCY:END -->
