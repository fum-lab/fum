# Arkhivnyij snimok odnoj zadachi FUMA

Adapter prinimayet yavno ukazannyij Codex JSONL i ozhidayemyij UUID zapisannoj sessii. Yego rezuljtat opisyivayet toljko sostoyaniye zavershyonnogo prochitannogo prefiksa. On ne nablyudayet zhivoj process, interfejs ili naznachennoye rabocheye derevo i ne schitayet finaljnyij otvet, tishinu, EOF libo HookPrompt dokazateljstvom zaversheniya zadachi ili vyipolneniya obyazateljstv.

## Podderzhannyij format

Samostoyateljnyij Swift-paket `Packages/АрхивныйСнимокЗадачи` proveren na Swift-kommite `cffd4c52852da19d3e71c5a2d22e41712b3e734f`; iskhodnaya osnova — `dd172958b0128cba73361eeac136e8bc66190230`. Paketyi `КонтейнерНаблюдений` i `СнимокАгентскойЗадачи` sokhranenyi bez izmeneniya. Adapter ispoljzuyet publichnyij reduktor i kontejner, no ne sinteticheskoye khranilisjhe ili sinteticheskiye predstavleniya prezhnego paketa.

Granica zavershyonnosti zadayotsya LF: ni korrektnyij JSON bez LF, ni nedopisannyij JSON ili UTF-8 v khvoste ne vkhodyat v snimok. Dopustimyi obolochki `session_meta`, `turn_context`, `event_msg`, `response_item`, `compacted`, `world_state`, `token_usage_record`, `inter_agent_communication_metadata`; verkhnij obyyekt soderzhit toljko `type`, `timestamp`, `payload`, `ordinal`, `metadata`. Dlya vsekh tipov obyazateljnyi `type` i obyyekt `payload`. Prezhniye formyi mogut ne soderzhatj `timestamp`, `ordinal` i `metadata`. Pri nalichii `timestamp` yavlyayetsya nepustoj strokoj do 128 bajtov UTF-8 bez upravlyayusjhikh simvolov, `metadata` — obyyektom, `ordinal` — iskhodnoj desyatichnoj JSON-leksemoj ot 0 do Int64.max bez znaka, drobi, eksponentyi i vedusjhego nulya, krome samogo `0`. Snachala trebuyetsya yedinstvennaya `session_meta` s kanonicheskim UUID, sovpadayusjhim s ozhidayemyim. Neizvestnaya verkhnyaya forma, povtornyij klyuch, neodnoznachnaya identichnostj ili prevyisheniye byudzheta zakryivayut import otkazom. `cli_version` ne dokazyivayet sovmestimostj neizvestnoj formyi.

Snimok sokhranyayet susjhestvovaniye zapisi sessii, poslednij yavno zapisannyij `cwd` iz `session_meta` ili `turn_context` i modelj poslednego khoda, yavno identificirovannogo podderzhannyimi `turn_context` ili `event_msg`. `turn_context` trebuyet nepustoj `turn_id`; `event_msg` s yavnyim `turn_id` menyayet toljko kontekst khoda. Sravneniye identifikatorov pobajtovoye. Poyavleniye drugogo khoda sbrasyivayet prezhnyuyu modelj; otsutstviye `model` v `turn_context` takzhe ostavlyayet yeyo neizvestnoj. Tekst dialoga, instrukcii, argumentyi i vyivod instrumentov ne vkhodyat v sokhranyayemyij nabor.

Tri sluzhebnyikh tipa, verkhniye `ordinal` i `metadata` sokhranyayutsya toljko v proiskhozhdenii: ikh bajtyi vliyayut na SHA i granicu iskhodnogo prefiksa. Soderzhimoye ne perenositsya v arkhiv i ne menyayet khod, modelj, `cwd`, chelovecheskiye polnomochiya ili zhivoj status. `ordinal` ne obyazan vozrastatj i ne zamenyayet schyotchik zavershyonnyikh LF-strok. Vlozhennyiye obyyektyi prokhodyat prezhniye resursnyiye byudzhetyi i proverku povtornyikh klyuchej. Neizvestnyiye verkhniye klyuchi, neizvestnyiye tipyi, nevernyiye vidyi `payload`/`metadata` i nevernyiye leksemyi `ordinal` otklonyayutsya.

