# Plan razbora shriftov strukturiruyusjhimi operatorami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0073 -->

Podgotovitj plan razbora fajlov shriftov posredstvom opredelenij obsjhikh strukturiruyusjhikh operatorov FUM. Predmetnyiye pravila formata — tablicyi, polya, versii, poryadok bajtov, smesjheniya, dlinyi, ssyilki i ogranicheniya — dolzhnyi byitj vidimyimi dannyimi opredeleniya, kotoryiye ispolnyayet obsjhij interpretator.

Rezuljtat razbora svyazyivayet tipizirovannyiye uzlyi i ryobra obsjhej operatornoj modeli s tochnyimi diapazonami iskhodnogo fajla i primenyonnyimi opredeleniyami. Formatnoye pravilo ne skryivayetsya v otdeljnom neprozrachnom parsere, vyizyivayemom yedinstvennyim operatorom. Dopolneniye obsjhego nabora primitivov dopuskayetsya toljko kak otdeljnoye obosnovannoye predlozheniye s konechnyim kontraktom; vyibor tekhnicheskoj zavisimosti etim trebovaniyem ne proizvoditsya.

## Kriterii proverki

- Plan vyibirayet odin pervyij zakryityij profilj formata s tochnoj oficialjnoj specifikaciyej, yeyo redakciyej i konechnyim perechnem razbirayemyikh struktur. Drugiye formatyi, kontejneryi, versii i tablicyi yavno vklyuchenyi v posleduyusjhiye predlozheniya libo isklyuchenyi; podderzhka vsekh shriftov ne obesjhayetsya.
- Sostavlena matrica «struktura i pole → normativnoye pravilo → opredeleniye operatora → obsjhij primitiv → diapazon i ssyilka → ozhidayemoye nablyudeniye». Dlya kazhdogo smesjheniya zadanyi osnovaniye, yedinica i razreshyonnaya oblastj; dlya dlinyi i kolichestva — proveryayemyiye predelyi. Pravila neljzya podmenitj neprozrachnyim vyizovom gotovogo parsera.
- Dlya budusjhego ispolneniya opredelenyi konechnyij iskhodnyij bajtovyij vkhod, versiya nabora operatorov, tipizirovannyij rezuljtat, absolyutnyiye pozicii oshibok, ssyilki na proiskhozhdeniye i yavno oboznachennyij nerazobrannyij ostatok. Vkhod ne prokhodit cherez ispravlyayusjheye tekstovoye dekodirovaniye, ne izmenyayetsya i ne ustanavlivayetsya v sistemu kak shrift.
- Plan otricateljnyikh proverok zakryivayet usecheniye, vyikhod diapazona za fajl ili soderzhasjhuyu strukturu, perepolneniye do slozheniya smesjheniya s dlinoj i umnozheniya chisla zapisej, nedopustimyiye versii i znacheniya, visyachiye ssyilki, protivorechivyiye dlinyi i nepodderzhivayemyij profilj. Dublikatyi, perekryitiya i sovmestnoye ispoljzovaniye dannyikh ocenivayutsya po vyibrannoj specifikacii, a ne odnim bezuslovnyim zapretom.
- Povtor i obkhod ssyilok imeyut konechnyij byudzhet i nablyudayemyij progress. Razlichayutsya cikl aktivnogo puti, dopustimaya povtornaya ssyilka na obsjhuyu strukturu i povtornyij razbor; opredelenyi predelyi glubinyi, shagov, uzlov, ryober, prochitannyikh bajtov, rezuljtata i trassyi. Predel etikh schyotchikov ne vyidayotsya za dokazannoye ogranicheniye pamyati processa ili vremeni CPU.
- Otkryityij korpus imeyet konechnyij sostav, tochnyiye bajtyi i khyeshi, proiskhozhdeniye i razresheniye na publikaciyu. On vklyuchayet vruchnuyu proveryayemyiye sinteticheskiye polozhiteljnyiye i povrezhdyonnyiye primeryi i vyibrannyiye otkryityiye shriftyi. Ozhidaniya vyivodyatsya nezavisimo ot proveryayemogo ispolnitelya; konkretnyij vneshnij sravnitelj ostayotsya otdeljnyim resheniyem.
- Pri odinakovyikh bajtakh, versiyakh operatorov, limitakh i vyichisliteljnom profile vosproizvodyatsya kanonicheskij logicheskij rezuljtat, poryadok nablyudayemoj trassyi i iskhod otkaza. Izmeneniye opredeleniya nablyudayemo dazhe pri odinakovom rezuljtate. Zameryi vremeni i pamyati otdelenyi ot determinirovannogo rezuljtata; dlya budusjhej realizacii zadan vosproizvodimyij profilj zagruzki, proverki opredeleniya, ispolneniya i trassirovki.
- Plan pokazyivayet svyazj razbora s obsjhim grafom operatorov i otdelyayet yeyo ot formirovaniya teksta, ispolneniya programm shrifta, khintinga i otrisovki. Eti sleduyusjhiye vozmozhnosti ne schitayutsya realizovannyimi razborom strukturyi.

## Semanticheskiye svyazi

- **dopolnyayet:** [chistoye ispolneniye operatorov i UTF-32](🟡-chistoye-ispolneniye-operatorov-i-UTF-32.md) — shriftovoj profilj trebuyet togo zhe razdeleniya opredeleniya, iskhodnogo vkhoda, nablyudeniya i nezavisimyikh ozhidanij; on ne zamenyayet i ne pereotkryivayet konechnyij UTF-8 → UTF-32 rezuljtat.

## Status i granicyi

Status trebovaniya — `🟡`.

Pervyij rezuljtat ogranichen analiticheskim planom shriftovogo profilya obsjhego interpretatora. Kod parsera, izmeneniye obsjhego dvizhka, import shriftov, ustanovka zavisimostej i sistemnyikh shriftov, vyipolneniye soderzhasjhikhsya v fajle programm i otrisovka v etot rezuljtat ne vkhodyat. Neizvestnyiye format, korpus, polnota primitivov i sleduyusjhij ispolnyayemyij obyyom dolzhnyi byitj razreshenyi planom libo sokhranenyi kak tochnyiye voprosyi.

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_16-55-35_MSK_utochnitj-operatornoye-vnimaniye-i-prodolzhitj-priyom/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 17:16:54 MSK -->
<!-- content-sha256: sha256:408d4226de68f086e4ac17c6102e54395575a2623cb4abdf1ac4fa612345c89d -->
<!-- FUM-MD-RECENCY:END -->
