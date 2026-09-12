# Universaljnoye parametricheskoye 3D i vizualizaciya FUMA

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0077 -->

V sostave FUMA dolzhno razvivatjsya universaljnoye parametricheskoye 3D-modelirovaniye i vizualizaciya. Obsjhaya celj okhvatyivayet tekhnicheskiye detali i sborki, arkhitekturu i pomesjheniya, svobodnyiye formyi i vizualizaciyu; landshaft, eksterjyer, interjyer, lyudej i ikh animaciyu, mekhanizmyi. Te zhe opisaniya i obsjhiye mekhanizmyi dolzhnyi imetj proveryayemyiye primeneniya v igrakh, virtualjnoj i dopolnennoj realjnosti. Ni CAD, ni odin sposob rendera ne zamenyayut etot polnyij obyyom.

Scenyi zadayutsya kodom i strukturiruyusjhimi operatorami FUM. Opredeleniya susjhnostej, parametrov, zavisimostej, ogranichenij, svyazej i povedeniya vkhodyat v obsjhij kanonicheskij graf i ispolnyayutsya cherez yavnyiye versii operatorov. Redaktor i renderer pokazyivayut proizvodnoye sostoyaniye; dejstviya vozvrasjhayutsya v obsjhij sobyitijnyij kontur. Sintaksis opisaniya scen, geometricheskoye predstavleniye, dvizhok, biblioteki i graficheskiye API konkretnyikh profilej etim trebovaniyem ne vyibirayutsya.

## Kriterii proverki

- Matrica pokryitiya sokhranyayet vse tri vyibrannyiye gruppyi i kazhduyu nazvannuyu predmetnuyu oblastj, a takzhe igryi, VR i AR. Dlya kazhdoj stroki opredelenyi neobkhodimyiye susjhnosti, operacii, predstavleniye rezuljtata, otkryityij primer i otdeljnyij kriterij budusjhej proverki. Vyipolneniye odnoj stroki ne zakryivayet ostaljnyiye.
- Opredelyon putj kod/strukturiruyusjhiye operatoryi → kanonicheskij graf scenyi → parametricheskoye vyichisleniye i povedeniye → predstavleniye → vizualizaciya i vzaimodejstviye. Ustanovlenyi yedinicyi, koordinatyi, masshtab, vremya, identichnostj, proiskhozhdeniye, ssyilki, izmeneniye parametrov i proveryayemyij pereschyot zavisimogo sostoyaniya.
- Modelj razlichayet geometriyu, sborki i ogranicheniya; okruzheniye, kameryi i materialyi; predstavleniye lyudej, pozyi i animaciyu; mekhanizmyi i ikh dvizheniye. Dlya tekhnicheskoj tochnosti, svobodnyikh form i interaktivnoj vizualizacii ustanovlenyi sobstvennyiye dopuski i granicyi vyibrannyikh predstavlenij. Izobrazheniye ne schitayetsya dokazateljstvom korrektnoj geometrii ili kinematiki.
- Igrovoye primeneniye imeyet yavnyiye sobyitiya, sostoyaniye, shag vremeni, vzaimodejstviye i vosproizvodimoye logicheskoye povedeniye. VR otdeljno opredelyayet stereopredstavleniye, pozu i vvod, sistemu koordinat i vremennyiye ogranicheniya. AR otdeljno opredelyayet privyazku scenyi k okruzheniyu, nablyudeniye/kalibrovku i granicyi dostupa k dannyim. Dlya VR i AR nuzhnyi sobstvennyiye profili ustrojstva i priyomka; obyichnyij ekran ikh ne podtverzhdayet.
- Obsjhiye mekhanizmyi interpretacii, pamyati, grafa, sobyitij, resursov i vosstanovleniya pereispoljzuyutsya po fakticheskoj gotovnosti. Formatnyiye pravila i predmetnyiye operacii vidimyi v opredeleniyakh operatorov; nezavisimyij skryityij parser ili vtoraya domennaya istina renderer ne zamenyayut etot kontrakt. Muzyikaljnyij instrument ostayotsya samostoyateljnoj chastjyu FUMA, dazhe pri vozmozhnom sovmestnom ispoljzovanii vremeni ili resursov.
- Dlya oshibochnyikh parametrov, ssyilok i dannyikh opredelenyi nablyudayemyiye otkazyi, predelyi pamyati, razmera scenyi, rabotyi i vremeni, otmena i vosstanovleniye. Ciklicheskiye svyazi ili sistema ogranichenij otlichenyi ot neogranichennoj rekursii ispolneniya; dopustimyiye iteracii imeyut yavnyij predel i kriterij skhodimosti.
- Kanonicheskij logicheskij rezuljtat i sokhranyonnyiye operacii imeyut vyibrannuyu vosproizvodimuyu oporu. Dlya geometricheskikh vyichislenij i kadrov otdeljno zadanyi dopustimyiye chislennyiye razlichiya i profilj platformyi; pobajtovoye ravenstvo na vsekh GPU, tochnaya fizika i promyishlennaya prigodnostj ne predpolagayutsya avtomaticheski.
- Lokaljnyiye scenarii imeyut yavnyij komplekt iskhodnikov, dannyikh, modelej i neobkhodimyikh zavisimostej s proiskhozhdeniyem i pravami dostavki. Otsutstviye seti sokhranyayet zayavlennuyu lokaljnuyu rabotu. Budusjhiye vneshniye komponentyi ne stanovyatsya vyibrannyimi zavisimostyami ot odnogo upominaniya; sobstvennyij kod CC0 i prava storonnikh assetov razlichayutsya.

## Semanticheskiye svyazi

- **dopolnyayet:** [GUI kak proyekciya vnutrennej pamyati i ispolneniya](🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md) — rasprostranyayet obsjhij kanonicheskij istochnik sostoyaniya i obratnyikh dejstvij na parametricheskiye prostranstvennyiye scenyi, ne podmenyaya obsjheye trebovaniye GUI.

## Status i granicyi

Status trebovaniya — `🟡`.

Pervyij rezuljtat — konechnyij arkhitekturnyij plan i proveryayemyiye etapyi realizacii vsego napravleniya. Gotovyij universaljnyij dvizhok, redaktor, render, igra, VR/AR-podklyucheniye i prokhozhdeniye tekhnicheskikh ili fizicheskikh dopuskov ne zayavlyayutsya. Vyibor pervogo ogranichennogo ispolnyayemogo sreza v plane ne udalyayet ostaljnyiye oblasti iz trebovaniya.

## Svyazannyiye granicyi

[Graficheskiye puti FUMA](🟡-graficheskiye-interfejsyi-FUMA.md) i [Metal dlya interfejsa Apple silicon](🟡-otrisovka-interfejsa-cherez-Metal.md) zadayut dejstvuyusjhiye platformennyiye usloviya. Oni ne yavlyayutsya gotovyim 3D-dvizhkom i ne vyibirayut sintaksis scen ili universaljnyij backend dlya vsekh platform.

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_20-37-47_MSK_prinyatj-parametricheskoye-3D-FUMA/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 20:52:00 MSK -->
<!-- content-sha256: sha256:edb96d099541040abb61e9f25b33ecfd4a289f8beca25777166913522d032812 -->
<!-- FUM-MD-RECENCY:END -->
