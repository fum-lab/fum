# Otchyot 2026-07-23 11:50:58 MSK - Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM

Nablyudateljskaya otnositeljnostj FUM poluchila proveryayemuyu yedinicu: odin napravlennyij perekhod ot tochnogo iskhodnogo sloya k predstavleniyu drugogo nablyudatelya. Proizvodnaya forma teperj obyazana pokazyivatj proiskhozhdeniye signalov, sokhranyonnyiye otnosheniya, poteri i granicu vozvrata k istochniku.

## Rezuljtat

[Specifikaciya versii 1](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md) zadayot strogij JSON-konvert s oblastjyu primenimosti, iskhodnoj i celevoj storonami, metodom preobrazovaniya, kartoj signalov, invariantami, poteryami, proverkoj obratimosti i otdeljnyim marshrutom k polnoj otnositeljno `scope` informacii.

[Mashinnaya skhema](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json) zapresjhayet neizvestnyiye polya, a [semanticheskij validator](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py) proveryayet mezhpolevuyu celostnostj. [Obratimaya fikstura](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-obratimogo-preobrazovaniya.json) proveryayet strogij UTF-8 round-trip, a [neobratimaya](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-neobratimogo-preobrazovaniya.json) predyyavlyayet kolliziyu dvukh Markdown-dokumentov s odinakovyim pervyim zagolovkom. Kazhdaya zapisj obnaruzhivayetsya cherez sobstvennyij materializovannyij kontekst postavki.

Termin [«preobrazovaniye mezhdu nablyudatelyami FUM»](../../Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md) dobavlen v glossarij. Dokumentyi ob arkhitekture, interfejse, nablyudateljskoj otnositeljnosti i kartochkakh sootvetstviya teperj razlichayut realjnyij napravlennyij perekhod i konceptualjnoye sopostavleniye.

## Proverka formata

Draft-proverka razobrala skhemu i obe fiksturyi. Sokhranyayemyij validator na standartnoj biblioteke Python podtverdil tochnyij nabor verkhneurovnevyikh polej, unikaljnostj i razreshimostj signalov, ischerpyivayusjhiye inventari, otsutstviye molchalivyikh poterj, materializovannuyu svyazj s sidecar-zapisjyu i uspeshnyiye proverki invariantov. Strogoye dekodirovaniye i obratnoye kodirovaniye vosstanovili iskhodnyiye bajtyi `Глоссарий/FUM.md`.

Dopolniteljno validator otklonil pyatnadcatj otricateljnyikh mutacij: visyachiye i povtornyiye ID, marshrut k chuzhomu istochniku, protivorechivyiye vyivodyi ob obratimosti, `preserved` bez uspeshnogo invarianta, nepodderzhivayemyij discovery-metod, lishniye statusnyiye polya, absolyutnyij `file:` URI, privatnyiye adresa i pokhozhiye na sekret parametryi URL.

Dlya neobratimogo primera stroki `# FUM\n\nA\n` i `# FUM\n\nB\n` razlichayutsya, no preobrazuyutsya v odnu podpisj `FUM`. Eto yavlyayetsya nablyudayemoj kolliziyej, a ne prosto neudachej vyibrannogo obratnogo metoda. V oboikh primerakh marshrut k iskhodnoj statjye razreshilsya po otnositeljnomu puti i tochnomu SHA-256.

## Granica primenimosti

Format opisyivayet odin perekhod dokumentacionnogo prototipa i ne realizuyet runtime, kompilyator, transport, chislovuyu metriku poterj ili prava dostupa. Polnota istochnika ogranichena yavno nazvannoj proyekciyej i zakreplyonnyim snimkom i podtverzhdayetsya ischerpyivayusjhim inventaryom signalov. Nalichiye ssyilki na original ne delayet svodku obratimoj, a dokazateljstvo odnogo zvena ne perenositsya avtomaticheski na cepochku preobrazovanij.

## Prodolzheniye

`FUM-STEP-0025` zavershena po fakticheskomu rezuljtatu. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0026` yedinstvennyim `ready`. Sleduyusjhij shag opisyivayet minimaljnyij pasport peredavayemogo rezuljtata FUM, lokaljno ispolnim po uzhe sokhranyonnyim istochnikam i ne trebuyet vneshnego dostupa ili novogo razresheniya.

## Zatronutyiye materialyi

- [specifikaciya minimaljnogo formata](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [mashinnaya skhema](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/skhema-preobrazovaniya-v1.json)
- [semanticheskij validator](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/proveritj-preobrazovaniye-v1.py)
- [kontekst postavki obratimoj fiksturyi](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-obratimoj-fiksturyi.json)
- [kontekst postavki neobratimoj fiksturyi](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/kontekst-postavki-neobratimoj-fiksturyi.json)
- [obratimaya fikstura](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-obratimogo-preobrazovaniya.json)
- [neobratimaya fikstura](../../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/fikstura-neobratimogo-preobrazovaniya.json)
- [termin «preobrazovaniye mezhdu nablyudatelyami FUM»](../../Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md)
- [zavershyonnaya kartochka FUM-STEP-0025](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0025-opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](../../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ec370b445f862c194f5740908e88b233ae225313fb153c07195d339e934e67a7 -->
<!-- FUM-MD-RECENCY:END -->
