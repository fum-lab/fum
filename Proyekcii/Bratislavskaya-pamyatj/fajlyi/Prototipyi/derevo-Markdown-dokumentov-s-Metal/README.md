# Derevo Markdown-dokumentov s otrisovkoj cherez Metal

Etot ustojchivyij Swift-prototip stroit iz katalogov i fajlov `.md` vyibrannogo repozitoriya interaktivnoye iyerarkhicheskoye derevo i vyivodit yego cherez Metal. On proveryayet uzkij graficheskij srez interfejsa FUM: chteniye lokaljnoj strukturyi, podgotovku geometrii, apparatnuyu otrisovku i navigaciyu po krupnoj karte dokumentov. Tekusjhij status — «proveryayetsya».

## Proveryayemyij rezuljtat

Prototip potokovo chitayet vyibrannyij katalog, vklyuchayet fajlyi s rasshireniyem `.md` i toljko ikh katalogi-predki i sokhranyayet roditeljsko-dochernyuyu iyerarkhiyu. Iz obkhoda isklyuchayutsya `.git`, `.build`, `.swiftpm`, kyeshi, kornevyiye `Подузлы`, vlozhennyiye korni Git-repozitoriyev i simvolicheskiye ssyilki. Nechitayemyiye i prevyisivshiye byudzhet puti propuskayutsya s vidimyim schyotchikom, a tekst s povrezhdyonnyim UTF-8 dekodiruyetsya s zamenoj nedopustimyikh posledovateljnostej. Po umolchaniyu odin prokhod ogranichen 200 000 putej, 20 000 dokumentov, glubinoj 128 komponentov, 2 MiB na dokument i 64 MiB prochitannogo Markdown-teksta; prevyisheniye chisla putej ostanavlivayet prokhod s yavnoj oshibkoj. Poluchennoye derevo yavlyayetsya fajlovoj proyekciyej repozitoriya, a ne semanticheskim grafom pamyati FUM: ono ne vyivodit smyislovyiye svyazi iz Markdown-ssyilok, teksta dokumentov, proiskhozhdeniya trebovanij ili operatornoj strukturyi.

Ekran pozvolyayet:

- iskatj uzlyi po imeni;
- vyibiratj katalog ili Markdown-dokument;
- peremesjhatj kartu zhestom panoramirovaniya i menyatj masshtab;
- svorachivatj i raskryivatj vetvi dereva;
- otkryivatj vyibrannyij `.md` shtatnyim sistemnyim prilozheniyem posle povtornoj proverki puti;
- razlichatj katalogi, dokumentyi, vyibrannyij uzel i najdennyiye sovpadeniya.

Dlya boljshikh kart prototip primenyayet urovni detalizacii (`LOD`) i otsecheniye (`culling`): za predelami vidimoj oblasti geometriya ne otpravlyayetsya na otrisovku, a podpisi i vtorostepennyiye detali poyavlyayutsya toljko pri dostatochnom masshtabe. Eti mekhanizmyi proveryayut ustrojstvo puti ot modeli dereva k kadru, no poka ne zadayut i ne podtverzhdayut izmerimyiye porogi proizvoditeljnosti.

## Graficheskij putj

Osnovnoj ekran ispoljzuyet `MTKView`, `MTLDevice` i `MTLCommandQueue`. Fon, ryobra, uzlyi i vyideleniye sobirayutsya cherez `CIContext`, privyazannyij k Metal-ustrojstvu, i zapisyivayutsya v drawable odnim Metal-komandnyim buferom. Podpisi ostayutsya otdeljnyim `CATextLayer`-overleyem i ne vyidayutsya za chastj apparatnoj geometrii. Kod realizuyet vyizov `CIContext.render(...commandBuffer:)` v teksturu tekusjhego drawable; bezokonnaya diagnostika otdeljno podtverzhdayet nalichiye Metal-ustrojstva i sozdaniye komandnoj ocheredi. Korotkij graficheskij smoke-progon podtverzhdayet, chto prilozheniye prokhodit nachaljnoye skanirovaniye i ostayotsya v cikle sobyitij, no ne vyipolnyayet snimok ili obratnoye chteniye kadra.

