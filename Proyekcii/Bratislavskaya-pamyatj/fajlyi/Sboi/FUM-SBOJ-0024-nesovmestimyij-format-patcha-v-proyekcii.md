+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0024"
"статус" = "активна"
+++
# Nesovmestimyij format patcha v proyekcii

## Nablyudayemyij sboj

Primer priyomsjhika sokhranyayet proverennyij patch kak `предложение.patch`, no `.patch` ne zaregistrirovan v kontrakte bratislavskoj proyekcii. Pereimenovaniye v `.patch.txt` prokhodit proyekciyu, odnako proverka mashinno-lokaljnyikh putej otklonyayet stroku zagolovka novogo fajla s oboznacheniyem nulevogo ustrojstva. Kontejner proverennogo patcha ne soglasovan so vsej posledovateljnostjyu priyomki.

## Granica povtoreniya

Granica — nesoglasovannyij kontejner vyikhodnogo materiala priyomsjhika i vkhodov obyazateljnyikh proverok. Obsjhaya mera predotvrasjheniya i regressionnyij primer okhvatyivayut polnyij putj dobavlyayusjhego fajl patcha cherez proyekciyu i proverku lokaljnyikh putej. Eto otdeljnyij mekhanizm ot [nekorrektnyikh bajtov vneshnego paketa](FUM-SBOJ-0023-nekorrektnyij-vneshnij-paket.md). Oba validatora srabotali soglasno svoim politikam.

## Proyavleniya

- **FUM-SBOJ-0024/PROYAVLENIYE-0001.** V [zapuske 10](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/materialyi/zapuski-proverok/10_ee4725ad-fb12-47ac-89ff-652d7125a225.json) pervyij smoke ostanovilsya na shage 4 s kodom 2 i diagnostikoj neizvestnogo formata materiala `внешний-вклад/предложение.patch`. Analogichnoye rasshireniye imel sokhranyonnyij iskhodnyij patch.

V prodolzhenii togo zhe priyoma [zapusk 14](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/materialyi/zapuski-proverok/14_70893788-a82c-418b-99db-4932681e003a.json) uspeshno proshyol primeneniye i nezavisimuyu proverku proyekcii, zatem zavershilsya s kodom 1 na shage 6. Adresnaya diagnostika pokazala `error.system-runtime-hardcode` v stroke 4 oboikh `.patch.txt`. Eto sleduyusjhij barjyer togo zhe nesovmestimogo kontejnera; zapisj zapuska podtverzhdayet iskhod processa, a konkretnaya diagnostika sokhranena zdesj kak nablyudeniye kornevoj sessii.

## Vosstanovleniye i ostavshayasya rabota

Posle proverki priyomsjhikom bajtyi oboikh patchej otdeljno zakodirovanyi v `.patch.base64`; prezhniye promezhutochnyiye kontejneryi udalenyi. Base64 uzhe ispoljzuyetsya samim paketom i zaregistrirovan proyekciyej kak tochnyij format. Dekodirovaniye s proverkoj alfavita vozvrasjhayet bajtyi, chji SHA-256 sovpadayut s JSON proverki i proiskhozhdeniya. Proverka mashinno-lokaljnyikh putej dlya etogo kontejnera proshla.

Eto otdeljnaya operaciya nad uzhe proverennyim rezuljtatom: tekusjhij priyomsjhik po-prezhnemu trebuyet tochnoye imya `предложение.patch` dlya `--выход-патч`. Flagi s `.txt` ili `.base64` ne obyyavlyayutsya podderzhannyimi. Pered budusjhej publikaciyej proverennyij vyikhod preobrazuyetsya v zaregistrirovannoye predstavleniye s obyazateljnoj sverkoj dekodirovannyikh bajtov.

Eto ogranichennoye vosstanovleniye tekusjhego materiala. Obsjhij primer navyika poka prodolzhayet rekomendovatj nesovmestimoye imya, poetomu kartochka ostayotsya aktivnoj. Soglasovaniye povtoryayemogo marshruta vyineseno v [FUM-STEP-0152](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0152-soglasovatj-format-patcha-priyomsjhika-s-proyekciyej.md).

## Kriterij zakryitiya

Dokumentirovannyij marshrut shtatnogo priyomsjhika prokhodit proyekciyu i proverku mashinno-lokaljnyikh putej bez nepredpisannyikh preobrazovanij; regressionnyij primer dobavleniya fajla podtverzhdayet tochnoye sokhraneniye dekodirovannyikh bajtov i otkaz dlya nezaregistrirovannogo formata.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md) i [otchyot](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/otchyot.md).
- [Primer priyomsjhika](../Instrumentyi/fum-priyom-vneshnego-vklada/SKILL.md) i [kontrakt proyekcii](../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/kontrakt-v2.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 20:02:13 MSK -->
<!-- content-sha256: sha256:a815db572d5781cf6176eaa59f25f1aac21a0f67780bcc999d61f64436deb3ec -->
<!-- FUM-MD-RECENCY:END -->
