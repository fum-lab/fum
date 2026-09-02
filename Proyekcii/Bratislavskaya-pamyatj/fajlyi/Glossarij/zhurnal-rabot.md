# Zhurnal rabot

Zhurnal rabot - razdel [pamyati FUM](pamyatj-FUM.md), kotoryij khranit khronologicheskuyu posledovateljnostj [papok zaprosov](papka-zaprosa.md). Kazhdaya papka obyyedinyayet doslovnyij [iskhodnyij zapros](iskhodnyij-zapros.md), chelovekochitayemyij vyisokourovnevyij otchyot o prodelannoj [rabochej sessii](rabochaya-sessiya.md) i prinadlezhasjhiye zaprosu materialyi.

Zhurnal rabot ne zamenyayet [proizvodnuyu dokumentaciyu](proizvodnaya-dokumentaciya.md), proverki ili Git-kommityi. Yego zadacha - sokhranyatj iskhodnoye trebovaniye ryadom s trassoj yego obrabotki i davatj obzornuyu istoriyu: kakoj smyisl imelo izmeneniye, kakiye materialyi byili zatronutyi, kakiye resheniya zafiksirovanyi i kakiye prodolzheniya stali vidnyi. V korne `Журнал/` nakhoditsya toljko navigacionnyij `README.md`; identichnostj zapisi zadayot imya papki s obyazateljnyim vremennyim prefiksom.

Kazhdyij novyij otchyot zhurnala takzhe soderzhit profilj vremeni vyipolneniya po fakticheski razlichimyim stadiyam [rabochej sessii](rabochaya-sessiya.md). Profilj ispoljzuyet proshedsheye wall-clock-vremya, pokazyivayet granicyi i sposob izmereniya, otdelyayet ozhidaniye ocheredi ot aktivnoj rabotyi i preduprezhdayet o perekryitii paralleljnyikh stadij. Neizvestnaya dliteljnostj ne vosstanavlivayetsya vyidumannoj ocenkoj; v otchyote pryamo ukazyivayetsya, chto ona ne izmerena.

Proverochnaya chastj profilya yavlyayetsya trassoj, a ne toljko vremenem itogovogo zelyonogo progona. Nachinaya s rabochej sessii `2026-08-04 20:45:26 MSK`, kazhdyij pryamoj verkhneurovnevyij zapusk testov, validatora, sborki, lint, benchmark, smoke-check vyibrannogo profilya ili drugogo proverochnogo processa provoditsya cherez obyazateljnuyu avtomatizaciyu i sokhranyayetsya v sobstvennoj versionirovannoj JSON-zapisi s atomarnoj ustanovkoj kazhdogo sostoyaniya. Neuspeshnyiye, prervannyiye i povtornyiye vyizovyi ne zamenyayut drug druga. Vlozhennyiye shagi sostavnogo zapuska mozhno detalizirovatj dlya poiska uzkikh mest, no oni ne stanovyatsya dopolniteljnyimi verkhneurovnevyimi zapisyami i ne pribavlyayutsya k summe vtoroj raz.

Chelovekochitayemaya Markdown-tablica ne redaktiruyetsya kak nezavisimyij istochnik: ona determinirovanno stroitsya iz uporyadochennyikh mashinnyikh zapisej. Nablyudayemaya dliteljnostj kazhdoj zavershyonnoj zapisi perevoditsya iz nanosekund v vidimyiye celyiye millisekundyi, i obsjhij profilj skladyivayet imenno eti otobrazhyonnyiye znacheniya. Takaya summa pokazyivayet sovokupnuyu stoimostj proverok i pri paralleljnom vyipolnenii ne podmenyayet kalendarnoye vremya sessii.

Zakryityij mashinnyij zhurnal soderzhit uporyadochennyij snimok imyon i tochnyikh SHA-256 khyeshej bajtov vsekh zapisej; marker otchyota svyazyivayet yego s khyeshem samogo snimka, a sgenerirovannyij Markdown dolzhen bajt-v-bajt sovpadatj s proyekciyej, zanovo postroyennoj iz zapisej. Dobavleniye, udaleniye, izmeneniye ili perestanovka zapisi posle zakryitiya delayet otchyot nesvyaznyim. Otkryityij predprosmotr mozhet promezhutochno susjhestvovatj mezhdu vyizovami, no strogaya proverka prinimayet yego toljko pri nalichii aktivno vyipolnyayusjhejsya zapisi, a konechnyij kommit — nikogda. Zakryitiye snachala stavit snimok, zatem Markdown; obnaruzhimaya podgotovlennaya faza blokiruyet novyiye vyizovyi i zavershayetsya povtorom. Predfinaljnyij smoke-check vyibrannogo profilya ostayotsya poslednej okhvachennoj zapisjyu, posle kotoroj vne profilya vyipolnyayutsya toljko proverki zamyikaniya otchyota; dlya obyichnoj dokumentacionnoj sessii vyibirayetsya standartnyij profilj.

## Svyazannyiye dokumentyi

- [Zhurnal rabot](../Zhurnal/README.md)
- [Papka zaprosa](papka-zaprosa.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [AGENTS.md](../AGENTS.md)
- [Avtomaticheskiye otchyotyi o zapuskakh proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-08-04 20:45:26 MSK — Formirovatj otchyotyi o zapuskakh testov](../Zhurnal/2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)
- [iskhodnyij zapros 2026-07-27 16:12:29 MSK - Uchityivatj vse proverochnyiye vyizovyi v profile vremeni](../Zhurnal/2026-07-27_16-12-29_MSK_uchityivatj-vse-proverochnyiye-vyizovyi-v-profile-vremeni/zapros.md)
- [iskhodnyij zapros 2026-07-23 14:47:43 MSK - Vklyuchatj profilj vremeni v otchyotyi zhurnala](../Zhurnal/2026-07-23_14-47-43_MSK_vklyuchatj-profilj-vremeni-v-otchyotyi-zhurnala/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 15:00:57 MSK -->
<!-- content-sha256: sha256:cb12a6edcd76bf1eef243d2790961752ec88b384f7dc30a1e70cea245b9da889 -->
<!-- FUM-MD-RECENCY:END -->
