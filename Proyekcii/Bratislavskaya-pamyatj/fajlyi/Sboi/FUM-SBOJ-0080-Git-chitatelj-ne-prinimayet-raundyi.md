+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0080"
"статус" = "активна"
+++
# Git-chitatelj ne prinimayet raundyi

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0080/ПРОЯВЛЕНИЕ-0001`: pri podgotovke obyichnoj priyomki paketa 0175 chteniyem tochnogo M `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d` ustanovleno, chto obyortka podderzhivayet v4/report-v3, a zakryityij Git-chitatelj trebuyet report-v2 i prezhnij poryadok. Obyichnyij rezhim, `--слияние` i `--допуск-слияния` ispoljzuyut odin obsjhij chitatelj bajtov; eto marshrutyi odnogo nablyudeniya, a ne tri nezavisimo povtoryonnyikh zapuska. [Razbor granicyi](../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/materialyi/granica-chitatelya-i-priyomki.md) sokhranyayet tochnyiye funkcii, ogranicheniye i proverennyij aljternativnyij putj. Novogo RED ili fakticheski zakryitogo otchyota etogo etapa yesjhyo net.

## Ozhidaniye, dejstvuyusjhij kontrakt i mekhanizm

Predpolozheniye o vozmozhnosti prinyatj vyibrannyiye v4-raundyi susjhestvuyusjhim Git-chitatelem ne podtverdilosj. Pri etom dejstvuyusjhij navyik pryamo razdelyayet versii i sokhranyayet Git-chitatelyu v3/report-v2: avtomatizaciya ne narushila zayavlennuyu podderzhku. Nablyudayemoye vozdejstviye — pervonachaljnyij vyibor v4 ne dayot trebuyemoj obyichnoj priyomki po M. Eto ogranicheniye sovmestimosti, a ne dokazateljstvo lozhnogo uspekha chitatelya.

Rasshireniye odnogo usloviya nomera skhemyi nedostatochno: trebuyetsya susjhestvuyusjhaya semantika strogogo inventarya, syiryikh zapisej, poryadka, perekhodov i dvukh otpechatkov. Soderzhateljnyij khyesh v4 vklyuchayet polnyiye Unix-rezhimyi, kotoryiye Git ne sokhranyayet. Soglasovannostj sokhranyonnyikh khyeshej neljzya vyidavatj za nezavisimoye vosstanovleniye prav iz kommita.

## Vosstanovleniye i posleduyusjhaya rabota

Koordinator otozval prezhnij vyivod ob obyazateljnosti reader-v4 dlya blizhajshego C2. Shtatnyij novyij otdeljnyij etap v3/report-v2 podderzhan iskhodnyim M i vyibran dlya blizhajshej priyomki shesti paketov. Tekusjhiye v4-zapisi sokhranyayutsya bez ponizheniya i bez perepisyivaniya. Novyij etap obuslovlen sovmestimoj priyomkoj, ne obkhodom otricateljnogo iskhoda.

Predlozhennyij budusjhij kontrakt yavno sokhranyayet dostatochnyiye atributyi vkhodov v novoj versii snimka libo vvodit otdeljnuyu Git-vosproizvodimuyu granicu. On poka ne realizovan i ne yavlyayetsya neobkhodimoj predposyilkoj blizhajshego sliyaniya. Staryiye zakryityiye v4 bez nedostayusjhikh dannyikh ne poluchayut vyimyishlennyiye rezhimyi.

## Svyazannyiye shagi

- [FUM-STEP-0175](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md); osnovaniye — `FUM-СБОЙ-0080/ПРОЯВЛЕНИЕ-0001`. Blizhajshaya rabota ispoljzuyet podderzhannyij format; posleduyusjheye issledovaniye sovmestimosti sokhranyayetsya otdeljno ot neobkhodimogo paketa.

## Kriterij zakryitiya

Novyiye priyomki imeyut yavnyij dostatochnyij kontrakt istoricheskogo svideteljstva i skvoznyiye RED/GREEN cherez neizmenyayemyiye Git-obyyektyi. Podderzhka starogo v3/report-v2 sokhranena; podmenyonnyiye bajtyi, nepolnyij inventarj, nevernyij poryadok i otpechatki otklonyayutsya. Rezhim C2 dopolniteljno sokhranyayet tochnyiye roditeli, derevo, proiskhozhdeniye ispolneniya iz M i politiku. Prava staryikh v4 ne ugadyivayutsya. Shtatnaya priyomka drugogo formata sama po sebe eto ogranicheniye ne ustranyayet.

## Istochniki

- [Upravlyayusjhaya koordinaciya i granica etapa](../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/zapros.md).
- Obsjhij raspredelitelj vyidelil nomer dlya zadachi `01a09047-faa1-7370-83f7-cdfc8f9943a6`; sobyitiye `1f37f53b0ffe6c4f7e7f6f25a27dfa8b32088e20eba68d3e50fbad6af8093b76`. Chastnaya kvitanciya prochitana; yeyo pervonachaljnaya gipoteza obyazateljnogo prerequisite utochnena pozdnim resheniyem koordinatora.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:47:51 MSK -->
<!-- content-sha256: sha256:e435d59f2d3665ead27ad8b4e6ccc3f7cab8e9ae4592f215ecb358ef0be37fb4 -->
<!-- FUM-MD-RECENCY:END -->
