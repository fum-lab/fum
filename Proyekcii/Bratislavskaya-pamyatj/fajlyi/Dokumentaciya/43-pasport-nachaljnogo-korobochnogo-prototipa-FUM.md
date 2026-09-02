# Pasport nachaljnogo korobochnogo prototipa FUM

Nachaljnyij [korobochnyij prototip FUM](../Glossarij/korobochnyij-prototip-FUM.md) — minimaljnyij lokaljnyij Swift-kontur, kotoryij proveryayet ne vneshnij vid prilozheniya, a sobstvennyij putj izmeneniya pamyati FUM. Yego osnovnoj scenarij obyazan vyipolnyatjsya bez WindowServer, AppKit i SwiftUI. Posleduyusjhiye srezyi nachaljnoj inzhenernoj stadii takzhe mogut ostavatjsya polnostjyu bez sobstvennogo GUI FUM: poljzovateljskij interfejs ne yavlyayetsya barjyerom ikh zapuska ili priyomki.

## Seed-kontur

Prototip nachinayet s malogo yavno versionirovannogo seed: pustogo libo minimaljno dopustimogo sostoyaniya pamyati, nabora razreshyonnyikh tipov sobyitij i versii politiki perekhodov. Fikstura opisyivayet vkhodyi, no ne soderzhit gotovogo ozhidayemogo snimka kak sposoba zapolneniya pamyati. Vremya, sluchajnostj, setj, vneshnyaya LLM i sostoyaniye mashinyi ne dolzhnyi neyavno vliyatj na rezuljtat.

Pervyij samostoyateljnyij paket nakhoditsya v [kataloge vosproizvodimogo popolneniya pamyati](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md). On sluzhit ispolnyayemoj proverkoj pasporta, a ne otdeljnyim istochnikom produktovyikh trebovanij.

## Shtatnyij putj popolneniya

Kazhdoye nablyudeniye prokhodit odin i tot zhe putj:

`версионированное входное событие → проверка → внутренний переход → фиксация происхождения → канонический снимок → наблюдаемая трасса`.

[Shtatnoye popolneniye pamyati FUM](../Glossarij/shtatnoye-popolneniye-pamyati-FUM.md) zapresjhayet testu napryamuyu podmenyatj prinyatuyu pamyatj ozhidayemyim rezuljtatom. Otkloneniye yavlyayetsya polnocennyim nablyudayemyim iskhodom i ne maskiruyetsya propuskom sobyitiya. Vse identifikatoryi, versii i poryadok serializuyutsya kanonicheski, chtobyi povtornyij zapusk mozhno byilo sravnitj pobajtno libo po yavno opredelyonnomu kanonicheskomu predstavleniyu.

## Granica vnutrennego ispolneniya

Nachaljnyij runtime vyipolnyayet toljko chistyiye lokaljnyiye perekhodyi nad peredannyim sostoyaniyem. On ne poluchayet setj, proizvoljnyij dostup k vneshnim servisam, realjnuyu LLM, GUI-frejmvork ili fizicheskiye dejstviya. Vyikhodom yavlyayetsya inertnyij otchyot, a ne komanda obolochki ili skryityij pobochnyij effekt.

Kontur pereispoljzuyet arkhitekturnyiye svojstva [pamyati strukturiruyusjhikh operatorov](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/README.md), [chistogo modeljnogo shaga](41-kontrakt-chistogo-modeljnogo-shaga.md) i [nablyudayemoj trassyi agentskogo cikla](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md), no ne obyyavlyayet eti samostoyateljnyiye prototipyi uzhe soyedinyonnyim produktovyim runtime.

## Kriterij vosproizvodimosti

Minimaljnyij obrazec prinimayetsya, yesli:

- iz odinakovyikh versionirovannyikh seed, vkhodov i politiki dva chistyikh zapuska poluchayut odinakovyiye kanonicheskiye snimok i trassu;
- izmeneniye vkhodnogo sobyitiya privodit k nablyudayemomu izmeneniyu rezuljtata libo k yavnomu otkloneniyu;
- poryadok prinyatyikh perekhodov i proiskhozhdeniye kazhdogo elementa pamyati vosstanavlivayutsya iz otchyota;
- bezopasnaya komanda zapuska i avtonomnyiye testyi ne trebuyut seti, GUI i vneshnikh zavisimostej;
- granicyi prototipa ne vyidayut konechnuyu fiksturu za dolgovremennuyu pamyatj, polnocennyij agentskij cikl ili produktovyij reliz.

## Bezokonnaya inzhenernaya rabota cherez Codex

