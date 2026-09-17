+++
schema_version = 1
card_id = "FUM-STEP-0230"
status = "active"
+++
# Sozdavatj kommityi cherez proveryayemyij putj

## Zadacha

Vyipolnitj [poljzovateljskij vyibor polnoj avtomatizacii sozdaniya kommitov](../../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/zapros.md): proveryatj imya avtora i ostaljnyiye obyazateljnyiye polya do i posle sozdaniya, sokhranyaya iskhodnogo committer i opublikovannuyu istoriyu. Ustranitj [FUM-SBOJ-0146](../../Sboi/FUM-SBOJ-0146-propusk-probela-v-imeni-avtora.md).

## Pochemu sejchas

Propusk probela povtorilsya v obyichnom rezuljtate i posleduyusjhem merge. Otdeljnyij predikat avtora ne obespechivayet pervichnyiye komandyi, modelj, tochnyij indeks, obyazateljnyiye proverki i proverku poluchennogo obyyekta.

## Kriterii zaversheniya

- Podgotovka i sozdaniye ispoljzuyut dejstviteljnyiye pervichnyiye komandyi, nablyudayemuyu modelj, poslednij kornevoj UUID i tochnyij proverennyij indeks.
- Obyichnyij kommit, merge s oboimi roditelyami i otkaz bez skryitogo povtoreniya podtverzhdenyi realjnyimi Git-fiksturami; sokhranenyi RED, GREEN i profilj.
- Avtor s obyichnyim probelom, email, committer i yavno naznachennyiye datyi sveryayutsya; neopredelyonnostj processa ne obyyavlyayetsya uspekhom.
- Kontroljnaya tochka prinyata v rabochem dereve; itogovyij rezhim otdeljno podklyuchayet yedinstvennoye zamyikaniye proyekcii i proveren po pravilu 000188. Poka itogovyij rezhim zakryito otkazyivayet, shag ostayotsya aktivnyim.
- Instrukciya otrazhayet realjnyiye effektyi, ogranicheniya i otdeljnuyu publikaciyu; integracionnaya dokumentaciya sverena.

## Tekusjhij rezuljtat

Kontroljnaya tochka `edff49de48decdef897ebd4fb300f1e92f5a86b4` sozdana cherez sam instrument i opublikovana; eto ne integraciya i ne itogovaya priyomka. [Sleduyusjhij etap](../../Zhurnal/2026-09-16_00-10-13_MSK_sokhranitj-postanovku-chipovogo-napravleniya/otchyot.md) utochnyayet obyazateljnyij native UUID, metku FUM-INTAKE, ostanovku Git i hooks pri signalakh, vosstanovleniye nepolnoj kvitancii i profilj rannikh otkazov. Itogovoye zamyikaniye proyekcii ostayotsya otdeljnyim nezavershyonnyim kriteriyem.

## Istochniki

- [Iskhodnyiye komandyi](../../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/zapros.md).
- [Otchyot i izmereniya](../../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/otchyot.md).
- [Kontrakt instrumenta](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/sozdaniye-kommita.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 00:40:41 MSK -->
<!-- content-sha256: sha256:a66d587a1a938eba86cd5dbf00fd6de62779378cd35a0dc22e4873aed7f889d0 -->
<!-- FUM-MD-RECENCY:END -->