Yesli Metal-ustrojstvo nedostupno, prilozheniye yavno pokazyivayet ogranichennyij rezhim. Takoj rezhim sokhranyayet vozmozhnostj uvidetj prichinu ogranicheniya, no ne vyidayotsya za proverku apparatnoj otrisovki i ne schitayetsya vyipolneniyem trebovaniya k polnocennomu Metal-puti.

## Zapusk

Nuzhnyi macOS 14+ i Swift 6+. Iz kataloga prototipa bezopasnyij zapusk s kornem tekusjhego repozitoriya vyiglyadit tak:

```bash
./запустить.sh
```

Drugoj katalog repozitoriya mozhno peredatj pervyim argumentom:

```bash
./запустить.sh /путь/к/репозиторию
```

Bezokonnaya diagnostika Metal vyipolnyayetsya otdeljno:

```bash
./запустить.sh диагностика
```

Avtonomnyiye testyi zapuskayutsya iz kataloga prototipa:

```bash
swift test
```

Zapusk i testyi ne trebuyut seti, uchyotnyikh dannyikh ili sekretov. Ispolnyayemoye prilozheniye toljko chitayet vyibrannoye fajlovoye derevo i ne izmenyayet Markdown-dokumentyi, Git-sostoyaniye ili nastrojki Obsidian. Sborka i pervyij `swift run` sozdayut Git-ignoriruyemyij katalog `.build` vnutri kataloga prototipa. Pered yavnyim otkryitiyem prilozheniye zanovo proveryayet, chto kazhdyij komponent puti ne yavlyayetsya simvolicheskoj ssyilkoj, dokument ostayotsya obyichnyim `.md`-fajlom i putj ne vyikhodit za vyibrannyij korenj. Zatem putj peredayotsya shtatnomu prilozheniyu macOS; daljnejsheye povedeniye etogo prilozheniya nakhoditsya za granicej prototipa.

## Granicyi proverki

Bezokonnaya diagnostika podtverzhdayet sozdaniye Metal-ustrojstva i komandnoj ocheredi; iskhodnyij kod i strogaya sborka podtverzhdayut nalichiye puti geometrii cherez `MTKView`, `CIContext` i odin Metal-komandnyij bufer. Vosjmisekundnyij graficheskij smoke-progon ne zavershilsya ranjshe vremeni posle nachaljnoj zagruzki, no pikseljnoye obratnoye chteniye, ruchnaya proverka vsekh vzaimodejstvij i izmereniye chastotyi kadrov ne vyipolnyalisj. Povtornaya proverka puti zasjhisjhayet obyichnoye statichnoye derevo i otkazoustojchivo obrabatyivayet zamenu fajla posle skanirovaniya, no peredacha URL v `NSWorkspace` ne yavlyayetsya atomarnoj zasjhitoj ot zlonamerennoj odnovremennoj podmenyi puti. Prototip ne yavlyayetsya polnoekrannyim interfejsom FUM bez sistemnoj obolochki, ne poluchayet modelj predstavleniya iz kanonicheskoj pamyati ili strukturiruyusjhikh operatorov i ne vozvrasjhayet dejstviya cheloveka v versionirovannyij sobyitijnyij kontur. Semanticheskiye ryobra, sovmestnoye redaktirovaniye, nablyudeniye za izmeneniyami fajlov, polnyij Markdown-parsing i izmerimyiye porogi chastotyi kadrov ili razmera dereva takzhe ne vkhodyat v etot srez.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-14 19:27:55 MSK — Sozdatj derevo dokumentov s otrisovkoj cherez Metal](../../Zhurnal/2026-08-14_19-27-55_MSK_sozdatj-derevo-dokumentov-s-otrisovkoj-cherez-Metal/zapros.md)
- [otrisovka interfejsa cherez Metal](../../Trebovaniya/🟡-otrisovka-interfejsa-cherez-Metal.md)
- [GUI kak proyekciya vnutrennej pamyati i ispolneniya](../../Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md)

## Opornyiye materialyi

- [interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [lokaljnyij navyik zapuska prototipov](../../Instrumentyi/fum-zapusk-prototipov/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 21:55:27 MSK -->
<!-- content-sha256: sha256:934cf5d85a459e8bdb88ca70407b2156383659e16f300cb0565ed6ae585fae8e -->
<!-- FUM-MD-RECENCY:END -->