Vneshnyaya agentskaya sessiya Codex mozhet byitj polnoj inzhenernoj poverkhnostjyu nachaljnoj stadii. Ona vyizyivayet versionirovannyiye lokaljnyiye tochki vkhoda, peredayot vkhodyi cherez argumentyi, standartnyij vvod ili fajlyi, chitayet iskhodniki i sokhranyonnoye sostoyaniye, sravnivayet kanonicheskiye otchyotyi, zapuskayet avtonomnyiye testyi i obyyasnyayet nablyudayemyiye oshibki. Dlya etogo konturu nuzhnyi fajlovyiye i CLI-interfejsyi, kodyi zaversheniya i mashinochitayemyiye rezuljtatyi, no ne okno FUM, renderer, snimki ekrana ili ruchnyiye dejstviya v GUI.

Codex ostayotsya vneshnim stendom, a ne skryityim komponentom prototipa. Vosproizvodimostj zadayut sokhranyonnyiye vkhodyi, versii, komandyi, artefaktyi i testyi; tot zhe scenarij dolzhen byitj dostupen obyichnomu neinteraktivnomu processu bez konteksta konkretnoj sessii Codex. Soglasiye modeli samo po sebe ne yavlyayetsya proverkoj, a vneshneye upravleniye ne dokazyivayet sobstvennyij [agentskij cikl FUM](../Glossarij/agentskij-cikl.md), realjnyij modeljnyij provajder ili gotovnostj poljzovateljskogo interfejsa.

## Podtverzhdyonnyiye pokoleniya pamyati

Prinyatoye sostoyaniye sokhranyayetsya kak kanonicheskoye neizmenyayemoye pokoleniye s versiyami skhemyi i politiki, SHA-256 kanonicheskoj programmyi sobyitij tekusjhego perekhoda, ssyilkoj na predyidusjheye pokoleniye, polnyimi snimkom, trassoj i proiskhozhdeniyem. Skhema pokoleniya `2` dopolniteljno vstraivayet yavnyij versionirovannyij pustoj seed i polnyij kumulyativnyij zhurnal kanonicheskikh tel prinyatyikh sobyitij. Validator vyivodit tekusjhuyu programmu kak vesj zhurnal nachaljnogo pokoleniya libo dobavlennyij suffiks prodolzheniya, proveryayet khyeshi i svyazj sobyitij s trassoj, a zatem sam povtorno ispolnyayet tochnuyu versiyu reduktorov `remember` i `compose` i sravnivayet vyichislennyiye snimok, trassu, proiskhozhdeniye i proyekciyu s sokhranyonnyimi artefaktami.

Fajl kandidata polnostjyu zapisyivayetsya vo vremennoye imya, sinkhroniziruyetsya cherez `fsync`, publikuyetsya bez zamesjheniya kak adresuyemoye pokoleniye i zakreplyayetsya sinkhronizaciyej kataloga `generations/` do izmeneniya ukazatelya `CURRENT`. Kazhdyij sotrudnichayusjhij process zakreplyayet tochnyij ozhidayemyij khyesh roditelya, poluchayet eksklyuzivnuyu blokirovku postoyannogo `CURRENT.lock`, zanovo chitayet podtverzhdyonnoye sostoyaniye pod blokirovkoj i toljko pri sovpadenii polnostjyu zapisyivayet i sinkhroniziruyet vremennyij ukazatelj, atomarno zamenyayet `CURRENT.json` i sinkhroniziruyet kornevoj katalog. Tochnyij povtor prinyatogo pokoleniya idempotenten, a proigravshij poluchayet tipizirovannyij konflikt i mozhet ostavitj toljko nepodtverzhdyonnyij adresuyemyij obyyekt.

Vosstanovleniye doveryayet toljko tochnomu ukazatelyu i povtorno proveryayet yego skhemu, kanonichnostj, khyesh fajla, vnutrenniye khyeshi i proiskhozhdeniye; ono ne skaniruyet katalog pokolenij i ne povyishayet sirotu. Vosemj tochek do i posle publikacii pokoleniya i ukazatelya proverenyi otdeljnyimi writer- i recovery-processami s prinuditeljnyim `SIGKILL`: novyij process vidit toljko prezhneye libo polnostjyu proveryayemoye novoye pokoleniye. Eto dokazyivayet process-crash consistency dannogo lokaljnogo protokola, no ne vzaimnoye isklyucheniye potokov odnogo processa, sovmestimostj setevoj fajlovoj sistemyi ili power-loss durability. `fsync` zadayot poryadok zaprosov k OS, a realjnaya sokhrannostj pri otklyuchenii pitaniya trebuyet otdeljnogo stenda s zakreplyonnyimi fajlovoj sistemoj, nositelem i rezhimami kyesha.

