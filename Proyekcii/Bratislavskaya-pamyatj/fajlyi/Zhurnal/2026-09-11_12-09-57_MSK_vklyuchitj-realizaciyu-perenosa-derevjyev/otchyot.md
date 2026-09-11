# Otchyot 2026-09-11 12:09:57 MSK - Vklyuchitj realizaciyu perenosa derevjyev

Vklyuchayetsya shestoj prinyatyij vkhod `1c31740699c8937d610eea45c4a3326314923330` v `161bf2c971ae737f9979e5bd07cbbf6e6418e8c6`. Sokhranyayutsya iskhodniki perenoschika, avtonomnaya priyomka i otkryitaya granica zhivyikh perenosov. Sam perenos rabochikh derevjyev v etoj zadache ne ispolnyayetsya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Komanda shestogo sliyaniya | 0.619761666 s | Monotonnyiye granicyi, vyikhod 1 s konfliktami |
| Razresheniye konfliktov | 67.888741750 s | Ot vozvrata merge do kanonicheskikh tekstov; vklyuchayet chteniye i sopostavleniye |
| Podgotovka Zhurnala, plana i indeksov | 193.753120584 s | Ot razresheniya tekstov do peresobrannogo reyestra; vklyuchaya rassuzhdeniye i vlozhennyiye obrasjheniya; recency otdeljno |
| Pryamyiye proverki | po tablice nizhe | Shtatnaya obyortka |

Granica profilya: ot shestogo merge do kontroljnoj tochki. CPU/RSS iskhodnoj komandyi dostupnyi v chastnom profile; fizicheskij I/O i stoimostj nablyudeniya otdeljno ne izmerenyi. Profilj samoj migracii otnositsya k prinyatomu avtonomnomu vkhodu.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                        | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------- | ------------ | --------- |
| [Integrator postavok] Sobratj reyestr posle vklyucheniya perenoschika             | 0,345 s      | neuspeshno |
| [Integrator postavok] Sobratj reyestr posle udaleniya ustarevshego povtora 0203 | 0,453 s      | uspeshno   |
| [Integrator postavok] Obnovitj svezhestj shestogo obyyedineniya                  | 1,263 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2,061 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Peresborka reyestra, aktualizaciya navigacii i recency, exact diff i indeks, zatem pryamaya zaklyuchiteljnaya svyaznostj kontroljnoj tochki. Ispolnyayemyiye fajlyi perenoschika ne imeli konfliktov i sokhranyayutsya tochno iz prinyatogo vkhoda. Yego otdeljnyiye suites ne povtoryayutsya; obsjhij primenimyij dopusk vyipolnyayetsya posle vosjmogo vkhoda.

## Resheniya i ogranicheniya

Pervyij planovyij build obnaruzhil avtomaticheski dobavlennuyu vne konfliktnogo bloka vtoruyu stroku 0203 so staryim active-statusom. Ustarevshaya stroka udalena, completed-stroka sokhranena; build povtoryon.

Shestj kanonicheskikh konfliktov kasalisj navigacii, indeksov i reyestra instrumentov. Sokhranenyi opisaniye tekusjhego obyazateljnogo chitatelya soobsjhenij i otdeljnaya registraciya perenoschika. V indekse 0207 stanovitsya completed s putyom ✅; 0176, 0177 i 0203 sokhranyayut zavershyonnyiye statusyi. Aktivnoye trebovaniye 0066 ne zakryivayetsya avtonomnyimi fiksturami: zhivyiye derevjya, privyazki i drugiye platformyi ostayutsya za granicej priyomki. Novoye svideteljstvo 0173 i proyavleniye 0045/0002 sokhranyayutsya s pervonachaljnoj osnovoj `1aab4c01`; 443 dopolniteljnyikh obyyavleniya otnosyatsya k toj osnove, obsjhij snimok obyyavlenij ne obnovlyalsya.

Nezavisimyij read-only-analiz podtverdil otsutstviye peresechenij v ispolnyayemyikh fajlakh. Sokhranyayutsya semj fajlov perenoschika, osnovnoj blob `0d13c44329366917157bd269486daac34bd8a677`, sorok fajlov yego Zhurnala, vklyuchaya 32 zapisi zapuskov i pyatj materialov profilya. Ispoljzuyemyiye moduli kanonicheskogo vvoda, obyyektov i dve funkcii proyektora sovmestimyi s prinyatyim snimkom 0207; rasshiryatj politiku proyekcii dlya etoj postavki ne trebuyetsya.

Devyatj konfliktov Proyekcii snyatyi celyim pokoleniyem pervogo roditelya, bez ruchnoj pravki otdeljnyikh rezuljtatov. SHA smyislovogo plana `8bd921c46d72f24a9b99f34ddb3c7c846c74f1b172629d31b7e32a108af811fb`; obsjhaya generaciya yesjhyo vperedi.

Predyidusjhaya tochka `161bf2c971ae737f9979e5bd07cbbf6e6418e8c6`, derevo `fe513a342fbf6c2c84bc352ae0d3dfaad72ef1ee`, roditeli `[4452d9aa8dacf692127fef7cfb5e9c1b62e47995, b762bd0cb77fdbcc418141a1f33800a7bdb630a6]` proshla svyaznostj i opublikovana s sovpavshim udalyonnyim OID. Sobstvennyij plan obnovlyon novyim ukazatelem i svideteljstvom pyatogo vkhoda; opredeleniya obyazateljstv, priyomki drugikh zadach i ikh zakryityiye otchyotyi ne perepisyivayutsya.

Koordinator predostavil vladeljcu 0208 korotkoye tikhoye okno dlya otdeljnogo izmereniya. V etoj integracii na eto vremya dopuskayutsya toljko Git, chteniye i lyogkaya podgotovka; sborki, nagruzochnyiye profili, proyekciya i polnyij smoke ne zapuskalisj.

Posle etogo etapa ostayutsya tochnyij 0208 `f49eeee3fd80a87cd63391d6606dafa19cd6d2b8`, shablonyi `acab107170a4a1243b76cba4f25b0b408e735603`, sovmestnyij dopusk i fakticheskaya peredacha prinyatogo kandidata pisatelyu fuma. Novyij benchmark vladeljca 0208 ne vklyuchyon. Staticheskij razbor v2 podtverdil dopustimostj otdeljnoj zavershayusjhej kontroljnoj tochki uchyota posle peredachi neizmennogo prinyatogo kandidata; polnyij dopusk kandidata neljzya vyidavatj za polnyij dopusk etoj posleduyusjhej zapisi.

## Istochniki

- [Zapros etapa](zapros.md).
- [Sobstvennyij plan](materialyi/planyi/prodolzheniye.json).
- [Prinyatyij perenoschik](../2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/otchyot.md).
- [Vosemj vkhodov](../2026-09-11_11-52-54_MSK_obyyedinitj-priyom-napravlenij-FUMA/materialyi/vkhodyi.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 12:13:12 MSK -->
<!-- content-sha256: sha256:d2020cabd685754d811ed3db56629483e192922e2bda0a07db5715ca42cb159f -->
<!-- FUM-MD-RECENCY:END -->
