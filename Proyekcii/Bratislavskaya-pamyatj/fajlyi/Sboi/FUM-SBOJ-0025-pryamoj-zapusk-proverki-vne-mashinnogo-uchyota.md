+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0025"
"статус" = "активна"
+++
# Pryamoj zapusk proverki vne mashinnogo uchyota

## Nablyudayemyij sboj

Pryamyiye proverochnyiye vyizovyi vyipolnyalisj cherez vruchnuyu sobrannuyu shell-komandu bez obyazateljnoj obyortki. V iskhodnom proyavlenii eto uspeshnaya proverka diff; v povtore 0176 — pervaya sborka planovogo reyestra; v povtore kornya 0201 — chetyire posledovateljnyikh build v odnom epizode vosstanovleniya sovmestimosti importirovannyikh trebovanij. Rezuljtatyi otkryitogo instrumentaljnogo vyivoda i pozdnikh zapuskov sokhranenyi, no mashinnyiye zapisi iskhodnyikh pryamyikh processov ne sozdanyi.

## Granica povtoreniya

Granica — ruchnaya sborka komandyi proverki, pozvolyayusjhaya zabyitj obyazateljnyij putj mashinnogo uchyota, v tom chisle pri generacii reyestra s zapisjyu rezuljtata. Oshibka formata vkhodnoj kartochki i propusk yeyo ispolnyayemoj zavisimosti ne obyyavlyayutsya odnim defektom s otsutstviyem uchyota: zdesj sokhranyayetsya imenno nablyudayemyij obkhod obyortki. Neskoljko popyitok ispravleniya odnogo vkhoda vnutri kornevogo epizoda ne schitayutsya chetyirjmya nezavisimyimi proyavleniyami.

## Proyavleniya

- **FUM-SBOJ-0025/PROYAVLENIYE-0001.** V [tekusjhej sessii](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md) instrumentaljnyij otvet pryamogo `git diff HEAD --check` s shestjyu tochnyimi isklyucheniyami pokazal kod 0 i wall-clock `0.234003917` s. Eti svedeniya perenesenyi v otdeljnoye nablyudeniye [otchyota](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/otchyot.md); oni ne vyidanyi za sozdannuyu obyortkoj zapisj.

- **FUM-SBOJ-0025/PROYAVLENIYE-0002.** V pervom etape 0176 planovyij generator zapusjhen napryamuyu posle podgotovki kartochki 0203 i vernul otkaz iz-za nevernogo znacheniya statusa indeksa. Obyazateljnaya obyortka ne sozdala zapisj iskhodnogo zapuska. [Adresnoye nablyudeniye](../Zhurnal/2026-09-11_02-13-44_MSK_integrirovatj-postavku-FUMA/materialyi/propusk-uchyota-0025.json) vosstanovleno chteniyem iskhodnogo vyizova i otveta JSONL; ono ne yavlyayetsya vruchnuyu izgotovlennoj kvitanciyej. [Pervyij otchyot](../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/otchyot.md) sokhranyayet ogranicheniye, uchtyonnyij povtor posle ispravleniya proshyol. Obsjheye sredstvo predotvrasjheniya i regressionnaya granica sovpadayut s pervyim proyavleniyem: proverochnyij generator dolzhen vkhoditj v obyortku do ispolneniya.

Povtor `FUM-СБОЙ-0025/ПРОЯВЛЕНИЕ-0002` aktualiziruyet shag 0153; rezuljtat povtornogo zapuska ne zakryivayet sistemnuyu prichinu.

Dopolniteljnoye svideteljstvo povtora: [posleduyusjhaya uchtyonnaya sborka № 15 abae9ca5](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-28-44_MSK_перенести-исходники-FUMA/материалы/запуски-проверок/15_abae9ca5-ea3c-4d01-96b0-36d9db0edb37.json) zavershena kodom 0 za 0,412869583 s. Eta kvitanciya otnositsya k povtoru, ne k pervomu vyizovu.


