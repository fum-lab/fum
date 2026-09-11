# Otchyot 2026-09-11 18:23:55 MSK - Zavershitj dopusk plana Gosuslug

Itogovyij snimok soderzhit prinyatyij analiticheskij plan pervogo scenariya Gosuslug, yego matricu, devyatj voprosov bez otpravki i razdeljnyiye priyomki A/B/V. Predmetnaya chastj prinyata koordinatorom i zadachej priyoma; ogranicheniye operatorov v istoricheskom istochnike ostavleno neproverennyim. Neobkhodimaya ekvivalentnaya deljta instrumenta perenesena sobstvennyim proverennyim kommitom.

## Profilj vremeni vyipolneniya

| Stadiya                                                 | Dliteljnostj         | Granicyi i sposob izmereniya                                                                    |
| ------------------------------------------------------ | -------------------- | --------------------------------------------------------------------------------------------- |
| Podgotovka itogovogo vkhoda                             | 275.693 s            | S 18:23:55 MSK do 18:28:30.692775 MSK; nastennyiye chasyi s yavnoj zonoj.                          |
| Adresnyiye proverki i standartnyij dokumentacionnyij smoke | Mashinnyiye stroki nizhe | Obyortka izmeryayet kazhdyij process; detalizaciya polnogo zapuska sokhranena v yego JSON.            |
| Ozhidaniye okna do etogo etapa                           | ne izmereno          | Okno uzhe peredano yavnyim soobsjheniyem; ozhidaniye ne pribavlyayetsya k rabote.                        |
| Finaljnoye primeneniye proyekcii i nezavisimaya proverka   | Vne mashinnoj granicyi | Po odnoj komande posle zakryitiya; privatnyiye metki profilya pokazyivayut fakticheskuyu dliteljnostj. |

Granica profilya: podgotovka otschityivayetsya ot nachala etoj papki do formirovaniya otchyota pered adresnyimi proverkami. Processyi obyortki ne pribavlyayutsya k etoj stadii pri perekryitii; vnutrenniye shagi smoke ne dubliruyutsya kak pryamyiye vyizovyi. Posle polnogo zapuska soderzhaniye otchyota sokhranyayetsya; fakticheskiye dliteljnosti i iskhodyi pokazyivayet mashinnyij blok. Zakryitiye, yedinstvennyiye apply/verify, zaklyuchiteljnaya svyaznostj, kommit i peredacha nakhodyatsya vne etoj granicyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:22886cab9d3887aa258c475f4c9957a11d1992b3e6d9b49f31615b2abfd38b6b -->

| Vyizov                                                                             | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------- | ------------ | --------- |
| [Planirovsjhik Gosuslug] Proveritj itogovyiye statusyi i planovyij reyestr               | 3,411 s      | uspeshno   |
| [Planirovsjhik Gosuslug] Proveritj svyaznostj podgotovlennogo itogovogo vkhoda        | 42,028 s     | uspeshno   |
| [Planirovsjhik Gosuslug] Proveritj okonchateljnyij kanonicheskij indeks                | 0,028 s      | uspeshno   |
| [Planirovsjhik Gosuslug] Itogovyij standartnyij dokumentacionnyij smoke plana Gosuslug | 1145,139 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1190,606 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Mashinnyiye stroki i khyeshirovannyij snimok yavlyayutsya istochnikom fakticheskogo iskhoda polnogo dopuska. Yedinstvennyij standartnyij dokumentacionnyij smoke proveryayet 24 shaga vmeste s tekusjhej sessiyej; shirokogo Swift-profilya net. Vse kanonicheskiye izmeneniya indeksiruyutsya do etogo zapuska. Do polnogo dopuska etot otchyot ne oznachayet uspekha po namereniyu.

Posle uspeshnogo terminal predusmotren rovno sleduyusjhij poryadok: proveritj-plan, zakryitj, odno finaljnoye primeneniye bratislavskoj proyekcii, odno nezavisimoye proveritj-manifest, tochnoye indeksirovaniye upravlyayemogo pokoleniya s isklyucheniyem poljzovateljskogo .DS_Store i zakryityikh svideteljstv, read-only svyaznostj, itogovyij kommit. Vo vremya zamyikaniya inoj kanonicheskij vkhod ne menyayetsya. Neuspekh ostanavlivayet priyomku s sokhraneniyem nablyudayemogo iskhoda.

## Resheniya i ogranicheniya

FUM-REQ-0070 i FUM-STEP-0215 podgotovlenyi v itogovom statuse toljko dlya analiticheskogo plana. Ikh priznaniye v etom etape svyazyivayetsya s uspeshnyim zakryityim dokazateljstvom i itogovyim kommitom; prezhniye kontroljnyiye tochki sokhranenyi. Sobstvennyij kod adaptera, registraciya, sekretyi, obrasjheniya i realjnyiye personaljnyiye dannyiye ne sozdavalisj. Otkryityiye voprosyi reguliruyut budusjhuyu realizaciyu, a ne skryivayut ostatok poruchennogo analiticheskogo rezuljtata.

Ispolnyayemyij kontur vzyat iz svoyej dejstvuyusjhej vetki, soderzhasjhej proverennuyu uzkuyu deljtu iz finansov. Polnyij rezuljtat finansov ne zamenyayet tekusjhij zapusk. Koordinator peredal resursnoye okno posle zaversheniya Linux; posle finaljnogo verify korenj soobsjhayet osvobozhdeniye i peredayot itogovyij OID, proverki i profilj oboim adresatam. Eto ne prodvizheniye master.

## Istochniki

- [Komandyi, istoriya i zatronutyiye fajlyi](zapros.md).
- [Itogovyij perechenj obyazateljstv](materialyi/plan-prodolzheniya.json).
- [Analiticheskij plan](../../Planirovaniye/integracii/Gosuslugi.md).
- [Predyidusjhiye adresnyiye dokazateljstva](../2026-09-11_18-02-51_MSK_perenesti-deljtu-tiljdovoj-ogradyi/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 18:28:31 MSK -->
<!-- content-sha256: sha256:5bf4c27e6267e60e046f2d3aaf605dfe517e23e7e920a8067b7eb83f013d60ce -->
<!-- FUM-MD-RECENCY:END -->
