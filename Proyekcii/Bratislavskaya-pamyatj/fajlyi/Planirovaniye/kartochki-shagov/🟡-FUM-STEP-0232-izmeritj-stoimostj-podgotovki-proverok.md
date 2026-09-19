+++
schema_version = 1
card_id = "FUM-STEP-0232"
status = "active"
+++
# Izmeritj stoimostj podgotovki proverok

## Zadacha

Razdelitj stoimostj importa i discovery, sozdaniya fikstur, tel testov i ochistki dorogogo nabora proverok reyestra. Vyibiratj optimizaciyu po nablyudayemomu profilyu, sokhranyaya semantiku i izolyaciyu.

## Pochemu sejchas

V prinyatom J22 nabor reyestra zanyal 490,878 s. Pervyij profilj obsjhej fiksturyi zanimayet okolo 0,253 s na podgotovku i sam po sebe ne obyyasnyayet vesj interval.

## Kriterii zaversheniya

- Vosproizvodimyij profilj razlichayet discovery, podgotovku, tela testov i ochistku; vlozhennyiye intervalyi ne summiruyutsya dvazhdyi.
- Regressii sokhranyayut iskhodyi izmeryayemyikh operacij i pervichnuyu oshibku pri otkaze ochistki; ustranenyi [0158](../../Sboi/FUM-SBOJ-0158-maskirovaniye-oshibki-podgotovki-ochistkoj.md) i [0159](../../Sboi/FUM-SBOJ-0159-podmena-importa-narushayet-nastrojku-regressii.md).
- Po rezuljtatam vyibrana i proverena optimizaciya libo obosnovano yeyo otsutstviye; opublikovanyi sopostavimyiye izmereniya i ogranicheniya.
- Izmeneniye proshlo primenimyiye obsjhiye proverki, dokumentaciya sootvetstvuyet realjnyim granicam.

## Tekusjhij rezuljtat

Adresno proverennyij profilj odnoj susjhestvuyusjhej fiksturyi, shestj regressij, dva otkryityikh izmereniya. Polnaya priyomka novogo koda yesjhyo ne vyipolnena. [Izmereniye vsego nabora](../../Zhurnal/2026-09-19_02-44-26_MSK_izmeritj-polnyij-nabor-proverok-reyestra/otchyot.md) zaversheno: 355 testov OK, discovery17,705 s, vyipolneniye463,382 s. Osnovnoj nablyudayemyij raskhod — vyizovyi subprocess.run; konkretnaya bezopasnaya optimizaciya yesjhyo vyibirayetsya. Nakladnyiye raskhodyi cProfile otdeljno ne izmerenyi, sravneniye uskoreniya ne zayavlyayetsya.

## Istochniki

- [Zapros](../../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/zapros.md) i [otchyot](../../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md).
- [Instrukciya izmereniya](../../Instrumentyi/fum-reyestr-planirovaniya/profilj-podgotovki-fikstur.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 02:58:35 MSK -->
<!-- content-sha256: sha256:69c351a6c45e0acf41edc0efcf3c1a606597250b9d3042fb7217bcc4365b5464 -->
<!-- FUM-MD-RECENCY:END -->
