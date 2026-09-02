# 05. Interfejs i servisnyiye adapteryi

## Naznacheniye

Eto napravleniye proyektiruyet [interfejs FUM-uzla](../../Glossarij/interfejs-FUM-uzla.md): vnutrennyuyu storonu, cherez kotoruyu uzel vidit sobstvennuyu pamyatj, sostoyaniya, poduzlyi i ogranicheniya, i vneshnyuyu storonu, cherez kotoruyu chelovek vyirazhayet namereniye, [lichnyij FUM-agent](../../Glossarij/lichnyij-FUM-agent.md) ponimayet kontekst, servisyi podklyuchayutsya cherez [MCP-serveryi](../../Glossarij/MCP-server.md) ili drugiye adapteryi, dejstviya podtverzhdayutsya, a rezuljtat vozvrasjhayetsya v [pamyatj FUM](../../Glossarij/pamyatj-FUM.md).

Otdeljnaya zadacha napravleniya - razlichatj profili [nablyudatelej FUM](../../Glossarij/nablyudatelj-FUM.md): CPU, GPU, LLM, cheloveka, servisnyij adapter ili drugoj uzel. Dlya kazhdogo profilya nuzhno ponimatj, kakiye signalyi dostupnyi, kakiye operacii osmyislennyi, chto teryayetsya pri preobrazovanii i kak eto svyazano s nizhelezhasjhim substratom.

## Proyektnyiye voprosyi

- Kak vyiglyadit minimaljnyij kontur: namereniye poljzovatelya -> utochneniye -> vyibor dejstviya -> podtverzhdeniye -> vyipolneniye -> sokhraneniye rezuljtata?
- Kakiye vnutrenniye sostoyaniya, poduzlyi, avtomatizacii i ogranicheniya dolzhen videtj sam uzel, chtobyi yego vneshnij interfejs ne stanovilsya slepyim fasadom?
- Dlya kakogo nablyudatelya postroyen konkretnyij interfejs: CPU, GPU, LLM, cheloveka, servisa, poduzla ili drugogo sostavnogo uzla?
- Kakiye servisnyiye vozmozhnosti dolzhnyi byitj dostupnyi cherez strukturirovannyij kontrakt, a kakiye poka ostayutsya obyichnyim interfejsom s poterej nablyudayemosti?
- Kak FUM dolzhen vesti kalendarj, raspisaniye, marshrutyi, vyizov taksi i drugiye poyezdochnyiye dejstviya tak, chtobyi poljzovatelj videl yedinyij zhiznennyij scenarij, a agent sokhranyal podtverzhdeniya, trassyi i granicyi dostupa?
- Kak fiksirovatj [urovni dostupa](../../Glossarij/urovenj-dostupa.md), podtverzhdeniya, oshibki i otmenyi?
- Kak ne prevratitj yedinuyu tochku vzaimodejstviya v skryituyu totaljnuyu vlastj nad servisami i poljzovatelem?

## Liniya razvitiya

Blizhnyaya rabota - opisatj minimaljnyij lokaljnyij poljzovateljskij kontur dlya rabotyi s repozitoriyem: zapros, vyibor dejstviya, podtverzhdeniye, zapusk proverki i sokhraneniye rezuljtata. Posle etogo mozhno vyidelyatj servisnyiye adapteryi kak [ustrojstva vospriyatiya i dejstviya FUM](../../Glossarij/ustrojstvo-vospriyatiya-i-dejstviya-FUM.md) s kontraktami, versiyami i ogranicheniyami.

Eto napravleniye dolzhno razvivatjsya ostorozhno: chem boljshe vneshnikh dejstvij poluchayet FUM, tem vazhneye proiskhozhdeniye, prava dostupa i vozmozhnostj vosstanovitj, chto imenno byilo podtverzhdeno chelovekom.

Kalendarno-transportnyij kontur stanovitsya otdeljnyim prakticheskim oriyentirom dlya etogo napravleniya. Yego nuzhno razvivatj cherez pasporta adapterov kalendarya, raspisanij, kart, taksi, biletov i uvedomlenij, nachinaya s fikstur i simulyatorov bez realjnogo zakaza, oplatyi i peredachi privatnogo mestopolozheniya.

## Blizhajshij proveryayemyij artefakt

