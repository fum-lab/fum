# Otchyot 2026-07-16 16:01:58 MSK - Dobavitj semanticheskiye ssyilki v kartochki trebovanij

Semj [kartochek trebovanij FUM](../../Glossarij/kartochka-trebovaniya-FUM.md) vruchnuyu prosmotrenyi kak yedinyij smyislovoj graf. Obyichnyimi inline Markdown-ssyilkami materializovanyi toljko otnosheniya, kotoryiye utochnyayut chteniye i realizaciyu trebovanij: posledovateljnostj avtomaticheskogo vkhoda i avtozapuska, graficheskij putj polnoekrannogo prilozheniya, vizualjnoye skryitiye sistemnoj obolochki, vosstanovleniye interfejsa posle sboya i uslovnoye usileniye rezhima cherez upravlyayemyij zhyostkij kiosk.

Vosemj napravlennyikh mezhkartochnyikh perekhodov vstroyenyi v soderzhateljnyiye predlozheniya, poetomu sama formulirovka obyyasnyayet tip otnosheniya. Obratnyiye ssyilki ne produblirovanyi tam, gde oni ne dobavlyali byi smyisla. Otdeljno svyazan glossarnyij sloj: soderzhateljnyiye upotrebleniya FUM, korobochnoj realizacii i statusa trebovaniya teperj vedut k opredeleniyam. Sistemnaya rabochaya sessiya macOS, fonovyij servis i pervyij prototip ne svyazanyi s pokhozhimi po napisaniyu, no drugimi ponyatiyami pamyati FUM.

## Resheniye po avtomatizacii

Smyislovaya umestnostj ssyilok proverena vruchnuyu. Budusjhaya TDD-proverka kartochek posle poyavleniya vtorogo nabora smozhet proveritj sintaksis, registr i razreshimostj celej, no ne dolzhna podmenyatj soderzhateljnoye resheniye o tipe svyazi.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [indeks trebovanij](../../Trebovaniya/README.md)
- [avtozapusk interfejsa](../../Trebovaniya/🟡-avtozapusk-interfejsa.md)
- [avtomaticheskij vkhod v vyidelennuyu uchyotnuyu zapisj](../../Trebovaniya/🟡-avtomaticheskij-vkhod-v-vyidelennuyu-uchyotnuyu-zapisj.md)
- [otrisovka interfejsa cherez Metal](../../Trebovaniya/🟡-otrisovka-interfejsa-cherez-Metal.md)
- [polnoekrannoye prilozheniye bez sistemnoj obolochki](../../Trebovaniya/🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md)
- [skryitiye Dock i stroki menyu](../../Trebovaniya/🟡-skryitiye-Dock-i-stroki-menyu.md)
- [upravlyayemyij zhyostkij kiosk-rezhim](../../Trebovaniya/🟡-upravlyayemyij-zhyostkij-kiosk-rezhim.md)
- [fonovyij servis vyichislenij i vosstanovleniya interfejsa](../../Trebovaniya/🟡-fonovyij-servis-vyichislenij-i-vosstanovleniya-interfejsa.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Vruchnuyu sopostavlenyi vse semj kartochek, vosemj mezhkartochnyikh otnoshenij i otricateljnyiye paryi bez dostatochnogo osnovaniya.
- Planovyij reyestr peresobran i provalidirovan; recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian obnovlenyi.
- `git diff --check` i `fum-session-coherence` zavershilisj uspeshno.
- Polnyij `fum-smoke-check` proshyol 14 shagov: 69 testov devyati lokaljnyikh avtomatizacij, sborku i proverku planovogo reyestra, proverki recency, grafa Obsidian i svyaznosti tekusjhej sessii.

## Istochniki

- [iskhodnyij zapros 2026-07-16 16:01:58 MSK](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:5e7e226382a2008c3a773d145c22f9cfb4d7af3ef4f2b51e34b19c8ea20b91b5 -->
<!-- FUM-MD-RECENCY:END -->
