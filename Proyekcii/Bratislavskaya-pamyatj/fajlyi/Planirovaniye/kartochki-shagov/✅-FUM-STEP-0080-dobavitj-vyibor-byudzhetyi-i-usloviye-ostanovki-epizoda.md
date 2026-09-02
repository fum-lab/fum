+++
schema_version = 1
card_id = "FUM-STEP-0080"
status = "completed"
+++
# Dobavitj vyibor, byudzhetyi i usloviye ostanovki epizoda

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zavershitj minimaljnyij ispolnyayemyij cikl raspredelyonnogo myisliteljnogo epizoda versionirovannyim resheniyem vyibora, konechnyimi byudzhetami i obyazateljnyim usloviyem ostanovki. Vyibor dolzhen opiratjsya na zaraneye obyyavlennyiye kriterii, proiskhozhdeniye, dokazateljstva, iskhodyi proverki i sokhranyonnyiye raznoglasiya, a ne na prostoye chislo soglasnyikh otvetov. Limityi ispolnitelej, raundov, modeljnyikh i instrumentaljnyikh vyizovov, vkhoda, vyikhoda i rezerva dolzhnyi proveryatjsya do sleduyusjhego dejstviya. Ozhidayusjhij podtverzhdeniya vneshnij perekhod dolzhen ostanavlivatjsya nezavisimo ot bezopasnoj produktivnoj modeljnoj chasti epizoda.

## Rezuljtat

Obsjhaya pamyatj raspredelyonnogo epizoda perevedena na skhemu zhurnala, sostoyaniya, pokoleniya i reducer versii 4. Seed khranit tochnyiye kanonicheskiye bajtyi neizmenyayemoj politiki vyibora i ostanovki, svyazannyiye s pasportnyimi `selection.main`, roljyu selektora, osnovaniyem vyibora, `stop.main` i zapretom golosovaniya; dinamicheskiye resheniye i terminaljnyij iskhod ostayutsya otdeljnyimi append-only-sobyitiyami.

Versionirovannoye resheniye vyibora zakreplyayet polnyiye spiski kriteriyev, rassmotrennyikh vkladov s khyeshami soderzhaniya i proiskhozhdeniya, proverok, vneshnikh dokazateljstv i dispozicij vsekh raznoglasij. Raznoglasiye svyazyivayetsya s tochnyimi proverkoj, utverzhdeniyem, vkladom, rezuljtatom i dopustimyimi dokazateljstvami; pozdneye razresheniye prinimayet dokazateljstvo toljko iz zavershyonnoj svyazannoj cherez zhurnal zaraneye obyyavlennoj razlichayusjhej proverki pri sovpadenii utverzhdeniya, vklada i rezuljtata. SHA-256 polnogo frontira vyibora, ssyilka na zamenyayemuyu redakciyu i obyazateljnyij pustoj nabor neustranyonnyikh raznoglasij ne pozvolyayut zavershitj `goal_met` po ustarevshemu ili konfliktnomu resheniyu. Politika zapresjhayet golosovaniye i podschyot korrelirovannyikh kopij kak samostoyateljnuyu oporu; vnutrennij vyibor ne poluchayet statusa podtverzhdeniya ili avtorizacii.

Pered kazhdyim dejstviyem otdeljnoye append-only-pokoleniye atomarno publikuyet rezervaciyu konechnogo shestimernogo byudzheta ispolnitelej, raundov, modeljnyikh i instrumentaljnyikh vyizovov, vkhoda i vyikhoda. Versionnaya politika izmereniya vyivodit raskhod vkladov i proverok iz distinct-identichnostej, proiskhozhdeniya, nablyudenij i razmera kanonicheskoj nagruzki. Sleduyusjheye pokoleniye zakryivayet tochnyij permit fakticheskim raskhodom, ne prevyishayusjhim rezervaciyu; convenience-interfejs yavno vozvrasjhayet oba pokoleniya dlya posledovateljnogo CAS. Nezakryitaya posle sboya rezervaciya ostayotsya zanyatoj. Obyichnaya rabota ne mozhet potratitj zasjhisjhyonnyiye rezervyi proverki i peredachi, a `budget_exhausted` obyazan vosproizvesti inache dopustimuyu rezervaciyu vmeste s tochnyimi required i available.

Ozhidaniye podtverzhdeniya khranitsya kak tochnyij versionirovannyij vneshnij perekhod i ne blokiruyet bezopasnyiye produktivnyiye model-only-vetvi. `needs_input` dopuskayetsya toljko posle ischerpaniya takikh vetvej libo ikh byudzheta, a `unresolved_conflict` — toljko posle ischerpaniya bezopasnyikh razlichayusjhikh proverok. Odin iz pyati terminaljnyikh iskhodov zapechatyivayet tekusjheye semantic run ot lyubyikh novyikh sobyitij; vozobnovleniye trebuyet novogo `run_generation_id`, drugikh kanonicheskikh bajtov aktivnogo kontekstno posiljnogo rabochego paketa, yego polnogo preflight po zakreplyonnomu snimku vkhodov i tochnogo SHA-256 terminaljnogo predshestvennika.

Kanonicheskoye vosstanovleniye vyivodit iz odnikh i tekh zhe seed i zhurnala tochnyiye resheniya, ostatki i nezakryityiye rezervacii byudzheta, ozhidayusjhiye perekhodyi, terminaljnyij iskhod i neustranyonnyiye raznoglasiya. Avtonomnyiye scenarii dokazyivayut realjnyij CAS-perekhod k novomu semantic run, pobajtovoye vosstanovleniye i fail-closed-otkaz gologo domennogo sobyitiya bez predshestvuyusjhej rezervacii. Polnaya skvoznaya avtonomnaya priyomka raspredelyonnogo myisliteljnogo epizoda ostayotsya granicej FUM-STEP-0081.

## Istochniki

- [iskhodnyij zapros 2026-08-02 09:36:50 MSK — Dobavitj vyibor, byudzhetyi i usloviye ostanovki epizoda](../../Zhurnal/2026-08-02_09-36-50_MSK_dobavitj-vyibor-byudzhetyi-i-usloviye-ostanovki-epizoda/zapros.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii pri ozhidanii podtverzhdeniya](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [proveryayemyij mnogoagentnyij kontur FUM](../../Glossarij/proveryayemyij-mnogoagentnyij-kontur-FUM.md)
- [FUM-STEP-0079 — nezavisimaya proverka i sokhraneniye raznoglasij](✅-FUM-STEP-0079-dobavitj-nezavisimuyu-proverku-i-sokhraneniye-raznoglasij.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3cc5ce431b588cb27beced815da80064bca58f2ccd2545c69c336f284140dda2 -->
<!-- FUM-MD-RECENCY:END -->