Blizhajshij artefakt - pasport interfejsa lokaljnogo [FUM-uzla](../../Glossarij/FUM-uzel.md) rabochej sessii. On dolzhen vklyuchatj profili nablyudatelej, vnutrenniye sostoyaniya, vneshniye vkhodyi i vyikhodyi, lokaljnyiye servisnyiye adapteryi, tochki podtverzhdeniya, prava dostupa, oshibki, granicyi nablyudayemosti i sposob sokhraneniya rezuljtata v [pamyati FUM](../../Glossarij/pamyatj-FUM.md).

Perekhodyi mezhdu predyyavleniyami etogo pasporta oformlyayutsya po [minimaljnomu formatu preobrazovaniya mezhdu nablyudatelyami FUM](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md), chtobyi karta signalov, invariantyi, poteri, obratimostj i marshrut k iskhodnomu sloyu ostavalisj proveryayemyimi.

Proverka: odin testovyij scenarij prokhodit cepochku namereniye -> podtverzhdeniye -> zapusk proverki -> sokhranyonnyij rezuljtat, ne trebuya vneshnikh servisov i privatnyikh dannyikh.

## Proveryayemyiye rezuljtatyi

- Opisan minimaljnyij poljzovateljskij scenarij s tochkami podtverzhdeniya.
- Dlya servisnogo adaptera zafiksirovanyi naznacheniye, vkhodyi, vyikhodyi, oshibki, prava dostupa i granicyi nablyudayemosti.
- Dejstviye cherez servis sokhranyayet istochnik namereniya, podtverzhdeniye, vyizvannyij instrument i rezuljtat.
- Dlya servisov bez mashinnogo kontrakta fiksiruyetsya poterya strukturirovannosti.
- Dlya kazhdogo napravlennogo perekhoda mezhdu nablyudatelyami vse iskhodnyiye signalyi pokryityi kartoj preobrazovaniya ili yavnoj poterej, a obratimostj i marshrut k istochniku proverenyi nezavisimo.
- Kalendarno-transportnyij scenarij razlichayet chteniye raspisaniya, modelirovaniye variantov, vneshnij vyizov servisa, podtverzhdeniye poljzovatelya, oshibku adaptera i sokhranyonnyij rezuljtat.

## Granicyi

Interfejs ne dolzhen pryatatj vazhnyiye resheniya v udobnyikh knopkakh ili avtomaticheskikh dejstviyakh. Poljzovateljskij kontur dolzhen ostavlyatj cheloveku ponyatnoye mesto dlya podtverzhdeniya, otmenyi i ogranicheniya dostupa. Servisnyij adapter ne dolzhen khranitj sekretyi ili privatnyiye sostoyaniya v otkryitoj pamyati.

Dlya kalendarej, taksi i poyezdok osobenno vazhna granica mezhdu poleznoj proaktivnostjyu i nedopustimoj avtonomiyej: fizicheskoye peremesjheniye cheloveka, platnyiye operacii, peredacha geolokacii i izmeneniye chuzhogo raspisaniya trebuyut otdeljnoj politiki dostupa. [Pasport kalendarno-transportnogo servisnogo kontura](../../Dokumentaciya/42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md) zakreplyayet konservativnuyu modeljnuyu versiyu `R0`, no ne razreshayet realjnyiye adapteryi i zaraneye zadannuyu avtonomiyu; eti granicyi ostayutsya v [chastichno proyasnyonnom voprose o kalendarno-transportnyikh dejstviyakh FUM](../../Voprosyi/2026-07-03_09-03-59_MSK_granicyi-kalendarno-transportnyikh-dejstvij-FUM.md).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 11:50:58 MSK - Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 09:55:41 MSK](../../Zhurnal/2026-06-26_09-55-41_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 10:26:06 MSK](../../Zhurnal/2026-06-26_10-26-06_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-03 09:03:59 MSK - Opisatj kalendarno transportnyiye dejstviya FUM](../../Zhurnal/2026-07-03_09-03-59_MSK_opisatj-kalendarno-transportnyiye-dejstviya-FUM/zapros.md)

## Opornyiye materialyi

- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Pasport kalendarno-transportnogo servisnogo kontura lichnogo FUM-agenta](../../Dokumentaciya/42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Gibridnyiye uzlyi i socialjnaya fraktaljnostj](../../Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md)
- [Obmen narabotkami i urovni dostupa](../../Dokumentaciya/09-obmen-narabotkami-i-urovni-dostupa.md)
- [MVP yedinoj tochki lokaljnoj rabotyi](../MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f67b884358b9ae89daa726c784fb44ed6e1adadc8af9276975b2dd97deb1d011 -->
<!-- FUM-MD-RECENCY:END -->
