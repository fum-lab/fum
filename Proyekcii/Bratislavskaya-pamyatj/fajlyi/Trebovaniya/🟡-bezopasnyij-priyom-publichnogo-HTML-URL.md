# Bezopasnyij priyom publichnogo HTML-URL

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0031 -->

Pervyij produktovyij servis istochnikov FUM dolzhen prinimatj toljko odin yavno podtverzhdyonnyij publichnyij HTTPS-URL s prostyim HTML-otvetom po kontraktu `fum.source-ingest.v1`. Proverki do seti, razresheniye adresov, kazhdyij redirect-hop, zagolovki i ogranichennoye potokovoye chteniye vyipolnyayutsya razdeljno; lyuboj nedokazannyij adres, tip, razmer ili status zakryivayet operaciyu do prinyatiya istochnika v [pamyatj FUM](../Glossarij/pamyatj-FUM.md).

## Semanticheskiye svyazi

- **zavisit ot:** [privyazannogo podtverzhdeniya i minimaljnyikh prav priyoma istochnika](🟡-privyazannoye-podtverzhdeniye-i-minimaljnyiye-prava-priyoma-istochnika.md) — setevoye chteniye razreshayetsya toljko tochnyim odnorazovyim podtverzhdeniyem pokazannogo plana.
- **zavisit ot:** [produktovogo proiskhozhdeniya prinyatogo istochnika](🟡-produktovoye-proiskhozhdeniye-prinyatogo-istochnika.md) — prinyatyij snimok obyazan sokhranyatj proveryayemuyu prichinnuyu cepochku ot namereniya do rezuljtata.
- **zavisit ot:** [atomarnogo prinyatiya snimka i proiskhozhdeniya istochnika](🟡-atomarnoye-prinyatiye-snimka-i-proiskhozhdeniya-istochnika.md) — setevoj uspekh ne stanovitsya produktovyim uspekhom bez yedinoj granicyi prinyatiya snimka i svyazi.

## Kriterii proverki

- mashinnaya skhema fiksiruyet versii entrypoint, zaprosa, plana, podtverzhdeniya, rezuljtata, manifesta, proiskhozhdeniya i stabiljnyikh kodov oshibok;
- preflight otklonyayet nepodderzhivayemuyu skhemu, userinfo, nepodtverzhdyonnyij plan, nesovmestimuyu versiyu, nedostatochnyiye prava i nedopustimuyu oblastj bez DNS, seti i kanonicheskoj zapisi;
- dlya iskhodnoj celi i kazhdogo perenapravleniya proveryayutsya vse DNS-adresa, fakticheskij peer, TLS-imya i prinadlezhnostj publichnoj global-unicast-oblasti; private, loopback, link-local, metadata, reserved, mixed i izmenivshiyesya pri rebinding adresa otklonyayutsya;
- pervyij reliz prinimayet toljko same-origin HTTPS-perenapravleniya, status `200`, `text/html` bez transportnogo szhatiya, ne boleye `64 KiB` zagolovkov i `4 MiB` tela; potok ostanavlivayetsya do prevyishayusjhej limit zapisi;
- avtonomnaya otricateljnaya matrica pokryivayet redirects, DNS rebinding, private i metadata targets, MIME, zayavlennyij i fakticheskij razmer, prava, podmenu plana i otsutstviye kanonicheskikh pobochnyikh zapisej.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i specificirovano v pasporte i JSON Schema, no postavlyayemyij servis, yego transport i produktovaya priyomka yesjhyo ne realizovanyi. Lokaljnyij `fum source archive` i fiksturnyij transport ostayutsya obrazcami, a ne dokazateljstvom produktovoj seti.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej sessii](../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [audit pasporta korobochnoj stadii](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md)
- [pasport pervogo produktovogo URL-sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)
- [mashinnaya skhema kontrakta v1](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza/kontrakt-pervogo-URL-sreza-v1.schema.json)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d9a3dbbe0264326d80354da27a9d7928b9f41cfe64a1518c9ca5f9545fa91ea9 -->
<!-- FUM-MD-RECENCY:END -->
