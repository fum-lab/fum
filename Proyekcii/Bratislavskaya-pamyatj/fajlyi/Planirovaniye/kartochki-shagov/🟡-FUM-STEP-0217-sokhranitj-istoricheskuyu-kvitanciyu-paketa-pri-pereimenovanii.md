+++
schema_version = 1
card_id = "FUM-STEP-0217"
status = "active"
+++
# Sokhranitj istoricheskuyu kvitanciyu paketa pri pereimenovanii

## Zadacha

Dobavitj v shtatnoye pereimenovaniye STEP konechnoye raspoznavaniye khyesh-svyazannoj istoricheskoj kvitancii primeneniya paketa diagnostiki i sokhranitj yeyo iskhodnyiye bajtyi pri obnovlenii zhivyikh ssyilok.

## Pochemu sejchas

Nablyudyonnoye proyavleniye 0085/0001 podmenilo istoricheskij putj pri neizmennom khyeshe prezhnej kartochki. Tochnoye vosstanovleniye uzhe vyipolneno, no tekusjhij instrument ne dokazyivayet predotvrasjheniya povtora. Susjhestvuyusjhij sluchaj profilya obyyavlenij ne pokryivayet etot format.

## Kriterii zaversheniya

- Zafiksirovan konechnyij raspoznavayemyij kontrakt kvitancii i yego proiskhozhdeniye; proizvoljnyiye JSON i pokhozhiye imena ne isklyuchayutsya avtomaticheski.
- RED vosproizvodit izmeneniye istoricheskogo klyucha pri prezhnem khyeshe do realizacii; GREEN sokhranyayet iskhodnuyu kvitanciyu pobajtno pri realjnom pereimenovanii.
- Zhivyiye JSON- i Markdown-ssyilki, kartochka i indeks obnovlyayutsya; raneye zasjhisjhyonnyij profilj obyyavlenij ostayotsya neizmennyim.
- Povrezhdyonnyij raspoznannyij format otklonyayetsya do pervoj zapisi; povtor i obyichnoye pereimenovaniye ne poluchayut regressii.
- Sokhranenyi adresnyiye iskhodyi, neobkhodimyij profilj i primenimaya priyomka. Obsjhaya migracionnaya sistema i realizaciya ostaljnyikh formatov ne dobavlyayutsya v obyyom.

## Istochniki

- [FUM-SBOJ-0085/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0085-podmena-puti-istoricheskoj-kvitancii-paketa-pri-pereimenovanii.md).
- [Iskhodnoye nablyudeniye](../../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/otchyot.md).
- [Postanovka konechnoj meryi](../../Zhurnal/2026-09-11_16-55-35_MSK_utochnitj-operatornoye-vnimaniye-i-prodolzhitj-priyom/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 17:16:54 MSK -->
<!-- content-sha256: sha256:d06efa2d6d38470ca317411a603efd4d5ef3bbb844f0c72c3fff766f03ff1fbf -->
<!-- FUM-MD-RECENCY:END -->
