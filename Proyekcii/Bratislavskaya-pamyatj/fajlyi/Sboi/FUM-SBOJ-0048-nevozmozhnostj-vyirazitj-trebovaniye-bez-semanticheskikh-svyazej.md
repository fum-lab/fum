+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0048"
"статус" = "устранена"
+++
# Nevozmozhnostj vyirazitj trebovaniye bez semanticheskikh svyazej

## Istoriya identifikatora

Pervonachaljnyij identifikator — `FUM-СБОЙ-0046`, pervonachaljnoye oboznacheniye yedinstvennogo proyavleniya — `FUM-СБОЙ-0046/ПРОЯВЛЕНИЕ-0001`. Kartochka vpervyiye sokhranena kommitom `0246844fe15ba51e48327005b33bc78b668f813a`. Tekusjhij soglasovannyij identifikator — `FUM-СБОЙ-0048`; prezhneye proyavleniye sootvetstvuyet `FUM-СБОЙ-0048/ПРОЯВЛЕНИЕ-0001` i ne yavlyayetsya novyim sluchayem.

Prichina perekhoda — mezhvetochnaya kolliziya: snimok `68996460643a50d47cfc6e121b34cc0911639f26` zakrepil 0046 za inyim sboyem dopisyivaniya JSONL. [Soglasovaniye perenosa](../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/zapros.md) razreshayet tekusjhij ID, imya i zhivyiye ssyilki izmenitj obyichnyim posleduyusjhim kommitom s sokhraneniyem opublikovannoj istorii. Sam mekhanizm kollizii uchtyon otdeljno v [FUM-SBOJ-0050](FUM-SBOJ-0050-vyideleniye-globaljnogo-identifikatora-iz-lokaljnogo-maksimuma.md). Istoricheskiye upominaniya 0046 i prezhniye dokazateljstva ustraneniya sokhranyayutsya.

## Nablyudayemyij sboj

Pri podgotovke nezavisimyikh trebovanij obnaruzheno protivorechiye vkhodnogo kontrakta planovogo reyestra. Kazhdaya kartochka obyazana soderzhatj nepustoj razdel `Семантические связи`, no razbor etogo razdela prinimayet toljko tipizirovannyiye otnosheniya s drugimi trebovaniyami. Pustoj razdel otklonyayetsya kak otsutstvuyusjhij, a chestnoye soobsjheniye ob otsutstvii ustanovlennyikh svyazej — kak neverno oformlennoye otnosheniye. Pri etom obsjhij istochnik ili obsjhaya tema ne dayut osnovaniya sozdavatj svyazj.

## Granica povtoreniya

