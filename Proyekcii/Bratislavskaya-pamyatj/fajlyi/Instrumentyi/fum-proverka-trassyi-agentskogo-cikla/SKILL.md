---
name: fum-proverka-trassyi-agentskogo-cikla
description: Proveryatj polnostjyu lokaljnyiye trassyi agentskogo cikla FUM versii 3, vklyuchaya neblokiruyusjheye modeljnoye vetvleniye, tochnoye podtverzhdeniye perekhoda i nezavisimyiye svideteljstva vneshnego ispolneniya.
---

# Proverka trassyi agentskogo cikla

Eta lokaljnaya avtomatizaciya proveryayet versionirovannuyu trassu odnogo agentskogo epizoda. Ona otdelyayet vnutrennyuyu model-only-rabotu ot ozhidayusjhego poljzovateljskogo podtverzhdeniya i ot kazhdogo posleduyusjhego rubezha vneshnego ispolneniya. Proverka rabotayet po sokhranyonnyim JSON-fajlam i ne obrasjhayetsya k seti, sekretam, zhivoj LLM, vneshnim servisam, publikacii ili fizicheskomu dejstviyu.

## Kogda ispoljzovatj

Ispoljzuj avtomatizaciyu posle izmeneniya skhemyi ili fikstur trassyi versii 3, a takzhe pered peredachej sessii, zatragivayusjhej kontrakt agentskogo cikla. Versii 1 i 2 ostayutsya samostoyateljnyimi istoricheskimi kontraktami: eta proverka ne perepisyivayet ikh semantiku.

## Komandyi

Proveritj skhemu v3 i vse tri etalonnyiye fiksturyi iz kornya repozitoriya:

```bash
python3 Инструменты/fum-proverka-trassyi-agentskogo-cikla/scripts/proveritj-trassu-agentskogo-cikla.py
```

Proveritj odnu trassu s yavno zadannyim scenariyem:

```bash
python3 Инструменты/fum-proverka-trassyi-agentskogo-cikla/scripts/proveritj-trassu-agentskogo-cikla.py \
  --schema Документация/37-минимальный-формат-трассы-исполняемого-агентского-цикла/схема-события-v3.json \
  --trace Документация/37-минимальный-формат-трассы-исполняемого-агентского-цикла/фикстура-неблокирующего-модельного-ветвления-v3.jsonl \
  --scenario nonblocking_branching_v3
```

Avtonomnyiye testyi:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-proverka-trassyi-agentskogo-cikla/tests \
  -p 'test_*.py'