- **FUM-SBOJ-0025/PROYAVLENIYE-0003.** V [etape kornya 0201 08:49:30 MSK](../Zhurnal/2026-09-11_08-49-30_MSK_prinyatj-perekodirovaniye-DNK-v-belki/otchyot.md) vyipolnenyi chetyire pryamyikh `build-planning-registry.py build --repo-root .` vne otchyotnoj obyortki: pervyij otklonil tochnyij marker nezavisimogo trebovaniya kak `malformed semantic relation`; dva sleduyusjhikh — udalyonnyij, zatem pustoj obyazateljnyij razdel kak `missing required section`; chetvyortyij zavershilsya uspeshno posle vosstanovleniya iskhodnogo formata i perenosa susjhestvuyusjhej dvukhstrochnoj zavisimosti. Eto tri otkaza i odin uspekh v odnom lokaljnom proyavlenii. Otkryityiye call_id: `call_xdeARQMhCl3K1VtYplvjkstv`, `call_01bM2bWifZcYRs1U3tUzG5fc`, `call_NLkauJR2K0lNaLK1zZc9NPqq`, `call_17D9zB5biAnW9ssxRc0zbMlI`. Pervyij shell-otvet `ca4864` soderzhit otkaz build i obsjhij kod 0 posleduyusjhej recency; etot 0 ne otmenyayet otkaz. Vremya otdeljnyikh build ne izmereno, otdeljnyij kod pervogo processa v sostavnom otvete ne vyidelen. [Pozdnyaya nastoyasjhaya adresnaya validaciya № 2 73ad2f81](../Zhurnal/2026-09-11_08-49-30_MSK_prinyatj-perekodirovaniye-DNK-v-belki/materialyi/zapuski-proverok/2_73ad2f81-b7c2-4592-8630-dfbe95d38cbc.json) zavershena kodom 0 za 0,406792083 s i ne yavlyayetsya kvitanciyej lyubogo iz chetyiryokh iskhodnyikh build.

## Ozhidaniye i klassifikaciya

Kazhdyij okhvachennyij pravilami pryamoj proverochnyij process dolzhen poluchatj sobstvennuyu mashinnuyu zapisj pri zapuske. Nablyudayemaya komanda generacii ili obsjhij uspekh poslednej shell-komandyi ne zamenyayut uchyot vsekh predyidusjhikh proverochnyikh processov. Novyiye faktyi podtverzhdayut prezhnyuyu granicu FUM-SBOJ-0025; novyij globaljnyij tip sboya i otdeljnyij STEP ne trebuyutsya.

## Mekhanizm i sistemnoye ustraneniye

Pri ruchnom formirovanii komand agent obkhodit obyazateljnuyu obyortku; pozdnyaya povtornaya proverka podtverzhdayet uzhe ispravlennoye sostoyaniye, no ne vosstanavlivayet polnotu iskhodnogo zhurnala. Sistemnaya mera predotvrasjheniya ili obnaruzheniya takogo obkhoda ostayotsya zadachej FUM-STEP-0153. Realizaciya etoj meryi v opisannyikh povtorakh ne ustanovlena. Mashinnyiye svideteljstva vruchnuyu i zadnim chislom ne izgotavlivayutsya; skhema uchyota ne menyayetsya.

## Svyazannyiye shagi

- [FUM-STEP-0153](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0153-predotvrasjhatj-pryamyiye-proverki-vne-obyortki.md): osnovaniya — vse tri proyavleniya; povtor 0176 i chetyire komandyi odnogo epizoda 0201 utochnyayut uzhe susjhestvuyusjhuyu granicu.

## Kriterii zakryitiya

Vosproizvodimaya mera obnaruzhivayet ili predotvrasjhayet pryamoj proverochnyij vyizov do ispolneniya vne obyortki; otdeljno proverenyi dopustimyiye isklyucheniya dlya read-only-inventarya i zaklyuchiteljnogo zamyikaniya. Svideteljstva okhvatyivayut iskhodnyij diff i sborku reyestra, vklyuchaya neskoljko proverochnyikh processov v sostavnoj komande. Obsjhij kod poslednej komandyi ne vyidayotsya za iskhod kazhdogo predyidusjhego processa. Uspeshnyij povtor podtverzhdayet novoye proveryayemoye sostoyaniye i sobstvennuyu kvitanciyu; propusjhennaya zapisj iskhodnogo vyizova ne zayavlyayetsya vosstanovlennoj. Poka eta mera ne proverena, status aktivnyij.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [Mashinnyij uchyot proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md).
- [Otchyot pervogo pryamogo build 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-28-44_MSK_перенести-исходники-FUMA/отчёт.md) i [podtverzhdeniye yego granicyi v sleduyusjhem etape](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-56-50_MSK_проверить-пакеты-FUMA-из-клона/отчёт.md).
- [Zapros kornya 0201](../Zhurnal/2026-09-11_08-49-30_MSK_prinyatj-perekodirovaniye-DNK-v-belki/zapros.md) i [yego otchyot](../Zhurnal/2026-09-11_08-49-30_MSK_prinyatj-perekodirovaniye-DNK-v-belki/otchyot.md).
- [Novyij zapros diagnostiki](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md) i [otchyot](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:59:08 MSK -->
<!-- content-sha256: sha256:f0ed92644b804b26d43bd999cffc0eb261aca451ff08b7ab210488236a5ce95f -->
<!-- FUM-MD-RECENCY:END -->
