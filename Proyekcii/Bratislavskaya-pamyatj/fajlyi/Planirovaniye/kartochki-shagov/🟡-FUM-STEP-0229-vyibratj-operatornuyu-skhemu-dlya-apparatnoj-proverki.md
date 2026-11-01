+++
schema_version = 1
card_id = "FUM-STEP-0229"
status = "active"
+++
# Vyibratj operatornuyu skhemu dlya apparatnoj proverki

## Zadacha

Vyibratj odin pervyij kandidat apparatnoj realizacii strukturiruyusjhikh operatorov po [trebovaniyu proyektirovaniya chipov](../../Trebovaniya/🟡-proyektirovaniye-chipov-dlya-FUM.md). Podgotovitj vosproizvodimyij programmnyij profilj i pasport ogranichennoj FPGA-proverki. Ni realizaciya FPGA, ni ASIC, ni sobstvennoye proizvodstvo etim pervyim shagom zaraneye ne obyyavlyayutsya zavershyonnyimi.

## Pochemu sejchas

Poljzovatelj otdeljno sprosil o napravlenii proyektirovaniya chipov i poruchil zanyatjsya im. Prezhnyaya komanda svyazala sobstvennoye proizvodstvo s ustojchivyimi chasto trebuyemyimi operatornyimi skhemami. Susjhestvuyusjhij [STEP0017](🟡-FUM-STEP-0017-opisatj-inzhenernyij-pasport-kremniyevogo-substrata-FUM.md) opisyivayet inzhenernyij pasport substrata; novaya rabota dolzhna prevratitj apparatnoye namereniye v ogranichennyij izmerimyij eksperiment.

## Kriterii zaversheniya

- Sopostavlenyi ne meneye dvukh kandidatov iz realjno ispolnyayemyikh operatornyikh skhem. Sokhranenyi podtverzhdyonnaya semantika, chastota na obyyavlennoj nagruzke, stabiljnostj kontrakta i obyyasneniye vyibora libo otkaza ot vsekh kandidatov.
- Sokhranenyi programmnyij baseline, tochnyij kommit, otkryityiye vkhodyi, nezavisimyiye ozhidayemyiye vyikhodyi, oshibki, predelyi, komandyi vosproizvedeniya i profilj zaderzhki/propusknoj sposobnosti/pamyati. Neizmerimaya energiya yavno ostayotsya neizvestnoj.
- Podgotovlen pasport FPGA-eksperimenta: interfejs dannyikh, ogranichennaya razryadnostj i razmer, testovyij stend, modelj otkazov, metriki resursov i tajminga, trebuyemyiye instrumentyi/plata i kriterii sopostavleniya s programmnyim baseline. Simulyaciya i fizicheskij zapusk imeyut raznyiye svideteljstva.
- Dlya ASIC cherez partnyora perechislenyi vkhodnyiye dokazateljstva i sleduyusjhij dopusk bez obrasjheniya k partnyoru: rezuljtat FPGA, apparatnyiye interfejsyi, PPA-ocenka, proveryayemostj, tekhnologicheskiye dannyiye i neopredelyonnosti.
- Sobstvennoye proizvodstvo vyideleno kak daljnij samostoyateljnyij etap; yego resursnaya i tekhnologicheskaya osusjhestvimostj ne obyyavlena ustanovlennoj. Pervyij shag zavershyon pasportom i profilem, a ne formaljnyim obesjhaniyem kremniya.
- Sokhranenyi istochniki, chelovecheskoye opisaniye zapuska i dopustimyij otricateljnyij rezuljtat: apparatnyij perenos mozhet okazatjsya necelesoobraznyim.

## Istochniki

- [Iskhodnaya komanda](../../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:06:47 MSK -->
<!-- content-sha256: sha256:acd7902e696e3db6d029e8fe224cad41baac673cd97a105fbf93f0eff25b3ac0 -->
<!-- FUM-MD-RECENCY:END -->
