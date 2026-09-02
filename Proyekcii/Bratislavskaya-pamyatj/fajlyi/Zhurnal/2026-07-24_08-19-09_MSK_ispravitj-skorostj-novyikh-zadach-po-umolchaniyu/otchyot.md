# Otchyot 2026-07-24 08:19:09 MSK - Ispravitj skorostj novyikh zadach po umolchaniyu

Konfiguracionnaya prichina Fast po umolchaniyu ustranena na tom urovne, kotoryij Desktop fakticheski primenyayet k novoj zadache. Upravlyayemyij sistemnyij profilj teperj zadayot standartnyij servisnyij urovenj `default`, soglasovannyij s proyektnyim konfigom, a modelj `gpt-5.6-sol` i rassuzhdeniye `ultra` sokhranenyi.

## Prichina raskhozhdeniya

Predyidusjheye izmeneniye zatronulo toljko `.codex/config.toml`. Ono byilo korrektnyim dlya proyektnogo sloya, no Desktop sozdaval zadachu s yavnyim `service_tier = "priority"` iz otdeljnogo upravlyayemogo profilya `models.new_thread`. Runtime-zhurnal tekusjhej zadachi neposredstvenno pokazyivayet etot override, a modeljnyij katalog nazyivayet urovenj `priority` rezhimom Fast. Poetomu proverka TOML i strogaya zagruzka CLI ne mogli dokazatj fakticheskij vyibor novoj Desktop-zadachi.

## Ispravleniye i granica proverki

V sistemnom profile novyikh zadach `service_tier = "priority"` zamenyon na `service_tier = "default"`. Otvet `configRequirements/read` novogo lokaljnogo app-server podtverdil ispravlennyij defolt vmeste s sokhranyonnyimi `gpt-5.6-sol` i `ultra`. Proyektnaya vozmozhnostj ruchnogo Fast-pereklyuchatelya ne otklyuchena.

Tekusjhaya zadacha uzhe poluchila prezhnij Fast-override pri zapuske. Sozdaniye otdeljnoj zadachi radi proverki ne vyipolnyalosj: kontrakt prilozheniya razreshayet eto toljko po yavnomu zaprosu poljzovatelya. Dlya garantirovannoj perechitki upravlyayemogo profilya nuzhno polnostjyu perezapustitj Desktop; nablyudeniye novoj zadachi posle perezapuska ostayotsya poljzovateljskoj proverkoj rezuljtata, a ne skryityim dejstviyem etoj sessii.

## Proverki

- Sopostavlenyi proyektnyij, poljzovateljskij, upravlyayemyij i startovyij sloi konfiguracii.
- Runtime-zhurnal podtverdil prezhnij override `priority`, a modeljnyij katalog — yego otobrazheniye kak Fast.
- Dekodirovannyij sistemnyij profilj i `configRequirements/read` podtverdili novoye znacheniye `default`.
- Recency-metki, graf Obsidian, sessionnaya svyaznostj, `git diff --check` i polnyij smoke-check prokhodyat.

## Profilj vremeni vyipolneniya

| Stadiya                           | Dliteljnostj  | Granicyi i sposob izmereniya                                                                                                          |
| -------------------------------- | ------------: | ----------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i dopusk FIFO        |         0,4 s | Odin vyizov `join` srazu vernul `admitted`; dliteljnostj izmerena instrumentaljnoj stenovoj metrikoj.                                |
| Soderzhateljnaya diagnostika       |   ne izmereno | Ot dopuska do vyiyavleniya upravlyayemogo profilya; tri nezavisimyikh read-only-napravleniya issledovalisj paralleljno i ne skladyivayutsya.    |
| Izmeneniye sistemnogo profilya     |         0,1 s | Tochechnaya zamena toljko `service_tier` v macOS preferences i nemedlennoye dekodirovannoye chteniye rezuljtata.                           |
| Proverka novogo app-server       |         5,1 s | Inicializaciya otdeljnogo lokaljnogo app-server i chteniye `configRequirements`; vklyuchayet dva ogranichennyikh okna ozhidaniya otveta PTY.   |
| Predfinaljnyij polnyij smoke-check | 3 min 39,90 s | Polnyij lokaljnyij progon iz 54 etapov, izmerennyij sistemnoj stenovoj obyortkoj.                                                        |

Granica profilya: ot atomarnoj registracii v FIFO do zaversheniya predfinaljnogo polnogo smoke-check; finaljnyiye recency-pravki, staging i atomarnaya peredacha ocheredi nakhodyatsya posle etoj granicyi.

## Zatronutyiye materialyi

- [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [predyidusjhij otchyot o proyektnoj konfiguracii](../2026-07-24_07-49-44_MSK_pereklyuchitj-skorostj-modeli-na-standartnuyu/otchyot.md)
- [iskhodnyij zapros tekusjhej sessii](zapros.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [predyidusjhij zapros o perevode proyektnoj konfiguracii na standartnuyu skorostj](../2026-07-24_07-49-44_MSK_pereklyuchitj-skorostj-modeli-na-standartnuyu/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1ef34274acedf1df143cc281ebc88701728c9e026066c47452daee1331a8694d -->
<!-- FUM-MD-RECENCY:END -->