Kazhdyij prefiks sozdayot novyij ogranichennyij snimok iz ne boleye tryokh nablyudenij. Vremya zdesj yavlyayetsya logicheskoj poziciyej prefiksa, a ne chasami realjnogo processa. JSON i Markdown yavno govoryat: «po sostoyaniyu prochitannogo prefiksa».

## Dolgovechnostj i proiskhozhdeniye

Odin obyyekt tipa `архивный-снимок-задачи/завершённый-префикс`, versii 1, svyazyivayet versiyu adaptera, ozhidayemyij UUID, identichnostj i SHA iskhodnoj `session_meta`, chislo prinyatyikh bajtov i strok, SHA vsego prefiksa, pozicii i SHA vyibrannyikh strok, ogranichennyiye faktyi i nablyudeniya, SHA snimka i SHA predyidusjhego arkhivnogo obyyekta. Syiryiye stroki ne sokhranyayutsya. Khyesh stroki vklyuchayet yeyo LF.

Kursor susjhestvuyet vnutri togo zhe obyyekta. Rezuljtat publikuyetsya toljko posle uspeshnoj zapisi i fsync fajla i kataloga. Tochnyij povtor snova podtverzhdayet dolgovechnostj, no ne uvelichivayet chislo obyyektov ili razmer kontejnera. Lyuboye dopolneniye zavershyonnyimi strokami sozdayot novyij obyyekt dazhe bez novyikh semanticheskikh faktov. Podmena ili usecheniye prinyatogo prefiksa zapresjhayet prodolzheniye.

Replay vosstanavlivayet snimok bez iskhodnika, proveryayet kanonicheskiye bajtyi, skhemu, identichnostj, SHA, soglasovannostj vyibrannyikh pozicij i perekhod mezhdu arkhivnyimi obyyektami. Staryij fakt ne mozhet poluchitj novoye znacheniye ili perejti k drugomu khodu pod prezhnej poziciyej. Posleduyusjhij import vsyo ravno perechityivayet i khyeshiruyet prezhnij prefiks. Optimizaciya propuskayet yego povtornyij semanticheskij razbor toljko posle vosstanovleniya proverennogo arkhivnogo sostoyaniya; polnyij razbor ostayotsya etalonnyim rezhimom.

Geometriya kursora dopolniteljno svyazyivayet kazhdoye izvestnoye chislo zavershyonnyikh strok s yedinstvennyim bajtovyim smesjheniyem. Proveryayutsya nachala i koncyi vyibrannyikh strok, prezhnyaya granica arkhivnoj cepochki i konechnyij kursor, vklyuchaya nevyibrannyij zavershyonnyij khvost. Na kazhduyu neizvestnuyu stroku trebuyetsya ot 34 bajtov do byudzheta stroki, vklyuchaya LF; pervaya `session_meta` s kanonicheskim UUID zanimayet minimum 80 bajtov. Sovpadayusjhij schyotchik s raznyimi smesjheniyami i nevyipolnimyiye intervalyi otklonyayutsya dazhe pri soglasovannom kanonicheskom arkhive i SHA snimka. Eto ne vosstanovleniye syiryikh strok i ne vneshnyaya autentifikaciya.

