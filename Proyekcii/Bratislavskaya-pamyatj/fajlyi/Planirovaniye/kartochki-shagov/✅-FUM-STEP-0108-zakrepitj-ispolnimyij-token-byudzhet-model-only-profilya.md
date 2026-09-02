+++
schema_version = 1
card_id = "FUM-STEP-0108"
status = "completed"
+++
# Zakrepitj ispolnimyij token-byudzhet model-only-profilya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj realjnyij model-only-profilj ispolnimyim i nablyudayemyim token-byudzhetom. Do kazhdogo vyizova adapter dolzhen nezavisimo proveritj ostatki vyizovov, vkhodnyikh i vyikhodnyikh tokenov i deneg, peredatj provajderu podderzhivayemyij predel generacii libo zakryitjsya otkazom, a posle vyizova sokhranitj podtverzhdyonnoye potrebleniye otdeljno ot modeljnogo teksta.

## Pochemu sejchas

Dejstvuyusjhij LM Studio process-adapter dokazyivayet odin realjnyij vyizov, no sokhranyayet `max_output_tokens = unknown` i izmeryayet bajtyi otveta. Etogo nedostatochno dlya pasporta epizoda, v kotorom ozhidaniye podtverzhdeniya ne uvelichivayet byudzhet i ischerpaniye ostatka sozdayot kontroljnuyu tochku bez novogo modeljnogo vyizova. Tekusjhij poljzovateljskij zapros snimayet poetapnoye podtverzhdeniye dlya tochnoj cepochki FUM-STEP-0108–FUM-STEP-0112 i razreshayet v nej toljko uzhe dostupnyij lokaljnyij provider s temi zhe ogranicheniyami: bez skachivaniya vesov, novyikh sekretov, platnogo dostupa, poljzovateljskikh dannyikh i vneshnej seti. Inaya identity ili capability zakryivayet shag, a ruchnoj `push` ne rasshiryayet eto polnomochiye.

## Kriterii zaversheniya

- Versionnyij profilj nezavisimo zakreplyayet tochnyij rezhim `local | remote`, identity modeli i runtime, klassyi, obyyom i naznacheniye razreshyonnogo raskryitiya dannyikh, maksimumyi vyizovov, vkhodnyikh i vyikhodnyikh tokenov, wall-clock-vremeni, vyichislenij i deneg; narusheniye disclosure-politiki ne vyizyivayet provider.
- Adapter do zapuska proveryayet affordability sleduyusjhego vyizova i atomarno sokhranyayet reservation yego maksimaljnyikh vyizovov, vkhodnyikh i vyikhodnyikh tokenov, vremeni, vyichislenij i deneg. Posle doverennogo provider usage reservation soglasuyetsya s faktom; tajm-aut, chastichnyij otvet ili otsutstviye usage sokhranyayut konservativnyij raskhod i ne razreshayut avtomaticheskij povtor. Ozhidaniye vneshnego podtverzhdeniya samo po sebe ne menyayet schyotchiki.
- Predel vyikhodnyikh tokenov ispolnim sredstvami vyibrannogo provider-interfejsa i podtverzhdayetsya avtonomnoj fiksturoj; neizvestnaya ili nepodderzhivayemaya capability zakryivayetsya otkazom, a ne znacheniyem `unknown`.
- Rezuljtat khranit proveryayemoye provider usage libo yavno tipizirovannyij otkaz; predvariteljnaya tokenizaciya sovmestima s provider-interfejsom, a modeljnyij tekst ne mozhet obyyavitj sobstvennoye potrebleniye, zavershitj reservation ili povyisitj limit.
- Perepolneniye, otricateljnyiye znacheniya, nesoglasovannyiye schyotchiki, tajm-aut i chastichnyij otvet imeyut otdeljnyiye terminaljnyiye iskhodyi i ne raskhoduyut byudzhet povtorno pri vosproizvedenii.
- Zapisannyiye testyi prokhodyat bez zhivoj modeli, a odin opt-in lokaljnyij progon podtverzhdayet identity, limit i usage bez skachivaniya vesov, novyikh sekretov, platnogo dostupa ili raskryitiya poljzovateljskikh dannyikh.

