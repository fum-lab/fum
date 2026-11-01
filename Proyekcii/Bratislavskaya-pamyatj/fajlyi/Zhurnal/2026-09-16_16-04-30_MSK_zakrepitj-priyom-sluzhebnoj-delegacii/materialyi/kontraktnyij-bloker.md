# Granica proiskhozhdeniya do izmeneniya koda

Snimok `fb288b45bd50e932c6f612f46d4786c1384d2051`. Kod i testyi ne izmenenyi. Usloviye porucheniya «sokhranitj konkretnyij kontraktnyij bloker do mutacii koda» primeneno k opisannoj nizhe granice, a ne k obsjhemu otsutstviyu mekhanizma uchyota.

## Chto uzhe mozhno pereispoljzovatj

- [Proverka diapazonov](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/obrabotka_soobsjhenij.py), `проверить_свидетельство`, stroki 67–73, i `фрагмент`, stroki 217–222: forma puti/granic i SHA konkretnyikh bajtov.
- [Chteniye istorii](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/istoriya_puti_gita.py), `прочитать_историю`, stroki 115–145: vse vershinyi/roditeli i versii obyichnogo fajla. Eto opora monotonnogo nabora prinyatij, bez vtoroj sistemyi statusov.
- [Reyestr koordinatora](../../../Planirovaniye/zadachi/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/obyazateljstva.json) soderzhit `FUM-ПРОДОЛЖЕНИЕ-СИСТЕМА` s dejstviteljnyim sokhranyonnyim chelovecheskim osnovaniyem. [Nezavisimyij yakorj v3](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/obyazateljstva_zadachi.py), stroki 24–32, zakreplyayet UUID koordinatora i import iz 6fc2c7a76dd7d23a703418b4072f0fdc561a4f53. On ne zakreplyayet konkretnuyu novuyu delegaciyu etomu ispolnitelyu i ID yego rabotyi.
- [Plan/guard](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/proveritj-prodolzheniye-zadachi.py), stroki 80–96, trebuyet sobstvennyij UUID osnovaniya. [Kontrakt v2](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/kontrakt-obyazateljstv-v2.md) i susjhestvuyusjhaya priyomka sokhranyayut trebovaniya k rezuljtatam; chuzhaya komanda ne mozhet molcha statj sobstvennoj.

## Nedostayusjhaya svyazj

Dostavka finansovogo sluchaya nablyudayetsya kak function_call_output instrumenta send_message_to_thread bez strukturnogo call_id. V adresno prosmotrennom tekusjhem istochnike koordinatora otpravleniye novogo etapa predstavleno custom_tool_call s imenem exec i JavaScript-vkhodom, posle nego — item_completed. Eto nablyudeniye serializacii, a ne dokazateljstvo semantiki proizvoljnogo JavaScript. Ni XML/source_thread_id poluchatelya, ni prisutstviye stroki v JS, ni razgovornoye prinyatiye ne udostoveryayut polnomochiya i tochnoye sootvetstviye dostavki otpravleniyu.

Diapazonyi/SHA podtverzhdayut celostnostj i povtornoye chteniye nablyudyonnyikh bajtov, no ne naznachayut doverennogo koordinatora. Chelovecheskaya komanda o sistemnom prodolzhenii i obsjheye pravilo delegacii dayut soderzhateljnoye osnovaniye rabotyi; oni sami po sebe ne yavlyayutsya mashinnyim svideteljstvom tochnoj svyazi etoj dostavki, prinyatiya i vyibrannogo ID rabotyi ispolnitelya. Susjhestvuyusjhiye helpers takoj svyazi ne ustanavlivayut. Nezavisimyij RO-razbor podtverdil etu granicu.

Dlya pervogo bezopasnogo mashinnogo priyoma nedostayot nezavisimo prinyatogo sopostavleniya: kakoj proverennyij akt koordinatora svyazyivayet konkretnuyu dostavku i otdeljnoye tipizirovannoye prinyatiye s UUID koordinatora/ispolnitelya, dejstviteljnyim chelovecheskim osnovaniyem i ID rabotyi. Yego doverennaya rolj dolzhna zadavatjsya vne samoj prinimayemoj zapisi. Polnyij Git OID mozhet zakrepitj uzhe prinyatoye sopostavleniye, no odin OID ne yavlyayetsya polnomochiyem. Ispolnitelj ne vprave sozdatj zapisj, vyibratj yeyo sobstvennyij OID i obyyavitj yego doverennyim yakorem prinyatiya root-obyazateljstv.

## Tochnyij sleduyusjhij shag

Koordinatoru opredelitj i zakrepitj minimaljnoye mezhzadachnoye svideteljstvo polnomochnogo sopostavleniya s ukazannyimi svyazyami i nezavisimo vyibrannoj tochkoj doveriya. Priyomka root-obyazateljstva ostayotsya u koordinatora. Variant — prinyatyij im neizmenyayemyij artefakt, yavno opirayusjhijsya na uzhe zakreplyonnoye chelovecheskoye osnovaniye; proverka dolzhna znatj yego doverennuyu rolj do razbora novoj zapisi. Eto predlozheniye granicyi, ne novaya utverzhdyonnaya JSON-skhema i ne trebovaniye kriptograficheskoj podpisi samo po sebe.

Posle etogo vyipolnitj iskhodnyij RED bez maskirovki: zavershyonnyij razovyij v1 i chelovecheskij ostatok 0, proverennaya dostavka i otdeljnoye dejstviteljnoye prinyatiye, otsutstviye svyazannoj rabotyi → exit 2. Dobavleniye nevyipolnennoj rabotyi cherez shtatnyij putj → exit 3 i tochnyij ID. Zatem proverki podmenyi istochnika/svyazi, poteri prinyatiya v istorii i povtornaya sverka pered vyidachej guard; susjhestvuyusjhiye statusyi i priyomku pereispoljzovatj. Profilj izmeryatj na toj zhe otkryitoj fiksture do i posle izmeneniya. Polnota ogranichena proverennyim dolgovechnyim naborom, ne vsemi razgovornyimi prinyatiyami.

RED/GREEN i profilj sejchas ne zapuskalisj: ikh predposyilka «proverennaya dostavka i dejstviteljnoye prinyatiye» yesjhyo ne imeyet minimaljno utverzhdyonnoj mezhzadachnoj proverki. Pritvornyij GREEN, proveryayusjhij toljko zayavlennyij XML ili samonaznachennyij yakorj, narushil byi prinyatuyu granicu. Hooks, Trust i nativnyij Stop ne zatronutyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 16:15:40 MSK -->
<!-- content-sha256: sha256:3896558b3805e344cda0a3d111fe364a4efb2fb9acfdae324fedc9a84cc70343 -->
<!-- FUM-MD-RECENCY:END -->
