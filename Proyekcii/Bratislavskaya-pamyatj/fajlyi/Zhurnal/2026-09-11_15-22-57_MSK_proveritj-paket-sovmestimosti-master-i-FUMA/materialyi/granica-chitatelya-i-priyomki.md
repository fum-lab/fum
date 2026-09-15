# Granica Git-chitatelya i obyichnoj priyomki

Iskhodnyij kommit pravil M: `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`. Proveryayemyij paket shesti perenosov sokhranyon v `69e267b75f83f3f762379cfb61dd09c3d4df125f`. Razbor vyipolnen toljko chteniyem kornya i dvukh dochernikh analizov; novyiye testyi, polnyij smoke i izmeneniya chitatelya pri etom ne vyipolnyalisj.

## Podtverzhdyonnaya granica

Obyortka podderzhivayet yavno vyibrannyiye `fum.test-run.v4` i zakryitiye `fum.test-run-report.v3`. Git-chitatelj M sokhranyayet otdeljnyij strogij kontrakt v3/report-v2. Eto pryamo opisano v razdele «Nezavisimyiye versii kontraktov» [navyika otchyotov](../../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md). Dobavleniye dopustimogo nomera skhemyi ne ispravlyayet nesovmestimostj: daleye chitatelj vyizyivayet prezhniye `ожидаемый_снимок`, `сформировать_блок` i `проверить_порядок_проверок`, otvergayusjhiye raundyi.

Dlya raundov v M uzhe susjhestvuyut `проверить_историю_раундов`, `построить_план_раундов`, `сформировать_блок_раундов` i `ожидаемый_снимок_раундов`. Oni strogo proveryayut syiryiye zapisi, perekhod skhemyi, poryadok, gotovnostj i dva sokhranyonnyikh konteksta. Ikh povtornoye ispoljzovaniye ne dokazyivayet nezavisimoye vosstanovleniye soderzhateljnogo otpechatka iz Git.

`вычислить_отпечаток_содержимого` v [obyortke](../../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/scripts/otchyotyi_o_zapuskakh_proverok.py) vklyuchayet polnyiye `stat.S_IMODE` obyichnyikh fajlov i fajlov podmodulej. Git sokhranyayet dlya etikh fajlov toljko `100644` ili `100755`. Naprimer, rezhimyi 0640 i 0644 dayut odin Git-rezhim i raznyiye soderzhateljnyiye otpechatki. Podstanovka predpolagayemyikh 0644/0755 ne vosstanavlivayet istoricheskiye prava.

## Proverennyiye blizkiye svideteljstva

- Kontur sliyaniya proveryayet bajtyi blob i poljzovateljskij ispolnyayemyij bit, fiksiruyet M/tree/L, derevo obyortki, gitlink i politiku. Polnyiye rezhimyi prezhnego rabochego dereva on ne sokhranyayet.
- `обязательства_задачи_v2.отпечаток_коммита` ispoljzuyet to zhe imya `fum.каноническое-содержимое.1`, podstavlyaya 644/755 iz Git. Etu realizaciyu neljzya perenositj kak dokazateljstvo prezhnego v4-otpechatka.
- Snimki indeksa soderzhat strogiye Git-obyyektyi, manifestyi zavisimostej i kvitanciyu materializacii. Poslednyaya dejstviteljno proveryayet tochnyiye 0644/0755, no opisyivayet novoye otdeljnoye derevo. Svyazj yeyo khyesha s prezhnimi run-v4/report-v3 otsutstvuyet; ona ne vospolnyayet istoricheskiye atributyi.

## Predlozheniye dlya budusjhikh priyomok

Minimaljnoye rasshireniye mozhet yavno sokhranyatj v novoj versii zakryitogo snimka polnyij perechenj rezhimov vkhodnyikh fajlov i podmodulej. Git-chitatelj togda proveryayet strogij inventarj, bajtyi, ispolnyayemyij bit i gitlink, vosstanavlivayet prezhnij soderzhateljnyij khyesh s sokhranyonnyimi rezhimami i otdeljno proveryayet Git-svyazj kommita. Staryiye zakryityiye v4 bez takogo svideteljstva ostayutsya istoricheskimi dannyimi. Eto predlozheniye kontrakta, ne realizovannyij dopusk i ne dokazannaya neobkhodimostj blizhajshej integracii.

## Shtatnaya obyichnaya priyomka susjhestvuyusjhim chitatelem

[Navyik otchyotov](../../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) pryamo dopuskayet: «Skhema sleduyusjhego etapa vyibirayetsya yavno, predyidusjhaya istoriya sokhranyayetsya». Format vyibirayetsya po katalogu konkretnogo zaprosa, a ne po UUID vsej zadachi. Git-chitatelj chitayet svideteljstva toljko ukazannoj papki.

Proverennyij plan: sokhranitj tekusjhij otkryityij terminaljnyij v4-etap kontroljnoj tochkoj Q bez zayavleniya finaljnoj gotovnosti; posle kommita Q sozdatj otdeljnyij etap s tem zhe UUID, doslovnyimi komandami i yavnyim vyiborom v3. Posle vozvrasjheniya tyazhyologo okna zavershitj obyichnyij standartnyij full, zakryitj report-v2 i vyipolnitj shtatnuyu paru zamyikaniya proyekcii. Poluchennyij P imeyet rovno odnogo roditelya Q. Prezhnij neizmennyij Git-chitatelj iz M proveryayet vyibrannyij novyij otchyot i svyazj Q→P. Staryiye v4-zapisi ne perepisyivayutsya i ne stanovyatsya novyim prinyatyim otchyotom.

Obyichnyij polnyij zapusk ispolnyayetsya v sobstvennom proveryayemom checkout. Yego chteniye staryim chitatelem M ne udostoveryayet proiskhozhdeniye vsego ispolneniya iz M. Klyuch `--источник-проверок` vklyuchayet specialjnyij kontur sliyaniya i neprimenim obyichnomu P. Dlya posleduyusjhego C2 otdeljno neobkhodimyi susjhestvuyusjhiye proverki roditelej [L, M], tochnogo dereva, proiskhozhdeniya ispolneniya iz novogo M i politiki; obyichnaya priyomka P ikh ne zamenyayet.

## Istochnik i ostatok

[Tekusjhij zapros](../zapros.md) sokhranyayet proiskhozhdeniye koordinacii. Koordinator podtverdil neobyazateljnostj v4 dlya blizhajshego C2 i otozval prezhnij vyivod o prerequisite. Paket vozvrasjhyon k shesti perenosam; predlozhennoye rasshireniye Unix-atributov sokhranyayetsya posleduyusjhej rabotoj. Tyazhyoloye okno peredano Linux VM, zatem finansovoj zadache i toljko posle nikh etoj zadache. Finaljnaya priyomka shesti paketov i dostavka koordinatoru ostayutsya nezavershyonnyimi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:47:51 MSK -->
<!-- content-sha256: sha256:ce5061562f6a1995cc719bf46d3990aa2d6d9a395abc02d5765152d1c0654d13 -->
<!-- FUM-MD-RECENCY:END -->
