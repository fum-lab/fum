+++
schema_version = 1
card_id = "FUM-STEP-0160"
status = "active"
+++
# Nakaplivatj statistiku vyizovov

## Zadacha

Realizovatj pervyij vosproizvodimyij Swift-importyor zavershyonnogo prefiksa Codex JSONL v dolgovechnyij kontejner i otchyot JSON/Markdown po pryamyim vyizovam modeli. Eto ogranichennyij segment [FUM-REQ-0045](../../Trebovaniya/🟡-statistika-vyizovov-dlya-razvitiya-avtomatizacij.md); adapteryi runtime/v4 i issledovaniye polnogo nabora evristik razvivayutsya otdeljno.

## Pochemu sejchas

Poljzovatelj trebuyet vyibiratj sleduyusjhiye urovni avtomatizacii po nakoplennyim sobyitiyam, a ne toljko po vpechatleniyu o chastyikh vyizovakh. Audit obnaruzhil dostupnyiye call_id i rezuljtatyi v JSONL, no ne universaljnyij parent_call_id dlya vlozhennyikh operacij. Ruchnoj podschyot nevosproizvodim i teryayet proiskhozhdeniye.

## Kriterii zaversheniya

- Importyor proveryayet identichnostj session_meta, prinimayet toljko zavershyonnyiye stroki i sokhranyayet dokazuyemyiye polya vyizova s bajtovyim proiskhozhdeniyem.
- Povtornoye chteniye i novyij process ne uvelichivayut schyotchiki; konflikt togo zhe klyucha s inyimi bajtami zakryito obnaruzhivayetsya. Nezavershyonnyij khvost, otsutstviye rezuljtata i output bez call_id ne stanovyatsya vyizovom ili uspekhom.
- Razlichayutsya chislo pryamyikh vyizovov, sopryazhyonnyiye i nesopryazhyonnyiye rezuljtatyi, neizvestnyij iskhod i izmerennaya zaderzhka zapisi; JSON i Markdown poluchenyi iz odnoj modeli.
- TDD, profilj malogo i boljshogo fiksirovannogo vkhoda i resheniye ob optimizacii sokhranyayut tochnyiye vkhodyi i rezuljtatyi. Nakladnyiye raskhodyi importa izmerenyi otdeljno.
- Posle proverki fikstur vyipolnen razreshyonnyij import kornevogo JSONL v lokaljnyij kontejner vne Git, povtornyij import i vosstanovleniye; publichnyij otchyot ne raskryivayet argumentyi, rezuljtatyi i sluzhebnoye sostoyaniye.
- Polnaya realizaciya trebovaniya ne vyivoditsya iz odnogo adaptera. Daljnejshiye adapteryi i evristiki sokhranenyi yavnyim prodolzheniyem.

## Istochniki

- [Tochnyij zapros i resheniye](../../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).
- [Trebovaniye FUM-REQ-0045](../../Trebovaniya/🟡-statistika-vyizovov-dlya-razvitiya-avtomatizacij.md).
- [Kontejner nablyudenij](🟡-FUM-STEP-0156-realizovatj-kontejner-nablyudenij-s-binarnyimi-blokami.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:20:29 MSK -->
<!-- content-sha256: sha256:889d6c14e350b0cde2f3a80f82b1d48b7ec709acf7b92080cfd43900a6bc03eb -->
<!-- FUM-MD-RECENCY:END -->