```

## Proveryayemyij kontrakt

Scenarij proveryayet dva sloya kontrakta:

- kazhduyu zapisj — po lokaljnoj JSON Schema versii 3 s zakryityim naborom polej;
- epizod celikom — po otnosheniyam mezhdu poryadkom zapisej, obsjhim tochnyim predkom vetvej, byudzhetami, proverkami, proiskhozhdeniyem rezuljtatov, politikoj khraneniya, bezopasnoj kontroljnoj tochkoj i nezavisimyimi svideteljstvami perekhoda.

Validator prinimayet shestj yavno nazvannyikh profilej. Tri iz nikh sootvetstvuyut kanonicheskim fiksturam:

- `nonblocking_branching_v3` — rovno dve proverennyiye model-only-vetvi ot obsjhego predka, zakryityij perekhod i otsutstviye vneshnego dejstviya;
- `late_confirmation_v3` — pozdnij razreshyonnyij otvet dlya tochnyikh tekusjhikh obyyekta i versii v sokhranyonnoj bezopasnoj kontroljnoj tochke vyibirayet sokhranyonnuyu aljternativu;
- `single_branch_limited_budget_v3` — rovno odna proverennaya vetvj, nepustoj spisok neproverennyikh aljternativ, `ambiguity_resolved = false`, nulevoj ostatok byudzheta i itogovyij `needs_input`.

Yesjhyo tri profilya ispoljzuyutsya avtonomnyimi mutacionnyimi testami: `stale_confirmation_v3` trebuyet ustarevsheye podtverzhdeniye i svyazannuyu stadiyu `stale_response`, `refusal_v3` — aktualjnyij otkaz i `refused`, `revocation_v3` — susjhestvovavsheye raneye tochnoye podtverzhdeniye, posleduyusjhij otzyiv i `revoked`. Oni ne obyyavlyayutsya dopolniteljnyimi kanonicheskimi fiksturami.

Vnutrennij vyibor ostayotsya `candidate_only` dazhe pri sostoyanii `selected_in_model`, `recommended` ili `selected_by_user`. Perekhod `transition_user_confirmed` trebuyet boleye rannego tochnogo poljzovateljskogo otveta dlya tekusjhikh obyyekta i versii na sokhranyonnoj bezopasnoj kontroljnoj tochke. Odnogo `actor = user` nedostatochno: `source_event.ingress_authorization` obyazan otdeljno zafiksirovatj tochnuyu trojku `status = allowed`, `purpose = transition_response` i nepustoj `policy_ref` politiki priyoma.

Vse zapisi obyazanyi sokhranyatj odin `trace_id`. Obe vetvi i ikh model-only-shagi ssyilayutsya na odin tochnyij `model_checkpoint`; summa stoimosti shagov i proverok sovpadayet s potrebleniyem byudzheta svoyej vetvi, a itogovoye potrebleniye byudzheta epizoda — s summoj potrebleniya vetvej. V `episode_checkpoint` i konechnom `episode_state` obyazanyi tochno sovpastj ostatok byudzheta, chislo bezopasnyikh produktivnyikh prodolzhenij i chislo ostavshikhsya razlichayusjhikh proverok. Modeljnaya i epizodnaya kontroljnyiye tochki, stadii i dejstviya sokhranyayut tochnyiye identifikator i versiyu ozhidayusjhego perekhoda.

`selected_by_user` svyazyivayetsya s boleye rannim tochnyim aktualjnyim otvetom i stadiyej `transition_user_confirmed`, tem zhe vyibrannyim variantom i yavnyimi nomerami dokazateljstv. `stale` ne sozdayot podtverzhdeniya ili vyibora. `refuse` zakryivayet osnovannuyu na etom otvete cepochku, a `revoke` dopustim toljko posle susjhestvovavshego raneye tochnogo aktualjnogo podtverzhdeniya i annuliruyet zavisyasjhiye ot nego posleduyusjhiye rubezhi; boleye pozdneye ispolneniye ne mozhet ssyilatjsya na otozvannuyu cepochku.

Kazhdyij rubezh posle poljzovateljskogo podtverzhdeniya trebuyet otdeljnoj boleye rannej zapisi `external_evidence` s tochnyimi koordinatami perekhoda, ozhidayemyim effektom, istochnikom i proiskhozhdeniyem: `authorized` — `authority_decision / allowed`, `preflight_passed` — `current_state_preflight / passed`, `executed` — `execution_receipt / succeeded`, `observed` — `result_observation / observed`. Eti svideteljstva ne vyivodyatsya drug iz druga, iz podtverzhdeniya ili modeljnogo vyibora; odnoj stroki roli `evidence_source` nedostatochno. Stadii `executed` i `observed` predstavlyayutsya toljko otdeljnyimi `transition_action`.

Validator razlichayet aktualjnoye podtverzhdeniye, ustarevshij signal, otkaz i otzyiv. On otklonyayet terminaljnuyu zapisj, posle kotoroj poyavilisj novyiye sobyitiya; prezhdevremennyiye `unresolved_conflict` i `needs_input`; lozhnoye snyatiye neodnoznachnosti odnoj vetvjyu; vneshneye dejstviye modeljnogo shaga; skryitoye rassuzhdeniye, setevoj provajder i sekretopodobnyij material.

## Granica avtomatizacii

Polozhiteljnyiye fiksturyi dokazyivayut toljko soglasovannostj sokhranyonnogo lokaljnogo primera s kontraktom. Oni ne yavlyayutsya skvoznyim runtime FUM, ne zapuskayut modelj i ne podtverzhdayut realjnyij poljzovateljskij interfejs, avtorizator, preflight, ispolnitelj ili nablyudatelj. Validator takzhe ne prinimayet reshenij za poljzovatelya i ne povyishayet vyibrannuyu modeljnuyu vetvj do kanonicheskogo sostoyaniya.

## Istochniki trebovanij

- [kartochka FUM-STEP-0106](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md)
- [trebovaniye FUM-REQ-0035](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-29 16:02:08 MSK -->
<!-- content-sha256: sha256:74407e2eb55a2b488174c42b4e0d580732c27018e51f049f98d07ed7afec363d -->
<!-- FUM-MD-RECENCY:END -->