Skhema arkhiva i versiya adaptera ostayutsya ravnyi 1: rasshireniye ne menyayet semantiku prezhnikh form i sokhranyonnyiye obyyektyi. Prezhniye minimaljnyiye formyi po-prezhnemu dopustimyi, poetomu nizhniye granicyi 34/80 bajtov sokhranyayutsya. Sintetika proveryayet neizmennostj starogo kontejnera, dopolneniye nejtraljnyimi zapisyami, pobajtovoye ravenstvo kanonicheskikh rezuljtatov polnogo i inkrementaljnogo razbora i otkryitiye bez istochnika. Budusjheye izvlecheniye faktov iz nejtraljnyikh tipov potrebuyet otdeljnogo resheniya o versii i povtornom razbore.

Oshibka zapisi ili podtverzhdeniya delayet tekusjhij ekzemplyar nedostupnyim do zakryitiya i novogo otkryitiya. Polnyij obyyekt, vidimyij posle neopredelyonnogo iskhoda fsync, trebuyet uspeshnogo podtverzhdeniya do vyidachi novogo podtverzhdyonnogo rezuljtata: pri tochnom povtore libo importe dopolneniya. Nepolnyij kontejnernyij khvost avtomaticheski ne udalyayetsya: yavnoye vosstanovleniye razresheno toljko posle proverki vsekh zavershyonnyikh obyyektov na ozhidayemuyu identichnostj i skhemu.

## Byudzhetyi i ogranicheniya

Predel istochnika — 256 MiB, stroki — 8 MiB, strok — 1 000 000, glubinyi JSON — 32, uzlov odnoj stroki — 65 536, klyuchej obyyekta — 4096, arkhivnyikh obyyektov — 1024, odnogo arkhivnogo obyyekta — 64 KiB. Razmer chitayemogo bloka — 256 KiB. Polnyij iskhodnik ne zagruzhayetsya v pamyatj; stroka i yeyo razbor ogranichenyi. Poljzovateljskij byudzhet mozhno toljko umenjshatj.

Izmeneniye fajla vo vremya odnogo chteniya obnaruzhivayetsya po razmeru i fajlovyim metadannyim i privodit k otkazu; novyij zapusk mozhet povtoritj import. Eto ne obesjhayet zasjhitu ot vrazhdebnogo processa, sposobnogo soglasovanno podmenyatj vesj lokaljnyij arkhiv, iskhodnik i metadannyiye. Khyeshi dokazyivayut celostnostj i vnutrennyuyu soglasovannostj, a ne vneshnyuyu podlinnostj.

## Proverennaya gotovnostj

Arkhivnyij adapter prinyat na dvukh zakreplyonnyikh prefiksakh odnoj yavno razreshyonnoj zadachi: 117 069 638 bajtov / 17 968 strok i 118 401 310 bajtov / 18 419 strok. Pervyij import ispravlennoj versii zavershilsya uspeshno; povtor i vosstanovleniye dali odinakovyiye bajtyi. Pri dopolnenii yesjhyo 451 strokoj prezhniye 4 877 bajtov kontejnera sokhranilisj, novyij razmer sostavil 9 839 bajtov. Povtor ne uvelichil kontejner; otdeljnyij process vosstanovil tot zhe rezuljtat.

Podmena odnogo bajta vremeni v korrektnom JSON prinyatogo prefiksa i usecheniye istochnika otklonenyi s kodom 2 bez vyivoda rezuljtata. V oboikh sluchayakh kontejner ostalsya pobajtno neizmennyim; posleduyusjheye vosstanovleniye proshlo. Oba iskhodnyikh fajla i prezhnij kontejner ispoljzovalisj toljko dlya chteniya. Podrobnosti, razmeryi, SHA i izmereniya nakhodyatsya v [otchyote priyomki](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md). Syiryiye dialog i otvetyi CLI sokhranenyi privatno.

Eto priyomka arkhivnogo komponenta v ukazannoj granice, bez nablyudeniya zhivogo processa ili interfejsa. Gotovnostj vsej FUMA, avtomaticheskoye prodolzheniye zadach i rabota ostaljnyikh napravlenij iz neyo ne sleduyut. Obsjhaya proverka FUM otnositsya k dokumentacii, planovoj kartochke i svideteljstvam tekusjhego izmeneniya; samostoyateljnyij Swift-paket v osnovnoj checkout ne perenositsya.