## Rezuljtat

V Swift-prototip dobavlen otdeljnyij profilj `schema_version = 2` dlya `fum.lm-studio-rest-v0.budgeted.v1`. On nezavisimo zakreplyayet `local | remote`, provider-interfejs i tochnyij endpoint, modelj, runtime, tokenizer, klassyi, bajtovyij obyyom i celj raskryitiya, a takzhe maksimumyi vyizovov, vkhodnyikh i vyikhodnyikh tokenov, wall-clock-vremeni, vyichisliteljnyikh yedinic i deneg s tochnyimi yedinicami. Neizvestnyiye polya authority-profilya i vlozhennyikh obyyektov otklonyayutsya. Invocation yavlyayetsya otdeljnoj uzkoj formoj s odnim `input` bez sobstvennogo polya versii, a ne polnyim rasshireniyem konverta versii `1`. Remote mozhno serializovatj, no adapter zakryivayet yego do tokenizer/provider, poka net istochnika cenyi i soglasovaniya; ispolnyayetsya toljko lokaljnyij rezhim. Staryij `fum.lm-studio-cli.one-shot.v1` sokhranyon bez izmeneniya smyisla: otsutstviye u `lms chat` ispolnimogo token limit po-prezhnemu ne maskiruyetsya bajtovyim predelom.

`VolatileModelBudgetLedger` odnoj actor-operaciyej proveryayet request hash i ostatki, zatem sokhranyayet maksimaljnyij reservation po vsem shesti izmereniyam. Aktivnyiye i terminaljnyiye zapisi prinadlezhat ledger, poetomu same-ID reentrancy linearizuyetsya, a replay posle sozdaniya drugogo adapter s tem zhe actor ne vyizyivayet provider i ne spisyivayet byudzhet povtorno. Doverennyiye `usage.prompt_tokens`, `usage.completion_tokens` i `usage.total_tokens` iz verkhnego urovnya LM Studio REST v0 soglasuyut vkhodnyiye i vyikhodnyiye tokenyi. Dlya lokaljnogo profilya wall-clock i compute izmeryayutsya v millisekundakh vmeste ot nachala tokenizer do zaversheniya HTTP, cena nezavisimo zakreplena `money_unit = none` i nulyom. Tajm-aut, chastichnyij otvet, otsutstviye ili nesoglasovannostj usage spisyivayut polnyij reservation i stanovyatsya nepovtoryayemyimi terminaljnyimi iskhodami.

Publichnaya ispolnyayemaya poverkhnostj prinimayet toljko konstantnuyu attestaciyu etoj kartochki i konkretnyij `LMStudioRESTV0BudgetTransport`; vnedreniye protocol-zaglushek v adapter i transport dostupno paketu toljko dlya avtonomnyikh testov, a syiryiye provider- i HTTP-metodyi ne vkhodyat v public API. Do JSON/SHA vse khyeshiruyemyiye polya prokhodyat absolyutnyiye UTF-8-predelyi, a 27-bajtovaya exact-fikstura obryivayet skanirovaniye vkhoda na `28`-m bajte. Rannij otkaz imeyet `request_sha256 = nil`, ne sozdayot terminal ledger entry i reservation i ne menyayet byudzhet. Transport razreshayet toljko tochnyij `http://127.0.0.1:<порт>/api/v0/chat/completions`, peredayot `max_tokens` isklyuchiteljno iz profilya i prinimayet strukturirovannyiye model/runtime/usage otdeljno ot nedoverennogo `message.content`. Dlya kazhdogo vyizova sozdayotsya isolated ephemeral-sessiya bez ambient cookie, credentials, cache i proxy; redirect zapresjhyon, konechnyij URL sveryayetsya, obsjhij resource timeout absolyuten, a absolyutnyij predel tela raven `1048576` bajtam i mozhet toljko umenjshatjsya. Toljko uspeshno soglasovannaya popyitka khranit SHA-256 tochnyikh bajtov tela, peredannyikh `URLSession` posle obrabotki HTTP-peredachi; lyuboj post-provider otkaz dayot tipizirovannyij iskhod bez digest, transport partial otdelyon ot etoj obsjhej kategorii invalid response, slishkom boljshoye telo i wire-overflow imeyut sobstvennyiye iskhodyi.

