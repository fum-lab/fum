# Pervyij scenarij strukturiruyusjhikh operatorov

## Vopros

Myi zhe uzhe sokhranyali scenarij dlya pervoj realizacii potoka strukturiruyusjhikh operatorov?

## Otvet

Da. V FUM-REQ-0067 pervyim predmetnyim scenariyem sokhraneno strogoye dekodirovaniye iskhodnyikh bajtov UTF-8 v Unicode-skalyaryi s otdeljnoj serializaciyej UTF-32LE ili UTF-32BE. Pravila dekodirovaniya vyirazhayutsya opredeleniyami strukturiruyusjhikh operatorov.

Konechnoye ispolneniye uzhe realizovano v prototipe. Pervaya vertikalj osnovnogo rantajma FUMA podklyuchayet etot zhe interpretator i sokhranyayet prinyatyij vkhod, rezuljtat i trassu v nakopiteljnuyu pamyatj. Osnovnoj primer i regressiya nastoyasjhego binarnika ispoljzuyut UTF-32LE; normalizaciya teksta ostayotsya dopolniteljnyim scenariyem. Rabota s konechnyim vkhodom ne podtverzhdayet obrabotku potoka porciyami.

## Istochniki trebovanij

- [Utochneniye poljzovatelya i rabota po integracii](../Zhurnal/2026-09-15_19-04-26_MSK_integrirovatj-ispolneniye-operatora-FUMA/zapros.md).
- [Iskhodnaya postanovka interpretatora](../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/zapros.md).

## Opornyiye materialyi

- [FUM-REQ-0067](../Trebovaniya/🟡-chistoye-ispolneniye-operatorov-i-UTF-32.md).
- [Vosproizvedeniye pervogo scenariya v FUMA](../Prilozheniya/FUMA/macOS/docs/ispolneniye-operatora.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:33:18 MSK -->
<!-- content-sha256: sha256:d96c5d2786f5473b5d18e379e457e93350335b7ba4d404e47efce8358f6e5b3b -->
<!-- FUM-MD-RECENCY:END -->