Prodolzheniye nachinayetsya iz poslednego podtverzhdyonnogo pokoleniya, sokhranyayet `dataset_id`, neizmennyiye prefiksyi zhurnala i trassyi, a takzhe neizmennostj raneye podtverzhdyonnyikh zapisej, prodolzhayet nomera i identifikatoryi sobyitij i ne dopuskayet povtornoj celi. Povrezhdyonnyij, nesovmestimyij ili prervannyij kandidat ne smesjhayet `CURRENT`, poetomu poslednij podtverzhdyonnyij snimok ostayotsya dostupnyim. Samodostatochnoye [vosproizvedeniye prinyatogo epizoda FUM](../Glossarij/vosproizvedeniye-prinyatogo-epizoda-FUM.md) rabotayet iz samogo pokoleniya bez prezhnego chata, vneshnej fiksturyi ili novogo modeljnogo vyizova. Pokoleniye skhemyi `1` ne perepisyivayetsya molcha i otklonyayetsya s yavnoj prichinoj, potomu chto utrachennyiye tela sobyitij neljzya vyivesti iz odnikh khyeshej.

## Perekhod k GUI

Operator `fum.view-projection.operator.v1` uzhe vyivodit inertnuyu deklarativnuyu modelj predstavleniya toljko iz prinyatoj pamyati: kazhdyij element sokhranyayet klyuch zapisi, porodivsheye sobyitiye, sobyitiya-vkladyi i versiyu operatora. Dopustimoye namereniye poljzovatelya preobrazuyetsya obratno v obyichnuyu versionirovannuyu programmu sobyitij pamyati. Validator pokoleniya povtorno stroit proyekciyu i otvergayet otdeljnuyu domennuyu istinu predstavleniya.

Eto yesjhyo ne zhiznesposobnyij GUI. Toljko posle otdeljnogo resheniya i vosproizvodimoj proverki modeli k nej mozhet byitj podklyuchyon renderer. Minimaljnoye dokazateljstvo budusjhego skvoznogo GUI-puti dolzhno svyazatj khotya byi odin element i odno dejstviye cepochkoj:

`память/оператор → модель представления → renderer → пользовательское событие → проверяемое изменение памяти`.

Gotovyij ekran neljzya pomesjhatj v seed kak ozhidayemyij snimok, a paralleljnoye ruchnoye sostoyaniye GUI ne dolzhno stanovitjsya vtoryim istochnikom istinyi. Tekusjhaya modelj ostayotsya `headless`, ne soderzhit ispolnyayemogo Swift-koda i ne vyibirayet UI-frejmvork. Tochnaya razreshyonnaya forma renderer i kriterij zhiznesposobnosti ostayutsya [otkryityim voprosom o granice GUI iz vnutrennikh mekhanizmov FUM](../Voprosyi/2026-07-24_10-44-28_MSK_granica-GUI-iz-vnutrennikh-mekhanizmov-FUM.md).

## Neceli nachaljnogo obrazca

Pasport ne trebuyet na nachaljnoj inzhenernoj stadii okna, Metal, setevogo importa, realjnoj modeli, proizvoljnoj samogeneracii koda, dolgovremennogo fonovogo processa ili produktovoj gotovnosti. On takzhe ne otmenyayet [pervyij produktovyij URL-srez](36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md): zamechaniya k yego pasportu zakryityi povtornoj proverkoj, no sama integraciya ostayotsya boleye pozdnej do otdeljnogo razresheniya produktovoj realizacii i yeyo priyomki; zhivoj setevoj dostup trebuyet samostoyateljnogo resheniya o polnomochiyakh.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-28 07:49:45 MSK — Dobavitj avarijnuyu soglasovannostj khranilisjha pamyati](../Zhurnal/2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-28 00:54:15 MSK — Dobavitj mezhprocessnyij CAS ukazatelya pamyati](../Zhurnal/2026-07-28_00-54-15_MSK_dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-27 22:17:40 MSK — Sokhranitj kanonicheskiye sobyitiya i dokazatj vosproizvedeniye](../Zhurnal/2026-07-27_22-17-40_MSK_sokhranitj-kanonicheskiye-sobyitiya-i-dokazatj-vosproizvedeniye/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:10:35 MSK — Razreshitj nachaljnuyu korobochnuyu FUM bez GUI cherez Codex](../Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [arkhitektura FUM](22-arkhitektura-FUM.md)
- [interfejs FUM-uzla](25-interfejs-FUM-uzla.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:9a8695ed69e42ab8c17a9cadbf6f320050c7c74072e4162b096f3f3e2e99335f -->
<!-- FUM-MD-RECENCY:END -->
