# Obsidian, glossarij i prototipyi

Eti pravila polnostjyu chitayutsya do izmeneniya Obsidian-nastroyek, glossariya, grafov, diagramm ili prototipov.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000134 -->
- Rabochiye prototipyi otdeljnyikh chastej reshenij dlya [korobochnoj realizacii FUM](../../Glossarij/korobochnaya-realizaciya-FUM.md) razmesjhayutsya v `Прототипы/`. Novyiye rabochiye prototipyi po umolchaniyu pishutsya na Swift; yesli konkretnaya proverka trebuyet drugogo yazyika, runtime ili steka, prichina isklyucheniya yavno fiksiruyetsya v pasporte prototipa. Kazhdyij ustojchivyij prototip khranitsya v otdeljnoj podpapke s kratkim pasportom ili `README.md`, ssyilkami na iskhodnyiye trebovaniya i svyazannuyu dokumentaciyu, sposobom proverki, granicami primenimosti, publikacionnyimi ogranicheniyami i tekusjhim statusom. V korne kazhdogo takogo prototipa khranitsya ispolnyayemyij POSIX-skript `запустить.sh`: on sam opredelyayet katalog prototipa, dayot poleznyij i bezopasnyij zapusk bez obyazateljnogo perekhoda v katalog, peredayot yavno zadannyiye argumentyi i dokumentiruyetsya v pasporte. V korne repozitoriya khranitsya ispolnyayemyij POSIX-skript `prototipyi.sh` s namerenno transliterirovannyim imenem: bez pereklyucheniya raskladki on otkryivayet pronumerovannuyu panelj, avtomaticheski nakhodit tochki vkhoda prototipov, podderzhivayet bezopasnyij vyikhod, neinteraktivnyij spisok i pryamoj zapusk po nomeru s peredachej argumentov. Nalichiye, ispolnyayemyij bit, shebang `#!/bin/sh`, sintaksis i povedeniye obsjhej paneli i tochek vkhoda proveryayutsya lokaljnoj avtomatizaciyej `Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py`, yeyo testami i yavnyim polnyim profilem smoke-check libo otdeljnyim celevyim zapuskom; v standartnyij dokumentacionnyij smoke etot korobochnyij kontur ne vkhodit. Prototipyi ne zamenyayut proizvodnuyu dokumentaciyu, trebovaniya ili lokaljnyiye avtomatizacii; prinyatyij rezuljtat perenositsya v `Документация/`, `Инструменты/`, `Планирование/` ili `Вопросы/` po smyislu.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000214 -->
- Katalog `.obsidian/` nakhoditsya pod upravleniyem [pamyati FUM](../../Glossarij/pamyatj-FUM.md), a ne isklyuchayetsya celikom. Agent otvechayet za yego khraneniye i konfigurirovaniye kak za chastj rabochej sredyi repozitoriya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000215 -->
- V Git sleduyet khranitj neboljshiye, ustojchivyiye i publikacionno chistyiye nastrojki Obsidian, kotoryiye pomogayut vosproizvoditj navigaciyu i rabotu s pamyatjyu: bazovyiye nastrojki prilozheniya, vneshnij vid, spisok vklyuchyonnyikh bazovyikh plaginov, nastrojki grafa, spisok osoznanno vyibrannyikh community-plaginov bez samikh paketov i sekretov, a takzhe drugiye deklarativnyiye nastrojki, yesli ikh smyisl ponyaten iz diff.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000217 -->
- Ostaljnyiye puti vnutri `.obsidian/` po-prezhnemu klassificiruyutsya yavno. Ustojchivyiye publikacionno chistyiye nastrojki mozhno khranitj v Git, a lokaljnyiye, izmenchivyiye i mashinnyiye sostoyaniya poluchayut tochnoye pravilo `.gitignore`; uzhe otslezhivayemyij lokaljnyij putj snimayetsya s uchyota bez udaleniya poljzovateljskoj kopii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000218 -->
- Grafyi, skhemyi i diagrammyi, prednaznachennyiye dlya otobrazheniya v Obsidian, po umolchaniyu oformlyayutsya kak Markdown-bloki koda s yazyikom `mermaid`, chtobyi vizualizaciya ostavalasj tekstovoj, diffiruyemoj i prigodnoj dlya vosproizvedeniya v [pamyati FUM](../../Glossarij/pamyatj-FUM.md).

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000219 -->
- Podpisi uzlov Mermaid ne dolzhnyi nachinatjsya s Markdown-markerov spiskov vrode `1. `, `1) `, `- `, `* ` ili `+ `: v Obsidian takiye podpisi mogut otobrazhatjsya kak `Unsupported markdown: list`; dlya numeracii ispoljzuj formu `Этап 1 - ...` ili drugoj tekstovyij prefiks.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000220 -->
- Obsidian Canvas, izobrazheniya i vneshniye redaktoryi dlya takikh skhem primenyayutsya toljko kogda Mermaid nedostatochen; v etom sluchaye v [pamyati FUM](../../Glossarij/pamyatj-FUM.md) sokhranyayetsya publikacionno chistyij iskhodnik ili deklarativnoye opisaniye skhemyi.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000221 -->
- Lokaljnyiye, izmenchivyiye ili mashinnyiye sostoyaniya Obsidian ne khranyatsya v [pamyati FUM](../../Glossarij/pamyatj-FUM.md): `workspace.json`, `workspace-mobile.json`, kyeshi, vosstanovleniye fajlov, zagruzhennyiye paketyi plaginov i tem, uchyotnyiye zapisi, tokenyi, ustrojstvo-specifichnyiye nastrojki, vremennyiye i rezervnyiye fajlyi. Bezyimyannyiye fajlyi Obsidian ne otnosyatsya k etoj gruppe toljko iz-za imeni ili pustogo nachaljnogo soderzhimogo.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000222 -->
- Pri poyavlenii novyikh fajlov v `.obsidian/` [rabochaya sessiya](../../Glossarij/rabochaya-sessiya.md) sama klassificiruyet ikh pered kommitom: poleznoye i deshyovoye dlya obsjhej pamyati dobavlyayet v Git, nenuzhnoye ostavlyayet vne kommita cherez `.gitignore` ili udalyayet toljko yesli ono sozdano tekusjhej sessiyej i ochevidno yavlyayetsya musorom.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000223 -->
- Bezyimyannyiye fajlyi Obsidian, vklyuchaya `Untitled.canvas`, `Untitled *.canvas` i drugiye avtomaticheski nazvannyiye Obsidian-fajlyi, vklyuchayutsya v postoyannoye khraneniye kak chastj [pamyati FUM](../../Glossarij/pamyatj-FUM.md) bez isklyuchenij po priznaku imeni ili pustogo nachaljnogo soderzhimogo. Takiye fajlyi ne dobavlyayutsya v `.gitignore`; pered kommitom dlya nikh sokhranyayetsya obyichnaya publikacionnaya proverka na sekretyi, personaljnyiye dannyiye i mashinnyij musor.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000224 -->
- Yesli dlya Obsidian trebuyetsya vneshnij plagin, tema ili servis, v [pamyati FUM](../../Glossarij/pamyatj-FUM.md) khranitsya publikacionno chistyij kontrakt ili deklarativnoye opisaniye nastrojki; vneshniye paketyi, tokenyi i personaljnyiye sostoyaniya ne kommityatsya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000228 -->
- [Glossarij proyekta](../../Glossarij/glossarij-proyekta.md) khranitsya v `Глоссарий/`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000229 -->
- Indeks glossariya nakhoditsya v `Глоссарий/README.md`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000230 -->
- Kazhdyij termin khranitsya v otdeljnom Markdown-fajle i nachinayetsya s zagolovka `# <Термин>`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000231 -->
- Imena fajlov statej glossariya pishutsya kirillicej dlya russkikh slov; nazvaniye FUM i tekhnicheskiye identifikatoryi sokhranyayutsya v prinyatom napisanii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000233 -->
- Pri dobavlenii ili redaktirovanii proizvodnoj dokumentacii nuzhno dobavlyatj ssyilki na kazhdoye soderzhateljnoye upotrebleniye uzhe zavedyonnogo termina glossariya, yesli ssyilka pomogayet vosstanovitj smyisl ponyatiya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000234 -->
- Ssyilki rasstavlyayutsya i dlya sklonyayemyikh form glossarnyikh terminov: tekst ssyilki sokhranyayet praviljnuyu formu v dannom kontekste, a adres vedyot na statjyu termina v imeniteljnom padezhe.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000235 -->
- Yesli poyavlyayetsya novyij ustojchivyij termin FUM, nuzhno dobavitj dlya nego otdeljnyij fajl v `Глоссарий/`, vklyuchitj yego v indeks i rasstavitj ssyilki v zatronutyikh fajlakh.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000236 -->
- Tekst iskhodnogo poljzovateljskogo zaprosa v `Журнал/*/запрос.md` ne izmenyayetsya radi ssyilok na glossarij, chtobyi sokhranyatj doslovnostj pervichnogo istochnika.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:13:37 MSK -->
<!-- content-sha256: sha256:ff48173263f72e5cab5461c421d8b0736fdbe5d08ee23bc476d45cc3044c3c0d -->
<!-- FUM-MD-RECENCY:END -->
