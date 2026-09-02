# Otchyot 2026-07-24 07:49:44 MSK - Pereklyuchitj skorostj modeli na standartnuyu

Proyektnyij sloj Codex boljshe ne zaprashivayet povyishennuyu skorostj Fast. V nyom sokhranenyi modelj `gpt-5.6-sol`, rassuzhdeniye `ultra` i izolyaciya lokaljnyikh navyikov. Samo eto izmeneniye ne dokazyivayet itogovyij vyibor Desktop pri sozdanii novoj zadachi.

## Izmeneniye konfiguracii

V `.codex/config.toml` znacheniye `service_tier = "fast"` zameneno na `service_tier = "default"`. Otdeljnoye znacheniye `standard` ne ispoljzuyetsya: skhema Codex nazyivayet bazovyij standartnyij servisnyij urovenj `default`. Flag `features.fast_mode = true` ostavlen kak vozmozhnostj ruchnogo vyibora Fast cherez interfejs Codex i sam po sebe ne vklyuchayet povyishennuyu skorostj.

Reyestr sistemnyikh prilozhenij i instrumentov sinkhronizirovan s novyim sostoyaniyem konfiguracii i nablyudayemyimi versiyami poverkhnosti, vstroyennogo runtime i samostoyateljnogo CLI. Istoricheskiye zaprosyi i otchyotyi, opisyivayusjhiye prezhnij Fast-snimok, ne perepisyivalisj.

## Posleduyusjheye utochneniye

Novaya Desktop-zadacha posle etogo izmeneniya vsyo ravno poluchila yavnyij `service_tier = "priority"` iz upravlyayemogo sistemnogo profilya `models.new_thread`. Etot boleye prioritetnyij vyibor sootvetstvuyet Fast i perekryil proyektnyij `default`; poetomu prezhnyaya priyomka podtverdila toljko proyektnyij sloj, no ne fakticheskij defolt novoj zadachi. Diagnostika i ispravleniye sistemnogo profilya opisanyi v [posleduyusjhem otchyote](../2026-07-24_08-19-09_MSK_ispravitj-skorostj-novyikh-zadach-po-umolchaniyu/otchyot.md).

## Proverki

- Lokaljnyij razbor TOML podtverzhdayet `service_tier = "default"` i sokhrannostj ostaljnyikh proyektnyikh invariantov.
- Vstroyennyij i samostoyateljnyij runtime Codex prokhodyat stroguyu zagruzku obnovlyonnoj konfiguracii i modeljnogo kataloga.
- Recency-metki, graf Obsidian, sessionnaya svyaznostj, `git diff --check` i polnyij smoke-check prokhodyat.

## Profilj vremeni vyipolneniya

| Stadiya                           | Dliteljnostj  | Granicyi i sposob izmereniya                                                                                                                             |
| -------------------------------- | ------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Ozhidaniye i dopusk FIFO           | 21 min 57,9 s | Ot atomarnoj registracii `join` do rezuljtata `admitted`, vklyuchaya perechityivaniye novogo `HEAD` i podtverzhdeniye `ack-head` posle rabotyi predshestvennika. |
| Soderzhateljnaya rabota            |   ne izmereno | Ot dopuska do celevyikh proverok; read-only-analiz subagentov vyipolnyalsya paralleljno i ne skladyivayetsya s obsjhim stenovyim vremenem.                        |
| Celevaya proverka konfiguracii    |        0,24 s | Lokaljnyij TOML-invariant i strogaya zagruzka dvumya runtime, izmerennyiye odnim stenovyim progonom.                                                         |
| Predfinaljnyij polnyij smoke-check | 3 min 59,36 s | Polnyij lokaljnyij progon repozitoriya iz 54 etapov, izmerennyij sistemnoj stenovoj obyortkoj.                                                              |

Granica profilya: ot pervogo FIFO-vyizova do zaversheniya predfinaljnogo polnogo smoke-check; vklyuchayet ozhidaniye ocheredi, a finaljnyiye recency-pravki, staging i atomarnaya peredacha nakhodyatsya posle izmeryayemogo smoke-check.

## Zatronutyiye materialyi

- [proyektnaya konfiguraciya Codex](../../.codex/config.toml)
- [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [iskhodnyij zapros tekusjhej sessii](zapros.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [iskhodnyij zapros o pervonachaljnom zakreplenii modeli i Fast](../2026-07-17_12-45-07_MSK_zakrepitj-modelj-Codex-po-umolchaniyu/zapros.md)
- [posleduyusjhij zapros ob ispravlenii sistemnogo profilya novyikh zadach](../2026-07-24_08-19-09_MSK_ispravitj-skorostj-novyikh-zadach-po-umolchaniyu/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6117b35544977c2c29a8f719b9e1c18d12ded106903d3c1d6eba6e0ae6e85409 -->
<!-- FUM-MD-RECENCY:END -->
