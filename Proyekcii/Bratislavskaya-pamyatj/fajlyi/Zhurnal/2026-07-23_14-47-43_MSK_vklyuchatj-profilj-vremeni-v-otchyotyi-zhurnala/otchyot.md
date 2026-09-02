# Otchyot 2026-07-23 14:47:43 MSK - Vklyuchatj profilj vremeni v otchyotyi zhurnala

Zhurnal teperj pokazyivayet ne toljko rezuljtat rabochej sessii, no i vremya, potrebovavsheyesya na yeyo razlichimyiye stadii. Ozhidaniye ocheredi, soderzhateljnaya rabota i proverki stanovyatsya vidimyimi razdeljno, poetomu dliteljnyij smoke-check ili drugoj etap mozhno obsuzhdatj po nablyudayemyim dannyim.

## Rezuljtat

Vvedyon obyazateljnyij razdel `## Профиль времени выполнения` s tablicej `Стадия | Длительность | Границы и способ измерения`. V kazhdom novom otchyote dolzhno byitj ne meneye dvukh nepustyikh stadij i otdeljnaya stroka `Граница профиля:`. Wall-clock-vremya ne podmenyayetsya CPU-vremenem, paralleljnyiye intervalyi pomechayutsya kak perekryivayusjhiyesya, a otsutstvuyusjheye izmereniye ne zamenyayetsya ocenkoj.

Pravilo zakrepleno v `AGENTS.md`, opisanii zhurnala i rabochej sessii. Susjhestvuyusjhaya proverka svyaznosti poluchila vremennuyu granicu: novyiye otchyotyi bez profilya otklonyayutsya, istoricheskiye ostayutsya dopustimyimi. Otdeljnyij izmeriteljnyij skript ne sozdan, potomu chto strukturnuyu obyazateljnostj proveryayet uzhe dejstvuyusjhaya avtomatizaciya, a fakticheskij tajmer vyibirayetsya po nablyudayemosti konkretnoj stadii.

## Profilj vremeni vyipolneniya

| Stadiya                                     | Dliteljnostj                 | Granicyi i sposob izmereniya                                                                                                       |
| ------------------------------------------ | ---------------------------: | -------------------------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO                      | 5739,7 s (1 ch 35 min 39,7 s) | Mashinnyiye `registered_at_epoch` i `admitted_at_epoch` bileta ocheredi; aktivnoj rabotoj ne schitayetsya.                              |
| Analiz i proyektirovaniye                    |       211,4 s (3 min 31,4 s) | Raznostj mashinnyikh epoch-otmetok dopuska i pervoj pravki; tri paralleljnyikh read-only-audita ne summiruyutsya.                       |
| Realizaciya i celevyiye proverki              |       603,5 s (10 min 3,5 s) | Raznostj mashinnyikh epoch-otmetok pervoj pravki i zapuska pervogo smoke-check; vklyuchayet TDD, recency, graf i celevyiye proverki.     |
| Pervyij polnyij smoke-check                  |       174,3 s (2 min 54,3 s) | Pervyij polnyij progon `39/39`; wall-clock izmeren monotonnyim tajmerom vokrug komandyi na tekusjhej mashine.                           |
| Itogovoye revjyu i korrektirovka             |                  ne izmereno | Otdeljnyij tajmer ne zapuskalsya; stadiya vklyuchayet nezavisimoye revjyu, usileniye validatora, otricateljnyij test i obnovleniye indeksa. |
| Predfinaljnyij polnyij smoke-check           |       207,7 s (3 min 27,7 s) | Vtoroj polnyij progon `39/39` posle ispravlenij revjyu; wall-clock izmeren tem zhe monotonnyim tajmerom.                             |
| Izmerennyij interval do pervogo smoke-check |  6728,9 s (1 ch 52 min 8,9 s) | Ot registracii bileta do konca pervogo smoke-check; perekryivayusjhij itog, kotoryij ne pribavlyayetsya k strokam stadij.                |

Granica profilya: ot registracii FIFO-bileta do zaversheniya vtorogo, predfinaljnogo polnogo smoke-check; ozhidaniye FIFO vklyucheno, a finaljnaya zapisj poslednego izmereniya, povtornyiye recency, svyaznostj, `git diff --check`, staging i atomarnyij commit+handoff nakhodyatsya posle granicyi. Nepreryivnaya obsjhaya dliteljnostj rasshirennogo intervala ne izmerena: pervonachaljnaya konechnaya otmetka byila zafiksirovana do nezavisimogo revjyu.

## Granica primenimosti

Profilj opisyivayet odin fakticheskij prokhod na tekusjhej mashine s yeyo kyeshami i nagruzkoj. On pomogayet nakhoditj dorogiye stadii, no ne yavlyayetsya benchmark mezhdu mashinami ili versiyami. Dliteljnostj zavershyonnogo predfinaljnogo smoke-check zapisyivayetsya posle progona; izmenivshijsya otchyot zatem proveryayetsya svyaznostjyu, recency i `git diff --check` bez rekursivnogo polnogo progona toljko radi vremeni sleduyusjhej proverki.

## Prodolzheniye

Novaya kartochka shaga ne nuzhna: obyazateljnyij format i yego avtomaticheskaya proverka zavershenyi etoj sessiyej. Rabochij nabor `master` ne menyayetsya.

## Proverki

TDD-regressiya snachala otklonila novyij otchyot bez profilya, zatem nabor `fum-svyaznostj-rabochej-sessii` proshyol `36/36` testov, vklyuchaya otricateljnyiye sluchai rannej i pustoj granicyi. Pervyij polnyij smoke-check proshyol `39/39` shagov za `174,3` sekundyi; posle ispravlenij nezavisimogo revjyu vtoroj, predfinaljnyij progon proshyol `39/39` za `207,7` sekundyi. Posle zapisi poslednego izmereniya povtoryayutsya toljko zavisyasjhiye ot otchyota recency, teplovaya karta grafa, svyaznostj sessii i `git diff --check`.

## Zatronutyiye materialyi

- [pravila repozitoriya](../../AGENTS.md)
- [opisaniye zhurnala rabot](../../Glossarij/zhurnal-rabot.md)
- [opisaniye rabochej sessii](../../Glossarij/rabochaya-sessiya.md)
- [dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [kontrakt proverki svyaznosti](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [proverka svyaznosti sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py)
- [regressionnyiye testyi](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:5cc026fa52f3f63e21ffb21eba944d4a7bc0d90e502b7a4fe212a07be68454bf -->
<!-- FUM-MD-RECENCY:END -->
