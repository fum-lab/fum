# Otchyot 2026-07-22 14:53:29 MSK - Ustranitj kholostyiye vozvratyi ozhidaniya ocheredi

Ozhidaniye FIFO-pozicii boljshe ne dolzhno samo stanovitjsya istochnikom raskhoda konteksta. Ocheredj poluchila dolgozhivusjhij besshumnyij rezhim, a pravila rabochej sessii zapresjhayut rutinnyiye soobsjheniya o neizmennom sostoyanii.

## Rezuljtat

Novaya komanda `wait-until-actionable` prodolzhayet pyatiminutnyiye read-only-okna vnutri odnogo processa i ne pechatayet promezhutochnyij `waiting`. Ona vozvrasjhayet pervyij dejstvennyij rezuljtat: neobkhodimostj perechitatj novyij `HEAD`, uspeshnyij dopusk, gryaznoye rabocheye derevo libo oshibku. Atomarnyij FIFO-poryadok, ranneye obnaruzheniye perekhoda i otsutstviye heartbeat-zapisej sokhranenyi.

Pyatiminutnyij `wait` ne udalyon. On ostayotsya zapasnyim putyom dlya sredyi bez bezopasnogo dolgozhivusjhego vyizova i otdeljnyim diagnosticheskim interfejsom. Neizmennyij otvet takogo vyizova ne poluchayet otdeljnogo soderzhateljnogo soobsjheniya sverkh obyazateljnogo obnovleniya host, no sam sluzhebnyij vozvrat mozhet zanyatj modeljnyij kontekst.

## Ekonomiya konteksta i granicyi host

Repozitornaya avtomatizaciya teperj ne vozvrasjhayet povtornyij JSON kazhdyiye pyatj minut i ne trebuyet povtornogo bootstrap-zapuska. Prodolzheniya zhivogo processa po vozmozhnosti uderzhivayutsya vnutri odnogo orkestracionnogo vyizova. Eto sokrasjhayet nablyudavshiyesya minutnyiye soobsjheniya v chat i kholostyiye vozvratyi modeli nastoljko, naskoljko pozvolyayet boleye prioritetnaya politika obnovlenij host.

Nekotoryiye sredyi vsyo ravno mogut vyidavatj sluzhebnyij deskriptor processa ili trebovatj pustoj poll. Eti zapisi ne pereskazyivayutsya poljzovatelyu, no polnostjyu ubratj ikh mozhet toljko push- ili deferred-wakeup-podderzhka host. Preryivaniye dostoverno zablokirovannogo processa sokhranyayet bilet; neodnoznachnyij rezuljtat vosstanavlivayetsya idempotentnyim `join` toj zhe kornevoj zadachi.

## TDD i proverki

Dva integracionnyikh scenariya snachala pokazali otsutstviye novoj CLI-komandyi: process nemedlenno zavershalsya vmesto tikhogo ozhidaniya. Posle realizacii oni podtverdili neizmennostj `queue_oid` do perekhoda, odin `reload_required` posle kommita i odin JSON `admitted` posle `finish-clean`. Otdeljnaya krasno-zelyonaya regressiya zakrepila zaversheniye `KeyboardInterrupt` kodom `130` bez stdout i traceback.

Polnyij nabor ocheredi proshyol `35/35` testov. Otdeljnyiye validatoryi rabochego nabora vetki, planovogo reyestra, mashinno-lokaljnyikh putej, recency, grafa i svyaznosti zavershilisj uspeshno; obsjhij smoke-check proshyol `39/39` shagov.

## Prodolzheniye

Novaya kartochka shaga ne nuzhna: sistemnoye ispravleniye zaversheno v etoj sessii. Rabochij nabor `master` ostayotsya bez izmenenij — `FUM-STEP-0024` sokhranyayet `ready`, `FUM-STEP-0035` sokhranyayet `blocked` i prezhneye usloviye vozobnovleniya.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [predyidusjhij zapros o pyatiminutnom ozhidanii](../2026-07-22_11-17-21_MSK_uvelichitj-ozhidaniye-ocheredi-do-pyati-minut/zapros.md)
- [kontrakt ocheredi](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:935ca5fc52068d52ddbc72b0f7642d459e3e091d862dde772770f125bd628291 -->
<!-- FUM-MD-RECENCY:END -->
