# Otchyot 2026-07-24 08:42:34 MSK - Ispravitj poisk zakreplyonnogo heartbeat dispetchera

Avtozapusk vosstanovlen na fakticheskoj strukture snimka Codex. Heartbeat teperj proveryayet vse zakreplyonnyiye i nedavniye nezakreplyonnyiye zadachi vmeste, poetomu vidit sobstvennuyu zakreplyonnuyu dispetcherskuyu zadachu i ne propuskayet chuzhuyu aktivnostj v lyubom iz dvukh massivov.

## Prichina i ispravleniye

`codex_app.list_threads` vozvrasjhayet raznyiye mnozhestva v polyakh `pinnedThreads` i `threads`: pervoye soderzhit vse zakreplyonnyiye zadachi, vtoroye — ne boleye 50 nedavnikh nezakreplyonnyikh. Zhivaya dispetcherskaya zadacha nakhodilasj toljko v `pinnedThreads`. Prezhnij prompt govoril o yedinom recent-snimke, no ne treboval obyyedinitj polya, poetomu tik iskal sobstvennyij identifikator v `threads` i zavershalsya do Git-proverok.

Pervyij i povtornyij snimki teperj yavno obyyedinyayut oba massiva. Sobstvennaya zadacha podtverzhdayetsya kak yedinstvennaya zapisj v `pinnedThreads` bez dublikata v `threads`, a vse ostaljnyiye sostoyaniya proveryayutsya po obyyedineniyu. Trebovaniye zakrepitj otdeljnuyu dispetcherskuyu zadachu stalo chastjyu ustanovki novogo klona; otsutstviye polya, narushennoye zakrepleniye, neizvestnoye sostoyaniye i lyubaya drugaya `active`-zadacha sokhranyayut fail-closed-ostanovku.

## Zhivaya avtomatizaciya

Susjhestvuyusjhaya heartbeat-avtomatizaciya obnovlena shtatnyim instrumentom bez sozdaniya dublya. Celevaya dispetcherskaya zadacha, pyatiminutnoye raspisaniye i status `ACTIVE` sokhranenyi. Proverka sokhranyonnogo sostoyaniya podtverzhdayet novyij prompt v obeikh inventarizaciyakh; neprozrachnyiye identifikatoryi ne perenesenyi v publikuyemuyu pamyatj.

## Proverki

- Krasnyij test snachala podtverdil otsutstviye obyyedineniya `pinnedThreads` i `threads`; posle ispravleniya vosemj celevyikh heartbeat-testov i polnyij avtonomnyij nabor iz `60` testov prokhodyat.
- Zhivoj snimok podtverdil tochnuyu prichinu: dispetcher prisutstvuyet toljko sredi zakreplyonnyikh zadach, a tekusjhaya rabochaya zadacha nablyudayetsya otdeljno kak `active`.
- Shtatnyiye obnovleniye i prosmotr avtomatizacii, a takzhe tochechnoye chteniye sokhranyonnyikh polej podtverzhdayut sokhraneniye yeyo identichnosti, raspisaniya i statusa.
- Pervyij planovyij tik s novyim prompt nashyol dispetcher i ostanovilsya po praviljnoj prichine — iz-za drugoj nablyudayemoj `active`-zadachi.
- Recency-metki, graf Obsidian, sessionnaya svyaznostj, `git diff --check` i polnyij smoke-check prokhodyat vse `54` etapa.

## Profilj vremeni vyipolneniya

| Stadiya                                 | Dliteljnostj  | Granicyi i sposob izmereniya                                                                                                                       |
| -------------------------------------- | ------------: | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Registraciya i dopusk FIFO              |         0,4 s | Odin shtatnyij `join` nemedlenno vernul `admitted`; neizmennogo ozhidaniya FIFO ne byilo.                                                             |
| Diagnostika zhivogo snimka              |   ne izmereno | Chteniye poslednikh tikov, skhemyi `list_threads` i lokaljnyikh kontraktov; tri nezavisimyikh read-only-audita vyipolnyalisj paralleljno i ne skladyivayutsya. |
| Krasnaya i zelyonaya celevyiye TDD-fazyi     | 0,2 s i 0,8 s | Otdeljnyiye stenovyiye zapuski odnogo novogo krasnogo testa i vosjmi heartbeat-testov posle ispravleniya.                                             |
| Polnyij nabor sleduyusjhego shaga vetki     |       18,16 s | Stenovoye vremya finaljnogo avtonomnogo nabora iz `60` testov posle usileniya proverki oboikh snimkov.                                               |
| Obnovleniye i proverka zhivogo heartbeat |         0,3 s | Shtatnyiye update/view i tochechnoye podtverzhdeniye sokhranyonnyikh polej avtomatizacii.                                                                    |
| Predfinaljnyij polnyij smoke-check       | 3 min 40,55 s | Polnyij lokaljnyij progon iz `54` etapov, izmerennyij sistemnoj stenovoj obyortkoj.                                                                  |

Granica profilya: ot pervogo FIFO-vyizova do zaversheniya predfinaljnogo polnogo smoke-check; neizmennogo ozhidaniya FIFO ne byilo, paralleljnyiye stadii ne skladyivayutsya, finaljnyiye recency-pravki, staging i atomarnyij commit+handoff nakhodyatsya posle izmeryayemogo smoke-check.

## Zatronutyiye materialyi

- [pravila repozitoriya](../../AGENTS.md) i [dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md) i [heartbeat-shablon](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [regressionnyiye testyi](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [reyestr sistemnyikh instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [predyidusjheye ispravleniye samoproverki heartbeat](../2026-07-24_07-23-50_MSK_ispravitj-samoproverku-heartbeat-dispetchera/zapros.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:27deda074dd61d4a0aab5afcf728101c3b7995d000f00c828b374cf03ee29da1 -->
<!-- FUM-MD-RECENCY:END -->