Kanonicheskaya kartochka samostoyateljnogo trebovaniya ne imeyet obosnovannyikh pryamyikh otnoshenij s drugimi trebovaniyami. Reyestr dolzhen sokhranitj yeyo s pustyim spiskom semanticheskikh svyazej bez vyidumannogo rebra. Otkaz iz-za postoronnego poyasneniya ryadom s nastoyasjhej tipizirovannoj svyazjyu otnositsya k obyichnoj proverke vkhoda i ne vkhodit v etot sboj.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                         | Effekt                                                                                                | Vosstanovleniye                                                                                                  |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0048/ПРОЯВЛЕНИЕ-0001` | [Diagnostika kontrakta](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/otchyot.md) i [vosproizvedeniye RED](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/materialyi/zapuski-proverok/1_139fd49f-cded-47b2-b5c3-61824ed2a0d8.json) | Nezavisimoye trebovaniye neljzya predstavitj korrektnoj kanonicheskoj kartochkoj bez neobosnovannoj svyazi. | Vvesti tochnoye yavnoye oboznacheniye otsutstviya svyazej i proveritj sokhraneniye prezhnej strogosti nastoyasjhikh otnoshenij. |

## Ozhidaniye i klassifikaciya

Eto defekt vyiraziteljnosti mashinnogo kontrakta. [Pravila kartochek trebovanij](../Trebovaniya/README.md) trebuyut obosnovannoj paryi otnoshenij i pryamo isklyuchayut obsjhuyu temu ili obsjhij istochnik kak dostatochnoye osnovaniye svyazi. Samostoyateljnoye trebovaniye dopustimo; otsutstviye ustanovlennyikh svyazej ne oznachayet otsutstviye samogo trebovaniya.

## Mekhanizm i sistemnoye ustraneniye

V `extract_requirement_cards` proveryayetsya nepustoye soderzhimoye vsekh obyazateljnyikh razdelov. Zatem `parse_requirement_relations` trebuyet ot kazhdoj nepustoj stroki format tipizirovannogo otnosheniya. Sovmestnoye dejstviye etikh uslovij isklyuchalo lyuboye korrektnoye predstavleniye pustogo grafa.

Ogranichennoye ustraneniye vvodit yedinstvennyij polnyij tekst razdela: `Прямые семантические связи пока не установлены.`. Vneshniye probelyi ne menyayut etot marker; on dayot pustoj spisok otnoshenij. Marker ne smeshivayetsya s otnosheniyami ili proizvoljnyim tekstom. Pustoj libo propusjhennyij razdel po-prezhnemu zapresjhyon. Proverki tipov, adresatov, povtorov i obratnyikh otnoshenij sokhranyayutsya.

## Svyazannyiye shagi

Otdeljnyij shag ne trebuyetsya: etot defekt ustranyon i proveren v toj zhe sessii v privedyonnoj granice. Eto ne zavershayet trebovaniya planiruyemyikh napravlenij i ne podtverzhdayet ikh realizaciyu.

## Kriterii zakryitiya

Samostoyateljnoye trebovaniye s tochnyim markerom prokhodit sborku i validaciyu reyestra s pustyim spiskom otnoshenij. Netochnyij, povtornyij libo smeshannyij marker otklonyayetsya. Marker ne skryivayet vkhodyasjhuyu svyazj bez trebuyemoj obratnoj paryi; nastoyasjhiye otnosheniya sokhranyayut prezhniye proverki. Format yavno opisan v pravilakh kartochek trebovanij.

## Podtverzhdeniye ustraneniya

Do izmeneniya parsera odin i tot zhe avtonomnyij nabor iz shesti testov dal dva isklyucheniya i odin neuspeshnyij assert (kod 1). Posle dvukhstrochnogo dopuska vse shestj testov proshli (kod 0), vklyuchaya polnyij build/validate fiksturyi i sokhraneniye otkaza otsutstvuyusjhej obratnoj paryi. Otdeljnaya regressiya sborsjhika — 65 testov, kod 0. Fakticheskij reyestr s FUM-REQ-0048 sobran i sveryon, kod 0. Proverennyij iskhodnyij HEAD — `5cd2e653de6c3a0749534f07d72ebf1f66c7048f`; tochnyiye khyeshi ispolnyayemyikh fajlov i profilj sokhranenyi v [materialakh etapa](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/materialyi/profilj-dopuska.json).

Dokazateljstvo svyazyivayet odin i tot zhe regressionnyij test `ПроверкиОтсутствияСемантическихСвязей.test_явный_маркер_даёт_пустой_граф_при_сборке_и_валидации` s otkazom do ispravleniya i uspekhom posle nego: [RED](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/materialyi/zapuski-proverok/1_139fd49f-cded-47b2-b5c3-61824ed2a0d8.json), [GREEN](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/materialyi/zapuski-proverok/2_866c1d45-13d8-44e6-a5b8-2309ccaf6028.json). [Proverka fakticheskogo reyestra](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/materialyi/zapuski-proverok/6_e171e03a-dcbe-466e-9b17-3f3e9c1dd76e.json) podtverzhdayet primenimostj ispravleniya k tekusjhim kartochkam. Polnaya priyomka serii i yeyo posleduyusjhaya integraciya ostayutsya otdeljnyim etapom.

## Istochniki

- [Iskhodnyij zapros etapa](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/zapros.md).
- [Otchyot etapa](../Zhurnal/2026-09-11_01-07-38_MSK_zaplanirovatj-decentralizovannyiye-seti/otchyot.md).
- [Pravila kartochek trebovanij](../Trebovaniya/README.md).
- [Sborsjhik planovogo reyestra](../Instrumentyi/fum-reyestr-planirovaniya/scripts/build-planning-registry.py).
- [Regressionnyiye proverki otsutstviya semanticheskikh svyazej](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_pustyiye_svyazi_trebovanij.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:02:09 MSK -->
<!-- content-sha256: sha256:a478041f30fd215fad6fba12ccfbcb98449e87316d9c5ca995c777c3749e4f76 -->
<!-- FUM-MD-RECENCY:END -->
