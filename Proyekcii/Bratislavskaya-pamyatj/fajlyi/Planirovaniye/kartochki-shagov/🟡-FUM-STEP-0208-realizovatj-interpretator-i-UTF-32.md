+++
schema_version = 1
card_id = "FUM-STEP-0208"
status = "active"
+++
# Realizovatj interpretator i UTF-32

## Zadacha

V susjhestvuyusjhem [Swift-prototipe pamyati strukturiruyusjhikh operatorov](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/README.md) vyidelitj chistoye ispolneniye konechnogo opredeleniya operatora nad otdeljnyim vkhodom i realizovatj strogij perekhod iskhodnyikh bajtov UTF-8 v Unicode-skalyaryi s otdeljnoj serializaciyej UTF-32LE ili UTF-32BE. Rezuljtat realizuyet [chistoye ispolneniye operatorov i UTF-32](../../Trebovaniya/🟡-chistoye-ispolneniye-operatorov-i-UTF-32.md).

## Pochemu sejchas

Poljzovatelj predlozhil nachatj sozdaniye interpretatora i pozdneye pryamo utochnil dekodirovaniye UTF-8 v UTF-32 na strukturiruyusjhikh operatorakh. Zavershyonnaya FUM-STEP-0004 uzhe dala neboljshoj proveryayemyij SwiftPM-prototip. AutomationExecutor.run prinimayet AutomationFixture, vyichislyayet rezuljtat i sravnivayet yego s expectedOutput; eti dve obyazannosti sleduyet razdelitj, sokhraniv staryiye fiksturyi kak adapter proverki.

Nachatj s AutomationAndSynchronization.swift, Domain.swift, ContextAndLattice.swift, susjhestvuyusjhikh fikstur, testov i probnika ukazannogo paketa. StreamEvent prinimayet String i poluchayet bytes cherez UTF-8 stroki, poetomu eta granica ne predstavlyayet oshibochnyiye iskhodnyiye bajtyi. BoundedContextForest.ingest(bytes:) obnulyayet lokaljnuyu istoriyu pri kazhdom vyizove i sam po sebe ne dokazyivayet strogij dekoder.

## Kriterii zaversheniya

- Pervyij RED peredayot opredeleniye normalizacii i otdeljnyij vkhod «  ISPRAVJ   OTCHYOT  » bez ozhidayemogo otveta; chistoye ispolneniye vozvrasjhayet «ispravj otchyot». Staraya AutomationFixture vyizyivayet tot zhe ispolnitelj, zatem otdeljno sravnivayet nablyudeniye s ozhidaniyem. Etot RED yavlyayetsya promezhutochnoj tochkoj; zaversheniye vklyuchayet dekodirovaniye UTF-8.
- Opredeleniye, versiya, argumentyi i poryadok shagov otdelenyi ot vkhodnyikh dannyikh i vkhodyat v identichnostj ispolneniya. Zakryityij razbor otklonyayet neizvestnyiye i povtornyiye polya, povtornyiye identifikatoryi, nevernyiye tipyi i argumentyi. Zadanyi konechnyiye predelyi razmera opredeleniya, vkhoda, chisla shagov, rezuljtata i trassyi.
- Tekst, iskhodnyiye bajtyi i Unicode-skalyaryi predstavlenyi raznyimi tipizirovannyimi znacheniyami. Bajtovyij vvod dopuskayet nekorrektnyiye posledovateljnosti dlya proverki otkaza; on ne prokhodit cherez ispravlyayusjheye dekodirovaniye String. Konechnyij CLI prinimayet opredeleniye i otdeljnyij vkhod cherez yavnyiye parametryi i stdin, bez vneshnikh effektov.
- Obsjhiye konechnyiye operatoryi sopostavlyayut diapazonyi bajtov, izvlekayut i soyedinyayut bitovyiye polya, sostavlyayut imenovannyiye pravila i povtoryayut ikh s obyazateljnyim prodvizheniyem. Konkretnyiye dlinyi, maski i dopustimyiye diapazonyi UTF-8 vyirazhenyi dannyimi opredeleniya. Yedinstvennyij neprozrachnyij vyizov standartnogo dekodera ne schitayetsya realizaciyej etogo kriteriya.
- Pri korrektnom vkhode rezuljtat snachala soderzhit Unicode-skalyaryi, zatem yavno vyibrannyij shag vozvrasjhayet UTF-32LE libo UTF-32BE bez Unicode-normalizacii i neyavnogo BOM. D1 91 dayot U+0451, UTF-32LE 51 04 00 00 i UTF-32BE 00 00 04 51.
- Nezavisimyiye ozhidaniya pokryivayut chetyire dlinyi UTF-8 i granichnyiye znacheniya. Otklonyayutsya otdeljno stoyasjhiye prodolzheniya, nevernyiye prodolzheniya, izbyitochnyiye kodirovki, surrogatyi, znacheniya vyishe U+10FFFF i nezavershyonnyij konec; oshibka sokhranyayet absolyutnuyu poziciyu bajta. Minimaljnyiye otricateljnyiye vkhodyi: C0 AF, E0 9F 80, ED A0 80, F4 90 80 80, F5 80 80 80 i D1.
- Izmeneniye opredeleniya menyayet povedeniye; raznyiye opredeleniya s odinakovyim itogom sokhranyayut raznyiye khyeshi. Trassa svyazyivayet versiyu opredeleniya, tochnyiye iskhodnyiye bajtyi i vyipolnennyiye shagi. Ozhidaniya ne vyichislyayutsya samim proveryayemyim ispolnitelem.
- Staryiye fiksturyi i nablyudayemyij kontrakt prototipa sokhranenyi libo yavno versionirovanyi. Yestj adresnyiye RED/GREEN, primenimyiye Swift-proverki i vosproizvodimyij profilj, razdeljno izmeryayusjhij zagruzku, proverku opredeleniya, ispolneniye i trassu. Iskhodniki i fiksturyi ostayutsya v ukazannom pakete monorepozitoriya.

## Proiskhozhdeniye i granicyi

Nachaljnaya komanda — «Pokhozhe myi uzhe mozhem nachatj sozdaniye interpretatora.»; ekzemplyar 4df0c064c2c559151ebcbe8e951ddccecb83ef841defc149f96fb09bc4698c21. Utochneniye — «Takzhe na strukturiruyusjhikh operatorakh realizuyem dekodirovaniye UTF-8 v UTF-32.»; ekzemplyar 9209710c0e01f0b5ec95cac93a2a8b4ae32c704560ea5728609deafd72702f5e. Oba otnosyatsya k zadache 01a07d3d-d376-7ad2-aafc-67e4c25a67eb; tochnyiye originalyi s LF sokhranyayutsya v svyazannom zaprose.

Pervaya versiya obrabatyivayet konechnyij bajtovyij vkhod. Rabota porciyami s sokhranyayemyim nepolnyim sostoyaniyem ostayotsya predlozheniyem daljnejshego sreza: chetyire repliki snimka ne podtverzhdenyi pervichnyim JSONL. Sozdaniye vtorogo dvizhka, zhivyiye modeli, ispolneniye proizvoljnogo koda i fajlovyiye effektyi v etot rezuljtat ne vkhodyat. Normativnyiye pravila UTF-8 i UTF-32 pered realizaciyej sveryayutsya po oficialjnomu standartu Unicode s tochnoj versiyej istochnika.

## Istochniki

- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:26:18 MSK -->
<!-- content-sha256: sha256:8d9a78445d77e84e2d89c57ad5cb344886baa3dc2f7d3fbb3532dbffff3b21d2 -->
<!-- FUM-MD-RECENCY:END -->