## Obsjhij chitatelj

V API statistiki kommita `85dccce282821a890e5e65539b4f22b895b52887` funkciya `прочитатьПрефикс` vozvrasjhayet `ПрочитанныйПрефикс` s uzhe vyibrannyimi `СобытиеВызова`, granicej i schyotchikami. Eto predmetnyij chitatelj statistiki, poetomu on ne zamenyayet arkhivnyij razbor. Vozmozhnoye budusjheye obyyedineniye ogranicheno nizhnim sloyem chteniya bajtov, LF-granic i SHA posle vyideleniya ustojchivogo kontrakta i yego regressij; redukcii statistiki i arkhivnogo snimka ostayutsya samostoyateljnyimi.

## Istochniki

- [Podderzhka sluzhebnyikh obolochek i granica realjnoj priyomki](https://github.com/fum-lab/fum/blob/81e2e2c6e830c0f742fffa719c38facde39e41a1/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_17-52-38_MSK_%D0%BF%D0%BE%D0%B4%D0%B4%D0%B5%D1%80%D0%B6%D0%B0%D1%82%D1%8C-%D1%81%D0%BB%D1%83%D0%B6%D0%B5%D0%B1%D0%BD%D1%8B%D0%B5-%D0%BE%D0%B1%D0%BE%D0%BB%D0%BE%D1%87%D0%BA%D0%B8-runtime/%D0%BE%D1%82%D1%87%D1%91%D1%82.md).

- [Ispravleniye vyipolnimosti kursora i utochneniye granicyi sravneniya profilya](https://github.com/fum-lab/fum/blob/81e2e2c6e830c0f742fffa719c38facde39e41a1/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_17-20-36_MSK_%D0%B8%D1%81%D0%BF%D1%80%D0%B0%D0%B2%D0%B8%D1%82%D1%8C-%D0%B2%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B8%D0%BC%D0%BE%D1%81%D1%82%D1%8C-%D0%B0%D1%80%D1%85%D0%B8%D0%B2%D0%BD%D0%BE%D0%B3%D0%BE-%D0%BA%D1%83%D1%80%D1%81%D0%BE%D1%80%D0%B0/%D0%BE%D1%82%D1%87%D1%91%D1%82.md).
- [Porucheniye i granicyi postavki](https://github.com/fum-lab/fum/blob/81e2e2c6e830c0f742fffa719c38facde39e41a1/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_16-02-38_MSK_%D1%80%D0%B5%D0%B0%D0%BB%D0%B8%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%B0%D1%80%D1%85%D0%B8%D0%B2%D0%BD%D1%8B%D0%B9-%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA-%D0%B7%D0%B0%D0%B4%D0%B0%D1%87%D0%B8/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md).
- [Otchyot, profilj i tochnyiye kommityi](https://github.com/fum-lab/fum/blob/81e2e2c6e830c0f742fffa719c38facde39e41a1/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_16-02-38_MSK_%D1%80%D0%B5%D0%B0%D0%BB%D0%B8%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%B0%D1%80%D1%85%D0%B8%D0%B2%D0%BD%D1%8B%D0%B9-%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA-%D0%B7%D0%B0%D0%B4%D0%B0%D1%87%D0%B8/%D0%BE%D1%82%D1%87%D1%91%D1%82.md).
- [Priyomka form runtime i realjnogo importa](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0164-prinyatj-formyi-runtime-i-realjnyij-arkhiv.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 18:54:52 MSK -->
<!-- content-sha256: sha256:ea8e84719646d4cccf5634e9dfe7ef8a62c0a2449b7a00a16224fcc7be4dc425 -->
<!-- FUM-MD-RECENCY:END -->