Predvariteljnyij tokenizer dopuskayet toljko `exact`. Poskoljku REST v0 ne predostavlyayet otdeljnyij tokenize-vyizov, zhivaya capability ogranichena odnoj publichnoj konstantnoj attestaciyej: provider/interface i framing odnogo user-message, endpoint, runtime, sinteticheskij prompt `Return the single letter A.`, yego SHA-256, modelj `qwen/qwen3-0.6b` i `14` vkhodnyikh tokenov zakreplenyi vmeste. Proizvoljnoye chislo cherez publichnyij initializer peredatj neljzya; drugoj profilj, input ili model zakryivayetsya do provider, a uspeshnyij otvet obyazan povtorno podtverditj `prompt_tokens = 14`. Universaljnaya tokenizaciya proizvoljnogo konteksta ne zayavlyayetsya.

Garantiya ledger namerenno ogranichena `durability = process_memory`: ona dokazyivayet atomarnostj i idempotentnostj v predelakh zhizni actor/process, no ne vosstanovleniye posle avarii. Podtverzhdyonnoye mezhprocessnoye khranilisjhe ostayotsya otdeljnoj FUM-STEP-0110.

## Proverka

Avtonomnyij nabor proveryayet strogij profilj, ogranichennyij prehash i disclosure do provider, kazhdyij byudzhetnyij predel, obsjhij deadline, konkurentnyiye reservation, same-ID reentrancy, replay mezhdu adapter, tochnyij `max_tokens`, redirect-otkaz, byte cap, SHA-256 prinyatogo tela, tochnuyu privyazku tokenizer, doverennoye usage i razdeljnyiye terminaljnyiye iskhodyi dlya otricateljnyikh znachenij, perepolneniya i nesoglasovannyikh schyotchikov. Otdeljnyij opt-in-progon uzhe sokhranyonnoj `qwen/qwen3-0.6b` cherez lokaljnyij LM Studio REST v0 podtverdil tochnyiye model/runtime, `finish_reason = length`, `max_tokens = 1`, `prompt_tokens = 14`, `completion_tokens = 1` i tochnoye sovpadeniye predvariteljnoj attestacii s provider usage. Server i modelj posle proverki vozvrasjhenyi v iskhodnoye ostanovlennoye i nezagruzhennoye sostoyaniye; vesa, sekretyi, platnyij dostup i poljzovateljskiye dannyiye ne dobavlyalisj.

## Istochniki

- [iskhodnyij dispetcherskij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-31_18-05-50_MSK_zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya/zapros.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master i poetapnoye podtverzhdeniye](../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [FUM-STEP-0107 — lokaljnyiye SwiftPM-zavisimosti prototipov](✅-FUM-STEP-0107-razreshitj-proveryayemyiye-lokaljnyiye-SwiftPM-zavisimosti-prototipov.md)
- [FUM-STEP-0102 — realjnyij model-only-adapter](✅-FUM-STEP-0102-podklyuchitj-proveryayemyij-realjnyij-model-only-adapter.md)
- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)
- [trebovaniye o skvoznom odnoagentnom epizode](../../Trebovaniya/✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0e972234f85965d73384d86d7eaad48c67db066bb2120bbba84a4997e9c5f84c -->
<!-- FUM-MD-RECENCY:END -->
