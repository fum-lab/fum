+++
schema_version = 1
card_id = "FUM-STEP-0169"
status = "completed"
+++
# Sokhranyatj metadannyiye Finder pri pereustanovke proyekcii

## Zadacha

Ustranitj blokirovku proyekcii sluzhebnyimi fajlami Finder s sokhraneniyem strogoj granicyi upravlyayemogo soderzhimogo. Iskhodnaya gipoteza rannego obnaruzheniya utochnena posle komandyi poljzovatelya ob ignorirovanii etikh fajlov: dlya izvestnyikh metadannyikh vyibran otdeljnyij zhiznennyij cikl.

## Rezuljtat

Obyichnyij fajl s tochnyim imenem `.DS_Store`, ignoriruyemyij Git po svoyemu fizicheskomu puti, isklyuchayetsya iz upravlyayemogo snimka. V sokhranyayemom kataloge on ostayotsya na meste. Pri udalenii prinadlezhasjhego generatoru kataloga yego soderzhimoye atomarno perenositsya v privatnyij katalog proverennogo Git-dir. Simvolicheskiye ssyilki, katalogi, FIFO, neignoriruyemyiye i otslezhivayemyiye fajlyi, inyiye neizvestnyiye imena sokhranyayut otkaz; otsutstviye kvitancii ne dayot vladeniya sluzhebnyim katalogom.

RED/GREEN podtverdili pervonachaljnuyu ustanovku pri metadannyikh v korne, povtor bez izmenenij i smenu pokoleniya s sokhraneniyem bajtov. Proverenyi chetyire fazyi preryivaniya, povtornoye vosstanovleniye i sleduyusjhij apply, a takzhe poryadok sinkhronizacii fajla i imeni arkhiva, sokhraneniye istochnika pri otkaze fajlovogo `fsync` i granica fakticheskogo registra imeni. Profilj sravnil odinakovyiye snimki na 14 katalogakh: okolo 0,00088 s bez metadannyikh i 0,199 s s nimi, sootvetstvenno 0 i 14 vyizovov Git-ignore. Eto adresnaya izmerennaya granica, ne ispyitaniye otklyucheniyem pitaniya.

Osnovaniya — FUM-SBOJ-0042/PROYAVLENIYE-0001 i FUM-SBOJ-0042/PROYAVLENIYE-0002. Ruchnaya ochistka boljshe ne yavlyayetsya shtatnyim resheniyem.

## Istochniki

- [FUM-SBOJ-0042](../../Sboi/FUM-SBOJ-0042-sluzhebnyiye-fajlyi-Finder-blokiruyut-pereustanovku-proyekcii.md).
- [Iskhodnyij zapros i utochneniye poljzovatelya](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/zapros.md).
- [Otchyot priyomki](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).
- [Profilj metadannyikh](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/materialyi/profilj-metadannyikh-Finder.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 20:02:47 MSK -->
<!-- content-sha256: sha256:8ced8449a6f69fc27dde7c2a273c5e26ffb5c82d2e32b6a6330720a3f490a101 -->
<!-- FUM-MD-RECENCY:END -->
