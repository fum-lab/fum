# Svyazj otpechatka proverki s kommitom

Kommit sam po sebe ne dokazyivayet, chto proverka proshla imenno na yego vkhode. Vspomogateljnyij [adapter](scripts/svyazj_otpechatka_s_kommitom.py) sopostavlyayet polnyij OID kommita s dvumya uzhe proverennyimi otpechatkami v3: iz zakryitogo otchyota i poslednego priyomochnogo zapuska. On nichego ne zapisyivayet; obyichnyij rezhim vozvrasjhayet mashinnyij rezuljtat skhemyi `fum.связь-отпечатка-с-коммитом.1`.

```bash
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/связь_отпечатка_с_коммитом.py \
  --корень-репозитория . \
  --сессия Журнал/<stem> \
  --коммит <полный-OID> \
  --отпечаток-закрытия <sha256:64-символа> \
  --отпечаток-запуска <sha256:64-символа> \
  --режим исторический
```

`--сессия` oboznachayet papku, a ne `запрос.md`. Korenj dolzhen sovpadatj s fakticheskim kornem checkout. V obyichnyikh rezhimakh dopuskayetsya toljko obyyekt kommita s odnim dostupnyim roditelem; teg, sokrasjhyonnyij OID, merge i nachaljnyij kommit otklonyayutsya. Podderzhanyi polnyiye SHA-1 i SHA-256.

Yavnyij `--слияние` trebuyet `--режим исторический` i polnyiye `--база L`, `--присоединяемый M`, `--дерево T`. On sveryayet rovno roditelej `[L, M]` i tochnoye derevo T, zatem vosstanavlivayet otpechatok s HEAD=L, diff L→C i pustoj rabochej raznicej. M proveryayetsya otdeljno ot osnovyi otpechatka. Rezuljtat imeyet skhemu `fum.связь-отпечатка-со-слиянием.1`; gotovnostj otchyota i proiskhozhdeniye proverok on ne dokazyivayet. Dlya etogo ispoljzuyetsya [chitatelj s parametrom `--допуск-слияния`](proverka-sliyaniya-iz-master.md).

| Kod zaversheniya | Rezuljtat | Znacheniye |
| --- | --- | --- |
| 0 | `подтверждён` | Kandidat tochno raven oboim predostavlennyim otpechatkam. |
| 2 | `не восстановлен` | Dannoj rekonstrukciyej sootvetstviye ne dokazano. Eto ne dokazateljstvo podmenyi. |
| 1 | Oshibka v stderr | Nevyipolneno predusloviye ili nedostupen lokaljnyij obyyekt. |

## Granica rekonstrukcii

Iskhodnyij v3-otpechatok svyazyivayet predkommitnyij HEAD, bukvaljnyiye bajtyi raznicyi indeksa i rabochego dereva, a takzhe otdeljnyiye neotslezhivayemyiye fajlyi. Adapter vosstanavlivayet toljko polnostjyu indeksirovannuyu granicu: roditelj vyibrannogo kommita, raznica do kommita i pustoye rabocheye derevo. Novyikh kadrov skhemyi i pustogo kadra neotslezhivayemyikh fajlov net. Tekusjhij otchyot, yego `материалы/запуски-проверок/` i tochnaya oblastj `Proyekcii/**` isklyuchayutsya tak zhe, kak v v3.

Istoricheskij rezhim chitayet dva dereva Git. Staraya konfiguraciya, attributes i versiya generatora diff ne sokhranenyi v v3, poetomu nesovpadeniye oznachayet toljko otsutstviye podtverzhdeniya. V chastnosti, `diff.mnemonicPrefix` razlichayet sravneniye kommita s indeksom i sravneniye dvukh kommitov. Staryiye zapisi i khyeshi radi adaptera ne perepisyivayutsya. Gitlink vkhodit v istoricheskij diff bez razvorachivaniya soderzhimogo zavisimosti.

Rezhim `после-коммита` dopolniteljno trebuyet tekusjhij HEAD vyibrannogo kommita, tochnoye ravenstvo stadij, OID, putej i rezhimov indeksa derevu kommita, otsutstviye kanonicheskogo neindeksirovannogo i neotslezhivayemogo khvosta. Stadii i flagi indeksa chitayutsya sovmestno. HEAD, indeks, rabochaya granica i bajtyi diff povtorno proveryayutsya; `assume-unchanged` i `skip-worktree` otklonyayutsya. Eto povtornyiye nablyudeniya, a ne globaljnaya atomarnaya blokirovka.

Pervaya versiya neposredstvennogo rezhima zakryito otklonyayet gitlink i nastroyennyiye ispolnyayemyiye `clean`/`process`-filjtryi do obkhoda rabochego dereva. Dlya takikh repozitoriyev primenim istoricheskij kandidat. Podderzhka proverki vlozhennyikh rabochikh kopij trebuyet otdeljnoj postavki. Fsmonitor otklyuchyon; lazy fetch, Git-pereadresacii, trassirovka i modifikatoryi pathspec iz sredyi ne ispoljzuyutsya. Yavnyiye granicyi sistemnoj i globaljnoj konfiguracii sokhranyayutsya. Nedostayusjhiye obyyektyi ne zagruzhayutsya avtomaticheski.

## Chto ostayotsya proveritj vyizyivayusjhej avtomatizacii

Ravenstvo SHA ne udostoveryayet proiskhozhdeniye peredannyikh strok, gotovnostj otchyota, polnomochiya na izmeneniye, aktualjnostj rezuljtata ili zaversheniye poljzovateljskoj zadachi. Do vyizova trebuyetsya polnaya proverka skhem, zapisej, zakryitogo snimka, upravlyayemogo bloka otchyota i istochnika komandyi; posle nego — proverka rezuljtata protiv konkretnogo obyazateljstva. Adapter ne perekhvatyivayet zaversheniye Codex i ne zapuskayet sleduyusjhij etap.

Regressii nakhodyatsya v [adresnom nabore](tests/test_svyazj_otpechatka_s_kommitom.py). Profilj, iskhodnaya realizaciya do optimizacii i proverka realjnogo prinyatogo kommita sokhranenyi v [zhurnale etapa](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/otchyot.md). Prodolzheniye uchyota obyazateljstv oformleno [otdeljnoj kartochkoj](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0172-proveryatj-ostatok-obyazateljstv-zadachi.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 19:46:01 MSK -->
<!-- content-sha256: sha256:c4ca9406def515eeaf8c8fdd680a5f1dbaeda0a7977f3fced48bea57fa09f7a2 -->
<!-- FUM-MD-RECENCY:END -->
